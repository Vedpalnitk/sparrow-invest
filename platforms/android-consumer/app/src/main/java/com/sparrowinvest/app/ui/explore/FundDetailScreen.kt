package com.sparrowinvest.app.ui.explore

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sparrowinvest.app.data.model.FundCategory
import com.sparrowinvest.app.data.model.FundDetail
import com.sparrowinvest.app.ui.components.CurrencyText
import com.sparrowinvest.app.ui.components.FullScreenLoading
import com.sparrowinvest.app.ui.components.GlassCard
import com.sparrowinvest.app.ui.components.PrimaryButton
import com.sparrowinvest.app.ui.components.ReturnText
import com.sparrowinvest.app.ui.components.SecondaryButton
import com.sparrowinvest.app.ui.components.SectionHeader
import com.sparrowinvest.app.ui.components.TopBar
import com.sparrowinvest.app.ui.components.formatCompactCurrency
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.ManropeFontFamily
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import java.util.Locale
import kotlin.math.max
import kotlin.math.sin

@Composable
fun FundDetailScreen(
    schemeCode: Int,
    viewModel: FundDetailViewModel = hiltViewModel(),
    onBackClick: () -> Unit,
    onNavigateToBroker: (String, Int) -> Unit = { _, _ -> }
) {
    val uiState by viewModel.uiState.collectAsState()
    val fundDetail by viewModel.fundDetail.collectAsState()
    val isInWatchlist by viewModel.isInWatchlist.collectAsState()
    val selectedPeriod by viewModel.selectedPeriod.collectAsState()

    LaunchedEffect(schemeCode) {
        viewModel.loadFundDetails(schemeCode)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .statusBarsPadding()
    ) {
        TopBar(
            title = "",
            onBackClick = onBackClick,
            actions = {
                IconButton(onClick = { viewModel.toggleWatchlist() }) {
                    Icon(
                        imageVector = if (isInWatchlist) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                        contentDescription = if (isInWatchlist) "Remove from watchlist" else "Add to watchlist",
                        tint = if (isInWatchlist) Color(0xFFEF4444) else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        )

        when (uiState) {
            is FundDetailUiState.Loading -> {
                FullScreenLoading()
            }
            is FundDetailUiState.Success -> {
                fundDetail?.let { fund ->
                    FundDetailContent(
                        fund = fund,
                        selectedPeriod = selectedPeriod,
                        onPeriodSelected = { viewModel.setSelectedPeriod(it) },
                        getReturnForPeriod = { period -> viewModel.getReturnForPeriod(fund, period) },
                        onNavigateToBroker = onNavigateToBroker
                    )
                }
            }
            is FundDetailUiState.Error -> {
                // Error state
            }
        }
    }
}

@Composable
private fun FundDetailContent(
    fund: FundDetail,
    selectedPeriod: String,
    onPeriodSelected: (String) -> Unit,
    getReturnForPeriod: (String) -> Double?,
    onNavigateToBroker: (String, Int) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = Spacing.medium)
    ) {
        // Fund Header
        FundHeader(fund = fund)

        Spacer(modifier = Modifier.height(Spacing.large))

        // NAV Card
        NavCard(fund = fund)

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Period Selector
        PeriodSelector(
            selectedPeriod = selectedPeriod,
            onPeriodSelected = onPeriodSelected
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Growth Chart
        GrowthChart(
            returnPercent = getReturnForPeriod(selectedPeriod) ?: 0.0,
            period = selectedPeriod
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Returns
        SectionHeader(title = "Returns")
        ReturnsCard(fund = fund)

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Fund Info
        SectionHeader(title = "Fund Information")
        FundInfoCard(fund = fund)

        Spacer(modifier = Modifier.height(Spacing.large))

        // Action Buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(Spacing.medium)
        ) {
            SecondaryButton(
                text = "Start SIP",
                onClick = { onNavigateToBroker(fund.schemeName, fund.schemeCode) },
                modifier = Modifier.weight(1f)
            )
            PrimaryButton(
                text = "Invest Now",
                onClick = { onNavigateToBroker(fund.schemeName, fund.schemeCode) },
                modifier = Modifier.weight(1f)
            )
        }

        Spacer(modifier = Modifier.height(Spacing.large))
    }
}

// -- Period Selector --

private val periods = listOf("1M", "3M", "6M", "1Y", "3Y", "5Y")

@Composable
private fun PeriodSelector(
    selectedPeriod: String,
    onPeriodSelected: (String) -> Unit
) {
    GlassCard(
        contentPadding = Spacing.small
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            periods.forEach { period ->
                val isSelected = period == selectedPeriod
                val shape = RoundedCornerShape(CornerRadius.medium)

                Box(
                    modifier = Modifier
                        .clip(shape)
                        .then(
                            if (isSelected) {
                                Modifier.background(
                                    brush = Brush.linearGradient(
                                        colors = listOf(Primary, Secondary)
                                    )
                                )
                            } else {
                                Modifier
                            }
                        )
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null
                        ) { onPeriodSelected(period) }
                        .padding(horizontal = Spacing.compact, vertical = Spacing.small),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = period,
                        style = MaterialTheme.typography.labelMedium.copy(
                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Medium
                        ),
                        color = if (isSelected) Color.White
                        else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

// -- Growth Chart --

private data class ChartPoint(val x: Float, val y: Float, val value: Double)

private fun generateChartData(
    baseValue: Double,
    returnPercent: Double,
    pointCount: Int = 60,
    volatility: Double = 0.02
): List<ChartPoint> {
    val finalValue = baseValue * (1 + returnPercent / 100.0)
    val points = mutableListOf<ChartPoint>()

    for (i in 0 until pointCount) {
        val progress = i.toDouble() / (pointCount - 1).toDouble()
        val baseGrowth = baseValue + (finalValue - baseValue) * progress
        val noise = sin(i * 0.5) * baseGrowth * volatility * (1.0 - progress * 0.5)
        val value = max(baseGrowth + noise, baseValue * 0.8)
        points.add(
            ChartPoint(
                x = progress.toFloat(),
                y = 0f, // Will be computed during drawing
                value = value
            )
        )
    }
    return points
}

@Composable
private fun GrowthChart(
    returnPercent: Double,
    period: String
) {
    val baseValue = 10000.0
    val chartData = remember(returnPercent, period) {
        generateChartData(baseValue, returnPercent)
    }

    val isPositive = returnPercent >= 0
    val chartColor = if (isPositive) Success else Error

    val animationProgress = remember { Animatable(0f) }
    LaunchedEffect(returnPercent, period) {
        animationProgress.snapTo(0f)
        animationProgress.animateTo(
            targetValue = 1f,
            animationSpec = tween(durationMillis = 800)
        )
    }

    val finalValue = baseValue * (1 + returnPercent / 100.0)
    val isDark = LocalIsDarkTheme.current

    val textMeasurer = rememberTextMeasurer()

    // Touch state
    var touchX by remember { mutableStateOf<Float?>(null) }
    var selectedPoint by remember { mutableStateOf<ChartPoint?>(null) }

    GlassCard {
        Column {
            // Header row: label + value + return badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column {
                    Text(
                        text = "Growth of \u20B910,000",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = formatCompactCurrency(selectedPoint?.value ?: finalValue),
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                // Return badge
                val badgeColor = if (isPositive) Success else Error
                val arrowStr = if (isPositive) "\u2191" else "\u2193"
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(CornerRadius.small))
                        .background(badgeColor.copy(alpha = 0.15f))
                        .padding(horizontal = Spacing.small, vertical = Spacing.micro)
                ) {
                    Text(
                        text = "$arrowStr ${String.format(Locale.US, "%.2f", returnPercent)}%",
                        style = MaterialTheme.typography.labelMedium.copy(
                            fontWeight = FontWeight.SemiBold
                        ),
                        color = badgeColor
                    )
                }
            }

            Spacer(modifier = Modifier.height(Spacing.medium))

            // Chart Canvas
            val minValue = chartData.minOf { it.value }
            val maxValue = chartData.maxOf { it.value }
            val valueRange = if (maxValue - minValue < 1.0) 1.0 else maxValue - minValue

            val labelStyle = TextStyle(
                fontFamily = ManropeFontFamily,
                fontWeight = FontWeight.Normal,
                fontSize = 10.sp,
                color = if (isDark) Color(0xFF9CA3AF) else Color(0xFF6B7280)
            )

            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
                    .pointerInput(chartData) {
                        awaitPointerEventScope {
                            while (true) {
                                val event = awaitPointerEvent()
                                val position = event.changes.firstOrNull()?.position
                                if (position != null) {
                                    val chartLeft = 48f
                                    val chartRight = size.width.toFloat() - 16f
                                    val chartWidth = chartRight - chartLeft
                                    if (position.x in chartLeft..chartRight && chartData.isNotEmpty()) {
                                        val normalizedX = ((position.x - chartLeft) / chartWidth).coerceIn(0f, 1f)
                                        val index = (normalizedX * (chartData.size - 1)).toInt()
                                            .coerceIn(0, chartData.size - 1)
                                        touchX = position.x
                                        selectedPoint = chartData[index]
                                    }
                                }
                                // Consume to prevent scroll
                                event.changes.forEach { it.consume() }
                            }
                        }
                    }
            ) {
                val chartLeft = 48.dp.toPx()
                val chartRight = size.width - 16.dp.toPx()
                val chartTop = 8.dp.toPx()
                val chartBottom = size.height - 24.dp.toPx()
                val chartWidth = chartRight - chartLeft
                val chartHeight = chartBottom - chartTop

                val currentProgress = animationProgress.value

                // Draw Y-axis labels (4 evenly spaced)
                for (i in 0..3) {
                    val labelValue = minValue + valueRange * (1.0 - i.toDouble() / 3.0)
                    val y = chartTop + chartHeight * (i.toFloat() / 3f)
                    val labelText = formatCompactCurrency(labelValue)
                    val measuredText = textMeasurer.measure(labelText, labelStyle)
                    drawText(
                        textLayoutResult = measuredText,
                        topLeft = Offset(0f, y - measuredText.size.height / 2f)
                    )
                    // Subtle grid line
                    drawLine(
                        color = if (isDark) Color.White.copy(alpha = 0.06f)
                        else Color.Black.copy(alpha = 0.06f),
                        start = Offset(chartLeft, y),
                        end = Offset(chartRight, y),
                        strokeWidth = 1f
                    )
                }

                // Draw X-axis labels (4 evenly spaced)
                val xLabels = getXAxisLabels(period)
                for (i in xLabels.indices) {
                    val x = chartLeft + chartWidth * (i.toFloat() / (xLabels.size - 1).toFloat())
                    val measuredText = textMeasurer.measure(xLabels[i], labelStyle)
                    drawText(
                        textLayoutResult = measuredText,
                        topLeft = Offset(
                            x - measuredText.size.width / 2f,
                            chartBottom + 4.dp.toPx()
                        )
                    )
                }

                if (chartData.isEmpty()) return@Canvas

                // Build the line path
                val linePath = Path()
                val areaPath = Path()
                var firstPoint = true

                val visibleCount = (chartData.size * currentProgress).toInt().coerceAtLeast(2)

                for (i in 0 until visibleCount) {
                    val point = chartData[i]
                    val x = chartLeft + point.x * chartWidth
                    val normalizedY = ((point.value - minValue) / valueRange).toFloat()
                    val y = chartBottom - normalizedY * chartHeight

                    if (firstPoint) {
                        linePath.moveTo(x, y)
                        areaPath.moveTo(x, chartBottom)
                        areaPath.lineTo(x, y)
                        firstPoint = false
                    } else {
                        linePath.lineTo(x, y)
                        areaPath.lineTo(x, y)
                    }
                }

                // Close area path
                val lastVisiblePoint = chartData[visibleCount - 1]
                val lastX = chartLeft + lastVisiblePoint.x * chartWidth
                areaPath.lineTo(lastX, chartBottom)
                areaPath.close()

                // Draw area fill
                drawPath(
                    path = areaPath,
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            chartColor.copy(alpha = 0.3f),
                            chartColor.copy(alpha = 0.0f)
                        ),
                        startY = chartTop,
                        endY = chartBottom
                    )
                )

                // Draw line
                drawPath(
                    path = linePath,
                    color = chartColor,
                    style = Stroke(
                        width = 3f,
                        cap = StrokeCap.Round
                    )
                )

                // Draw touch indicator
                touchX?.let { tx ->
                    selectedPoint?.let { sp ->
                        val spX = chartLeft + sp.x * chartWidth
                        val normalizedY = ((sp.value - minValue) / valueRange).toFloat()
                        val spY = chartBottom - normalizedY * chartHeight

                        // Vertical dashed line
                        drawLine(
                            color = chartColor.copy(alpha = 0.5f),
                            start = Offset(spX, chartTop),
                            end = Offset(spX, chartBottom),
                            strokeWidth = 1.5f,
                            pathEffect = PathEffect.dashPathEffect(
                                floatArrayOf(8f, 6f), 0f
                            )
                        )

                        // Dot
                        drawCircle(
                            color = chartColor,
                            radius = 6f,
                            center = Offset(spX, spY)
                        )
                        drawCircle(
                            color = Color.White,
                            radius = 3f,
                            center = Offset(spX, spY)
                        )
                    }
                }
            }
        }
    }
}

