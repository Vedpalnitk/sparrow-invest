package com.sparrowinvest.app.ui.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
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
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.ui.components.PrimaryButton
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import kotlinx.coroutines.delay

// Data models for risk assessment questions
data class RiskQuestion(
    val id: Int,
    val title: String,
    val subtitle: String,
    val options: List<RiskOption>
)

data class RiskOption(
    val text: String,
    val score: Int
)

// All 5 questions matching iOS reference
private val riskQuestions = listOf(
    RiskQuestion(
        id = 1,
        title = "Investment Experience",
        subtitle = "How would you describe your investment experience?",
        options = listOf(
            RiskOption("New to investing", 1),
            RiskOption("1-3 years", 2),
            RiskOption("3-5 years", 3),
            RiskOption("5+ years", 4)
        )
    ),
    RiskQuestion(
        id = 2,
        title = "Investment Goal",
        subtitle = "What is your primary investment goal?",
        options = listOf(
            RiskOption("Tax saving", 1),
            RiskOption("Regular income", 2),
            RiskOption("Retirement planning", 2),
            RiskOption("Child education", 3),
            RiskOption("Wealth creation", 4)
        )
    ),
    RiskQuestion(
        id = 3,
        title = "Time Horizon",
        subtitle = "How long do you plan to stay invested?",
        options = listOf(
            RiskOption("Less than 1 year", 1),
            RiskOption("1-3 years", 2),
            RiskOption("3-5 years", 3),
            RiskOption("5-10 years", 3),
            RiskOption("10+ years", 4)
        )
    ),
    RiskQuestion(
        id = 4,
        title = "Risk Tolerance",
        subtitle = "How do you feel about potential losses?",
        options = listOf(
            RiskOption("Can't tolerate any loss", 1),
            RiskOption("Small losses are OK", 2),
            RiskOption("Moderate losses are OK", 3),
            RiskOption("High volatility is OK", 4)
        )
    ),
    RiskQuestion(
        id = 5,
        title = "Monthly Investment",
        subtitle = "How much can you invest monthly?",
        options = listOf(
            RiskOption("Less than \u20B95,000", 1),
            RiskOption("\u20B95,000 - \u20B915,000", 2),
            RiskOption("\u20B915,000 - \u20B930,000", 3),
            RiskOption("More than \u20B930,000", 4)
        )
    )
)

