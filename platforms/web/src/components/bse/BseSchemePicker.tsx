import { useState, useCallback, useEffect, useRef } from 'react'
import { useFATheme } from '@/utils/fa'
import { bseApi } from '@/services/api'

interface Scheme {
  id: string
  schemeCode: string
  schemeName: string
  isin?: string
  amcCode?: string
  purchaseAllowed: boolean
  sipAllowed: boolean
  minPurchaseAmt?: number
  minSipAmt?: number
}

interface BseSchemePickerProps {
  onSelect: (scheme: Scheme) => void
  filterType?: 'purchase' | 'sip' | 'switch' | 'redemption'
  placeholder?: string
}

export default function BseSchemePicker({ onSelect, filterType, placeholder }: BseSchemePickerProps) {
  const { colors } = useFATheme()
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<Scheme[]>([])
  const [loading, setLoading] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const debounceRef = useRef<NodeJS.Timeout>()
  const containerRef = useRef<HTMLDivElement>(null)

  const search = useCallback(async (q: string) => {
    if (q.length < 2) {
      setResults([])
      return
    }

    setLoading(true)
    try {
      const response = await bseApi.masters.searchSchemes(q, 1, 15)
      let schemes = response.data || []

      if (filterType === 'purchase') {
        schemes = schemes.filter((s: Scheme) => s.purchaseAllowed)
      } else if (filterType === 'sip') {
        schemes = schemes.filter((s: Scheme) => s.sipAllowed)
      }

      setResults(schemes)
      setIsOpen(true)
    } catch {
      setResults([])
    } finally {
      setLoading(false)
    }
  }, [filterType])

  const handleInputChange = (value: string) => {
    setQuery(value)
    if (debounceRef.current) clearTimeout(debounceRef.current)
    debounceRef.current = setTimeout(() => search(value), 300)
  }

  const handleSelect = (scheme: Scheme) => {
    setQuery(scheme.schemeName)
    setIsOpen(false)
    onSelect(scheme)
  }

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  return (
    <div ref={containerRef} className="relative">
      <input
        type="text"
        value={query}
        onChange={(e) => handleInputChange(e.target.value)}
        onFocus={() => results.length > 0 && setIsOpen(true)}
        placeholder={placeholder || 'Search BSE schemes...'}
        className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
        style={{
          background: colors.inputBg,
          border: `1px solid ${colors.inputBorder}`,
          color: colors.textPrimary,
        }}
      />
      {loading && (
        <div className="absolute right-3 top-2.5">
          <div className="w-5 h-5 border-2 border-t-transparent rounded-full animate-spin" style={{ borderColor: colors.primary, borderTopColor: 'transparent' }} />
        </div>
      )}

      {isOpen && results.length > 0 && (
        <div
          className="absolute z-50 w-full mt-1 max-h-60 overflow-y-auto rounded-xl shadow-lg"
          style={{
            background: colors.cardBackground,
            border: `1px solid ${colors.cardBorder}`,
          }}
        >
          {results.map((scheme) => (
            <button
              key={scheme.schemeCode}
              onClick={() => handleSelect(scheme)}
              className="w-full text-left px-4 py-2.5 transition-colors hover:opacity-80"
              style={{ borderBottom: `1px solid ${colors.cardBorder}` }}
            >
              <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>
                {scheme.schemeName}
              </p>
              <p className="text-xs mt-0.5" style={{ color: colors.textTertiary }}>
                {scheme.schemeCode} {scheme.isin ? `| ${scheme.isin}` : ''}
                {scheme.minPurchaseAmt ? ` | Min: ₹${scheme.minPurchaseAmt}` : ''}
              </p>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
