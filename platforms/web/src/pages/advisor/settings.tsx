/**
 * Advisor Settings Page
 *
 * Manage advisor profile, preferences, and account settings.
 * Includes: Profile info, Notifications, Display, Security
 */

import { useState } from 'react'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatDate } from '@/utils/fa'
import { AdvisorProfile, AdvisorPreferences, ReportFormat } from '@/utils/faTypes'
import {
  FACard,
  FALabel,
  FAInput,
  FATextarea,
  FASelect,
  FAButton,
  FACheckbox,
} from '@/components/advisor/shared'

// Settings tabs
type SettingsTab = 'profile' | 'notifications' | 'display' | 'security'

// Mock advisor data
const mockAdvisor: AdvisorProfile = {
  id: 'adv1',
  name: 'Rajesh Kumar',
  email: 'rajesh.kumar@sparrowinvest.com',
  phone: '+91 98765 43210',
  arn: 'ARN-123456',
  euin: 'E123456',
  firmName: 'Sparrow Wealth Advisors',
  address: '123 Financial District, Bandra Kurla Complex',
  city: 'Mumbai',
  state: 'Maharashtra',
  pincode: '400051',
  photoUrl: '',
  joinedDate: '2020-03-15',
}

const mockPreferences: AdvisorPreferences = {
  theme: 'system',
  defaultReportFormat: 'PDF',
  emailNotifications: true,
  smsNotifications: true,
  sipReminders: true,
  goalAlerts: true,
  marketAlerts: false,
  dashboardWidgets: ['kpi', 'pending-actions', 'recent-transactions', 'insights'],
}

const DASHBOARD_WIDGETS = [
  { id: 'kpi', label: 'Key Metrics', description: 'AUM, clients, and growth stats' },
  { id: 'pending-actions', label: 'Pending Actions', description: 'Tasks requiring attention' },
  { id: 'recent-transactions', label: 'Recent Transactions', description: 'Latest client transactions' },
  { id: 'insights', label: 'AI Insights', description: 'Smart recommendations and alerts' },
  { id: 'top-clients', label: 'Top Clients', description: 'Highest AUM clients' },
  { id: 'upcoming-sips', label: 'Upcoming SIPs', description: 'SIPs scheduled this week' },
  { id: 'goal-progress', label: 'Goal Progress', description: 'Client goal tracking' },
  { id: 'market-summary', label: 'Market Summary', description: 'Index and sector performance' },
]

