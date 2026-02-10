package com.sparrowinvest.fa.ui.transactions

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.fa.core.network.ApiResult
import com.sparrowinvest.fa.data.model.Client
import com.sparrowinvest.fa.data.model.CreateTransactionRequest
import com.sparrowinvest.fa.data.model.Fund
import com.sparrowinvest.fa.data.repository.ClientRepository
import com.sparrowinvest.fa.data.repository.FundsRepository
import com.sparrowinvest.fa.data.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class WizardStep(val index: Int, val title: String) {
    SELECT_CLIENT(0, "Client"),
    SELECT_FUND(1, "Fund"),
    ENTER_DETAILS(2, "Details"),
    SELECT_PLATFORM(3, "Platform"),
    REVIEW(4, "Review")
}

enum class TransactionType(val label: String) {
    BUY("Buy"),
    SELL("Sell"),
    SIP("SIP"),
    SWP("SWP"),
    SWITCH("Switch"),
    STP("STP")
}

enum class PaymentMode(val label: String) {
    NET_BANKING("Net Banking"),
    UPI("UPI"),
    NACH("NACH"),
    CHEQUE("Cheque")
}

enum class Platform(val id: String, val label: String, val description: String) {
    BSE("bse", "BSE Star MF", "BSE's mutual fund transaction platform for distributors"),
    MFU("mfu", "MF Utility (MFU)", "Industry-wide transaction portal with TransactEezz")
}

data class NewTransactionWizardUiState(
    val currentStep: WizardStep = WizardStep.SELECT_CLIENT,

    // Step 1: Client
    val clients: List<Client> = emptyList(),
    val clientSearchQuery: String = "",
    val selectedClient: Client? = null,
    val isLoadingClients: Boolean = false,

    // Step 2: Fund
    val fundSearchQuery: String = "",
    val fundSearchResults: List<Fund> = emptyList(),
    val selectedFund: Fund? = null,
    val isFundSearchLoading: Boolean = false,

    // Step 3: Details
    val transactionType: TransactionType = TransactionType.BUY,
    val amount: String = "",
    val folioNumber: String = "",
    val isNewFolio: Boolean = true,
    val paymentMode: PaymentMode = PaymentMode.NET_BANKING,
    val notes: String = "",

    // Step 4: Platform
    val selectedPlatform: Platform? = null,
    val orderId: String = "",
    val skipOrderId: Boolean = false,
    val platformVisited: Boolean = false,

    // Step 5: Submit
    val isSubmitting: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null
) {
    val canGoNext: Boolean get() = when (currentStep) {
        WizardStep.SELECT_CLIENT -> selectedClient != null
        WizardStep.SELECT_FUND -> selectedFund != null
        WizardStep.ENTER_DETAILS -> {
            val amountVal = amount.toDoubleOrNull()
            amountVal != null && amountVal > 0
        }
        WizardStep.SELECT_PLATFORM -> {
            selectedPlatform != null && (orderId.isNotBlank() || skipOrderId)
        }
        WizardStep.REVIEW -> !isSubmitting
    }

    val filteredClients: List<Client> get() {
        if (clientSearchQuery.isBlank()) return clients
        val query = clientSearchQuery.lowercase()
        return clients.filter {
            it.name.lowercase().contains(query) ||
                    it.email.lowercase().contains(query)
        }
    }
}

