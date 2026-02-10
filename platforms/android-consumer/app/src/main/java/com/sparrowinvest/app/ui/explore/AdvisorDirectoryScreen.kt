package com.sparrowinvest.app.ui.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Star
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.Advisor
import com.sparrowinvest.app.ui.components.GlassCard
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GradientEndCyan
import com.sparrowinvest.app.ui.theme.GradientStartBlue
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AdvisorDirectoryScreen(
    viewModel: AdvisorViewModel = hiltViewModel(),
    onNavigateToAdvisor: (String) -> Unit,
    onBackClick: () -> Unit
) {
    val advisors by viewModel.advisors.collectAsState()
    val selectedRegion by viewModel.selectedRegion.collectAsState()
    val allRegions by viewModel.allRegions.collectAsState()
    val isDark = LocalIsDarkTheme.current

    val filteredAdvisors = viewModel.filteredAdvisors

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
                text = "Find Advisor",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f)
            )
        }

        // Region Filter Chips
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState())
                .padding(horizontal = Spacing.medium, vertical = Spacing.small),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            // "All" chip
            RegionChip(
                label = "All",
                isSelected = selectedRegion == null,
                onClick = { viewModel.setRegion(null) }
            )

            // Region chips
            allRegions.forEach { region ->
                RegionChip(
                    label = region,
                    isSelected = selectedRegion == region,
                    showLocationIcon = true,
                    onClick = { viewModel.setRegion(region) }
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.small))

        // Advisor List
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = Spacing.medium, vertical = Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            items(filteredAdvisors, key = { it.id }) { advisor ->
                AdvisorCard(
                    advisor = advisor,
                    onClick = { onNavigateToAdvisor(advisor.id) }
                )
            }
        }
    }
}

@Composable
private fun RegionChip(
    label: String,
    isSelected: Boolean,
    showLocationIcon: Boolean = false,
    onClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(
                if (isSelected) Primary
                else if (isDark) Color.White.copy(alpha = 0.08f)
                else Color.Black.copy(alpha = 0.06f)
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 8.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (showLocationIcon) {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = if (isSelected) Color.White
                    else MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.width(4.dp))
            }
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = if (isSelected) Color.White
                else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun AdvisorCard(
    advisor: Advisor,
    onClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current

    GlassCard(
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Avatar with gradient
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(
                                colors = listOf(GradientStartBlue, GradientEndCyan)
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = advisor.initials,
                        style = MaterialTheme.typography.titleMedium,
                        color = Color.White,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Spacer(modifier = Modifier.width(Spacing.compact))

                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = advisor.name,
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface,
                            fontWeight = FontWeight.SemiBold
                        )
                        Spacer(modifier = Modifier.width(Spacing.small))
                        // Availability dot
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(
                                    if (advisor.isAvailable) Success else Color.Gray
                                )
                        )
                    }

                    Spacer(modifier = Modifier.height(4.dp))

                    // Region badge
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(2.dp))
                        Text(
                            text = advisor.region,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                // Rating and Experience
                Column(horizontalAlignment = Alignment.End) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = Color(0xFFF59E0B)
                        )
                        Spacer(modifier = Modifier.width(2.dp))
                        Text(
                            text = "${advisor.rating}",
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurface,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = advisor.formattedExperience,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.compact))

            // Specialization chips
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                verticalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                advisor.specializationEnums.forEach { spec ->
                    SpecializationChip(text = spec.displayName, isDark = isDark)
                }
            }
        }
    }
}

@Composable
private fun SpecializationChip(
    text: String,
    isDark: Boolean
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(CornerRadius.small))
            .background(
                if (isDark) Primary.copy(alpha = 0.15f)
                else Primary.copy(alpha = 0.08f)
            )
            .padding(horizontal = Spacing.small, vertical = Spacing.micro)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = Primary
        )
    }
}
