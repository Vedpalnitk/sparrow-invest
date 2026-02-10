/**
 * Admin Portal Card Components - "Sage & Cream" Design System
 *
 * A warm, sophisticated aesthetic with soft sage greens and cream tones.
 * Light, airy, and approachable while remaining professional.
 *
 * Import with: import { AdminCard, AdminTintedCard, AdminInfoTile } from '@/components/admin/shared'
 */

import { ReactNode, CSSProperties } from 'react'
import { useAdminTheme, AdminColorPalette } from '@/utils/adminTheme'

interface BaseCardProps {
  children: ReactNode
  className?: string
  style?: CSSProperties
  onClick?: () => void
}

/**
 * Base Card - Clean container with subtle sage border
 */
export const AdminCard = ({
  children,
  className = '',
  style,
  onClick,
  padding = 'md',
  hover = false,
}: BaseCardProps & {
  padding?: 'none' | 'sm' | 'md' | 'lg'
  hover?: boolean
}) => {
  const { isDark, colors } = useAdminTheme()

  const paddingClass = {
    none: '',
    sm: 'p-4',
    md: 'p-5',
    lg: 'p-6',
  }[padding]

  const hoverClass = hover ? 'transition-all duration-200 hover:-translate-y-0.5 hover:shadow-lg cursor-pointer' : ''

  return (
    <div
      className={`rounded-2xl ${paddingClass} ${hoverClass} ${className}`}
      style={{
        background: colors.cardBackground,
        border: `1px solid ${colors.cardBorder}`,
        boxShadow: isDark ? 'none' : `0 2px 8px ${colors.glassShadow}`,
        ...style,
      }}
      onClick={onClick}
    >
      {children}
    </div>
  )
}

/**
 * Tinted Card - Warm sage-tinted background for interactive items
 */
export const AdminTintedCard = ({
  children,
  className = '',
  style,
  onClick,
  padding = 'md',
  accentColor,
  hover = true,
}: BaseCardProps & {
  padding?: 'none' | 'sm' | 'md' | 'lg'
  accentColor?: string
  hover?: boolean
}) => {
  const { isDark, colors } = useAdminTheme()

  const paddingClass = {
    none: '',
    sm: 'p-3',
    md: 'p-4',
    lg: 'p-5',
  }[padding]

  const hoverClass = hover ? 'transition-all duration-200 hover:-translate-y-0.5 hover:shadow-md cursor-pointer' : ''

  return (
    <div
      className={`rounded-xl ${hoverClass} ${paddingClass} ${className}`}
      style={{
        background: colors.inkWash,
        border: `1px solid ${colors.cardBorder}`,
        borderLeft: accentColor ? `3px solid ${accentColor}` : `1px solid ${colors.cardBorder}`,
        ...style,
      }}
      onClick={onClick}
    >
      {children}
    </div>
  )
}

/**
 * Info Tile - Card with warm accent border
 */
export const AdminInfoTile = ({
  children,
  className = '',
  style,
  accentColor,
  padding = 'md',
  variant = 'info',
}: BaseCardProps & {
  accentColor?: string
  padding?: 'none' | 'sm' | 'md' | 'lg'
  variant?: 'info' | 'success' | 'warning' | 'error'
}) => {
  const { isDark, colors } = useAdminTheme()

  const paddingClass = {
    none: '',
    sm: 'p-3',
    md: 'p-4',
    lg: 'p-5',
  }[padding]

  const getAccentColor = () => {
    if (accentColor) return accentColor
    switch (variant) {
      case 'success': return colors.success
      case 'warning': return colors.warning
      case 'error': return colors.error
      case 'info':
      default: return colors.primary
    }
  }

  const accent = getAccentColor()

  return (
    <div
      className={`rounded-xl ${paddingClass} ${className}`}
      style={{
        background: isDark ? colors.backgroundSecondary : colors.cardBackground,
        border: `1px solid ${colors.cardBorder}`,
        borderLeft: `3px solid ${accent}`,
        boxShadow: isDark ? 'none' : `0 1px 4px ${colors.glassShadow}`,
        ...style,
      }}
    >
      {children}
    </div>
  )
}

/**
 * Stat Card - Warm sage gradient for KPIs
 */
