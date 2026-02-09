package com.sparrowinvest.fa.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.fa.core.network.ApiResult
import com.sparrowinvest.fa.data.model.NotificationCategory
import com.sparrowinvest.fa.data.model.NotificationChannelType
import com.sparrowinvest.fa.data.model.NotificationPreferences
import com.sparrowinvest.fa.data.model.PreferenceUpdate
import com.sparrowinvest.fa.data.repository.NotificationRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class NotificationsUiState {
    data object Loading : NotificationsUiState()
    data class Success(val preferences: NotificationPreferences) : NotificationsUiState()
    data class Error(val message: String) : NotificationsUiState()
}

@HiltViewModel
class NotificationsViewModel @Inject constructor(
    private val notificationRepository: NotificationRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<NotificationsUiState>(NotificationsUiState.Loading)
    val uiState: StateFlow<NotificationsUiState> = _uiState.asStateFlow()

    init {
        loadPreferences()
    }

    fun loadPreferences() {
        viewModelScope.launch {
            _uiState.value = NotificationsUiState.Loading
            when (val result = notificationRepository.getPreferences()) {
                is ApiResult.Success -> {
                    _uiState.value = NotificationsUiState.Success(result.data)
                }
                is ApiResult.Error -> {
                    _uiState.value = NotificationsUiState.Error(result.message)
                }
                else -> {}
            }
        }
    }

    fun togglePreference(category: NotificationCategory, channel: NotificationChannelType, enabled: Boolean) {
        val currentState = _uiState.value
        if (currentState !is NotificationsUiState.Success) return

        // Optimistic update
        val updatedPrefs = currentState.preferences.toMutableMap()
        val categoryPrefs = (updatedPrefs[category.key] ?: emptyMap()).toMutableMap()
        categoryPrefs[channel.key] = enabled
        updatedPrefs[category.key] = categoryPrefs
        _uiState.value = NotificationsUiState.Success(updatedPrefs)

        // Sync with backend
        viewModelScope.launch {
            val result = notificationRepository.updatePreferences(
                listOf(PreferenceUpdate(category.key, channel.key, enabled))
            )
            if (result is ApiResult.Error) {
                // Revert on failure
                val revertedPrefs = currentState.preferences.toMutableMap()
                val revertedCategoryPrefs = (revertedPrefs[category.key] ?: emptyMap()).toMutableMap()
                revertedCategoryPrefs[channel.key] = !enabled
                revertedPrefs[category.key] = revertedCategoryPrefs
                _uiState.value = NotificationsUiState.Success(revertedPrefs)
            }
        }
    }

    fun isEnabled(prefs: NotificationPreferences, category: NotificationCategory, channel: NotificationChannelType): Boolean {
        return prefs[category.key]?.get(channel.key) ?: false
    }
}