const SettingsPage = () => {
  const { colors, isDark } = useFATheme()
  const [activeTab, setActiveTab] = useState<SettingsTab>('profile')
  const [profile, setProfile] = useState<AdvisorProfile>(mockAdvisor)
  const [preferences, setPreferences] = useState<AdvisorPreferences>(mockPreferences)
  const [isSaving, setIsSaving] = useState(false)
  const [savedMessage, setSavedMessage] = useState('')

  // Security state
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')

  const tabs: { id: SettingsTab; label: string; icon: string }[] = [
    { id: 'profile', label: 'Profile', icon: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z' },
    { id: 'notifications', label: 'Notifications', icon: 'M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9' },
    { id: 'display', label: 'Display', icon: 'M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z' },
    { id: 'security', label: 'Security', icon: 'M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z' },
  ]

  const handleSave = async () => {
    setIsSaving(true)
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000))
    setIsSaving(false)
    setSavedMessage('Settings saved successfully!')
    setTimeout(() => setSavedMessage(''), 3000)
  }

  const toggleWidget = (widgetId: string) => {
    setPreferences(prev => ({
      ...prev,
      dashboardWidgets: prev.dashboardWidgets.includes(widgetId)
        ? prev.dashboardWidgets.filter(w => w !== widgetId)
        : [...prev.dashboardWidgets, widgetId]
    }))
  }

  return (
    <AdvisorLayout title="Settings">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <p className="text-sm" style={{ color: colors.textSecondary }}>Manage your account and preferences</p>
          </div>
          {savedMessage && (
            <div
              className="flex items-center gap-2 px-4 py-2 rounded-full"
              style={{ background: `${colors.success}15`, color: colors.success }}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
              </svg>
              <span className="text-sm font-medium">{savedMessage}</span>
            </div>
          )}
        </div>

        <div className="flex gap-6">
          {/* Sidebar Navigation */}
          <div className="w-64 flex-shrink-0">
            <FACard className="sticky top-4">
              <nav className="space-y-1">
                {tabs.map(tab => (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id)}
                    className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all"
                    style={{
                      background: activeTab === tab.id ? `${colors.primary}15` : 'transparent',
                      color: activeTab === tab.id ? colors.primary : colors.textSecondary,
                    }}
                  >
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d={tab.icon} />
                    </svg>
                    {tab.label}
                  </button>
                ))}
              </nav>
            </FACard>
          </div>

          {/* Main Content */}
          <div className="flex-1 space-y-6">
            {/* Profile Tab */}
            {activeTab === 'profile' && (
              <>
                {/* Personal Information */}
                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.primary}15`, color: colors.primary }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Personal Information</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Update your personal details</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <FALabel>Full Name</FALabel>
                      <FAInput
                        value={profile.name}
                        onChange={(e) => setProfile({ ...profile, name: e.target.value })}
                      />
                    </div>
                    <div>
                      <FALabel>Email Address</FALabel>
                      <FAInput
                        type="email"
                        value={profile.email}
                        onChange={(e) => setProfile({ ...profile, email: e.target.value })}
                      />
                    </div>
                    <div>
                      <FALabel>Phone Number</FALabel>
                      <FAInput
                        type="tel"
                        value={profile.phone}
                        onChange={(e) => setProfile({ ...profile, phone: e.target.value })}
                      />
                    </div>
                    <div>
                      <FALabel>Member Since</FALabel>
                      <FAInput
                        value={formatDate(profile.joinedDate)}
                        disabled
                      />
                    </div>
                  </div>
                </FACard>

                {/* Professional Details */}
                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.secondary}15`, color: colors.secondary }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Professional Details</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Your AMFI registration information</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <FALabel>ARN Number</FALabel>
                      <FAInput
                        value={profile.arn}
                        onChange={(e) => setProfile({ ...profile, arn: e.target.value })}
                        placeholder="ARN-XXXXXX"
                      />
                    </div>
                    <div>
                      <FALabel>EUIN</FALabel>
                      <FAInput
                        value={profile.euin}
                        onChange={(e) => setProfile({ ...profile, euin: e.target.value })}
                        placeholder="EXXXXXX"
                      />
                    </div>
                    <div className="col-span-2">
                      <FALabel>Firm Name</FALabel>
                      <FAInput
                        value={profile.firmName || ''}
                        onChange={(e) => setProfile({ ...profile, firmName: e.target.value })}
                        placeholder="Your firm or company name"
                      />
                    </div>
                  </div>
                </FACard>

                {/* Address */}
                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.warning}15`, color: colors.warning }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Business Address</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Your office or business location</p>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div>
                      <FALabel>Street Address</FALabel>
                      <FAInput
                        value={profile.address || ''}
                        onChange={(e) => setProfile({ ...profile, address: e.target.value })}
                        placeholder="Enter your street address"
                      />
                    </div>
                    <div className="grid grid-cols-3 gap-4">
                      <div>
                        <FALabel>City</FALabel>
                        <FAInput
                          value={profile.city || ''}
                          onChange={(e) => setProfile({ ...profile, city: e.target.value })}
                        />
                      </div>
                      <div>
                        <FALabel>State</FALabel>
                        <FAInput
                          value={profile.state || ''}
                          onChange={(e) => setProfile({ ...profile, state: e.target.value })}
                        />
                      </div>
                      <div>
                        <FALabel>Pincode</FALabel>
                        <FAInput
                          value={profile.pincode || ''}
                          onChange={(e) => setProfile({ ...profile, pincode: e.target.value })}
                          maxLength={6}
                        />
                      </div>
                    </div>
                  </div>
                </FACard>

                {/* Save Button */}
                <div className="flex justify-end">
                  <FAButton onClick={handleSave} disabled={isSaving}>
                    {isSaving ? 'Saving...' : 'Save Profile'}
                  </FAButton>
                </div>
              </>
            )}

            {/* Notifications Tab */}
            {activeTab === 'notifications' && (
              <>
                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.primary}15`, color: colors.primary }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Notification Channels</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Choose how you want to be notified</p>
                    </div>
                  </div>

                  <div className="space-y-4">
                    <div
                      className="p-4 rounded-xl flex items-center justify-between"
                      style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className="w-10 h-10 rounded-lg flex items-center justify-center"
                          style={{ background: `${colors.primary}15`, color: colors.primary }}
                        >
                          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                          </svg>
                        </div>
                        <div>
                          <p className="font-medium" style={{ color: colors.textPrimary }}>Email Notifications</p>
                          <p className="text-sm" style={{ color: colors.textSecondary }}>Receive updates via email</p>
                        </div>
                      </div>
                      <button
                        onClick={() => setPreferences({ ...preferences, emailNotifications: !preferences.emailNotifications })}
                        className="w-12 h-6 rounded-full relative transition-all"
                        style={{
                          background: preferences.emailNotifications
                            ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                            : colors.chipBg,
                          border: `1px solid ${preferences.emailNotifications ? 'transparent' : colors.cardBorder}`,
                        }}
                      >
                        <div
                          className="w-5 h-5 rounded-full absolute top-0.5 transition-all shadow"
                          style={{
                            background: 'white',
                            left: preferences.emailNotifications ? '26px' : '2px',
                          }}
                        />
                      </button>
                    </div>

                    <div
                      className="p-4 rounded-xl flex items-center justify-between"
                      style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className="w-10 h-10 rounded-lg flex items-center justify-center"
                          style={{ background: `${colors.secondary}15`, color: colors.secondary }}
                        >
                          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                          </svg>
                        </div>
                        <div>
                          <p className="font-medium" style={{ color: colors.textPrimary }}>SMS Notifications</p>
                          <p className="text-sm" style={{ color: colors.textSecondary }}>Receive updates via SMS</p>
                        </div>
                      </div>
                      <button
                        onClick={() => setPreferences({ ...preferences, smsNotifications: !preferences.smsNotifications })}
                        className="w-12 h-6 rounded-full relative transition-all"
                        style={{
                          background: preferences.smsNotifications
                            ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                            : colors.chipBg,
                          border: `1px solid ${preferences.smsNotifications ? 'transparent' : colors.cardBorder}`,
                        }}
                      >
                        <div
                          className="w-5 h-5 rounded-full absolute top-0.5 transition-all shadow"
                          style={{
                            background: 'white',
                            left: preferences.smsNotifications ? '26px' : '2px',
                          }}
                        />
                      </button>
                    </div>
                  </div>
                </FACard>

                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.warning}15`, color: colors.warning }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Alert Types</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Choose which alerts you want to receive</p>
                    </div>
                  </div>

                  <div className="space-y-3">
                    {[
                      { key: 'sipReminders', label: 'SIP Reminders', description: 'Get notified about upcoming SIP dates' },
                      { key: 'goalAlerts', label: 'Goal Alerts', description: 'Updates on client goal progress and milestones' },
                      { key: 'marketAlerts', label: 'Market Alerts', description: 'Significant market movements and news' },
                    ].map(alert => (
                      <div
                        key={alert.key}
                        className="p-3 rounded-lg flex items-center justify-between"
                        style={{ background: colors.chipBg }}
                      >
                        <div>
                          <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{alert.label}</p>
                          <p className="text-xs" style={{ color: colors.textTertiary }}>{alert.description}</p>
                        </div>
                        <button
                          onClick={() => setPreferences({ ...preferences, [alert.key]: !preferences[alert.key as keyof AdvisorPreferences] })}
                          className="w-10 h-5 rounded-full relative transition-all"
                          style={{
                            background: preferences[alert.key as keyof AdvisorPreferences]
                              ? colors.primary
                              : colors.cardBorder,
                          }}
                        >
                          <div
                            className="w-4 h-4 rounded-full absolute top-0.5 transition-all shadow"
                            style={{
                              background: 'white',
                              left: preferences[alert.key as keyof AdvisorPreferences] ? '22px' : '2px',
                            }}
                          />
                        </button>
                      </div>
                    ))}
                  </div>
                </FACard>

                <div className="flex justify-end">
                  <FAButton onClick={handleSave} disabled={isSaving}>
                    {isSaving ? 'Saving...' : 'Save Preferences'}
                  </FAButton>
                </div>
              </>
            )}

            {/* Display Tab */}
            {activeTab === 'display' && (
              <>
                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.primary}15`, color: colors.primary }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Theme</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Choose your preferred appearance</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-3">
                    {[
                      { value: 'light', label: 'Light', icon: 'M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z' },
                      { value: 'dark', label: 'Dark', icon: 'M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z' },
                      { value: 'system', label: 'System', icon: 'M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z' },
                    ].map(theme => (
                      <button
                        key={theme.value}
                        onClick={() => setPreferences({ ...preferences, theme: theme.value as 'light' | 'dark' | 'system' })}
                        className="p-4 rounded-xl flex flex-col items-center gap-3 transition-all hover:scale-[1.02]"
                        style={{
                          background: preferences.theme === theme.value ? `${colors.primary}15` : colors.chipBg,
                          border: `2px solid ${preferences.theme === theme.value ? colors.primary : 'transparent'}`,
                        }}
                      >
                        <div
                          className="w-12 h-12 rounded-xl flex items-center justify-center"
                          style={{
                            background: preferences.theme === theme.value ? `${colors.primary}25` : colors.cardBackground,
                            color: preferences.theme === theme.value ? colors.primary : colors.textSecondary,
                          }}
                        >
                          <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d={theme.icon} />
                          </svg>
                        </div>
                        <span
                          className="text-sm font-medium"
                          style={{ color: preferences.theme === theme.value ? colors.primary : colors.textPrimary }}
                        >
                          {theme.label}
                        </span>
                      </button>
                    ))}
                  </div>
                </FACard>

                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.secondary}15`, color: colors.secondary }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Dashboard Widgets</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Customize your dashboard layout</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    {DASHBOARD_WIDGETS.map(widget => (
                      <button
                        key={widget.id}
                        onClick={() => toggleWidget(widget.id)}
                        className="p-3 rounded-xl flex items-start gap-3 text-left transition-all hover:scale-[1.01]"
                        style={{
                          background: preferences.dashboardWidgets.includes(widget.id)
                            ? `${colors.primary}10`
                            : colors.chipBg,
                          border: `1px solid ${preferences.dashboardWidgets.includes(widget.id) ? colors.primary : colors.cardBorder}`,
                        }}
                      >
                        <div
                          className="w-5 h-5 rounded flex-shrink-0 flex items-center justify-center mt-0.5"
                          style={{
                            background: preferences.dashboardWidgets.includes(widget.id) ? colors.primary : 'transparent',
                            border: `2px solid ${preferences.dashboardWidgets.includes(widget.id) ? colors.primary : colors.cardBorder}`,
                          }}
                        >
                          {preferences.dashboardWidgets.includes(widget.id) && (
                            <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                            </svg>
                          )}
                        </div>
                        <div>
                          <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{widget.label}</p>
                          <p className="text-xs" style={{ color: colors.textTertiary }}>{widget.description}</p>
                        </div>
                      </button>
                    ))}
                  </div>
                </FACard>

                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.warning}15`, color: colors.warning }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Report Preferences</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Default format for generated reports</p>
                    </div>
                  </div>

                  <div>
                    <FALabel>Default Report Format</FALabel>
                    <FASelect
                      options={[
                        { value: 'PDF', label: 'PDF Document' },
                        { value: 'Excel', label: 'Excel Spreadsheet' },
                        { value: 'CSV', label: 'CSV File' },
                      ]}
                      value={preferences.defaultReportFormat}
                      onChange={(e) => setPreferences({ ...preferences, defaultReportFormat: e.target.value as ReportFormat })}
                      containerClassName="max-w-xs"
                    />
                  </div>
                </FACard>

                <div className="flex justify-end">
                  <FAButton onClick={handleSave} disabled={isSaving}>
                    {isSaving ? 'Saving...' : 'Save Display Settings'}
                  </FAButton>
                </div>
              </>
            )}

            {/* Security Tab */}
            {activeTab === 'security' && (
              <>
                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.primary}15`, color: colors.primary }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Change Password</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Update your account password</p>
                    </div>
                  </div>

                  <div className="space-y-4 max-w-md">
                    <div>
                      <FALabel>Current Password</FALabel>
                      <FAInput
                        type="password"
                        value={currentPassword}
                        onChange={(e) => setCurrentPassword(e.target.value)}
                        placeholder="Enter current password"
                      />
                    </div>
                    <div>
                      <FALabel>New Password</FALabel>
                      <FAInput
                        type="password"
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        placeholder="Enter new password"
                      />
                    </div>
                    <div>
                      <FALabel>Confirm New Password</FALabel>
                      <FAInput
                        type="password"
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        placeholder="Confirm new password"
                      />
                    </div>
                    <FAButton
                      onClick={() => {
                        // Password change logic would go here
                        setCurrentPassword('')
                        setNewPassword('')
                        setConfirmPassword('')
                        setSavedMessage('Password updated successfully!')
                        setTimeout(() => setSavedMessage(''), 3000)
                      }}
                      disabled={!currentPassword || !newPassword || newPassword !== confirmPassword}
                    >
                      Update Password
                    </FAButton>
                  </div>
                </FACard>

                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.success}15`, color: colors.success }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Two-Factor Authentication</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Add an extra layer of security</p>
                    </div>
                  </div>

                  <div
                    className="p-4 rounded-xl flex items-center justify-between"
                    style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className="w-10 h-10 rounded-lg flex items-center justify-center"
                        style={{ background: `${colors.success}15`, color: colors.success }}
                      >
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" />
                        </svg>
                      </div>
                      <div>
                        <p className="font-medium" style={{ color: colors.textPrimary }}>Authenticator App</p>
                        <p className="text-sm" style={{ color: colors.success }}>Enabled</p>
                      </div>
                    </div>
                    <button
                      className="px-4 py-2 rounded-full text-sm font-semibold transition-all"
                      style={{
                        background: colors.chipBg,
                        color: colors.textPrimary,
                        border: `1px solid ${colors.cardBorder}`,
                      }}
                    >
                      Configure
                    </button>
                  </div>
                </FACard>

                <FACard>
                  <div className="flex items-center gap-3 mb-6">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.secondary}15`, color: colors.secondary }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>Active Sessions</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Manage your logged-in devices</p>
                    </div>
                  </div>

                  <div className="space-y-3">
                    {[
                      { device: 'MacBook Pro', location: 'Mumbai, India', time: 'Current session', current: true },
                      { device: 'iPhone 15 Pro', location: 'Mumbai, India', time: '2 hours ago', current: false },
                      { device: 'Chrome on Windows', location: 'Bangalore, India', time: '3 days ago', current: false },
                    ].map((session, i) => (
                      <div
                        key={i}
                        className="p-3 rounded-lg flex items-center justify-between"
                        style={{ background: colors.chipBg }}
                      >
                        <div className="flex items-center gap-3">
                          <div
                            className="w-10 h-10 rounded-lg flex items-center justify-center"
                            style={{ background: colors.cardBackground, color: colors.textSecondary }}
                          >
                            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                              <path strokeLinecap="round" strokeLinejoin="round" d={session.device.includes('iPhone') ? 'M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z' : 'M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z'} />
                            </svg>
                          </div>
                          <div>
                            <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                              {session.device}
                              {session.current && (
                                <span
                                  className="ml-2 text-xs px-2 py-0.5 rounded-full"
                                  style={{ background: `${colors.success}15`, color: colors.success }}
                                >
                                  Current
                                </span>
                              )}
                            </p>
                            <p className="text-xs" style={{ color: colors.textTertiary }}>
                              {session.location} · {session.time}
                            </p>
                          </div>
                        </div>
                        {!session.current && (
                          <button
                            className="text-sm font-medium transition-all hover:underline"
                            style={{ color: colors.error }}
                          >
                            Revoke
                          </button>
                        )}
                      </div>
                    ))}
                  </div>
                </FACard>

                <FACard>
                  <div className="flex items-center gap-3 mb-4">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center"
                      style={{ background: `${colors.error}15`, color: colors.error }}
                    >
                      <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                      </svg>
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.error }}>Danger Zone</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>Irreversible account actions</p>
                    </div>
                  </div>

                  <button
                    className="px-4 py-2 rounded-full text-sm font-semibold transition-all"
                    style={{
                      background: `${colors.error}15`,
                      color: colors.error,
                      border: `1px solid ${colors.error}30`,
                    }}
                  >
                    Delete Account
                  </button>
                </FACard>
              </>
            )}
          </div>
        </div>
      </div>
    </AdvisorLayout>
  )
}

export default SettingsPage
