package com.sparrowinvest.fa.data.model

import kotlinx.serialization.Serializable

enum class NotificationCategory(val key: String, val displayName: String, val description: String) {
    TRADE_ALERTS("TRADE_ALERTS", "Trade Alerts", "Get notified when trades are executed"),
    SIP_REMINDERS("SIP_REMINDERS", "SIP Reminders", "Upcoming SIP installment reminders"),
    CLIENT_REQUESTS("CLIENT_REQUESTS", "Client Requests", "New trade requests from clients"),
    MARKET_UPDATES("MARKET_UPDATES", "Market Updates", "Daily market summary and NAV updates"),
    DAILY_DIGEST("DAILY_DIGEST", "Daily Digest", "Summary of portfolio changes and pending actions"),
    PORTFOLIO_ALERTS("PORTFOLIO_ALERTS", "Portfolio Alerts", "Significant portfolio value changes"),
    KYC_ALERTS("KYC_ALERTS", "KYC Alerts", "KYC expiry and renewal reminders");
}

enum class NotificationChannelType(val key: String, val displayName: String) {
    PUSH("PUSH", "Push"),
    EMAIL("EMAIL", "Email"),
    WHATSAPP("WHATSAPP", "WhatsApp");
}

@Serializable
data class ChannelPrefs(
    val PUSH: Boolean = false,
    val EMAIL: Boolean = false,
    val WHATSAPP: Boolean = false
)

// Backend returns Map<String, Map<String, Boolean>>
// e.g. { "TRADE_ALERTS": { "PUSH": true, "EMAIL": true, "WHATSAPP": false } }
typealias NotificationPreferences = Map<String, Map<String, Boolean>>

@Serializable
data class PreferenceUpdate(
    val category: String,
    val channel: String,
    val enabled: Boolean
)

@Serializable
data class UpdatePreferencesRequest(
    val updates: List<PreferenceUpdate>
)

@Serializable
data class NotificationLogEntry(
    val id: String,
    val category: String,
    val channel: String,
    val status: String,
    val subject: String? = null,
    val body: String? = null,
    val error: String? = null,
    val sentAt: String? = null,
    val createdAt: String
)

@Serializable
data class NotificationLogsResponse(
    val data: List<NotificationLogEntry>,
    val total: Int,
    val limit: Int,
    val offset: Int
)
