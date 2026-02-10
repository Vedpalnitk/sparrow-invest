package com.sparrowinvest.app.ui.auth

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.fragment.app.FragmentActivity
import com.sparrowinvest.app.core.auth.BiometricHelper
import com.sparrowinvest.app.core.auth.BiometricResult
import com.sparrowinvest.app.ui.theme.AppGradients
import com.sparrowinvest.app.ui.theme.AppTextStyles
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import kotlinx.coroutines.delay

/**
 * Biometric Login Screen -- Android equivalent of iOS BiometricLoginView.swift.
 *
 * Shows a fingerprint/biometric icon inside a glass circle with radial glow,
 * "Welcome back" title, optional user name, error display, and bottom action
 * buttons. Auto-triggers biometric authentication on appear.
 *
 * @param userName  Optional user first name to display below the greeting.
 * @param onAuthSuccess  Callback invoked when biometric authentication succeeds.
 * @param onUsePassword  Callback invoked when the user opts to use password instead.
 */
@Composable
fun BiometricLoginScreen(
    userName: String?,
    onAuthSuccess: () -> Unit,
    onUsePassword: () -> Unit
) {
    val context = LocalContext.current
    val isDark = LocalIsDarkTheme.current

    var isAuthenticating by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var showError by remember { mutableStateOf(false) }

    // Entrance animation states
    var iconVisible by remember { mutableStateOf(false) }
    val iconScale by animateFloatAsState(
        targetValue = if (iconVisible) 1f else 0.8f,
        animationSpec = spring(
            dampingRatio = 0.7f,
            stiffness = Spring.StiffnessLow
        ),
        label = "biometric_icon_scale"
    )
    val iconAlpha by animateFloatAsState(
        targetValue = if (iconVisible) 1f else 0f,
        animationSpec = spring(
            dampingRatio = 1f,
            stiffness = Spring.StiffnessMediumLow
        ),
        label = "biometric_icon_alpha"
    )

    // Glass border brush (matching GlassCard)
    val glassBorderBrush = if (isDark) {
        Brush.linearGradient(
            colors = listOf(
                GlassBorderStartDark,
                GlassBorderMidDark,
                GlassBorderEndDark
            )
        )
    } else {
        Brush.linearGradient(
            colors = listOf(
                GlassBorderStartLight,
                GlassBorderMidLight,
                GlassBorderEndLight
            )
        )
    }

    // Biometric type info
    val biometricTypeName = remember { BiometricHelper.getBiometricType(context) }

    // Perform biometric authentication
    fun performBiometricAuth() {
        if (isAuthenticating) return
        isAuthenticating = true
        showError = false
        errorMessage = null

        val activity = context as? FragmentActivity
        if (activity == null) {
            errorMessage = "Unable to start authentication."
            showError = true
            isAuthenticating = false
            return
        }

        BiometricHelper.authenticate(
            activity = activity,
            title = "Authenticate",
            subtitle = "Use your biometric to sign in to Sparrow Invest"
        ) { result ->
            isAuthenticating = false
            when (result) {
                is BiometricResult.Success -> {
                    onAuthSuccess()
                }
                is BiometricResult.Cancelled -> {
                    // User cancelled -- do not show error, allow re-tap
                }
                is BiometricResult.UsePassword -> {
                    onUsePassword()
                }
                is BiometricResult.Error -> {
                    errorMessage = result.message
                    showError = true
                }
            }
        }
    }

    // Auto-trigger biometric on screen appear (with short delay)
    LaunchedEffect(Unit) {
        iconVisible = true
        delay(400)
        performBiometricAuth()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .padding(horizontal = Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.weight(1f))

        // ---- Logo (matching iOS: bird icon + "Sparrow Invest") ----
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Default.Fingerprint,
                contentDescription = null,
                modifier = Modifier.size(28.dp),
                tint = Primary
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "Sparrow Invest",
                style = MaterialTheme.typography.headlineLarge.copy(
                    fontWeight = FontWeight.Normal
                ),
                color = MaterialTheme.colorScheme.onSurface
            )
        }

        Spacer(modifier = Modifier.height(48.dp))

        // ---- Biometric Icon with Glass Circle and Radial Glow ----
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier
                .graphicsLayer {
                    scaleX = iconScale
                    scaleY = iconScale
                    alpha = iconAlpha
                }
        ) {
            // Outer radial glow
            Box(
                modifier = Modifier
                    .size(160.dp)
                    .background(
                        brush = Brush.radialGradient(
                            colors = listOf(
                                Primary.copy(alpha = if (isDark) 0.15f else 0.1f),
                                Color.Transparent
                            )
                        ),
                        shape = CircleShape
                    )
            )

            // Glass circle
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .then(
                        if (!isDark) {
                            Modifier.shadow(
                                elevation = 16.dp,
                                shape = CircleShape,
                                spotColor = Color.Black.copy(alpha = 0.08f),
                                ambientColor = Color.Black.copy(alpha = 0.08f)
                            )
                        } else Modifier
                    )
                    .clip(CircleShape)
                    .background(
                        if (isDark) Color.White.copy(alpha = 0.06f) else Color.White
                    )
                    .border(1.dp, glassBorderBrush, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                // Fingerprint icon
                Icon(
                    imageVector = Icons.Default.Fingerprint,
                    contentDescription = "Biometric authentication",
                    modifier = Modifier.size(48.dp),
                    tint = Primary
                )
            }
        }

        Spacer(modifier = Modifier.height(28.dp))

        // ---- Welcome Title ----
        Text(
            text = "Welcome back",
            style = MaterialTheme.typography.headlineMedium.copy(
                fontWeight = FontWeight.Normal
            ),
            color = MaterialTheme.colorScheme.onSurface
        )

        // User name subtitle
        if (!userName.isNullOrBlank()) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = userName,
                style = MaterialTheme.typography.bodyLarge.copy(
                    fontWeight = FontWeight.Light
                ),
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // ---- Error Message ----
        AnimatedVisibility(
            visible = showError && errorMessage != null,
            enter = fadeIn() + slideInVertically { -it / 2 },
            exit = fadeOut()
        ) {
            Row(
                modifier = Modifier.padding(top = Spacing.medium, bottom = Spacing.small),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.error
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = errorMessage ?: "",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    textAlign = TextAlign.Center
                )
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        // ---- Bottom Action Buttons ----
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 40.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            // Authenticate with Fingerprint -- gradient button
            val shape = RoundedCornerShape(CornerRadius.medium)
            val interactionSource = remember { MutableInteractionSource() }

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp)
                    .clip(shape)
                    .background(
                        brush = if (!isAuthenticating) {
                            Brush.linearGradient(listOf(Primary, Secondary))
                        } else {
                            Brush.linearGradient(
                                listOf(
                                    Color.Gray.copy(alpha = 0.3f),
                                    Color.Gray.copy(alpha = 0.3f)
                                )
                            )
                        }
                    )
                    .clickable(
                        interactionSource = interactionSource,
                        indication = null,
                        enabled = !isAuthenticating
                    ) {
                        performBiometricAuth()
                    },
                contentAlignment = Alignment.Center
            ) {
                if (isAuthenticating) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Fingerprint,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp),
                            tint = Color.White
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Text(
                            text = "Authenticate with $biometricTypeName",
                            style = AppTextStyles.buttonText,
                            color = Color.White
                        )
                    }
                }
            }

            // Use Password Instead -- text button
            TextButton(
                onClick = onUsePassword,
                enabled = !isAuthenticating
            ) {
                Text(
                    text = "Use Password Instead",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Primary
                )
            }
        }
    }
}
