package com.sparrowinvest.app.ui.points

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.Stars
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.PointsData
import com.sparrowinvest.app.data.model.RewardTier
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

@Composable
fun PointsScreen(
    viewModel: PointsViewModel = hiltViewModel(),
    onBackClick: () -> Unit
) {
    val pointsData by viewModel.points.collectAsState()

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding(),
        verticalArrangement = Arrangement.spacedBy(Spacing.large)
    ) {
        // Header
        item {
            PointsHeader(onBackClick = onBackClick)
        }

        // Tier Card
        item {
            TierCard(
                tier = pointsData.tier,
                formattedTotalPoints = viewModel.formattedTotalPoints,
                pointsToNextTier = viewModel.pointsToNextTier,
                progress = viewModel.progressToNextTier,
                modifier = Modifier.padding(horizontal = Spacing.medium)
            )
        }

        // Points Summary
        item {
            PointsSummarySection(
                formattedLifetimePoints = viewModel.formattedLifetimePoints,
                formattedExpiringPoints = viewModel.formattedExpiringPoints,
                expiryDate = pointsData.expiryDate,
                modifier = Modifier.padding(horizontal = Spacing.medium)
            )
        }

        // Tier Benefits
        item {
            TierBenefitsSection(
                tier = pointsData.tier,
                modifier = Modifier.padding(horizontal = Spacing.medium)
            )
        }

        // All Tiers
        item {
            AllTiersSection(
                currentTier = pointsData.tier,
                modifier = Modifier.padding(horizontal = Spacing.medium)
            )
        }

        // Bottom spacing
        item {
            Spacer(modifier = Modifier.height(Spacing.xxLarge))
        }
    }
}

// -- Header --

@Composable
private fun PointsHeader(onBackClick: () -> Unit) {
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
            text = "Points",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onSurface,
            fontWeight = FontWeight.Bold
        )
    }
}

// -- Section Header --

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelSmall,
        color = Primary,
        fontWeight = FontWeight.Medium,
        letterSpacing = 1.sp
    )
}

// -- Tier Card (Primary Glass Tile) --

@Composable
private fun TierCard(
    tier: RewardTier,
    formattedTotalPoints: String,
    pointsToNextTier: Int,
    progress: Float,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.xLarge)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = if (isDark) {
        Brush.linearGradient(listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark))
    } else {
        Brush.linearGradient(listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight))
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (!isDark) Modifier.shadow(12.dp, shape, ambientColor = ShadowColor, spotColor = ShadowColor)
                else Modifier
            )
            .clip(shape)
            .background(backgroundColor)
            .border(1.dp, borderBrush, shape)
            .padding(Spacing.medium)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.medium)) {
            // Tier icon and name
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(RoundedCornerShape(10.dp))
                        .background(tier.tierColor.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = tierIcon(tier),
                        contentDescription = tier.displayName,
                        tint = tier.tierColor,
                        modifier = Modifier.size(20.dp)
                    )
                }

                Spacer(modifier = Modifier.width(Spacing.compact))

                Column {
                    Text(
                        text = tier.displayName,
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "Member",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Total points
            Row(
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = formattedTotalPoints,
                    style = MaterialTheme.typography.displaySmall.copy(
                        fontWeight = FontWeight.Light
                    ),
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "points",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(bottom = 4.dp)
                )
            }

            // Progress to next tier
            val nextTier = tier.nextTier
            if (nextTier != null) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = "${formatNumber(pointsToNextTier)} points to ${nextTier.displayName}",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    // Progress bar
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp)
                            .clip(RoundedCornerShape(3.dp))
                            .background(tier.tierColor.copy(alpha = 0.2f))
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(fraction = progress)
                                .fillMaxHeight()
                                .clip(RoundedCornerShape(3.dp))
                                .background(
                                    Brush.horizontalGradient(
                                        colors = listOf(tier.tierColor, nextTier.tierColor)
                                    )
                                )
                        )
                    }
                }
            }
        }
    }
}

// -- Points Summary Section --

@Composable
private fun PointsSummarySection(
    formattedLifetimePoints: String,
    formattedExpiringPoints: String,
    expiryDate: String?,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        SectionHeader(title = "SUMMARY")

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            SummaryTile(
                title = "Lifetime",
                value = formattedLifetimePoints,
                icon = Icons.Default.ShowChart,
                iconColor = Color(0xFF3B82F6),
                modifier = Modifier.weight(1f)
            )

            if (expiryDate != null) {
                SummaryTile(
                    title = "Expiring",
                    value = formattedExpiringPoints,
                    subtitle = "by $expiryDate",
                    icon = Icons.Default.AccessTime,
                    iconColor = Color(0xFFF59E0B),
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun SummaryTile(
    title: String,
    value: String,
    subtitle: String? = null,
    icon: ImageVector,
    iconColor: Color,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.xLarge)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = if (isDark) {
        Brush.linearGradient(listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark))
    } else {
        Brush.linearGradient(listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight))
    }

    Column(
        modifier = modifier
            .then(
                if (!isDark) Modifier.shadow(8.dp, shape, ambientColor = ShadowColor, spotColor = ShadowColor)
                else Modifier
            )
            .clip(shape)
            .background(backgroundColor)
            .border(1.dp, borderBrush, shape)
            .padding(Spacing.compact),
        verticalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        // Icon and title row
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(28.dp)
                    .clip(RoundedCornerShape(6.dp))
                    .background(iconColor.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconColor,
                    modifier = Modifier.size(14.dp)
                )
            }

            Text(
                text = title,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Value
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium.copy(
                fontWeight = FontWeight.Light
            ),
            color = MaterialTheme.colorScheme.onSurface
        )

        // Subtitle (e.g., expiry date)
        if (subtitle != null) {
            Text(
                text = subtitle,
                style = MaterialTheme.typography.labelSmall,
                color = iconColor
            )
        }
    }
}

