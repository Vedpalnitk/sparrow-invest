package com.sparrowinvest.fa.ui.transactions

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.fa.data.model.Client
import com.sparrowinvest.fa.data.model.Fund
import com.sparrowinvest.fa.ui.components.GlassCard
import com.sparrowinvest.fa.ui.components.GlassTextField
import com.sparrowinvest.fa.ui.components.ListItemCard
import com.sparrowinvest.fa.ui.components.LoadingIndicator
import com.sparrowinvest.fa.ui.components.PrimaryButton
import com.sparrowinvest.fa.ui.components.SecondaryButton
import com.sparrowinvest.fa.ui.components.WizardStepIndicator
import com.sparrowinvest.fa.ui.theme.CornerRadius
import com.sparrowinvest.fa.ui.theme.Error
import com.sparrowinvest.fa.ui.theme.Primary
import com.sparrowinvest.fa.ui.theme.Secondary
import com.sparrowinvest.fa.ui.theme.Spacing
import com.sparrowinvest.fa.ui.theme.Success

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NewTransactionWizardScreen(
    viewModel: NewTransactionWizardViewModel = hiltViewModel(),
    onBackClick: () -> Unit,
    onNavigateToPlatform: (String) -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("New Transaction") },
                navigationIcon = {
                    IconButton(onClick = {
                        if (uiState.currentStep.index > 0) {
                            viewModel.goToPreviousStep()
                        } else {
                            onBackClick()
                        }
                    }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        bottomBar = {
            WizardBottomBar(
                currentStep = uiState.currentStep,
                canGoNext = uiState.canGoNext,
                isSubmitting = uiState.isSubmitting,
                onBack = {
                    if (uiState.currentStep.index > 0) {
                        viewModel.goToPreviousStep()
                    } else {
                        onBackClick()
                    }
                },
                onNext = { viewModel.goToNextStep() },
                onSubmit = { viewModel.submitTransaction(onBackClick) }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Step indicator
            WizardStepIndicator(
                steps = WizardStep.entries.map { it.title },
                currentStep = uiState.currentStep.index,
                modifier = Modifier.padding(
                    horizontal = Spacing.small,
                    vertical = Spacing.compact
                )
            )

            Spacer(modifier = Modifier.height(Spacing.compact))

            // Error banner
            uiState.error?.let { error ->
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = Spacing.medium)
                        .clip(RoundedCornerShape(CornerRadius.small))
                        .background(Error.copy(alpha = 0.1f))
                        .padding(Spacing.compact)
                ) {
                    Text(
                        text = error,
                        style = MaterialTheme.typography.bodySmall,
                        color = Error
                    )
                }
                Spacer(modifier = Modifier.height(Spacing.small))
            }

            // Step content with animated transitions
            AnimatedContent(
                targetState = uiState.currentStep,
                transitionSpec = {
                    val direction = if (targetState.index > initialState.index) 1 else -1
                    slideInHorizontally { fullWidth -> direction * fullWidth } togetherWith
                            slideOutHorizontally { fullWidth -> -direction * fullWidth }
                },
                label = "WizardStep"
            ) { step ->
                when (step) {
                    WizardStep.SELECT_CLIENT -> SelectClientStep(
                        clients = uiState.filteredClients,
                        searchQuery = uiState.clientSearchQuery,
                        selectedClient = uiState.selectedClient,
                        isLoading = uiState.isLoadingClients,
                        onSearchQueryChange = viewModel::setClientSearchQuery,
                        onSelectClient = viewModel::selectClient
                    )
                    WizardStep.SELECT_FUND -> SelectFundStep(
                        searchQuery = uiState.fundSearchQuery,
                        searchResults = uiState.fundSearchResults,
                        selectedFund = uiState.selectedFund,
                        isLoading = uiState.isFundSearchLoading,
                        onSearchQueryChange = viewModel::setFundSearchQuery,
                        onSelectFund = viewModel::selectFund,
                        onClearFund = viewModel::clearFund
                    )
                    WizardStep.ENTER_DETAILS -> EnterDetailsStep(
                        transactionType = uiState.transactionType,
                        amount = uiState.amount,
                        folioNumber = uiState.folioNumber,
                        isNewFolio = uiState.isNewFolio,
                        paymentMode = uiState.paymentMode,
                        notes = uiState.notes,
                        onTransactionTypeChange = viewModel::setTransactionType,
                        onAmountChange = viewModel::setAmount,
                        onFolioChange = viewModel::setFolioNumber,
                        onNewFolioToggle = viewModel::toggleNewFolio,
                        onPaymentModeChange = viewModel::setPaymentMode,
                        onNotesChange = viewModel::setNotes
                    )
                    WizardStep.SELECT_PLATFORM -> SelectPlatformStep(
                        selectedPlatform = uiState.selectedPlatform,
                        orderId = uiState.orderId,
                        skipOrderId = uiState.skipOrderId,
                        platformVisited = uiState.platformVisited,
                        onSelectPlatform = viewModel::selectPlatform,
                        onOrderIdChange = viewModel::setOrderId,
                        onSkipOrderIdToggle = viewModel::toggleSkipOrderId,
                        onOpenPlatform = { platformId ->
                            viewModel.markPlatformVisited()
                            onNavigateToPlatform(platformId)
                        }
                    )
                    WizardStep.REVIEW -> ReviewStep(uiState = uiState)
                }
            }
        }
    }
}

