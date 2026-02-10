package com.sparrowinvest.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Paid
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.data.model.DividendRecord
import com.sparrowinvest.app.data.model.DividendSummary
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning
import java.util.Locale

@Composable
fun DividendIncomeCard(
    dividendSummary: DividendSummary,
    modifier: Modifier = Modifier,
    onViewAll: () -> Unit = {}
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
                            .background(Success.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Paid,
                            contentDescription = null,
                            tint = Success,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                    Spacer(modifier = Modifier.width(Spacing.small))
                    Column {
                        Text(
                            text = "Dividend Income",
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = dividendSummary.financialYear,
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable(onClick = onViewAll)
                ) {
                    Text(
                        text = "View All",
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

            // Stats Row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(IntrinsicSize.Min),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Received
                DividendStatItem(
                    label = "Received",
                    value = formatCompactCurrency(dividendSummary.totalReceived),
                    valueColor = Success,
                    modifier = Modifier.weight(1f)
                )

                // Vertical Divider
                Box(
                    modifier = Modifier
                        .width(1.dp)
                        .fillMaxHeight()
                        .padding(vertical = 4.dp)
                        .background(
                            if (isDark) Color.White.copy(alpha = 0.12f)
                            else Color.Black.copy(alpha = 0.08f)
                        )
                )

                // Projected
                DividendStatItem(
                    label = "Projected",
                    value = formatCompactCurrency(dividendSummary.projectedAnnual),
                    valueColor = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.weight(1f)
                )

                // Vertical Divider
                Box(
                    modifier = Modifier
                        .width(1.dp)
                        .fillMaxHeight()
                        .padding(vertical = 4.dp)
                        .background(
                            if (isDark) Color.White.copy(alpha = 0.12f)
                            else Color.Black.copy(alpha = 0.08f)
                        )
                )

                // Yield
                DividendStatItem(
                    label = "Yield",
                    value = String.format(Locale.US, "%.1f%%", dividendSummary.dividendYield),
                    valueColor = Secondary,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Recent Dividends
            if (dividendSummary.recentRecords.isNotEmpty()) {
                Text(
                    text = "Recent Dividends",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(Spacing.small))

                Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    dividendSummary.recentRecords.forEach { record ->
                        DividendRecordItem(
                            record = record,
                            isDark = isDark
                        )
                    }
                }
            }

            // Next Expected Date
            dividendSummary.nextExpectedDate?.let { nextDate ->
                Spacer(modifier = Modifier.height(Spacing.medium))

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(CornerRadius.medium))
                        .background(Primary.copy(alpha = if (isDark) 0.08f else 0.05f))
                        .padding(Spacing.compact),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.CalendarToday,
                        contentDescription = null,
                        tint = Primary,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(Spacing.small))
                    Text(
                        text = "Next Expected: ",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = nextDate,
                        style = MaterialTheme.typography.labelMedium,
                        color = Primary
                    )
                }
            }
        }
    }
}

@Composable
private fun DividendStatItem(
    label: String,
    value: String,
    valueColor: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleMedium,
            color = valueColor
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun DividendRecordItem(
    record: DividendRecord,
    isDark: Boolean
) {
    val statusColor = when (record.status) {
        "Announced" -> Warning
        "Pending" -> Primary
        "Paid" -> Success
        else -> Primary
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(
                if (isDark) Color.White.copy(alpha = 0.06f)
                else MaterialTheme.colorScheme.surfaceVariant
            )
            .padding(Spacing.compact),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Fund icon with 2-letter abbreviation
        val abbreviation = record.fundName
            .split(" ")
            .take(2)
            .joinToString("") { it.first().uppercase() }

        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(statusColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = abbreviation,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Bold,
                color = statusColor
            )
        }

        Spacer(modifier = Modifier.width(Spacing.compact))

        // Fund name and payment date
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = record.fundName,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = record.paymentDate,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Spacer(modifier = Modifier.width(Spacing.small))

        // Amount and status
        Column(horizontalAlignment = Alignment.End) {
            Text(
                text = "+${formatCompactCurrency(record.amount)}",
                style = MaterialTheme.typography.labelMedium,
                color = Success
            )
            // Status badge
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(CornerRadius.small))
                    .background(statusColor.copy(alpha = 0.12f))
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = record.status,
                    style = MaterialTheme.typography.labelSmall,
                    color = statusColor
                )
            }
        }
    }
}