@Composable
fun RiskAssessmentScreen(
    onComplete: (category: String, score: Int) -> Unit,
    onBackClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    var currentQuestionIndex by remember { mutableIntStateOf(0) }
    val selectedAnswers = remember { mutableStateListOf<Int?>(null, null, null, null, null) }
    var isCalculating by remember { mutableStateOf(false) }

    // Direction tracking for animation
    var animationDirection by remember { mutableIntStateOf(1) } // 1 = forward, -1 = backward

    val currentQuestion = riskQuestions[currentQuestionIndex]
    val currentSelection = selectedAnswers[currentQuestionIndex]

    // Progress animation
    val progressTarget = (currentQuestionIndex + 1).toFloat() / riskQuestions.size.toFloat()
    val animatedProgress by animateFloatAsState(
        targetValue = progressTarget,
        animationSpec = tween(400),
        label = "progress"
    )

    // Calculating animation: wait then navigate to result
    LaunchedEffect(isCalculating) {
        if (isCalculating) {
            delay(2000)
            // Calculate total score from selected answers
            var score = 0
            for (i in riskQuestions.indices) {
                val answerIdx = selectedAnswers[i]
                if (answerIdx != null) {
                    score += riskQuestions[i].options[answerIdx].score
                }
            }
            val category = when {
                score <= 9 -> "Conservative"
                score <= 14 -> "Moderate"
                else -> "Aggressive"
            }
            onComplete(category, score)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
    ) {
        if (isCalculating) {
            // Calculating screen
            CalculatingView()
        } else {
            // Top bar with back button
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.small, vertical = Spacing.small),
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = {
                        if (currentQuestionIndex > 0) {
                            animationDirection = -1
                            currentQuestionIndex--
                        } else {
                            onBackClick()
                        }
                    }
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = MaterialTheme.colorScheme.onSurface
                    )
                }

                Spacer(modifier = Modifier.weight(1f))

                Text(
                    text = "Risk Assessment",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Spacer(modifier = Modifier.weight(1f))

                // Invisible placeholder for symmetry
                Box(modifier = Modifier.size(48.dp))
            }

            // Progress section
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.large)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Question ${currentQuestionIndex + 1} of ${riskQuestions.size}",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = "${(animatedProgress * 100).toInt()}%",
                        style = MaterialTheme.typography.labelMedium,
                        color = Primary
                    )
                }

                Spacer(modifier = Modifier.height(Spacing.small))

                // Progress bar with primary gradient
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(RoundedCornerShape(3.dp))
                        .background(
                            if (isDark) Color.White.copy(alpha = 0.1f)
                            else Color.Black.copy(alpha = 0.06f)
                        )
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(animatedProgress)
                            .height(6.dp)
                            .clip(RoundedCornerShape(3.dp))
                            .background(
                                brush = Brush.linearGradient(
                                    colors = listOf(Primary, Secondary)
                                )
                            )
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.xLarge))

            // Animated question content
            AnimatedContent(
                targetState = currentQuestionIndex,
                transitionSpec = {
                    val direction = animationDirection
                    (slideInHorizontally(
                        animationSpec = tween(300),
                        initialOffsetX = { fullWidth -> direction * fullWidth }
                    ) + fadeIn(animationSpec = tween(300)))
                        .togetherWith(
                            slideOutHorizontally(
                                animationSpec = tween(300),
                                targetOffsetX = { fullWidth -> -direction * fullWidth }
                            ) + fadeOut(animationSpec = tween(300))
                        )
                },
                label = "questionTransition"
            ) { questionIndex ->
                val question = riskQuestions[questionIndex]

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .verticalScroll(rememberScrollState())
                        .padding(horizontal = Spacing.large)
                ) {
                    // Question title
                    Text(
                        text = question.title,
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )

                    Spacer(modifier = Modifier.height(Spacing.small))

                    // Question subtitle
                    Text(
                        text = question.subtitle,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )

                    Spacer(modifier = Modifier.height(Spacing.xLarge))

                    // Answer options
                    question.options.forEachIndexed { optionIndex, option ->
                        OptionCard(
                            text = option.text,
                            isSelected = selectedAnswers[questionIndex] == optionIndex,
                            onClick = {
                                selectedAnswers[questionIndex] = optionIndex
                            }
                        )
                        if (optionIndex < question.options.lastIndex) {
                            Spacer(modifier = Modifier.height(Spacing.compact))
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom button area
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = Spacing.large)
                    .padding(bottom = Spacing.xxLarge)
            ) {
                val isLastQuestion = currentQuestionIndex == riskQuestions.size - 1
                val buttonText = if (isLastQuestion) "See Results" else "Next"

                PrimaryButton(
                    text = buttonText,
                    onClick = {
                        if (isLastQuestion) {
                            isCalculating = true
                        } else {
                            animationDirection = 1
                            currentQuestionIndex++
                        }
                    },
                    enabled = currentSelection != null
                )

                // Step dots indicator
                Spacer(modifier = Modifier.height(Spacing.medium))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    riskQuestions.indices.forEach { index ->
                        val isActive = index == currentQuestionIndex
                        val isCompleted = selectedAnswers[index] != null

                        Box(
                            modifier = Modifier
                                .size(if (isActive) 10.dp else 8.dp)
                                .clip(CircleShape)
                                .background(
                                    when {
                                        isActive -> Primary
                                        isCompleted -> Primary.copy(alpha = 0.4f)
                                        else -> if (isDark) Color.White.copy(alpha = 0.15f)
                                        else Color.Black.copy(alpha = 0.1f)
                                    }
                                )
                        )
                        if (index < riskQuestions.lastIndex) {
                            Spacer(modifier = Modifier.width(Spacing.small))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun OptionCard(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.large)
    val interactionSource = remember { MutableInteractionSource() }

    val backgroundColor = when {
        isSelected && isDark -> Primary.copy(alpha = 0.15f)
        isSelected && !isDark -> Primary.copy(alpha = 0.08f)
        isDark -> Color.White.copy(alpha = 0.06f)
        else -> MaterialTheme.colorScheme.surfaceVariant
    }

    val borderColor = when {
        isSelected -> Primary
        isDark -> Color.White.copy(alpha = 0.1f)
        else -> Color.Black.copy(alpha = 0.08f)
    }

    val borderWidth = if (isSelected) 1.5.dp else 1.dp

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(backgroundColor)
            .border(width = borderWidth, color = borderColor, shape = shape)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = Spacing.medium, vertical = Spacing.medium)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Selection indicator circle
            Box(
                modifier = Modifier
                    .size(22.dp)
                    .clip(CircleShape)
                    .border(
                        width = if (isSelected) 6.dp else 2.dp,
                        color = if (isSelected) Primary
                        else if (isDark) Color.White.copy(alpha = 0.3f)
                        else Color.Black.copy(alpha = 0.2f),
                        shape = CircleShape
                    )
            )

            Spacer(modifier = Modifier.width(Spacing.medium))

            Text(
                text = text,
                style = MaterialTheme.typography.bodyLarge.copy(
                    fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal
                ),
                color = if (isSelected) Primary
                else MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

@Composable
private fun CalculatingView() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(Spacing.large),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Animated loading indicator
        CircularProgressIndicator(
            modifier = Modifier.size(64.dp),
            color = Primary,
            strokeWidth = 4.dp
        )

        Spacer(modifier = Modifier.height(Spacing.xLarge))

        Text(
            text = "Analyzing your profile...",
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Text(
            text = "We're determining the best investment\nstrategy for you",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}
