package com.sparrowinvest.app.ui.explore

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Diamond
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.HomeWork
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Work
import androidx.compose.material.icons.automirrored.filled.TrendingUp
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.Advisor
import com.sparrowinvest.app.data.model.AdvisorSpecialization
import com.sparrowinvest.app.ui.components.GlassCard
import com.sparrowinvest.app.ui.components.PrimaryButton
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GradientEndCyan
import com.sparrowinvest.app.ui.theme.GradientStartBlue
import com.sparrowinvest.app.ui.theme.Info
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AdvisorDetailScreen(
    advisorId: String,
    viewModel: AdvisorViewModel = hiltViewModel(),
    onBackClick: () -> Unit
) {
    val advisor = viewModel.getAdvisorById(advisorId)
    val isDark = LocalIsDarkTheme.current
    var callbackRequested by remember { mutableStateOf(false) }

    if (advisor == null) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Advisor not found",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        return
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
                text = "Advisor Profile",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f)
            )
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = Spacing.medium, vertical = Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            // Profile Header
            item {
                ProfileHeader(advisor = advisor)
            }

            // Contact Info
            item {
                ContactInfoSection(advisor = advisor, isDark = isDark)
            }

            // Specializations
            item {
                SpecializationsSection(advisor = advisor, isDark = isDark)
            }

            // Stats
            item {
                StatsSection(advisor = advisor, isDark = isDark)
            }

            // Languages
            item {
                LanguagesSection(advisor = advisor, isDark = isDark)
            }

            // Callback Request Button
            item {
                if (callbackRequested) {
                    GlassCard {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(Warning)
                            )
                            Spacer(modifier = Modifier.width(Spacing.small))
                            Text(
                                text = "Callback Request Pending",
                                style = MaterialTheme.typography.titleSmall,
                                color = Warning,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                } else {
                    PrimaryButton(
                        text = "Request Callback",
                        onClick = { callbackRequested = true }
                    )
                }

                Spacer(modifier = Modifier.height(Spacing.large))
            }
        }
    }
}

@Composable
private fun ProfileHeader(advisor: Advisor) {
    GlassCard {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Large avatar
            Box(
                modifier = Modifier
                    .size(80.dp)
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
                    style = MaterialTheme.typography.headlineMedium,
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.height(Spacing.compact))

            // Name
            Text(
                text = advisor.name,
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(Spacing.micro))

            // Region badge
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(Primary.copy(alpha = 0.1f))
                    .padding(horizontal = Spacing.compact, vertical = Spacing.micro)
            ) {
                Text(
                    text = advisor.region,
                    style = MaterialTheme.typography.labelMedium,
                    color = Primary
                )
            }

            Spacer(modifier = Modifier.height(Spacing.small))

            // Availability indicator
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(if (advisor.isAvailable) Success else Color.Gray)
                )
                Spacer(modifier = Modifier.width(Spacing.small))
                Text(
                    text = if (advisor.isAvailable) "Available" else "Unavailable",
                    style = MaterialTheme.typography.bodySmall,
                    color = if (advisor.isAvailable) Success else Color.Gray
                )
            }
        }
    }
}

@Composable
private fun ContactInfoSection(advisor: Advisor, isDark: Boolean) {
    GlassCard {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.compact)) {
            Text(
                text = "CONTACT",
                style = MaterialTheme.typography.labelSmall,
                color = Primary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(Spacing.micro))

            // Phone row
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(CornerRadius.small))
                        .background(
                            if (isDark) Primary.copy(alpha = 0.15f)
                            else Primary.copy(alpha = 0.08f)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Phone,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = Primary
                    )
                }
                Spacer(modifier = Modifier.width(Spacing.compact))
                Column {
                    Text(
                        text = "Phone",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = advisor.phone,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }

            // Email row
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(CornerRadius.small))
                        .background(
                            if (isDark) Secondary.copy(alpha = 0.15f)
                            else Secondary.copy(alpha = 0.08f)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Email,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = Secondary
                    )
                }
                Spacer(modifier = Modifier.width(Spacing.compact))
                Column {
                    Text(
                        text = "Email",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = advisor.email,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun SpecializationsSection(advisor: Advisor, isDark: Boolean) {
    GlassCard {
        Column {
            Text(
                text = "SPECIALIZATIONS",
                style = MaterialTheme.typography.labelSmall,
                color = Primary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(Spacing.compact))

            // 2-column grid using FlowRow
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                verticalArrangement = Arrangement.spacedBy(Spacing.small),
                maxItemsInEachRow = 2
            ) {
                advisor.specializationEnums.forEach { spec ->
                    SpecializationDetailChip(
                        spec = spec,
                        isDark = isDark,
                        modifier = Modifier.weight(1f)
                    )
                }
                // Add empty spacer if odd number of items
                if (advisor.specializationEnums.size % 2 != 0) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun SpecializationDetailChip(
    spec: AdvisorSpecialization,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    val (icon, color) = getSpecializationIconAndColor(spec)

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(
                if (isDark) color.copy(alpha = 0.12f)
                else color.copy(alpha = 0.06f)
            )
            .padding(horizontal = Spacing.compact, vertical = Spacing.small)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = color
            )
            Spacer(modifier = Modifier.width(Spacing.small))
            Text(
                text = spec.displayName,
                style = MaterialTheme.typography.labelMedium,
                color = color,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

private fun getSpecializationIconAndColor(spec: AdvisorSpecialization): Pair<ImageVector, Color> {
    return when (spec) {
        AdvisorSpecialization.RETIREMENT -> Icons.Default.AccountBalance to Color(0xFF2563EB)
        AdvisorSpecialization.TAX_PLANNING -> Icons.Default.Work to Color(0xFF10B981)
        AdvisorSpecialization.HNI -> Icons.Default.Diamond to Color(0xFF8B5CF6)
        AdvisorSpecialization.MUTUAL_FUNDS -> Icons.AutoMirrored.Filled.TrendingUp to Color(0xFF06B6D4)
        AdvisorSpecialization.INSURANCE -> Icons.Default.Shield to Color(0xFFF59E0B)
        AdvisorSpecialization.ESTATE_PLANNING -> Icons.Default.HomeWork to Color(0xFF14B8A6)
        AdvisorSpecialization.NRI -> Icons.Default.Flight to Color(0xFFEF4444)
        AdvisorSpecialization.EQUITY -> Icons.AutoMirrored.Filled.TrendingUp to Color(0xFFEA580C)
    }
}

@Composable
private fun StatsSection(advisor: Advisor, isDark: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        // Rating tile
        GlassCard(modifier = Modifier.weight(1f)) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                    tint = Color(0xFFF59E0B)
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                Text(
                    text = "${advisor.rating}",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${advisor.reviewCount} reviews",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Experience tile
        GlassCard(modifier = Modifier.weight(1f)) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Default.Work,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                    tint = Primary
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                Text(
                    text = advisor.formattedExperience,
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Experience",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun LanguagesSection(advisor: Advisor, isDark: Boolean) {
    GlassCard {
        Column {
            Text(
                text = "LANGUAGES",
                style = MaterialTheme.typography.labelSmall,
                color = Primary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(Spacing.compact))

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                verticalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                advisor.languages.forEach { language ->
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(50))
                            .background(
                                if (isDark) Color.White.copy(alpha = 0.08f)
                                else Color.Black.copy(alpha = 0.05f)
                            )
                            .padding(horizontal = Spacing.compact, vertical = Spacing.micro)
                    ) {
                        Text(
                            text = language,
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                    }
                }
            }
        }
    }
}
