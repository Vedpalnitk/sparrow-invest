import { useState, useRef, useEffect, useCallback } from 'react'
import Markdown from 'react-markdown'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { chatApi, ChatMessage } from '@/services/api'
import { useFATheme } from '@/utils/fa'

const SUGGESTED_QUESTIONS = [
  'What are the top performing funds this quarter?',
  'Show me clients with expiring KYC',
  'Summarize my portfolio performance',
  'Which SIPs need attention?',
]

const POLL_INTERVAL = 500
const MAX_POLL_ATTEMPTS = 120

const SparkleIcon = ({ size = 28, color = '#3B82F6' }: { size?: number; color?: string }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path
      d="M12 2L13.09 8.26L18 6L14.74 10.91L21 12L14.74 13.09L18 18L13.09 15.74L12 22L10.91 15.74L6 18L9.26 13.09L3 12L9.26 10.91L6 6L10.91 8.26L12 2Z"
      fill={color}
      opacity={0.9}
    />
    <path
      d="M12 2L13.09 8.26L18 6L14.74 10.91L21 12L14.74 13.09L18 18L13.09 15.74L12 22L10.91 15.74L6 18L9.26 13.09L3 12L9.26 10.91L6 6L10.91 8.26L12 2Z"
      fill={color}
      opacity={0.4}
      style={{ filter: 'blur(4px)' }}
    />
  </svg>
)

const TypingIndicator = ({ colors }: { colors: any }) => (
  <div className="flex items-start gap-3 mb-4">
    <div
      className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0"
      style={{ background: `${colors.primary}15` }}
    >
      <SparkleIcon size={16} color={colors.primary} />
    </div>
    <div
      className="px-4 py-3 rounded-2xl rounded-bl-md"
      style={{
        background: colors.cardBackground,
        border: `1px solid ${colors.cardBorder}`,
      }}
    >
      <div className="flex items-center gap-1.5">
        {[0, 1, 2].map(i => (
          <div
            key={i}
            className="w-2 h-2 rounded-full"
            style={{
              background: colors.primary,
              opacity: 0.6,
              animation: `typingDot 1.4s ease-in-out ${i * 0.2}s infinite`,
            }}
          />
        ))}
      </div>
    </div>
  </div>
)

