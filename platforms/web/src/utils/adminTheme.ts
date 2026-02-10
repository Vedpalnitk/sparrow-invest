/**
 * Admin Portal Theme - "Cyan & Slate" Design System
 *
 * A clean, modern aesthetic with vibrant cyan primaries and cool slate tones.
 * Sharp, professional, and contemporary.
 *
 * Font: Plus Jakarta Sans
 * @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');
 */

import { useState, useEffect } from 'react'

export interface AdminColorPalette {
  // Primary - Cyan
  primary: string
  primaryDark: string
  primaryDeep: string
  primaryLight: string
  accent: string

  // Secondary - Teal
  secondary: string
  secondaryDark: string

  // Semantic
  success: string
  warning: string
  error: string
  info: string

  // Backgrounds
  background: string
  backgroundSecondary: string
  backgroundTertiary: string
  cardBackground: string

  // Glass effects (backward compatibility)
  glassBackground: string
  glassBorder: string

  // Borders & Shadows
  cardBorder: string
  inputBorder: string
  chipBg: string
  chipBorder: string
  glassShadow: string

  // Text
  textPrimary: string
  textSecondary: string
  textTertiary: string

  // Inputs
  inputBg: string

  // Progress
  progressBg: string

  // Gradients
  gradientPrimary: string
  gradientSecondary: string
  gradientSuccess: string
  gradientWarning: string

  // Admin-specific
  inkWash: string
  inkStroke: string
  paperTexture: string

  // Card background gradient (backward compatibility)
  cardBg: string
}

export const ADMIN_COLORS_LIGHT: AdminColorPalette = {
  // Primary - Cyan (vibrant, modern)
  primary: '#06B6D4',           // Cyan 500
  primaryDark: '#0891B2',       // Cyan 600
  primaryDeep: '#0E7490',       // Cyan 700
  primaryLight: '#22D3EE',      // Cyan 400
  accent: '#67E8F9',            // Cyan 300

  // Secondary - Teal (complementary depth)
  secondary: '#14B8A6',         // Teal 500
  secondaryDark: '#0D9488',     // Teal 600

  // Semantic (clear, distinct)
  success: '#10B981',           // Emerald 500
  warning: '#F59E0B',           // Amber 500
  error: '#EF4444',             // Red 500
  info: '#06B6D4',              // Cyan 500

  // Backgrounds - Cool slate
  background: '#F8FAFC',        // Slate 50
  backgroundSecondary: '#F1F5F9', // Slate 100
  backgroundTertiary: '#E2E8F0', // Slate 200
  cardBackground: '#FFFFFF',

  // Glass effects (backward compatibility)
  glassBackground: 'rgba(255, 255, 255, 0.85)',
  glassBorder: 'rgba(6, 182, 212, 0.15)',

  // Borders & Shadows - Cool and crisp
  cardBorder: 'rgba(6, 182, 212, 0.12)',
  inputBorder: 'rgba(6, 182, 212, 0.2)',
  chipBg: 'rgba(6, 182, 212, 0.08)',
  chipBorder: 'rgba(6, 182, 212, 0.15)',
  glassShadow: 'rgba(6, 182, 212, 0.08)',

  // Text - Cool neutrals
  textPrimary: '#0F172A',       // Slate 900
  textSecondary: '#475569',     // Slate 600
  textTertiary: '#94A3B8',      // Slate 400

  // Inputs
  inputBg: 'rgba(6, 182, 212, 0.04)',

  // Progress
  progressBg: 'rgba(6, 182, 212, 0.12)',

  // Gradients - Vibrant and clean
  gradientPrimary: 'linear-gradient(135deg, #06B6D4 0%, #22D3EE 100%)',
  gradientSecondary: 'linear-gradient(135deg, #14B8A6 0%, #2DD4BF 100%)',
  gradientSuccess: 'linear-gradient(135deg, #10B981 0%, #34D399 100%)',
  gradientWarning: 'linear-gradient(135deg, #F59E0B 0%, #FBBF24 100%)',

  // Admin-specific
  inkWash: 'linear-gradient(180deg, rgba(6, 182, 212, 0.03) 0%, rgba(6, 182, 212, 0.06) 100%)',
  inkStroke: 'rgba(6, 182, 212, 0.1)',
  paperTexture: 'rgba(248, 250, 252, 0.8)',

  // Card background gradient (backward compatibility)
  cardBg: 'linear-gradient(135deg, rgba(6, 182, 212, 0.04) 0%, rgba(34, 211, 238, 0.02) 100%)',
}

