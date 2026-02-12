package com.sparrowinvest.fa.ui.actioncenter

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.fa.core.network.ApiResult
import com.sparrowinvest.fa.data.model.Client
import com.sparrowinvest.fa.data.model.FASip
import com.sparrowinvest.fa.data.model.FATransaction
import com.sparrowinvest.fa.data.repository.ClientRepository
import com.sparrowinvest.fa.data.repository.SipRepository
import com.sparrowinvest.fa.data.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ActionCenterData(
    val failedSips: List<FASip> = emptyList(),
    val pendingTransactions: List<FATransaction> = emptyList(),
    val pendingKycClients: List<Client> = emptyList()
) {
    val totalCount: Int get() = failedSips.size + pendingTransactions.size + pendingKycClients.size
}

sealed class ActionCenterUiState {
    data object Loading : ActionCenterUiState()
    data class Success(val data: ActionCenterData) : ActionCenterUiState()
    data class Error(val message: String) : ActionCenterUiState()
}

@HiltViewModel
class ActionCenterViewModel @Inject constructor(
    private val sipRepository: SipRepository,
    private val transactionRepository: TransactionRepository,
    private val clientRepository: ClientRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<ActionCenterUiState>(ActionCenterUiState.Loading)
    val uiState: StateFlow<ActionCenterUiState> = _uiState.asStateFlow()

    init {
        loadActions()
    }

    fun loadActions() {
        viewModelScope.launch {
            _uiState.value = ActionCenterUiState.Loading

            val failedSips = when (val result = sipRepository.getSips(status = "FAILED")) {
                is ApiResult.Success -> result.data
                else -> emptyList()
            }

            val pendingTransactions = when (val result = transactionRepository.getPendingTransactions()) {
                is ApiResult.Success -> result.data
                else -> emptyList()
            }

            val pendingKycClients = when (val result = clientRepository.getClients()) {
                is ApiResult.Success -> result.data.filter {
                    it.kycStatus != null && it.kycStatus != "VERIFIED"
                }
                else -> emptyList()
            }

            _uiState.value = ActionCenterUiState.Success(
                ActionCenterData(
                    failedSips = failedSips,
                    pendingTransactions = pendingTransactions,
                    pendingKycClients = pendingKycClients
                )
            )
        }
    }
}