export const AdminStatCard = ({
  label,
  value,
  change,
  changeType = 'neutral',
  icon,
  variant = 'primary',
  className = '',
}: {
  label: string
  value: string | number
  change?: string
  changeType?: 'positive' | 'negative' | 'neutral'
  icon?: ReactNode
  variant?: 'primary' | 'secondary' | 'success' | 'accent'
  className?: string
}) => {
  const { isDark, colors } = useAdminTheme()

  const getGradient = () => {
    switch (variant) {
      case 'secondary':
        return colors.gradientSecondary
      case 'success':
        return colors.gradientSuccess
      case 'accent':
        return `linear-gradient(135deg, ${colors.primaryLight} 0%, ${colors.primary} 100%)`
      default:
        return colors.gradientPrimary
    }
  }

  const getChangeColor = () => {
    switch (changeType) {
      case 'positive': return '#FFFFFF'
      case 'negative': return '#FFE4E4'
      default: return 'rgba(255,255,255,0.8)'
    }
  }

  return (
    <div
      className={`p-5 rounded-2xl relative overflow-hidden transition-all duration-300 hover:-translate-y-1 hover:shadow-xl ${className}`}
      style={{
        background: getGradient(),
        boxShadow: `0 8px 24px ${colors.primary}25`,
      }}
    >
      {/* Decorative organic shape */}
      <div
        className="absolute -top-8 -right-8 w-32 h-32 rounded-full opacity-20"
        style={{
          background: 'radial-gradient(circle, rgba(255,255,255,0.4) 0%, transparent 70%)',
        }}
      />
      <div
        className="absolute -bottom-4 -left-4 w-20 h-20 rounded-full opacity-10"
        style={{
          background: 'radial-gradient(circle, rgba(255,255,255,0.5) 0%, transparent 70%)',
        }}
      />
      <div className="relative z-10">
        <div className="flex items-center justify-between mb-3">
          <p className="text-[11px] font-semibold uppercase tracking-wider text-white/70">
            {label}
          </p>
          {icon && (
            <div className="w-9 h-9 rounded-xl flex items-center justify-center bg-white/15 backdrop-blur-sm">
              {icon}
            </div>
          )}
        </div>
        <p className="text-2xl font-bold text-white">{value}</p>
        {change && (
          <div className="mt-3">
            <span
              className="text-xs font-semibold px-2.5 py-1 rounded-full"
              style={{
                background: 'rgba(255, 255, 255, 0.2)',
                color: getChangeColor(),
              }}
            >
              {change}
            </span>
          </div>
        )}
      </div>
    </div>
  )
}

/**
 * Section Header - Warm typography hierarchy
 */
export const AdminSectionHeader = ({
  title,
  subtitle,
  action,
  icon,
  className = '',
}: {
  title: string
  subtitle?: string
  action?: ReactNode
  icon?: ReactNode
  className?: string
}) => {
  const { colors } = useAdminTheme()

  return (
    <div className={`flex items-center justify-between mb-5 ${className}`}>
      <div className="flex items-center gap-3">
        {icon && (
          <div
            className="w-10 h-10 rounded-xl flex items-center justify-center"
            style={{
              background: `linear-gradient(135deg, ${colors.primary}15 0%, ${colors.primary}08 100%)`,
              border: `1px solid ${colors.primary}20`,
            }}
          >
            {icon}
          </div>
        )}
        <div>
          <h3 className="text-[15px] font-semibold" style={{ color: colors.textPrimary }}>
            {title}
          </h3>
          {subtitle && (
            <p className="text-xs mt-0.5" style={{ color: colors.textTertiary }}>
              {subtitle}
            </p>
          )}
        </div>
      </div>
      {action}
    </div>
  )
}

/**
 * Chip/Badge - Soft pill style
 */
export const AdminChip = ({
  children,
  color,
  variant = 'filled',
  size = 'sm',
  className = '',
}: {
  children: ReactNode
  color?: string
  variant?: 'filled' | 'outlined'
  size?: 'xs' | 'sm' | 'md'
  className?: string
}) => {
  const { colors } = useAdminTheme()
  const chipColor = color || colors.primary

  const sizeClass = {
    xs: 'text-[10px] px-2 py-0.5',
    sm: 'text-[11px] px-2.5 py-1',
    md: 'text-xs px-3 py-1.5',
  }[size]

  const variantStyle =
    variant === 'filled'
      ? {
          background: `${chipColor}15`,
          color: chipColor,
          border: `1px solid ${chipColor}25`,
        }
      : {
          background: 'transparent',
          color: chipColor,
          border: `1px solid ${chipColor}50`,
        }

  return (
    <span
      className={`rounded-full font-semibold ${sizeClass} ${className}`}
      style={variantStyle}
    >
      {children}
    </span>
  )
}

/**
 * Icon Container - Sage-tinted background
 */
