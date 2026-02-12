package com.sparrowinvest.fa.ui.actioncenter

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.People
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.Warning
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.fa.data.model.Client
import com.sparrowinvest.fa.data.model.FASip
import com.sparrowinvest.fa.data.model.FATransaction
import com.sparrowinvest.fa.ui.components.EmptyState
import com.sparrowinvest.fa.ui.components.ErrorState
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.LoadingIndicator
import com.sparrowinvest.fa.ui.components.TopBar
import com.sparrowinvest.fa.ui.theme.CornerRadius
import com.sparrowinvest.fa.ui.theme.Error
import com.sparrowinvest.fa.ui.theme.Primary
import com.sparrowinvest.fa.ui.theme.Spacing
import com.sparrowinvest.fa.ui.theme.Success
import com.sparrowinvest.fa.ui.theme.Warning

@OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class)
@Composable
fun ActionCenterScreen(
    viewModel: ActionCenterViewModel = hiltViewModel(),
    onBackClick: () -> Unit,
    onNavigateToClient: (String) -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val isRefreshing = uiState is ActionCenterUiState.Loading

    Column(modifier = Modifier.fillMaxSize()) {
        TopBar(title = "Action Center", onBackClick = onBackClick)

        androidx.compose.material3.pulltorefresh.PullToRefreshBox(
            isRefreshing = isRefreshing,
            onRefresh = { viewModel.loadActions() },
            modifier = Modifier.fillMaxSize()
        ) {
            when (val state = uiState) {
                is ActionCenterUiState.Loading -> {
                    LoadingIndicator(modifier = Modifier.fillMaxSize())
                }
                is ActionCenterUiState.Error -> {
                    ErrorState(
                        message = state.message,
                        onRetry = { viewModel.loadActions() },
                        modifier = Modifier.fillMaxSize()
                    )
                }
                is ActionCenterUiState.Success -> {
                    val data = state.data
                    if (data.totalCount == 0) {
                        EmptyState(
                            title = "All caught up!",
                            message = "No pending actions at the moment",
                            modifier = Modifier.fillMaxSize()
                        )
                    } else {
                        ActionCenterContent(
                            data = data,
                            context = context
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ActionCenterContent(
    data: ActionCenterData,
    context: Context
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.medium)
    ) {
        item { Spacer(modifier = Modifier.height(Spacing.compact)) }

        // Summary bar
        item {
            SummaryBar(
                failedSips = data.failedSips.size,
                pendingTx = data.pendingTransactions.size,
                pendingKyc = data.pendingKycClients.size
            )
        }

        // Failed SIPs section
        if (data.failedSips.isNotEmpty()) {
            item {
                SectionLabel(
                    text = "FAILED SIPS",
                    count = data.failedSips.size,
                    color = Error
                )
            }
            item {
                GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
                    Column {
                        data.failedSips.forEach { sip ->
                            FailedSipActionItem(
                                sip = sip,
                                onWhatsAppClick = { shareSipFailure(context, sip) },
                                onEmailClick = { emailSipFailure(context, sip) }
                            )
                        }
                    }
                }
            }
        }

        // Pending Transactions section
        if (data.pendingTransactions.isNotEmpty()) {
            item {
                SectionLabel(
                    text = "PENDING TRANSACTIONS",
                    count = data.pendingTransactions.size,
                    color = Warning
                )
            }
            item {
                GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
                    Column {
                        data.pendingTransactions.forEach { tx ->
                            PendingTransactionActionItem(
                                transaction = tx,
                                onWhatsAppClick = { sharePendingTransaction(context, tx) },
                                onEmailClick = { emailPendingTransaction(context, tx) }
                            )
                        }
                    }
                }
            }
        }

        // KYC Alerts section
        if (data.pendingKycClients.isNotEmpty()) {
            item {
                SectionLabel(
                    text = "KYC PENDING",
                    count = data.pendingKycClients.size,
                    color = Primary
                )
            }
            item {
                GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
                    Column {
                        data.pendingKycClients.forEach { client ->
                            KycAlertItem(
                                client = client,
                                onWhatsAppClick = { shareKycReminder(context, client) },
                                onEmailClick = { emailKycReminder(context, client) }
                            )
                        }
                    }
                }
            }
        }

        item { Spacer(modifier = Modifier.height(Spacing.large)) }
    }
}

@Composable
private fun SummaryBar(failedSips: Int, pendingTx: Int, pendingKyc: Int) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        SummaryChip(
            count = failedSips,
            label = "Failed SIPs",
            color = Error,
            modifier = Modifier.weight(1f)
        )
        SummaryChip(
            count = pendingTx,
            label = "Pending Tx",
            color = Warning,
            modifier = Modifier.weight(1f)
        )
        SummaryChip(
            count = pendingKyc,
            label = "KYC Pending",
            color = Primary,
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun SummaryChip(
    count: Int,
    label: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(CornerRadius.medium))
            .background(color.copy(alpha = 0.08f))
            .padding(horizontal = Spacing.compact, vertical = Spacing.small),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = count.toString(),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = color
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = color.copy(alpha = 0.8f)
        )
    }
}