private fun getXAxisLabels(period: String): List<String> {
    return when (period) {
        "1M" -> listOf("Week 1", "Week 2", "Week 3", "Week 4")
        "3M" -> listOf("Month 1", "Month 2", "Month 3", "Now")
        "6M" -> listOf("Month 1", "Month 3", "Month 5", "Now")
        "1Y" -> listOf("Q1", "Q2", "Q3", "Q4")
        "3Y" -> listOf("Year 1", "Year 2", "Year 3", "Now")
        "5Y" -> listOf("Year 1", "Year 2", "Year 3", "Year 5")
        else -> listOf("Start", "", "", "Now")
    }
}

// -- Existing composables --

@Composable
private fun FundHeader(fund: FundDetail) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(RoundedCornerShape(CornerRadius.medium))
                .background(
                    Color(FundCategory.fromString(fund.assetClass).color).copy(alpha = 0.1f)
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = fund.schemeName.take(2).uppercase(),
                style = MaterialTheme.typography.titleMedium,
                color = Color(FundCategory.fromString(fund.assetClass).color)
            )
        }

        Spacer(modifier = Modifier.width(Spacing.medium))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = fund.schemeName,
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )

            Spacer(modifier = Modifier.height(Spacing.small))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(Spacing.small)
            ) {
                Text(
                    text = fund.category,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                fund.riskRating?.let { rating ->
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        repeat(rating.coerceIn(1, 5)) {
                            Icon(
                                imageVector = Icons.Default.Star,
                                contentDescription = null,
                                modifier = Modifier.size(12.dp),
                                tint = Color(0xFFF59E0B)
                            )
                        }
                    }
                }
            }

            fund.fundHouse?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun NavCard(fund: FundDetail) {
    GlassCard {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Current NAV",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                CurrencyText(
                    amount = fund.nav,
                    style = MaterialTheme.typography.headlineSmall
                )
                fund.navDate?.let {
                    Text(
                        text = "as on $it",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "Min SIP",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                CurrencyText(
                    amount = fund.minSip,
                    style = MaterialTheme.typography.titleMedium
                )
            }
        }
    }
}

