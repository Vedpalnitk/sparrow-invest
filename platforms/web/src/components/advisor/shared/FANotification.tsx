/**
 * FA Portal Toast Notification Component
 *
 * Global notification system for success/error feedback.
 * Import with: import { FANotificationProvider, useNotification } from '@/components/advisor/shared/FANotification'
 */

import { createContext, useContext, useState, useCallback, useEffect, ReactNode } from 'react'
import { useFATheme } from '@/utils/faHooks'

type NotificationType = 'success' | 'error' | 'warning' | 'info'

interface Notification {
  id: string
  type: NotificationType
  title: string
  message?: string
  duration?: number
}

interface NotificationContextType {
  notify: (notification: Omit<Notification, 'id'>) => void
  success: (title: string, message?: string) => void
  error: (title: string, message?: string) => void
  warning: (title: string, message?: string) => void
  info: (title: string, message?: string) => void
  dismiss: (id: string) => void
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined)

export const useNotification = () => {
  const context = useContext(NotificationContext)
  if (!context) {
    throw new Error('useNotification must be used within FANotificationProvider')
  }
  return context
}

/**
 * Individual Toast Component
 */
const Toast = ({
  notification,
  onDismiss,
}: {
  notification: Notification
  onDismiss: () => void
}) => {
  const { colors, isDark } = useFATheme()

  useEffect(() => {
    const timer = setTimeout(() => {
      onDismiss()
    }, notification.duration || 4000)

    return () => clearTimeout(timer)
  }, [notification.duration, onDismiss])

  const getTypeConfig = () => {
    switch (notification.type) {
      case 'success':
        return {
          color: colors.success,
          bgColor: isDark ? 'rgba(16, 185, 129, 0.15)' : 'rgba(16, 185, 129, 0.08)',
          icon: (
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          ),
        }
      case 'error':
        return {
          color: colors.error,
          bgColor: isDark ? 'rgba(239, 68, 68, 0.15)' : 'rgba(239, 68, 68, 0.08)',
          icon: (
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          ),
        }
      case 'warning':
        return {
          color: colors.warning,
          bgColor: isDark ? 'rgba(245, 158, 11, 0.15)' : 'rgba(245, 158, 11, 0.08)',
          icon: (
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          ),
        }
      case 'info':
      default:
        return {
          color: colors.primary,
          bgColor: isDark ? 'rgba(59, 130, 246, 0.15)' : 'rgba(59, 130, 246, 0.08)',
          icon: (
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          ),
        }
    }
  }

  const config = getTypeConfig()

  return (
    <div
      className="flex items-start gap-3 p-4 rounded-xl animate-in slide-in-from-top-2 fade-in duration-200"
      style={{
        background: colors.cardBackground,
        backdropFilter: 'blur(20px)',
        border: `1px solid ${colors.cardBorder}`,
        borderLeft: `4px solid ${config.color}`,
        boxShadow: `0 8px 32px ${colors.glassShadow}`,
        minWidth: '320px',
        maxWidth: '400px',
      }}
    >
      <div
        className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
        style={{ background: config.bgColor }}
      >
        <span style={{ color: config.color }}>{config.icon}</span>
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold" style={{ color: colors.textPrimary }}>
          {notification.title}
        </p>
        {notification.message && (
          <p className="text-sm mt-0.5" style={{ color: colors.textSecondary }}>
            {notification.message}
          </p>
        )}
      </div>
      <button
        onClick={onDismiss}
        className="p-1 rounded-lg transition-all hover:scale-105 flex-shrink-0"
        style={{ background: colors.chipBg, color: colors.textTertiary }}
      >
        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  )
}

/**
 * Notification Provider
 * Wrap your app with this to enable notifications
 */
export const FANotificationProvider = ({ children }: { children: ReactNode }) => {
  const [notifications, setNotifications] = useState<Notification[]>([])

  const notify = useCallback((notification: Omit<Notification, 'id'>) => {
    const id = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    setNotifications((prev) => [...prev, { ...notification, id }])
  }, [])

  const dismiss = useCallback((id: string) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id))
  }, [])

  const success = useCallback((title: string, message?: string) => {
    notify({ type: 'success', title, message })
  }, [notify])

  const error = useCallback((title: string, message?: string) => {
    notify({ type: 'error', title, message })
  }, [notify])

  const warning = useCallback((title: string, message?: string) => {
    notify({ type: 'warning', title, message })
  }, [notify])

  const info = useCallback((title: string, message?: string) => {
    notify({ type: 'info', title, message })
  }, [notify])

  return (
    <NotificationContext.Provider value={{ notify, success, error, warning, info, dismiss }}>
      {children}
      {/* Toast Container */}
      <div className="fixed top-4 right-4 z-[100] flex flex-col gap-3">
        {notifications.map((notification) => (
          <Toast
            key={notification.id}
            notification={notification}
            onDismiss={() => dismiss(notification.id)}
          />
        ))}
      </div>
    </NotificationContext.Provider>
  )
}

export default FANotificationProvider
