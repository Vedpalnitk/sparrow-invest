/**
 * Admin Portal Colors Hook - "Cyan & Slate" Design System
 *
 * Thin wrapper that re-exports from adminTheme.ts for backward compatibility.
 * All admin pages using useAdminColors will automatically get the Cyan & Slate theme.
 */

import {
  ADMIN_COLORS_LIGHT,
  ADMIN_COLORS_DARK,
  useAdminDarkMode,
  useAdminTheme,
  AdminColorPalette,
} from './adminTheme'

// Re-export colors with V4 naming for backward compatibility
export const V4_COLORS_LIGHT = ADMIN_COLORS_LIGHT
export const V4_COLORS_DARK = ADMIN_COLORS_DARK

// Re-export the AdminColors type (extends AdminColorPalette for full compatibility)
export type AdminColors = AdminColorPalette
export type { AdminColorPalette }

// Re-export dark mode hook
export const useDarkMode = useAdminDarkMode

// Main hook - returns colors based on dark mode
export const useAdminColors = () => {
  const isDark = useDarkMode()
  return isDark ? V4_COLORS_DARK : V4_COLORS_LIGHT
}

// Re-export the full theme hook
export { useAdminTheme }

// Default export for convenience
export default useAdminColors