@HiltViewModel
class NewTransactionWizardViewModel @Inject constructor(
    private val clientRepository: ClientRepository,
    private val fundsRepository: FundsRepository,
    private val transactionRepository: TransactionRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow(NewTransactionWizardUiState())
    val uiState: StateFlow<NewTransactionWizardUiState> = _uiState.asStateFlow()

    private var fundSearchJob: Job? = null
    private val preselectedClientId: String? = savedStateHandle["clientId"]

    init {
        loadClients()
    }

    private fun loadClients() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoadingClients = true) }
            when (val result = clientRepository.getClients()) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(isLoadingClients = false, clients = result.data) }
                    // Auto-select client if pre-selected
                    if (preselectedClientId != null) {
                        val client = result.data.find { it.id == preselectedClientId }
                        if (client != null) {
                            _uiState.update {
                                it.copy(
                                    selectedClient = client,
                                    currentStep = WizardStep.SELECT_FUND
                                )
                            }
                        }
                    }
                }
                is ApiResult.Error -> {
                    _uiState.update {
                        it.copy(isLoadingClients = false, error = result.message)
                    }
                }
                else -> {}
            }
        }
    }

    // Step navigation
    fun goToNextStep() {
        val state = _uiState.value
        if (!state.canGoNext) return
        val nextStep = WizardStep.entries.getOrNull(state.currentStep.index + 1) ?: return
        _uiState.update { it.copy(currentStep = nextStep, error = null) }
    }

    fun goToPreviousStep() {
        val state = _uiState.value
        val prevStep = WizardStep.entries.getOrNull(state.currentStep.index - 1) ?: return
        _uiState.update { it.copy(currentStep = prevStep, error = null) }
    }

    // Step 1: Client
    fun setClientSearchQuery(query: String) {
        _uiState.update { it.copy(clientSearchQuery = query) }
    }

    fun selectClient(client: Client) {
        _uiState.update { it.copy(selectedClient = client) }
    }

    // Step 2: Fund
    fun setFundSearchQuery(query: String) {
        _uiState.update { it.copy(fundSearchQuery = query) }
        fundSearchJob?.cancel()
        if (query.length >= 3) {
            fundSearchJob = viewModelScope.launch {
                _uiState.update { it.copy(isFundSearchLoading = true) }
                delay(300)
                when (val result = fundsRepository.searchFunds(query)) {
                    is ApiResult.Success -> {
                        _uiState.update {
                            it.copy(fundSearchResults = result.data, isFundSearchLoading = false)
                        }
                    }
                    else -> {
                        _uiState.update {
                            it.copy(fundSearchResults = emptyList(), isFundSearchLoading = false)
                        }
                    }
                }
            }
        } else {
            _uiState.update { it.copy(fundSearchResults = emptyList(), isFundSearchLoading = false) }
        }
    }

    fun selectFund(fund: Fund) {
        _uiState.update {
            it.copy(
                selectedFund = fund,
                fundSearchQuery = fund.schemeName,
                fundSearchResults = emptyList()
            )
        }
    }

    fun clearFund() {
        _uiState.update {
            it.copy(selectedFund = null, fundSearchQuery = "", fundSearchResults = emptyList())
        }
    }

    // Step 3: Details
    fun setTransactionType(type: TransactionType) {
        _uiState.update { it.copy(transactionType = type) }
    }

    fun setAmount(amount: String) {
        _uiState.update { it.copy(amount = amount) }
    }

    fun setFolioNumber(folio: String) {
        _uiState.update { it.copy(folioNumber = folio) }
    }

    fun toggleNewFolio(isNew: Boolean) {
        _uiState.update { it.copy(isNewFolio = isNew, folioNumber = if (isNew) "" else it.folioNumber) }
    }

    fun setPaymentMode(mode: PaymentMode) {
        _uiState.update { it.copy(paymentMode = mode) }
    }

    fun setNotes(notes: String) {
        _uiState.update { it.copy(notes = notes) }
    }

    // Step 4: Platform
    fun selectPlatform(platform: Platform) {
        _uiState.update { it.copy(selectedPlatform = platform) }
    }

    fun setOrderId(orderId: String) {
        _uiState.update { it.copy(orderId = orderId, skipOrderId = false) }
    }

    fun toggleSkipOrderId(skip: Boolean) {
        _uiState.update { it.copy(skipOrderId = skip, orderId = if (skip) "" else it.orderId) }
    }

    fun markPlatformVisited() {
        _uiState.update { it.copy(platformVisited = true) }
    }

    // Step 5: Submit
    fun submitTransaction(onSuccess: () -> Unit) {
        val state = _uiState.value
        val client = state.selectedClient ?: return
        val fund = state.selectedFund ?: return
        val amount = state.amount.toDoubleOrNull() ?: return

        viewModelScope.launch {
            _uiState.update { it.copy(isSubmitting = true, error = null) }

            val remarks = buildString {
                state.selectedPlatform?.let { append("Platform: ${it.label}") }
                if (state.orderId.isNotBlank()) {
                    append(" | Order ID: ${state.orderId}")
                }
                if (state.notes.isNotBlank()) {
                    if (isNotEmpty()) append(" | ")
                    append(state.notes)
                }
            }.takeIf { it.isNotBlank() }

            val request = CreateTransactionRequest(
                clientId = client.id,
                fundName = fund.schemeName,
                fundSchemeCode = fund.schemeCode.toString(),
                fundCategory = fund.schemeCategory ?: "Equity",
                type = state.transactionType.label,
                amount = amount,
                nav = fund.nav ?: 0.0,
                folioNumber = if (state.isNewFolio) "NEW" else state.folioNumber,
                paymentMode = state.paymentMode.label,
                remarks = remarks
            )

            when (val result = transactionRepository.createTransaction(request)) {
                is ApiResult.Success -> {
                    _uiState.update { it.copy(isSubmitting = false, isSuccess = true) }
                    onSuccess()
                }
                is ApiResult.Error -> {
                    _uiState.update {
                        it.copy(isSubmitting = false, error = result.message)
                    }
                }
                else -> {
                    _uiState.update {
                        it.copy(isSubmitting = false, error = "Unexpected error")
                    }
                }
            }
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }
}
