package com.sparrowinvest.app.ui.auth

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import com.sparrowinvest.app.ui.components.GlassTextField
import com.sparrowinvest.app.ui.components.OtpInput
import com.sparrowinvest.app.ui.components.PrimaryButton
import com.sparrowinvest.app.ui.components.TopBar
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import kotlinx.coroutines.delay

private enum class ForgotPasswordStep {
    EMAIL,
    OTP,
    NEW_PASSWORD
}

@Composable
fun ForgotPasswordScreen(
    viewModel: AuthViewModel,
    onBackToLogin: () -> Unit
) {
    var currentStep by remember { mutableStateOf(ForgotPasswordStep.EMAIL) }
    var email by remember { mutableStateOf("") }
    var otp by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var showSuccess by remember { mutableStateOf(false) }
    var resendCountdown by remember { mutableIntStateOf(0) }
    var localError by remember { mutableStateOf<String?>(null) }

    val otpState by viewModel.otpState.collectAsState()

    val isLoading = otpState is AuthState.Loading
    val apiError = (otpState as? AuthState.Error)?.message
    val displayError = localError ?: apiError

    // Clear local error when API error changes
    LaunchedEffect(apiError) {
        if (apiError != null) {
            localError = null
        }
    }

    // Handle state transitions from viewModel
    LaunchedEffect(otpState) {
        when (otpState) {
            is AuthState.OtpSent -> {
                currentStep = ForgotPasswordStep.OTP
                resendCountdown = 30
                localError = null
                viewModel.resetOtpState()
            }
            is AuthState.OtpVerified -> {
                currentStep = ForgotPasswordStep.NEW_PASSWORD
                localError = null
                viewModel.resetOtpState()
            }
            is AuthState.PasswordResetSuccess -> {
                showSuccess = true
                viewModel.resetOtpState()
            }
            else -> {}
        }
    }

    // Countdown timer for resend
    LaunchedEffect(resendCountdown) {
        if (resendCountdown > 0) {
            delay(1000)
            resendCountdown--
        }
    }

    // Navigate back to login after success
    LaunchedEffect(showSuccess) {
        if (showSuccess) {
            delay(2000)
            onBackToLogin()
        }
    }

    val onBack: () -> Unit = {
        localError = null
        viewModel.resetOtpState()
        when (currentStep) {
            ForgotPasswordStep.EMAIL -> onBackToLogin()
            ForgotPasswordStep.OTP -> {
                currentStep = ForgotPasswordStep.EMAIL
                otp = ""
            }
            ForgotPasswordStep.NEW_PASSWORD -> {
                currentStep = ForgotPasswordStep.OTP
                newPassword = ""
                confirmPassword = ""
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .imePadding()
            .verticalScroll(rememberScrollState())
    ) {
        TopBar(
            title = "",
            onBackClick = onBack
        )

        AnimatedContent(
            targetState = currentStep,
            transitionSpec = {
                slideInHorizontally { fullWidth -> fullWidth } togetherWith
                        slideOutHorizontally { fullWidth -> -fullWidth }
            },
            label = "forgot_password_step"
        ) { step ->
            when {
                showSuccess -> {
                    SuccessContent()
                }
                else -> when (step) {
                    ForgotPasswordStep.EMAIL -> {
                        EmailStepContent(
                            email = email,
                            onEmailChange = { email = it },
                            onSendCode = {
                                if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                                    localError = "Please enter a valid email address"
                                } else {
                                    localError = null
                                    viewModel.sendOtp(email)
                                }
                            },
                            isLoading = isLoading,
                            errorMessage = displayError
                        )
                    }
                    ForgotPasswordStep.OTP -> {
                        OtpStepContent(
                            email = email,
                            otp = otp,
                            onOtpChange = { otp = it },
                            onVerify = {
                                if (otp.length != 6) {
                                    localError = "Please enter the complete 6-digit code"
                                } else {
                                    localError = null
                                    viewModel.verifyOtp(email, otp)
                                }
                            },
                            onResend = {
                                viewModel.resendOtp(email)
                                resendCountdown = 30
                            },
                            resendCountdown = resendCountdown,
                            isLoading = isLoading,
                            errorMessage = displayError
                        )
                    }
                    ForgotPasswordStep.NEW_PASSWORD -> {
                        NewPasswordStepContent(
                            newPassword = newPassword,
                            onNewPasswordChange = { newPassword = it },
                            confirmPassword = confirmPassword,
                            onConfirmPasswordChange = { confirmPassword = it },
                            passwordVisible = passwordVisible,
                            onTogglePasswordVisibility = { passwordVisible = !passwordVisible },
                            onResetPassword = {
                                when {
                                    newPassword.length < 6 -> {
                                        localError = "Password must be at least 6 characters"
                                    }
                                    newPassword != confirmPassword -> {
                                        localError = "Passwords don't match"
                                    }
                                    else -> {
                                        localError = null
                                        viewModel.resetPassword(email, otp, newPassword)
                                    }
                                }
                            },
                            isLoading = isLoading,
                            errorMessage = displayError
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun EmailStepContent(
    email: String,
    onEmailChange: (String) -> Unit,
    onSendCode: () -> Unit,
    isLoading: Boolean,
    errorMessage: String?
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(Spacing.large)
    ) {
        Spacer(modifier = Modifier.height(Spacing.large))

        Text(
            text = "Forgot Password",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Text(
            text = "Enter your email address and we'll send you a code to reset your password",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(Spacing.xxLarge))

        GlassTextField(
            value = email,
            onValueChange = onEmailChange,
            placeholder = "Email",
            prefix = {
                Icon(
                    imageVector = Icons.Default.Email,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            },
            keyboardType = KeyboardType.Email,
            imeAction = ImeAction.Done,
            isError = errorMessage != null,
            errorMessage = errorMessage,
            onImeAction = onSendCode
        )

        Spacer(modifier = Modifier.height(Spacing.xxLarge))

        PrimaryButton(
            text = "Send Reset Code",
            onClick = onSendCode,
            enabled = email.isNotBlank(),
            isLoading = isLoading
        )
    }
}

@Composable
private fun OtpStepContent(
    email: String,
    otp: String,
    onOtpChange: (String) -> Unit,
    onVerify: () -> Unit,
    onResend: () -> Unit,
    resendCountdown: Int,
    isLoading: Boolean,
    errorMessage: String?
) {
    val canResend = resendCountdown == 0

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(Spacing.large))

        Text(
            text = "Enter Reset Code",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Text(
            text = "Enter the 6-digit code sent to $email",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(Spacing.xxLarge))

        OtpInput(
            value = otp,
            onValueChange = onOtpChange,
            isError = errorMessage != null
        )

        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(Spacing.small))
            Text(
                text = errorMessage,
                style = MaterialTheme.typography.bodySmall,
                color = Error
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xxLarge))

        PrimaryButton(
            text = "Verify Code",
            onClick = onVerify,
            enabled = otp.length == 6,
            isLoading = isLoading
        )

        Spacer(modifier = Modifier.height(Spacing.large))

        if (canResend) {
            TextButton(onClick = onResend) {
                Text(
                    text = "Resend Code",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Primary
                )
            }
        } else {
            Text(
                text = "Resend code in ${resendCountdown}s",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun NewPasswordStepContent(
    newPassword: String,
    onNewPasswordChange: (String) -> Unit,
    confirmPassword: String,
    onConfirmPasswordChange: (String) -> Unit,
    passwordVisible: Boolean,
    onTogglePasswordVisibility: () -> Unit,
    onResetPassword: () -> Unit,
    isLoading: Boolean,
    errorMessage: String?
) {
    val passwordsMatch = confirmPassword.isEmpty() || newPassword == confirmPassword
    val passwordLongEnough = newPassword.isEmpty() || newPassword.length >= 6
    val isFormValid = newPassword.length >= 6 && newPassword == confirmPassword

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(Spacing.large)
    ) {
        Spacer(modifier = Modifier.height(Spacing.large))

        Text(
            text = "Create New Password",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Text(
            text = "Enter your new password below",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(Spacing.xxLarge))

        GlassTextField(
            value = newPassword,
            onValueChange = onNewPasswordChange,
            placeholder = "New Password",
            prefix = {
                Icon(
                    imageVector = Icons.Default.Lock,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            },
            suffix = {
                IconButton(onClick = onTogglePasswordVisibility) {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Default.VisibilityOff else Icons.Default.Visibility,
                        contentDescription = if (passwordVisible) "Hide password" else "Show password",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            },
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardType = KeyboardType.Password,
            imeAction = ImeAction.Next,
            isError = !passwordLongEnough,
            errorMessage = if (!passwordLongEnough) "Password must be at least 6 characters" else null
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        GlassTextField(
            value = confirmPassword,
            onValueChange = onConfirmPasswordChange,
            placeholder = "Confirm New Password",
            prefix = {
                Icon(
                    imageVector = Icons.Default.Lock,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            },
            visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            keyboardType = KeyboardType.Password,
            imeAction = ImeAction.Done,
            isError = !passwordsMatch,
            errorMessage = if (!passwordsMatch) "Passwords don't match" else null,
            onImeAction = {
                if (isFormValid) {
                    onResetPassword()
                }
            }
        )

        if (errorMessage != null) {
            Spacer(modifier = Modifier.height(Spacing.small))
            Text(
                text = errorMessage,
                style = MaterialTheme.typography.bodySmall,
                color = Error
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xxLarge))

        PrimaryButton(
            text = "Reset Password",
            onClick = onResetPassword,
            enabled = isFormValid,
            isLoading = isLoading
        )
    }
}

@Composable
private fun SuccessContent() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(Spacing.xxxLarge))

        Text(
            text = "Password Reset",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Text(
            text = "Your password has been reset successfully. Redirecting to login...",
            style = MaterialTheme.typography.bodyLarge,
            color = Success
        )
    }
}
