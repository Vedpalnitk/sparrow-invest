package com.sparrowinvest.fa.data.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
data class CommunicationTemplate(
    val type: String,
    val label: String,
    val description: String
)

@Serializable
data class CommunicationPreview(
    val emailSubject: String,
    val emailBody: String,
    val whatsappBody: String
)

@Serializable
data class CommunicationSendResult(
    val success: Boolean,
    val logId: String,
    val waLink: String? = null,
    val error: String? = null
)

@Serializable
data class PreviewCommunicationRequest(
    val clientId: String,
    val type: String,
    val contextData: JsonObject? = null
)

@Serializable
data class SendCommunicationRequest(
    val clientId: String,
    val channel: String,
    val type: String,
    val subject: String,
    val body: String,
    val metadata: JsonObject? = null
)

enum class CommunicationChannel(val value: String) {
    EMAIL("EMAIL"),
    WHATSAPP("WHATSAPP")
}

@Serializable
data class CommunicationLogClient(
    val id: String,
    val name: String,
    val email: String? = null,
    val phone: String? = null
)

@Serializable
data class CommunicationLog(
    val id: String,
    val advisorId: String,
    val clientId: String,
    val channel: String,
    val type: String,
    val subject: String? = null,
    val body: String,
    val status: String,
    val error: String? = null,
    val sentAt: String? = null,
    val createdAt: String,
    val client: CommunicationLogClient? = null
)

@Serializable
data class CommunicationStats(
    val totalSent: Int,
    val emailCount: Int,
    val whatsappCount: Int,
    val thisMonthCount: Int
)

@Serializable
data class BulkSendRequest(
    val clientIds: List<String>,
    val channel: String,
    val type: String,
    val subject: String? = null,
    val customBody: String? = null
)

@Serializable
data class BulkSendResultItem(
    val clientId: String,
    val clientName: String,
    val success: Boolean,
    val error: String? = null,
    val logId: String? = null,
    val waLink: String? = null
)

@Serializable
data class BulkSendResult(
    val total: Int,
    val sent: Int,
    val failed: Int,
    val results: List<BulkSendResultItem>
)

@Serializable
data class PaginatedCommunicationResponse(
    val data: List<CommunicationLog>,
    val total: Int,
    val page: Int,
    val limit: Int,
    val totalPages: Int
)
