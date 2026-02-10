package com.sparrowinvest.app.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Warning

data class Language(
    val nativeName: String,
    val englishName: String,
    val code: String
)

@Composable
fun LanguageScreen(
    onBackClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    var selectedLanguage by remember { mutableStateOf("en") }

    val languages = remember {
        listOf(
            Language("English", "English", "en"),
            Language("\u0939\u093F\u0928\u094D\u0926\u0940", "Hindi", "hi"),
            Language("\u092E\u0930\u093E\u0920\u0940", "Marathi", "mr"),
            Language("\u0A97\u0AC1\u0A9C\u0AB0\u0ABE\u0AA4\u0AC0", "Gujarati", "gu"),
            Language("\u0BA4\u0BAE\u0BBF\u0BB4\u0BCD", "Tamil", "ta"),
            Language("\u0C24\u0C46\u0C32\u0C41\u0C17\u0C41", "Telugu", "te"),
            Language("\u0C95\u0CA8\u0CCD\u0CA8\u0CA1", "Kannada", "kn"),
            Language("\u09AC\u09BE\u0982\u09B2\u09BE", "Bengali", "bn")
        )
    }

    val glassBorderBrush = if (isDark) {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    val cardBackground = if (isDark) CardBackgroundDark else CardBackgroundLight
    val cardShape = RoundedCornerShape(CornerRadius.xLarge)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
            .verticalScroll(rememberScrollState())
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(
                onClick = onBackClick,
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(Primary.copy(alpha = 0.1f))
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = Primary
                )
            }

            Spacer(modifier = Modifier.width(Spacing.medium))

            Text(
                text = "Language",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Bold
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Language list card
        val cardModifier = if (isDark) {
            Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .clip(cardShape)
                .background(cardBackground)
                .border(1.dp, glassBorderBrush, cardShape)
        } else {
            Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .shadow(8.dp, cardShape, clip = false, ambientColor = ShadowColor, spotColor = ShadowColor)
                .clip(cardShape)
                .background(cardBackground)
                .border(1.dp, glassBorderBrush, cardShape)
        }

        Column(modifier = cardModifier) {
            languages.forEachIndexed { index, language ->
                val isSelected = selectedLanguage == language.code

                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { selectedLanguage = language.code }
                        .padding(horizontal = Spacing.medium, vertical = Spacing.compact + Spacing.micro),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Language text
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = language.nativeName,
                            style = MaterialTheme.typography.bodyLarge,
                            color = if (isSelected) Primary else MaterialTheme.colorScheme.onSurface,
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium
                        )
                        Text(
                            text = language.englishName,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }

                    // Checkmark indicator
                    if (isSelected) {
                        Box(
                            modifier = Modifier
                                .size(28.dp)
                                .clip(CircleShape)
                                .background(Primary),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = "Selected",
                                tint = Color.White,
                                modifier = Modifier.size(16.dp)
                            )
                        }
                    } else {
                        Box(
                            modifier = Modifier
                                .size(28.dp)
                                .clip(CircleShape)
                                .border(
                                    width = 2.dp,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.3f),
                                    shape = CircleShape
                                )
                        )
                    }
                }

                // Divider between items (not after last)
                if (index < languages.size - 1) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = Spacing.medium)
                            .height(1.dp)
                            .background(MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.5f))
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Info text
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.large),
            horizontalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Language changes will apply after restarting the app",
                style = MaterialTheme.typography.bodySmall,
                color = Warning,
                fontWeight = FontWeight.Medium
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xLarge))
    }
}
