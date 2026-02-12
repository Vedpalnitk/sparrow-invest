package com.sparrowinvest.fa.ui.settings

import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Schedule
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.fa.data.model.NotificationCategory
import com.sparrowinvest.fa.data.model.NotificationChannelType
import com.sparrowinvest.fa.data.model.NotificationLogEntry
import com.sparrowinvest.fa.data.model.NotificationPreferences
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.TopBar
import com.sparrowinvest.fa.ui.theme.CornerRadius
import com.sparrowinvest.fa.ui.theme.Error
import com.sparrowinvest.fa.ui.theme.Spacing
import com.sparrowinvest.fa.ui.theme.Success
import com.sparrowinvest.fa.ui.theme.Warning

@Composable
fun NotificationsScreen(
    onBackClick: () -> Unit,
    viewModel: NotificationsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val logs by viewModel.logs.collectAsState()
    val logsLoading by viewModel.logsLoading.collectAsState()

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
                    logs = logs,
                    logsLoading = logsLoading,
                    viewModel = viewModel
                )
            }
        }
    }
}

@Composable
private fun NotificationsContent(
    preferences: NotificationPreferences,
    logs: List<NotificationLogEntry>,
    logsLoading: Boolean,
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

        // Recent Notification Logs
        Text(
            text = "RECENT NOTIFICATIONS",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(start = Spacing.compact)
        )

        if (logsLoading) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(80.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(modifier = Modifier.size(24.dp))
            }
        } else if (logs.isEmpty()) {
            GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.medium) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = Spacing.medium),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "No recent notifications",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
                Column {
                    logs.take(10).forEach { log ->
                        NotificationLogItem(log = log)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.large))
    }
}

@Composable
private fun NotificationLogItem(log: NotificationLogEntry) {
    val statusColor = when (log.status.uppercase()) {
        "SENT", "DELIVERED" -> Success
        "FAILED" -> Error
        "PENDING", "QUEUED" -> Warning
        else -> MaterialTheme.colorScheme.onSurfaceVariant
    }

    val channelIcon: ImageVector = when (log.channel.uppercase()) {
        "EMAIL" -> Icons.Default.Email
        "PUSH" -> Icons.Default.Notifications
        else -> Icons.Default.NotificationsActive
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        // Channel icon
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(statusColor.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = channelIcon,
                contentDescription = null,
                tint = statusColor,
                modifier = Modifier.size(18.dp)
            )
        }

        // Content
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = log.subject ?: log.category.replace("_", " "),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Row(
                horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = log.channel.lowercase().replaceFirstChar { it.uppercase() },
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = formatLogDate(log.sentAt ?: log.createdAt),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Status indicator
        Icon(
            imageVector = when (log.status.uppercase()) {
                "SENT", "DELIVERED" -> Icons.Default.Check
                "FAILED" -> Icons.Default.Close
                else -> Icons.Default.Schedule
            },
            contentDescription = log.status,
            tint = statusColor,
            modifier = Modifier.size(16.dp)
        )
    }
}

private fun formatLogDate(dateStr: String): String {
    return try {
        // Simple display: take first 10 chars for date, or show time portion
        if (dateStr.length >= 16) {
            dateStr.substring(0, 16).replace("T", " ")
        } else {
            dateStr.take(10)
        }
    } catch (_: Exception) {
        dateStr
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
