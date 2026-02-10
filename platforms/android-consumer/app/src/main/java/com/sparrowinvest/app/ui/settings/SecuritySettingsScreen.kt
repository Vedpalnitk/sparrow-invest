package com.sparrowinvest.app.ui.settings

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Computer
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.filled.PhoneIphone
import androidx.compose.material.icons.filled.RemoveRedEye
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.core.auth.BiometricHelper
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.Info
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning

private data class SessionInfo(
    val deviceName: String,
    val details: String,
    val time: String,
    val icon: ImageVector,
    val isCurrentDevice: Boolean
)

@Composable
fun SecuritySettingsScreen(
    onBackClick: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val isDark = LocalIsDarkTheme.current
    val biometricEnabled by viewModel.biometricEnabled.collectAsState()

    // Password change form state
    var showPasswordForm by remember { mutableStateOf(false) }
    var currentPassword by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var showCurrentPassword by remember { mutableStateOf(false) }
    var showNewPassword by remember { mutableStateOf(false) }
    var showConfirmPassword by remember { mutableStateOf(false) }

    // Auto-lock timer
    var autoLockExpanded by remember { mutableStateOf(false) }
    var selectedAutoLock by remember { mutableStateOf("After 5 min") }
    val autoLockOptions = listOf("Immediately", "After 1 min", "After 5 min", "After 15 min")

    // Privacy toggles
    var twoFactorEnabled by remember { mutableStateOf(false) }
    var hideBalance by remember { mutableStateOf(false) }

    // Sessions
    var sessions by remember {
        mutableStateOf(
            listOf(
                SessionInfo("This Device", "Android \u2022 Mumbai \u2022 Active now", "Active now", Icons.Default.PhoneAndroid, true),
                SessionInfo("iPhone 15", "iOS \u2022 Delhi \u2022 2 hours ago", "2 hours ago", Icons.Default.PhoneIphone, false),
                SessionInfo("Chrome Browser", "Web \u2022 Pune \u2022 1 day ago", "1 day ago", Icons.Default.Computer, false)
            )
        )
    }

    // Delete account dialog
    var showDeleteDialog by remember { mutableStateOf(false) }

    // Biometric
    val context = LocalContext.current
    val biometricAvailable = remember { BiometricHelper.canAuthenticate(context) }

    val glassBorderBrush = if (isDark) {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    val cardBackground = if (isDark) CardBackgroundDark else CardBackgroundLight
    val cardShape = RoundedCornerShape(CornerRadius.xLarge)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = onBackClick,
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
                text = "Security",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 1: Authentication
        Text(
            text = "Authentication",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        SecurityGlassCard(isDark, cardBackground, glassBorderBrush, cardShape) {
            // Change Password row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showPasswordForm = !showPasswordForm }
                    .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(RoundedCornerShape(CornerRadius.medium))
                        .background(Color(0xFF3B82F6).copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = null,
                        tint = Color(0xFF3B82F6),
                        modifier = Modifier.size(22.dp)
                    )
                }

                Spacer(modifier = Modifier.width(Spacing.medium))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Change Password",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "Update your account password",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(24.dp)
                )
            }

            // Expandable password form
            AnimatedVisibility(
                visible = showPasswordForm,
                enter = expandVertically(),
                exit = shrinkVertically()
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = Spacing.medium, vertical = Spacing.small)
                ) {
                    // Current password
                    OutlinedTextField(
                        value = currentPassword,
                        onValueChange = { currentPassword = it },
                        label = { Text("Current Password") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        visualTransformation = if (showCurrentPassword) VisualTransformation.None else PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                        trailingIcon = {
                            IconButton(onClick = { showCurrentPassword = !showCurrentPassword }) {
                                Icon(
                                    imageVector = if (showCurrentPassword) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                    contentDescription = if (showCurrentPassword) "Hide password" else "Show password"
                                )
                            }
                        },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Primary,
                            focusedLabelColor = Primary
                        ),
                        shape = RoundedCornerShape(CornerRadius.medium)
                    )

                    Spacer(modifier = Modifier.height(Spacing.small))

                    // New password
                    OutlinedTextField(
                        value = newPassword,
                        onValueChange = { newPassword = it },
                        label = { Text("New Password") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        visualTransformation = if (showNewPassword) VisualTransformation.None else PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                        trailingIcon = {
                            IconButton(onClick = { showNewPassword = !showNewPassword }) {
                                Icon(
                                    imageVector = if (showNewPassword) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                    contentDescription = if (showNewPassword) "Hide password" else "Show password"
                                )
                            }
                        },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Primary,
                            focusedLabelColor = Primary
                        ),
                        shape = RoundedCornerShape(CornerRadius.medium)
                    )

                    Spacer(modifier = Modifier.height(Spacing.small))

                    // Confirm password
                    OutlinedTextField(
                        value = confirmPassword,
                        onValueChange = { confirmPassword = it },
                        label = { Text("Confirm New Password") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        visualTransformation = if (showConfirmPassword) VisualTransformation.None else PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                        trailingIcon = {
                            IconButton(onClick = { showConfirmPassword = !showConfirmPassword }) {
                                Icon(
                                    imageVector = if (showConfirmPassword) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                                    contentDescription = if (showConfirmPassword) "Hide password" else "Show password"
                                )
                            }
                        },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Primary,
                            focusedLabelColor = Primary
                        ),
                        shape = RoundedCornerShape(CornerRadius.medium)
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    // Save button
                    Button(
                        onClick = {
                            // Mock save
                            currentPassword = ""
                            newPassword = ""
                            confirmPassword = ""
                            showPasswordForm = false
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(44.dp),
                        shape = RoundedCornerShape(CornerRadius.large),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Primary
                        ),
                        enabled = currentPassword.isNotEmpty() && newPassword.isNotEmpty() && confirmPassword.isNotEmpty() && newPassword == confirmPassword
                    ) {
                        Text(
                            text = "Update Password",
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    Spacer(modifier = Modifier.height(Spacing.small))
                }
            }

            SecurityDivider()

            // Biometric Login
            SecurityToggleRow(
                icon = Icons.Default.Fingerprint,
                iconColor = Color(0xFF10B981),
                title = "Biometric Login",
                subtitle = if (biometricAvailable) "Use fingerprint or face to sign in" else "Biometric not available on this device",
                isEnabled = biometricEnabled && biometricAvailable,
                onToggle = { enabled ->
                    if (biometricAvailable) {
                        viewModel.setBiometricEnabled(enabled)
                    }
                }
            )

            SecurityDivider()

            // Auto-Lock Timer
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(RoundedCornerShape(CornerRadius.medium))
                        .background(Warning.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Timer,
                        contentDescription = null,
                        tint = Warning,
                        modifier = Modifier.size(22.dp)
                    )
                }

                Spacer(modifier = Modifier.width(Spacing.medium))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Auto-Lock Timer",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "Lock app after inactivity",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Box {
                    TextButton(onClick = { autoLockExpanded = true }) {
                        Text(
                            text = selectedAutoLock,
                            color = Primary,
                            fontWeight = FontWeight.Medium,
                            style = MaterialTheme.typography.bodyMedium
                        )
                    }

                    DropdownMenu(
                        expanded = autoLockExpanded,
                        onDismissRequest = { autoLockExpanded = false }
                    ) {
                        autoLockOptions.forEach { option ->
                            DropdownMenuItem(
                                text = {
                                    Text(
                                        text = option,
                                        fontWeight = if (option == selectedAutoLock) FontWeight.SemiBold else FontWeight.Normal,
                                        color = if (option == selectedAutoLock) Primary else MaterialTheme.colorScheme.onSurface
                                    )
                                },
                                onClick = {
                                    selectedAutoLock = option
                                    autoLockExpanded = false
                                }
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 2: Privacy
        Text(
            text = "Privacy",
            style = MaterialTheme.typography.titleSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        SecurityGlassCard(isDark, cardBackground, glassBorderBrush, cardShape) {
            SecurityToggleRow(
                icon = Icons.Default.Shield,
                iconColor = Info,
                title = "Two-Factor Authentication",
                subtitle = "Add extra security with OTP verification",
                isEnabled = twoFactorEnabled,
                onToggle = { twoFactorEnabled = it }
            )

            SecurityDivider()

            SecurityToggleRow(
                icon = Icons.Default.RemoveRedEye,
                iconColor = Color(0xFF64748B),
                title = "Hide Portfolio Balance",
                subtitle = "Hide amounts on the home screen",
                isEnabled = hideBalance,
                onToggle = { hideBalance = it }
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 3: Active Sessions
        Row(
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Active Sessions",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.width(Spacing.small))

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(CornerRadius.small))
                    .background(Primary.copy(alpha = 0.15f))
                    .padding(horizontal = 8.dp, vertical = 2.dp)
            ) {
                Text(
                    text = "${sessions.size}",
                    style = MaterialTheme.typography.labelSmall,
                    color = Primary,
                    fontWeight = FontWeight.Bold
                )
            }
        }

        SecurityGlassCard(isDark, cardBackground, glassBorderBrush, cardShape) {
            sessions.forEachIndexed { index, session ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Device icon
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .clip(RoundedCornerShape(CornerRadius.medium))
                            .background(
                                if (session.isCurrentDevice) Success.copy(alpha = 0.15f)
                                else MaterialTheme.colorScheme.surfaceVariant
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = session.icon,
                            contentDescription = null,
                            tint = if (session.isCurrentDevice) Success else MaterialTheme.colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(22.dp)
                        )
                    }

                    Spacer(modifier = Modifier.width(Spacing.medium))

                    Column(modifier = Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = session.deviceName,
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurface,
                                fontWeight = FontWeight.Medium
                            )
                            if (session.isCurrentDevice) {
                                Spacer(modifier = Modifier.width(Spacing.small))
                                Box(
                                    modifier = Modifier
                                        .size(8.dp)
                                        .clip(CircleShape)
                                        .background(Success)
                                )
                            }
                        }
                        Text(
                            text = session.details,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    if (!session.isCurrentDevice) {
                        TextButton(
                            onClick = {
                                sessions = sessions.filterNot { it == session }
                            }
                        ) {
                            Text(
                                text = "Remove",
                                color = Error,
                                fontWeight = FontWeight.SemiBold,
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                    } else {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(Success)
                        )
                    }
                }

                if (index < sessions.size - 1) {
                    SecurityDivider()
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Section 4: Danger Zone
        Text(
            text = "Danger Zone",
            style = MaterialTheme.typography.titleSmall,
            color = Error,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = Spacing.medium, vertical = Spacing.small)
        )

        val dangerCardModifier = if (isDark) {
            Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .clip(cardShape)
                .background(cardBackground)
                .border(1.dp, Brush.linearGradient(colors = listOf(Error.copy(alpha = 0.3f), Error.copy(alpha = 0.1f))), cardShape)
        } else {
            Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .shadow(8.dp, cardShape, clip = false, ambientColor = ShadowColor, spotColor = ShadowColor)
                .clip(cardShape)
                .background(cardBackground)
                .border(1.dp, Brush.linearGradient(colors = listOf(Error.copy(alpha = 0.3f), Error.copy(alpha = 0.1f))), cardShape)
        }

        Column(modifier = dangerCardModifier) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { showDeleteDialog = true }
                    .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .clip(RoundedCornerShape(CornerRadius.medium))
                        .background(Error.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.DeleteForever,
                        contentDescription = null,
                        tint = Error,
                        modifier = Modifier.size(22.dp)
                    )
                }

                Spacer(modifier = Modifier.width(Spacing.medium))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = "Delete Account",
                        style = MaterialTheme.typography.bodyLarge,
                        color = Error,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "Permanently delete your account and data",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = Error.copy(alpha = 0.6f),
                    modifier = Modifier.size(24.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.xLarge))
    }

    // Delete Account dialog
    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = {
                Text(
                    text = "Delete Account?",
                    fontWeight = FontWeight.Bold,
                    color = Error
                )
            },
            text = {
                Text(
                    "This action is permanent and cannot be undone. All your portfolio data, transaction history, " +
                            "goals, and personal information will be permanently deleted. Your investments through " +
                            "broker platforms will not be affected."
                )
            },
            confirmButton = {
                TextButton(
                    onClick = { showDeleteDialog = false }
                ) {
                    Text("Delete My Account", color = Error, fontWeight = FontWeight.SemiBold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
}

@Composable
private fun SecurityGlassCard(
    isDark: Boolean,
    cardBackground: Color,
    glassBorderBrush: Brush,
    cardShape: RoundedCornerShape,
    content: @Composable () -> Unit
) {
    val modifier = if (isDark) {
        Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .clip(cardShape)
            .background(cardBackground)
            .border(1.dp, glassBorderBrush, cardShape)
    } else {
        Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .shadow(8.dp, cardShape, clip = false, ambientColor = ShadowColor, spotColor = ShadowColor)
            .clip(cardShape)
            .background(cardBackground)
            .border(1.dp, glassBorderBrush, cardShape)
    }

    Column(modifier = modifier) {
        content()
    }
}

@Composable
private fun SecurityToggleRow(
    icon: ImageVector,
    iconColor: Color,
    title: String,
    subtitle: String,
    isEnabled: Boolean,
    onToggle: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
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
private fun SecurityDivider() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.medium)
            .height(1.dp)
            .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
    )
}
