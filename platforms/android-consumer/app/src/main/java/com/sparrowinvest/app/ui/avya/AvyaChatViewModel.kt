package com.sparrowinvest.app.ui.avya

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.app.core.network.ApiResult
import com.sparrowinvest.app.data.repository.ChatRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class AvyaChatUiState(
    val messages: List<ChatMessage> = emptyList(),
    val isProcessing: Boolean = false,
    val currentSessionId: String? = null,
    val errorMessage: String? = null
)

@HiltViewModel
class AvyaChatViewModel @Inject constructor(
    private val chatRepository: ChatRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AvyaChatUiState())
    val uiState: StateFlow<AvyaChatUiState> = _uiState.asStateFlow()

    private var pollingJob: Job? = null
    private var pendingMessageId: String? = null

    private val pollingIntervalMs = 500L
    private val maxPollingAttempts = 120

    init {
        // Auto-clear chat state on logout to prevent cross-user data leakage
        viewModelScope.launch {
            chatRepository.logoutEvent.collect {
                clearChat()
            }
        }
    }

    fun sendMessage(content: String) {
        val trimmedContent = content.trim()
        if (trimmedContent.isEmpty()) return

        viewModelScope.launch {
            if (_uiState.value.currentSessionId == null) {
                val sessionResult = chatRepository.createSession("Chat Session")
                when (sessionResult) {
                    is ApiResult.Success -> {
                        _uiState.update { it.copy(currentSessionId = sessionResult.data.id) }
                    }
                    is ApiResult.Error -> {
                        _uiState.update { it.copy(errorMessage = sessionResult.message) }
                        return@launch
                    }
                    else -> return@launch
                }
            }

            val sessionId = _uiState.value.currentSessionId ?: return@launch

            val userMessage = ChatMessage(
                content = trimmedContent,
                isUser = true
            )
            _uiState.update { state ->
                state.copy(
                    messages = state.messages + userMessage,
                    isProcessing = true,
                    errorMessage = null
                )
            }

            val result = chatRepository.sendMessage(
                sessionId = sessionId,
                content = trimmedContent,
                speakResponse = false
            )

            when (result) {
                is ApiResult.Success -> {
                    pendingMessageId = result.data.messageId
                    startPolling()
                }
                is ApiResult.Error -> {
                    _uiState.update { state ->
                        state.copy(
                            isProcessing = false,
                            messages = state.messages + ChatMessage(
                                content = "Sorry, I couldn't process your request. Please try again.",
                                isUser = false
                            )
                        )
                    }
                }
                else -> {
                    _uiState.update { it.copy(isProcessing = false) }
                }
            }
        }
    }

    private fun startPolling() {
        pollingJob?.cancel()
        pollingJob = viewModelScope.launch {
            var attempts = 0

            while (attempts < maxPollingAttempts) {
                delay(pollingIntervalMs)
                attempts++

                val messageId = pendingMessageId ?: break

                val result = chatRepository.getMessageStatus(messageId)

                when (result) {
                    is ApiResult.Success -> {
                        val status = result.data

                        when (status.status) {
                            "complete" -> {
                                pendingMessageId = null
                                _uiState.update { state ->
                                    state.copy(
                                        isProcessing = false,
                                        messages = state.messages + ChatMessage(
                                            id = messageId,
                                            content = status.content ?: "",
                                            isUser = false
                                        )
                                    )
                                }
                                break
                            }
                            "error" -> {
                                pendingMessageId = null
                                _uiState.update { state ->
                                    state.copy(
                                        isProcessing = false,
                                        messages = state.messages + ChatMessage(
                                            id = messageId,
                                            content = status.error ?: "An error occurred.",
                                            isUser = false
                                        )
                                    )
                                }
                                break
                            }
                        }
                    }
                    is ApiResult.Error -> { }
                    else -> {}
                }
            }

            if (attempts >= maxPollingAttempts && pendingMessageId != null) {
                pendingMessageId = null
                _uiState.update { state ->
                    state.copy(
                        isProcessing = false,
                        messages = state.messages + ChatMessage(
                            content = "Sorry, the response took too long. Please try again.",
                            isUser = false
                        )
                    )
                }
            }
        }
    }

    fun clearChat() {
        pollingJob?.cancel()
        pendingMessageId = null
        _uiState.update {
            AvyaChatUiState()
        }
    }

    fun dismissError() {
        _uiState.update { it.copy(errorMessage = null) }
    }

    override fun onCleared() {
        super.onCleared()
        pollingJob?.cancel()
    }
}
