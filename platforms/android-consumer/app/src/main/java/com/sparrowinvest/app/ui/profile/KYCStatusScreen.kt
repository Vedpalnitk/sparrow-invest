package com.sparrowinvest.app.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Upload
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.KycStatus
import com.sparrowinvest.app.ui.components.PrimaryButton
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Warning

private enum class StepStatus { COMPLETED, IN_PROGRESS, PENDING }

private data class KycStep(
    val title: String,
    val description: String,
    val status: StepStatus
)

private data class KycDocument(
    val name: String,
    val icon: ImageVector,
    val status: String,
    val statusColor: Color
)

@Composable
fun KYCStatusScreen(
    onBackClick: () -> Unit,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val currentUser by viewModel.currentUser.collectAsState()
    val isDark = LocalIsDarkTheme.current

    val kycStatus = currentUser?.kycStatus ?: KycStatus.PENDING
    val isFullyVerified = kycStatus == KycStatus.VERIFIED

    val steps = listOf(
        KycStep(
            title = "PAN Verification",
            description = "PAN card details verified",
            status = StepStatus.COMPLETED
        ),
        KycStep(
            title = "Aadhaar Verification",
            description = "Identity verified via Aadhaar",
            status = StepStatus.COMPLETED
        ),
        KycStep(
            title = "Bank Account",
            description = "Bank account linked for transactions",
            status = StepStatus.IN_PROGRESS
        ),
        KycStep(
            title = "Video KYC",
            description = "Complete a video call for verification",
            status = StepStatus.PENDING
        ),
        KycStep(
            title = "Digital Signature",
            description = "E-sign required documents",
            status = StepStatus.PENDING
        )
    )

    val successColor = Success
    val warningColor = Warning
    val errorColor = Color(0xFFEF4444)
    val grayColor = Color(0xFF9CA3AF)

    val documents = listOf(
        KycDocument(
            name = "PAN Card",
            icon = Icons.Default.Verified,
            status = "Verified",
            statusColor = successColor
        ),
        KycDocument(
            name = "Aadhaar Card",
            icon = Icons.Default.Verified,
            status = "Verified",
            statusColor = successColor
        ),
        KycDocument(
            name = "Address Proof",
            icon = Icons.Default.Schedule,
            status = "Pending Upload",
            statusColor = warningColor
        ),
        KycDocument(
            name = "Bank Statement",
            icon = Icons.Default.Upload,
            status = "Not Uploaded",
            statusColor = grayColor
        )
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
    ) {
        // Top Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = MaterialTheme.colorScheme.onSurface
                )
            }
            Text(
                text = "KYC Verification",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f)
            )
        }

        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = Spacing.medium)
        ) {
            Spacer(modifier = Modifier.height(Spacing.medium))

            // Section 1: Status Header
            KycGlassCard(isDark = isDark) {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Status icon circle
                    val (statusIcon, statusIconColor, statusBgColor) = when (kycStatus) {
                        KycStatus.VERIFIED -> Triple(
                            Icons.Default.CheckCircle,
                            successColor,
                            successColor.copy(alpha = 0.12f)
                        )
                        KycStatus.IN_PROGRESS -> Triple(
                            Icons.Default.Schedule,
                            warningColor,
                            warningColor.copy(alpha = 0.12f)
                        )
                        else -> Triple(
                            Icons.Default.Error,
                            errorColor,
                            errorColor.copy(alpha = 0.12f)
                        )
                    }

                    Box(
                        modifier = Modifier
                            .size(64.dp)
                            .clip(CircleShape)
                            .background(statusBgColor),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = statusIcon,
                            contentDescription = null,
                            tint = statusIconColor,
                            modifier = Modifier.size(32.dp)
                        )
                    }

                    Spacer(modifier = Modifier.height(Spacing.compact))

                    Text(
                        text = when (kycStatus) {
                            KycStatus.VERIFIED -> "KYC Verified"
                            KycStatus.IN_PROGRESS -> "KYC In Progress"
                            KycStatus.PENDING -> "KYC Not Verified"
                            KycStatus.REJECTED -> "KYC Rejected"
                        },
                        style = MaterialTheme.typography.titleLarge,
                        color = statusIconColor,
                        fontWeight = FontWeight.SemiBold
                    )

                    Spacer(modifier = Modifier.height(Spacing.micro))

                    Text(
                        text = when (kycStatus) {
                            KycStatus.VERIFIED -> "Your identity has been verified"
                            KycStatus.IN_PROGRESS -> "Verification is being processed"
                            KycStatus.PENDING -> "Complete KYC to start investing"
                            KycStatus.REJECTED -> "Please resubmit your documents"
                        },
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Section 2: Verification Steps Timeline
            KycGlassCard(isDark = isDark) {
                Text(
                    text = "VERIFICATION STEPS",
                    style = MaterialTheme.typography.labelSmall,
                    color = Primary,
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(Spacing.medium))

                steps.forEachIndexed { index, step ->
                    TimelineStep(
                        step = step,
                        isLast = index == steps.lastIndex,
                        isDark = isDark
                    )
                    if (index < steps.lastIndex) {
                        Spacer(modifier = Modifier.height(Spacing.micro))
                    }
                }
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Section 3: Documents
            KycGlassCard(isDark = isDark) {
                Text(
                    text = "DOCUMENTS",
                    style = MaterialTheme.typography.labelSmall,
                    color = Primary,
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(Spacing.medium))

                documents.forEachIndexed { index, document ->
                    DocumentRow(document = document)
                    if (index < documents.lastIndex) {
                        Spacer(modifier = Modifier.height(Spacing.compact))
                    }
                }
            }

            Spacer(modifier = Modifier.height(Spacing.xLarge))

            // CTA Button
            if (!isFullyVerified) {
                PrimaryButton(
                    text = "Continue Verification",
                    onClick = { /* Navigate to verification flow */ },
                    modifier = Modifier.padding(bottom = Spacing.medium)
                )
            }

            Spacer(modifier = Modifier.height(Spacing.large))
        }
    }
}