// ─── Step 1: Select Client ──────────────────────────────────────────────────

@Composable
private fun SelectClientStep(
    clients: List<Client>,
    searchQuery: String,
    selectedClient: Client?,
    isLoading: Boolean,
    onSearchQueryChange: (String) -> Unit,
    onSelectClient: (Client) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.medium)
    ) {
        Text(
            text = "Select Client",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(Spacing.compact))

        GlassTextField(
            value = searchQuery,
            onValueChange = onSearchQueryChange,
            placeholder = "Search by name or email...",
            prefix = {
                Icon(
                    imageVector = Icons.Default.Search,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        )

        Spacer(modifier = Modifier.height(Spacing.compact))

        if (isLoading) {
            LoadingIndicator(
                modifier = Modifier.fillMaxSize(),
                message = "Loading clients..."
            )
        } else {
            LazyColumn(
                verticalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                items(clients, key = { it.id }) { client ->
                    ClientSelectCard(
                        client = client,
                        isSelected = selectedClient?.id == client.id,
                        onClick = { onSelectClient(client) }
                    )
                }
                item { Spacer(modifier = Modifier.height(Spacing.large)) }
            }
        }
    }
}

@Composable
private fun ClientSelectCard(
    client: Client,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    ListItemCard(
        modifier = Modifier
            .clickable(onClick = onClick)
            .then(
                if (isSelected) Modifier.border(
                    width = 2.dp,
                    color = Primary,
                    shape = RoundedCornerShape(CornerRadius.medium)
                ) else Modifier
            )
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            // Initials avatar
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(
                        if (isSelected) Primary
                        else Primary.copy(alpha = 0.1f)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = client.initials,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isSelected) Color.White else Primary
                )
            }

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = client.name,
                    style = MaterialTheme.typography.titleSmall,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = client.email,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "₹${client.formattedAum}",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurface
                )
                client.riskProfile?.let { risk ->
                    Text(
                        text = risk,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (isSelected) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Selected",
                    tint = Primary,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

// ─── Step 2: Select Fund ────────────────────────────────────────────────────

@Composable
private fun SelectFundStep(
    searchQuery: String,
    searchResults: List<Fund>,
    selectedFund: Fund?,
    isLoading: Boolean,
    onSearchQueryChange: (String) -> Unit,
    onSelectFund: (Fund) -> Unit,
    onClearFund: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = Spacing.medium)
    ) {
        Text(
            text = "Select Fund",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(Spacing.compact))

        if (selectedFund != null) {
            // Selected fund card
            GlassCard {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = selectedFund.schemeName,
                            style = MaterialTheme.typography.titleSmall,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Row(
                            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            selectedFund.nav?.let { nav ->
                                Text(
                                    text = "NAV: ₹${"%.2f".format(nav)}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            selectedFund.schemeCategory?.let { cat ->
                                Text(
                                    text = cat,
                                    style = MaterialTheme.typography.labelSmall,
                                    color = Primary
                                )
                            }
                        }
                    }
                    IconButton(onClick = onClearFund) {
                        Icon(
                            imageVector = Icons.Default.Clear,
                            contentDescription = "Clear",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        } else {
            GlassTextField(
                value = searchQuery,
                onValueChange = onSearchQueryChange,
                placeholder = "Search funds (min. 3 characters)...",
                prefix = {
                    Icon(
                        imageVector = Icons.Default.Search,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            )

            Spacer(modifier = Modifier.height(Spacing.compact))

            if (isLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = Spacing.large),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
                }
            } else {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(Spacing.small)
                ) {
                    items(searchResults, key = { it.schemeCode }) { fund ->
                        FundSelectCard(fund = fund, onClick = { onSelectFund(fund) })
                    }
                    item { Spacer(modifier = Modifier.height(Spacing.large)) }
                }
            }
        }
    }
}

@Composable
private fun FundSelectCard(
    fund: Fund,
    onClick: () -> Unit
) {
    ListItemCard(
        modifier = Modifier.clickable(onClick = onClick)
    ) {
        Column {
            Text(
                text = fund.schemeName,
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurface,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(Spacing.compact),
                verticalAlignment = Alignment.CenterVertically
            ) {
                fund.nav?.let { nav ->
                    Text(
                        text = "NAV: ₹${"%.2f".format(nav)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                fund.returns1y?.let { ret ->
                    val color = if (ret >= 0) Success else Error
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(4.dp))
                            .background(color.copy(alpha = 0.1f))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "%+.1f%% 1Y".format(ret),
                            style = MaterialTheme.typography.labelSmall,
                            color = color
                        )
                    }
                }
                fund.schemeCategory?.let { cat ->
                    Text(
                        text = cat,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }
    }
}

// ─── Step 3: Enter Details ──────────────────────────────────────────────────

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun EnterDetailsStep(
    transactionType: TransactionType,
    amount: String,
    folioNumber: String,
    isNewFolio: Boolean,
    paymentMode: PaymentMode,
    notes: String,
    onTransactionTypeChange: (TransactionType) -> Unit,
    onAmountChange: (String) -> Unit,
    onFolioChange: (String) -> Unit,
    onNewFolioToggle: (Boolean) -> Unit,
    onPaymentModeChange: (PaymentMode) -> Unit,
    onNotesChange: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.medium)
    ) {
        Text(
            text = "Transaction Details",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Spacer(modifier = Modifier.height(Spacing.medium))

        // Transaction Type
        Text(
            text = "TYPE",
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = Primary
        )
        Spacer(modifier = Modifier.height(Spacing.small))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            TransactionType.entries.forEach { type ->
                FilterChip(
                    selected = transactionType == type,
                    onClick = { onTransactionTypeChange(type) },
                    label = { Text(type.label) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = Primary.copy(alpha = 0.15f),
                        selectedLabelColor = Primary
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Amount
        Text(
            text = "AMOUNT",
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = Primary
        )
        Spacer(modifier = Modifier.height(Spacing.small))
        GlassTextField(
            value = amount,
            onValueChange = onAmountChange,
            placeholder = "Enter amount",
            prefix = {
                Text(
                    text = "₹",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            },
            keyboardType = androidx.compose.ui.text.input.KeyboardType.Decimal,
            singleLine = true
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Folio
        Text(
            text = "FOLIO NUMBER",
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = Primary
        )
        Spacer(modifier = Modifier.height(Spacing.small))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            FilterChip(
                selected = isNewFolio,
                onClick = { onNewFolioToggle(true) },
                label = { Text("New Folio") },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = Primary.copy(alpha = 0.15f),
                    selectedLabelColor = Primary
                )
            )
            FilterChip(
                selected = !isNewFolio,
                onClick = { onNewFolioToggle(false) },
                label = { Text("Existing") },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = Primary.copy(alpha = 0.15f),
                    selectedLabelColor = Primary
                )
            )
        }
        if (!isNewFolio) {
            Spacer(modifier = Modifier.height(Spacing.small))
            GlassTextField(
                value = folioNumber,
                onValueChange = onFolioChange,
                placeholder = "Enter folio number",
                singleLine = true
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Payment Mode
        Text(
            text = "PAYMENT MODE",
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = Primary
        )
        Spacer(modifier = Modifier.height(Spacing.small))
        FlowRow(
            horizontalArrangement = Arrangement.spacedBy(Spacing.small),
            verticalArrangement = Arrangement.spacedBy(Spacing.small)
        ) {
            PaymentMode.entries.forEach { mode ->
                FilterChip(
                    selected = paymentMode == mode,
                    onClick = { onPaymentModeChange(mode) },
                    label = { Text(mode.label) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = Primary.copy(alpha = 0.15f),
                        selectedLabelColor = Primary
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Notes
        Text(
            text = "NOTES (OPTIONAL)",
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.SemiBold,
            color = Primary
        )
        Spacer(modifier = Modifier.height(Spacing.small))
        GlassTextField(
            value = notes,
            onValueChange = onNotesChange,
            placeholder = "Any additional notes...",
            singleLine = false
        )

        Spacer(modifier = Modifier.height(Spacing.xxLarge))
    }
}

// ─── Step 4: Select Platform ────────────────────────────────────────────────

@Composable
private fun SelectPlatformStep(
    selectedPlatform: Platform?,
    orderId: String,
    skipOrderId: Boolean,
    platformVisited: Boolean,
    onSelectPlatform: (Platform) -> Unit,
    onOrderIdChange: (String) -> Unit,
    onSkipOrderIdToggle: (Boolean) -> Unit,
    onOpenPlatform: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.medium)
    ) {
        Text(
            text = "Select Platform & Execute",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Text(
            text = "Choose where to execute the transaction",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(Spacing.medium))

        // Platform cards
        Platform.entries.forEach { platform ->
            val isSelected = selectedPlatform == platform
            ListItemCard(
                modifier = Modifier
                    .clickable { onSelectPlatform(platform) }
                    .then(
                        if (isSelected) Modifier.border(
                            width = 2.dp,
                            color = Primary,
                            shape = RoundedCornerShape(CornerRadius.medium)
                        ) else Modifier
                    )
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = platform.label,
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = MaterialTheme.colorScheme.onSurface
                        )
                        Text(
                            text = platform.description,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    if (isSelected) {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = "Selected",
                            tint = Primary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
            Spacer(modifier = Modifier.height(Spacing.small))
        }

        // Open platform button
        if (selectedPlatform != null) {
            Spacer(modifier = Modifier.height(Spacing.compact))
            SecondaryButton(
                text = "Open ${selectedPlatform.label}",
                onClick = { onOpenPlatform(selectedPlatform.id) },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(Spacing.medium))

            if (platformVisited) {
                Text(
                    text = "ORDER ID",
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = Primary
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                GlassTextField(
                    value = orderId,
                    onValueChange = onOrderIdChange,
                    placeholder = "Enter order ID from ${selectedPlatform.label}",
                    singleLine = true,
                    enabled = !skipOrderId
                )
                Spacer(modifier = Modifier.height(Spacing.small))
            }

            // Skip option
            FilterChip(
                selected = skipOrderId,
                onClick = { onSkipOrderIdToggle(!skipOrderId) },
                label = { Text("Skip — Record without Order ID") },
                colors = FilterChipDefaults.filterChipColors(
                    selectedContainerColor = Primary.copy(alpha = 0.15f),
                    selectedLabelColor = Primary
                )
            )
        }

        Spacer(modifier = Modifier.height(Spacing.xxLarge))
    }
}

// ─── Step 5: Review ─────────────────────────────────────────────────────────

@Composable
private fun ReviewStep(uiState: NewTransactionWizardUiState) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.medium)
    ) {
        Text(
            text = "Review Transaction",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Text(
            text = "Please verify all details before submitting",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(Spacing.medium))

        // Client section
        GlassCard {
            Column {
                SectionLabel("CLIENT")
                Spacer(modifier = Modifier.height(Spacing.small))
                uiState.selectedClient?.let { client ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(Primary.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = client.initials,
                                style = MaterialTheme.typography.labelMedium,
                                color = Primary
                            )
                        }
                        Column {
                            Text(
                                text = client.name,
                                style = MaterialTheme.typography.titleSmall,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                            Text(
                                text = client.email,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.compact))

        // Fund section
        GlassCard {
            Column {
                SectionLabel("FUND")
                Spacer(modifier = Modifier.height(Spacing.small))
                uiState.selectedFund?.let { fund ->
                    Text(
                        text = fund.schemeName,
                        style = MaterialTheme.typography.titleSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Row(horizontalArrangement = Arrangement.spacedBy(Spacing.compact)) {
                        fund.nav?.let { nav ->
                            Text(
                                text = "NAV: ₹${"%.2f".format(nav)}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        fund.schemeCategory?.let { cat ->
                            Text(
                                text = cat,
                                style = MaterialTheme.typography.labelSmall,
                                color = Primary
                            )
                        }
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.compact))

        // Trade details section
        GlassCard {
            Column {
                SectionLabel("TRADE DETAILS")
                Spacer(modifier = Modifier.height(Spacing.small))

                ReviewRow("Type", uiState.transactionType.label)
                ReviewRow("Amount", "₹${uiState.amount}")
                ReviewRow(
                    "Folio",
                    if (uiState.isNewFolio) "New Folio" else uiState.folioNumber
                )
                ReviewRow("Payment", uiState.paymentMode.label)
                if (uiState.notes.isNotBlank()) {
                    ReviewRow("Notes", uiState.notes)
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.compact))

        // Platform section
        GlassCard {
            Column {
                SectionLabel("PLATFORM")
                Spacer(modifier = Modifier.height(Spacing.small))
                ReviewRow("Platform", uiState.selectedPlatform?.label ?: "-")
                if (uiState.orderId.isNotBlank()) {
                    ReviewRow("Order ID", uiState.orderId)
                } else if (uiState.skipOrderId) {
                    ReviewRow("Order ID", "Skipped")
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.xxLarge))
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.SemiBold,
        color = Primary
    )
}

@Composable
private fun ReviewRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

// ─── Bottom Bar ─────────────────────────────────────────────────────────────

@Composable
private fun WizardBottomBar(
    currentStep: WizardStep,
    canGoNext: Boolean,
    isSubmitting: Boolean,
    onBack: () -> Unit,
    onNext: () -> Unit,
    onSubmit: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .padding(horizontal = Spacing.medium, vertical = Spacing.compact)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            SecondaryButton(
                text = if (currentStep.index == 0) "Cancel" else "Back",
                onClick = onBack,
                modifier = Modifier.weight(1f)
            )

            if (currentStep == WizardStep.REVIEW) {
                PrimaryButton(
                    text = "Submit Transaction",
                    onClick = onSubmit,
                    enabled = canGoNext && !isSubmitting,
                    isLoading = isSubmitting,
                    modifier = Modifier.weight(1f)
                )
            } else {
                PrimaryButton(
                    text = "Next",
                    onClick = onNext,
                    enabled = canGoNext,
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}
