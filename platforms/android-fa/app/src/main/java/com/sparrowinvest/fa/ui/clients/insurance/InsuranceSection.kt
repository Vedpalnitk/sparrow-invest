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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sparrowinvest.fa.data.model.GapAnalysisResponse
import com.sparrowinvest.fa.data.model.InsurancePolicy
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.IconContainer
import com.sparrowinvest.fa.ui.components.StatusBadge
import com.sparrowinvest.fa.ui.theme.Error
import com.sparrowinvest.fa.ui.theme.Info
import com.sparrowinvest.fa.ui.theme.Primary
import com.sparrowinvest.fa.ui.theme.Spacing
import com.sparrowinvest.fa.ui.theme.Success
import com.sparrowinvest.fa.ui.theme.Warning

fun LazyListScope.insuranceTabContent(
    policies: List<InsurancePolicy>,
    gapAnalysis: GapAnalysisResponse?,
    onAddClick: () -> Unit,
    onDeleteClick: (String) -> Unit
) {
    // Gap Analysis Card
    item {
        GapAnalysisCard(gapAnalysis = gapAnalysis)
    }

    // Header
    item {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Insurance Policies (${policies.size})",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface
            )
            TextButton(onClick = onAddClick) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = Primary
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text("Add Policy", color = Primary, style = MaterialTheme.typography.labelMedium)
            }
        }
    }

    if (policies.isEmpty()) {
        item {
            GlassCard {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = Spacing.large),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(Spacing.small)
                ) {
                    Icon(
                        imageVector = Icons.Default.Shield,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                    )
                    Text(
                        text = "No insurance policies",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "Tap \"Add Policy\" to record coverage",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                    )
                }
            }
        }
    } else {
        policies.forEach { policy ->
            item(key = policy.id) {
                PolicyCard(policy = policy, onDelete = { onDeleteClick(policy.id) })
            }
        }
    }
}

@Composable
private fun PolicyCard(
    policy: InsurancePolicy,
    onDelete: () -> Unit
) {
    val accentColor = when {
        policy.isLifeCover -> Primary
        policy.isHealthCover -> Success
        else -> Warning
    }

    val statusColor = when (policy.status) {
        "ACTIVE" -> Success
        "LAPSED" -> Error
        "SURRENDERED" -> Warning
        "MATURED" -> Info
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    GlassCard {
        Column(
            verticalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            // Header row
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
            ) {
                // Type icon
                IconContainer(
                    size = 36.dp,
                    backgroundColor = accentColor.copy(alpha = 0.15f)
                ) {
                    Icon(
                        imageVector = when {
                            policy.isLifeCover -> Icons.Default.Shield
                            policy.isHealthCover -> Icons.Default.Favorite
                            else -> Icons.Default.TrendingUp
                        },
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = accentColor
                    )
                }

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = policy.provider,
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = policy.typeLabel,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                StatusBadge(
                    text = policy.status.lowercase().replaceFirstChar { it.uppercase() },
                    color = statusColor
                )

                IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                    Icon(
                        imageVector = Icons.Default.Delete,
                        contentDescription = "Delete",
                        modifier = Modifier.size(16.dp),
                        tint = Error.copy(alpha = 0.7f)
                    )
                }
            }

            // Details row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                DetailItem(label = "Sum Assured", value = policy.formattedSumAssured)
                DetailItem(label = "Premium", value = policy.formattedPremium)
                DetailItem(label = "Policy #", value = policy.policyNumber)
            }

            // Nominees
            if (!policy.nominees.isNullOrBlank()) {
                Text(
                    text = "Nominees: ${policy.nominees}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun DetailItem(label: String, value: String) {
    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurface,
            maxLines = 1
        )
    }
}
