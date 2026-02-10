package com.sparrowinvest.app.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.CardGiftcard
import androidx.compose.material.icons.filled.FiberNew
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.Info
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning

@Composable
fun NotificationSettingsScreen(
    onBackClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current

    // Master toggle
    var allNotifications by remember { mutableStateOf(true) }

    // Investment alerts
    var navUpdates by remember { mutableStateOf(true) }
    var sipReminders by remember { mutableStateOf(true) }
    var goalMilestones by remember { mutableStateOf(true) }
    var marketAlerts by remember { mutableStateOf(true) }

    // Account & Security
    var transactionAlerts by remember { mutableStateOf(true) }
    var loginAlerts by remember { mutableStateOf(true) }
    var kycUpdates by remember { mutableStateOf(true) }

    // Recommendations
    var aiInsights by remember { mutableStateOf(true) }
    var newFundAlerts by remember { mutableStateOf(true) }
    var offersRewards by remember { mutableStateOf(true) }

    val glassBorderBrush = if (isDark) {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    val cardBackground = if (isDark) CardBackgroundDark else CardBackgroundLight
    val cardShape = RoundedCornerShape(CornerRadius.xLarge)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = onBackClick,
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Primary.copy(alpha = 0.1f))
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = Primary
                )
            }

            Spacer(modifier = Modifier.width(Spacing.medium))

            Text(
                text = "Notifications",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 1: Master Toggle
        GlassCard(isDark, cardBackground, glassBorderBrush, cardShape) {
            NotificationToggleRow(
                icon = Icons.Default.NotificationsActive,
                iconColor = Primary,
                title = "All Notifications",
                subtitle = "Receive push notifications",
                isEnabled = allNotifications,
                onToggle = { allNotifications = it }
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 2: Investment Alerts
        Text(
            text = "Investment Alerts",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        GlassCard(isDark, cardBackground, glassBorderBrush, cardShape) {
            NotificationToggleRow(
                icon = Icons.Default.ShowChart,
                iconColor = Color(0xFF3B82F6),
                title = "NAV Updates",
                subtitle = "Daily NAV changes for your holdings",
                isEnabled = navUpdates && allNotifications,
                onToggle = { navUpdates = it },
                enabled = allNotifications
            )
            NotificationDivider()
            NotificationToggleRow(
                icon = Icons.Default.Timer,
                iconColor = Color(0xFF06B6D4),
                title = "SIP Reminders",
                subtitle = "Upcoming SIP payment reminders",
                isEnabled = sipReminders && allNotifications,
                onToggle = { sipReminders = it },
                enabled = allNotifications
            )
            NotificationDivider()
            NotificationToggleRow(
                icon = Icons.Default.Flag,
                iconColor = Success,
                title = "Goal Milestones",
                subtitle = "Progress updates on your goals",
                isEnabled = goalMilestones && allNotifications,
                onToggle = { goalMilestones = it },
                enabled = allNotifications
            )
            NotificationDivider()
            NotificationToggleRow(
                icon = Icons.Default.TrendingUp,
                iconColor = Warning,
                title = "Market Alerts",
                subtitle = "Major market movements and events",
                isEnabled = marketAlerts && allNotifications,
                onToggle = { marketAlerts = it },
                enabled = allNotifications
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 3: Account & Security
        Text(
            text = "Account & Security",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        GlassCard(isDark, cardBackground, glassBorderBrush, cardShape) {
            NotificationToggleRow(
                icon = Icons.Default.Receipt,
                iconColor = Color(0xFF10B981),
                title = "Transaction Alerts",
                subtitle = "Buy, sell, and SIP confirmations",
                isEnabled = transactionAlerts && allNotifications,
                onToggle = { transactionAlerts = it },
                enabled = allNotifications
            )
            NotificationDivider()
            NotificationToggleRow(
                icon = Icons.Default.Security,
                iconColor = Color(0xFFEF4444),
                title = "Login Alerts",
                subtitle = "New device and suspicious login alerts",
                isEnabled = loginAlerts && allNotifications,
                onToggle = { loginAlerts = it },
                enabled = allNotifications
            )
            NotificationDivider()
            NotificationToggleRow(
                icon = Icons.Default.VerifiedUser,
                iconColor = Color(0xFF8B5CF6),
                title = "KYC Updates",
                subtitle = "Verification status changes",
                isEnabled = kycUpdates && allNotifications,
                onToggle = { kycUpdates = it },
                enabled = allNotifications
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 4: Recommendations
        Text(
            text = "Recommendations",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        GlassCard(isDark, cardBackground, glassBorderBrush, cardShape) {
            NotificationToggleRow(
                icon = Icons.Default.AutoAwesome,
                iconColor = Color(0xFF8B5CF6),
                title = "AI Insights",
                subtitle = "Personalized portfolio recommendations",
                isEnabled = aiInsights && allNotifications,
                onToggle = { aiInsights = it },
                enabled = allNotifications
            )
            NotificationDivider()
            NotificationToggleRow(
                icon = Icons.Default.FiberNew,
                iconColor = Color(0xFF2563EB),
                title = "New Fund Alerts",
                subtitle = "New fund launches matching your profile",
                isEnabled = newFundAlerts && allNotifications,
                onToggle = { newFundAlerts = it },
                enabled = allNotifications
            )
            NotificationDivider()
            NotificationToggleRow(
                icon = Icons.Default.CardGiftcard,
                iconColor = Color(0xFFF59E0B),
                title = "Offers & Rewards",
                subtitle = "Points, promotions, and special offers",
                isEnabled = offersRewards && allNotifications,
                onToggle = { offersRewards = it },
                enabled = allNotifications
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xLarge))
    }
}

@Composable
private fun GlassCard(
    isDark: Boolean,
    cardBackground: Color,
    glassBorderBrush: Brush,
    cardShape: RoundedCornerShape,
    content: @Composable () -> Unit
) {
    val modifier = if (isDark) {
        Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .clip(cardShape)
            .background(cardBackground)
            .border(1.dp, glassBorderBrush, cardShape)
    } else {
        Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .shadow(8.dp, cardShape, clip = false, ambientColor = ShadowColor, spotColor = ShadowColor)
            .clip(cardShape)
            .background(cardBackground)
            .border(1.dp, glassBorderBrush, cardShape)
    }

    Column(modifier = modifier) {
        content()
    }
}

@Composable
private fun NotificationToggleRow(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String,
    isEnabled: Boolean,
    onToggle: (Boolean) -> Unit,
    enabled: Boolean = true
) {
    val alpha = if (enabled) 1f else 0.4f

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Icon
        Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(CornerRadius.medium))
                .background(iconColor.copy(alpha = 0.15f * alpha)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconColor.copy(alpha = alpha),
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        // Text
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = alpha),
                fontWeight = FontWeight.Medium
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = alpha)
            )
        }

        // Switch
        Switch(
            checked = isEnabled,
            onCheckedChange = { if (enabled) onToggle(it) },
            enabled = enabled,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = Primary,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = MaterialTheme.colorScheme.surfaceVariant
            )
        )
    }
}

@Composable
private fun NotificationDivider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .height(1.dp)
            .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
    )
}
