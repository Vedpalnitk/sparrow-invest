package com.sparrowinvest.fa.ui.communications

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.fa.core.network.ApiResult
import com.sparrowinvest.fa.data.model.*
import com.sparrowinvest.fa.data.repository.CommunicationRepository
import com.sparrowinvest.fa.data.repository.ClientRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CommunicationsUiState(
    val stats: CommunicationStats? = null,
    val logs: List<CommunicationLog> = emptyList(),
    val templates: List<CommunicationTemplate> = emptyList(),
    val clients: List<Client> = emptyList(),
    val isLoading: Boolean = false,
    val isLoadingHistory: Boolean = false,
    val error: String? = null,
    // Pagination
    val currentPage: Int = 1,
    val totalPages: Int = 1,
    val total: Int = 0,
    // Filters
    val channelFilter: String? = null,
    val typeFilter: String? = null,
    // Compose sheet
    val showComposeSheet: Boolean = false,
    val composeClientSearch: String = "",
    val composeSelectedClient: Client? = null,
    val composeChannel: CommunicationChannel = CommunicationChannel.EMAIL,
    val composeSelectedType: String = "",
    val composeSubject: String = "",
    val composeEmailBody: String = "",
    val composeWhatsappBody: String = "",
    val isLoadingPreview: Boolean = false,
    val isSending: Boolean = false,
    val composeSent: Boolean = false,
    val composeError: String? = null,
    // Bulk sheet
    val showBulkSheet: Boolean = false,
    val bulkSelectedClients: Set<String> = emptySet(),
    val bulkChannel: CommunicationChannel = CommunicationChannel.EMAIL,
    val bulkSelectedType: String = "",
    val isBulkSending: Boolean = false,
    val bulkResult: BulkSendResult? = null,
    val bulkError: String? = null
)

