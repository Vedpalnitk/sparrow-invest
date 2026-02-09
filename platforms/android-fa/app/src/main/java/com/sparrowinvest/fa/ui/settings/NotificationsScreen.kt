package com.sparrowinvest.fa.ui.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.fa.data.model.NotificationCategory
import com.sparrowinvest.fa.data.model.NotificationChannelType
import com.sparrowinvest.fa.data.model.NotificationPreferences
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.TopBar
import com.sparrowinvest.fa.ui.theme.CornerRadius
import com.sparrowinvest.fa.ui.theme.Spacing

@Composable
fun NotificationsScreen(
    onBackClick: () -> Unit,
    viewModel: NotificationsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(modifier = Modifier.fillMaxSize()) {
        TopBar(title = "Notifications", onBackClick = onBackClick)

        when (val state = uiState) {
            is NotificationsUiState.Loading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            is NotificationsUiState.Error -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            text = "Failed to load preferences",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.height(Spacing.small))
                        TextButton(onClick = { viewModel.loadPreferences() }) {
                            Text("Retry")
                        }
                    }
                }
            }
            is NotificationsUiState.Success -> {
                NotificationsContent(
                    preferences = state.preferences,
                    viewModel = viewModel
                )
            }
        }
    }
}

@Composable
private fun NotificationsContent(
    preferences: NotificationPreferences,
    viewModel: NotificationsViewModel
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.medium)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium)
    ) {
        Spacer(modifier = Modifier.height(Spacing.compact))

        // Group categories into sections
        NotificationSection(
            title = "ALERTS",
            categories = listOf(
                NotificationCategory.TRADE_ALERTS,
                NotificationCategory.SIP_REMINDERS,
                NotificationCategory.CLIENT_REQUESTS,
                NotificationCategory.PORTFOLIO_ALERTS,
                NotificationCategory.KYC_ALERTS,
            ),
            preferences = preferences,
            viewModel = viewModel
        )

        NotificationSection(
            title = "UPDATES",
            categories = listOf(
                NotificationCategory.MARKET_UPDATES,
                NotificationCategory.DAILY_DIGEST,
            ),
            preferences = preferences,
            viewModel = viewModel
        )

        Spacer(modifier = Modifier.height(Spacing.large))
    }
}

@Composable
private fun NotificationSection(
    title: String,
    categories: List<NotificationCategory>,
    preferences: NotificationPreferences,
    viewModel: NotificationsViewModel
) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(start = Spacing.compact)
    )
    GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
        Column {
            categories.forEach { category ->
                CategoryRow(
                    category = category,
                    preferences = preferences,
                    viewModel = viewModel
                )
            }
        }
    }
}

@Composable
private fun CategoryRow(
    category: NotificationCategory,
    preferences: NotificationPreferences,
    viewModel: NotificationsViewModel
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            Icon(
                imageVector = Icons.Default.NotificationsActive,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(22.dp)
            )
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = category.displayName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = category.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Channel toggles row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 38.dp, top = 4.dp),
            horizontalArrangement = Arrangement.spacedBy(Spacing.large)
        ) {
            NotificationChannelType.entries.forEach { channel ->
                val enabled = viewModel.isEnabled(preferences, category, channel)
                ChannelToggle(
                    channel = channel,
                    checked = enabled,
                    onCheckedChange = { viewModel.togglePreference(category, channel, it) }
                )
            }
        }
    }
}

@Composable
private fun ChannelToggle(
    channel: NotificationChannelType,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier.clickable { onCheckedChange(!checked) }
    ) {
        Text(
            text = channel.displayName,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            modifier = Modifier.height(24.dp)
        )
    }
}
