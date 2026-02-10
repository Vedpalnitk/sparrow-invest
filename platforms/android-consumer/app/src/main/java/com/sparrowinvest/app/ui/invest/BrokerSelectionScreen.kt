package com.sparrowinvest.app.ui.invest

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.outlined.OpenInNew
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sparrowinvest.app.ui.components.Divider
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing

// Broker data class matching iOS BrokerSelectionView
data class Broker(
    val name: String,
    val iconName: String,
    val appScheme: String?,
    val webUrl: String,
    val color: Color
)

private val brokers = listOf(
    Broker(
        name = "Zerodha Coin",
        iconName = "Z",
        appScheme = "zerodha://",
        webUrl = "https://coin.zerodha.com",
        color = Color(0xFFFF9800) // Orange
    ),
    Broker(
        name = "Groww",
        iconName = "G",
        appScheme = "groww://",
        webUrl = "https://groww.in",
        color = Color(0xFF4CAF50) // Green
    ),
    Broker(
        name = "Kuvera",
        iconName = "K",
        appScheme = null,
        webUrl = "https://kuvera.in",
        color = Color(0xFF2196F3) // Blue
    ),
    Broker(
        name = "Paytm Money",
        iconName = "P",
        appScheme = "paytmmoney://",
        webUrl = "https://paytmmoney.com",
        color = Color(0xFF00BCD4) // Cyan
    ),
    Broker(
        name = "ET Money",
        iconName = "E",
        appScheme = null,
        webUrl = "https://etmoney.com",
        color = Color(0xFF9C27B0) // Purple
    )
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BrokerSelectionScreen(
    fundName: String,
    fundSchemeCode: Int,
    onBackClick: () -> Unit,
    onNavigateToManualEntry: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Choose Broker") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.large)
        ) {
            // Section A: Fund Info Header
            FundInfoHeader(
                fundName = fundName,
                isDark = isDark
            )

            // Section B: Investment Platforms
            BrokerListSection(
                brokers = brokers,
                isDark = isDark,
                context = context
            )

            // Section C: After Investing
            AfterInvestingSection(
                isDark = isDark,
                onNavigateToManualEntry = onNavigateToManualEntry
            )

            Spacer(modifier = Modifier.height(Spacing.large))
        }
    }
}

