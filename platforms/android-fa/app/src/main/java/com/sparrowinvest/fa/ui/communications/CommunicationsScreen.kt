package com.sparrowinvest.fa.ui.communications

import android.webkit.WebView
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.fa.data.model.CommunicationChannel
import com.sparrowinvest.fa.data.model.CommunicationLog
import com.sparrowinvest.fa.data.model.Client
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.ListItemCard
import com.sparrowinvest.fa.ui.theme.*

private val WhatsAppGreen = Color(0xFF25D366)
private val GradientStart = Color(0xFF3B82F6)
private val GradientEnd = Color(0xFF38BDF8)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CommunicationsScreen(
    onBackClick: () -> Unit,
    viewModel: CommunicationsViewModel = hiltViewModel()
) {
    val state by viewModel.uiState.collectAsState()
    val context = LocalContext.current

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Communications") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.openBulkSend() }) {
                        Icon(Icons.Default.Groups, contentDescription = "Bulk Send")
                    }
                    IconButton(onClick = { viewModel.openCompose() }) {
                        Icon(Icons.Default.Edit, contentDescription = "Compose")
                    }
                }
            )
        }
    ) { padding ->
        if (state.isLoading) {
            Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .padding(horizontal = Spacing.medium),
                verticalArrangement = Arrangement.spacedBy(Spacing.medium)
            ) {
                // Stats KPI Row
                item {
                    Spacer(modifier = Modifier.height(Spacing.small))
                    StatsRow(state.stats)
                }

                // Channel Filter
                item {
                    ChannelFilterRow(
                        channelFilter = state.channelFilter,
                        onChannelChange = viewModel::onChannelFilterChange
                    )
                }

                // Type Filter
                if (state.templates.isNotEmpty()) {
                    item {
                        TypeFilterRow(
                            typeFilter = state.typeFilter,
                            templates = state.templates.map { it.type to it.label },
                            onTypeChange = viewModel::onTypeFilterChange
                        )
                    }
                }

                // History header
                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        SectionLabel("History")
                        Text(
                            "${state.total} total",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }

                if (state.isLoadingHistory) {
                    item {
                        Box(Modifier.fillMaxWidth().height(100.dp), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(modifier = Modifier.size(24.dp))
                        }
                    }
                } else if (state.logs.isEmpty()) {
                    item {
                        EmptyHistoryCard()
                    }
                } else {
                    items(state.logs, key = { it.id }) { log ->
                        HistoryItem(log)
                    }

                    if (state.totalPages > 1) {
                        item {
                            PaginationRow(
                                currentPage = state.currentPage,
                                totalPages = state.totalPages,
                                onPageChange = viewModel::loadHistory
                            )
                        }
                    }
                }

                item { Spacer(modifier = Modifier.height(40.dp)) }
            }
        }
    }

    // Quick Compose Sheet
    if (state.showComposeSheet) {
        ComposeSheet(state = state, viewModel = viewModel, context = context)
    }

    // Bulk Send Sheet
    if (state.showBulkSheet) {
        BulkSendSheet(state = state, viewModel = viewModel)
    }
}

// MARK: - Section Label

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text.uppercase(),
        style = MaterialTheme.typography.labelSmall.copy(
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.5.sp
        ),
        color = MaterialTheme.colorScheme.onSurfaceVariant
    )
}

// MARK: - Stats Row

@Composable
private fun StatsRow(stats: com.sparrowinvest.fa.data.model.CommunicationStats?) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small)
    ) {
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.AutoMirrored.Filled.Send,
            label = "Total Sent",
            value = "${stats?.totalSent ?: 0}",
            color = Primary
        )
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Default.Email,
            label = "Emails",
            value = "${stats?.emailCount ?: 0}",
            color = Info
        )
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Default.Forum,
            label = "WhatsApp",
            value = "${stats?.whatsappCount ?: 0}",
            color = WhatsAppGreen
        )
        StatCard(
            modifier = Modifier.weight(1f),
            icon = Icons.Default.CalendarMonth,
            label = "This Month",
            value = "${stats?.thisMonthCount ?: 0}",
            color = Warning
        )
    }
}

