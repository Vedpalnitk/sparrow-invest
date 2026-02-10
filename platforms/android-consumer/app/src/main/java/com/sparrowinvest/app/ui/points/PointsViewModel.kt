package com.sparrowinvest.app.ui.points

import androidx.lifecycle.ViewModel
import com.sparrowinvest.app.data.model.PointsData
import com.sparrowinvest.app.data.model.RewardTier
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.text.NumberFormat
import java.util.Locale
import javax.inject.Inject

@HiltViewModel
class PointsViewModel @Inject constructor() : ViewModel() {

    private val _points = MutableStateFlow(
        PointsData(
            totalPoints = 2450,
            tier = RewardTier.GOLD,
            lifetimePoints = 5200,
            expiringPoints = 350,
            expiryDate = "Apr 9, 2026"
        )
    )
    val points: StateFlow<PointsData> = _points.asStateFlow()

    private val numberFormat = NumberFormat.getNumberInstance(Locale("en", "IN"))

    // Computed properties matching iOS PointsStore

    val pointsToNextTier: Int
        get() {
            val data = _points.value
            val nextTier = data.tier.nextTier ?: return 0
            return maxOf(0, nextTier.minPoints - data.totalPoints)
        }

    val progressToNextTier: Float
        get() {
            val data = _points.value
            val nextTier = data.tier.nextTier ?: return 1.0f
            val currentTierMin = data.tier.minPoints
            val nextTierMin = nextTier.minPoints
            val range = nextTierMin - currentTierMin
            val progress = data.totalPoints - currentTierMin
            return (progress.toFloat() / range.toFloat()).coerceIn(0f, 1f)
        }

    val formattedTotalPoints: String
        get() = numberFormat.format(_points.value.totalPoints)

    val formattedLifetimePoints: String
        get() = numberFormat.format(_points.value.lifetimePoints)

    val formattedExpiringPoints: String
        get() = numberFormat.format(_points.value.expiringPoints)
}
