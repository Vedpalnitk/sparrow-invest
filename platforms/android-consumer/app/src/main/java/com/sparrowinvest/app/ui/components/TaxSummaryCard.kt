package com.sparrowinvest.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Receipt
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.data.model.TaxSummary
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GradientEndCyan
import com.sparrowinvest.app.ui.theme.GradientStartBlue
import com.sparrowinvest.app.ui.theme.Info
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Error
import java.util.Locale

@Composable
fun TaxSummaryCard(
    taxSummary: TaxSummary,
    modifier: Modifier = Modifier,
    onViewDetails: () -> Unit = {}
) {
    val isDark = LocalIsDarkTheme.current

    GlassCard(modifier = modifier) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(32.dp)
                            .clip(RoundedCornerShape(CornerRadius.small))
                            .background(Info.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Receipt,
                            contentDescription = null,
                            tint = Info,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(Spacing.small))
                    Column {
                        Text(
                            text = "Tax Summary",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = taxSummary.financialYear,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable(onClick = onViewDetails)
                ) {
                    Text(
                        text = "Details",
                        style = MaterialTheme.typography.labelMedium,
                        color = Primary
                    )
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                        contentDescription = null,
                        tint = Primary,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Capital Gains Section - LTCG and STCG side by side
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
            ) {
                // LTCG Card
                CapitalGainItem(
                    label = "LTCG",
                    amount = taxSummary.totalLTCG,
                    taxLiability = taxSummary.ltcgTaxLiability,
                    tintColor = Success,
                    isDark = isDark,
                    modifier = Modifier.weight(1f)
                )

                // STCG Card
                CapitalGainItem(
                    label = "STCG",
                    amount = taxSummary.totalSTCG,
                    taxLiability = taxSummary.stcgTaxLiability,
                    tintColor = Primary,
                    isDark = isDark,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // 80C ELSS Progress Section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(CornerRadius.medium))
                    .background(
                        if (isDark) Color.White.copy(alpha = 0.06f)
                        else MaterialTheme.colorScheme.surfaceVariant
                    )
                    .padding(Spacing.compact)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "80C ELSS Progress",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = String.format(Locale.US, "%.0f%%", taxSummary.elss80CProgress * 100),
                        style = MaterialTheme.typography.labelMedium,
                        color = Primary
                    )
                }

                Spacer(modifier = Modifier.height(Spacing.small))

                // Progress Bar
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(RoundedCornerShape(4.dp))
                        .background(
                            if (isDark) Color.White.copy(alpha = 0.1f)
                            else Color(0xFFE5E7EB)
                        )
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(fraction = taxSummary.elss80CProgress.toFloat().coerceIn(0f, 1f))
                            .height(8.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(
                                Brush.horizontalGradient(
                                    colors = listOf(GradientStartBlue, GradientEndCyan)
                                )
                            )
                    )
                }

                Spacer(modifier = Modifier.height(Spacing.small))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Text(
                            text = "Tax Saved",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = formatCompactCurrency(taxSummary.totalTaxSaved),
                            style = MaterialTheme.typography.bodyMedium,
                            color = Success
                        )
                    }
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "Remaining",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = formatCompactCurrency(taxSummary.elss80CRemaining),
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun CapitalGainItem(
    label: String,
    amount: Double,
    taxLiability: Double,
    tintColor: Color,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    val amountColor = if (amount >= 0) Success else Error

    Column(
        modifier = modifier
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(tintColor.copy(alpha = if (isDark) 0.08f else 0.05f))
            .padding(Spacing.compact)
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = tintColor
        )

        Spacer(modifier = Modifier.height(Spacing.micro))

        Text(
            text = formatCompactCurrency(amount),
            style = MaterialTheme.typography.titleMedium,
            color = amountColor
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Text(
            text = "Tax Liability",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Text(
            text = formatCompactCurrency(taxLiability),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}
