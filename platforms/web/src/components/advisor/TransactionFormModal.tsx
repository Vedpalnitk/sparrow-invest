/**
 * Transaction Form Modal Component
 *
 * Modal for recording mutual fund transactions executed on BSE Star MF / MFU.
 * The FA executes the order on the external platform, then records it here
 * for portfolio tracking and audit trail.
 */

import { useState, useEffect, useCallback, useRef } from 'react'
import { useFATheme, formatCurrency } from '@/utils/fa'
import { TransactionType, TransactionFormData, ExecutionPlatform } from '@/utils/faTypes'
import { dbFundsApi, DatabaseFund, clientsApi } from '@/services/api'
import {
  FAButton,
  FAInput,
  FASelect,
  FALabel,
  FAFormSection,
  FASpinner,
} from '@/components/advisor/shared'

interface TransactionFormModalProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (data: TransactionFormData) => void
  initialType?: TransactionType
  /** Pre-fill client (e.g. from client detail page) */
  clientId?: string
  clientName?: string
}

const TRANSACTION_TYPES = [
  { value: 'Buy', label: 'Purchase', icon: 'M12 4v16m8-8H4' },
  { value: 'SIP', label: 'SIP', icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15' },
  { value: 'Sell', label: 'Redeem', icon: 'M20 12H4' },
  { value: 'Switch', label: 'Switch', icon: 'M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4' },
  { value: 'SWP', label: 'SWP', icon: 'M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z' },
  { value: 'STP', label: 'STP', icon: 'M13 7h8m0 0v8m0-8l-8 8-4-4-6 6' },
] as const

const PLATFORMS: { value: ExecutionPlatform; label: string; description: string }[] = [
  { value: 'BSE_STARMF', label: 'BSE Star MF', description: 'BSE StAR MF Platform' },
  { value: 'MFU', label: 'MFU', description: 'MF Utilities' },
  { value: 'AMC_DIRECT', label: 'AMC Direct', description: 'Direct with AMC' },
]

const PAYMENT_MODES = [
  { value: 'Net Banking', label: 'Net Banking' },
  { value: 'UPI', label: 'UPI' },
  { value: 'NACH', label: 'NACH / Mandate' },
]

const SIP_DATES = [1, 5, 10, 15, 20, 25, 28]

interface ClientOption {
  id: string
  name: string
  email?: string
}

// Debounce hook
function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)
  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay)
    return () => clearTimeout(handler)
  }, [value, delay])
  return debouncedValue
}