@Composable
private fun SectionLabel(text: String, count: Int, color: Color) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.small),
        modifier = Modifier.padding(start = Spacing.compact)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = color
        )
        Box(
            modifier = Modifier
                .size(20.dp)
                .clip(CircleShape)
                .background(color.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = count.toString(),
                style = MaterialTheme.typography.labelSmall,
                color = color
            )
        }
    }
}

@Composable
private fun FailedSipActionItem(
    sip: FASip,
    onWhatsAppClick: () -> Unit,
    onEmailClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.compact, vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(Error.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.Warning,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = Error
            )
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = sip.clientName ?: "Client",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = sip.fundName,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "SIP of ${sip.formattedAmount} failed",
                style = MaterialTheme.typography.labelSmall,
                color = Error
            )
        }

        IconButton(onClick = onWhatsAppClick, modifier = Modifier.size(36.dp)) {
            Icon(
                imageVector = Icons.Default.Share,
                contentDescription = "Share via WhatsApp",
                tint = Success,
                modifier = Modifier.size(18.dp)
            )
        }
        IconButton(onClick = onEmailClick, modifier = Modifier.size(36.dp)) {
            Icon(
                imageVector = Icons.Default.Email,
                contentDescription = "Share via Email",
                tint = Primary,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

@Composable
private fun PendingTransactionActionItem(
    transaction: FATransaction,
    onWhatsAppClick: () -> Unit,
    onEmailClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.compact, vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(Warning.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.SwapHoriz,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = Warning
            )
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = transaction.clientName ?: "Client",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "${transaction.type} - ${transaction.fundName}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = transaction.formattedAmount,
                style = MaterialTheme.typography.labelSmall,
                color = Warning
            )
        }

        IconButton(onClick = onWhatsAppClick, modifier = Modifier.size(36.dp)) {
            Icon(
                imageVector = Icons.Default.Share,
                contentDescription = "Share via WhatsApp",
                tint = Success,
                modifier = Modifier.size(18.dp)
            )
        }
        IconButton(onClick = onEmailClick, modifier = Modifier.size(36.dp)) {
            Icon(
                imageVector = Icons.Default.Email,
                contentDescription = "Share via Email",
                tint = Primary,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

@Composable
private fun KycAlertItem(
    client: Client,
    onWhatsAppClick: () -> Unit,
    onEmailClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = Spacing.compact, vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .clip(RoundedCornerShape(CornerRadius.small))
                .background(Primary.copy(alpha = 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.People,
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = Primary
            )
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = client.name,
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "KYC: ${client.kycStatus ?: "PENDING"}",
                style = MaterialTheme.typography.labelSmall,
                color = Primary
            )
        }
        IconButton(onClick = onWhatsAppClick, modifier = Modifier.size(36.dp)) {
            Icon(
                imageVector = Icons.Default.Share,
                contentDescription = "Share via WhatsApp",
                tint = Success,
                modifier = Modifier.size(18.dp)
            )
        }
        IconButton(onClick = onEmailClick, modifier = Modifier.size(36.dp)) {
            Icon(
                imageVector = Icons.Default.Email,
                contentDescription = "Share via Email",
                tint = Primary,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

// --- Share intent helpers ---

fun shareSipFailure(context: Context, sip: FASip) {
    val message = buildString {
        appendLine("Hi ${sip.clientName ?: ""},")
        appendLine()
        appendLine("Your SIP of ${sip.formattedAmount} in ${sip.fundName} could not be processed.")
        appendLine()
        appendLine("This usually happens due to insufficient balance in your bank account on the SIP date.")
        appendLine()
        appendLine("Please ensure sufficient funds are available and I'll help re-initiate the installment.")
        appendLine()
        appendLine("- Sparrow Invest")
    }
    val shareIntent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, message)
    }
    context.startActivity(Intent.createChooser(shareIntent, "Share via"))
}

private fun emailSipFailure(context: Context, sip: FASip) {
    val subject = "SIP Payment Failed - ${sip.fundName}"
    val body = buildString {
        appendLine("Hi ${sip.clientName ?: ""},")
        appendLine()
        appendLine("Your SIP of ${sip.formattedAmount} in ${sip.fundName} could not be processed.")
        appendLine()
        appendLine("This usually happens due to insufficient balance in your bank account on the SIP date.")
        appendLine()
        appendLine("Please ensure sufficient funds are available and I'll help re-initiate the installment.")
        appendLine()
        appendLine("Best regards,")
        appendLine("Sparrow Invest")
    }
    openEmail(context, subject, body)
}

private fun sharePendingTransaction(context: Context, tx: FATransaction) {
    val message = buildString {
        appendLine("Hi ${tx.clientName ?: ""},")
        appendLine()
        appendLine("Your ${tx.type} transaction of ${tx.formattedAmount} in ${tx.fundName} is pending.")
        appendLine()
        appendLine("Please complete the required steps to process this transaction at the earliest.")
        appendLine()
        appendLine("- Sparrow Invest")
    }
    openWhatsApp(context, message)
}

private fun emailPendingTransaction(context: Context, tx: FATransaction) {
    val subject = "Pending Transaction - ${tx.fundName}"
    val body = buildString {
        appendLine("Hi ${tx.clientName ?: ""},")
        appendLine()
        appendLine("Your ${tx.type} transaction of ${tx.formattedAmount} in ${tx.fundName} is pending.")
        appendLine()
        appendLine("Please complete the required steps to process this transaction at the earliest.")
        appendLine()
        appendLine("Best regards,")
        appendLine("Sparrow Invest")
    }
    openEmail(context, subject, body)
}

private fun shareKycReminder(context: Context, client: Client) {
    val message = buildString {
        appendLine("Hi ${client.name},")
        appendLine()
        appendLine("A gentle reminder to complete your KYC verification for your mutual fund investments.")
        appendLine()
        appendLine("KYC is mandatory as per SEBI regulations and takes just a few minutes. Please share your PAN card and address proof at your earliest convenience.")
        appendLine()
        appendLine("I'm happy to guide you through the process.")
        appendLine()
        appendLine("- Sparrow Invest")
    }

    val phone = client.phone
    if (phone != null) {
        val cleanPhone = phone.replace("+", "").replace(" ", "")
        openWhatsApp(context, message, cleanPhone)
    } else {
        openWhatsApp(context, message)
    }
}

private fun emailKycReminder(context: Context, client: Client) {
    val subject = "KYC Verification Reminder"
    val body = buildString {
        appendLine("Hi ${client.name},")
        appendLine()
        appendLine("A gentle reminder to complete your KYC verification for your mutual fund investments.")
        appendLine()
        appendLine("KYC is mandatory as per SEBI regulations and takes just a few minutes. Please share your PAN card and address proof at your earliest convenience.")
        appendLine()
        appendLine("I'm happy to guide you through the process.")
        appendLine()
        appendLine("Best regards,")
        appendLine("Sparrow Invest")
    }
    openEmail(context, subject, body, client.email)
}

// --- Common intent helpers ---

private fun openWhatsApp(context: Context, message: String, phone: String? = null) {
    // Try WhatsApp directly first
    val waIntent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        setPackage("com.whatsapp")
        putExtra(Intent.EXTRA_TEXT, message)
    }
    try {
        context.startActivity(waIntent)
    } catch (_: Exception) {
        // WhatsApp not installed — open share sheet with pre-drafted text
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, message)
        }
        context.startActivity(Intent.createChooser(shareIntent, "Share via"))
    }
}

private fun openEmail(context: Context, subject: String, body: String, recipientEmail: String? = null) {
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "message/rfc822"
        if (recipientEmail != null) {
            putExtra(Intent.EXTRA_EMAIL, arrayOf(recipientEmail))
        }
        putExtra(Intent.EXTRA_SUBJECT, subject)
        putExtra(Intent.EXTRA_TEXT, body)
    }
    try {
        context.startActivity(Intent.createChooser(intent, "Send email via"))
    } catch (_: Exception) {
        // No email client — open general share sheet
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }
        context.startActivity(Intent.createChooser(shareIntent, "Share via"))
    }
}
