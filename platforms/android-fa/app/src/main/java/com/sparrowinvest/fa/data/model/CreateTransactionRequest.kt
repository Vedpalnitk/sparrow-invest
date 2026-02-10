package com.sparrowinvest.fa.data.model

import kotlinx.serialization.Serializable

@Serializable
data class CreateTransactionRequest(
    val clientId: String,
    val fundName: String,
    val fundSchemeCode: String,
    val fundCategory: String,
    val type: String,           // "Buy", "Sell", "SIP", "SWP", "Switch", "STP"
    val amount: Double,
    val nav: Double,
    val folioNumber: String,
    val date: String? = null,
    val paymentMode: String? = null,
    val remarks: String? = null
)
