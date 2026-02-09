package com.sparrowinvest.app.ui.insights

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.app.core.network.ApiResult
import com.sparrowinvest.app.data.model.ActionItem
import com.sparrowinvest.app.data.model.ActionPriority
import com.sparrowinvest.app.data.model.ActionType
import com.sparrowinvest.app.data.model.AssetAllocation
import com.sparrowinvest.app.data.model.ClassifyHolding
import com.sparrowinvest.app.data.model.ClassifyRequest
import com.sparrowinvest.app.data.model.ClassifyResponse
import com.sparrowinvest.app.data.model.FamilyMember
import com.sparrowinvest.app.data.model.FamilyPortfolio
import com.sparrowinvest.app.data.model.Holding
import com.sparrowinvest.app.data.model.PortfolioAnalysis
import com.sparrowinvest.app.data.model.Relationship
import com.sparrowinvest.app.data.model.RiskAssessment
import com.sparrowinvest.app.data.repository.PortfolioRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

// Alert data classes
data class PortfolioAlert(
    val id: String,
    val title: String,
    val message: String,
    val type: AlertType,
    val priority: AlertPriority,
    val actionLabel: String? = null
)

enum class AlertType {
    WARNING,
    INFO,
    SUCCESS,
    ACTION_REQUIRED
}

enum class AlertPriority {
    HIGH, MEDIUM, LOW
}

// Insight card data
data class InsightCard(
    val id: String,
    val title: String,
    val description: String,
    val type: InsightType,
    val value: String? = null,
    val trend: Double? = null
)

enum class InsightType {
    DIVERSIFICATION,
    RISK_ADJUSTED_RETURNS,
    EXPENSE_RATIO,
    TAX_EFFICIENCY,
    GOAL_PROGRESS
}

enum class PortfolioViewMode {
    INDIVIDUAL,
    FAMILY
}

// Status requirements for analysis
data class AnalysisRequirements(
    val hasProfile: Boolean = false,
    val hasHoldings: Boolean = false
) {
    val canRunAnalysis: Boolean
        get() = hasProfile && hasHoldings
}

