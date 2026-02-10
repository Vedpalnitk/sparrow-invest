package com.sparrowinvest.app.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.sparrowinvest.app.data.model.HistoryPeriod
import com.sparrowinvest.app.data.model.PortfolioHistory
import com.sparrowinvest.app.data.model.PortfolioHistoryPoint
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.GradientEndCyan
import com.sparrowinvest.app.ui.theme.GradientStartBlue
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.PrimaryLight
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.Error
import java.util.Locale

@Composable
fun PortfolioGrowthChart(
    history: PortfolioHistory,
    selectedPeriod: HistoryPeriod,
    onPeriodChange: (HistoryPeriod) -> Unit,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
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

    var selectedPoint by remember { mutableStateOf<PortfolioHistoryPoint?>(null) }

    Column(
        modifier = modifier
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
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Portfolio Growth",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )

                Spacer(modifier = Modifier.height(4.dp))

                if (selectedPoint != null) {
                    val point = selectedPoint!!
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CurrencyText(
                            amount = point.value,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurface,
                            compact = true
                        )
                        Spacer(modifier = Modifier.width(Spacing.small))
                        Text(
                            text = String.format(Locale.US, "%+.1f%%", point.returnsPercentage),
                            style = MaterialTheme.typography.labelSmall,
                            color = if (point.returns >= 0) Success else Error
                        )
                    }
                } else if (history.dataPoints.isNotEmpty()) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = String.format(Locale.US, "%+.1f%%", history.periodReturn),
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (history.periodReturn >= 0) Success else Error
                        )
                        Spacer(modifier = Modifier.width(Spacing.small))
                        Text(
                            text = "in ${selectedPeriod.label}",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.compact))

        // Period Selector
        PeriodSelector(
            selectedPeriod = selectedPeriod,
            onPeriodChange = {
                selectedPoint = null
                onPeriodChange(it)
            }
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        // Chart
        if (history.dataPoints.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "No data available",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            GrowthLineChart(
                history = history,
                selectedPoint = selectedPoint,
                onPointSelected = { selectedPoint = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(180.dp)
            )
        }
    }
}

@Composable
private fun PeriodSelector(
    selectedPeriod: HistoryPeriod,
    onPeriodChange: (HistoryPeriod) -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    val selectorBg = if (isDark) Color.White.copy(alpha = 0.06f) else Color.Black.copy(alpha = 0.04f)

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(50))
            .background(selectorBg)
            .padding(4.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        HistoryPeriod.entries.forEach { period ->
            val isSelected = period == selectedPeriod
            val bgColor = if (isSelected) {
                Brush.linearGradient(listOf(GradientStartBlue, GradientEndCyan))
            } else {
                Brush.linearGradient(listOf(Color.Transparent, Color.Transparent))
            }
            val textColor = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurfaceVariant

            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(50))
                    .background(bgColor)
                    .clickable { onPeriodChange(period) }
                    .padding(vertical = 8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = period.label,
                    style = MaterialTheme.typography.labelSmall,
                    color = textColor
                )
            }
        }
    }
}

