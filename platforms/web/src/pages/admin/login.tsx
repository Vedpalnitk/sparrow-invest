import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Head from 'next/head'
import { useAuth } from '@/context/AuthContext'

// Cyan & Slate Theme Colors
const COLORS = {
  light: {
    primary: '#06B6D4',
    primaryDark: '#0891B2',
    primaryLight: '#22D3EE',
    background: '#F8FAFC',
    cardBg: 'rgba(255, 255, 255, 0.95)',
    glassBorder: 'rgba(6, 182, 212, 0.15)',
    textPrimary: '#0F172A',
    textSecondary: '#475569',
    textTertiary: '#94A3B8',
    inputBg: 'rgba(6, 182, 212, 0.04)',
    inputBorder: 'rgba(6, 182, 212, 0.15)',
    error: '#EF4444',
  },
  dark: {
    primary: '#22D3EE',
    primaryDark: '#06B6D4',
    primaryLight: '#67E8F9',
    background: '#0F172A',
    cardBg: 'rgba(30, 41, 59, 0.95)',
    glassBorder: 'rgba(34, 211, 238, 0.15)',
    textPrimary: '#F1F5F9',
    textSecondary: '#CBD5E1',
    textTertiary: '#94A3B8',
    inputBg: 'rgba(34, 211, 238, 0.08)',
    inputBorder: 'rgba(34, 211, 238, 0.15)',
    error: '#F87171',
  },
}

export default function AdminLoginPage() {
  const router = useRouter()
  const { login, isAuthenticated, isLoading } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [isDark, setIsDark] = useState(false)

  // Detect dark mode
  useEffect(() => {
    const checkDark = () => setIsDark(document.documentElement.classList.contains('dark'))
    checkDark()
    const observer = new MutationObserver(checkDark)
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] })
    return () => observer.disconnect()
  }, [])

  // Redirect if already authenticated
  useEffect(() => {
    if (!isLoading && isAuthenticated) {
      router.push('/admin/dashboard')
    }
  }, [isAuthenticated, isLoading, router])

  const colors = isDark ? COLORS.dark : COLORS.light

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSubmitting(true)

    try {
      await login(email, password)
      router.push('/admin/dashboard')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Invalid credentials')
    } finally {
      setSubmitting(false)
    }
  }

  if (isLoading) {
    return (
      <div
        className="min-h-screen flex items-center justify-center"
        style={{
          background: colors.background,
          fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif",
        }}
      >
        <div
          className="w-8 h-8 border-2 rounded-full animate-spin"
          style={{ borderColor: colors.primary, borderTopColor: 'transparent' }}
        />
      </div>
    )
  }

  return (
    <>
      <Head>
        <title>Admin Login | Sparrow Invest</title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
      </Head>
      <div
        className="min-h-screen flex items-center justify-center p-4"
        style={{
          background: isDark
            ? `linear-gradient(135deg, ${colors.background} 0%, #020617 100%)`
            : `linear-gradient(135deg, ${colors.background} 0%, #E2E8F0 100%)`,
          fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif",
        }}
      >
        {/* Decorative elements */}
        <div
          className="absolute top-20 left-20 w-64 h-64 rounded-full opacity-20 blur-3xl"
          style={{ background: colors.primary }}
        />
        <div
          className="absolute bottom-20 right-20 w-80 h-80 rounded-full opacity-15 blur-3xl"
          style={{ background: colors.primaryLight }}
        />

        {/* Login Card */}
        <div
          className="relative w-full max-w-md p-8 rounded-2xl"
          style={{
            background: colors.cardBg,
            backdropFilter: 'blur(50px) saturate(180%)',
            WebkitBackdropFilter: 'blur(50px) saturate(180%)',
            border: `1px solid ${colors.glassBorder}`,
            boxShadow: isDark
              ? '0 25px 50px rgba(0, 0, 0, 0.5)'
              : '0 25px 50px rgba(6, 182, 212, 0.12)',
          }}
        >
          {/* Logo */}
          <div className="flex flex-col items-center mb-8">
            <div
              className="w-16 h-16 rounded-2xl flex items-center justify-center text-white mb-4"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryLight} 100%)`,
                boxShadow: `0 8px 24px ${colors.primary}40`,
              }}
            >
              <svg viewBox="0 0 24 24" className="w-8 h-8" fill="none" stroke="currentColor" strokeWidth="2">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 3c-4 0-7 3-7 7 0 5 7 11 7 11s7-6 7-11c0-4-3-7-7-7z" />
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 7v6" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
              Sparrow Invest
            </h1>
            <p className="text-sm font-medium mt-1" style={{ color: colors.primary }}>
              Admin Portal
            </p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email */}
            <div>
              <label
                className="block text-xs font-semibold uppercase tracking-wide mb-1.5"
                style={{ color: colors.primary }}
              >
                Email
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full h-12 px-4 rounded-xl text-sm transition-all focus:outline-none focus:ring-2"
                style={{
                  background: colors.inputBg,
                  border: `1px solid ${colors.inputBorder}`,
                  color: colors.textPrimary,
                  // @ts-ignore
                  '--tw-ring-color': `${colors.primary}40`,
                }}
                placeholder="admin@sparrowinvest.com"
                required
              />
            </div>

            {/* Password */}
            <div>
              <label
                className="block text-xs font-semibold uppercase tracking-wide mb-1.5"
                style={{ color: colors.primary }}
              >
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full h-12 px-4 rounded-xl text-sm transition-all focus:outline-none focus:ring-2"
                style={{
                  background: colors.inputBg,
                  border: `1px solid ${colors.inputBorder}`,
                  color: colors.textPrimary,
                  // @ts-ignore
                  '--tw-ring-color': `${colors.primary}40`,
                }}
                placeholder="Enter your password"
                required
              />
            </div>

            {/* Error Message */}
            {error && (
              <div
                className="p-3 rounded-xl text-sm font-medium"
                style={{
                  background: `${colors.error}15`,
                  color: colors.error,
                  border: `1px solid ${colors.error}30`,
                }}
              >
                {error}
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={submitting}
              className="w-full h-12 rounded-xl text-white font-semibold text-sm transition-all hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:transform-none"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryLight} 100%)`,
                boxShadow: `0 4px 14px ${colors.primary}30`,
              }}
            >
              {submitting ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Signing In...
                </span>
              ) : (
                'Sign In to Admin Portal'
              )}
            </button>
          </form>

          {/* Demo credentials hint */}
          <div
            className="mt-6 p-3 rounded-xl"
            style={{
              background: `${colors.primary}08`,
              border: `1px solid ${colors.primary}15`,
            }}
          >
            <p className="text-xs font-medium text-center" style={{ color: colors.textSecondary }}>
              Demo: <span style={{ color: colors.primary }}>admin@sparrowinvest.com</span> / <span style={{ color: colors.primary }}>Admin@123</span>
            </p>
          </div>

          {/* Footer */}
          <p className="text-center text-xs mt-5" style={{ color: colors.textTertiary }}>
            Secure access for administrators only
          </p>
        </div>
      </div>
    </>
  )
}
