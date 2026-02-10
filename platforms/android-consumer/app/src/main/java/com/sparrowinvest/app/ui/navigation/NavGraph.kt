package com.sparrowinvest.app.ui.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.sparrowinvest.app.core.auth.BiometricHelper
import com.sparrowinvest.app.ui.auth.AuthViewModel
import com.sparrowinvest.app.ui.auth.BiometricLoginScreen
import com.sparrowinvest.app.ui.auth.ForgotPasswordScreen
import com.sparrowinvest.app.ui.auth.LoginScreen
import com.sparrowinvest.app.ui.auth.OtpVerificationScreen
import com.sparrowinvest.app.ui.auth.SignupScreen
import com.sparrowinvest.app.ui.auth.WelcomeScreen
import com.sparrowinvest.app.ui.avya.AvyaChatScreen
import com.sparrowinvest.app.ui.components.AvyaFab
import com.sparrowinvest.app.ui.explore.AdvisorDetailScreen
import com.sparrowinvest.app.ui.explore.AdvisorDirectoryScreen
import com.sparrowinvest.app.ui.explore.ExploreScreen
import com.sparrowinvest.app.ui.explore.FundDetailScreen
import com.sparrowinvest.app.ui.explore.MyAdvisorScreen
import com.sparrowinvest.app.ui.goals.GoalDetailScreen
import com.sparrowinvest.app.ui.goals.GoalsScreen
import com.sparrowinvest.app.ui.home.HomeScreen
import com.sparrowinvest.app.ui.insights.InsightsScreen
import com.sparrowinvest.app.ui.invest.BrokerSelectionScreen
import com.sparrowinvest.app.ui.invest.ManualInvestmentScreen
import com.sparrowinvest.app.ui.investments.InvestmentsScreen
import com.sparrowinvest.app.ui.onboarding.RiskAssessmentScreen
import com.sparrowinvest.app.ui.onboarding.RiskResultScreen
import com.sparrowinvest.app.ui.points.PointsScreen
import com.sparrowinvest.app.ui.profile.EditProfileScreen
import com.sparrowinvest.app.ui.profile.KYCStatusScreen
import com.sparrowinvest.app.ui.profile.ProfileScreen
import com.sparrowinvest.app.ui.profile.RiskProfileScreen
import com.sparrowinvest.app.ui.analysis.PortfolioAnalysisScreen
import com.sparrowinvest.app.ui.settings.CacheManagementScreen
import com.sparrowinvest.app.ui.settings.LanguageScreen
import com.sparrowinvest.app.ui.settings.NotificationSettingsScreen
import com.sparrowinvest.app.ui.settings.SecuritySettingsScreen
import com.sparrowinvest.app.ui.settings.SettingsScreen

