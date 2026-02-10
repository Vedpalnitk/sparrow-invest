package com.sparrowinvest.app.data.model

import kotlinx.serialization.Serializable

@Serializable
data class ChatSession(
    val id: String,
    val userId: String,
    val title: String? = null,
    val isActive: Boolean,
    val createdAt: String
)

@Serializable
data class CreateSessionRequest(
    val title: String? = null
)

@Serializable
data class SendMessageRequest(
    val sessionId: String,
    val content: String,
    val speakResponse: Boolean? = null
)

@Serializable
data class ChatMessageResponse(
    val messageId: String,
    val status: String,
    val content: String? = null,
    val audioUrl: String? = null,
    val error: String? = null,
    val createdAt: String? = null
)

@Serializable
data class ChatMessageStatus(
    val messageId: String,
    val status: String,
    val content: String? = null,
    val audioUrl: String? = null,
    val error: String? = null
)

@Serializable
data class ChatHistoryMessage(
    val id: String,
    val role: String,
    val content: String,
    val createdAt: String
)
