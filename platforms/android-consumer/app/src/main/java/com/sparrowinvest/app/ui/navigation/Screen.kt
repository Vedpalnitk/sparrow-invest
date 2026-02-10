package com.sparrowinvest.app.ui.navigation

import android.net.Uri

sealed class Screen(val route: String) {
    // Auth screens
    data object Welcome : Screen("welcome")
    data object Login : Screen("login")
    data object BiometricLogin : Screen("biometric-login")
    data object Signup : Screen("signup")
    data object OtpVerification : Screen("otp/{email}/{type}") {
        fun createRoute(email: String, type: String) = "otp/$email/$type"
    }
    data object ForgotPassword : Screen("forgot-password")

    // Main screens
    data object Home : Screen("home")
    data object Investments : Screen("investments")
    data object Explore : Screen("explore")
    data object Insights : Screen("insights")
    data object Profile : Screen("profile")

    // Detail screens
    data object FundDetail : Screen("fund/{schemeCode}") {
        fun createRoute(schemeCode: Int) = "fund/$schemeCode"
    }
    data object HoldingDetail : Screen("holding/{holdingId}") {
        fun createRoute(holdingId: String) = "holding/$holdingId"
    }
    data object TransactionHistory : Screen("transactions")
    data object SipList : Screen("sips")

    // Goals
    data object Goals : Screen("goals")
    data object GoalDetail : Screen("goal/{goalId}") {
        fun createRoute(goalId: String) = "goal/$goalId"
    }
    data object CreateGoal : Screen("goal/create")

    // Settings
    data object Settings : Screen("settings")
    data object NotificationSettings : Screen("settings/notifications")
    data object SecuritySettings : Screen("settings/security")
    data object LanguageSettings : Screen("settings/language")
    data object CacheManagement : Screen("settings/cache")

    // Onboarding
    data object RiskAssessment : Screen("onboarding/risk-assessment")
    data object RiskResult : Screen("onboarding/risk-result/{category}/{score}") {
        fun createRoute(category: String, score: Int) = "onboarding/risk-result/$category/$score"
    }

    // Advisor
    data object AdvisorDirectory : Screen("explore/advisors")
    data object AdvisorDetail : Screen("explore/advisor/{advisorId}") {
        fun createRoute(advisorId: String) = "explore/advisor/$advisorId"
    }
    data object MyAdvisor : Screen("my-advisor")

    // Profile sub-screens
    data object EditProfile : Screen("profile/edit")
    data object KYCStatus : Screen("profile/kyc")
    data object RiskProfile : Screen("profile/risk")

    // Points/Rewards
    data object Points : Screen("points")

    // AI/Analysis
    data object PortfolioAnalysis : Screen("analysis")
    data object Recommendations : Screen("recommendations")
    data object AvyaChat : Screen("avya_chat")

    // Invest
    data object BrokerSelection : Screen("broker-selection/{fundName}/{schemeCode}") {
        fun createRoute(fundName: String, schemeCode: Int) =
            "broker-selection/${Uri.encode(fundName)}/$schemeCode"
    }
    data object ManualInvestment : Screen("manual-investment")
}

object NavArguments {
    const val SCHEME_CODE = "schemeCode"
    const val HOLDING_ID = "holdingId"
    const val GOAL_ID = "goalId"
    const val EMAIL = "email"
    const val VERIFICATION_TYPE = "type"
    const val RISK_CATEGORY = "category"
    const val RISK_SCORE = "score"
    const val ADVISOR_ID = "advisorId"
    const val FUND_NAME = "fundName"
}
