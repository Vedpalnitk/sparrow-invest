package com.sparrowinvest.app.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
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
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.ArrowDropUp
import androidx.compose.material.icons.filled.ShowChart
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.data.model.Holding
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import java.util.Locale

@Composable
fun TopMoversCard(
    gainers: List<Holding>,
    losers: List<Holding>,
    modifier: Modifier = Modifier
) {
    var selectedTab by remember { mutableIntStateOf(0) } // 0 = Gainers, 1 = Losers

    val currentList = if (selectedTab == 0) gainers else losers

    GlassCard(modifier = modifier) {
        Column(modifier = Modifier.fillMaxWidth()) {
            // Header
            Text(
                text = "Today's Movers",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(Spacing.compact))

            // Tab Toggle: Gainers / Losers
            MoverTabToggle(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it }
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Holdings List or Empty State
            if (currentList.isEmpty()) {
                MoverEmptyState(isGainers = selectedTab == 0)
            } else {
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    currentList.take(3).forEach { holding ->
                        MoverRow(
                            holding = holding,
                            isGainer = selectedTab == 0
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MoverTabToggle(
    selectedTab: Int,
    onTabSelected: (Int) -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    val capsuleBackground = if (isDark) Color.White.copy(alpha = 0.08f)
    else MaterialTheme.colorScheme.surfaceVariant

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(50))
            .background(capsuleBackground)
            .padding(3.dp)
    ) {
        val tabs = listOf("Gainers" to Success, "Losers" to Error)

        tabs.forEachIndexed { index, (label, activeColor) ->
            val isSelected = selectedTab == index

            val bgColor by animateColorAsState(
                targetValue = if (isSelected) activeColor else Color.Transparent,
                animationSpec = tween(durationMillis = 250),
                label = "tabBg"
            )
            val textColor by animateColorAsState(
                targetValue = if (isSelected) Color.White
                else MaterialTheme.colorScheme.onSurfaceVariant,
                animationSpec = tween(durationMillis = 250),
                label = "tabText"
            )

            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(50))
                    .background(bgColor)
                    .clickable { onTabSelected(index) }
                    .padding(vertical = Spacing.small),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = label,
                    style = MaterialTheme.typography.labelMedium,
                    color = textColor
                )
            }
        }
    }
}

@Composable
private fun MoverRow(
    holding: Holding,
    isGainer: Boolean
) {
    val isDark = LocalIsDarkTheme.current
    val changeColor = if (isGainer) Success else Error

    // Generate icon background color from fund name
    val iconBgColor = fundIconColor(holding.fundName)

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
        // Fund icon: 2-letter abbreviation in colored rounded rect
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(iconBgColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = fundInitials(holding.fundName),
                style = MaterialTheme.typography.labelMedium,
                color = iconBgColor
            )
        }

        Spacer(modifier = Modifier.width(Spacing.compact))

        // Fund name + category
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = holding.fundName,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = holding.category,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        Spacer(modifier = Modifier.width(Spacing.small))

        // Day change amount + percentage with arrow
        Column(horizontalAlignment = Alignment.End) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = if (isGainer) Icons.Default.ArrowDropUp else Icons.Default.ArrowDropDown,
                    contentDescription = null,
                    tint = changeColor,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = formatCompactCurrency(kotlin.math.abs(holding.dayChange)),
                    style = MaterialTheme.typography.labelMedium,
                    color = changeColor
                )
            }
            Text(
                text = String.format(
                    Locale.US,
                    "%s%.2f%%",
                    if (holding.dayChangePercentage >= 0) "+" else "",
                    holding.dayChangePercentage
                ),
                style = MaterialTheme.typography.labelSmall,
                color = changeColor
            )
        }
    }
}

@Composable
private fun MoverEmptyState(isGainers: Boolean) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = Icons.Default.ShowChart,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f),
            modifier = Modifier.size(36.dp)
        )
        Spacer(modifier = Modifier.height(Spacing.small))
        Text(
            text = if (isGainers) "No gainers today" else "No losers today",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
        )
    }
}

/**
 * Extract 2-letter initials from fund name.
 * Takes first letters of the first two words.
 */
private fun fundInitials(name: String): String {
    val words = name.split(" ").filter { it.isNotEmpty() }
    return when {
        words.size >= 2 -> "${words[0].first()}${words[1].first()}".uppercase()
        words.size == 1 -> words[0].take(2).uppercase()
        else -> "FD"
    }
}

/**
 * Generate a deterministic color from fund name for the icon background.
 */
private fun fundIconColor(name: String): Color {
    val colors = listOf(
        Color(0xFF2563EB), // Blue
        Color(0xFF06B6D4), // Cyan
        Color(0xFF10B981), // Green
        Color(0xFF8B5CF6), // Purple
        Color(0xFFF59E0B), // Amber
        Color(0xFF14B8A6), // Teal
        Color(0xFFEC4899), // Pink
        Color(0xFFEF4444)  // Red
    )
    val index = kotlin.math.abs(name.hashCode()) % colors.size
    return colors[index]
}
