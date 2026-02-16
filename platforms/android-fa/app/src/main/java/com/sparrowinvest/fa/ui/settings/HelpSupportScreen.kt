package com.sparrowinvest.fa.ui.settings

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.QuestionAnswer
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.TopBar
import com.sparrowinvest.fa.ui.theme.CornerRadius
import com.sparrowinvest.fa.ui.theme.Spacing

private data class FaqItem(val question: String, val answer: String)

private val faqItems = listOf(
    FaqItem(
        "How do I add a new client?",
        "Go to the Clients tab and tap the '+' button in the top right corner. Fill in the client's basic information, KYC details, and risk profile, then tap 'Create Client'."
    ),
    FaqItem(
        "How do I execute a transaction for a client?",
        "Navigate to the client's detail page, then tap the 'New Transaction' button. Follow the 4-step wizard: select client, choose transaction type, pick a fund, and enter the amount."
    ),
    FaqItem(
        "How do I manage SIPs?",
        "From a client's detail page, go to the SIPs tab. You can create new SIPs, or pause, resume, and cancel existing ones using the action buttons on each SIP card."
    ),
    FaqItem(
        "How do I generate client reports?",
        "Open the client's detail page and go to the Reports tab. Choose a report type (Portfolio Statement, Monthly Summary, etc.) and tap 'Generate'. You can share reports via WhatsApp, email, or save to Downloads."
    ),
    FaqItem(
        "What is Avya?",
        "Avya is your AI-powered assistant. You can ask Avya questions about your clients' portfolios, get rebalancing suggestions, tax-saving opportunities, and more. Access Avya from the floating button on the Dashboard."
    ),
    FaqItem(
        "How do I switch between BSE Star MF and MFU?",
        "When executing a transaction, you'll see the platform selection step. Choose either BSE Star MF or MFU as your execution platform. The app will open the respective platform's portal."
    ),
    FaqItem(
        "How do I update a client's KYC status?",
        "Go to the client's detail page, tap the Edit icon in the top right, and update their PAN number and KYC information. KYC status is also updated automatically when verified through BSE/MFU."
    ),
    FaqItem(
        "Can I access the app offline?",
        "The app requires an internet connection for live data. However, recently viewed client details and fund information may be cached for brief offline viewing."
    )
)

@Composable
fun HelpSupportScreen(
    onBackClick: () -> Unit
) {
    val context = LocalContext.current

    Column(modifier = Modifier.fillMaxSize()) {
        TopBar(title = "Help & Support", onBackClick = onBackClick)

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = Spacing.medium)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            Spacer(modifier = Modifier.height(Spacing.compact))

            // FAQs Section
            Text(
                text = "FREQUENTLY ASKED QUESTIONS",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(start = Spacing.compact)
            )
            GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
                Column {
                    faqItems.forEachIndexed { index, faq ->
                        FaqAccordionItem(
                            question = faq.question,
                            answer = faq.answer
                        )
                        if (index < faqItems.lastIndex) {
                            HorizontalDivider(
                                modifier = Modifier.padding(horizontal = Spacing.medium),
                                color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
                            )
                        }
                    }
                }
            }

            // User Guide
            Text(
                text = "RESOURCES",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(start = Spacing.compact)
            )
            GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
                Column {
                    HelpItem(
                        icon = Icons.Default.Book,
                        title = "User Guide",
                        subtitle = "Learn how to use the app",
                        onClick = { }
                    )
                }
            }

            // Contact Us
            Text(
                text = "CONTACT US",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(start = Spacing.compact)
            )
            GlassCard(cornerRadius = CornerRadius.large, contentPadding = Spacing.small) {
                Column {
                    HelpItem(
                        icon = Icons.AutoMirrored.Filled.Chat,
                        title = "Live Chat",
                        subtitle = "Chat with our support team",
                        onClick = { }
                    )
                    HelpItem(
                        icon = Icons.Default.Email,
                        title = "Email Support",
                        subtitle = "support@sparrow-invest.com",
                        onClick = {
                            val intent = Intent(Intent.ACTION_SENDTO).apply {
                                data = Uri.parse("mailto:support@sparrow-invest.com")
                                putExtra(Intent.EXTRA_SUBJECT, "FA App Support Request")
                            }
                            context.startActivity(Intent.createChooser(intent, "Send Email"))
                        }
                    )
                    HelpItem(
                        icon = Icons.Default.Phone,
                        title = "Call Us",
                        subtitle = "+91 1800-XXX-XXXX",
                        onClick = {
                            val intent = Intent(Intent.ACTION_DIAL).apply {
                                data = Uri.parse("tel:+911800XXXXXXX")
                            }
                            context.startActivity(intent)
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.large))
        }
    }
}

@Composable
private fun FaqAccordionItem(
    question: String,
    answer: String
) {
    var expanded by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { expanded = !expanded }
            .padding(horizontal = Spacing.medium, vertical = Spacing.small)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            Icon(
                imageVector = Icons.Default.QuestionAnswer,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(20.dp)
            )
            Text(
                text = question,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1f)
            )
            Icon(
                imageVector = if (expanded) Icons.Default.ExpandLess else Icons.Default.ExpandMore,
                contentDescription = if (expanded) "Collapse" else "Expand",
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.size(20.dp)
            )
        }

        AnimatedVisibility(
            visible = expanded,
            enter = expandVertically(),
            exit = shrinkVertically()
        ) {
            Text(
                text = answer,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(start = 28.dp, top = Spacing.small)
            )
        }
    }
}

@Composable
private fun HelpItem(
    icon: ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit = {}
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = Spacing.medium, vertical = Spacing.small),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.medium)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(22.dp)
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        Icon(
            imageVector = Icons.Default.ChevronRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(20.dp)
        )
    }
}
