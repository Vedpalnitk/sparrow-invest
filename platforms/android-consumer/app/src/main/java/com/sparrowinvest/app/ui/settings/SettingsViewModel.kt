package com.sparrowinvest.app.ui.settings

import androidx.lifecycle.ViewModel
import com.sparrowinvest.app.MainActivity
import com.sparrowinvest.app.core.storage.PreferencesManager
import com.sparrowinvest.app.core.storage.ThemeMode
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val preferencesManager: PreferencesManager
) : ViewModel() {

    private val _themeMode = MutableStateFlow(preferencesManager.themeMode)
    val themeMode: StateFlow<ThemeMode> = _themeMode.asStateFlow()

    private val _notificationsEnabled = MutableStateFlow(true)
    val notificationsEnabled: StateFlow<Boolean> = _notificationsEnabled.asStateFlow()

    private val _biometricEnabled = MutableStateFlow(preferencesManager.biometricEnabled)
    val biometricEnabled: StateFlow<Boolean> = _biometricEnabled.asStateFlow()

    fun setThemeMode(mode: ThemeMode) {
        preferencesManager.themeMode = mode
        _themeMode.value = mode
        // Update the global theme flow to trigger recomposition
        MainActivity.themeModeFlow.value = mode
    }

    fun setDarkModeEnabled(enabled: Boolean) {
        val mode = if (enabled) ThemeMode.DARK else ThemeMode.LIGHT
        setThemeMode(mode)
    }

    fun setNotificationsEnabled(enabled: Boolean) {
        _notificationsEnabled.value = enabled
    }

    fun setBiometricEnabled(enabled: Boolean) {
        preferencesManager.biometricEnabled = enabled
        _biometricEnabled.value = enabled
    }

    fun clearCache() {
        // Implementation for clearing cache
    }
}
