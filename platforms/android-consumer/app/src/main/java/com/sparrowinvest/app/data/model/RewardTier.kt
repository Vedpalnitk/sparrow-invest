package com.sparrowinvest.app.data.model

import androidx.compose.ui.graphics.Color

/**
 * Reward tier levels for the Sparrow Invest points/rewards system.
 * Matches the iOS RewardTier enum in Points.swift.
 */
enum class RewardTier(
    val displayName: String,
    val minPoints: Int,
    val tierColor: Color,
    val iconName: String,
    val benefits: List<String>
) {
    BRONZE(
        displayName = "Bronze",
        minPoints = 0,
        tierColor = Color(0xFFCC8033),
        iconName = "star",
        benefits = listOf(
            "Access to basic fund recommendations",
            "Monthly portfolio insights",
            "Email support"
        )
    ),
    SILVER(
        displayName = "Silver",
        minPoints = 1000,
        tierColor = Color(0xFFBFBFBF),
        iconName = "star_fill",
        benefits = listOf(
            "Priority customer support",
            "Weekly market insights",
            "Reduced transaction fees (0.1%)",
            "Early access to new features"
        )
    ),
    GOLD(
        displayName = "Gold",
        minPoints = 2500,
        tierColor = Color(0xFFFFD700),
        iconName = "star_circle_fill",
        benefits = listOf(
            "Dedicated relationship manager",
            "Free portfolio health checkups",
            "Reduced transaction fees (0.25%)",
            "Exclusive webinars & events",
            "Priority callback from advisors"
        )
    ),
    PLATINUM(
        displayName = "Platinum",
        minPoints = 5000,
        tierColor = Color(0xFFE6E6FA),
        iconName = "sparkles",
        benefits = listOf(
            "Personal wealth advisor",
            "Zero transaction fees",
            "Premium research reports",
            "VIP event invitations",
            "Concierge support 24/7",
            "Exclusive investment opportunities"
        )
    );

    val nextTier: RewardTier?
        get() = when (this) {
            BRONZE -> SILVER
            SILVER -> GOLD
            GOLD -> PLATINUM
            PLATINUM -> null
        }
}

/**
 * Holds the user's current points state.
 * Matches the iOS Points struct.
 */
data class PointsData(
    val totalPoints: Int = 0,
    val tier: RewardTier = RewardTier.BRONZE,
    val lifetimePoints: Int = 0,
    val expiringPoints: Int = 0,
    val expiryDate: String? = null
)
