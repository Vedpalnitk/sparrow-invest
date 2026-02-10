package com.sparrowinvest.app.ui.onboarding

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.scaleIn
import androidx.compose.foundation.background
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
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sparrowinvest.app.ui.components.GlassCard
import com.sparrowinvest.app.ui.components.PrimaryButton
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning
import kotlinx.coroutines.delay

// Risk category configuration
private data class RiskCategoryConfig(
    val title: String,
    val description: String,
    val color: Color,
    val gradientColors: List<Color>,
    val suitableFunds: List<String>,
    val scoreRange: String
)

private fun getCategoryConfig(category: String): RiskCategoryConfig {
    return when (category.lowercase()) {
        "conservative" -> RiskCategoryConfig(
            title = "Conservative",
            description = "You prefer stability and capital preservation over high returns. " +
                    "A conservative approach focuses on minimizing risk with steady, " +
                    "predictable growth.",
            color = Success,
            gradientColors = listOf(Success, Color(0xFF34D399)),
            suitableFunds = listOf(
                "Liquid Funds",
                "Ultra Short Duration Funds",
                "Short Duration Debt Funds",
                "Banking & PSU Funds",
                "Corporate Bond Funds"
            ),
            scoreRange = "5-9"
        )
        "moderate" -> RiskCategoryConfig(
            title = "Moderate",
            description = "You seek a balance between growth and stability. " +
                    "A moderate approach combines equity and debt for " +
                    "consistent, balanced returns.",
            color = Primary,
            gradientColors = listOf(Primary, Secondary),
            suitableFunds = listOf(
                "Balanced Advantage Funds",
                "Hybrid Equity Funds",
                "Large Cap Funds",
                "Index Funds",
                "ELSS Tax Saver Funds"
            ),
            scoreRange = "10-14"
        )
        else -> RiskCategoryConfig(
            title = "Aggressive",
            description = "You are comfortable with market volatility and aim for " +
                    "maximum long-term growth. An aggressive approach invests " +
                    "primarily in equities for higher potential returns.",
            color = Warning,
            gradientColors = listOf(Warning, Color(0xFFF97316)),
            suitableFunds = listOf(
                "Small Cap Funds",
                "Mid Cap Funds",
                "Sectoral/Thematic Funds",
                "Flexi Cap Funds",
                "International Equity Funds"
            ),
            scoreRange = "15-20"
        )
    }
}

@Composable
fun RiskResultScreen(
    category: String,
    score: Int,
    onContinue: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    val config = remember(category) { getCategoryConfig(category) }
    var showContent by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        delay(200)
        showContent = true
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
    ) {
        Spacer(modifier = Modifier.height(Spacing.xxLarge))

        // Animated result content
        AnimatedVisibility(
            visible = showContent,
            enter = fadeIn(animationSpec = tween(500)) + scaleIn(
                animationSpec = tween(500),
                initialScale = 0.8f
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.large),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Top label
                Text(
                    text = "YOUR RISK PROFILE",
                    style = MaterialTheme.typography.labelMedium.copy(
                        letterSpacing = 2.sp
                    ),
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(Spacing.xLarge))

                // Color-coded circle with score
                Box(
                    modifier = Modifier
                        .size(140.dp)
                        .clip(CircleShape)
                        .background(
                            brush = Brush.linearGradient(
                                colors = config.gradientColors.map { it.copy(alpha = 0.15f) }
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Box(
                        modifier = Modifier
                            .size(110.dp)
                            .clip(CircleShape)
                            .background(
                                brush = Brush.linearGradient(
                                    colors = config.gradientColors
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = "$score",
                                style = MaterialTheme.typography.headlineLarge.copy(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 36.sp
                                ),
                                color = Color.White
                            )
                            Text(
                                text = "/ 20",
                                style = MaterialTheme.typography.labelMedium,
                                color = Color.White.copy(alpha = 0.8f)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(Spacing.xLarge))

                // Category name
                Text(
                    text = config.title,
                    style = MaterialTheme.typography.headlineLarge.copy(
                        fontWeight = FontWeight.Bold
                    ),
                    color = config.color
                )

                Spacer(modifier = Modifier.height(Spacing.compact))

                // Score range
                Text(
                    text = "Score range: ${config.scoreRange}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(Spacing.large))

                // Description card
                GlassCard(
                    cornerRadius = CornerRadius.xLarge,
                    contentPadding = Spacing.medium
                ) {
                    Column {
                        Text(
                            text = "What this means",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )

                        Spacer(modifier = Modifier.height(Spacing.small))

                        Text(
                            text = config.description,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 22.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(Spacing.medium))

                // Suitable fund types card
                GlassCard(
                    cornerRadius = CornerRadius.xLarge,
                    contentPadding = Spacing.medium
                ) {
                    Column {
                        Text(
                            text = "Suitable Fund Types",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )

                        Spacer(modifier = Modifier.height(Spacing.compact))

                        config.suitableFunds.forEach { fund ->
                            FundTypeRow(
                                text = fund,
                                color = config.color,
                                isDark = isDark
                            )
                            if (fund != config.suitableFunds.last()) {
                                Spacer(modifier = Modifier.height(Spacing.small))
                            }
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        // Continue button
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.large)
                .padding(bottom = Spacing.xxLarge)
        ) {
            PrimaryButton(
                text = "Continue",
                onClick = onContinue
            )

            Spacer(modifier = Modifier.height(Spacing.small))

            Text(
                text = "You can update your risk profile anytime from Settings",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun FundTypeRow(
    text: String,
    color: Color,
    isDark: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(
                if (isDark) color.copy(alpha = 0.08f)
                else color.copy(alpha = 0.05f)
            )
            .padding(horizontal = Spacing.compact, vertical = Spacing.compact),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Small colored dot
        Box(
            modifier = Modifier
                .size(8.dp)
                .clip(CircleShape)
                .background(color)
        )

        Spacer(modifier = Modifier.width(Spacing.compact))

        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium.copy(
                fontWeight = FontWeight.Medium
            ),
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}
