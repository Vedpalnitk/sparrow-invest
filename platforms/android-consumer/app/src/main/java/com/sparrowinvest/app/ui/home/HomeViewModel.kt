package com.sparrowinvest.app.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sparrowinvest.app.core.network.ApiResult
import com.sparrowinvest.app.data.model.AdvisorInfo
import com.sparrowinvest.app.data.model.AssetAllocation
import com.sparrowinvest.app.data.model.ClientType
import com.sparrowinvest.app.data.model.Goal
import com.sparrowinvest.app.data.model.HistoryPeriod
import com.sparrowinvest.app.data.model.Holding
import com.sparrowinvest.app.data.model.MarketIndex
import com.sparrowinvest.app.data.model.MarketOverview
import com.sparrowinvest.app.data.model.Portfolio
import com.sparrowinvest.app.data.model.PortfolioHistory
import com.sparrowinvest.app.data.model.PortfolioHistoryPoint
import com.sparrowinvest.app.data.model.Sip
import com.sparrowinvest.app.data.model.SipFrequency
import com.sparrowinvest.app.data.model.SipStatus
import com.sparrowinvest.app.data.model.Transaction
import com.sparrowinvest.app.data.model.TransactionType
import com.sparrowinvest.app.data.model.TransactionStatus
import com.sparrowinvest.app.data.model.User
import com.sparrowinvest.app.data.model.TaxSummary
import com.sparrowinvest.app.data.model.DividendSummary
import com.sparrowinvest.app.data.model.DividendRecord
import com.sparrowinvest.app.data.repository.AuthRepository
import com.sparrowinvest.app.data.repository.GoalsRepository
import com.sparrowinvest.app.data.repository.PortfolioRepository
import com.sparrowinvest.app.ui.components.ActionType
import com.sparrowinvest.app.ui.components.UpcomingAction
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Locale
import javax.inject.Inject