@Composable
private fun KycGlassCard(
    isDark: Boolean,
    content: @Composable () -> Unit
) {
    val shape = RoundedCornerShape(CornerRadius.xLarge)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = if (isDark) {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            colors = listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (!isDark) {
                    Modifier.shadow(
                        elevation = 12.dp,
                        shape = shape,
                        spotColor = ShadowColor,
                        ambientColor = ShadowColor
                    )
                } else Modifier
            )
            .clip(shape)
            .background(backgroundColor)
            .border(width = 1.dp, brush = borderBrush, shape = shape)
            .padding(Spacing.medium)
    ) {
        content()
    }
}

@Composable
private fun TimelineStep(
    step: KycStep,
    isLast: Boolean,
    isDark: Boolean
) {
    val successColor = Success
    val warningColor = Warning
    val grayColor = Color(0xFF9CA3AF)

    val dotColor = when (step.status) {
        StepStatus.COMPLETED -> successColor
        StepStatus.IN_PROGRESS -> warningColor
        StepStatus.PENDING -> grayColor
    }

    val lineColor = when (step.status) {
        StepStatus.COMPLETED -> successColor.copy(alpha = 0.4f)
        StepStatus.IN_PROGRESS -> warningColor.copy(alpha = 0.3f)
        StepStatus.PENDING -> grayColor.copy(alpha = 0.2f)
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(64.dp),
        verticalAlignment = Alignment.Top
    ) {
        // Timeline dot + line
        Box(
            modifier = Modifier
                .width(32.dp)
                .height(64.dp),
            contentAlignment = Alignment.TopCenter
        ) {
            // Vertical line
            if (!isLast) {
                Box(
                    modifier = Modifier
                        .width(2.dp)
                        .height(64.dp)
                        .padding(top = 14.dp)
                        .background(lineColor)
                )
            }
            // Dot
            Box(
                modifier = Modifier
                    .size(12.dp)
                    .clip(CircleShape)
                    .background(dotColor)
                    .padding(top = 2.dp)
            )
        }

        Spacer(modifier = Modifier.width(Spacing.compact))

        // Step content
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = step.title,
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface,
                fontWeight = FontWeight.Medium
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = step.description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }

        // Status badge
        val (badgeText, badgeColor) = when (step.status) {
            StepStatus.COMPLETED -> "Completed" to successColor
            StepStatus.IN_PROGRESS -> "In Progress" to warningColor
            StepStatus.PENDING -> "Pending" to grayColor
        }

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(badgeColor.copy(alpha = 0.12f))
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(
                text = badgeText,
                style = MaterialTheme.typography.labelSmall,
                color = badgeColor,
                fontWeight = FontWeight.Medium
            )
        }
    }
}

@Composable
private fun DocumentRow(document: KycDocument) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(document.statusColor.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = document.icon,
                contentDescription = null,
                tint = document.statusColor,
                modifier = Modifier.size(20.dp)
            )
        }

        Spacer(modifier = Modifier.width(Spacing.compact))

        Text(
            text = document.name,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(document.statusColor.copy(alpha = 0.1f))
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(
                text = document.status,
                style = MaterialTheme.typography.labelSmall,
                color = document.statusColor,
                fontWeight = FontWeight.Medium
            )
        }
    }
}
