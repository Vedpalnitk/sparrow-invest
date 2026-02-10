package com.sparrowinvest.app.ui.auth

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
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.sparrowinvest.app.ui.components.OtpTextField
import com.sparrowinvest.app.ui.components.TopBar
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Spacing
import kotlinx.coroutines.delay

@Composable
fun OtpVerificationScreen(
    email: String,
    verificationType: String,
    viewModel: AuthViewModel,
    onVerificationSuccess: () -> Unit,
    onBackClick: () -> Unit
) {
    val otpState by viewModel.otpState.collectAsState()

    val isLoading = otpState is AuthState.Loading
    val errorMessage = (otpState as? AuthState.Error)?.message

    var resendCountdown by remember { mutableIntStateOf(30) }
    val canResend = resendCountdown == 0

    // Countdown timer for resend
    LaunchedEffect(resendCountdown) {
        if (resendCountdown > 0) {
            delay(1000)
            resendCountdown--
        }
    }

    // Handle verification success
    LaunchedEffect(otpState) {
        if (otpState is AuthState.OtpVerified) {
            onVerificationSuccess()
            viewModel.resetOtpState()
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
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.large),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(Spacing.large))

            Text(
                text = "Verify Your Email",
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

            OtpTextField(
                onOtpComplete = { otp ->
                    viewModel.verifyOtp(email, otp)
                },
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

            if (canResend) {
                TextButton(
                    onClick = {
                        viewModel.resendOtp(email)
                        resendCountdown = 30
                    }
                ) {
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
}
