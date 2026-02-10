/**
 * FA Portal Formatters & Utilities
 *
 * Formatting functions for currency, dates, numbers, etc.
 * Import with: import { formatCurrency, formatDate, etc } from '@/utils/faFormatters'
 */

/**
 * Format currency with Indian notation (Lakhs, Crores)
 * Examples:
 *   formatCurrency(1500000) => "₹15.00 L"
 *   formatCurrency(25000000) => "₹2.50 Cr"
 *   formatCurrency(50000) => "₹50,000"
 */
export const formatCurrency = (amount: number, options?: { short?: boolean; decimals?: number }): string => {
  const { short = true, decimals = 2 } = options || {}

  if (short) {
    if (Math.abs(amount) >= 10000000) {
      return `₹${(amount / 10000000).toFixed(decimals)} Cr`
    }
    if (Math.abs(amount) >= 100000) {
      return `₹${(amount / 100000).toFixed(decimals)} L`
    }
  }

  return `₹${amount.toLocaleString('en-IN', { maximumFractionDigits: 0 })}`
}

/**
 * Format currency for compact display (no decimals for L/Cr)
 */
export const formatCurrencyCompact = (amount: number): string => {
  if (Math.abs(amount) >= 10000000) {
    const crores = amount / 10000000
    return crores % 1 === 0 ? `₹${crores} Cr` : `₹${crores.toFixed(1)} Cr`
  }
  if (Math.abs(amount) >= 100000) {
    const lakhs = amount / 100000
    return lakhs % 1 === 0 ? `₹${lakhs} L` : `₹${lakhs.toFixed(1)} L`
  }
  if (Math.abs(amount) >= 1000) {
    return `₹${(amount / 1000).toFixed(0)}K`
  }
  return `₹${amount.toLocaleString('en-IN', { maximumFractionDigits: 0 })}`
}

/**
 * Format number with Indian notation
 */
export const formatNumber = (num: number, decimals: number = 0): string => {
  return num.toLocaleString('en-IN', { maximumFractionDigits: decimals })
}

/**
 * Format percentage
 */
export const formatPercent = (value: number, options?: { decimals?: number; showSign?: boolean }): string => {
  const { decimals = 1, showSign = false } = options || {}
  const formatted = value.toFixed(decimals)
  if (showSign && value > 0) {
    return `+${formatted}%`
  }
  return `${formatted}%`
}

/**
 * Format returns with color indication
 */
export const formatReturns = (value: number | undefined, decimals: number = 1): string => {
  if (value === undefined || value === null) return '-'
  const sign = value >= 0 ? '+' : ''
  return `${sign}${value.toFixed(decimals)}%`
}

/**
 * Format NAV value
 */
export const formatNav = (nav: number): string => {
  return `₹${nav.toFixed(2)}`
}

/**
 * Format units
 */
export const formatUnits = (units: number, decimals: number = 3): string => {
  return units.toFixed(decimals)
}

/**
 * Format date in Indian format
 */
export const formatDate = (
  date: string | Date,
  options?: { format?: 'short' | 'medium' | 'long' | 'relative' }
): string => {
  const { format = 'medium' } = options || {}
  const d = typeof date === 'string' ? new Date(date) : date

  if (isNaN(d.getTime())) return '-'

  switch (format) {
    case 'short':
      // "20 Jan"
      return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
    case 'medium':
      // "20 Jan 2024"
      return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
    case 'long':
      // "20 January 2024"
      return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' })
    case 'relative':
      return formatRelativeTime(d)
    default:
      return d.toLocaleDateString('en-IN')
  }
}

/**
 * Format datetime
 */
export const formatDateTime = (date: string | Date): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  if (isNaN(d.getTime())) return '-'

  return d.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

/**
 * Format relative time (e.g., "2 hours ago", "3 days ago")
 */
export const formatRelativeTime = (date: string | Date): string => {
  const d = typeof date === 'string' ? new Date(date) : date
  if (isNaN(d.getTime())) return '-'

  const now = new Date()
  const diffMs = now.getTime() - d.getTime()
  const diffSec = Math.floor(diffMs / 1000)
  const diffMin = Math.floor(diffSec / 60)
  const diffHour = Math.floor(diffMin / 60)
  const diffDay = Math.floor(diffHour / 24)
  const diffWeek = Math.floor(diffDay / 7)
  const diffMonth = Math.floor(diffDay / 30)

  if (diffSec < 60) return 'Just now'
  if (diffMin < 60) return `${diffMin} min${diffMin > 1 ? 's' : ''} ago`
  if (diffHour < 24) return `${diffHour} hour${diffHour > 1 ? 's' : ''} ago`
  if (diffDay < 7) return `${diffDay} day${diffDay > 1 ? 's' : ''} ago`
  if (diffWeek < 4) return `${diffWeek} week${diffWeek > 1 ? 's' : ''} ago`
  if (diffMonth < 12) return `${diffMonth} month${diffMonth > 1 ? 's' : ''} ago`

  return formatDate(d, { format: 'medium' })
}