const WelcomeCard = ({
  colors,
  isDark,
  onSuggestionClick,
}: {
  colors: any
  isDark: boolean
  onSuggestionClick: (q: string) => void
}) => (
  <div className="flex-1 flex items-center justify-center p-6">
    <div className="w-full max-w-lg">
      <div
        className="p-8 rounded-2xl text-center relative overflow-hidden"
        style={{
          background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 50%, ${colors.secondary || colors.primaryDark} 100%)`,
          boxShadow: `0 8px 32px ${isDark ? 'rgba(0,0,0,0.4)' : `${colors.primary}30`}`,
        }}
      >
        {/* Decorative circles */}
        <div
          className="absolute -top-8 -right-8 w-32 h-32 rounded-full"
          style={{ background: 'rgba(255,255,255,0.08)' }}
        />
        <div
          className="absolute -bottom-10 -left-10 w-40 h-40 rounded-full"
          style={{ background: 'rgba(255,255,255,0.05)' }}
        />

        <div className="relative z-10">
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-4" style={{ background: 'rgba(255,255,255,0.2)' }}>
            <SparkleIcon size={28} color="#FFFFFF" />
          </div>
          <h2
            className="text-2xl font-bold text-white mb-2"
            style={{ fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif" }}
          >
            Avya AI
          </h2>
          <p className="text-sm text-white/70 mb-6">Your intelligent financial assistant</p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {SUGGESTED_QUESTIONS.map((q, i) => (
              <button
                key={i}
                onClick={() => onSuggestionClick(q)}
                className="text-left px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all hover:scale-[1.02]"
                style={{
                  background: 'rgba(255,255,255,0.15)',
                  color: 'rgba(255,255,255,0.9)',
                  border: '1px solid rgba(255,255,255,0.2)',
                  backdropFilter: 'blur(8px)',
                }}
              >
                {q}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  </div>
)

const MessageBubble = ({
  message,
  colors,
  isDark,
}: {
  message: ChatMessage
  colors: any
  isDark: boolean
}) => {
  const isUser = message.role === 'user'

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'} mb-4`}>
      {!isUser && (
        <div
          className="w-8 h-8 rounded-xl flex items-center justify-center flex-shrink-0 mr-3 mt-1"
          style={{ background: `${colors.primary}15` }}
        >
          <SparkleIcon size={16} color={colors.primary} />
        </div>
      )}
      <div className={`max-w-[75%] ${isUser ? 'order-1' : ''}`}>
        <div
          className={`px-4 py-3 text-sm leading-relaxed ${
            isUser ? 'rounded-2xl rounded-br-md' : 'rounded-2xl rounded-bl-md'
          }`}
          style={
            isUser
              ? {
                  background: `linear-gradient(135deg, ${colors.primary}, ${colors.primaryDark})`,
                  color: '#FFFFFF',
                }
              : {
                  background: colors.cardBackground,
                  border: `1px solid ${colors.cardBorder}`,
                  color: colors.textPrimary,
                }
          }
        >
          {isUser ? (
            message.content
          ) : (
            <Markdown
              components={{
                p: ({ children }) => <p className="mb-2 last:mb-0">{children}</p>,
                ul: ({ children }) => <ul className="list-disc ml-4 mb-2">{children}</ul>,
                ol: ({ children }) => <ol className="list-decimal ml-4 mb-2">{children}</ol>,
                li: ({ children }) => <li className="mb-0.5">{children}</li>,
                strong: ({ children }) => <strong className="font-semibold">{children}</strong>,
                em: ({ children }) => <em className="italic" style={{ color: colors.textSecondary }}>{children}</em>,
                h3: ({ children }) => <h3 className="font-semibold text-sm mb-1">{children}</h3>,
                h4: ({ children }) => <h4 className="font-semibold text-sm mb-1">{children}</h4>,
                a: ({ href, children }) => (
                  <a href={href} target="_blank" rel="noopener noreferrer" className="underline" style={{ color: colors.primary }}>
                    {children}
                  </a>
                ),
              }}
            >
              {message.content}
            </Markdown>
          )}
        </div>
        {message.timestamp && (
          <p
            className={`text-xs mt-1 ${isUser ? 'text-right' : 'text-left'}`}
            style={{ color: colors.textTertiary }}
          >
            {message.timestamp}
          </p>
        )}
      </div>
    </div>
  )
}

