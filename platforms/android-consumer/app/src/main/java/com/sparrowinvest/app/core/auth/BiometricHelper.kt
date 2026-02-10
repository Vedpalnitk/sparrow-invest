package com.sparrowinvest.app.core.auth

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

/**
 * Result sealed class representing the outcome of a biometric authentication attempt.
 */
sealed class BiometricResult {
    /** Authentication succeeded. */
    data object Success : BiometricResult()

    /** User cancelled the biometric prompt. */
    data object Cancelled : BiometricResult()

    /** User chose to use password instead (negative button). */
    data object UsePassword : BiometricResult()

    /** An error occurred during authentication. */
    data class Error(val message: String) : BiometricResult()
}

/**
 * Utility class for managing biometric authentication using the AndroidX Biometric API.
 * Mirrors the iOS BiometricManager pattern.
 */
class BiometricHelper {

    companion object {

        private const val ALLOWED_AUTHENTICATORS =
            BiometricManager.Authenticators.BIOMETRIC_STRONG or
                    BiometricManager.Authenticators.BIOMETRIC_WEAK

        /**
         * Check whether biometric authentication is available on this device.
         */
        fun canAuthenticate(context: Context): Boolean {
            val biometricManager = BiometricManager.from(context)
            return biometricManager.canAuthenticate(ALLOWED_AUTHENTICATORS) ==
                    BiometricManager.BIOMETRIC_SUCCESS
        }

        /**
         * Returns the biometric type name suitable for display in the UI.
         * Returns "Fingerprint" when fingerprint hardware is detected,
         * or "Biometric" as a generic fallback (covers Face, Iris, etc.).
         */
        fun getBiometricType(context: Context): String {
            val biometricManager = BiometricManager.from(context)

            // On API 30+ we can check for BIOMETRIC_STRONG specifically;
            // fingerprint is the most common strong biometric on Android.
            // We use the package manager to detect fingerprint hardware.
            val hasFingerprint = context.packageManager
                .hasSystemFeature("android.hardware.fingerprint")

            return if (hasFingerprint) "Fingerprint" else "Biometric"
        }

        /**
         * Returns the Material icon name hint for the biometric type.
         * Useful for determining which icon to show in the UI.
         */
        fun isFingerprint(context: Context): Boolean {
            return context.packageManager
                .hasSystemFeature("android.hardware.fingerprint")
        }

        /**
         * Launch the system biometric prompt. Requires a [FragmentActivity] as the host.
         *
         * @param activity  The hosting FragmentActivity (required by BiometricPrompt).
         * @param title     Optional title for the prompt dialog.
         * @param subtitle  Optional subtitle for the prompt dialog.
         * @param onResult  Callback invoked with the [BiometricResult].
         */
        fun authenticate(
            activity: FragmentActivity,
            title: String = "Authenticate",
            subtitle: String = "Use your biometric to sign in",
            onResult: (BiometricResult) -> Unit
        ) {
            val executor = ContextCompat.getMainExecutor(activity)

            val callback = object : BiometricPrompt.AuthenticationCallback() {

                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult
                ) {
                    super.onAuthenticationSucceeded(result)
                    onResult(BiometricResult.Success)
                }

                override fun onAuthenticationError(
                    errorCode: Int,
                    errString: CharSequence
                ) {
                    super.onAuthenticationError(errorCode, errString)
                    when (errorCode) {
                        BiometricPrompt.ERROR_USER_CANCELED,
                        BiometricPrompt.ERROR_CANCELED ->
                            onResult(BiometricResult.Cancelled)

                        BiometricPrompt.ERROR_NEGATIVE_BUTTON ->
                            onResult(BiometricResult.UsePassword)

                        else ->
                            onResult(BiometricResult.Error(errString.toString()))
                    }
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    // Do not invoke onResult here.
                    // The system will automatically allow the user to retry,
                    // and will eventually call onAuthenticationError if too many
                    // attempts fail.
                }
            }

            val biometricPrompt = BiometricPrompt(activity, executor, callback)

            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle)
                .setNegativeButtonText("Use Password")
                .setAllowedAuthenticators(ALLOWED_AUTHENTICATORS)
                .build()

            biometricPrompt.authenticate(promptInfo)
        }
    }
}