@Composable
private fun ReturnsCard(fund: FundDetail) {
    GlassCard {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            fund.returns?.let { returns ->
                returns.oneYear?.let {
                    ReturnItem(label = "1Y", value = it)
                }
                returns.threeYear?.let {
                    ReturnItem(label = "3Y", value = it)
                }
                returns.fiveYear?.let {
                    ReturnItem(label = "5Y", value = it)
                }
            }
        }
    }
}

@Composable
private fun ReturnItem(label: String, value: Double) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(4.dp))
        ReturnText(
            value = value,
            style = MaterialTheme.typography.titleMedium
        )
    }
}

@Composable
private fun FundInfoCard(fund: FundDetail) {
    GlassCard {
        Column(verticalArrangement = Arrangement.spacedBy(Spacing.compact)) {
            fund.aum?.let {
                InfoRow(label = "AUM", value = "\u20B9${String.format("%.0f", it / 10000000)} Cr")
            }
            fund.expenseRatio?.let {
                InfoRow(label = "Expense Ratio", value = "${String.format("%.2f", it)}%")
            }
            fund.fundManager?.let {
                InfoRow(label = "Fund Manager", value = it)
            }
            fund.benchmark?.let {
                InfoRow(label = "Benchmark", value = it)
            }
            fund.inceptionDate?.let {
                InfoRow(label = "Inception Date", value = it)
            }
        }
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}
