package com.sparrowinvest.app.ui.avya

import java.util.UUID

/**
 * Data class representing a chat message in Avya conversation
 */
data class ChatMessage(
    val id: String = UUID.randomUUID().toString(),
    val content: String,
    val isUser: Boolean,
    val timestamp: Long = System.currentTimeMillis()
)