const ChatPage = () => {
  const { colors, isDark } = useFATheme()
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [inputValue, setInputValue] = useState('')
  const [sending, setSending] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [sessionId, setSessionId] = useState<string | null>(null)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const scrollToBottom = useCallback(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [])

  useEffect(() => {
    scrollToBottom()
  }, [messages, sending, scrollToBottom])

  // Cleanup polling on unmount
  useEffect(() => {
    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current)
    }
  }, [])

  const formatTimestamp = () => {
    const now = new Date()
    return now.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })
  }

  const ensureSession = useCallback(async (): Promise<string> => {
    if (sessionId) return sessionId
    const session = await chatApi.createSession()
    setSessionId(session.id)
    return session.id
  }, [sessionId])

  const pollForResponse = useCallback((messageId: string) => {
    let attempts = 0

    pollingRef.current = setInterval(async () => {
      attempts++

      if (attempts > MAX_POLL_ATTEMPTS) {
        if (pollingRef.current) clearInterval(pollingRef.current)
        pollingRef.current = null
        setMessages(prev => [...prev, {
          role: 'assistant',
          content: 'Response timed out. Please try again.',
          timestamp: formatTimestamp(),
        }])
        setSending(false)
        return
      }

      try {
        const status = await chatApi.getMessageStatus(messageId)

        if (status.status === 'complete' && status.content) {
          if (pollingRef.current) clearInterval(pollingRef.current)
          pollingRef.current = null
          setMessages(prev => [...prev, {
            role: 'assistant',
            content: status.content!,
            timestamp: formatTimestamp(),
          }])
          setSending(false)
        } else if (status.status === 'error') {
          if (pollingRef.current) clearInterval(pollingRef.current)
          pollingRef.current = null
          setMessages(prev => [...prev, {
            role: 'assistant',
            content: status.error || 'Sorry, something went wrong. Please try again.',
            timestamp: formatTimestamp(),
          }])
          setSending(false)
        }
      } catch {
        // Silently retry on network errors during polling
      }
    }, POLL_INTERVAL)
  }, [])

  const handleSend = useCallback(async (text?: string) => {
    const messageText = (text || inputValue).trim()
    if (!messageText || sending) return

    setError(null)

    const userMessage: ChatMessage = {
      role: 'user',
      content: messageText,
      timestamp: formatTimestamp(),
    }

    setMessages(prev => [...prev, userMessage])
    setInputValue('')
    setSending(true)

    try {
      const currentSessionId = await ensureSession()
      const result = await chatApi.sendMessage(currentSessionId, messageText)
      pollForResponse(result.messageId)
    } catch (err: any) {
      setSending(false)
      setError(err.message || 'Failed to send message')
      setMessages(prev => [...prev, {
        role: 'assistant',
        content: 'Failed to connect to Avya. Please check your connection and try again.',
        timestamp: formatTimestamp(),
      }])
    }
  }, [inputValue, sending, ensureSession, pollForResponse])

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      handleSend()
    }
  }

  const handleNewChat = useCallback(() => {
    if (pollingRef.current) clearInterval(pollingRef.current)
    pollingRef.current = null
    setMessages([])
    setSessionId(null)
    setSending(false)
    setError(null)
  }, [])

  return (
    <AdvisorLayout title="Avya AI Chat">
      <style>{`
        @keyframes typingDot {
          0%, 60%, 100% { transform: translateY(0); opacity: 0.4; }
          30% { transform: translateY(-4px); opacity: 1; }
        }
      `}</style>

      <div
        className="flex flex-col h-[calc(100vh-8rem)]"
        style={{ background: colors.background, margin: '-2rem', padding: '0' }}
      >
        {/* Header with New Chat button */}
        {messages.length > 0 && (
          <div
            className="flex-shrink-0 px-6 py-3 flex items-center justify-end"
            style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
          >
            <button
              onClick={handleNewChat}
              className="px-4 py-1.5 rounded-full text-xs font-semibold transition-all hover:shadow-md"
              style={{
                background: colors.chipBg,
                color: colors.primary,
                border: `1px solid ${colors.chipBorder}`,
              }}
            >
              New Chat
            </button>
          </div>
        )}

        {/* Error banner */}
        {error && (
          <div
            className="mx-6 mt-3 px-4 py-2.5 rounded-xl text-xs font-medium flex items-center justify-between"
            style={{
              background: `${colors.error}10`,
              border: `1px solid ${colors.error}30`,
              color: colors.error,
            }}
          >
            <span>{error}</span>
            <button onClick={() => setError(null)} className="ml-3 opacity-60 hover:opacity-100">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        )}

        {/* Messages Area or Welcome */}
        {messages.length === 0 ? (
          <WelcomeCard colors={colors} isDark={isDark} onSuggestionClick={handleSend} />
        ) : (
          <div className="flex-1 overflow-y-auto px-6 py-4">
            {messages.map((msg, i) => (
              <MessageBubble key={i} message={msg} colors={colors} isDark={isDark} />
            ))}
            {sending && <TypingIndicator colors={colors} />}
            <div ref={messagesEndRef} />
          </div>
        )}

        {/* Input Bar */}
        <div
          className="flex-shrink-0 px-6 py-4"
          style={{
            background: isDark
              ? 'rgba(11, 17, 32, 0.85)'
              : 'rgba(255, 255, 255, 0.85)',
            backdropFilter: 'blur(20px)',
            borderTop: `1px solid ${colors.cardBorder}`,
          }}
        >
          <div className="max-w-3xl mx-auto flex items-center gap-3">
            <input
              type="text"
              value={inputValue}
              onChange={e => setInputValue(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask Avya anything about your portfolio..."
              disabled={sending}
              maxLength={5000}
              className="flex-1 h-11 px-5 rounded-full text-sm transition-all focus:outline-none disabled:opacity-50"
              style={{
                background: colors.inputBg,
                border: `1px solid ${colors.inputBorder}`,
                color: colors.textPrimary,
                fontFamily: "'Plus Jakarta Sans', system-ui, -apple-system, sans-serif",
              }}
            />
            <button
              onClick={() => handleSend()}
              disabled={!inputValue.trim() || sending}
              className="w-11 h-11 rounded-full flex items-center justify-center flex-shrink-0 transition-all disabled:opacity-40 hover:shadow-lg"
              style={{
                background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                boxShadow: `0 4px 14px ${colors.glassShadow}`,
              }}
            >
              <svg className="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </AdvisorLayout>
  )
}

export default ChatPage
