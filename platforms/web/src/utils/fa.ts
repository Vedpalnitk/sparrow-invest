/**
 * FA Portal Utilities - Central Export
 *
 * Import all FA utilities from this single file:
 * import { useFAColors, formatCurrency, FA_COLORS_LIGHT, Client } from '@/utils/fa'
 *
 * Or import from specific files for tree-shaking:
 * import { useFAColors } from '@/utils/faHooks'
 * import { formatCurrency } from '@/utils/faFormatters'
 */

// Colors
export {
  FA_COLORS_LIGHT,
  FA_COLORS_DARK,
  CATEGORY_COLORS,
  getRiskColor,
  getTransactionTypeColor,
  getStatusColor,
  getAssetClassColor,
  getSeverityColor,
  getStageColor,
  getGoalStatusColor,
  getRiskRatingInfo,
  getCategoryBadgeStyle,
} from './faColors'
export type { FAColorPalette } from './faColors'

// Hooks
export {
  useDarkMode,
  useFAColors,
  useFATheme,
  useDebounce,
  useLocalStorage,
  useFilters,
  usePagination,
  useModal,
  useAsync,
  useWindowSize,
  useIsMobile,
} from './faHooks'
export type { FilterState } from './faHooks'

// Formatters
export {
  formatCurrency,
  formatCurrencyCompact,
  formatNumber,
  formatPercent,
  formatReturns,
  formatNav,
  formatUnits,
  formatDate,
  formatDateTime,
  formatRelativeTime,
  formatFileSize,
  formatPhone,
  maskPan,
  maskAccountNumber,
  getInitials,
  truncate,
  calculateCAGR,
  calculateAbsoluteReturn,
  formatSipDate,
  getFiscalYear,
  isCurrentFiscalYear,
  getAssetClassLabel,
  ASSET_CLASS_LABELS,
  RISK_PROFILE_LABELS,
  TRANSACTION_TYPE_LABELS,
} from './faFormatters'

// Types
export type {
  // Client
  RiskProfile,
  Client,
  BankAccount,
  ClientFormData,
  // Portfolio
  Holding,
  Portfolio,
  AssetAllocation,
  // Transactions
  TransactionType,
  TransactionStatus,
  Transaction,
  TransactionFormData,
  // SIP
  SIPStatus,
  SIPFrequency,
  SIP,
  SIPFormData,
  // Goals
  GoalType,
  GoalPriority,
  Goal,
  GoalFormData,
  // Prospects
  ProspectStage,
  LeadSource,
  Prospect,
  ProspectActivity,
  ProspectFormData,
  // Reports
  ReportType,
  ReportFormat,
  ReportFrequency,
  Report,
  ScheduledReport,
  ReportConfig,
  // Analysis
  AnalysisType,
  AnalysisResult,
  InsightSeverity,
  AIInsight,
  // Dashboard
  DashboardKPI,
  PendingAction,
  // Advisor
  AdvisorProfile,
  AdvisorPreferences,
  // Funds
  FundBasic,
  FundDetails,
  // Common
  SortDirection,
  PaginationParams,
  PaginatedResponse,
  DateRange,
  SelectOption,
} from './faTypes'
