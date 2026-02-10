package com.sparrowinvest.app.ui.profile

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.layout.offset
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
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.ui.components.Avatar
import com.sparrowinvest.app.ui.components.PrimaryButton
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing
import kotlinx.coroutines.launch

private val indianStates = listOf(
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand",
    "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur",
    "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab",
    "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura",
    "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Delhi", "Jammu & Kashmir", "Ladakh", "Chandigarh", "Puducherry"
)

@Composable
fun EditProfileScreen(
    onBackClick: () -> Unit,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val currentUser by viewModel.currentUser.collectAsState()
    val isDark = LocalIsDarkTheme.current
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()

    // Form state
    var firstName by remember(currentUser) { mutableStateOf(currentUser?.firstName ?: "") }
    var lastName by remember(currentUser) { mutableStateOf(currentUser?.lastName ?: "") }
    var email by remember(currentUser) { mutableStateOf(currentUser?.email ?: "") }
    var phone by remember(currentUser) { mutableStateOf(currentUser?.phone ?: "") }
    var dateOfBirth by remember { mutableStateOf("15/08/1990") }
    var panNumber by remember(currentUser) {
        mutableStateOf(currentUser?.panNumber?.let { maskPan(it) } ?: "")
    }

    // Address state
    var addressLine1 by remember { mutableStateOf("42, Ashok Nagar") }
    var addressLine2 by remember { mutableStateOf("Near MG Road Metro Station") }
    var city by remember { mutableStateOf("Bengaluru") }
    var selectedState by remember { mutableStateOf("Karnataka") }
    var pinCode by remember { mutableStateOf("560001") }

    // Validation
    var showErrors by remember { mutableStateOf(false) }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .statusBarsPadding()
                .padding(paddingValues)
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
                    text = "Edit Profile",
                    style = MaterialTheme.typography.titleLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.weight(1f)
                )
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = Spacing.medium)
            ) {
                Spacer(modifier = Modifier.height(Spacing.medium))

                // Section 1: Profile Photo
                Box(
                    modifier = Modifier.fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Box {
                        Avatar(
                            initials = currentUser?.initials ?: "U",
                            size = 96,
                            backgroundColor = Primary
                        )
                        // Camera overlay button
                        Box(
                            modifier = Modifier
                                .size(32.dp)
                                .align(Alignment.BottomEnd)
                                .offset(x = 4.dp, y = 4.dp)
                                .clip(CircleShape)
                                .background(Primary)
                                .clickable { /* Camera action */ },
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.CameraAlt,
                                contentDescription = "Change Photo",
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(Spacing.xLarge))

                // Section 2: Personal Information
                GlassFormCard(isDark = isDark) {
                    Text(
                        text = "PERSONAL INFORMATION",
                        style = MaterialTheme.typography.labelSmall,
                        color = Primary,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = MaterialTheme.typography.labelSmall.letterSpacing
                    )

                    Spacer(modifier = Modifier.height(Spacing.medium))

                    ProfileTextField(
                        label = "FIRST NAME",
                        value = firstName,
                        onValueChange = { firstName = it },
                        isError = showErrors && firstName.isBlank(),
                        errorMessage = "First name is required"
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "LAST NAME",
                        value = lastName,
                        onValueChange = { lastName = it },
                        isError = showErrors && lastName.isBlank(),
                        errorMessage = "Last name is required"
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "EMAIL",
                        value = email,
                        onValueChange = { },
                        enabled = false,
                        keyboardType = KeyboardType.Email
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "PHONE NUMBER",
                        value = phone,
                        onValueChange = { newValue ->
                            phone = newValue.filter { it.isDigit() }.take(10)
                        },
                        keyboardType = KeyboardType.Phone,
                        prefix = "+91 "
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "DATE OF BIRTH",
                        value = dateOfBirth,
                        onValueChange = { dateOfBirth = it },
                        placeholder = "DD/MM/YYYY"
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "PAN NUMBER",
                        value = panNumber,
                        onValueChange = { newValue ->
                            panNumber = newValue.uppercase().take(10)
                        },
                        placeholder = "ABCDE1234F"
                    )
                }

                Spacer(modifier = Modifier.height(Spacing.medium))

                // Section 3: Address
                GlassFormCard(isDark = isDark) {
                    Text(
                        text = "ADDRESS",
                        style = MaterialTheme.typography.labelSmall,
                        color = Primary,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = MaterialTheme.typography.labelSmall.letterSpacing
                    )

                    Spacer(modifier = Modifier.height(Spacing.medium))

                    ProfileTextField(
                        label = "ADDRESS LINE 1",
                        value = addressLine1,
                        onValueChange = { addressLine1 = it },
                        isError = showErrors && addressLine1.isBlank(),
                        errorMessage = "Address is required"
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "ADDRESS LINE 2",
                        value = addressLine2,
                        onValueChange = { addressLine2 = it }
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "CITY",
                        value = city,
                        onValueChange = { city = it },
                        isError = showErrors && city.isBlank(),
                        errorMessage = "City is required"
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    StateDropdown(
                        label = "STATE",
                        selectedState = selectedState,
                        onStateSelected = { selectedState = it },
                        isDark = isDark
                    )

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    ProfileTextField(
                        label = "PIN CODE",
                        value = pinCode,
                        onValueChange = { newValue ->
                            pinCode = newValue.filter { it.isDigit() }.take(6)
                        },
                        keyboardType = KeyboardType.Number,
                        isError = showErrors && pinCode.length != 6,
                        errorMessage = "Enter a valid 6-digit PIN code"
                    )
                }

                Spacer(modifier = Modifier.height(Spacing.xLarge))

                // Save Button
                PrimaryButton(
                    text = "Save Changes",
                    onClick = {
                        showErrors = true
                        val isValid = firstName.isNotBlank() &&
                                lastName.isNotBlank() &&
                                addressLine1.isNotBlank() &&
                                city.isNotBlank() &&
                                pinCode.length == 6

                        if (isValid) {
                            coroutineScope.launch {
                                snackbarHostState.showSnackbar("Profile updated successfully")
                            }
                        }
                    },
                    modifier = Modifier.padding(bottom = Spacing.medium)
                )

                Spacer(modifier = Modifier.height(Spacing.large))
            }
        }
    }
}

