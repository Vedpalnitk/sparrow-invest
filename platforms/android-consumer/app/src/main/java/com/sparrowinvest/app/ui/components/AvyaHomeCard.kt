package com.sparrowinvest.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.Chat
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sparrowinvest.app.ui.theme.*

/**
 * Avya Home Card - Prominent AI assistant widget on Home screen
 */
@Composable
fun AvyaHomeCard(
    onStartChat: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current

    val cardBackground = if (isDark) {
        Brush.linearGradient(
            colors = listOf(
                Color(0xFF1E1B4B).copy(alpha = 0.6f),
                Color(0xFF172554).copy(alpha = 0.4f)
            )
        )
    } else {
        Brush.linearGradient(
            colors = listOf(
                Color.White,
                Color(0xFFFAF5FF)
            )
        )
    }

    val borderGradient = Brush.linearGradient(
        colors = if (isDark) {
            listOf(
                Color(0xFF8B5CF6).copy(alpha = 0.4f),
                Color(0xFF3B82F6).copy(alpha = 0.2f),
                Color(0xFF06B6D4).copy(alpha = 0.3f)
            )
        } else {
            listOf(
                Color(0xFF8B5CF6).copy(alpha = 0.2f),
                Color(0xFF3B82F6).copy(alpha = 0.1f),
                Color(0xFF06B6D4).copy(alpha = 0.15f)
            )
        }
    )

    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(
                elevation = if (isDark) 0.dp else 16.dp,
                shape = RoundedCornerShape(20.dp),
                ambientColor = Primary.copy(alpha = 0.15f),
                spotColor = Primary.copy(alpha = 0.15f)
            )
            .clip(RoundedCornerShape(20.dp))
            .background(cardBackground)
            .border(
                width = 1.5.dp,
                brush = borderGradient,
                shape = RoundedCornerShape(20.dp)
            )
    ) {
        // Header Section
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Avya Avatar
            Box(
                modifier = Modifier
                    .size(56.dp)
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
                    modifier = Modifier.size(28.dp),
                    tint = Color.White
                )
            }

            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Avya",
                        fontSize = 20.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = if (isDark) Color.White else TextPrimaryLight
                    )
                    // AI Badge
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
                Text(
                    text = "Your intelligent investment companion",
                    fontSize = 13.sp,
                    color = if (isDark) Color.White.copy(alpha = 0.7f) else TextSecondaryLight
                )
            }
        }

        // Divider
        HorizontalDivider(
            color = if (isDark) Color.White.copy(alpha = 0.1f) else Color.Black.copy(alpha = 0.05f),
            thickness = 1.dp
        )

        // Quick Prompts Section
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(
                text = "ASK AVYA",
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (isDark) Color.White.copy(alpha = 0.5f) else TextTertiaryLight,
                letterSpacing = 1.sp
            )

            // Prompt Chips
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                PromptChip(
                    text = "How's my portfolio?",
                    onClick = onStartChat,
                    modifier = Modifier.weight(1f)
                )
                PromptChip(
                    text = "Rebalance?",
                    onClick = onStartChat,
                    modifier = Modifier.weight(1f)
                )
            }

            // Start Conversation Button
            Button(
                onClick = onStartChat,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color.Transparent
                ),
                contentPadding = PaddingValues(0.dp)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
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
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Chat,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp),
                                tint = Color.White
                            )
                            Text(
                                text = "Start a conversation",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = Color.White
                            )
                        }
                        Icon(
                            imageVector = Icons.Default.ArrowForward,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = Color.White
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun PromptChip(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current

    Surface(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .clickable(onClick = onClick),
        color = if (isDark) Color.White.copy(alpha = 0.1f) else Primary.copy(alpha = 0.08f),
        shape = RoundedCornerShape(20.dp)
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            color = if (isDark) Color.White.copy(alpha = 0.9f) else TextPrimaryLight.copy(alpha = 0.8f),
            maxLines = 1
        )
    }
}