export const AdminIconContainer = ({
  children,
  color,
  size = 'md',
  gradient = false,
  className = '',
}: {
  children: ReactNode
  color?: string
  size?: 'sm' | 'md' | 'lg'
  gradient?: boolean
  className?: string
}) => {
  const { colors } = useAdminTheme()
  const iconColor = color || colors.primary

  const sizeClass = {
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-12 h-12',
  }[size]

  const bgStyle = gradient
    ? { background: colors.gradientPrimary }
    : { background: `${iconColor}12`, border: `1px solid ${iconColor}20` }

  return (
    <div
      className={`rounded-xl flex items-center justify-center ${sizeClass} ${className}`}
      style={bgStyle}
    >
      {children}
    </div>
  )
}

/**
 * Empty State - Warm, inviting placeholder
 */
export const AdminEmptyState = ({
  icon,
  title,
  description,
  action,
}: {
  icon?: ReactNode
  title: string
  description?: string
  action?: ReactNode
}) => {
  const { colors } = useAdminTheme()

  return (
    <div className="text-center py-16" style={{ color: colors.textSecondary }}>
      {icon && (
        <div
          className="w-16 h-16 mx-auto mb-5 rounded-2xl flex items-center justify-center"
          style={{
            background: `linear-gradient(135deg, ${colors.primary}10 0%, ${colors.primary}05 100%)`,
            border: `1px solid ${colors.primary}15`,
          }}
        >
          {icon}
        </div>
      )}
      <p className="text-base font-semibold" style={{ color: colors.textPrimary }}>
        {title}
      </p>
      {description && (
        <p className="text-sm mt-2 max-w-sm mx-auto" style={{ color: colors.textTertiary }}>
          {description}
        </p>
      )}
      {action && <div className="mt-5">{action}</div>}
    </div>
  )
}

/**
 * Loading Spinner - Sage colored
 */
export const AdminSpinner = ({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) => {
  const { colors } = useAdminTheme()

  const sizeClass = {
    sm: 'w-4 h-4',
    md: 'w-5 h-5',
    lg: 'w-6 h-6',
  }[size]

  return (
    <svg
      className={`animate-spin ${sizeClass}`}
      style={{ color: colors.primary }}
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="3"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
  )
}

/**
 * Button - Sage gradient primary button
 */
export const AdminButton = ({
  children,
  onClick,
  variant = 'primary',
  size = 'md',
  disabled = false,
  className = '',
}: {
  children: ReactNode
  onClick?: () => void
  variant?: 'primary' | 'secondary' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  className?: string
}) => {
  const { isDark, colors } = useAdminTheme()

  const sizeClass = {
    sm: 'text-xs px-3 py-1.5',
    md: 'text-[13px] px-4 py-2.5',
    lg: 'text-sm px-5 py-3',
  }[size]

  const getVariantStyle = () => {
    switch (variant) {
      case 'primary':
        return {
          background: colors.gradientPrimary,
          color: '#FFFFFF',
          border: 'none',
          boxShadow: `0 4px 12px ${colors.primary}30`,
        }
      case 'secondary':
        return {
          background: colors.chipBg,
          color: colors.textPrimary,
          border: `1px solid ${colors.cardBorder}`,
          boxShadow: 'none',
        }
      case 'ghost':
        return {
          background: 'transparent',
          color: colors.textSecondary,
          border: 'none',
          boxShadow: 'none',
        }
    }
  }

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`rounded-xl font-semibold transition-all duration-200 hover:opacity-90 hover:-translate-y-0.5 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none ${sizeClass} ${className}`}
      style={getVariantStyle()}
    >
      {children}
    </button>
  )
}

/**
 * Divider - Subtle sage line
 */
export const AdminDivider = ({ className = '' }: { className?: string }) => {
  const { colors } = useAdminTheme()

  return (
    <div
      className={`h-px w-full ${className}`}
      style={{ background: colors.inkStroke }}
    />
  )
}

/**
 * Progress Bar - Sage gradient fill
 */
export const AdminProgressBar = ({
  value,
  max = 100,
  showLabel = false,
  className = '',
}: {
  value: number
  max?: number
  showLabel?: boolean
  className?: string
}) => {
  const { colors } = useAdminTheme()
  const percentage = Math.min(100, Math.max(0, (value / max) * 100))

  return (
    <div className={className}>
      <div
        className="h-2 rounded-full overflow-hidden"
        style={{ background: colors.progressBg }}
      >
        <div
          className="h-full rounded-full transition-all duration-500"
          style={{
            width: `${percentage}%`,
            background: colors.gradientPrimary,
          }}
        />
      </div>
      {showLabel && (
        <p className="text-xs mt-1 text-right" style={{ color: colors.textTertiary }}>
          {percentage.toFixed(0)}%
        </p>
      )}
    </div>
  )
}

export default AdminCard