export const ADMIN_COLORS_DARK: AdminColorPalette = {
  // Primary - Lifted Cyan for dark mode
  primary: '#22D3EE',           // Cyan 400
  primaryDark: '#06B6D4',       // Cyan 500
  primaryDeep: '#0891B2',       // Cyan 600
  primaryLight: '#67E8F9',      // Cyan 300
  accent: '#A5F3FC',            // Cyan 200

  // Secondary - Lifted Teal
  secondary: '#2DD4BF',         // Teal 400
  secondaryDark: '#14B8A6',     // Teal 500

  // Semantic
  success: '#34D399',           // Emerald 400
  warning: '#FBBF24',           // Amber 400
  error: '#F87171',             // Red 400
  info: '#22D3EE',              // Cyan 400

  // Backgrounds - Cool dark slate
  background: '#0F172A',        // Slate 900
  backgroundSecondary: '#1E293B', // Slate 800
  backgroundTertiary: '#334155', // Slate 700
  cardBackground: '#1E293B',

  // Glass effects (backward compatibility)
  glassBackground: 'rgba(30, 41, 59, 0.88)',
  glassBorder: 'rgba(34, 211, 238, 0.15)',

  // Borders & Shadows
  cardBorder: 'rgba(34, 211, 238, 0.15)',
  inputBorder: 'rgba(34, 211, 238, 0.2)',
  chipBg: 'rgba(34, 211, 238, 0.1)',
  chipBorder: 'rgba(34, 211, 238, 0.15)',
  glassShadow: 'rgba(0, 0, 0, 0.3)',

  // Text
  textPrimary: '#F1F5F9',       // Slate 100
  textSecondary: '#CBD5E1',     // Slate 300
  textTertiary: '#94A3B8',      // Slate 400

  // Inputs
  inputBg: 'rgba(34, 211, 238, 0.08)',

  // Progress
  progressBg: 'rgba(34, 211, 238, 0.15)',

  // Gradients
  gradientPrimary: 'linear-gradient(135deg, #0891B2 0%, #06B6D4 100%)',
  gradientSecondary: 'linear-gradient(135deg, #0D9488 0%, #14B8A6 100%)',
  gradientSuccess: 'linear-gradient(135deg, #059669 0%, #10B981 100%)',
  gradientWarning: 'linear-gradient(135deg, #D97706 0%, #F59E0B 100%)',

  // Admin-specific
  inkWash: 'linear-gradient(180deg, rgba(34, 211, 238, 0.04) 0%, rgba(34, 211, 238, 0.08) 100%)',
  inkStroke: 'rgba(34, 211, 238, 0.12)',
  paperTexture: 'rgba(15, 23, 42, 0.8)',

  // Card background gradient (backward compatibility)
  cardBg: 'linear-gradient(135deg, rgba(34, 211, 238, 0.06) 0%, rgba(103, 232, 249, 0.03) 100%)',
}

/**
 * Hook to detect dark mode
 */
export const useAdminDarkMode = () => {
  const [isDark, setIsDark] = useState(false)
  useEffect(() => {
    const checkDark = () => setIsDark(document.documentElement.classList.contains('dark'))
    checkDark()
    const observer = new MutationObserver(checkDark)
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })
    return () => observer.disconnect()
  }, [])
  return isDark
}

/**
 * Hook to get Admin theme colors
 */
export const useAdminTheme = () => {
  const isDark = useAdminDarkMode()
  const colors = isDark ? ADMIN_COLORS_DARK : ADMIN_COLORS_LIGHT
  return { isDark, colors }
}

/**
 * Model/Engine status colors
 */
export const getModelStatusColor = (status: string, colors: AdminColorPalette): string => {
  switch (status) {
    case 'Healthy':
    case 'Active':
    case 'Online':
      return colors.success
    case 'Monitoring':
    case 'Warning':
    case 'Pending':
      return colors.warning
    case 'Error':
    case 'Offline':
    case 'Failed':
      return colors.error
    case 'Training':
    case 'Processing':
      return colors.info
    default:
      return colors.textSecondary
  }
}

/**
 * Activity type colors
 */
export const getActivityTypeColor = (type: string, colors: AdminColorPalette): string => {
  switch (type) {
    case 'user':
    case 'onboard':
      return colors.primary
    case 'model':
    case 'training':
      return colors.secondary
    case 'create':
    case 'add':
      return colors.success
    case 'check':
    case 'compliance':
      return colors.info
    case 'warning':
    case 'alert':
      return colors.warning
    case 'error':
    case 'fail':
      return colors.error
    default:
      return colors.textSecondary
  }
}

/**
 * Risk band colors
 */
export const getRiskBandColor = (band: string, colors: AdminColorPalette): string => {
  switch (band) {
    case 'Capital Protection':
    case 'Conservative':
    case 'Low':
      return colors.success
    case 'Balanced Growth':
    case 'Moderate':
    case 'Medium':
      return colors.info
    case 'Accelerated Growth':
    case 'Aggressive':
    case 'High':
      return colors.warning
    case 'Very High':
      return colors.error
    default:
      return colors.textSecondary
  }
}
