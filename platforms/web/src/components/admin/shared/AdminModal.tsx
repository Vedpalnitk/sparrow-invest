/**
 * Admin Portal Modal Component - "Sage & Cream" Design System
 *
 * Shared modal component for Admin pages with consistent styling.
 * Import with: import { AdminModal } from '@/components/admin/shared'
 */

import { ReactNode, useEffect } from 'react'
import { useAdminTheme } from '@/utils/adminTheme'

export interface AdminModalProps {
  isOpen: boolean
  onClose: () => void
  title: string
  children: ReactNode
  size?: 'sm' | 'md' | 'lg' | 'xl'
  footer?: ReactNode
}

const sizeClasses = {
  sm: 'max-w-sm',
  md: 'max-w-lg',
  lg: 'max-w-2xl',
  xl: 'max-w-4xl',
}

export const AdminModal = ({
  isOpen,
  onClose,
  title,
  children,
  size = 'md',
  footer,
}: AdminModalProps) => {
  const { colors } = useAdminTheme()

  // Handle escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose()
      }
    }
    document.addEventListener('keydown', handleEscape)
    return () => document.removeEventListener('keydown', handleEscape)
  }, [isOpen, onClose])

  // Prevent body scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = ''
    }
    return () => {
      document.body.style.overflow = ''
    }
  }, [isOpen])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />

      {/* Modal container */}
      <div
        className={`relative p-6 w-full ${sizeClasses[size]} max-h-[90vh] overflow-y-auto rounded-xl`}
        style={{
          background: colors.cardBackground,
          border: `1px solid ${colors.cardBorder}`,
          boxShadow: `0 25px 50px -12px ${colors.glassShadow}`,
        }}
      >
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <h3
            className="text-lg font-bold"
            style={{ color: colors.textPrimary }}
          >
            {title}
          </h3>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-xl flex items-center justify-center transition-colors hover:opacity-70"
            style={{ background: colors.chipBg }}
            aria-label="Close modal"
          >
            <svg
              className="w-4 h-4"
              style={{ color: colors.textSecondary }}
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div>{children}</div>

        {/* Footer (optional) */}
        {footer && (
          <div
            className="mt-6 pt-4 border-t"
            style={{ borderColor: colors.cardBorder }}
          >
            {footer}
          </div>
        )}
      </div>
    </div>
  )
}

export default AdminModal