@Composable
private fun GrowthLineChart(
    history: PortfolioHistory,
    selectedPoint: PortfolioHistoryPoint?,
    onPointSelected: (PortfolioHistoryPoint?) -> Unit,
    modifier: Modifier = Modifier
) {
    val isDark = LocalIsDarkTheme.current
    val lineColor = if (isDark) PrimaryLight else Primary
    val fillColorTop = lineColor.copy(alpha = 0.3f)
    val fillColorBottom = lineColor.copy(alpha = 0.02f)
    val gridColor = if (isDark) Color.White.copy(alpha = 0.06f) else Color.Black.copy(alpha = 0.06f)
    val labelColor = if (isDark) Color.White.copy(alpha = 0.4f) else Color.Black.copy(alpha = 0.4f)

    val dataPoints = history.dataPoints
    val minVal = history.minValue * 0.95
    val maxVal = history.maxValue * 1.05
    val range = maxVal - minVal

    var animationPlayed by remember { mutableStateOf(false) }
    val animatedProgress by animateFloatAsState(
        targetValue = if (animationPlayed) 1f else 0f,
        animationSpec = tween(durationMillis = 800),
        label = "chartAnimation"
    )

    LaunchedEffect(dataPoints) {
        animationPlayed = false
        animationPlayed = true
    }

    Canvas(
        modifier = modifier
            .pointerInput(dataPoints) {
                detectTapGestures { offset ->
                    val pointIndex = findClosestPointIndex(offset.x, size.width.toFloat(), dataPoints.size)
                    onPointSelected(dataPoints.getOrNull(pointIndex))
                }
            }
            .pointerInput(dataPoints) {
                detectHorizontalDragGestures(
                    onDragEnd = { onPointSelected(null) },
                    onHorizontalDrag = { _, _ -> }
                )
            }
    ) {
        val width = size.width
        val height = size.height
        val chartPadding = 0f

        if (dataPoints.size < 2 || range <= 0) return@Canvas

        // Draw horizontal grid lines
        val gridLineCount = 4
        for (i in 0..gridLineCount) {
            val y = height - (height * i / gridLineCount)
            drawLine(
                color = gridColor,
                start = Offset(chartPadding, y),
                end = Offset(width - chartPadding, y),
                strokeWidth = 1f
            )
        }

        // Build line path
        val linePath = Path()
        val fillPath = Path()
        val stepX = (width - chartPadding * 2) / (dataPoints.size - 1)

        dataPoints.forEachIndexed { index, point ->
            val x = chartPadding + index * stepX
            val normalizedY = ((point.value - minVal) / range).toFloat().coerceIn(0f, 1f)
            val y = height - (normalizedY * height * animatedProgress)

            if (index == 0) {
                linePath.moveTo(x, y)
                fillPath.moveTo(x, height)
                fillPath.lineTo(x, y)
            } else {
                // Smooth curve using cubic bezier
                val prevX = chartPadding + (index - 1) * stepX
                val prevPoint = dataPoints[index - 1]
                val prevNormalizedY = ((prevPoint.value - minVal) / range).toFloat().coerceIn(0f, 1f)
                val prevY = height - (prevNormalizedY * height * animatedProgress)

                val controlX1 = prevX + stepX * 0.4f
                val controlX2 = x - stepX * 0.4f

                linePath.cubicTo(controlX1, prevY, controlX2, y, x, y)
                fillPath.cubicTo(controlX1, prevY, controlX2, y, x, y)
            }
        }

        // Close fill path
        fillPath.lineTo(chartPadding + (dataPoints.size - 1) * stepX, height)
        fillPath.close()

        // Draw gradient fill
        drawPath(
            path = fillPath,
            brush = Brush.verticalGradient(
                colors = listOf(fillColorTop, fillColorBottom),
                startY = 0f,
                endY = height
            )
        )

        // Draw line
        drawPath(
            path = linePath,
            color = lineColor,
            style = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round)
        )

        // Draw selected point indicator
        selectedPoint?.let { point ->
            val idx = dataPoints.indexOf(point)
            if (idx >= 0) {
                val x = chartPadding + idx * stepX
                val normalizedY = ((point.value - minVal) / range).toFloat().coerceIn(0f, 1f)
                val y = height - (normalizedY * height * animatedProgress)

                // Vertical dashed line
                drawLine(
                    color = lineColor.copy(alpha = 0.3f),
                    start = Offset(x, 0f),
                    end = Offset(x, height),
                    strokeWidth = 1.dp.toPx(),
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(8f, 8f))
                )

                // Outer glow
                drawCircle(
                    color = lineColor.copy(alpha = 0.2f),
                    radius = 10.dp.toPx(),
                    center = Offset(x, y)
                )

                // Point dot
                drawCircle(
                    color = lineColor,
                    radius = 5.dp.toPx(),
                    center = Offset(x, y)
                )

                // Inner white dot
                drawCircle(
                    color = Color.White,
                    radius = 2.5.dp.toPx(),
                    center = Offset(x, y)
                )
            }
        }
    }
}

private fun findClosestPointIndex(touchX: Float, width: Float, pointCount: Int): Int {
    if (pointCount <= 1) return 0
    val stepX = width / (pointCount - 1)
    return ((touchX / stepX).toInt()).coerceIn(0, pointCount - 1)
}
