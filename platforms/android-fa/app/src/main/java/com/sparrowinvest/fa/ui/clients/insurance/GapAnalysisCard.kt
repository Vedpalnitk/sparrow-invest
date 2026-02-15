package com.sparrowinvest.fa.ui.clients.insurance

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.sparrowinvest.fa.data.model.CoverageGap
import com.sparrowinvest.fa.data.model.GapAnalysisResponse
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.IconContainer
import com.sparrowinvest.fa.ui.theme.Primary
import com.sparrowinvest.fa.ui.theme.Success
import com.sparrowinvest.fa.ui.theme.Error
import com.sparrowinvest.fa.ui.theme.Spacing

@Composable
fun GapAnalysisCard(
    gapAnalysis: GapAnalysisResponse?,
    modifier: Modifier = Modifier
) {
    GlassCard(modifier = modifier) {
        Column(
            verticalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                IconContainer(
                    size = 32.dp,
                    backgroundColor = Primary.copy(alpha = 0.15f)
                ) {
                    Icon(
                        imageVector = Icons.Default.Shield,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = Primary
                    )
                }
                Text(
                    text = "Coverage Gap Analysis",
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            if (gapAnalysis != null) {
                CoverageBar(
                    label = "Life Insurance",
                    icon = Icons.Default.Shield,
                    gap = gapAnalysis.life
                )
                CoverageBar(
                    label = "Health Insurance",
                    icon = Icons.Default.Favorite,
                    gap = gapAnalysis.health
                )
            } else {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = Spacing.medium),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        strokeWidth = 2.dp,
                        color = Primary
                    )
                }
            }
        }
    }
}

@Composable
private fun CoverageBar(
    label: String,
    icon: ImageVector,
    gap: CoverageGap
) {
    val progress = if (gap.recommended > 0) (gap.current / gap.recommended).toFloat().coerceIn(0f, 1f) else 0f
    val barColor = if (gap.adequate) Success else Error

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(8.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
            .padding(Spacing.compact),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = barColor
                )
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            if (gap.adequate) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(2.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(12.dp),
                        tint = Success
                    )
                    Text(
                        text = "Adequate",
                        style = MaterialTheme.typography.labelSmall,
                        color = Success
                    )
                }
            } else {
                Text(
                    text = "Gap: ${formatAmount(gap.gap)}",
                    style = MaterialTheme.typography.labelSmall,
                    color = Error
                )
            }
        }

        // Progress bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp))
                .background(MaterialTheme.colorScheme.surfaceVariant)
        ) {
            Box(
                modifier = Modifier
                    .fillMaxWidth(fraction = progress)
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp))
                    .background(barColor)
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Current: ${formatAmount(gap.current)}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Recommended: ${formatAmount(gap.recommended)}",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private fun formatAmount(amount: Double): String = when {
    amount >= 10000000 -> "₹${"%.1f".format(amount / 10000000)} Cr"
    amount >= 100000 -> "₹${"%.1f".format(amount / 100000)} L"
    else -> "₹${"%,.0f".format(amount)}"
}