@Composable
private fun GlassFormCard(
    isDark: Boolean,
    content: @Composable () -> Unit
) {
    val shape = RoundedCornerShape(CornerRadius.xLarge)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = if (isDark) {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (!isDark) {
                    Modifier.shadow(
                        elevation = 12.dp,
                        shape = shape,
                        spotColor = ShadowColor,
                        ambientColor = ShadowColor
                    )
                } else Modifier
            )
            .clip(shape)
            .background(backgroundColor)
            .border(width = 1.dp, brush = borderBrush, shape = shape)
            .padding(Spacing.medium)
    ) {
        content()
    }
}

@Composable
private fun ProfileTextField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    placeholder: String = "",
    prefix: String = "",
    keyboardType: KeyboardType = KeyboardType.Text,
    isError: Boolean = false,
    errorMessage: String? = null
) {
    val isDark = LocalIsDarkTheme.current

    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = Primary,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(Spacing.micro))

        OutlinedTextField(
            value = if (prefix.isNotEmpty()) "$prefix$value" else value,
            onValueChange = { newValue ->
                if (prefix.isNotEmpty()) {
                    val stripped = if (newValue.startsWith(prefix)) {
                        newValue.removePrefix(prefix)
                    } else {
                        newValue
                    }
                    onValueChange(stripped)
                } else {
                    onValueChange(newValue)
                }
            },
            modifier = Modifier.fillMaxWidth(),
            enabled = enabled,
            placeholder = {
                if (placeholder.isNotEmpty()) {
                    Text(
                        text = placeholder,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                    )
                }
            },
            isError = isError,
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyMedium.copy(
                color = if (enabled) MaterialTheme.colorScheme.onSurface
                else MaterialTheme.colorScheme.onSurfaceVariant
            ),
            keyboardOptions = KeyboardOptions(
                keyboardType = keyboardType,
                imeAction = ImeAction.Next
            ),
            shape = RoundedCornerShape(CornerRadius.medium),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = Primary,
                unfocusedBorderColor = if (isDark) Color.White.copy(alpha = 0.12f)
                else Color.Black.copy(alpha = 0.12f),
                disabledBorderColor = if (isDark) Color.White.copy(alpha = 0.06f)
                else Color.Black.copy(alpha = 0.06f),
                disabledTextColor = MaterialTheme.colorScheme.onSurfaceVariant,
                errorBorderColor = Color(0xFFEF4444),
                focusedContainerColor = Color.Transparent,
                unfocusedContainerColor = Color.Transparent,
                disabledContainerColor = if (isDark) Color.White.copy(alpha = 0.04f)
                else Color.Black.copy(alpha = 0.04f)
            )
        )

        AnimatedVisibility(visible = isError && errorMessage != null) {
            Text(
                text = errorMessage ?: "",
                style = MaterialTheme.typography.bodySmall,
                color = Color(0xFFEF4444),
                modifier = Modifier.padding(top = Spacing.micro, start = Spacing.small)
            )
        }
    }
}

@Composable
private fun StateDropdown(
    label: String,
    selectedState: String,
    onStateSelected: (String) -> Unit,
    isDark: Boolean
) {
    var expanded by remember { mutableStateOf(false) }

    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = Primary,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(Spacing.micro))

        Box {
            OutlinedTextField(
                value = selectedState,
                onValueChange = { },
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { expanded = true },
                enabled = false,
                readOnly = true,
                trailingIcon = {
                    Icon(
                        imageVector = Icons.Default.KeyboardArrowDown,
                        contentDescription = "Select State",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                },
                textStyle = MaterialTheme.typography.bodyMedium.copy(
                    color = MaterialTheme.colorScheme.onSurface
                ),
                shape = RoundedCornerShape(CornerRadius.medium),
                colors = OutlinedTextFieldDefaults.colors(
                    disabledBorderColor = if (isDark) Color.White.copy(alpha = 0.12f)
                    else Color.Black.copy(alpha = 0.12f),
                    disabledTextColor = MaterialTheme.colorScheme.onSurface,
                    disabledContainerColor = Color.Transparent
                )
            )

            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                indianStates.forEach { state ->
                    DropdownMenuItem(
                        text = {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = state,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                                if (state == selectedState) {
                                    Icon(
                                        imageVector = Icons.Default.Check,
                                        contentDescription = null,
                                        tint = Primary,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        },
                        onClick = {
                            onStateSelected(state)
                            expanded = false
                        }
                    )
                }
            }
        }
    }
}

private fun maskPan(pan: String): String {
    if (pan.length < 4) return pan
    return pan.take(2) + "*".repeat(pan.length - 4) + pan.takeLast(2)
}
