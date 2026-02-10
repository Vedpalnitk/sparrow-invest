package com.sparrowinvest.app.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Storage
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.core.auth.BiometricHelper
import com.sparrowinvest.app.core.storage.ThemeMode
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Spacing

@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel = hiltViewModel(),
    onNavigateBack: () -> Unit,
    onNavigateToLanguage: () -> Unit = {},
    onNavigateToCache: () -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
    onNavigateToSecurity: () -> Unit = {}
) {
    val themeMode by viewModel.themeMode.collectAsState()
    val notificationsEnabled by viewModel.notificationsEnabled.collectAsState()
    val biometricEnabled by viewModel.biometricEnabled.collectAsState()

    val isDarkModeEnabled = when (themeMode) {
        ThemeMode.DARK -> true
        ThemeMode.LIGHT -> false
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
    ) {
        // Header
        SettingsHeader(onNavigateBack = onNavigateBack)

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Appearance Section
        SettingsSectionHeader(title = "Appearance")

        SettingsToggleItem(
            icon = Icons.Default.DarkMode,
            iconColor = Color(0xFF8B5CF6),
            title = "Dark Mode",
            subtitle = "Use dark theme",
            isEnabled = isDarkModeEnabled,
            onToggle = { viewModel.setDarkModeEnabled(it) }
        )

        SettingsNavigationItem(
            icon = Icons.Default.Language,
            iconColor = Color(0xFF3B82F6),
            title = "Language",
            subtitle = "English",
            onClick = onNavigateToLanguage
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Notifications Section
        SettingsSectionHeader(title = "Notifications")

        SettingsToggleItem(
            icon = Icons.Default.Notifications,
            iconColor = Color(0xFFF59E0B),
            title = "Push Notifications",
            subtitle = "Receive alerts and updates",
            isEnabled = notificationsEnabled,
            onToggle = { viewModel.setNotificationsEnabled(it) }
        )

        SettingsNavigationItem(
            icon = Icons.Default.NotificationsActive,
            iconColor = Color(0xFF2563EB),
            title = "Notification Settings",
            subtitle = "Manage notification preferences",
            onClick = onNavigateToNotifications
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Security Section
        SettingsSectionHeader(title = "Security")

        val context = LocalContext.current
        val biometricAvailable = remember { BiometricHelper.canAuthenticate(context) }
        val biometricType = remember { BiometricHelper.getBiometricType(context) }

        SettingsToggleItem(
            icon = Icons.Default.Fingerprint,
            iconColor = Color(0xFF10B981),
            title = "Biometric Login",
            subtitle = if (biometricAvailable) "Use $biometricType to sign in" else "Biometric not available on this device",
            isEnabled = biometricEnabled && biometricAvailable,
            onToggle = { enabled ->
                if (biometricAvailable) {
                    viewModel.setBiometricEnabled(enabled)
                }
            }
        )

        SettingsNavigationItem(
            icon = Icons.Default.Security,
            iconColor = Color(0xFF8B5CF6),
            title = "Security",
            subtitle = "Password, 2FA, sessions",
            onClick = onNavigateToSecurity
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Data Section
        SettingsSectionHeader(title = "Data")

        SettingsNavigationItem(
            icon = Icons.Default.Storage,
            iconColor = Color(0xFFEF4444),
            title = "Clear Cache",
            subtitle = "Free up storage space",
            onClick = onNavigateToCache
        )

        Spacer(modifier = Modifier.height(Spacing.xLarge))
    }
}

@Composable
private fun SettingsHeader(
    onNavigateBack: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
        verticalAlignment = Alignment.CenterVertically
    ) {
        IconButton(
            onClick = onNavigateBack,
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(Primary.copy(alpha = 0.1f))
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Back",
                tint = Primary
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        Text(
            text = "App Settings",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.onSurface,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
    )
}

@Composable
private fun SettingsToggleItem(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String,
    isEnabled: Boolean,
    onToggle: (Boolean) -> Unit
) {
    val backgroundColor = MaterialTheme.colorScheme.surfaceVariant

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small)
            .clip(RoundedCornerShape(CornerRadius.large))
            .background(backgroundColor)
            .padding(Spacing.medium),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Icon
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(CornerRadius.medium))
                .background(iconColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconColor,
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        // Text
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Switch
        Switch(
            checked = isEnabled,
            onCheckedChange = onToggle,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = Primary,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = MaterialTheme.colorScheme.surfaceVariant
            )
        )
    }
}

@Composable
private fun SettingsNavigationItem(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String,
    onClick: () -> Unit = {}
) {
    val backgroundColor = MaterialTheme.colorScheme.surfaceVariant

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.small)
            .clip(RoundedCornerShape(CornerRadius.large))
            .background(backgroundColor)
            .clickable(onClick = onClick)
            .padding(Spacing.medium),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Icon
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .size(44.dp)
                .clip(RoundedCornerShape(CornerRadius.medium))
                .background(iconColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconColor,
                modifier = Modifier.size(22.dp)
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        // Text
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Arrow
        Icon(
            imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
    }
}
