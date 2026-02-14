package com.sparrowinvest.fa.data.repository

import com.sparrowinvest.fa.core.network.ApiResult
import com.sparrowinvest.fa.core.network.ApiService
import com.sparrowinvest.fa.data.model.BulkSendRequest
import com.sparrowinvest.fa.data.model.BulkSendResult
import com.sparrowinvest.fa.data.model.CommunicationPreview
import com.sparrowinvest.fa.data.model.CommunicationSendResult
import com.sparrowinvest.fa.data.model.CommunicationStats
import com.sparrowinvest.fa.data.model.CommunicationTemplate
import com.sparrowinvest.fa.data.model.PaginatedCommunicationResponse
import com.sparrowinvest.fa.data.model.PreviewCommunicationRequest
import com.sparrowinvest.fa.data.model.SendCommunicationRequest
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CommunicationRepository @Inject constructor(
    private val apiService: ApiService
) {

    suspend fun getTemplates(): ApiResult<List<CommunicationTemplate>> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getCommunicationTemplates()
            if (response.isSuccessful) {
                ApiResult.success(response.body() ?: emptyList())
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to fetch templates",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }

    suspend fun preview(request: PreviewCommunicationRequest): ApiResult<CommunicationPreview> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.previewCommunication(request)
            if (response.isSuccessful) {
                response.body()?.let { preview ->
                    ApiResult.success(preview)
                } ?: ApiResult.error("Empty response")
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to preview communication",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }

    suspend fun send(request: SendCommunicationRequest): ApiResult<CommunicationSendResult> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.sendCommunication(request)
            if (response.isSuccessful) {
                response.body()?.let { result ->
                    ApiResult.success(result)
                } ?: ApiResult.error("Empty response")
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to send communication",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }

    suspend fun getHistory(
        clientId: String? = null,
        channel: String? = null,
        type: String? = null,
        page: Int? = null,
        limit: Int? = null
    ): ApiResult<PaginatedCommunicationResponse> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getCommunicationHistory(clientId, channel, type, page, limit)
            if (response.isSuccessful) {
                response.body()?.let { result ->
                    ApiResult.success(result)
                } ?: ApiResult.error("Empty response")
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to fetch history",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }

    suspend fun getStats(): ApiResult<CommunicationStats> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.getCommunicationStats()
            if (response.isSuccessful) {
                response.body()?.let { result ->
                    ApiResult.success(result)
                } ?: ApiResult.error("Empty response")
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to fetch stats",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }

    suspend fun sendBulk(request: BulkSendRequest): ApiResult<BulkSendResult> = withContext(Dispatchers.IO) {
        try {
            val response = apiService.sendBulkCommunication(request)
            if (response.isSuccessful) {
                response.body()?.let { result ->
                    ApiResult.success(result)
                } ?: ApiResult.error("Empty response")
            } else {
                ApiResult.error(
                    response.errorBody()?.string() ?: "Failed to send bulk communication",
                    response.code()
                )
            }
        } catch (e: Exception) {
            ApiResult.error(e.message ?: "Network error", exception = e)
        }
    }
}