@Composable
private fun StatCard(
    modifier: Modifier,
    icon: ImageVector,
    label: String,
    value: String,
    color: Color
) {
    GlassCard(
        modifier = modifier,
        contentPadding = Spacing.compact
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .clip(CircleShape)
                    .background(color.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    icon,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = color
                )
            }
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                value,
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

// MARK: - Channel Filter (Capsule Toggles)

@Composable
private fun ChannelFilterRow(
    channelFilter: String?,
    onChannelChange: (String?) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
        SectionLabel("Channel")
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            CapsuleFilterButton(
                modifier = Modifier.weight(1f),
                label = "All",
                icon = Icons.Default.Inbox,
                isSelected = channelFilter == null,
                color = Primary,
                onClick = { onChannelChange(null) }
            )
            CapsuleFilterButton(
                modifier = Modifier.weight(1f),
                label = "Email",
                icon = Icons.Default.Email,
                isSelected = channelFilter == "EMAIL",
                color = Primary,
                onClick = { onChannelChange("EMAIL") }
            )
            CapsuleFilterButton(
                modifier = Modifier.weight(1f),
                label = "WhatsApp",
                icon = Icons.Default.Forum,
                isSelected = channelFilter == "WHATSAPP",
                color = WhatsAppGreen,
                onClick = { onChannelChange("WHATSAPP") }
            )
        }
    }
}

@Composable
private fun CapsuleFilterButton(
    modifier: Modifier = Modifier,
    label: String,
    icon: ImageVector,
    isSelected: Boolean,
    color: Color,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(50))
            .background(if (isSelected) color else color.copy(alpha = 0.1f))
            .clickable(onClick = onClick)
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                icon,
                contentDescription = null,
                modifier = Modifier.size(14.dp),
                tint = if (isSelected) Color.White else color
            )
            Spacer(modifier = Modifier.width(6.dp))
            Text(
                label,
                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Medium),
                color = if (isSelected) Color.White else color
            )
        }
    }
}

// MARK: - Type Filter (Horizontal Scrolling Pills)

@Composable
private fun TypeFilterRow(
    typeFilter: String?,
    templates: List<Pair<String, String>>,
    onTypeChange: (String?) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
        SectionLabel("Type")
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            GradientPill(
                label = "All",
                isSelected = typeFilter == null,
                onClick = { onTypeChange(null) }
            )
            templates.forEach { (type, label) ->
                GradientPill(
                    label = label,
                    isSelected = typeFilter == type,
                    onClick = { onTypeChange(type) }
                )
            }
        }
    }
}

@Composable
private fun GradientPill(
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .then(
                if (isSelected) Modifier.background(Brush.horizontalGradient(listOf(GradientStart, GradientEnd)))
                else Modifier.background(Primary.copy(alpha = 0.08f))
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 7.dp)
    ) {
        Text(
            label,
            style = MaterialTheme.typography.labelMedium,
            color = if (isSelected) Color.White else Primary
        )
    }
}

// MARK: - Empty History

@Composable
private fun EmptyHistoryCard() {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(CornerRadius.large))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
            .border(
                width = 0.5.dp,
                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.1f),
                shape = RoundedCornerShape(CornerRadius.large)
            )
            .padding(vertical = Spacing.xLarge),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                Icons.Default.MailOutline,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
            )
            Spacer(modifier = Modifier.height(Spacing.small))
            Text(
                "No communications yet",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                "Tap compose to send your first message",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
        }
    }
}

// MARK: - History Item

@Composable
private fun HistoryItem(log: CommunicationLog) {
    val channelColor = if (log.channel == "EMAIL") Primary else WhatsAppGreen

    ListItemCard {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(Spacing.small),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(channelColor.copy(alpha = 0.1f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    if (log.channel == "EMAIL") Icons.Default.Email else Icons.Default.Forum,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = channelColor
                )
            }

            Spacer(modifier = Modifier.width(Spacing.compact))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    log.client?.name ?: "Unknown",
                    style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    log.subject ?: log.type,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    formatDate(log.createdAt),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }

            Spacer(modifier = Modifier.width(Spacing.small))

            val statusColor = when (log.status.lowercase()) {
                "sent" -> Success
                "failed" -> Error
                "pending" -> Warning
                else -> MaterialTheme.colorScheme.onSurfaceVariant
            }
            Text(
                log.status,
                style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Medium),
                color = statusColor,
                modifier = Modifier
                    .clip(RoundedCornerShape(50))
                    .background(statusColor.copy(alpha = 0.1f))
                    .padding(horizontal = 8.dp, vertical = 3.dp)
            )
        }
    }
}