/**
 * Format file size
 */
export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`
}

/**
 * Format phone number (Indian format)
 */
export const formatPhone = (phone: string): string => {
  const cleaned = phone.replace(/\D/g, '')
  if (cleaned.length === 10) {
    return `+91 ${cleaned.slice(0, 5)} ${cleaned.slice(5)}`
  }
  if (cleaned.length === 12 && cleaned.startsWith('91')) {
    return `+${cleaned.slice(0, 2)} ${cleaned.slice(2, 7)} ${cleaned.slice(7)}`
  }
  return phone
}

/**
 * Mask PAN number (show only last 4)
 */
export const maskPan = (pan: string): string => {
  if (!pan || pan.length < 4) return pan
  return `XXXXXX${pan.slice(-4)}`
}

/**
 * Mask account number (show only last 4)
 */
export const maskAccountNumber = (account: string): string => {
  if (!account || account.length < 4) return account
  return `XXXX${account.slice(-4)}`
}

/**
 * Get initials from name
 */
export const getInitials = (name: string, maxChars: number = 2): string => {
  if (!name) return ''
  const words = name.trim().split(/\s+/)
  const initials = words.map((w) => w[0]?.toUpperCase() || '').join('')
  return initials.slice(0, maxChars)
}

/**
 * Truncate text with ellipsis
 */
export const truncate = (text: string, maxLength: number): string => {
  if (!text || text.length <= maxLength) return text
  return `${text.slice(0, maxLength - 3)}...`
}

/**
 * Calculate CAGR (Compound Annual Growth Rate)
 */
export const calculateCAGR = (beginValue: number, endValue: number, years: number): number => {
  if (beginValue <= 0 || years <= 0) return 0
  return (Math.pow(endValue / beginValue, 1 / years) - 1) * 100
}

/**
 * Calculate absolute return percentage
 */
export const calculateAbsoluteReturn = (invested: number, current: number): number => {
  if (invested <= 0) return 0
  return ((current - invested) / invested) * 100
}

/**
 * Format SIP date (ordinal)
 */
export const formatSipDate = (day: number): string => {
  const suffix = ['th', 'st', 'nd', 'rd']
  const v = day % 100
  return `${day}${suffix[(v - 20) % 10] || suffix[v] || suffix[0]} of every month`
}

/**
 * Get fiscal year for a date
 */
export const getFiscalYear = (date: Date = new Date()): string => {
  const year = date.getFullYear()
  const month = date.getMonth()
  if (month >= 3) {
    return `FY${year}-${(year + 1).toString().slice(-2)}`
  }
  return `FY${year - 1}-${year.toString().slice(-2)}`
}

/**
 * Check if date is in current fiscal year
 */
export const isCurrentFiscalYear = (date: Date): boolean => {
  const currentFY = getFiscalYear(new Date())
  const dateFY = getFiscalYear(date)
  return currentFY === dateFY
}

/**
 * Asset class display labels
 */
export const ASSET_CLASS_LABELS: Record<string, string> = {
  equity: 'Equity',
  debt: 'Debt',
  hybrid: 'Hybrid',
  liquid: 'Liquid',
  gold: 'Gold',
  international: 'International',
  elss: 'ELSS',
  index: 'Index',
  fof: 'Fund of Funds',
}

/**
 * Get asset class label
 */
export const getAssetClassLabel = (assetClass: string): string => {
  return ASSET_CLASS_LABELS[assetClass.toLowerCase()] || assetClass
}

/**
 * Risk profile labels
 */
export const RISK_PROFILE_LABELS: Record<string, string> = {
  conservative: 'Conservative',
  moderate: 'Moderate',
  aggressive: 'Aggressive',
}

/**
 * Transaction type labels
 */
export const TRANSACTION_TYPE_LABELS: Record<string, string> = {
  buy: 'Purchase',
  sell: 'Redemption',
  sip: 'SIP',
  swp: 'SWP',
  switch: 'Switch',
  stp: 'STP',
}