// -- Tier Benefits Section --

@Composable
private fun TierBenefitsSection(
    tier: RewardTier,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.xLarge)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = if (isDark) {
        Brush.linearGradient(listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark))
    } else {
        Brush.linearGradient(listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight))
    }

    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        SectionHeader(title = "${tier.displayName.uppercase()} BENEFITS")

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (!isDark) Modifier.shadow(12.dp, shape, ambientColor = ShadowColor, spotColor = ShadowColor)
                    else Modifier
                )
                .clip(shape)
                .background(backgroundColor)
                .border(1.dp, borderBrush, shape)
        ) {
            tier.benefits.forEachIndexed { index, benefit ->
                BenefitRow(
                    benefit = benefit,
                    tierColor = tier.tierColor
                )

                if (index < tier.benefits.size - 1) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 50.dp),
                        color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                    )
                }
            }
        }
    }
}

@Composable
private fun BenefitRow(
    benefit: String,
    tierColor: Color
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.compact, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Box(
            modifier = Modifier
                .size(26.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(tierColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Check,
                contentDescription = null,
                tint = tierColor,
                modifier = Modifier.size(14.dp)
            )
        }

        Text(
            text = benefit,
            style = MaterialTheme.typography.bodyMedium.copy(
                fontWeight = FontWeight.Light
            ),
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

// -- All Tiers Section --

@Composable
private fun AllTiersSection(
    currentTier: RewardTier,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.xLarge)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = if (isDark) {
        Brush.linearGradient(listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark))
    } else {
        Brush.linearGradient(listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight))
    }

    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        SectionHeader(title = "ALL TIERS")

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (!isDark) Modifier.shadow(12.dp, shape, ambientColor = ShadowColor, spotColor = ShadowColor)
                    else Modifier
                )
                .clip(shape)
                .background(backgroundColor)
                .border(1.dp, borderBrush, shape)
        ) {
            val allTiers = RewardTier.entries
            allTiers.forEachIndexed { index, tier ->
                val isCurrentTier = tier == currentTier

                TierRow(
                    tier = tier,
                    isCurrentTier = isCurrentTier
                )

                if (index < allTiers.size - 1) {
                    HorizontalDivider(
                        modifier = Modifier.padding(start = 52.dp),
                        color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f)
                    )
                }
            }
        }
    }
}

@Composable
private fun TierRow(
    tier: RewardTier,
    isCurrentTier: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (isCurrentTier) Modifier.background(tier.tierColor.copy(alpha = 0.05f))
                else Modifier
            )
            .padding(horizontal = Spacing.compact, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        // Tier icon
        Box(
            modifier = Modifier
                .size(26.dp)
                .clip(RoundedCornerShape(6.dp))
                .background(tier.tierColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = tierIcon(tier),
                contentDescription = null,
                tint = tier.tierColor,
                modifier = Modifier.size(14.dp)
            )
        }

        // Name and points
        Column(modifier = Modifier.weight(1f)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(5.dp)
            ) {
                Text(
                    text = tier.displayName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = if (isCurrentTier) FontWeight.Medium else FontWeight.Normal
                )

                if (isCurrentTier) {
                    Text(
                        text = "Current",
                        style = MaterialTheme.typography.labelSmall.copy(
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Medium
                        ),
                        color = Color.White,
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(tier.tierColor)
                            .padding(horizontal = 5.dp, vertical = 2.dp)
                    )
                }
            }

            Text(
                text = if (tier.minPoints == 0) "Starting tier" else "${formatNumber(tier.minPoints)}+ points",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Benefits count
        Text(
            text = "${tier.benefits.size} benefits",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )
    }
}

// -- Utility functions --

/**
 * Returns the appropriate Material icon for each reward tier.
 */
private fun tierIcon(tier: RewardTier): ImageVector {
    return when (tier) {
        RewardTier.BRONZE -> Icons.Default.StarBorder
        RewardTier.SILVER -> Icons.Default.Star
        RewardTier.GOLD -> Icons.Default.Stars
        RewardTier.PLATINUM -> Icons.Default.AutoAwesome
    }
}

/**
 * Formats a number with Indian locale grouping.
 */
private fun formatNumber(value: Int): String {
    return java.text.NumberFormat.getNumberInstance(java.util.Locale("en", "IN")).format(value)
}
