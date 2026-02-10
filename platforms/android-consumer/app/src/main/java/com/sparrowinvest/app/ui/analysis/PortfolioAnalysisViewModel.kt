package com.sparrowinvest.app.ui.analysis

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.app.data.model.FundHealthStatus
import com.sparrowinvest.app.data.model.HoldingAnalysis
import com.sparrowinvest.app.data.model.HoldingScores
import com.sparrowinvest.app.data.model.PortfolioAnalysisResponse
import com.sparrowinvest.app.data.model.PortfolioAnalysisSummary
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class PortfolioAnalysisUiState {
    data object Loading : PortfolioAnalysisUiState()
    data object Success : PortfolioAnalysisUiState()
    data class Error(val message: String) : PortfolioAnalysisUiState()
}

@HiltViewModel
class PortfolioAnalysisViewModel @Inject constructor() : ViewModel() {

    private val _uiState = MutableStateFlow<PortfolioAnalysisUiState>(PortfolioAnalysisUiState.Loading)
    val uiState: StateFlow<PortfolioAnalysisUiState> = _uiState.asStateFlow()

    private val _analysis = MutableStateFlow<PortfolioAnalysisResponse?>(null)
    val analysis: StateFlow<PortfolioAnalysisResponse?> = _analysis.asStateFlow()

    private val _selectedFilter = MutableStateFlow<FundHealthStatus?>(null)
    val selectedFilter: StateFlow<FundHealthStatus?> = _selectedFilter.asStateFlow()

