package com.sparrowinvest.app.ui.analysis

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.FundHealthStatus
import com.sparrowinvest.app.data.model.HoldingAnalysis
import com.sparrowinvest.app.data.model.HoldingScores
import com.sparrowinvest.app.data.model.PortfolioAnalysisResponse
import com.sparrowinvest.app.data.model.PortfolioAnalysisSummary
import com.sparrowinvest.app.ui.components.GlassCard
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
import kotlinx.coroutines.launch

// ──────────────────────────────────────────────────────────────
// Formatting helpers
// ──────────────────────────────────────────────────────────────

private fun formatCurrency(value: Double): String {
    return when {
        value >= 100_000 -> "₹${String.format("%.1f", value / 100_000)}L"
        value >= 1_000 -> "₹${String.format("%.1f", value / 1_000)}K"
        else -> "₹${value.toInt()}"
    }
}

private fun formatPercent(value: Double): String {
    val sign = if (value >= 0) "+" else ""
    return "$sign${String.format("%.1f", value)}%"
}

// ──────────────────────────────────────────────────────────────
// Status icon helper
// ──────────────────────────────────────────────────────────────

@Composable
private fun StatusArrowIcon(
    status: FundHealthStatus,
    modifier: Modifier = Modifier,
    sizeDp: Int = 18
) {
    val icon: ImageVector = when (status) {
        FundHealthStatus.IN_FORM -> Icons.Filled.KeyboardArrowUp
        FundHealthStatus.ON_TRACK -> Icons.Filled.KeyboardArrowUp
        FundHealthStatus.OFF_TRACK -> Icons.Filled.KeyboardArrowDown
        FundHealthStatus.OUT_OF_FORM -> Icons.Filled.KeyboardArrowDown
    }
    // For double-arrow statuses, stack two icons
    if (status == FundHealthStatus.IN_FORM || status == FundHealthStatus.OUT_OF_FORM) {
        Column(
            modifier = modifier,
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = status.statusColor,
                modifier = Modifier.size(sizeDp.dp)
            )
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = status.statusColor,
                modifier = Modifier
                    .size(sizeDp.dp)
                    .padding(top = 0.dp)
            )
        }
    } else {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = status.statusColor,
            modifier = modifier.size(sizeDp.dp)
        )
    }
}

