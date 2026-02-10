package com.sparrowinvest.app.ui.profile

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
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
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.RiskCategory
import com.sparrowinvest.app.ui.components.PrimaryButton
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
import com.sparrowinvest.app.ui.theme.Success

private data class RiskFactor(
    val name: String,
    val score: Int,
    val maxScore: Int = 10
)

private data class AssetAllocation(
    val assetClass: String,
    val percentage: Int,
    val color: Color
)

@Composable
fun RiskProfileScreen(
    onBackClick: () -> Unit,
    onRetakeAssessment: () -> Unit,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val currentUser by viewModel.currentUser.collectAsState()
    val isDark = LocalIsDarkTheme.current

    val riskProfile = currentUser?.riskProfile
    val riskCategory = riskProfile?.category ?: RiskCategory.MODERATE
    val riskScore = riskProfile?.score ?: 6
    val assessedDate = riskProfile?.assessedAt ?: "Jan 15, 2026"

    val categoryColor = when (riskCategory) {
        RiskCategory.CONSERVATIVE -> Success
        RiskCategory.MODERATELY_CONSERVATIVE -> Color(0xFF06B6D4)
        RiskCategory.MODERATE -> Primary
        RiskCategory.MODERATELY_AGGRESSIVE -> Color(0xFFF59E0B)
        RiskCategory.AGGRESSIVE -> Color(0xFFEF4444)
    }

    val categoryDescription = when (riskCategory) {
        RiskCategory.CONSERVATIVE -> "You prefer stability and capital preservation over high returns. Suitable for short-term goals and risk-averse investors."
        RiskCategory.MODERATELY_CONSERVATIVE -> "You lean towards safety but are open to some growth. A balanced approach with more weight on debt."
        RiskCategory.MODERATE -> "You seek a balance between growth and stability. Comfortable with moderate market fluctuations for better returns."
        RiskCategory.MODERATELY_AGGRESSIVE -> "You are willing to take higher risks for potentially higher returns. Comfortable with market volatility."
        RiskCategory.AGGRESSIVE -> "You seek maximum growth and are comfortable with significant market fluctuations. Suitable for long-term goals."
    }

    val riskFactors = listOf(
        RiskFactor("Investment Horizon", 8),
        RiskFactor("Loss Tolerance", 6),
        RiskFactor("Income Stability", 7),
        RiskFactor("Investment Experience", 5)
    )

    val equityColor = Color(0xFF3B82F6)
    val debtColor = Color(0xFF10B981)
    val goldColor = Color(0xFFF59E0B)
    val cashColor = Color(0xFF9CA3AF)

    val allocations = when (riskCategory) {
        RiskCategory.CONSERVATIVE -> listOf(
            AssetAllocation("Equity", 20, equityColor),
            AssetAllocation("Debt", 55, debtColor),
            AssetAllocation("Gold", 15, goldColor),
            AssetAllocation("Cash", 10, cashColor)
        )
        RiskCategory.MODERATELY_CONSERVATIVE -> listOf(
            AssetAllocation("Equity", 35, equityColor),
            AssetAllocation("Debt", 40, debtColor),
            AssetAllocation("Gold", 15, goldColor),
            AssetAllocation("Cash", 10, cashColor)
        )
        RiskCategory.MODERATE -> listOf(
            AssetAllocation("Equity", 60, equityColor),
            AssetAllocation("Debt", 25, debtColor),
            AssetAllocation("Gold", 10, goldColor),
            AssetAllocation("Cash", 5, cashColor)
        )
        RiskCategory.MODERATELY_AGGRESSIVE -> listOf(
            AssetAllocation("Equity", 75, equityColor),
            AssetAllocation("Debt", 15, debtColor),
            AssetAllocation("Gold", 7, goldColor),
            AssetAllocation("Cash", 3, cashColor)
        )
        RiskCategory.AGGRESSIVE -> listOf(
            AssetAllocation("Equity", 85, equityColor),
            AssetAllocation("Debt", 8, debtColor),
            AssetAllocation("Gold", 5, goldColor),
            AssetAllocation("Cash", 2, cashColor)
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
    ) {
        // Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
            Text(
                text = "Risk Profile",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f)
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.medium)
        ) {
            Spacer(modifier = Modifier.height(Spacing.medium))

            // Section 1: Current Risk Profile
            RiskGlassCard(isDark = isDark) {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Risk category badge
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(CornerRadius.medium))
                            .background(categoryColor.copy(alpha = 0.12f))
                            .padding(horizontal = Spacing.medium, vertical = Spacing.small)
                    ) {
                        Text(
                            text = riskCategory.displayName,
                            style = MaterialTheme.typography.titleMedium,
                            color = categoryColor,
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    Spacer(modifier = Modifier.height(Spacing.large))

                    // Animated risk score circle
                    RiskScoreCircle(
                        score = riskScore,
                        maxScore = 10,
                        color = categoryColor
                    )

                    Spacer(modifier = Modifier.height(Spacing.medium))

                    Text(
                        text = categoryDescription,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = Spacing.small)
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    Text(
                        text = "Your risk profile was assessed on $assessedDate",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Section 2: Risk Breakdown
            RiskGlassCard(isDark = isDark) {
                Text(
                    text = "RISK BREAKDOWN",
                    style = MaterialTheme.typography.labelSmall,
                    color = Primary,
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(Spacing.medium))

                riskFactors.forEachIndexed { index, factor ->
                    RiskFactorRow(
                        factor = factor,
                        color = categoryColor
                    )
                    if (index < riskFactors.lastIndex) {
                        Spacer(modifier = Modifier.height(Spacing.compact))
                    }
                }
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Section 3: Asset Allocation Recommendation
            RiskGlassCard(isDark = isDark) {
                Text(
                    text = "RECOMMENDED ASSET ALLOCATION",
                    style = MaterialTheme.typography.labelSmall,
                    color = Primary,
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(Spacing.medium))

                // Stacked horizontal bar
                StackedAllocationBar(allocations = allocations)

                Spacer(modifier = Modifier.height(Spacing.medium))

                // Legend items
                allocations.forEach { allocation ->
                    AllocationLegendItem(allocation = allocation)
                    Spacer(modifier = Modifier.height(Spacing.small))
                }
            }

            Spacer(modifier = Modifier.height(Spacing.xLarge))

            // CTA Button
            PrimaryButton(
                text = "Retake Risk Assessment",
                onClick = onRetakeAssessment,
                modifier = Modifier.padding(bottom = Spacing.medium)
            )

            Spacer(modifier = Modifier.height(Spacing.large))
        }
    }
}

@Composable
private fun RiskGlassCard(
    isDark: Boolean,
    content: @Composable () -> Unit
) {
    val shape = RoundedCornerShape(CornerRadius.xLarge)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = if (isDark) {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (!isDark) {
                    Modifier.shadow(
                        elevation = 12.dp,
                        shape = shape,
                        spotColor = ShadowColor,
                        ambientColor = ShadowColor
                    )
                } else Modifier
            )
            .clip(shape)
            .background(backgroundColor)
            .border(width = 1.dp, brush = borderBrush, shape = shape)
            .padding(Spacing.medium)
    ) {
        content()
    }
}

@Composable
private fun RiskScoreCircle(
    score: Int,
    maxScore: Int,
    color: Color
) {
    var targetProgress by remember { mutableFloatStateOf(0f) }
    val animatedProgress by animateFloatAsState(
        targetValue = targetProgress,
        animationSpec = tween(durationMillis = 1200),
        label = "riskScore"
    )

    LaunchedEffect(score) {
        targetProgress = score.toFloat() / maxScore.toFloat()
    }

    val trackColor = color.copy(alpha = 0.15f)

    Box(
        modifier = Modifier.size(140.dp),
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.size(140.dp)) {
            val strokeWidth = 12.dp.toPx()
            val radius = (size.minDimension - strokeWidth) / 2
            val topLeft = Offset(
                (size.width - radius * 2) / 2,
                (size.height - radius * 2) / 2
            )
            val arcSize = Size(radius * 2, radius * 2)

            // Track
            drawArc(
                color = trackColor,
                startAngle = -225f,
                sweepAngle = 270f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )

            // Progress
            drawArc(
                color = color,
                startAngle = -225f,
                sweepAngle = 270f * animatedProgress,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )
        }

        // Score text in center
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "$score",
                style = MaterialTheme.typography.headlineLarge,
                color = color,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "out of $maxScore",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun RiskFactorRow(
    factor: RiskFactor,
    color: Color
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = factor.name,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = "${factor.score}/${factor.maxScore}",
                style = MaterialTheme.typography.labelMedium,
                color = color,
                fontWeight = FontWeight.SemiBold
            )
        }

        Spacer(modifier = Modifier.height(Spacing.small))

        LinearProgressIndicator(
            progress = { factor.score.toFloat() / factor.maxScore.toFloat() },
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(CircleShape),
            color = color,
            trackColor = color.copy(alpha = 0.15f),
            strokeCap = StrokeCap.Round
        )
    }
}

@Composable
private fun StackedAllocationBar(
    allocations: List<AssetAllocation>
) {
    val totalPercentage = allocations.sumOf { it.percentage }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(24.dp)
            .clip(RoundedCornerShape(CornerRadius.medium))
    ) {
        allocations.forEach { allocation ->
            val weight = allocation.percentage.toFloat() / totalPercentage.toFloat()
            Box(
                modifier = Modifier
                    .weight(weight)
                    .height(24.dp)
                    .background(allocation.color),
                contentAlignment = Alignment.Center
            ) {
                if (allocation.percentage >= 10) {
                    Text(
                        text = "${allocation.percentage}%",
                        style = MaterialTheme.typography.labelSmall,
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 9.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun AllocationLegendItem(
    allocation: AssetAllocation
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Color dot
        Box(
            modifier = Modifier
                .size(10.dp)
                .clip(CircleShape)
                .background(allocation.color)
        )

        Spacer(modifier = Modifier.width(Spacing.compact))

        Text(
            text = allocation.assetClass,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )

        Text(
            text = "${allocation.percentage}%",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface,
            fontWeight = FontWeight.SemiBold
        )
    }
}
