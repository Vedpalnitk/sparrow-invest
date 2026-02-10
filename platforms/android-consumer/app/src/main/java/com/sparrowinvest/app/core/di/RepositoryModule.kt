package com.sparrowinvest.app.core.di

import com.sparrowinvest.app.core.network.ApiService
import com.sparrowinvest.app.core.storage.PreferencesManager
import com.sparrowinvest.app.core.storage.TokenManager
import com.sparrowinvest.app.data.repository.AdvisorRepository
import com.sparrowinvest.app.data.repository.AuthRepository
import com.sparrowinvest.app.data.repository.FundsRepository
import com.sparrowinvest.app.data.repository.ChatRepository
import com.sparrowinvest.app.data.repository.GoalsRepository
import com.sparrowinvest.app.data.repository.PortfolioRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    @Provides
    @Singleton
    fun provideAuthRepository(
        apiService: ApiService,
        tokenManager: TokenManager,
        preferencesManager: PreferencesManager,
        chatRepository: ChatRepository
    ): AuthRepository {
        return AuthRepository(apiService, tokenManager, preferencesManager, chatRepository)
    }

    @Provides
    @Singleton
    fun provideFundsRepository(
        apiService: ApiService
    ): FundsRepository {
        return FundsRepository(apiService)
    }

    @Provides
    @Singleton
    fun providePortfolioRepository(
        apiService: ApiService
    ): PortfolioRepository {
        return PortfolioRepository(apiService)
    }

    @Provides
    @Singleton
    fun provideGoalsRepository(
        apiService: ApiService
    ): GoalsRepository {
        return GoalsRepository(apiService)
    }

    @Provides
    @Singleton
    fun provideChatRepository(
        apiService: ApiService
    ): ChatRepository {
        return ChatRepository(apiService)
    }

    @Provides
    @Singleton
    fun provideAdvisorRepository(): AdvisorRepository {
        return AdvisorRepository()
    }
}
