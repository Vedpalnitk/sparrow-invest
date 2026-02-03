/**
 * Notification Center Component
 *
 * Displays alerts, reminders, and important notifications for the advisor.
 * Includes bell icon with badge and dropdown panel.
 */

import { useState, useRef, useEffect } from 'react'
import Link from 'next/link'

interface Notification {
  id: string
  type: 'sip' | 'goal' | 'kyc' | 'transaction' | 'market' | 'system'
  title: string
  message: string
  timestamp: string
  read: boolean
  actionUrl?: string
  clientName?: string
  severity?: 'info' | 'warning' | 'error' | 'success'
}

// Mock notifications
const MOCK_NOTIFICATIONS: Notification[] = [
  {
    id: '1',
    type: 'sip',
    title: 'SIP Failed',
    message: 'SIP for Rajesh Sharma failed due to insufficient funds',
    timestamp: '2024-01-20T10:30:00',
    read: false,
    actionUrl: '/advisor/sips',
    clientName: 'Rajesh Sharma',
    severity: 'error',
  },
  {
    id: '2',
    type: 'goal',
    title: 'Goal Milestone Reached',
    message: 'Priya Patel has reached 75% of her Retirement goal',
    timestamp: '2024-01-20T09:15:00',
    read: false,
    actionUrl: '/advisor/goals',
    clientName: 'Priya Patel',
    severity: 'success',
  },
  {
    id: '3',
    type: 'kyc',
    title: 'KYC Expiring Soon',
    message: 'KYC for Amit Kumar expires in 15 days',
    timestamp: '2024-01-19T16:45:00',
    read: false,
    actionUrl: '/advisor/clients/c3',
    clientName: 'Amit Kumar',
    severity: 'warning',
  },
  {
    id: '4',
    type: 'transaction',
    title: 'Large Transaction Alert',
    message: 'Redemption of ₹5L processed for Sneha Gupta',
    timestamp: '2024-01-19T14:20:00',
    read: true,
    actionUrl: '/advisor/transactions',
    clientName: 'Sneha Gupta',
    severity: 'info',
  },
  {
    id: '5',
    type: 'market',
    title: 'Market Alert',
    message: 'Nifty 50 down 2.5% - Consider reviewing client portfolios',
    timestamp: '2024-01-19T11:00:00',
    read: true,
    severity: 'warning',
  },
  {
    id: '6',
    type: 'system',
    title: 'New Feature',
    message: 'Fund Comparison tool is now available',
    timestamp: '2024-01-18T09:00:00',
    read: true,
    actionUrl: '/advisor/compare',
    severity: 'info',
  },
  {
    id: '7',
    type: 'sip',
    title: 'Upcoming SIPs',
    message: '8 SIPs scheduled for tomorrow',
    timestamp: '2024-01-20T08:00:00',
    read: false,
    actionUrl: '/advisor/sips',
    severity: 'info',
  },
]

interface NotificationCenterProps {
  colors: {
    primary: string
    primaryDark: string
    success: string
    warning: string
    error: string
    textPrimary: string
    textSecondary: string
    textTertiary: string
    cardBg: string
    cardBorder: string
    chipBg: string
    glassShadow: string
  }
}