// MARK: - Pagination

@Composable
private fun PaginationRow(currentPage: Int, totalPages: Int, onPageChange: (Int) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        TextButton(
            onClick = { onPageChange(currentPage - 1) },
            enabled = currentPage > 1
        ) {
            Icon(Icons.Default.ChevronLeft, null, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(4.dp))
            Text("Previous")
        }
        Text(
            "Page $currentPage of $totalPages",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        TextButton(
            onClick = { onPageChange(currentPage + 1) },
            enabled = currentPage < totalPages
        ) {
            Text("Next")
            Spacer(modifier = Modifier.width(4.dp))
            Icon(Icons.Default.ChevronRight, null, modifier = Modifier.size(16.dp))
        }
    }
}

// MARK: - Capsule Channel Toggle (for sheets)

@Composable
private fun SheetChannelToggle(
    selected: CommunicationChannel,
    onSelect: (CommunicationChannel) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
        SectionLabel("Channel")
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            val isEmail = selected == CommunicationChannel.EMAIL
            // Email button
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(50))
                    .background(if (isEmail) Primary else Primary.copy(alpha = 0.1f))
                    .clickable { onSelect(CommunicationChannel.EMAIL) }
                    .padding(vertical = 10.dp),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Email, null,
                        modifier = Modifier.size(14.dp),
                        tint = if (isEmail) Color.White else Primary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        "Email",
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Medium),
                        color = if (isEmail) Color.White else Primary
                    )
                }
            }
            // WhatsApp button
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(50))
                    .background(if (!isEmail) WhatsAppGreen else WhatsAppGreen.copy(alpha = 0.1f))
                    .clickable { onSelect(CommunicationChannel.WHATSAPP) }
                    .padding(vertical = 10.dp),
                contentAlignment = Alignment.Center
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        Icons.Default.Forum, null,
                        modifier = Modifier.size(14.dp),
                        tint = if (!isEmail) Color.White else WhatsAppGreen
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        "WhatsApp",
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Medium),
                        color = if (!isEmail) Color.White else WhatsAppGreen
                    )
                }
            }
        }
    }
}

// MARK: - Horizontal Template Selector (for sheets)

@Composable
private fun SheetTemplateSelector(
    templates: List<com.sparrowinvest.fa.data.model.CommunicationTemplate>,
    selectedType: String,
    onSelect: (String) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
        SectionLabel("Template")
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            templates.forEach { template ->
                GradientPill(
                    label = template.label,
                    isSelected = selectedType == template.type,
                    onClick = { onSelect(template.type) }
                )
            }
        }
    }
}

