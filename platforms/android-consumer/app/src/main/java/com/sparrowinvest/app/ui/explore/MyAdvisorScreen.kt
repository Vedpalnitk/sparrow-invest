package com.sparrowinvest.app.ui.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.Work
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.Advisor
import com.sparrowinvest.app.data.repository.PortfolioRepository
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
fun MyAdvisorScreen(
    viewModel: AdvisorViewModel = hiltViewModel(),
    onBackClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    // For demo purposes, use the first advisor as "my advisor" (Priya Sharma)
    val myAdvisor = viewModel.getAdvisorById("adv-001")

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
                text = "My Advisor",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f)
            )
        }

        if (myAdvisor == null) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "No advisor assigned",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Spacer(modifier = Modifier.height(Spacing.small))
                    Text(
                        text = "Contact support to get matched with an advisor",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
            return
        }

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = Spacing.medium, vertical = Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            // Advisor Header Card
            item {
                AdvisorHeaderCard(advisor = myAdvisor)
            }

            // Quick Actions
            item {
                QuickActionsSection(advisor = myAdvisor, isDark = isDark)
            }

            // Stats Tiles
            item {
                StatsTilesSection(advisor = myAdvisor, isDark = isDark)
            }

            // Specializations
            item {
                MyAdvisorSpecializationsSection(advisor = myAdvisor, isDark = isDark)
            }

            // Languages
            item {
                MyAdvisorLanguagesSection(advisor = myAdvisor, isDark = isDark)
            }

            // Contact Info
            item {
                MyAdvisorContactSection(advisor = myAdvisor, isDark = isDark)
                Spacer(modifier = Modifier.height(Spacing.large))
            }
        }
    }
}

@Composable
private fun AdvisorHeaderCard(advisor: Advisor) {
    GlassCard {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            Box(
                modifier = Modifier
                    .size(72.dp)
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
                    style = MaterialTheme.typography.headlineSmall,
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.width(Spacing.medium))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = advisor.name,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Financial Advisor",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                Spacer(modifier = Modifier.height(Spacing.small))

                Row(
                    horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Region badge
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(50))
                            .background(Primary.copy(alpha = 0.1f))
                            .padding(horizontal = Spacing.small, vertical = 2.dp)
                    ) {
                        Text(
                            text = advisor.region,
                            style = MaterialTheme.typography.labelSmall,
                            color = Primary
                        )
                    }

                    // Rating badge
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            modifier = Modifier.size(12.dp),
                            tint = Color(0xFFF59E0B)
                        )
                        Spacer(modifier = Modifier.width(2.dp))
                        Text(
                            text = "${advisor.rating}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurface,
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    // Availability badge
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(6.dp)
                                .clip(CircleShape)
                                .background(if (advisor.isAvailable) Success else Color.Gray)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = if (advisor.isAvailable) "Online" else "Offline",
                            style = MaterialTheme.typography.labelSmall,
                            color = if (advisor.isAvailable) Success else Color.Gray
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun QuickActionsSection(advisor: Advisor, isDark: Boolean) {
    GlassCard {
        Column {
            Text(
                text = "QUICK ACTIONS",
                style = MaterialTheme.typography.labelSmall,
                color = Primary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(Spacing.compact))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                QuickActionItem(
                    icon = Icons.Default.Phone,
                    label = "Call",
                    color = Success,
                    isDark = isDark,
                    onClick = { /* Initiate call */ }
                )
                QuickActionItem(
                    icon = Icons.AutoMirrored.Filled.Chat,
                    label = "Message",
                    color = Primary,
                    isDark = isDark,
                    onClick = { /* Open chat */ }
                )
                QuickActionItem(
                    icon = Icons.Default.Email,
                    label = "Email",
                    color = Secondary,
                    isDark = isDark,
                    onClick = { /* Send email */ }
                )
            }
        }
    }
}

@Composable
private fun QuickActionItem(
    icon: ImageVector,
    label: String,
    color: Color,
    isDark: Boolean,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(CircleShape)
                .background(
                    if (isDark) color.copy(alpha = 0.15f)
                    else color.copy(alpha = 0.1f)
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                modifier = Modifier.size(22.dp),
                tint = color
            )
        }
        Spacer(modifier = Modifier.height(Spacing.small))
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun StatsTilesSection(advisor: Advisor, isDark: Boolean) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small)
    ) {
        // Experience
        GlassCard(modifier = Modifier.weight(1f)) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Default.Work,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Primary
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                Text(
                    text = advisor.formattedExperience,
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Experience",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Rating
        GlassCard(modifier = Modifier.weight(1f)) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Color(0xFFF59E0B)
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                Text(
                    text = "${advisor.rating}",
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Rating",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Reviews
        GlassCard(modifier = Modifier.weight(1f)) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Chat,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                    tint = Secondary
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                Text(
                    text = "${advisor.reviewCount}",
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Reviews",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun MyAdvisorSpecializationsSection(advisor: Advisor, isDark: Boolean) {
    GlassCard {
        Column {
            Text(
                text = "SPECIALIZATIONS",
                style = MaterialTheme.typography.labelSmall,
                color = Primary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(Spacing.compact))

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                verticalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                advisor.specializationEnums.forEach { spec ->
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(CornerRadius.small))
                            .background(
                                if (isDark) Primary.copy(alpha = 0.15f)
                                else Primary.copy(alpha = 0.08f)
                            )
                            .padding(horizontal = Spacing.compact, vertical = Spacing.micro)
                    ) {
                        Text(
                            text = spec.displayName,
                            style = MaterialTheme.typography.labelMedium,
                            color = Primary
                        )
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun MyAdvisorLanguagesSection(advisor: Advisor, isDark: Boolean) {
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

@Composable
private fun MyAdvisorContactSection(advisor: Advisor, isDark: Boolean) {
    GlassCard {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.compact)) {
            Text(
                text = "CONTACT INFO",
                style = MaterialTheme.typography.labelSmall,
                color = Primary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(Spacing.micro))

            // Phone
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

            // Email
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
