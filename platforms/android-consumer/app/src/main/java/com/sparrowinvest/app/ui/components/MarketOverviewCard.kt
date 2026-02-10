package com.sparrowinvest.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.ArrowDropUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.data.model.MarketIndex
import com.sparrowinvest.app.data.model.MarketOverview
import com.sparrowinvest.app.data.model.MarketStatus
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning
import java.util.Locale

@Composable
fun MarketOverviewCard(
    marketOverview: MarketOverview,
    modifier: Modifier = Modifier
) {
    GlassCard(modifier = modifier) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Header: Title + Status Badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Market Overview",
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface
                )

                MarketStatusBadge(status = marketOverview.statusEnum)
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Primary Indices: Row of 2 tiles
            val primaryIndices = marketOverview.primaryIndices
            if (primaryIndices.isNotEmpty()) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
                ) {
                    primaryIndices.forEach { index ->
                        PrimaryIndexTile(
                            index = index,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    // Fill remaining space if only one primary index
                    if (primaryIndices.size == 1) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }

            // Other Indices: Horizontal scroll
            val otherIndices = marketOverview.otherIndices
            if (otherIndices.isNotEmpty()) {
                Spacer(modifier = Modifier.height(Spacing.compact))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(Spacing.small)
                ) {
                    otherIndices.forEach { index ->
                        CompactIndexTile(index = index)
                    }
                }
            }

            // Last Updated
            if (marketOverview.lastUpdated.isNotEmpty()) {
                Spacer(modifier = Modifier.height(Spacing.compact))

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.AccessTime,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(Spacing.micro))
                    Text(
                        text = marketOverview.lastUpdated,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                    )
                }
            }
        }
    }
}

@Composable
private fun MarketStatusBadge(status: MarketStatus) {
    val statusColor = when (status) {
        MarketStatus.OPEN -> Success
        MarketStatus.CLOSED -> Error
        MarketStatus.PRE_OPEN -> Warning
        MarketStatus.POST_CLOSE -> Warning
    }

    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(statusColor.copy(alpha = 0.12f))
            .padding(horizontal = Spacing.small, vertical = Spacing.micro),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(6.dp)
                .clip(CircleShape)
                .background(statusColor)
        )
        Spacer(modifier = Modifier.width(Spacing.micro))
        Text(
            text = status.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = statusColor
        )
    }
}

@Composable
private fun PrimaryIndexTile(
    index: MarketIndex,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val tintColor = if (index.isPositive) Success else Error
    val bgAlpha = if (isDark) 0.10f else 0.06f

    Column(
        modifier = modifier
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(tintColor.copy(alpha = bgAlpha))
            .padding(Spacing.compact)
    ) {
        Text(
            text = index.name,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(Spacing.micro))

        Text(
            text = index.formattedValue,
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(Spacing.micro))

        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = if (index.isPositive) Icons.Default.ArrowDropUp else Icons.Default.ArrowDropDown,
                contentDescription = null,
                tint = tintColor,
                modifier = Modifier.size(18.dp)
            )
            Text(
                text = index.formattedChange,
                style = MaterialTheme.typography.labelSmall,
                color = tintColor
            )
        }
    }
}

@Composable
private fun CompactIndexTile(
    index: MarketIndex,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val tintColor = if (index.isPositive) Success else Error

    Column(
        modifier = modifier
            .clip(RoundedCornerShape(CornerRadius.small))
            .background(
                if (isDark) Color.White.copy(alpha = 0.06f)
                else MaterialTheme.colorScheme.surfaceVariant
            )
            .padding(horizontal = Spacing.compact, vertical = Spacing.small)
    ) {
        Text(
            text = index.name,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(Spacing.micro))

        Text(
            text = index.formattedValue,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(2.dp))

        Text(
            text = String.format(
                Locale.US,
                "%s%.2f%%",
                if (index.changePercentage >= 0) "+" else "",
                index.changePercentage
            ),
            style = MaterialTheme.typography.labelSmall,
            color = tintColor
        )
    }
}
