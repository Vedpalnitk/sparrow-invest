package com.sparrowinvest.app.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.Analytics
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.Info
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.PrimaryDark
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning

private data class CacheCategory(
    val name: String,
    val subtitle: String,
    val icon: ImageVector,
    val iconColor: Color,
    val initialSize: String
)

@Composable
fun CacheManagementScreen(
    onBackClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current

    // Cache sizes state
    var fundDataSize by remember { mutableStateOf("12.3 MB") }
    var portfolioSize by remember { mutableStateOf("8.7 MB") }
    var imageSize by remember { mutableStateOf("15.2 MB") }
    var analyticsSize by remember { mutableStateOf("9.0 MB") }
    var totalUsed by remember { mutableStateOf(45.2f) }
    var showClearAllDialog by remember { mutableStateOf(false) }
    var showDeleteDataDialog by remember { mutableStateOf(false) }

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
                text = "Storage & Cache",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 1: Storage Overview
        val overviewModifier = if (isDark) {
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

        Column(
            modifier = overviewModifier.then(Modifier.padding(Spacing.large)),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Circular progress ring
            val totalCapacity = 100f
            val usedFraction = totalUsed / totalCapacity
            val primaryColor = Primary
            val trackColor = MaterialTheme.colorScheme.surfaceVariant

            Box(
                modifier = Modifier.size(160.dp),
                contentAlignment = Alignment.Center
            ) {
                androidx.compose.foundation.Canvas(
                    modifier = Modifier.size(160.dp)
                ) {
                    val strokeWidth = 14.dp.toPx()
                    val arcSize = Size(size.width - strokeWidth, size.height - strokeWidth)
                    val topLeft = Offset(strokeWidth / 2, strokeWidth / 2)

                    // Background track
                    drawArc(
                        color = trackColor,
                        startAngle = -90f,
                        sweepAngle = 360f,
                        useCenter = false,
                        topLeft = topLeft,
                        size = arcSize,
                        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                    )

                    // Used arc
                    drawArc(
                        color = primaryColor,
                        startAngle = -90f,
                        sweepAngle = 360f * usedFraction,
                        useCenter = false,
                        topLeft = topLeft,
                        size = arcSize,
                        style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                    )
                }

                // Center text
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = if (totalUsed > 0) String.format("%.1f MB", totalUsed) else "0 MB",
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "Used",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.small))

            Text(
                text = "Total app storage",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 2: Cache Breakdown
        Text(
            text = "Cache Breakdown",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        val breakdownModifier = if (isDark) {
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

        Column(modifier = breakdownModifier) {
            CacheCategoryItem(
                icon = Icons.Default.ShowChart,
                iconColor = Primary,
                title = "Fund Data Cache",
                subtitle = "NAV data, fund details",
                size = fundDataSize,
                onClear = {
                    fundDataSize = "0 MB"
                    totalUsed = (totalUsed - 12.3f).coerceAtLeast(0f)
                }
            )

            CacheDivider()

            CacheCategoryItem(
                icon = Icons.Default.AccountBalance,
                iconColor = Success,
                title = "Portfolio Cache",
                subtitle = "Holdings, transactions",
                size = portfolioSize,
                onClear = {
                    portfolioSize = "0 MB"
                    totalUsed = (totalUsed - 8.7f).coerceAtLeast(0f)
                }
            )

            CacheDivider()

            CacheCategoryItem(
                icon = Icons.Default.Image,
                iconColor = Info,
                title = "Image Cache",
                subtitle = "Fund logos, charts",
                size = imageSize,
                onClear = {
                    imageSize = "0 MB"
                    totalUsed = (totalUsed - 15.2f).coerceAtLeast(0f)
                }
            )

            CacheDivider()

            CacheCategoryItem(
                icon = Icons.Default.Analytics,
                iconColor = Warning,
                title = "Analytics Cache",
                subtitle = "AI insights, analysis",
                size = analyticsSize,
                onClear = {
                    analyticsSize = "0 MB"
                    totalUsed = (totalUsed - 9.0f).coerceAtLeast(0f)
                }
            )
        }

        Spacer(modifier = Modifier.height(Spacing.large))

        // Section 3: Actions
        // Clear All Cache gradient button
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .height(52.dp)
                .clip(RoundedCornerShape(CornerRadius.large))
                .background(
                    Brush.linearGradient(
                        colors = listOf(Primary, PrimaryDark)
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            androidx.compose.material3.Surface(
                onClick = { showClearAllDialog = true },
                modifier = Modifier.fillMaxSize(),
                color = Color.Transparent,
                shape = RoundedCornerShape(CornerRadius.large)
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(Spacing.small))
                        Text(
                            text = "Clear All Cache",
                            style = MaterialTheme.typography.bodyLarge,
                            color = Color.White,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.compact))

        // Clear All Data button (error outline)
        OutlinedButton(
            onClick = { showDeleteDataDialog = true },
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .height(52.dp),
            shape = RoundedCornerShape(CornerRadius.large),
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = Error
            ),
            border = androidx.compose.foundation.BorderStroke(1.5.dp, Error)
        ) {
            Text(
                text = "Clear All Data",
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xLarge))
    }

    // Clear All Cache confirmation dialog
    if (showClearAllDialog) {
        AlertDialog(
            onDismissRequest = { showClearAllDialog = false },
            title = {
                Text(
                    text = "Clear All Cache",
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Text("Are you sure? This will clear all cached data. You'll need to re-download fund data.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        fundDataSize = "0 MB"
                        portfolioSize = "0 MB"
                        imageSize = "0 MB"
                        analyticsSize = "0 MB"
                        totalUsed = 0f
                        showClearAllDialog = false
                    }
                ) {
                    Text("Clear", color = Error, fontWeight = FontWeight.SemiBold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearAllDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    // Clear All Data confirmation dialog
    if (showDeleteDataDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDataDialog = false },
            title = {
                Text(
                    text = "Clear All Data",
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Text("This will delete all app data including your preferences and cached content. This action cannot be undone.")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        fundDataSize = "0 MB"
                        portfolioSize = "0 MB"
                        imageSize = "0 MB"
                        analyticsSize = "0 MB"
                        totalUsed = 0f
                        showDeleteDataDialog = false
                    }
                ) {
                    Text("Delete All", color = Error, fontWeight = FontWeight.SemiBold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDataDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun CacheCategoryItem(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String,
    size: String,
    onClear: () -> Unit
) {
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
                .background(iconColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconColor,
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        // Text
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Size
        Text(
            text = size,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(end = Spacing.small)
        )

        // Clear button
        TextButton(
            onClick = onClear,
            enabled = size != "0 MB"
        ) {
            Text(
                text = "Clear",
                style = MaterialTheme.typography.bodySmall,
                color = if (size != "0 MB") Primary else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
private fun CacheDivider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .height(1.dp)
            .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
    )
}