@Composable
fun NavGraph(
    navController: NavHostController = rememberNavController(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val isAuthenticated by authViewModel.isAuthenticated.collectAsState()
    val hasCompletedOnboarding by authViewModel.hasCompletedOnboarding.collectAsState()
    val currentUser by authViewModel.currentUser.collectAsState()
    val context = LocalContext.current

    // Check if biometric gate should be shown before Home
    val biometricAvailable = remember { BiometricHelper.canAuthenticate(context) }
    val biometricEnabled = remember {
        context.getSharedPreferences("sparrow_prefs", android.content.Context.MODE_PRIVATE)
            .getBoolean("biometric_enabled", false)
    }
    val shouldShowBiometric = isAuthenticated && biometricEnabled && biometricAvailable

    val startDestination = when {
        shouldShowBiometric -> Screen.BiometricLogin.route
        isAuthenticated -> Screen.Home.route
        hasCompletedOnboarding -> Screen.Login.route
        else -> Screen.Welcome.route
    }

    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route

    // Screens that show bottom nav and FAB
    val showBottomNav = currentRoute in listOf(
        Screen.Home.route,
        Screen.Investments.route,
        Screen.Explore.route,
        Screen.Insights.route,
        Screen.Profile.route
    )

    // Show FAB on main screens (except when chat is open)
    val showFab = showBottomNav && currentRoute != Screen.AvyaChat.route

    Scaffold(
        bottomBar = {
            if (showBottomNav) {
                BottomNavBar(
                    currentRoute = currentRoute,
                    onNavigate = { route ->
                        navController.navigate(route) {
                            popUpTo(Screen.Home.route) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }
                )
            }
        },
        floatingActionButton = {
            if (showFab) {
                AvyaFab(
                    onClick = {
                        navController.navigate(Screen.AvyaChat.route)
                    }
                )
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            NavHost(
                navController = navController,
                startDestination = startDestination,
                enterTransition = {
                    slideIntoContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                exitTransition = {
                    slideOutOfContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Left,
                        animationSpec = tween(300)
                    )
                },
                popEnterTransition = {
                    slideIntoContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                },
                popExitTransition = {
                    slideOutOfContainer(
                        towards = AnimatedContentTransitionScope.SlideDirection.Right,
                        animationSpec = tween(300)
                    )
                }
            ) {
                // Auth Flow
                composable(Screen.Welcome.route) {
                    WelcomeScreen(
                        onGetStarted = {
                            authViewModel.setOnboardingCompleted()
                            navController.navigate(Screen.Signup.route) {
                                popUpTo(Screen.Welcome.route) { inclusive = true }
                            }
                        },
                        onLoginClick = {
                            navController.navigate(Screen.Login.route)
                        },
                        onSkip = {
                            authViewModel.continueAsGuest()
                            navController.navigate(Screen.Home.route) {
                                popUpTo(Screen.Welcome.route) { inclusive = true }
                            }
                        }
                    )
                }

                composable(Screen.Login.route) {
                    LoginScreen(
                        viewModel = authViewModel,
                        onLoginSuccess = {
                            if (!authViewModel.hasCompletedOnboarding.value) {
                                navController.navigate(Screen.RiskAssessment.route) {
                                    popUpTo(Screen.Welcome.route) { inclusive = true }
                                }
                            } else {
                                navController.navigate(Screen.Home.route) {
                                    popUpTo(Screen.Welcome.route) { inclusive = true }
                                }
                            }
                        },
                        onSignupClick = {
                            navController.navigate(Screen.Signup.route)
                        },
                        onSkip = {
                            authViewModel.continueAsGuest()
                            navController.navigate(Screen.Home.route) {
                                popUpTo(Screen.Welcome.route) { inclusive = true }
                            }
                        },
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onForgotPasswordClick = {
                            navController.navigate(Screen.ForgotPassword.route)
                        }
                    )
                }

                composable(Screen.Signup.route) {
                    SignupScreen(
                        viewModel = authViewModel,
                        onSignupComplete = {
                            if (!authViewModel.hasCompletedOnboarding.value) {
                                navController.navigate(Screen.RiskAssessment.route) {
                                    popUpTo(Screen.Welcome.route) { inclusive = true }
                                }
                            } else {
                                navController.navigate(Screen.Home.route) {
                                    popUpTo(Screen.Welcome.route) { inclusive = true }
                                }
                            }
                        },
                        onLoginClick = {
                            navController.navigate(Screen.Login.route) {
                                popUpTo(Screen.Signup.route) { inclusive = true }
                            }
                        },
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                composable(
                    route = Screen.OtpVerification.route,
                    arguments = listOf(
                        navArgument(NavArguments.EMAIL) { type = NavType.StringType },
                        navArgument(NavArguments.VERIFICATION_TYPE) { type = NavType.StringType }
                    )
                ) { backStackEntry ->
                    val email = backStackEntry.arguments?.getString(NavArguments.EMAIL) ?: ""
                    val verificationType = backStackEntry.arguments?.getString(NavArguments.VERIFICATION_TYPE) ?: "login"

                    OtpVerificationScreen(
                        email = email,
                        verificationType = verificationType,
                        viewModel = authViewModel,
                        onVerificationSuccess = {
                            navController.navigate(Screen.Home.route) {
                                popUpTo(Screen.Welcome.route) { inclusive = true }
                            }
                        },
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                composable(Screen.ForgotPassword.route) {
                    ForgotPasswordScreen(
                        viewModel = authViewModel,
                        onBackToLogin = {
                            navController.popBackStack()
                        }
                    )
                }

                // Biometric Login Gate
                composable(Screen.BiometricLogin.route) {
                    BiometricLoginScreen(
                        userName = currentUser?.firstName,
                        onAuthSuccess = {
                            navController.navigate(Screen.Home.route) {
                                popUpTo(Screen.BiometricLogin.route) { inclusive = true }
                            }
                        },
                        onUsePassword = {
                            navController.navigate(Screen.Login.route) {
                                popUpTo(Screen.BiometricLogin.route) { inclusive = true }
                            }
                        }
                    )
                }

                // Onboarding Flow
                composable(Screen.RiskAssessment.route) {
                    RiskAssessmentScreen(
                        onComplete = { category, score ->
                            navController.navigate(
                                Screen.RiskResult.createRoute(category, score)
                            ) {
                                popUpTo(Screen.RiskAssessment.route) { inclusive = true }
                            }
                        },
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                composable(
                    route = Screen.RiskResult.route,
                    arguments = listOf(
                        navArgument(NavArguments.RISK_CATEGORY) { type = NavType.StringType },
                        navArgument(NavArguments.RISK_SCORE) { type = NavType.IntType }
                    )
                ) { backStackEntry ->
                    val category = backStackEntry.arguments?.getString(NavArguments.RISK_CATEGORY) ?: "Moderate"
                    val score = backStackEntry.arguments?.getInt(NavArguments.RISK_SCORE) ?: 10

                    RiskResultScreen(
                        category = category,
                        score = score,
                        onContinue = {
                            authViewModel.setOnboardingCompleted()
                            navController.navigate(Screen.Home.route) {
                                popUpTo(Screen.RiskResult.route) { inclusive = true }
                            }
                        }
                    )
                }

                // Main screens
                composable(Screen.Home.route) {
                    HomeScreen(
                        onNavigateToInvestments = {
                            navController.navigate(Screen.Investments.route)
                        },
                        onNavigateToFund = { schemeCode ->
                            navController.navigate(Screen.FundDetail.createRoute(schemeCode))
                        },
                        onNavigateToGoals = {
                            navController.navigate(Screen.Goals.route)
                        },
                        onNavigateToAnalysis = {
                            navController.navigate(Screen.Insights.route)
                        },
                        onNavigateToAvya = {
                            navController.navigate(Screen.AvyaChat.route)
                        }
                    )
                }

                composable(Screen.Investments.route) {
                    InvestmentsScreen(
                        onNavigateToFund = { schemeCode ->
                            navController.navigate(Screen.FundDetail.createRoute(schemeCode))
                        },
                        onNavigateToTransactions = {
                            navController.navigate(Screen.TransactionHistory.route)
                        }
                    )
                }

                composable(Screen.Explore.route) {
                    ExploreScreen(
                        onNavigateToFund = { schemeCode ->
                            navController.navigate(Screen.FundDetail.createRoute(schemeCode))
                        }
                    )
                }

                composable(Screen.Insights.route) {
                    InsightsScreen(
                        onNavigateToRecommendations = {
                            navController.navigate(Screen.Recommendations.route)
                        }
                    )
                }

                composable(Screen.Profile.route) {
                    ProfileScreen(
                        onLogout = {
                            authViewModel.logout()
                            navController.navigate(Screen.Login.route) {
                                popUpTo(Screen.Home.route) { inclusive = true }
                            }
                        },
                        onNavigateToSettings = {
                            navController.navigate(Screen.Settings.route)
                        },
                        onNavigateToGoals = {
                            navController.navigate(Screen.Goals.route)
                        },
                        onNavigateToEditProfile = {
                            navController.navigate(Screen.EditProfile.route)
                        },
                        onNavigateToKYC = {
                            navController.navigate(Screen.KYCStatus.route)
                        },
                        onNavigateToRiskProfile = {
                            navController.navigate(Screen.RiskProfile.route)
                        }
                    )
                }

                // Profile sub-screens
                composable(Screen.EditProfile.route) {
                    EditProfileScreen(
                        onBackClick = { navController.popBackStack() }
                    )
                }

                composable(Screen.KYCStatus.route) {
                    KYCStatusScreen(
                        onBackClick = { navController.popBackStack() }
                    )
                }

                composable(Screen.RiskProfile.route) {
                    RiskProfileScreen(
                        onBackClick = { navController.popBackStack() },
                        onRetakeAssessment = { navController.navigate(Screen.RiskAssessment.route) }
                    )
                }

                // Detail screens
                composable(
                    route = Screen.FundDetail.route,
                    arguments = listOf(
                        navArgument(NavArguments.SCHEME_CODE) { type = NavType.IntType }
                    )
                ) { backStackEntry ->
                    val schemeCode = backStackEntry.arguments?.getInt(NavArguments.SCHEME_CODE) ?: 0

                    FundDetailScreen(
                        schemeCode = schemeCode,
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onNavigateToBroker = { name, code ->
                            navController.navigate(Screen.BrokerSelection.createRoute(name, code))
                        }
                    )
                }

                composable(Screen.Goals.route) {
                    GoalsScreen(
                        onNavigateToGoal = { goalId ->
                            navController.navigate(Screen.GoalDetail.createRoute(goalId))
                        },
                        onCreateGoal = {
                            navController.navigate(Screen.CreateGoal.route)
                        },
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                composable(
                    route = Screen.GoalDetail.route,
                    arguments = listOf(
                        navArgument(NavArguments.GOAL_ID) { type = NavType.StringType }
                    )
                ) {
                    GoalDetailScreen(
                        onNavigateToFund = { schemeCode ->
                            navController.navigate(Screen.FundDetail.createRoute(schemeCode))
                        },
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                // Settings
                composable(Screen.Settings.route) {
                    SettingsScreen(
                        onNavigateBack = {
                            navController.popBackStack()
                        },
                        onNavigateToLanguage = {
                            navController.navigate(Screen.LanguageSettings.route)
                        },
                        onNavigateToCache = {
                            navController.navigate(Screen.CacheManagement.route)
                        },
                        onNavigateToNotifications = {
                            navController.navigate(Screen.NotificationSettings.route)
                        },
                        onNavigateToSecurity = {
                            navController.navigate(Screen.SecuritySettings.route)
                        }
                    )
                }

                // Settings sub-screens
                composable(Screen.LanguageSettings.route) {
                    LanguageScreen(
                        onBackClick = { navController.popBackStack() }
                    )
                }

                composable(Screen.CacheManagement.route) {
                    CacheManagementScreen(
                        onBackClick = { navController.popBackStack() }
                    )
                }

                composable(Screen.NotificationSettings.route) {
                    NotificationSettingsScreen(
                        onBackClick = { navController.popBackStack() }
                    )
                }

                composable(Screen.SecuritySettings.route) {
                    SecuritySettingsScreen(
                        onBackClick = { navController.popBackStack() }
                    )
                }

                // Advisor screens
                composable(Screen.AdvisorDirectory.route) {
                    AdvisorDirectoryScreen(
                        onNavigateToAdvisor = { advisorId ->
                            navController.navigate(Screen.AdvisorDetail.createRoute(advisorId))
                        },
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                composable(
                    route = Screen.AdvisorDetail.route,
                    arguments = listOf(
                        navArgument(NavArguments.ADVISOR_ID) { type = NavType.StringType }
                    )
                ) { backStackEntry ->
                    val advisorId = backStackEntry.arguments?.getString(NavArguments.ADVISOR_ID) ?: ""

                    AdvisorDetailScreen(
                        advisorId = advisorId,
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                composable(Screen.MyAdvisor.route) {
                    MyAdvisorScreen(
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                // Points/Rewards
                composable(Screen.Points.route) {
                    PointsScreen(
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                // Avya AI Chat
                composable(Screen.AvyaChat.route) {
                    AvyaChatScreen(
                        onNavigateBack = {
                            navController.popBackStack()
                        }
                    )
                }

                // Portfolio Analysis
                composable(Screen.PortfolioAnalysis.route) {
                    PortfolioAnalysisScreen(
                        onBackClick = {
                            navController.popBackStack()
                        }
                    )
                }

                // Invest - Broker Selection
                composable(
                    route = Screen.BrokerSelection.route,
                    arguments = listOf(
                        navArgument(NavArguments.FUND_NAME) { type = NavType.StringType },
                        navArgument(NavArguments.SCHEME_CODE) { type = NavType.IntType }
                    )
                ) { backStackEntry ->
                    val fundName = backStackEntry.arguments?.getString(NavArguments.FUND_NAME) ?: ""
                    val schemeCode = backStackEntry.arguments?.getInt(NavArguments.SCHEME_CODE) ?: 0

                    BrokerSelectionScreen(
                        fundName = fundName,
                        fundSchemeCode = schemeCode,
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onNavigateToManualEntry = {
                            navController.navigate(Screen.ManualInvestment.route)
                        }
                    )
                }

                // Invest - Manual Investment
                composable(Screen.ManualInvestment.route) {
                    ManualInvestmentScreen(
                        onBackClick = {
                            navController.popBackStack()
                        },
                        onSave = {
                            navController.popBackStack()
                        }
                    )
                }
            }
        }
    }
}
