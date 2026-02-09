package com.sparrowinvest.app.ui.avya

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sparrowinvest.app.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

/**
 * Avya AI Chat Screen with voice and text input
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AvyaChatScreen(
    onNavigateBack: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    var messageText by remember { mutableStateOf("") }
    var messages by remember { mutableStateOf(listOf<ChatMessage>()) }
    var isTyping by remember { mutableStateOf(false) }
    var isRecording by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()
    val coroutineScope = rememberCoroutineScope()

    // Dummy AI responses
    val dummyResponses = listOf(
        "Based on your portfolio, I recommend increasing your large-cap allocation by 5% to reduce volatility.",
        "Your current SIP of ₹10,000 is on track. Consider increasing it by 10% annually to reach your retirement goal faster.",
        "I've analyzed your holdings. The Parag Parikh Flexi Cap Fund has outperformed its benchmark by 3.2% this year.",
        "Looking at your risk profile, you might want to consider adding some debt funds for better diversification.",
        "Your portfolio health score is 78/100. The main areas for improvement are international exposure and sector diversification.",
        "Tax-saving tip: You can invest up to ₹1.5 lakhs in ELSS funds before March to save on taxes under Section 80C.",
        "I notice your mid-cap allocation has drifted 8% above target. Would you like me to suggest a rebalancing strategy?",
        "Great question! Based on current market conditions, hybrid funds could be a good option for moderate risk investors."
    )

    fun sendMessage() {
        if (messageText.isBlank()) return

        val userMessage = ChatMessage(
            content = messageText.trim(),
            isUser = true
        )
        messages = messages + userMessage
        messageText = ""

        // Scroll to bottom
        coroutineScope.launch {
            delay(100)
            listState.animateScrollToItem(messages.size)
        }

        // Simulate AI typing
        isTyping = true
        coroutineScope.launch {
            delay((1000..2500).random().toLong())
            isTyping = false

            val aiResponse = ChatMessage(
                content = dummyResponses.random(),
                isUser = false
            )
            messages = messages + aiResponse

            delay(100)
            listState.animateScrollToItem(messages.size)
        }
    }

    fun toggleRecording() {
        isRecording = !isRecording
        if (isRecording) {
            // Simulate voice recording
            coroutineScope.launch {
                delay(2000)
                isRecording = false
                val voiceQueries = listOf(
                    "How is my portfolio performing?",
                    "Should I increase my SIP?",
                    "What funds do you recommend?",
                    "Tell me about tax saving options"
                )
                messageText = voiceQueries.random()
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = "Avya",
                            fontWeight = FontWeight.SemiBold
                        )
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(4.dp))
                                .background(
                                    Brush.linearGradient(
                                        colors = listOf(
                                            Color(0xFF8B5CF6),
                                            Color(0xFF3B82F6)
                                        )
                                    )
                                )
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "AI",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = "Close"
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { messages = emptyList() }) {
                        Icon(
                            imageVector = Icons.Default.DeleteOutline,
                            contentDescription = "Clear chat"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = if (isDark) BackgroundDark else BackgroundLight
                )
            )
        },
        containerColor = if (isDark) BackgroundDark else BackgroundLight
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Messages List
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                state = listState,
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Welcome Card (shown when no messages)
                if (messages.isEmpty()) {
                    item {
                        WelcomeCard(onStartChat = { prompt ->
                            messageText = prompt
                            sendMessage()
                        })
                    }
                }

                // Chat Messages
                items(messages, key = { it.id }) { message ->
                    ChatBubble(message = message)
                }

                // Typing Indicator
                if (isTyping) {
                    item {
                        TypingIndicator()
                    }
                }
            }

            // Input Area
            ChatInputBar(
                messageText = messageText,
                onMessageChange = { messageText = it },
                onSend = { sendMessage() },
                onVoiceToggle = { toggleRecording() },
                isRecording = isRecording,
                isDark = isDark
            )
        }
    }
}

@Composable
private fun WelcomeCard(
    onStartChat: (String) -> Unit
) {
    val isDark = LocalIsDarkTheme.current

    val suggestedPrompts = listOf(
        "How is my portfolio performing?",
        "Should I rebalance my investments?",
        "What tax-saving options do I have?",
        "Recommend funds for my goals"
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(if (isDark) SurfaceDark else Color.White)
            .border(
                width = 1.dp,
                color = if (isDark) Color.White.copy(alpha = 0.1f) else Color.Black.copy(alpha = 0.05f),
                shape = RoundedCornerShape(20.dp)
            )
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Avya Avatar
        Box(
            modifier = Modifier
                .size(72.dp)
                .clip(CircleShape)
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            Color(0xFF6366F1),
                            Color(0xFF3B82F6),
                            Color(0xFF06B6D4)
                        )
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.AutoAwesome,
                contentDescription = null,
                modifier = Modifier.size(32.dp),
                tint = Color.White
            )
        }

        Text(
            text = "Avya",
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (isDark) Color.White else TextPrimaryLight
        )

        Text(
            text = "Your intelligent portfolio assistant",
            fontSize = 14.sp,
            color = if (isDark) Color.White.copy(alpha = 0.7f) else TextSecondaryLight,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        // Suggested Prompts
        Text(
            text = "TRY ASKING",
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            color = Primary,
            letterSpacing = 1.sp
        )

        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            suggestedPrompts.forEach { prompt ->
                SuggestedPromptRow(
                    prompt = prompt,
                    onClick = { onStartChat(prompt) },
                    isDark = isDark
                )
            }
        }
    }
}

@Composable
private fun SuggestedPromptRow(
    prompt: String,
    onClick: () -> Unit,
    isDark: Boolean
) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = if (isDark) Color.White.copy(alpha = 0.06f) else Color(0xFFF3F4F6)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Default.AutoAwesome,
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = Primary
            )
            Text(
                text = prompt,
                fontSize = 13.sp,
                color = if (isDark) Color.White else TextPrimaryLight,
                modifier = Modifier.weight(1f)
            )
            Icon(
                imageVector = Icons.Default.ArrowForward,
                contentDescription = null,
                modifier = Modifier.size(12.dp),
                tint = if (isDark) Color.White.copy(alpha = 0.4f) else TextTertiaryLight
            )
        }
    }
}

@Composable
private fun ChatBubble(message: ChatMessage) {
    val isDark = LocalIsDarkTheme.current
    val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (message.isUser) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.Bottom
    ) {
        if (!message.isUser) {
            // AI Avatar
            Box(
                modifier = Modifier
                    .padding(end = 8.dp)
                    .size(28.dp)
                    .clip(CircleShape)
                    .background(
                        Brush.linearGradient(
                            colors = listOf(
                                Color(0xFF6366F1),
                                Color(0xFF3B82F6)
                            )
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.AutoAwesome,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = Color.White
                )
            }
        }

        Column(
            horizontalAlignment = if (message.isUser) Alignment.End else Alignment.Start
        ) {
            Box(
                modifier = Modifier
                    .widthIn(max = 280.dp)
                    .clip(
                        RoundedCornerShape(
                            topStart = 18.dp,
                            topEnd = 18.dp,
                            bottomStart = if (message.isUser) 18.dp else 4.dp,
                            bottomEnd = if (message.isUser) 4.dp else 18.dp
                        )
                    )
                    .background(
                        if (message.isUser) {
                            Brush.linearGradient(
                                colors = listOf(
                                    Color(0xFF6366F1),
                                    Color(0xFF3B82F6)
                                )
                            )
                        } else {
                            Brush.linearGradient(
                                colors = if (isDark) {
                                    listOf(
                                        Color.White.copy(alpha = 0.1f),
                                        Color.White.copy(alpha = 0.1f)
                                    )
                                } else {
                                    listOf(
                                        Color(0xFFF3F4F6),
                                        Color(0xFFF3F4F6)
                                    )
                                }
                            )
                        }
                    )
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Text(
                    text = message.content,
                    fontSize = 15.sp,
                    color = if (message.isUser) Color.White else if (isDark) Color.White else TextPrimaryLight,
                    lineHeight = 22.sp
                )
            }

            Text(
                text = timeFormat.format(Date(message.timestamp)),
                fontSize = 10.sp,
                color = if (isDark) Color.White.copy(alpha = 0.4f) else TextTertiaryLight,
                modifier = Modifier.padding(top = 4.dp, start = 4.dp, end = 4.dp)
            )
        }
    }
}

@Composable
private fun TypingIndicator() {
    val isDark = LocalIsDarkTheme.current

    val infiniteTransition = rememberInfiniteTransition(label = "typing")

    Row(
        verticalAlignment = Alignment.Bottom,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // AI Avatar
        Box(
            modifier = Modifier
                .size(28.dp)
                .clip(CircleShape)
                .background(
                    Brush.linearGradient(
                        colors = listOf(
                            Color(0xFF6366F1),
                            Color(0xFF3B82F6)
                        )
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.AutoAwesome,
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = Color.White
            )
        }

        Row(
            modifier = Modifier
                .clip(RoundedCornerShape(18.dp))
                .background(if (isDark) Color.White.copy(alpha = 0.1f) else Color.White)
                .padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            repeat(3) { index ->
                val delay = index * 200
                val alpha by infiniteTransition.animateFloat(
                    initialValue = 0.3f,
                    targetValue = 1f,
                    animationSpec = infiniteRepeatable(
                        animation = tween(600, delayMillis = delay),
                        repeatMode = RepeatMode.Reverse
                    ),
                    label = "dot_$index"
                )

                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(Primary.copy(alpha = alpha))
                )
            }
        }
    }
}

@Composable
private fun ChatInputBar(
    messageText: String,
    onMessageChange: (String) -> Unit,
    onSend: () -> Unit,
    onVoiceToggle: () -> Unit,
    isRecording: Boolean,
    isDark: Boolean
) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = if (isDark) SurfaceDark else Color.White,
        shadowElevation = 8.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // Voice Button
            IconButton(
                onClick = onVoiceToggle,
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(
                        if (isRecording) Error else Primary.copy(alpha = 0.1f)
                    )
            ) {
                Icon(
                    imageVector = if (isRecording) Icons.Default.GraphicEq else Icons.Outlined.Mic,
                    contentDescription = "Voice input",
                    tint = if (isRecording) Color.White else Primary
                )
            }

            // Text Input
            OutlinedTextField(
                value = messageText,
                onValueChange = onMessageChange,
                modifier = Modifier.weight(1f),
                placeholder = {
                    Text(
                        text = "Ask Avya anything...",
                        color = if (isDark) Color.White.copy(alpha = 0.4f) else TextTertiaryLight
                    )
                },
                shape = RoundedCornerShape(24.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = if (isDark) Color.White.copy(alpha = 0.06f) else Color(0xFFF3F4F6),
                    unfocusedContainerColor = if (isDark) Color.White.copy(alpha = 0.06f) else Color(0xFFF3F4F6),
                    focusedBorderColor = Color.Transparent,
                    unfocusedBorderColor = Color.Transparent
                ),
                maxLines = 4
            )

            // Send Button
            IconButton(
                onClick = onSend,
                enabled = messageText.isNotBlank(),
                modifier = Modifier
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(
                        if (messageText.isNotBlank()) {
                            Brush.linearGradient(
                                colors = listOf(
                                    Color(0xFF6366F1),
                                    Color(0xFF3B82F6)
                                )
                            )
                        } else {
                            Brush.linearGradient(
                                colors = listOf(
                                    Color.Gray.copy(alpha = 0.3f),
                                    Color.Gray.copy(alpha = 0.3f)
                                )
                            )
                        }
                    )
            ) {
                Icon(
                    imageVector = Icons.Default.ArrowUpward,
                    contentDescription = "Send",
                    tint = if (messageText.isNotBlank()) Color.White else Color.Gray
                )
            }
        }
    }
}