@HiltViewModel
class InsightsViewModel @Inject constructor(
    private val portfolioRepository: PortfolioRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<InsightsUiState>(InsightsUiState.Idle)
    val uiState: StateFlow<InsightsUiState> = _uiState.asStateFlow()

    private val _analysisResult = MutableStateFlow<ClassifyResponse?>(null)
    val analysisResult: StateFlow<ClassifyResponse?> = _analysisResult.asStateFlow()

    private val _alerts = MutableStateFlow<List<PortfolioAlert>>(emptyList())
    val alerts: StateFlow<List<PortfolioAlert>> = _alerts.asStateFlow()

    private val _actionItems = MutableStateFlow<List<ActionItem>>(emptyList())
    val actionItems: StateFlow<List<ActionItem>> = _actionItems.asStateFlow()

    private val _insightCards = MutableStateFlow<List<InsightCard>>(emptyList())
    val insightCards: StateFlow<List<InsightCard>> = _insightCards.asStateFlow()

    private val _lastAnalyzedDate = MutableStateFlow<String?>(null)
    val lastAnalyzedDate: StateFlow<String?> = _lastAnalyzedDate.asStateFlow()

    // Portfolio view mode
    private val _portfolioViewMode = MutableStateFlow(PortfolioViewMode.INDIVIDUAL)
    val portfolioViewMode: StateFlow<PortfolioViewMode> = _portfolioViewMode.asStateFlow()

    // Family portfolio data
    private val _familyPortfolio = MutableStateFlow<FamilyPortfolio?>(null)
    val familyPortfolio: StateFlow<FamilyPortfolio?> = _familyPortfolio.asStateFlow()

    // Selected family member for analysis
    private val _selectedFamilyMember = MutableStateFlow<FamilyMember?>(null)
    val selectedFamilyMember: StateFlow<FamilyMember?> = _selectedFamilyMember.asStateFlow()

    // Holdings for analysis
    private val _holdings = MutableStateFlow<List<Holding>>(emptyList())
    val holdings: StateFlow<List<Holding>> = _holdings.asStateFlow()

    // Analysis requirements status
    private val _analysisRequirements = MutableStateFlow(AnalysisRequirements())
    val analysisRequirements: StateFlow<AnalysisRequirements> = _analysisRequirements.asStateFlow()

    init {
        // Load cached analysis if available
        loadCachedAnalysis()
        // Load portfolio data
        loadPortfolioData()
    }

    private fun loadCachedAnalysis() {
        // In a real app, this would load from local storage
        // For demo, we'll show the idle state
    }

    private fun loadPortfolioData() {
        viewModelScope.launch {
            // Load holdings (mock data)
            _holdings.value = createMockHoldings()

            // Load family portfolio (mock data)
            _familyPortfolio.value = createMockFamilyPortfolio()

            // Update requirements based on current state
            updateAnalysisRequirements()
        }
    }

    fun setPortfolioViewMode(mode: PortfolioViewMode) {
        _portfolioViewMode.value = mode
        if (mode == PortfolioViewMode.INDIVIDUAL) {
            _selectedFamilyMember.value = null
        }
        // Reset analysis when switching modes
        _uiState.value = InsightsUiState.Idle
        _analysisResult.value = null
        updateAnalysisRequirements()
    }

    fun selectFamilyMember(member: FamilyMember?) {
        _selectedFamilyMember.value = member
        // Reset analysis when selecting different member
        _uiState.value = InsightsUiState.Idle
        _analysisResult.value = null
        updateAnalysisRequirements()
    }

    private fun updateAnalysisRequirements() {
        val viewMode = _portfolioViewMode.value
        val selectedMember = _selectedFamilyMember.value
        val holdings = _holdings.value
        val familyPortfolio = _familyPortfolio.value

        val hasProfile = when (viewMode) {
            PortfolioViewMode.INDIVIDUAL -> true // Individual profile always available for demo
            PortfolioViewMode.FAMILY -> {
                if (selectedMember == null) {
                    // "All" selected - check if family has at least one member with profile
                    familyPortfolio?.members?.isNotEmpty() == true
                } else {
                    // Specific member selected - assume profile exists
                    true
                }
            }
        }

        val hasHoldings = when (viewMode) {
            PortfolioViewMode.INDIVIDUAL -> holdings.isNotEmpty()
            PortfolioViewMode.FAMILY -> {
                // For family, check if selected member or family has holdings
                familyPortfolio?.totalValue?.let { it > 0 } == true
            }
        }

        _analysisRequirements.value = AnalysisRequirements(
            hasProfile = hasProfile,
            hasHoldings = hasHoldings
        )
    }

    private fun createMockHoldings(): List<Holding> {
        return listOf(
            Holding(
                id = "1",
                fundCode = "122639",
                fundName = "Parag Parikh Flexi Cap Fund",
                category = "Flexi Cap",
                assetClass = "equity",
                units = 1250.45,
                averageNav = 65.50,
                currentNav = 78.45,
                investedAmount = 81904.0,
                currentValue = 98110.0,
                returns = 16206.0,
                returnsPercentage = 19.78,
                dayChange = 245.0,
                dayChangePercentage = 0.25
            ),
            Holding(
                id = "2",
                fundCode = "112090",
                fundName = "HDFC Mid-Cap Opportunities",
                category = "Mid Cap",
                assetClass = "equity",
                units = 850.25,
                averageNav = 95.20,
                currentNav = 112.35,
                investedAmount = 80923.0,
                currentValue = 95526.0,
                returns = 14603.0,
                returnsPercentage = 18.01,
                dayChange = -120.0,
                dayChangePercentage = -0.12
            ),
            Holding(
                id = "3",
                fundCode = "120465",
                fundName = "ICICI Prudential Corporate Bond",
                category = "Corporate Bond",
                assetClass = "debt",
                units = 2500.0,
                averageNav = 22.50,
                currentNav = 24.10,
                investedAmount = 56250.0,
                currentValue = 60250.0,
                returns = 4000.0,
                returnsPercentage = 7.11,
                dayChange = 50.0,
                dayChangePercentage = 0.08
            ),
            Holding(
                id = "4",
                fundCode = "118551",
                fundName = "Axis Bluechip Fund",
                category = "Large Cap",
                assetClass = "equity",
                units = 620.0,
                averageNav = 48.50,
                currentNav = 52.18,
                investedAmount = 30070.0,
                currentValue = 32352.0,
                returns = 2282.0,
                returnsPercentage = 7.59,
                dayChange = 85.0,
                dayChangePercentage = 0.26
            ),
            Holding(
                id = "5",
                fundCode = "135781",
                fundName = "SBI Gold Fund",
                category = "Gold",
                assetClass = "gold",
                units = 750.0,
                averageNav = 12.80,
                currentNav = 14.24,
                investedAmount = 9600.0,
                currentValue = 10680.0,
                returns = 1080.0,
                returnsPercentage = 11.25,
                dayChange = 42.0,
                dayChangePercentage = 0.39
            )
        )
    }

    private fun createMockFamilyPortfolio(): FamilyPortfolio {
        return FamilyPortfolio(
            id = "family_1",
            name = "Family Portfolio",
            members = listOf(
                FamilyMember(
                    id = "1",
                    name = "Rahul Sharma",
                    relationship = Relationship.SELF,
                    portfolioValue = 245680.0,
                    contribution = 45.0
                ),
                FamilyMember(
                    id = "2",
                    name = "Priya Sharma",
                    relationship = Relationship.SPOUSE,
                    portfolioValue = 185420.0,
                    contribution = 34.0
                ),
                FamilyMember(
                    id = "3",
                    name = "Arun Sharma",
                    relationship = Relationship.PARENT,
                    portfolioValue = 115230.0,
                    contribution = 21.0
                )
            ),
            totalValue = 546330.0,
            totalInvested = 498750.0,
            totalReturns = 47580.0,
            returnsPercentage = 9.54,
            assetAllocation = AssetAllocation(
                equity = 320000.0,
                debt = 145000.0,
                hybrid = 51330.0,
                gold = 30000.0,
                other = 0.0
            )
        )
    }

    fun analyzePortfolio() {
        // Check if analysis can run
        if (!_analysisRequirements.value.canRunAnalysis) {
            return
        }

        viewModelScope.launch {
            _uiState.value = InsightsUiState.Analyzing

            // Get holdings based on view mode
            val holdingsToAnalyze = when (_portfolioViewMode.value) {
                PortfolioViewMode.INDIVIDUAL -> _holdings.value
                PortfolioViewMode.FAMILY -> {
                    // For family mode, use the mock holdings (in real app, would fetch member-specific holdings)
                    _holdings.value
                }
            }

            // Create request with portfolio holdings
            val request = ClassifyRequest(
                holdings = holdingsToAnalyze.map { holding ->
                    ClassifyHolding(
                        fundName = holding.fundName,
                        schemeCode = holding.fundCode.toIntOrNull(),
                        currentValue = holding.currentValue
                    )
                },
                riskProfile = "Moderate"
            )

            when (val result = portfolioRepository.classifyPortfolio(request)) {
                is ApiResult.Success -> {
                    _analysisResult.value = result.data
                    _uiState.value = InsightsUiState.Success
                    loadAlerts()
                    loadActionItems()
                    loadInsightCards()
                    _lastAnalyzedDate.value = "Jan 19, 2026"
                }
                is ApiResult.Error -> {
                    // Use mock data for demo
                    delay(2000) // Simulate API call
                    _analysisResult.value = createMockAnalysis()
                    _uiState.value = InsightsUiState.Success
                    loadAlerts()
                    loadActionItems()
                    loadInsightCards()
                    _lastAnalyzedDate.value = "Jan 19, 2026"
                }
                else -> {}
            }
        }
    }

    private fun loadAlerts() {
        _alerts.value = listOf(
            PortfolioAlert(
                id = "1",
                title = "High Mid-Cap Exposure",
                message = "Your mid-cap allocation (38%) is above recommended levels for a moderate risk profile. Consider rebalancing.",
                type = AlertType.WARNING,
                priority = AlertPriority.HIGH,
                actionLabel = "Rebalance Now"
            ),
            PortfolioAlert(
                id = "2",
                title = "Tax Saving Opportunity",
                message = "You can invest ₹50,000 more in ELSS funds to maximize your 80C deductions before March 31.",
                type = AlertType.INFO,
                priority = AlertPriority.MEDIUM,
                actionLabel = "Explore ELSS"
            ),
            PortfolioAlert(
                id = "3",
                title = "SIP Due Tomorrow",
                message = "Your Parag Parikh Flexi Cap SIP of ₹10,000 is due tomorrow. Ensure sufficient balance.",
                type = AlertType.ACTION_REQUIRED,
                priority = AlertPriority.HIGH,
                actionLabel = "View SIP"
            ),
            PortfolioAlert(
                id = "4",
                title = "Goal On Track",
                message = "Your Retirement Fund goal is on track! You've achieved 25% of your target.",
                type = AlertType.SUCCESS,
                priority = AlertPriority.LOW
            )
        )
    }

    private fun loadActionItems() {
        _actionItems.value = listOf(
            ActionItem(
                action = ActionType.REBALANCE,
                fundName = "Mid-Cap to Large-Cap",
                reason = "Reduce mid-cap exposure by 8% and increase large-cap allocation for better risk management",
                priority = ActionPriority.HIGH
            ),
            ActionItem(
                action = ActionType.START_SIP,
                fundName = "Motilal Oswal Nasdaq 100 FOF",
                schemeCode = 145678,
                amount = 3000.0,
                reason = "Add international equity exposure for geographic diversification",
                priority = ActionPriority.MEDIUM
            ),
            ActionItem(
                action = ActionType.INCREASE_SIP,
                fundName = "ICICI Prudential Corporate Bond",
                schemeCode = 120465,
                amount = 2000.0,
                reason = "Increase debt allocation for portfolio stability",
                priority = ActionPriority.MEDIUM
            ),
            ActionItem(
                action = ActionType.BUY,
                fundName = "Nippon India Gold Savings Fund",
                schemeCode = 132456,
                amount = 5000.0,
                reason = "Add gold exposure as inflation hedge and portfolio diversifier",
                priority = ActionPriority.LOW
            )
        )
    }

    private fun loadInsightCards() {
        _insightCards.value = listOf(
            InsightCard(
                id = "1",
                title = "Diversification Score",
                description = "Your portfolio is well-diversified across 5 asset classes",
                type = InsightType.DIVERSIFICATION,
                value = "Good",
                trend = 5.0
            ),
            InsightCard(
                id = "2",
                title = "Risk-Adjusted Returns",
                description = "Sharpe Ratio of 1.2 indicates efficient risk management",
                type = InsightType.RISK_ADJUSTED_RETURNS,
                value = "1.2",
                trend = 0.1
            ),
            InsightCard(
                id = "3",
                title = "Expense Ratio",
                description = "Portfolio weighted average expense ratio",
                type = InsightType.EXPENSE_RATIO,
                value = "0.45%",
                trend = -0.05
            ),
            InsightCard(
                id = "4",
                title = "Tax Efficiency",
                description = "Estimated tax liability on current gains",
                type = InsightType.TAX_EFFICIENCY,
                value = "₹8,250",
                trend = null
            )
        )
    }

    fun dismissAlert(alertId: String) {
        _alerts.value = _alerts.value.filter { it.id != alertId }
    }

    private fun createMockAnalysis(): ClassifyResponse {
        return ClassifyResponse(
            analysis = PortfolioAnalysis(
                overallScore = 78,
                diversificationScore = 72,
                riskAlignmentScore = 85,
                costEfficiencyScore = 82,
                summary = "Your portfolio shows good diversification across asset classes with a slight overweight in mid-cap equity. The overall risk-return profile aligns well with your moderate investment strategy.",
                strengths = listOf(
                    "Well-diversified across large, mid, and flexi cap funds",
                    "Low expense ratio funds selected (avg 0.45%)",
                    "Good mix of growth and value-oriented funds",
                    "Risk profile aligned with moderate investment strategy",
                    "Consistent SIP discipline maintained"
                ),
                weaknesses = listOf(
                    "Limited exposure to international equities (0%)",
                    "Mid-cap allocation slightly higher than recommended",
                    "Could benefit from more debt allocation for stability",
                    "No ELSS funds - missing tax saving opportunity"
                ),
                assetBreakdown = mapOf(
                    "Equity - Large Cap" to 35.0,
                    "Equity - Mid Cap" to 38.0,
                    "Equity - Flexi Cap" to 12.0,
                    "Debt" to 11.0,
                    "Gold" to 4.0
                )
            ),
            recommendations = listOf(
                "Consider adding 10% allocation to international equity funds for geographic diversification",
                "Reduce mid-cap exposure by 8% and shift to large-cap funds",
                "Increase debt allocation by 5% to reduce portfolio volatility",
                "Start an ELSS SIP to save up to ₹46,800 in taxes annually",
                "Add a gold fund with 5% allocation as inflation hedge"
            ),
            riskAssessment = RiskAssessment(
                currentRiskLevel = "Moderate-High",
                recommendedRiskLevel = "Moderate",
                aligned = false,
                explanation = "Your current portfolio risk is slightly higher than your stated moderate risk preference due to high mid-cap exposure."
            )
        )
    }
}

sealed class InsightsUiState {
    data object Idle : InsightsUiState()
    data object Analyzing : InsightsUiState()
    data object Success : InsightsUiState()
    data class Error(val message: String) : InsightsUiState()
}