enum class PortfolioViewMode {
    INDIVIDUAL,
    FAMILY
}

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val portfolioRepository: PortfolioRepository,
    private val goalsRepository: GoalsRepository
) : ViewModel() {

    val currentUser: StateFlow<User?> = authRepository.currentUser
    val isGuest: StateFlow<Boolean> = authRepository.isGuestUser

    // Client type and advisor info from portfolio repository
    val clientType: StateFlow<ClientType> = portfolioRepository.clientType
    val advisor: StateFlow<AdvisorInfo?> = portfolioRepository.advisor

    /**
     * Check if user is a managed client (has FA advisor)
     */
    val isManagedClient: Boolean
        get() = portfolioRepository.isManagedClient

    private val _uiState = MutableStateFlow<HomeUiState>(HomeUiState.Loading)
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    private val _portfolio = MutableStateFlow<Portfolio?>(null)
    val portfolio: StateFlow<Portfolio?> = _portfolio.asStateFlow()

    private val _goals = MutableStateFlow<List<Goal>>(emptyList())
    val goals: StateFlow<List<Goal>> = _goals.asStateFlow()

    private val _recentTransactions = MutableStateFlow<List<Transaction>>(emptyList())
    val recentTransactions: StateFlow<List<Transaction>> = _recentTransactions.asStateFlow()

    private val _activeSIPs = MutableStateFlow<List<Sip>>(emptyList())
    val activeSIPs: StateFlow<List<Sip>> = _activeSIPs.asStateFlow()

    private val _upcomingActions = MutableStateFlow<List<UpcomingAction>>(emptyList())
    val upcomingActions: StateFlow<List<UpcomingAction>> = _upcomingActions.asStateFlow()

    private val _portfolioViewMode = MutableStateFlow(PortfolioViewMode.INDIVIDUAL)
    val portfolioViewMode: StateFlow<PortfolioViewMode> = _portfolioViewMode.asStateFlow()

    private val _profileCompletion = MutableStateFlow(65)
    val profileCompletion: StateFlow<Int> = _profileCompletion.asStateFlow()

    private val _portfolioHistory = MutableStateFlow(PortfolioHistory.empty)
    val portfolioHistory: StateFlow<PortfolioHistory> = _portfolioHistory.asStateFlow()

    private val _selectedHistoryPeriod = MutableStateFlow(HistoryPeriod.ONE_YEAR)
    val selectedHistoryPeriod: StateFlow<HistoryPeriod> = _selectedHistoryPeriod.asStateFlow()

    private val _taxSummary = MutableStateFlow(TaxSummary.empty)
    val taxSummary: StateFlow<TaxSummary> = _taxSummary.asStateFlow()

    private val _dividendSummary = MutableStateFlow(DividendSummary.empty)
    val dividendSummary: StateFlow<DividendSummary> = _dividendSummary.asStateFlow()

    private val _marketOverview = MutableStateFlow(MarketOverview.empty)
    val marketOverview: StateFlow<MarketOverview> = _marketOverview.asStateFlow()

    // Top movers derived from portfolio holdings
    val topGainers: List<Holding>
        get() = _portfolio.value?.holdings
            ?.filter { it.dayChange > 0 }
            ?.sortedByDescending { it.dayChangePercentage }
            ?.take(3) ?: emptyList()

    val topLosers: List<Holding>
        get() = _portfolio.value?.holdings
            ?.filter { it.dayChange < 0 }
            ?.sortedBy { it.dayChangePercentage }
            ?.take(3) ?: emptyList()

    init {
        loadData()
    }

    fun setPortfolioViewMode(mode: PortfolioViewMode) {
        _portfolioViewMode.value = mode
    }

    fun setHistoryPeriod(period: HistoryPeriod) {
        _selectedHistoryPeriod.value = period
        _portfolioHistory.value = createMockPortfolioHistory(period)
    }

    fun loadData() {
        viewModelScope.launch {
            _uiState.value = HomeUiState.Loading

            // Load portfolio with clientType and advisor info
            val myPortfolioResult = portfolioRepository.getMyPortfolio()
            when (myPortfolioResult) {
                is ApiResult.Success -> {
                    // Convert PortfolioResponse to Portfolio for UI
                    val response = myPortfolioResult.data
                    _portfolio.value = Portfolio(
                        totalValue = response.portfolio.totalValue,
                        totalInvested = response.portfolio.totalInvested,
                        totalReturns = response.portfolio.totalReturns,
                        returnsPercentage = response.portfolio.returnsPercentage,
                        todayChange = 0.0,
                        todayChangePercentage = 0.0,
                        xirr = null,
                        assetAllocation = AssetAllocation(),
                        holdings = emptyList(),
                        sips = emptyList()
                    )
                }
                is ApiResult.Error -> {
                    // Fall back to old endpoint
                    val portfolioResult = portfolioRepository.getPortfolio()
                    when (portfolioResult) {
                        is ApiResult.Success -> {
                            _portfolio.value = portfolioResult.data
                        }
                        is ApiResult.Error -> {
                            // Use mock data for demo
                            _portfolio.value = createMockPortfolio()
                        }
                        else -> {}
                    }
                }
            }

            // Load goals
            val goalsResult = goalsRepository.getGoals()
            when (goalsResult) {
                is ApiResult.Success -> {
                    _goals.value = goalsResult.data
                }
                is ApiResult.Error -> {
                    _goals.value = createMockGoals()
                }
                else -> {}
            }

            // Load transactions
            val transactionsResult = portfolioRepository.getTransactions()
            when (transactionsResult) {
                is ApiResult.Success -> {
                    _recentTransactions.value = transactionsResult.data.take(5)
                }
                is ApiResult.Error -> {
                    _recentTransactions.value = createMockTransactions()
                }
                else -> {}
            }

            // Load SIPs (mock for now)
            _activeSIPs.value = createMockSIPs()

            // Load upcoming actions (mock for now)
            _upcomingActions.value = createMockUpcomingActions()

            // Load portfolio history (mock for now)
            _portfolioHistory.value = createMockPortfolioHistory(_selectedHistoryPeriod.value)

            // Load tax summary (mock for now)
            _taxSummary.value = TaxSummary.calculate(
                ltcg = 85000.0,
                stcg = 12000.0,
                elss = 95000.0
            )

            // Load dividend summary (mock for now)
            _dividendSummary.value = createMockDividendSummary()

            // Load market overview (mock for now)
            _marketOverview.value = MarketOverview(
                indices = listOf(
                    MarketIndex("1", "Nifty 50", "NSEI", 22456.80, 22380.50, 76.30, 0.34),
                    MarketIndex("2", "Sensex", "BSESN", 73890.45, 73650.20, 240.25, 0.33),
                    MarketIndex("3", "Bank Nifty", "NSEBANK", 48230.15, 48100.00, 130.15, 0.27),
                    MarketIndex("4", "Nifty IT", "NSEIT", 38450.60, 38520.30, -69.70, -0.18),
                    MarketIndex("5", "Nifty Midcap", "NSEMID", 42180.90, 42050.10, 130.80, 0.31)
                ),
                status = "Closed",
                lastUpdated = "Jan 10, 2026 3:30 PM"
            )

            _uiState.value = HomeUiState.Success
        }
    }

    fun getGreeting(): String {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        return when {
            hour < 12 -> "Good morning"
            hour < 17 -> "Good afternoon"
            else -> "Good evening"
        }
    }

    private fun createMockPortfolio(): Portfolio {
        return Portfolio(
            totalValue = 245680.0,
            totalInvested = 233230.0,
            totalReturns = 12450.0,
            returnsPercentage = 5.34,
            todayChange = 890.0,
            todayChangePercentage = 0.36,
            xirr = 14.2,
            assetAllocation = AssetAllocation(
                equity = 145000.0,
                debt = 65000.0,
                hybrid = 25000.0,
                gold = 10680.0,
                other = 0.0
            ),
            holdings = createMockHoldings(),
            sips = createMockSIPs()
        )
    }

    private fun createMockHoldings(): List<Holding> {
        return listOf(
            Holding(
                id = "1",
                fundCode = "119598",
                fundName = "Axis Bluechip Fund Direct Growth",
                category = "Large Cap",
                assetClass = "equity",
                units = 234.56,
                averageNav = 45.23,
                currentNav = 52.10,
                investedAmount = 10610.0,
                currentValue = 12218.5,
                returns = 1608.5,
                returnsPercentage = 15.15,
                dayChange = 45.0,
                dayChangePercentage = 0.37
            ),
            Holding(
                id = "2",
                fundCode = "145552",
                fundName = "Mirae Asset Large Cap Fund Direct Growth",
                category = "Large Cap",
                assetClass = "equity",
                units = 189.32,
                averageNav = 78.45,
                currentNav = 85.23,
                investedAmount = 14855.0,
                currentValue = 16132.9,
                returns = 1277.9,
                returnsPercentage = 8.6,
                dayChange = 32.0,
                dayChangePercentage = 0.2
            ),
            Holding(
                id = "3",
                fundCode = "120594",
                fundName = "HDFC Corporate Bond Fund Direct Growth",
                category = "Corporate Bond",
                assetClass = "debt",
                units = 500.0,
                averageNav = 25.10,
                currentNav = 26.80,
                investedAmount = 12550.0,
                currentValue = 13400.0,
                returns = 850.0,
                returnsPercentage = 6.77,
                dayChange = 8.0,
                dayChangePercentage = 0.06
            )
        )
    }

    private fun createMockSIPs(): List<Sip> {
        return listOf(
            Sip(
                id = "1",
                fundCode = "119598",
                fundName = "Axis Bluechip Fund Direct Growth",
                amount = 5000.0,
                frequency = SipFrequency.MONTHLY,
                nextDate = "Jan 15",
                status = SipStatus.ACTIVE,
                totalInvested = 60000.0,
                sipCount = 12
            ),
            Sip(
                id = "2",
                fundCode = "145552",
                fundName = "Mirae Asset Large Cap Fund Direct Growth",
                amount = 3000.0,
                frequency = SipFrequency.MONTHLY,
                nextDate = "Jan 20",
                status = SipStatus.ACTIVE,
                totalInvested = 36000.0,
                sipCount = 12
            ),
            Sip(
                id = "3",
                fundCode = "120594",
                fundName = "HDFC Corporate Bond Fund Direct Growth",
                amount = 2000.0,
                frequency = SipFrequency.MONTHLY,
                nextDate = "Jan 25",
                status = SipStatus.ACTIVE,
                totalInvested = 24000.0,
                sipCount = 12
            )
        )
    }

    private fun createMockTransactions(): List<Transaction> {
        return listOf(
            Transaction(
                id = "1",
                fundCode = "119598",
                fundName = "Axis Bluechip Fund Direct Growth",
                type = TransactionType.SIP_INSTALLMENT,
                amount = 5000.0,
                units = 95.23,
                nav = 52.50,
                date = "Jan 10, 2026",
                status = TransactionStatus.COMPLETED
            ),
            Transaction(
                id = "2",
                fundCode = "145552",
                fundName = "Mirae Asset Large Cap Fund",
                type = TransactionType.PURCHASE,
                amount = 10000.0,
                units = 117.37,
                nav = 85.20,
                date = "Jan 5, 2026",
                status = TransactionStatus.COMPLETED
            ),
            Transaction(
                id = "3",
                fundCode = "120594",
                fundName = "HDFC Corporate Bond Fund",
                type = TransactionType.SIP_INSTALLMENT,
                amount = 2000.0,
                units = 74.63,
                nav = 26.80,
                date = "Jan 1, 2026",
                status = TransactionStatus.COMPLETED
            )
        )
    }

    private fun createMockUpcomingActions(): List<UpcomingAction> {
        return listOf(
            UpcomingAction(
                id = "1",
                title = "SIP Due: Axis Bluechip",
                description = "₹5,000 on Jan 15",
                type = ActionType.SIP_DUE,
                dueDate = "Jan 15"
            ),
            UpcomingAction(
                id = "2",
                title = "Tax Saving Deadline",
                description = "₹50,000 remaining under 80C",
                type = ActionType.TAX_SAVING,
                dueDate = "Mar 31"
            ),
            UpcomingAction(
                id = "3",
                title = "Portfolio Rebalance",
                description = "Equity allocation above target",
                type = ActionType.REBALANCE,
                dueDate = "Review"
            )
        )
    }

    private fun createMockPortfolioHistory(period: HistoryPeriod): PortfolioHistory {
        val days = period.days.coerceAtMost(365 * 5)
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_YEAR, -days)

        val baseValue = 180000.0
        val baseInvested = 175000.0
        val pointCount = when (period) {
            HistoryPeriod.ONE_MONTH -> 30
            HistoryPeriod.THREE_MONTHS -> 45
            HistoryPeriod.SIX_MONTHS -> 60
            HistoryPeriod.ONE_YEAR -> 52
            HistoryPeriod.THREE_YEARS -> 72
            HistoryPeriod.FIVE_YEARS -> 60
            HistoryPeriod.ALL -> 80
        }
        val stepDays = days / pointCount

        val points = mutableListOf<PortfolioHistoryPoint>()
        var currentValue = baseValue
        var currentInvested = baseInvested

        for (i in 0..pointCount) {
            val dateStr = String.format(
                Locale.US, "%04d-%02d-%02d",
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH) + 1,
                calendar.get(Calendar.DAY_OF_MONTH)
            )

            points.add(
                PortfolioHistoryPoint(
                    id = i.toString(),
                    date = dateStr,
                    value = currentValue,
                    invested = currentInvested
                )
            )

            // Simulate growth with some volatility
            val growthRate = 0.0008 + (Math.random() * 0.003 - 0.001)
            currentValue *= (1 + growthRate)
            currentInvested += (500 + Math.random() * 200) * stepDays / 30
            calendar.add(Calendar.DAY_OF_YEAR, stepDays)
        }

        return PortfolioHistory(dataPoints = points, period = period)
    }

    private fun createMockDividendSummary(): DividendSummary {
        return DividendSummary(
            financialYear = "FY 2025-26",
            totalReceived = 8450.0,
            projectedAnnual = 14200.0,
            dividendYield = 2.8,
            records = listOf(
                DividendRecord(
                    id = "d1",
                    fundCode = "119598",
                    fundName = "Axis Bluechip Fund",
                    amount = 3200.0,
                    unitsHeld = 234.56,
                    dividendPerUnit = 13.64,
                    recordDate = "Dec 15, 2025",
                    paymentDate = "Dec 20, 2025",
                    status = "Paid"
                ),
                DividendRecord(
                    id = "d2",
                    fundCode = "145552",
                    fundName = "Mirae Asset Large Cap Fund",
                    amount = 2750.0,
                    unitsHeld = 189.32,
                    dividendPerUnit = 14.53,
                    recordDate = "Nov 28, 2025",
                    paymentDate = "Dec 5, 2025",
                    status = "Paid"
                ),
                DividendRecord(
                    id = "d3",
                    fundCode = "120594",
                    fundName = "HDFC Corporate Bond Fund",
                    amount = 2500.0,
                    unitsHeld = 500.0,
                    dividendPerUnit = 5.0,
                    recordDate = "Jan 15, 2026",
                    paymentDate = "Jan 22, 2026",
                    status = "Announced"
                )
            ),
            nextExpectedDate = "Feb 15, 2026"
        )
    }

    private fun createMockGoals(): List<Goal> {
        return listOf(
            Goal(
                id = "1",
                name = "Retirement Fund",
                targetAmount = 5000000.0,
                currentAmount = 1250000.0,
                targetDate = "2045-01-01"
            ),
            Goal(
                id = "2",
                name = "Child Education",
                targetAmount = 2000000.0,
                currentAmount = 450000.0,
                targetDate = "2035-06-01"
            )
        )
    }
}

sealed class HomeUiState {
    data object Loading : HomeUiState()
    data object Success : HomeUiState()
    data class Error(val message: String) : HomeUiState()
}