// MARK: - Quick Compose Sheet

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ComposeSheet(
    state: CommunicationsUiState,
    viewModel: CommunicationsViewModel,
    context: android.content.Context
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val clipboardManager = LocalClipboardManager.current
    val channelColor = if (state.composeChannel == CommunicationChannel.WHATSAPP) WhatsAppGreen else Primary

    ModalBottomSheet(
        onDismissRequest = { viewModel.dismissCompose() },
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .padding(bottom = Spacing.xLarge),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            Text(
                "Quick Compose",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
                color = MaterialTheme.colorScheme.onSurface
            )

            if (state.composeSent) {
                // Success
                Column(
                    modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.xLarge),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(Spacing.small)
                ) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(CircleShape)
                            .background(Success.copy(alpha = 0.1f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Default.CheckCircle, null, modifier = Modifier.size(44.dp), tint = Success)
                    }
                    Text("Sent successfully!", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold))
                    Text("Your message has been delivered", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Spacer(modifier = Modifier.height(Spacing.small))
                    Button(
                        onClick = { viewModel.dismissCompose() },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(50),
                        colors = ButtonDefaults.buttonColors(containerColor = Primary)
                    ) {
                        Text("Done", modifier = Modifier.padding(vertical = 4.dp))
                    }
                }
            } else if (state.composeSelectedClient == null) {
                // Client selection
                SectionLabel("Select Client")
                OutlinedTextField(
                    value = state.composeClientSearch,
                    onValueChange = viewModel::onComposeClientSearch,
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Search clients...") },
                    leadingIcon = { Icon(Icons.Default.Search, null, modifier = Modifier.size(18.dp)) },
                    singleLine = true,
                    shape = RoundedCornerShape(CornerRadius.medium)
                )

                val filtered = state.clients.filter {
                    state.composeClientSearch.isEmpty() ||
                    it.name.contains(state.composeClientSearch, ignoreCase = true) ||
                    it.email.contains(state.composeClientSearch, ignoreCase = true)
                }.take(10)

                LazyColumn(modifier = Modifier.heightIn(max = 300.dp)) {
                    items(filtered, key = { it.id }) { client ->
                        ListItemCard(modifier = Modifier.padding(vertical = 2.dp).clickable {
                            viewModel.onComposeClientSelect(client)
                        }) {
                            Row(
                                modifier = Modifier.fillMaxWidth().padding(Spacing.compact),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // Avatar
                                Box(
                                    modifier = Modifier
                                        .size(36.dp)
                                        .clip(CircleShape)
                                        .background(Primary.copy(alpha = 0.1f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        client.name.take(1).uppercase(),
                                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
                                        color = Primary
                                    )
                                }
                                Spacer(modifier = Modifier.width(Spacing.compact))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(client.name, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium), color = MaterialTheme.colorScheme.onSurface)
                                    Text(client.email, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                }
                                Icon(Icons.Default.ChevronRight, null, modifier = Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    }
                }
            } else {
                // Selected client chip
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(CornerRadius.medium))
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
                        .border(0.5.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.1f), RoundedCornerShape(CornerRadius.medium))
                        .padding(Spacing.compact),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(32.dp)
                            .clip(CircleShape)
                            .background(Primary.copy(alpha = 0.1f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            state.composeSelectedClient!!.name.take(1).uppercase(),
                            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.SemiBold),
                            color = Primary
                        )
                    }
                    Spacer(modifier = Modifier.width(Spacing.compact))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            state.composeSelectedClient!!.name,
                            style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium),
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            state.composeSelectedClient!!.email,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    IconButton(
                        onClick = { viewModel.openCompose() },
                        modifier = Modifier.size(28.dp)
                    ) {
                        Icon(
                            Icons.Default.Close, null,
                            modifier = Modifier.size(16.dp),
                            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
                        )
                    }
                }

                // Channel toggle
                SheetChannelToggle(
                    selected = state.composeChannel,
                    onSelect = viewModel::onComposeChannelChange
                )

                // Template selector
                SheetTemplateSelector(
                    templates = state.templates,
                    selectedType = state.composeSelectedType,
                    onSelect = viewModel::onComposeTemplateChange
                )

                if (state.isLoadingPreview) {
                    Box(Modifier.fillMaxWidth().height(60.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(modifier = Modifier.size(24.dp))
                    }
                }

                AnimatedVisibility(visible = state.composeSelectedType.isNotEmpty() && !state.isLoadingPreview) {
                    Column(verticalArrangement = Arrangement.spacedBy(Spacing.medium)) {
                        if (state.composeChannel == CommunicationChannel.EMAIL) {
                            // Subject
                            Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                                SectionLabel("Subject")
                                OutlinedTextField(
                                    value = state.composeSubject,
                                    onValueChange = viewModel::onComposeSubjectChange,
                                    modifier = Modifier.fillMaxWidth(),
                                    singleLine = true,
                                    shape = RoundedCornerShape(CornerRadius.medium)
                                )
                            }
                        }

                        // Message Preview
                        Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                SectionLabel("Message Preview")
                                Row(
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(50))
                                        .clickable {
                                            val text = if (state.composeChannel == CommunicationChannel.EMAIL) {
                                                state.composeEmailBody.replace(Regex("<[^>]+>"), "")
                                            } else state.composeWhatsappBody
                                            clipboardManager.setText(AnnotatedString(text))
                                        }
                                        .padding(horizontal = 8.dp, vertical = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        Icons.Default.ContentCopy, null,
                                        modifier = Modifier.size(12.dp),
                                        tint = Primary
                                    )
                                    Spacer(modifier = Modifier.width(3.dp))
                                    Text(
                                        "Copy",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = Primary
                                    )
                                }
                            }

                            if (state.composeChannel == CommunicationChannel.EMAIL) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .heightIn(max = 200.dp)
                                        .clip(RoundedCornerShape(CornerRadius.medium))
                                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
                                        .border(0.5.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.1f), RoundedCornerShape(CornerRadius.medium))
                                ) {
                                    AndroidView(
                                        factory = { ctx ->
                                            WebView(ctx).apply {
                                                settings.javaScriptEnabled = false
                                            }
                                        },
                                        update = { webView ->
                                            webView.loadDataWithBaseURL(null, state.composeEmailBody, "text/html", "UTF-8", null)
                                        },
                                        modifier = Modifier.fillMaxWidth().heightIn(min = 100.dp)
                                    )
                                }
                            } else {
                                Text(
                                    state.composeWhatsappBody,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurface,
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(CornerRadius.medium))
                                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f))
                                        .border(0.5.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.1f), RoundedCornerShape(CornerRadius.medium))
                                        .padding(Spacing.compact)
                                )
                            }
                        }
                    }
                }

                // Error
                state.composeError?.let { error ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Warning, null, modifier = Modifier.size(14.dp), tint = Error)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(error, style = MaterialTheme.typography.bodySmall, color = Error)
                    }
                }

                // Send button
                Button(
                    onClick = { viewModel.sendCompose(context) },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = state.composeSelectedType.isNotEmpty() && !state.isSending && !state.isLoadingPreview,
                    shape = RoundedCornerShape(50),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = channelColor,
                        disabledContainerColor = channelColor.copy(alpha = 0.4f)
                    )
                ) {
                    if (state.isSending) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp, color = Color.White)
                    } else {
                        Icon(
                            if (state.composeChannel == CommunicationChannel.WHATSAPP) Icons.AutoMirrored.Filled.Send else Icons.Default.Email,
                            null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            if (state.composeChannel == CommunicationChannel.WHATSAPP) "Send via WhatsApp" else "Send via Email",
                            modifier = Modifier.padding(vertical = 4.dp)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Bulk Send Sheet

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BulkSendSheet(
    state: CommunicationsUiState,
    viewModel: CommunicationsViewModel
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val channelColor = if (state.bulkChannel == CommunicationChannel.WHATSAPP) WhatsAppGreen else Primary

    ModalBottomSheet(
        onDismissRequest = { viewModel.dismissBulkSend() },
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium)
                .padding(bottom = Spacing.xLarge),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            Text(
                "Bulk Send",
                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.SemiBold),
                color = MaterialTheme.colorScheme.onSurface
            )

            if (state.bulkResult != null) {
                // Results
                Column(
                    modifier = Modifier.fillMaxWidth().padding(vertical = Spacing.xLarge),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(Spacing.small)
                ) {
                    Box(
                        modifier = Modifier
                            .size(80.dp)
                            .clip(CircleShape)
                            .background(Success.copy(alpha = 0.1f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Default.CheckCircle, null, modifier = Modifier.size(44.dp), tint = Success)
                    }
                    Text("Bulk send complete", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.SemiBold))

                    Row(horizontalArrangement = Arrangement.spacedBy(Spacing.large)) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                "${state.bulkResult.sent}",
                                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = Success
                            )
                            Text("Sent", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                "${state.bulkResult.failed}",
                                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = if (state.bulkResult.failed > 0) Error else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text("Failed", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                "${state.bulkResult.total}",
                                style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text("Total", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }

                    Spacer(modifier = Modifier.height(Spacing.small))
                    Button(
                        onClick = { viewModel.dismissBulkSend() },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(50),
                        colors = ButtonDefaults.buttonColors(containerColor = Primary)
                    ) {
                        Text("Done", modifier = Modifier.padding(vertical = 4.dp))
                    }
                }
            } else {
                // Channel toggle
                SheetChannelToggle(selected = state.bulkChannel, onSelect = viewModel::onBulkChannelChange)

                // Template selector
                SheetTemplateSelector(
                    templates = state.templates,
                    selectedType = state.bulkSelectedType,
                    onSelect = viewModel::onBulkTemplateChange
                )

                // Client selection
                Column(verticalArrangement = Arrangement.spacedBy(Spacing.small)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        SectionLabel("Select Clients")
                        Text(
                            "${state.bulkSelectedClients.size} selected",
                            style = MaterialTheme.typography.labelSmall,
                            color = Primary
                        )
                    }

                    // Select All
                    val allSelected = state.clients.isNotEmpty() && state.clients.all { it.id in state.bulkSelectedClients }
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(50))
                            .clickable {
                                if (allSelected) {
                                    state.clients.forEach { viewModel.toggleBulkClient(it.id) }
                                } else {
                                    state.clients.filter { it.id !in state.bulkSelectedClients }
                                        .forEach { viewModel.toggleBulkClient(it.id) }
                                }
                            }
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            if (allSelected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                            null,
                            modifier = Modifier.size(16.dp),
                            tint = Primary
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            if (allSelected) "Deselect All" else "Select All",
                            style = MaterialTheme.typography.labelMedium,
                            color = Primary
                        )
                    }

                    LazyColumn(modifier = Modifier.heightIn(max = 300.dp)) {
                        items(state.clients, key = { it.id }) { client ->
                            val isSelected = client.id in state.bulkSelectedClients
                            ListItemCard(modifier = Modifier.padding(vertical = 2.dp).clickable {
                                viewModel.toggleBulkClient(client.id)
                            }) {
                                Row(
                                    modifier = Modifier.fillMaxWidth().padding(Spacing.compact),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        if (isSelected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                                        null,
                                        modifier = Modifier.size(20.dp),
                                        tint = if (isSelected) Primary else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                                    )
                                    Spacer(modifier = Modifier.width(Spacing.compact))
                                    Box(
                                        modifier = Modifier
                                            .size(32.dp)
                                            .clip(CircleShape)
                                            .background(Primary.copy(alpha = 0.1f)),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(
                                            client.name.take(1).uppercase(),
                                            style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.SemiBold),
                                            color = Primary
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(Spacing.compact))
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(client.name, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Medium), color = MaterialTheme.colorScheme.onSurface)
                                        Text(client.email, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                                    }
                                }
                            }
                        }
                    }
                }

                // Error
                state.bulkError?.let { error ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Warning, null, modifier = Modifier.size(14.dp), tint = Error)
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(error, style = MaterialTheme.typography.bodySmall, color = Error)
                    }
                }

                // Send button
                Button(
                    onClick = { viewModel.sendBulk() },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = state.bulkSelectedClients.isNotEmpty() && state.bulkSelectedType.isNotEmpty() && !state.isBulkSending,
                    shape = RoundedCornerShape(50),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = channelColor,
                        disabledContainerColor = channelColor.copy(alpha = 0.4f)
                    )
                ) {
                    if (state.isBulkSending) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp, color = Color.White)
                    } else {
                        Icon(
                            if (state.bulkChannel == CommunicationChannel.WHATSAPP) Icons.AutoMirrored.Filled.Send else Icons.Default.Email,
                            null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            "Send to ${state.bulkSelectedClients.size} client${if (state.bulkSelectedClients.size == 1) "" else "s"}",
                            modifier = Modifier.padding(vertical = 4.dp)
                        )
                    }
                }
            }
        }
    }
}

private fun formatDate(dateStr: String): String {
    return try {
        val parts = dateStr.take(10).split("-")
        if (parts.size == 3) {
            val months = listOf("", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
            val month = months.getOrElse(parts[1].toInt()) { parts[1] }
            "${parts[2]} $month ${parts[0]}"
        } else dateStr
    } catch (_: Exception) { dateStr }
}