const NotificationCenter = ({ colors }: NotificationCenterProps) => {
  const [isOpen, setIsOpen] = useState(false)
  const [notifications, setNotifications] = useState<Notification[]>(MOCK_NOTIFICATIONS)
  const dropdownRef = useRef<HTMLDivElement>(null)

  const unreadCount = notifications.filter(n => !n.read).length

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const markAsRead = (id: string) => {
    setNotifications(prev =>
      prev.map(n => n.id === id ? { ...n, read: true } : n)
    )
  }

  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })))
  }

  const getTypeIcon = (type: Notification['type']) => {
    const icons: Record<Notification['type'], string> = {
      sip: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15',
      goal: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z',
      kyc: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
      transaction: 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
      market: 'M13 7h8m0 0v8m0-8l-8 8-4-4-6 6',
      system: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    }
    return icons[type]
  }

  const getSeverityColor = (severity?: Notification['severity']) => {
    switch (severity) {
      case 'error': return colors.error
      case 'warning': return colors.warning
      case 'success': return colors.success
      default: return colors.primary
    }
  }

  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp)
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const minutes = Math.floor(diff / 60000)
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)

    if (minutes < 60) return `${minutes}m ago`
    if (hours < 24) return `${hours}h ago`
    if (days < 7) return `${days}d ago`
    return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
  }

  return (
    <div className="relative" ref={dropdownRef}>
      {/* Bell Icon Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="relative p-2 rounded-lg transition-all hover:scale-105"
        style={{
          background: isOpen ? colors.chipBg : 'transparent',
          color: colors.textSecondary,
        }}
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
        </svg>
        {unreadCount > 0 && (
          <span
            className="absolute -top-0.5 -right-0.5 w-5 h-5 rounded-full text-xs font-bold flex items-center justify-center text-white"
            style={{ background: colors.error }}
          >
            {unreadCount > 9 ? '9+' : unreadCount}
          </span>
        )}
      </button>

      {/* Dropdown Panel */}
      {isOpen && (
        <div
          className="absolute right-0 top-full mt-2 w-96 rounded-2xl overflow-hidden z-50"
          style={{
            background: colors.cardBg,
            border: `1px solid ${colors.cardBorder}`,
            boxShadow: `0 20px 40px ${colors.glassShadow}`,
          }}
        >
          {/* Header */}
          <div
            className="p-4 flex items-center justify-between"
            style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
          >
            <div>
              <h3 className="font-semibold" style={{ color: colors.textPrimary }}>
                Notifications
              </h3>
              <p className="text-xs" style={{ color: colors.textTertiary }}>
                {unreadCount} unread
              </p>
            </div>
            {unreadCount > 0 && (
              <button
                onClick={markAllAsRead}
                className="text-xs font-medium transition-all hover:underline"
                style={{ color: colors.primary }}
              >
                Mark all as read
              </button>
            )}
          </div>

          {/* Notifications List */}
          <div className="max-h-96 overflow-y-auto">
            {notifications.length === 0 ? (
              <div className="p-8 text-center">
                <div
                  className="w-12 h-12 rounded-xl mx-auto mb-3 flex items-center justify-center"
                  style={{ background: colors.chipBg, color: colors.textTertiary }}
                >
                  <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
                  </svg>
                </div>
                <p className="text-sm" style={{ color: colors.textSecondary }}>
                  No notifications
                </p>
              </div>
            ) : (
              notifications.map((notification, i) => {
                const severityColor = getSeverityColor(notification.severity)
                const content = (
                  <div
                    className={`p-4 transition-all hover:bg-opacity-50 cursor-pointer ${!notification.read ? 'bg-opacity-100' : ''}`}
                    style={{
                      background: !notification.read ? `${colors.primary}05` : 'transparent',
                      borderBottom: i < notifications.length - 1 ? `1px solid ${colors.cardBorder}` : undefined,
                    }}
                    onClick={() => markAsRead(notification.id)}
                  >
                    <div className="flex gap-3">
                      <div
                        className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
                        style={{ background: `${severityColor}15`, color: severityColor }}
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d={getTypeIcon(notification.type)} />
                        </svg>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <p
                            className={`text-sm ${!notification.read ? 'font-semibold' : 'font-medium'}`}
                            style={{ color: colors.textPrimary }}
                          >
                            {notification.title}
                          </p>
                          {!notification.read && (
                            <div
                              className="w-2 h-2 rounded-full flex-shrink-0 mt-1.5"
                              style={{ background: colors.primary }}
                            />
                          )}
                        </div>
                        <p className="text-xs mt-0.5 line-clamp-2" style={{ color: colors.textSecondary }}>
                          {notification.message}
                        </p>
                        <div className="flex items-center gap-2 mt-1.5">
                          {notification.clientName && (
                            <span
                              className="text-xs px-1.5 py-0.5 rounded"
                              style={{ background: colors.chipBg, color: colors.textTertiary }}
                            >
                              {notification.clientName}
                            </span>
                          )}
                          <span className="text-xs" style={{ color: colors.textTertiary }}>
                            {formatTime(notification.timestamp)}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                )

                return notification.actionUrl ? (
                  <Link key={notification.id} href={notification.actionUrl} onClick={() => setIsOpen(false)}>
                    {content}
                  </Link>
                ) : (
                  <div key={notification.id}>{content}</div>
                )
              })
            )}
          </div>

          {/* Footer */}
          <div
            className="p-3"
            style={{ borderTop: `1px solid ${colors.cardBorder}` }}
          >
            <Link
              href="/advisor/settings"
              className="block w-full text-center text-sm font-medium py-2 rounded-lg transition-all"
              style={{ background: colors.chipBg, color: colors.primary }}
              onClick={() => setIsOpen(false)}
            >
              Notification Settings
            </Link>
          </div>
        </div>
      )}
    </div>
  )
}

export default NotificationCenter