@HiltViewModel
class CommunicationsViewModel @Inject constructor(
    private val communicationRepository: CommunicationRepository,
    private val clientRepository: ClientRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CommunicationsUiState())
    val uiState = _uiState.asStateFlow()

    init {
        loadData()
    }

    fun loadData() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            // Load stats, history, templates, and clients in parallel
            val statsResult = communicationRepository.getStats()
            val historyResult = communicationRepository.getHistory(page = 1, limit = 20)
            val templatesResult = communicationRepository.getTemplates()
            val clientsResult = clientRepository.getClients()

            _uiState.update { state ->
                state.copy(
                    isLoading = false,
                    stats = (statsResult as? ApiResult.Success)?.data,
                    logs = (historyResult as? ApiResult.Success)?.data?.data ?: emptyList(),
                    totalPages = (historyResult as? ApiResult.Success)?.data?.totalPages ?: 1,
                    total = (historyResult as? ApiResult.Success)?.data?.total ?: 0,
                    currentPage = 1,
                    templates = (templatesResult as? ApiResult.Success)?.data ?: emptyList(),
                    clients = (clientsResult as? ApiResult.Success)?.data ?: emptyList(),
                    error = if (statsResult is ApiResult.Error && historyResult is ApiResult.Error)
                        "Failed to load communications" else null
                )
            }
        }
    }

    fun loadHistory(page: Int = 1) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingHistory = true) }

            val state = _uiState.value
            val result = communicationRepository.getHistory(
                channel = state.channelFilter,
                type = state.typeFilter,
                page = page,
                limit = 20
            )

            _uiState.update { s ->
                when (result) {
                    is ApiResult.Success -> s.copy(
                        isLoadingHistory = false,
                        logs = result.data.data,
                        currentPage = result.data.page,
                        totalPages = result.data.totalPages,
                        total = result.data.total
                    )
                    is ApiResult.Error -> s.copy(
                        isLoadingHistory = false,
                        error = result.message
                    )
                    else -> s.copy(isLoadingHistory = false)
                }
            }
        }
    }

    fun onChannelFilterChange(channel: String?) {
        _uiState.update { it.copy(channelFilter = channel) }
        loadHistory(page = 1)
    }

    fun onTypeFilterChange(type: String?) {
        _uiState.update { it.copy(typeFilter = type) }
        loadHistory(page = 1)
    }

    // -- Quick Compose --

    fun openCompose() {
        _uiState.update {
            it.copy(
                showComposeSheet = true,
                composeSelectedClient = null,
                composeClientSearch = "",
                composeChannel = CommunicationChannel.EMAIL,
                composeSelectedType = "",
                composeSubject = "",
                composeEmailBody = "",
                composeWhatsappBody = "",
                composeSent = false,
                composeError = null
            )
        }
    }

    fun dismissCompose() {
        _uiState.update { it.copy(showComposeSheet = false) }
    }

    fun onComposeClientSearch(query: String) {
        _uiState.update { it.copy(composeClientSearch = query) }
    }

    fun onComposeClientSelect(client: Client) {
        _uiState.update { it.copy(composeSelectedClient = client) }
    }

    fun onComposeChannelChange(channel: CommunicationChannel) {
        _uiState.update { it.copy(composeChannel = channel) }
    }

    fun onComposeTemplateChange(type: String) {
        _uiState.update { it.copy(composeSelectedType = type) }
        val client = _uiState.value.composeSelectedClient ?: return
        loadPreview(client.id, type)
    }

    private fun loadPreview(clientId: String, type: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingPreview = true) }
            val result = communicationRepository.preview(
                PreviewCommunicationRequest(clientId = clientId, type = type)
            )
            _uiState.update { state ->
                when (result) {
                    is ApiResult.Success -> state.copy(
                        isLoadingPreview = false,
                        composeSubject = result.data.emailSubject,
                        composeEmailBody = result.data.emailBody,
                        composeWhatsappBody = result.data.whatsappBody
                    )
                    is ApiResult.Error -> state.copy(
                        isLoadingPreview = false,
                        composeError = result.message
                    )
                    else -> state.copy(isLoadingPreview = false)
                }
            }
        }
    }

    fun onComposeSubjectChange(subject: String) {
        _uiState.update { it.copy(composeSubject = subject) }
    }

    fun onComposeWhatsappBodyChange(body: String) {
        _uiState.update { it.copy(composeWhatsappBody = body) }
    }

    fun sendCompose(context: Context) {
        val state = _uiState.value
        val client = state.composeSelectedClient ?: return
        val type = state.composeSelectedType.ifEmpty { return }

        if (state.composeChannel == CommunicationChannel.WHATSAPP) {
            // Open WhatsApp with pre-filled message
            val phone = client.phone?.replace(Regex("[^0-9+]"), "") ?: ""
            val body = state.composeWhatsappBody
            val url = if (phone.isNotEmpty()) {
                "https://wa.me/$phone?text=${Uri.encode(body)}"
            } else {
                "https://wa.me/?text=${Uri.encode(body)}"
            }
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            context.startActivity(intent)

            // Also log it server-side
            viewModelScope.launch {
                communicationRepository.send(
                    SendCommunicationRequest(
                        clientId = client.id,
                        channel = "WHATSAPP",
                        type = type,
                        subject = "",
                        body = body
                    )
                )
                _uiState.update { it.copy(composeSent = true) }
                loadData() // Refresh stats
            }
        } else {
            // Send email via API
            viewModelScope.launch {
                _uiState.update { it.copy(isSending = true, composeError = null) }
                val result = communicationRepository.send(
                    SendCommunicationRequest(
                        clientId = client.id,
                        channel = "EMAIL",
                        type = type,
                        subject = state.composeSubject,
                        body = state.composeEmailBody
                    )
                )
                _uiState.update { s ->
                    when (result) {
                        is ApiResult.Success -> s.copy(isSending = false, composeSent = true)
                        is ApiResult.Error -> s.copy(isSending = false, composeError = result.message)
                        else -> s.copy(isSending = false)
                    }
                }
                if (result is ApiResult.Success) loadData()
            }
        }
    }

    // -- Bulk Send --

    fun openBulkSend() {
        _uiState.update {
            it.copy(
                showBulkSheet = true,
                bulkSelectedClients = emptySet(),
                bulkChannel = CommunicationChannel.EMAIL,
                bulkSelectedType = "",
                bulkResult = null,
                bulkError = null
            )
        }
    }

    fun dismissBulkSend() {
        _uiState.update { it.copy(showBulkSheet = false) }
    }

    fun toggleBulkClient(clientId: String) {
        _uiState.update { state ->
            val updated = state.bulkSelectedClients.toMutableSet()
            if (clientId in updated) updated.remove(clientId) else updated.add(clientId)
            state.copy(bulkSelectedClients = updated)
        }
    }

    fun onBulkChannelChange(channel: CommunicationChannel) {
        _uiState.update { it.copy(bulkChannel = channel) }
    }

    fun onBulkTemplateChange(type: String) {
        _uiState.update { it.copy(bulkSelectedType = type) }
    }

    fun sendBulk() {
        val state = _uiState.value
        if (state.bulkSelectedClients.isEmpty() || state.bulkSelectedType.isEmpty()) return

        viewModelScope.launch {
            _uiState.update { it.copy(isBulkSending = true, bulkError = null) }
            val result = communicationRepository.sendBulk(
                BulkSendRequest(
                    clientIds = state.bulkSelectedClients.toList(),
                    channel = state.bulkChannel.value,
                    type = state.bulkSelectedType
                )
            )
            _uiState.update { s ->
                when (result) {
                    is ApiResult.Success -> s.copy(isBulkSending = false, bulkResult = result.data)
                    is ApiResult.Error -> s.copy(isBulkSending = false, bulkError = result.message)
                    else -> s.copy(isBulkSending = false)
                }
            }
            if (result is ApiResult.Success) loadData()
        }
    }
}