// ──────────────────────────────────────────────────────────────
// Main Screen
// ──────────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PortfolioAnalysisScreen(
    onBackClick: () -> Unit,
    viewModel: PortfolioAnalysisViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val analysis by viewModel.analysis.collectAsState()
    val selectedFilter by viewModel.selectedFilter.collectAsState()
    val filteredHoldings by viewModel.filteredHoldings.collectAsState()
    val isDark = LocalIsDarkTheme.current

    var selectedHolding by remember { mutableStateOf<HoldingAnalysis?>(null) }
    var showDetailSheet by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Portfolio Health",
                        fontWeight = FontWeight.SemiBold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.fetchAnalysis() }) {
                        Icon(
                            imageVector = Icons.Filled.Refresh,
                            contentDescription = "Refresh"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = if (isDark) Color(0xFF0A0A0F) else MaterialTheme.colorScheme.background
                )
            )
        },
        containerColor = if (isDark) Color(0xFF0A0A0F) else MaterialTheme.colorScheme.background
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when (uiState) {
                is PortfolioAnalysisUiState.Loading -> {
                    LoadingState()
                }

                is PortfolioAnalysisUiState.Error -> {
                    ErrorState(
                        message = (uiState as PortfolioAnalysisUiState.Error).message,
                        onRetry = { viewModel.fetchAnalysis() }
                    )
                }

                is PortfolioAnalysisUiState.Success -> {
                    analysis?.let { data ->
                        LazyColumn(
                            modifier = Modifier
                                .fillMaxSize()
                                .padding(horizontal = Spacing.medium),
                            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
                        ) {
                            // Health Summary Card
                            item {
                                Spacer(modifier = Modifier.height(Spacing.small))
                                HealthSummaryCard(summary = data.summary)
                            }

                            // Status Filter Bar
                            item {
                                StatusFilterBar(
                                    summary = data.summary,
                                    selectedFilter = selectedFilter,
                                    onFilterSelected = { viewModel.setFilter(it) }
                                )
                            }

                            // Holdings List
                            items(
                                items = filteredHoldings,
                                key = { it.id }
                            ) { holding ->
                                HoldingAnalysisCard(
                                    holding = holding,
                                    onClick = {
                                        selectedHolding = holding
                                        showDetailSheet = true
                                    }
                                )
                            }

                            // Recommendations Card
                            if (data.recommendations.isNotEmpty()) {
                                item {
                                    RecommendationsCard(recommendations = data.recommendations)
                                }
                            }

                            // Powered By Footer
                            data.poweredBy?.let { poweredBy ->
                                item {
                                    Text(
                                        text = "Powered by $poweredBy",
                                        fontSize = 11.sp,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(vertical = Spacing.small),
                                        textAlign = TextAlign.Center
                                    )
                                }
                            }

                            // Bottom spacing
                            item {
                                Spacer(modifier = Modifier.height(Spacing.large))
                            }
                        }
                    }
                }
            }
        }
    }

    // Detail Bottom Sheet
    if (showDetailSheet) {
        selectedHolding?.let { holding ->
            HoldingAnalysisDetailSheet(
                holding = holding,
                onDismiss = {
                    showDetailSheet = false
                    selectedHolding = null
                }
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Loading State
// ──────────────────────────────────────────────────────────────

@Composable
private fun LoadingState() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            CircularProgressIndicator(
                modifier = Modifier.size(48.dp),
                color = Primary,
                strokeWidth = 3.dp
            )
            Text(
                text = "Analyzing portfolio...",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Error State
// ──────────────────────────────────────────────────────────────

@Composable
private fun ErrorState(
    message: String,
    onRetry: () -> Unit
) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            Text(
                text = message,
                fontSize = 14.sp,
                color = MaterialTheme.colorScheme.error,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = Spacing.xLarge)
            )
            Text(
                text = "Tap to retry",
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                color = Primary,
                modifier = Modifier.clickable { onRetry() }
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Health Summary Card
// ──────────────────────────────────────────────────────────────

@Composable
private fun HealthSummaryCard(summary: PortfolioAnalysisSummary) {
    val isDark = LocalIsDarkTheme.current

    GlassCard {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.medium)) {
            // Top row: health info + score circle
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Left: Overall Health label + health label + trend
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = "Overall Health",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Light,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(
                        text = summary.healthLabel,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Light,
                        color = summary.healthColor
                    )
                    summary.healthTrend?.let { trend ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Icon(
                                imageVector = if (trend == "improving")
                                    Icons.Filled.KeyboardArrowUp
                                else
                                    Icons.Filled.KeyboardArrowDown,
                                contentDescription = null,
                                tint = if (trend == "improving") Success else MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.size(14.dp)
                            )
                            Text(
                                text = trend.replaceFirstChar { it.uppercase() },
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Light,
                                color = if (trend == "improving") Success else MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                }

                // Right: Animated score circle
                HealthScoreCircle(
                    score = summary.portfolioHealthScore,
                    color = summary.healthColor
                )
            }

            // Status count badges row
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                FundHealthStatus.entries.forEach { status ->
                    StatusCountBadge(
                        count = summary.countFor(status),
                        status = status,
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Animated Health Score Circle
// ──────────────────────────────────────────────────────────────

@Composable
private fun HealthScoreCircle(
    score: Double,
    color: Color
) {
    val animatedProgress by animateFloatAsState(
        targetValue = (score / 100f).toFloat(),
        animationSpec = tween(durationMillis = 1200),
        label = "scoreProgress"
    )

    val animatedColor by animateColorAsState(
        targetValue = color,
        animationSpec = tween(durationMillis = 800),
        label = "scoreColor"
    )

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier.size(80.dp)
    ) {
        Canvas(modifier = Modifier.size(80.dp)) {
            val strokeWidth = 8.dp.toPx()
            val arcSize = size.width - strokeWidth
            val topLeft = Offset(strokeWidth / 2, strokeWidth / 2)

            // Track
            drawArc(
                color = animatedColor.copy(alpha = 0.2f),
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = Size(arcSize, arcSize),
                style = Stroke(width = strokeWidth)
            )

            // Progress
            drawArc(
                color = animatedColor,
                startAngle = -90f,
                sweepAngle = animatedProgress * 360f,
                useCenter = false,
                topLeft = topLeft,
                size = Size(arcSize, arcSize),
                style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
            )
        }

        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "${score.toInt()}",
                fontSize = 24.sp,
                fontWeight = FontWeight.Light,
                color = animatedColor
            )
            Text(
                text = "/ 100",
                fontSize = 10.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Status Count Badge
// ──────────────────────────────────────────────────────────────

@Composable
private fun StatusCountBadge(
    count: Int,
    status: FundHealthStatus,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val bgAlpha = if (isDark) 0.15f else 0.1f
    val shape = RoundedCornerShape(CornerRadius.small)

    Column(
        modifier = modifier
            .clip(shape)
            .background(status.statusColor.copy(alpha = bgAlpha))
            .then(
                if (isDark) Modifier.border(
                    width = 0.5.dp,
                    color = status.statusColor.copy(alpha = 0.2f),
                    shape = shape
                ) else Modifier
            )
            .padding(vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            StatusArrowIcon(status = status, sizeDp = 11)
            Text(
                text = "$count",
                fontSize = 15.sp,
                fontWeight = FontWeight.Normal,
                color = status.statusColor
            )
        }
        Text(
            text = status.label,
            fontSize = 10.sp,
            fontWeight = FontWeight.Light,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            maxLines = 1
        )
    }
}

// ──────────────────────────────────────────────────────────────
// Status Filter Bar
// ──────────────────────────────────────────────────────────────

@Composable
private fun StatusFilterBar(
    summary: PortfolioAnalysisSummary,
    selectedFilter: FundHealthStatus?,
    onFilterSelected: (FundHealthStatus?) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState()),
        horizontalArrangement = Arrangement.spacedBy(Spacing.small)
    ) {
        // "All" pill
        FilterPill(
            label = "All",
            count = summary.totalHoldings,
            isSelected = selectedFilter == null,
            color = Primary,
            onClick = { onFilterSelected(null) }
        )

        // Status pills (only shown if count > 0)
        FundHealthStatus.entries.forEach { status ->
            val count = summary.countFor(status)
            if (count > 0) {
                FilterPill(
                    label = status.label,
                    count = count,
                    isSelected = selectedFilter == status,
                    color = status.statusColor,
                    onClick = { onFilterSelected(status) }
                )
            }
        }
    }
}

@Composable
private fun FilterPill(
    label: String,
    count: Int,
    isSelected: Boolean,
    color: Color,
    onClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    val pillShape = RoundedCornerShape(50)

    val backgroundColor = when {
        isSelected -> color
        isDark -> CardBackgroundDark
        else -> CardBackgroundLight
    }

    val textColor = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface

    val borderBrush = if (isSelected) {
        Brush.linearGradient(listOf(Color.Transparent, Color.Transparent))
    } else if (isDark) {
        Brush.linearGradient(
            listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    Row(
        modifier = Modifier
            .then(
                if (!isSelected && !isDark) {
                    Modifier.shadow(
                        elevation = 6.dp,
                        shape = pillShape,
                        spotColor = ShadowColor,
                        ambientColor = ShadowColor
                    )
                } else Modifier
            )
            .clip(pillShape)
            .background(backgroundColor)
            .border(
                width = 1.dp,
                brush = borderBrush,
                shape = pillShape
            )
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        Text(
            text = label,
            fontSize = 14.sp,
            fontWeight = FontWeight.Normal,
            color = textColor
        )
        Text(
            text = "$count",
            fontSize = 12.sp,
            fontWeight = FontWeight.Normal,
            color = textColor,
            modifier = Modifier
                .clip(RoundedCornerShape(50))
                .background(
                    if (isSelected) Color.White.copy(alpha = 0.2f)
                    else color.copy(alpha = if (isDark) 0.2f else 0.12f)
                )
                .padding(horizontal = 8.dp, vertical = 3.dp)
        )
    }
}

// ──────────────────────────────────────────────────────────────
// Holding Analysis Card
// ──────────────────────────────────────────────────────────────

@Composable
private fun HoldingAnalysisCard(
    holding: HoldingAnalysis,
    onClick: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.large)

    val borderBrush = if (isDark) {
        Brush.linearGradient(
            listOf(GlassBorderStartDark, GlassBorderMidDark, GlassBorderEndDark)
        )
    } else {
        Brush.linearGradient(
            listOf(GlassBorderStartLight, GlassBorderMidLight, GlassBorderEndLight)
        )
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (!isDark) Modifier.shadow(
                    elevation = 8.dp,
                    shape = shape,
                    spotColor = ShadowColor,
                    ambientColor = ShadowColor
                ) else Modifier
            )
            .clip(shape)
            .background(if (isDark) CardBackgroundDark else CardBackgroundLight)
            .border(width = 1.dp, brush = borderBrush, shape = shape)
            .clickable { onClick() }
            .padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        // Header Row
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.Top
        ) {
            // Status icon in colored square
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(CornerRadius.small))
                    .background(holding.statusColor.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                StatusArrowIcon(status = holding.status, sizeDp = 18)
            }

            Spacer(modifier = Modifier.width(Spacing.compact))

            // Fund name + category
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(3.dp)
            ) {
                Text(
                    text = holding.fundName,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Normal,
                    color = MaterialTheme.colorScheme.onSurface,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = holding.fundCategory,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Light,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            Spacer(modifier = Modifier.width(Spacing.small))

            // Status badge capsule
            StatusBadge(status = holding.status)
        }

        // Values Row
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            ValueColumn(label = "Invested", value = formatCurrency(holding.investedValue))
            ValueColumn(
                label = "Current",
                value = formatCurrency(holding.currentValue),
                alignment = Alignment.CenterHorizontally
            )
            ValueColumn(
                label = "Returns",
                value = formatPercent(holding.absoluteGainPercent),
                valueColor = if (holding.absoluteGainPercent >= 0) Success else Color(0xFFEF4444),
                alignment = Alignment.End
            )
        }

        // Score Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(
                text = "Score",
                fontSize = 11.sp,
                fontWeight = FontWeight.Light,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            LinearProgressIndicator(
                progress = { (holding.scores.overallScore / 100f).toFloat() },
                modifier = Modifier
                    .weight(1f)
                    .height(6.dp)
                    .clip(RoundedCornerShape(3.dp)),
                color = holding.statusColor,
                trackColor = holding.statusColor.copy(alpha = 0.2f)
            )
            Text(
                text = "${holding.scores.overallScore.toInt()}",
                fontSize = 13.sp,
                fontWeight = FontWeight.Normal,
                color = holding.statusColor,
                modifier = Modifier.width(28.dp),
                textAlign = TextAlign.End
            )
        }

        // Action Hint
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "\uD83D\uDCA1",  // lightbulb emoji as fallback
                fontSize = 11.sp,
                color = holding.statusColor
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = holding.actionHint,
                fontSize = 12.sp,
                fontWeight = FontWeight.Light,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.weight(1f)
            )
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f),
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

@Composable
private fun ValueColumn(
    label: String,
    value: String,
    valueColor: Color = MaterialTheme.colorScheme.onSurface,
    alignment: Alignment.Horizontal = Alignment.Start
) {
    Column(
        horizontalAlignment = alignment,
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = FontWeight.Light,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            fontSize = 15.sp,
            fontWeight = FontWeight.Light,
            color = valueColor
        )
    }
}

// ──────────────────────────────────────────────────────────────
// Status Badge (capsule)
// ──────────────────────────────────────────────────────────────

@Composable
private fun StatusBadge(status: FundHealthStatus) {
    val isDark = LocalIsDarkTheme.current
    val bgAlpha = if (isDark) 0.2f else 0.12f

    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(50))
            .background(status.statusColor.copy(alpha = bgAlpha))
            .padding(horizontal = 10.dp, vertical = 5.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        StatusArrowIcon(status = status, sizeDp = 10)
        Text(
            text = status.label,
            fontSize = 11.sp,
            fontWeight = FontWeight.Normal,
            color = status.statusColor
        )
    }
}

// ──────────────────────────────────────────────────────────────
// Recommendations Card
// ──────────────────────────────────────────────────────────────

@Composable
private fun RecommendationsCard(recommendations: List<String>) {
    GlassCard {
        Column(
            verticalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            // Header
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "\uD83D\uDCA1",  // lightbulb
                    fontSize = 20.sp
                )
                Text(
                    text = "Recommendations",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Normal,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            // Bulleted list
            recommendations.forEach { recommendation ->
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .padding(top = 7.dp)
                            .size(6.dp)
                            .clip(CircleShape)
                            .background(Warning)
                    )
                    Text(
                        text = recommendation,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Light,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        lineHeight = 20.sp
                    )
                }
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Holding Analysis Detail Sheet
// ──────────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HoldingAnalysisDetailSheet(
    holding: HoldingAnalysis,
    onDismiss: () -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    val scope = rememberCoroutineScope()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = if (LocalIsDarkTheme.current) Color(0xFF0F172A) else MaterialTheme.colorScheme.surface,
        dragHandle = {
            Box(
                modifier = Modifier
                    .padding(top = 12.dp, bottom = 8.dp)
                    .width(40.dp)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f))
            )
        }
    ) {
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            // Header
            item {
                DetailSheetHeader(holding = holding)
            }

            // Score Breakdown
            item {
                ScoreBreakdownCard(scores = holding.scores, statusColor = holding.statusColor)
            }

            // Insights
            item {
                InsightsCard(insights = holding.insights, statusColor = holding.statusColor)
            }

            // Investment Summary
            item {
                InvestmentSummaryCard(holding = holding)
            }

            // Bottom spacing
            item {
                Spacer(modifier = Modifier.height(Spacing.xxLarge))
            }
        }
    }
}