const TransactionFormModal = ({
  isOpen,
  onClose,
  onSubmit,
  initialType = 'Buy',
  clientId: presetClientId,
  clientName: presetClientName,
}: TransactionFormModalProps) => {
  const { colors, isDark } = useFATheme()

  // Transaction type
  const [txnType, setTxnType] = useState<TransactionType>(initialType)

  // Platform
  const [platform, setPlatform] = useState<ExecutionPlatform>('BSE_STARMF')

  // Client
  const [clientQuery, setClientQuery] = useState('')
  const [clientResults, setClientResults] = useState<ClientOption[]>([])
  const [selectedClient, setSelectedClient] = useState<ClientOption | null>(null)
  const [showClientResults, setShowClientResults] = useState(false)
  const [isSearchingClients, setIsSearchingClients] = useState(false)
  const debouncedClientQuery = useDebounce(clientQuery, 300)

  // Fund
  const [fundQuery, setFundQuery] = useState('')
  const [fundResults, setFundResults] = useState<DatabaseFund[]>([])
  const [selectedFund, setSelectedFund] = useState<DatabaseFund | null>(null)
  const [showFundResults, setShowFundResults] = useState(false)
  const [isSearchingFunds, setIsSearchingFunds] = useState(false)
  const debouncedFundQuery = useDebounce(fundQuery, 300)

  // Target fund (Switch/STP)
  const [targetFundQuery, setTargetFundQuery] = useState('')
  const [targetFundResults, setTargetFundResults] = useState<DatabaseFund[]>([])
  const [selectedTargetFund, setSelectedTargetFund] = useState<DatabaseFund | null>(null)
  const [showTargetFundResults, setShowTargetFundResults] = useState(false)
  const [isSearchingTargetFunds, setIsSearchingTargetFunds] = useState(false)
  const debouncedTargetFundQuery = useDebounce(targetFundQuery, 300)

  // Transaction details
  const [amount, setAmount] = useState<number | ''>('')
  const [folioNumber, setFolioNumber] = useState('')
  const [paymentMode, setPaymentMode] = useState<'Net Banking' | 'UPI' | 'NACH'>('Net Banking')

  // SIP details
  const [sipFrequency, setSipFrequency] = useState<'Monthly' | 'Quarterly' | 'Weekly'>('Monthly')
  const [sipDate, setSipDate] = useState(5)
  const [sipStartDate, setSipStartDate] = useState('')
  const [sipEndDate, setSipEndDate] = useState('')
  const [isPerpetual, setIsPerpetual] = useState(true)

  // Platform reference
  const [orderNumber, setOrderNumber] = useState('')
  const [remarks, setRemarks] = useState('')

  // Validation
  const [errors, setErrors] = useState<Record<string, string>>({})

  // Reset on open
  useEffect(() => {
    if (isOpen) {
      setTxnType(initialType)
      setPlatform('BSE_STARMF')
      setClientQuery(presetClientName || '')
      setSelectedClient(presetClientId && presetClientName ? { id: presetClientId, name: presetClientName } : null)
      setClientResults([])
      setFundQuery('')
      setSelectedFund(null)
      setFundResults([])
      setTargetFundQuery('')
      setSelectedTargetFund(null)
      setTargetFundResults([])
      setAmount('')
      setFolioNumber('')
      setPaymentMode('Net Banking')
      setSipFrequency('Monthly')
      setSipDate(5)
      setSipStartDate('')
      setSipEndDate('')
      setIsPerpetual(true)
      setOrderNumber('')
      setRemarks('')
      setErrors({})
    }
  }, [isOpen, initialType, presetClientId, presetClientName])

  // Search clients
  useEffect(() => {
    if (debouncedClientQuery.length < 2 || selectedClient) return
    const search = async () => {
      setIsSearchingClients(true)
      try {
        const response = await clientsApi.list<{ data: ClientOption[] }>({ search: debouncedClientQuery, limit: 8 })
        setClientResults((response as any).data || [])
      } catch {
        setClientResults([])
      } finally {
        setIsSearchingClients(false)
      }
    }
    search()
  }, [debouncedClientQuery, selectedClient])

  // Search funds
  useEffect(() => {
    if (debouncedFundQuery.length < 2 || selectedFund) return
    const search = async () => {
      setIsSearchingFunds(true)
      try {
        const results = await dbFundsApi.searchFunds(debouncedFundQuery)
        setFundResults(results.slice(0, 8))
      } catch {
        setFundResults([])
      } finally {
        setIsSearchingFunds(false)
      }
    }
    search()
  }, [debouncedFundQuery, selectedFund])

  // Search target funds
  useEffect(() => {
    if (debouncedTargetFundQuery.length < 2 || selectedTargetFund) return
    const search = async () => {
      setIsSearchingTargetFunds(true)
      try {
        const results = await dbFundsApi.searchFunds(debouncedTargetFundQuery)
        setTargetFundResults(results.filter(f => f.schemeCode !== selectedFund?.schemeCode).slice(0, 8))
      } catch {
        setTargetFundResults([])
      } finally {
        setIsSearchingTargetFunds(false)
      }
    }
    search()
  }, [debouncedTargetFundQuery, selectedTargetFund, selectedFund])

  // Validation
  const validate = (): boolean => {
    const e: Record<string, string> = {}

    if (!selectedClient) e.client = 'Select a client'
    if (!selectedFund) e.fund = 'Select a fund'
    if (!amount || amount <= 0) e.amount = 'Enter a valid amount'
    if (txnType === 'Buy' && amount && amount < 500) e.amount = 'Minimum purchase is ₹500'
    if (txnType === 'SIP' && amount && amount < 500) e.amount = 'Minimum SIP amount is ₹500'
    if ((txnType === 'Switch' || txnType === 'STP') && !selectedTargetFund) e.targetFund = 'Select target fund'
    if (txnType === 'SIP' && !sipStartDate) e.sipStartDate = 'Select SIP start date'

    setErrors(e)
    return Object.keys(e).length === 0
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!validate()) return

    const data: TransactionFormData = {
      clientId: selectedClient!.id,
      clientName: selectedClient!.name,
      fundSchemeCode: selectedFund!.schemeCode.toString(),
      fundName: selectedFund!.schemeName,
      fundCategory: selectedFund!.category,
      nav: selectedFund!.currentNav,
      type: txnType,
      amount: Number(amount),
      folioNumber: folioNumber || undefined,
      paymentMode,
      platform,
      orderNumber: orderNumber || undefined,
      remarks: remarks || undefined,
      // SIP fields
      ...(txnType === 'SIP' || txnType === 'SWP' || txnType === 'STP' ? {
        sipFrequency,
        sipDate,
        sipStartDate,
        sipEndDate: isPerpetual ? undefined : sipEndDate,
        isPerpetual,
      } : {}),
      // Switch/STP fields
      ...((txnType === 'Switch' || txnType === 'STP') && selectedTargetFund ? {
        targetFundCode: selectedTargetFund.schemeCode.toString(),
        targetFundName: selectedTargetFund.schemeName,
      } : {}),
    }

    onSubmit(data)
  }

  // Close search dropdowns on click outside
  useEffect(() => {
    const handleClickOutside = () => {
      setShowClientResults(false)
      setShowFundResults(false)
      setShowTargetFundResults(false)
    }
    if (isOpen) {
      document.addEventListener('click', handleClickOutside)
      return () => document.removeEventListener('click', handleClickOutside)
    }
  }, [isOpen])

  if (!isOpen) return null

  const needsTargetFund = txnType === 'Switch' || txnType === 'STP'
  const needsSipDetails = txnType === 'SIP' || txnType === 'SWP' || txnType === 'STP'
  const needsPaymentMode = txnType === 'Buy' || txnType === 'SIP'

  const chipStyle = (active: boolean) => ({
    background: active
      ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
      : colors.chipBg,
    color: active ? '#FFFFFF' : colors.textSecondary,
    border: `1px solid ${active ? 'transparent' : colors.cardBorder}`,
  })

  const searchDropdownStyle = {
    background: colors.cardBackground,
    border: `1px solid ${colors.cardBorder}`,
    boxShadow: `0 8px 32px ${colors.glassShadow}`,
  }

  const searchItemHover = (e: React.MouseEvent, enter: boolean) => {
    (e.currentTarget as HTMLElement).style.background = enter
      ? (isDark ? 'rgba(147, 197, 253, 0.1)' : 'rgba(59, 130, 246, 0.05)')
      : 'transparent'
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />

      <div
        className="relative w-full max-w-lg max-h-[90vh] overflow-hidden rounded-2xl"
        style={{
          background: colors.cardBackground,
          border: `1px solid ${colors.cardBorder}`,
          boxShadow: `0 25px 50px -12px ${colors.glassShadow}`,
        }}
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4" style={{ borderBottom: `1px solid ${colors.cardBorder}` }}>
          <h2 className="text-base font-semibold" style={{ color: colors.textPrimary }}>Record Transaction</h2>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg transition-all"
            style={{ background: colors.chipBg, color: colors.textSecondary }}
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          <div className="px-5 py-4 overflow-y-auto space-y-5" style={{ maxHeight: 'calc(90vh - 130px)' }}>

            {/* Transaction Type */}
            <div>
              <FALabel>Transaction Type</FALabel>
              <div className="grid grid-cols-6 gap-1.5 mt-1.5">
                {TRANSACTION_TYPES.map(t => (
                  <button
                    key={t.value}
                    type="button"
                    onClick={() => setTxnType(t.value as TransactionType)}
                    className="flex flex-col items-center gap-1 p-2 rounded-xl text-xs font-medium transition-all"
                    style={chipStyle(txnType === t.value)}
                  >
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d={t.icon} />
                    </svg>
                    {t.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Execution Platform */}
            <div>
              <FALabel>Executed On</FALabel>
              <div className="grid grid-cols-3 gap-2 mt-1.5">
                {PLATFORMS.map(p => (
                  <button
                    key={p.value}
                    type="button"
                    onClick={() => setPlatform(p.value)}
                    className="p-2.5 rounded-xl text-sm font-medium transition-all text-center"
                    style={chipStyle(platform === p.value)}
                  >
                    {p.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Client */}
            <div>
              <FALabel>Client</FALabel>
              <div className="relative mt-1.5" onClick={e => e.stopPropagation()}>
                <input
                  type="text"
                  placeholder="Search by client name..."
                  value={clientQuery}
                  onChange={e => {
                    setClientQuery(e.target.value)
                    setShowClientResults(true)
                    if (selectedClient && e.target.value !== selectedClient.name) {
                      setSelectedClient(null)
                    }
                  }}
                  onFocus={() => { if (!selectedClient) setShowClientResults(true) }}
                  className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                  style={{
                    background: colors.inputBg,
                    border: `1px solid ${errors.client ? colors.error : selectedClient ? colors.success : colors.inputBorder}`,
                    color: colors.textPrimary,
                  }}
                />
                {isSearchingClients && (
                  <div className="absolute right-3 top-1/2 -translate-y-1/2"><FASpinner size="sm" /></div>
                )}
                {selectedClient && (
                  <div className="absolute right-3 top-1/2 -translate-y-1/2">
                    <svg className="w-4 h-4" style={{ color: colors.success }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                )}
                {showClientResults && clientResults.length > 0 && !selectedClient && (
                  <div className="absolute z-20 w-full mt-1 rounded-xl overflow-hidden max-h-48 overflow-y-auto" style={searchDropdownStyle}>
                    {clientResults.map(c => (
                      <button
                        key={c.id}
                        type="button"
                        onClick={() => {
                          setSelectedClient(c)
                          setClientQuery(c.name)
                          setShowClientResults(false)
                          setErrors(prev => { const { client, ...rest } = prev; return rest })
                        }}
                        className="w-full px-4 py-2.5 text-left transition-all"
                        style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
                        onMouseEnter={e => searchItemHover(e, true)}
                        onMouseLeave={e => searchItemHover(e, false)}
                      >
                        <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{c.name}</p>
                        {c.email && <p className="text-xs" style={{ color: colors.textTertiary }}>{c.email}</p>}
                      </button>
                    ))}
                  </div>
                )}
              </div>
              {errors.client && <p className="text-xs mt-1" style={{ color: colors.error }}>{errors.client}</p>}
            </div>

            {/* Fund */}
            <div>
              <FALabel>{needsTargetFund ? 'Source Fund' : 'Fund'}</FALabel>
              <div className="relative mt-1.5" onClick={e => e.stopPropagation()}>
                <input
                  type="text"
                  placeholder="Search by fund name or AMC..."
                  value={fundQuery}
                  onChange={e => {
                    setFundQuery(e.target.value)
                    setShowFundResults(true)
                    if (selectedFund && e.target.value !== selectedFund.schemeName) {
                      setSelectedFund(null)
                    }
                  }}
                  onFocus={() => { if (!selectedFund) setShowFundResults(true) }}
                  className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                  style={{
                    background: colors.inputBg,
                    border: `1px solid ${errors.fund ? colors.error : selectedFund ? colors.success : colors.inputBorder}`,
                    color: colors.textPrimary,
                  }}
                />
                {isSearchingFunds && (
                  <div className="absolute right-3 top-1/2 -translate-y-1/2"><FASpinner size="sm" /></div>
                )}
                {selectedFund && (
                  <div className="absolute right-3 top-1/2 -translate-y-1/2">
                    <svg className="w-4 h-4" style={{ color: colors.success }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                )}
                {showFundResults && fundResults.length > 0 && !selectedFund && (
                  <div className="absolute z-20 w-full mt-1 rounded-xl overflow-hidden max-h-48 overflow-y-auto" style={searchDropdownStyle}>
                    {fundResults.map(f => (
                      <button
                        key={f.schemeCode}
                        type="button"
                        onClick={() => {
                          setSelectedFund(f)
                          setFundQuery(f.schemeName)
                          setShowFundResults(false)
                          setErrors(prev => { const { fund, ...rest } = prev; return rest })
                        }}
                        className="w-full px-4 py-2.5 text-left transition-all"
                        style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
                        onMouseEnter={e => searchItemHover(e, true)}
                        onMouseLeave={e => searchItemHover(e, false)}
                      >
                        <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{f.schemeName}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs" style={{ color: colors.textTertiary }}>{f.category}</span>
                          <span className="text-xs" style={{ color: colors.textTertiary }}>•</span>
                          <span className="text-xs font-medium" style={{ color: colors.primary }}>
                            NAV ₹{f.currentNav?.toFixed(2) || 'N/A'}
                          </span>
                        </div>
                      </button>
                    ))}
                  </div>
                )}
              </div>
              {errors.fund && <p className="text-xs mt-1" style={{ color: colors.error }}>{errors.fund}</p>}
              {selectedFund && (
                <div className="mt-2 px-3 py-2 rounded-lg flex items-center justify-between" style={{ background: colors.chipBg }}>
                  <span className="text-xs" style={{ color: colors.textSecondary }}>{selectedFund.category} • {selectedFund.fundHouse}</span>
                  <span className="text-xs font-semibold" style={{ color: colors.primary }}>NAV ₹{selectedFund.currentNav?.toFixed(2)}</span>
                </div>
              )}
            </div>

            {/* Target Fund (Switch/STP) */}
            {needsTargetFund && (
              <div>
                <FALabel>Target Fund</FALabel>
                <div className="relative mt-1.5" onClick={e => e.stopPropagation()}>
                  <input
                    type="text"
                    placeholder="Search target fund..."
                    value={targetFundQuery}
                    onChange={e => {
                      setTargetFundQuery(e.target.value)
                      setShowTargetFundResults(true)
                      if (selectedTargetFund && e.target.value !== selectedTargetFund.schemeName) {
                        setSelectedTargetFund(null)
                      }
                    }}
                    onFocus={() => { if (!selectedTargetFund) setShowTargetFundResults(true) }}
                    className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                    style={{
                      background: colors.inputBg,
                      border: `1px solid ${errors.targetFund ? colors.error : selectedTargetFund ? colors.success : colors.inputBorder}`,
                      color: colors.textPrimary,
                    }}
                  />
                  {isSearchingTargetFunds && (
                    <div className="absolute right-3 top-1/2 -translate-y-1/2"><FASpinner size="sm" /></div>
                  )}
                  {showTargetFundResults && targetFundResults.length > 0 && !selectedTargetFund && (
                    <div className="absolute z-20 w-full mt-1 rounded-xl overflow-hidden max-h-48 overflow-y-auto" style={searchDropdownStyle}>
                      {targetFundResults.map(f => (
                        <button
                          key={f.schemeCode}
                          type="button"
                          onClick={() => {
                            setSelectedTargetFund(f)
                            setTargetFundQuery(f.schemeName)
                            setShowTargetFundResults(false)
                            setErrors(prev => { const { targetFund, ...rest } = prev; return rest })
                          }}
                          className="w-full px-4 py-2.5 text-left transition-all"
                          style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
                          onMouseEnter={e => searchItemHover(e, true)}
                          onMouseLeave={e => searchItemHover(e, false)}
                        >
                          <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{f.schemeName}</p>
                          <span className="text-xs" style={{ color: colors.textTertiary }}>{f.category}</span>
                        </button>
                      ))}
                    </div>
                  )}
                </div>
                {errors.targetFund && <p className="text-xs mt-1" style={{ color: colors.error }}>{errors.targetFund}</p>}
              </div>
            )}

            {/* Amount + Folio */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <FALabel>{txnType === 'SIP' || txnType === 'SWP' || txnType === 'STP' ? 'Per Installment' : 'Amount'}</FALabel>
                <div className="relative mt-1.5">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-sm" style={{ color: colors.textTertiary }}>₹</span>
                  <input
                    type="number"
                    placeholder="0"
                    value={amount}
                    onChange={e => {
                      setAmount(e.target.value ? Number(e.target.value) : '')
                      setErrors(prev => { const { amount, ...rest } = prev; return rest })
                    }}
                    className="w-full h-10 pl-7 pr-3 rounded-xl text-sm focus:outline-none"
                    style={{
                      background: colors.inputBg,
                      border: `1px solid ${errors.amount ? colors.error : colors.inputBorder}`,
                      color: colors.textPrimary,
                    }}
                  />
                </div>
                {errors.amount && <p className="text-xs mt-1" style={{ color: colors.error }}>{errors.amount}</p>}
              </div>
              <div>
                <FALabel>Folio Number</FALabel>
                <input
                  type="text"
                  placeholder="New or existing folio"
                  value={folioNumber}
                  onChange={e => setFolioNumber(e.target.value)}
                  className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none mt-1.5"
                  style={{
                    background: colors.inputBg,
                    border: `1px solid ${colors.inputBorder}`,
                    color: colors.textPrimary,
                  }}
                />
              </div>
            </div>

            {/* Estimated units */}
            {amount && selectedFund && selectedFund.currentNav > 0 && (
              <div className="px-3 py-2 rounded-lg" style={{ background: colors.chipBg }}>
                <span className="text-xs" style={{ color: colors.textSecondary }}>
                  Est. units: <span className="font-semibold" style={{ color: colors.textPrimary }}>
                    {(Number(amount) / selectedFund.currentNav).toFixed(3)}
                  </span> at current NAV
                </span>
              </div>
            )}

            {/* SIP / Systematic Details */}
            {needsSipDetails && (
              <div>
                <FALabel>{txnType} Details</FALabel>
                <div className="grid grid-cols-2 gap-3 mt-1.5">
                  <select
                    value={sipFrequency}
                    onChange={e => setSipFrequency(e.target.value as typeof sipFrequency)}
                    className="h-10 px-3 rounded-xl text-sm focus:outline-none cursor-pointer"
                    style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                  >
                    <option value="Monthly">Monthly</option>
                    <option value="Quarterly">Quarterly</option>
                    <option value="Weekly">Weekly</option>
                  </select>
                  <select
                    value={sipDate}
                    onChange={e => setSipDate(Number(e.target.value))}
                    className="h-10 px-3 rounded-xl text-sm focus:outline-none cursor-pointer"
                    style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                  >
                    {SIP_DATES.map(d => (
                      <option key={d} value={d}>{d}{d === 1 ? 'st' : d === 2 ? 'nd' : d === 3 ? 'rd' : 'th'} of month</option>
                    ))}
                  </select>
                  <div>
                    <label className="text-xs" style={{ color: colors.textTertiary }}>Start Date</label>
                    <input
                      type="date"
                      value={sipStartDate}
                      onChange={e => {
                        setSipStartDate(e.target.value)
                        setErrors(prev => { const { sipStartDate, ...rest } = prev; return rest })
                      }}
                      className="w-full h-10 px-3 rounded-xl text-sm focus:outline-none mt-0.5"
                      style={{
                        background: colors.inputBg,
                        border: `1px solid ${errors.sipStartDate ? colors.error : colors.inputBorder}`,
                        color: colors.textPrimary,
                      }}
                    />
                    {errors.sipStartDate && <p className="text-xs mt-0.5" style={{ color: colors.error }}>{errors.sipStartDate}</p>}
                  </div>
                  <div>
                    <div className="flex items-center justify-between">
                      <label className="text-xs" style={{ color: colors.textTertiary }}>End Date</label>
                      <label className="flex items-center gap-1.5 cursor-pointer">
                        <input
                          type="checkbox"
                          checked={isPerpetual}
                          onChange={e => setIsPerpetual(e.target.checked)}
                          className="sr-only"
                        />
                        <div
                          className="w-4 h-4 rounded border flex items-center justify-center"
                          style={{
                            background: isPerpetual ? colors.primary : 'transparent',
                            borderColor: isPerpetual ? colors.primary : colors.inputBorder,
                          }}
                        >
                          {isPerpetual && (
                            <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                              <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                            </svg>
                          )}
                        </div>
                        <span className="text-xs" style={{ color: colors.textSecondary }}>Perpetual</span>
                      </label>
                    </div>
                    {!isPerpetual && (
                      <input
                        type="date"
                        value={sipEndDate}
                        onChange={e => setSipEndDate(e.target.value)}
                        className="w-full h-10 px-3 rounded-xl text-sm focus:outline-none mt-0.5"
                        style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                      />
                    )}
                    {isPerpetual && (
                      <div className="h-10 flex items-center mt-0.5">
                        <span className="text-xs" style={{ color: colors.textTertiary }}>No end date</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Payment Mode */}
            {needsPaymentMode && (
              <div>
                <FALabel>Payment Mode</FALabel>
                <div className="grid grid-cols-3 gap-2 mt-1.5">
                  {PAYMENT_MODES.map(m => (
                    <button
                      key={m.value}
                      type="button"
                      onClick={() => setPaymentMode(m.value as typeof paymentMode)}
                      className="p-2 rounded-xl text-xs font-medium transition-all text-center"
                      style={chipStyle(paymentMode === m.value)}
                    >
                      {m.label}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Platform Reference */}
            <div
              className="p-3 rounded-xl space-y-3"
              style={{
                background: isDark ? 'rgba(147, 197, 253, 0.04)' : 'rgba(59, 130, 246, 0.02)',
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              <div className="flex items-center gap-2">
                <svg className="w-4 h-4" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z" />
                </svg>
                <span className="text-xs font-semibold uppercase tracking-wider" style={{ color: colors.primary }}>
                  Platform Reference
                </span>
              </div>
              <input
                type="text"
                placeholder={platform === 'BSE_STARMF' ? 'BSE Order Number' : platform === 'MFU' ? 'MFU Transaction Ref' : 'Order Reference'}
                value={orderNumber}
                onChange={e => setOrderNumber(e.target.value)}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
              <textarea
                placeholder="Remarks / notes (optional)"
                value={remarks}
                onChange={e => setRemarks(e.target.value)}
                rows={2}
                className="w-full px-4 py-2.5 rounded-xl text-sm focus:outline-none resize-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>

            {/* Sell/SWP Warning */}
            {(txnType === 'Sell' || txnType === 'SWP') && (
              <div
                className="flex items-start gap-2.5 p-3 rounded-xl"
                style={{ background: `${colors.warning}08`, border: `1px solid ${colors.warning}25` }}
              >
                <svg className="w-4 h-4 flex-shrink-0 mt-0.5" style={{ color: colors.warning }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                <p className="text-xs" style={{ color: colors.textSecondary }}>
                  {txnType === 'Sell'
                    ? 'Exit load may apply. Proceeds credited to registered bank account within T+1 to T+3 days.'
                    : 'Ensure sufficient units in folio. SWP will redeem units on each installment date.'}
                </p>
              </div>
            )}
          </div>

          {/* Footer */}
          <div className="flex items-center justify-end gap-3 px-5 py-3" style={{ borderTop: `1px solid ${colors.cardBorder}` }}>
            <FAButton type="button" variant="secondary" onClick={onClose}>Cancel</FAButton>
            <FAButton type="submit">
              Record {txnType === 'Buy' ? 'Purchase' : txnType === 'Sell' ? 'Redemption' : txnType}
            </FAButton>
          </div>
        </form>
      </div>
    </div>
  )
}

export default TransactionFormModal