@Composable
private fun FundInfoHeader(
    fundName: String,
    isDark: Boolean
) {
    val shape = RoundedCornerShape(CornerRadius.large)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = glassBorderBrush(isDark)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (!isDark) Modifier.shadow(12.dp, shape, spotColor = ShadowColor, ambientColor = ShadowColor)
                else Modifier
            )
            .clip(shape)
            .background(backgroundColor)
            .border(1.dp, borderBrush, shape)
            .padding(Spacing.medium),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Fund Icon (initials in colored rounded rect)
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(Primary.copy(alpha = if (isDark) 0.15f else 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = fundName.take(2).uppercase(),
                style = MaterialTheme.typography.titleSmall,
                color = Primary
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = fundName,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 2
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = "Select a broker to invest in this fund",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun BrokerListSection(
    brokers: List<Broker>,
    isDark: Boolean,
    context: Context
) {
    val shape = RoundedCornerShape(CornerRadius.large)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = glassBorderBrush(isDark)

    Column(verticalArrangement = Arrangement.spacedBy(Spacing.compact)) {
        // Section header
        Text(
            text = "INVESTMENT PLATFORMS",
            style = MaterialTheme.typography.labelSmall,
            color = Primary,
            fontWeight = FontWeight.Medium,
            letterSpacing = 1.sp
        )

        // Broker list card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (!isDark) Modifier.shadow(12.dp, shape, spotColor = ShadowColor, ambientColor = ShadowColor)
                    else Modifier
                )
                .clip(shape)
                .background(backgroundColor)
                .border(1.dp, borderBrush, shape)
        ) {
            brokers.forEachIndexed { index, broker ->
                BrokerRow(
                    broker = broker,
                    isDark = isDark,
                    onClick = { openBroker(context, broker) }
                )

                if (index < brokers.lastIndex) {
                    Divider(
                        modifier = Modifier.padding(start = 72.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun BrokerRow(
    broker: Broker,
    isDark: Boolean,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(Spacing.medium),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Broker colored circle icon
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(broker.color.copy(alpha = if (isDark) 0.15f else 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = broker.iconName,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                color = broker.color
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        Text(
            text = broker.name,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )

        Icon(
            imageVector = Icons.Outlined.OpenInNew,
            contentDescription = "Open ${broker.name}",
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(18.dp)
        )
    }
}

@Composable
private fun AfterInvestingSection(
    isDark: Boolean,
    onNavigateToManualEntry: () -> Unit
) {
    val shape = RoundedCornerShape(CornerRadius.large)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = glassBorderBrush(isDark)

    Column(verticalArrangement = Arrangement.spacedBy(Spacing.compact)) {
        // Section header
        Text(
            text = "AFTER INVESTING",
            style = MaterialTheme.typography.labelSmall,
            color = Primary,
            fontWeight = FontWeight.Medium,
            letterSpacing = 1.sp
        )

        // Info card
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (!isDark) Modifier.shadow(12.dp, shape, spotColor = ShadowColor, ambientColor = ShadowColor)
                    else Modifier
                )
                .clip(shape)
                .background(backgroundColor)
                .border(1.dp, borderBrush, shape)
                .padding(Spacing.medium)
        ) {
            // Info header
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Info,
                    contentDescription = null,
                    tint = Primary,
                    modifier = Modifier.size(14.dp)
                )
                Spacer(modifier = Modifier.width(Spacing.small))
                Text(
                    text = "Track your investment",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            Spacer(modifier = Modifier.height(Spacing.small))

            Text(
                text = "After investing through your broker, add your investment manually or upload a portfolio screenshot to track it in SparrowInvest.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Add Investment Manually button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(CornerRadius.medium))
                    .background(Primary.copy(alpha = if (isDark) 0.15f else 0.1f))
                    .border(
                        width = 1.dp,
                        color = Primary.copy(alpha = 0.3f),
                        shape = RoundedCornerShape(CornerRadius.medium)
                    )
                    .clickable(onClick = onNavigateToManualEntry)
                    .padding(vertical = 14.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.AddCircle,
                    contentDescription = null,
                    tint = Primary,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(Spacing.small))
                Text(
                    text = "Add Investment Manually",
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.SemiBold,
                    color = Primary
                )
            }
        }
    }
}

/**
 * Try to open the broker's native app first via app scheme.
 * If that fails (no app installed), fall back to the web URL.
 */
private fun openBroker(context: Context, broker: Broker) {
    try {
        val schemeUri = broker.appScheme?.let { Uri.parse(it) }
        if (schemeUri != null) {
            val appIntent = Intent(Intent.ACTION_VIEW, schemeUri)
            val resolvedActivity = context.packageManager.resolveActivity(appIntent, 0)
            if (resolvedActivity != null) {
                context.startActivity(appIntent)
                return
            }
        }
        // Fallback to web URL
        val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(broker.webUrl))
        context.startActivity(webIntent)
    } catch (e: Exception) {
        // Silently handle if no browser is available
        try {
            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse(broker.webUrl))
            context.startActivity(webIntent)
        } catch (_: Exception) { }
    }
}

@Composable
private fun glassBorderBrush(isDark: Boolean): Brush {
    return if (isDark) {
        Brush.linearGradient(
            colors = listOf(
                GlassBorderStartDark,
                GlassBorderMidDark,
                GlassBorderEndDark
            )
        )
    } else {
        Brush.linearGradient(
            colors = listOf(
                GlassBorderStartLight,
                GlassBorderMidLight,
                GlassBorderEndLight
            )
        )
    }
}