@Composable
private fun DetailSheetHeader(holding: HoldingAnalysis) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = Spacing.medium),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(Spacing.small)
    ) {
        // Status icon circle
        Box(
            modifier = Modifier
                .size(64.dp)
                .clip(CircleShape)
                .background(holding.statusColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            StatusArrowIcon(status = holding.status, sizeDp = 28)
        }

        Text(
            text = holding.fundName,
            fontSize = 18.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface,
            textAlign = TextAlign.Center
        )

        Text(
            text = holding.fundCategory,
            fontSize = 14.sp,
            fontWeight = FontWeight.Normal,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        StatusBadge(status = holding.status)
    }
}

// ──────────────────────────────────────────────────────────────
// Score Breakdown Card (detail sheet)
// ──────────────────────────────────────────────────────────────

@Composable
private fun ScoreBreakdownCard(scores: HoldingScores, statusColor: Color) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.medium)
    val bgColor = if (isDark) Color.White.copy(alpha = 0.06f)
    else MaterialTheme.colorScheme.surfaceVariant

    val scoreItems = listOf(
        Triple("Returns", scores.returnsScore, "40%"),
        Triple("Risk-Adjusted", scores.riskScore, "25%"),
        Triple("Consistency", scores.consistencyScore, "20%"),
        Triple("Momentum", scores.momentumScore, "15%")
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(bgColor)
            .then(
                if (isDark) Modifier.border(
                    width = 0.5.dp,
                    color = Color.White.copy(alpha = 0.08f),
                    shape = shape
                ) else Modifier
            )
            .padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Text(
            text = "Score Breakdown",
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )

        scoreItems.forEach { (label, score, weight) ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = label,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Normal,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.width(90.dp)
                )

                // Weight badge
                Text(
                    text = weight,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f),
                    modifier = Modifier
                        .clip(RoundedCornerShape(50))
                        .background(MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.1f))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )

                Spacer(modifier = Modifier.weight(1f))

                // Progress bar
                LinearProgressIndicator(
                    progress = { (score / 100f).toFloat() },
                    modifier = Modifier
                        .width(80.dp)
                        .height(6.dp)
                        .clip(RoundedCornerShape(3.dp)),
                    color = statusColor,
                    trackColor = statusColor.copy(alpha = 0.2f)
                )

                Text(
                    text = "${score.toInt()}",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = statusColor,
                    modifier = Modifier.width(28.dp),
                    textAlign = TextAlign.End
                )
            }
        }

        Divider(
            modifier = Modifier.padding(vertical = 4.dp),
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.15f)
        )

        // Overall Score
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "Overall Score",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = "${scores.overallScore.toInt()}",
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = statusColor
            )
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Insights Card (detail sheet)
// ──────────────────────────────────────────────────────────────

