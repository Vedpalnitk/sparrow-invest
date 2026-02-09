package com.sparrowinvest.fa.data.repository

import com.sparrowinvest.fa.core.network.ApiResult
import com.sparrowinvest.fa.core.network.ApiService
import com.sparrowinvest.fa.data.model.NotificationLogsResponse
import com.sparrowinvest.fa.data.model.NotificationPreferences
import com.sparrowinvest.fa.data.model.PreferenceUpdate
import com.sparrowinvest.fa.data.model.UpdatePreferencesRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationRepository @Inject constructor(
    private val apiService: ApiService
) {

    suspend fun getPreferences(): ApiResult<NotificationPreferences> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getNotificationPreferences()
            if (response.isSuccessful) {
                response.body()?.let { prefs ->
                    ApiResult.success(prefs)
                } ?: ApiResult.success(emptyMap())
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to fetch notification preferences",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }

    suspend fun updatePreferences(updates: List<PreferenceUpdate>): ApiResult<NotificationPreferences> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.updateNotificationPreferences(
                UpdatePreferencesRequest(updates = updates)
            )
            if (response.isSuccessful) {
                response.body()?.let { prefs ->
                    ApiResult.success(prefs)
                } ?: ApiResult.error("Empty response")
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to update preferences",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }

    suspend fun getLogs(limit: Int = 50, offset: Int = 0): ApiResult<NotificationLogsResponse> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getNotificationLogs(limit, offset)
            if (response.isSuccessful) {
                response.body()?.let { logs ->
                    ApiResult.success(logs)
                } ?: ApiResult.error("Empty response")
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to fetch notification logs",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }
}