    val filteredHoldings: StateFlow<List<HoldingAnalysis>> = combine(
        _analysis,
        _selectedFilter
    ) { analysisData, filter ->
        val data = analysisData ?: return@combine emptyList()
        if (filter != null) {
            data.holdings.filter { it.status == filter }
        } else {
            data.holdingsSortedByScore
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    init {
        fetchAnalysis()
    }

    fun fetchAnalysis() {
        viewModelScope.launch {
            _uiState.value = PortfolioAnalysisUiState.Loading
            delay(1500L)
            _analysis.value = createMockAnalysis()
            _uiState.value = PortfolioAnalysisUiState.Success
        }
    }

    fun setFilter(status: FundHealthStatus?) {
        _selectedFilter.value = status
    }

    private fun createMockAnalysis(): PortfolioAnalysisResponse {
        val summary = PortfolioAnalysisSummary(
            portfolioHealthScore = 74.0,
            healthLabel = "Good",
            healthTrend = "improving",
            inFormCount = 3,
            onTrackCount = 2,
            offTrackCount = 1,
            outOfFormCount = 1,
            totalHoldings = 7
        )

        val holdings = listOf(
            HoldingAnalysis(
                id = "h1",
                fundName = "Parag Parikh Flexi Cap Fund",
                fundCategory = "Flexi Cap",
                status = FundHealthStatus.IN_FORM,
                investedValue = 250000.0,
                currentValue = 342500.0,
                absoluteGainPercent = 37.0,
                scores = HoldingScores(
                    overallScore = 92.0,
                    returnsScore = 95.0,
                    riskScore = 88.0,
                    consistencyScore = 91.0,
                    momentumScore = 90.0
                ),
                insights = listOf(
                    "Outperforming category average by 8.2%",
                    "Strong momentum in recent 3 months",
                    "Consistent top-quartile returns"
                ),
                actionHint = "Continue investing"
            ),
            HoldingAnalysis(
                id = "h2",
                fundName = "HDFC Mid-Cap Opportunities Fund",
                fundCategory = "Mid Cap",
                status = FundHealthStatus.IN_FORM,
                investedValue = 180000.0,
                currentValue = 241200.0,
                absoluteGainPercent = 34.0,
                scores = HoldingScores(
                    overallScore = 87.0,
                    returnsScore = 90.0,
                    riskScore = 82.0,
                    consistencyScore = 88.0,
                    momentumScore = 85.0
                ),
                insights = listOf(
                    "Excellent stock selection in mid-cap segment",
                    "Fund manager has strong track record",
                    "Benefiting from mid-cap rally"
                ),
                actionHint = "Continue investing"
            ),
            HoldingAnalysis(
                id = "h3",
                fundName = "Mirae Asset Large Cap Fund",
                fundCategory = "Large Cap",
                status = FundHealthStatus.IN_FORM,
                investedValue = 200000.0,
                currentValue = 254000.0,
                absoluteGainPercent = 27.0,
                scores = HoldingScores(
                    overallScore = 83.0,
                    returnsScore = 85.0,
                    riskScore = 86.0,
                    consistencyScore = 80.0,
                    momentumScore = 78.0
                ),
                insights = listOf(
                    "Stable large-cap allocation providing downside protection",
                    "Beating Nifty 50 by 3.5%",
                    "Low expense ratio at 0.55%"
                ),
                actionHint = "Continue investing"
            ),
            HoldingAnalysis(
                id = "h4",
                fundName = "Kotak Emerging Equity Fund",
                fundCategory = "Mid Cap",
                status = FundHealthStatus.ON_TRACK,
                investedValue = 150000.0,
                currentValue = 178500.0,
                absoluteGainPercent = 19.0,
                scores = HoldingScores(
                    overallScore = 72.0,
                    returnsScore = 74.0,
                    riskScore = 70.0,
                    consistencyScore = 73.0,
                    momentumScore = 68.0
                ),
                insights = listOf(
                    "Meeting category benchmarks steadily",
                    "Stable performance with moderate risk",
                    "Good risk-adjusted returns"
                ),
                actionHint = "Hold / invest more"
            ),
            HoldingAnalysis(
                id = "h5",
                fundName = "SBI Small Cap Fund",
                fundCategory = "Small Cap",
                status = FundHealthStatus.ON_TRACK,
                investedValue = 120000.0,
                currentValue = 139200.0,
                absoluteGainPercent = 16.0,
                scores = HoldingScores(
                    overallScore = 68.0,
                    returnsScore = 70.0,
                    riskScore = 62.0,
                    consistencyScore = 72.0,
                    momentumScore = 65.0
                ),
                insights = listOf(
                    "Decent performance in small-cap segment",
                    "Higher volatility but within acceptable range",
                    "Recent quarters showing improvement"
                ),
                actionHint = "Hold / invest more"
            ),
            HoldingAnalysis(
                id = "h6",
                fundName = "Axis Bluechip Fund",
                fundCategory = "Large Cap",
                status = FundHealthStatus.OFF_TRACK,
                investedValue = 100000.0,
                currentValue = 98000.0,
                absoluteGainPercent = -2.0,
                scores = HoldingScores(
                    overallScore = 38.0,
                    returnsScore = 32.0,
                    riskScore = 45.0,
                    consistencyScore = 40.0,
                    momentumScore = 30.0
                ),
                insights = listOf(
                    "Underperforming category average by 5.8%",
                    "Fund manager style not in favour currently",
                    "Consider reviewing allocation"
                ),
                actionHint = "Review and monitor"
            ),
            HoldingAnalysis(
                id = "h7",
                fundName = "Nippon India Growth Fund",
                fundCategory = "Mid Cap",
                status = FundHealthStatus.OUT_OF_FORM,
                investedValue = 80000.0,
                currentValue = 68000.0,
                absoluteGainPercent = -15.0,
                scores = HoldingScores(
                    overallScore = 22.0,
                    returnsScore = 18.0,
                    riskScore = 25.0,
                    consistencyScore = 20.0,
                    momentumScore = 15.0
                ),
                insights = listOf(
                    "Significantly underperforming peers",
                    "High risk relative to returns generated",
                    "Better alternatives available in same category"
                ),
                actionHint = "Consider exiting"
            )
        )

        val recommendations = listOf(
            "Consider exiting Nippon India Growth Fund and reallocating to a better-performing mid-cap fund.",
            "Monitor Axis Bluechip Fund for 1 more quarter before taking action.",
            "Increase SIP in Parag Parikh Flexi Cap Fund to capitalise on strong momentum.",
            "Your portfolio has good large-cap/mid-cap balance. Consider adding a small-cap allocation of 10-15%."
        )

        return PortfolioAnalysisResponse(
            summary = summary,
            holdings = holdings,
            recommendations = recommendations,
            poweredBy = "Avya AI"
        )
    }
}