@Composable
private fun InsightsCard(insights: List<String>, statusColor: Color) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.medium)
    val bgColor = if (isDark) Color.White.copy(alpha = 0.06f)
    else MaterialTheme.colorScheme.surfaceVariant

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(bgColor)
            .then(
                if (isDark) Modifier.border(
                    width = 0.5.dp,
                    color = Color.White.copy(alpha = 0.08f),
                    shape = shape
                ) else Modifier
            )
            .padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Text(
            text = "Key Insights",
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )

        insights.forEach { insight ->
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.Top
            ) {
                Text(
                    text = "\u2713",  // checkmark
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = statusColor,
                    modifier = Modifier.padding(top = 1.dp)
                )
                Text(
                    text = insight,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Normal,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    lineHeight = 18.sp
                )
            }
        }
    }
}

// ──────────────────────────────────────────────────────────────
// Investment Summary Card (detail sheet)
// ──────────────────────────────────────────────────────────────

@Composable
private fun InvestmentSummaryCard(holding: HoldingAnalysis) {
    val isDark = LocalIsDarkTheme.current
    val shape = RoundedCornerShape(CornerRadius.medium)
    val bgColor = if (isDark) Color.White.copy(alpha = 0.06f)
    else MaterialTheme.colorScheme.surfaceVariant

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(shape)
            .background(bgColor)
            .then(
                if (isDark) Modifier.border(
                    width = 0.5.dp,
                    color = Color.White.copy(alpha = 0.08f),
                    shape = shape
                ) else Modifier
            )
            .padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Text(
            text = "Investment Summary",
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            SummaryValueItem(
                label = "Invested",
                value = formatCurrency(holding.investedValue)
            )
            SummaryValueItem(
                label = "Current",
                value = formatCurrency(holding.currentValue),
                alignment = Alignment.CenterHorizontally
            )
            SummaryValueItem(
                label = "Returns",
                value = formatPercent(holding.absoluteGainPercent),
                valueColor = if (holding.absoluteGainPercent >= 0) Success else Color(0xFFEF4444),
                alignment = Alignment.End
            )
        }
    }
}

@Composable
private fun SummaryValueItem(
    label: String,
    value: String,
    valueColor: Color = MaterialTheme.colorScheme.onSurface,
    alignment: Alignment.Horizontal = Alignment.Start
) {
    Column(
        horizontalAlignment = alignment,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = label,
            fontSize = 11.sp,
            fontWeight = FontWeight.Normal,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            fontSize = 15.sp,
            fontWeight = FontWeight.SemiBold,
            color = valueColor
        )
    }
}
