import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Head from 'next/head'
import { useAuth } from '@/context/AuthContext'

// FA Theme Colors - Main Design (Blue/Cyan)
const COLORS = {
  light: {
    primary: '#3B82F6',
    primaryDark: '#2563EB',
    background: '#FFFFFF',
    cardBg: 'rgba(255, 255, 255, 0.95)',
    glassBorder: 'rgba(59, 130, 246, 0.15)',
    textPrimary: '#1E293B',
    textSecondary: '#64748B',
    inputBg: 'rgba(59, 130, 246, 0.04)',
    inputBorder: 'rgba(59, 130, 246, 0.15)',
    error: '#EF4444',
  },
  dark: {
    primary: '#93C5FD',
    primaryDark: '#60A5FA',
    background: '#0B1120',
    cardBg: 'rgba(17, 24, 39, 0.85)',
    glassBorder: 'rgba(147, 197, 253, 0.2)',
    textPrimary: '#F8FAFC',
    textSecondary: '#94A3B8',
    inputBg: 'rgba(147, 197, 253, 0.08)',
    inputBorder: 'rgba(147, 197, 253, 0.2)',
    error: '#F87171',
  },
}

export default function AdvisorLoginPage() {
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
      router.replace('/advisor/dashboard')
    }
  }, [isAuthenticated, isLoading])

  const colors = isDark ? COLORS.dark : COLORS.light

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setSubmitting(true)

    try {
      await login(email, password)
      router.push('/advisor/dashboard')
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
        style={{ background: colors.background }}
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
        <title>Advisor Login | Sparrow Invest</title>
      </Head>
      <div
        className="min-h-screen flex items-center justify-center p-4"
        style={{
          background: `linear-gradient(135deg, ${colors.background} 0%, ${isDark ? '#111827' : '#F8FAFC'} 100%)`,
        }}
      >
        {/* Login Card */}
        <div
          className="w-full max-w-md p-8 rounded-2xl"
          style={{
            background: colors.cardBg,
            backdropFilter: 'blur(50px) saturate(180%)',
            WebkitBackdropFilter: 'blur(50px) saturate(180%)',
            border: `1px solid ${colors.glassBorder}`,
            boxShadow: isDark
              ? '0 25px 50px rgba(0, 0, 0, 0.5)'
              : '0 25px 50px rgba(59, 130, 246, 0.1)',
          }}
        >
          {/* Logo */}
          <div className="flex flex-col items-center mb-8">
            <div
              className="w-16 h-16 rounded-2xl flex items-center justify-center text-white mb-4"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                boxShadow: `0 8px 24px rgba(59, 130, 246, 0.3)`,
              }}
            >
              <svg viewBox="0 0 24 24" className="w-9 h-9" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path strokeLinecap="round" d="M17 5H9a4 4 0 000 8h6a4 4 0 010 8H7"/>
              </svg>
            </div>
            <h1 className="text-2xl font-bold" style={{ color: colors.textPrimary }}>
              Sparrow Invest
            </h1>
            <p className="text-sm mt-1" style={{ color: colors.primary }}>
              Financial Advisor Portal
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
                className="w-full h-12 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{
                  background: isDark ? colors.inputBg : '#FFFFFF',
                  border: `1px solid ${colors.inputBorder}`,
                  color: colors.textPrimary,
                }}
                placeholder="advisor@sparrowinvest.com"
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
                className="w-full h-12 px-4 rounded-xl text-sm transition-all focus:outline-none"
                style={{
                  background: isDark ? colors.inputBg : '#FFFFFF',
                  border: `1px solid ${colors.inputBorder}`,
                  color: colors.textPrimary,
                }}
                placeholder="Enter your password"
                required
              />
            </div>

            {/* Error Message */}
            {error && (
              <div
                className="p-3 rounded-xl text-sm"
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
              className="w-full h-12 rounded-full text-white font-semibold text-sm transition-all hover:shadow-lg disabled:opacity-60"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                boxShadow: `0 4px 14px rgba(59, 130, 246, 0.3)`,
              }}
            >
              {submitting ? 'Signing In...' : 'Sign In to Advisor Portal'}
            </button>
          </form>

          {/* Footer */}
          <p className="text-center text-xs mt-6" style={{ color: colors.textSecondary }}>
            Secure access for financial advisors
          </p>
        </div>
      </div>
    </>
  )
}
