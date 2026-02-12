import { useState, useEffect } from 'react'
import AdminLayout from '@/components/layout/AdminLayout'
import {
  personasApi,
  allocationsApi,
  Persona,
  AllocationStrategy,
  AllocationComponent,
  ClassificationLog,
  ClassificationStats,
} from '@/services/api'
import { personaProfiles } from '@/utils/constants'

import { useAdminColors, useDarkMode } from '@/utils/useAdminColors'
import { AdminModal } from '@/components/admin/shared'

// Alias for backward compatibility
const useV4Colors = useAdminColors

// Icon paths
const ICONS = {
  plus: 'M12 4v16m8-8H4',
  close: 'M6 18L18 6M6 6l12 12',
  edit: 'M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z',
  trash: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16',
  user: 'M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z',
  rules: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2',
  insights: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  beaker: 'M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z',
  chart: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
  play: 'M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  check: 'M5 13l4 4L19 7',
  copy: 'M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z',
  pieChart: 'M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z',
}

// Sage & Cream themed allocation bar colors
const ALLOCATION_COLORS = [
  { bg: '#5B8A72', light: 'rgba(91, 138, 114, 0.15)' },    // Sage
  { bg: '#7BA894', light: 'rgba(123, 168, 148, 0.15)' },   // Light sage
  { bg: '#C4A484', light: 'rgba(196, 164, 132, 0.15)' },   // Warm sand
  { bg: '#D4A574', light: 'rgba(212, 165, 116, 0.15)' },   // Warm amber
  { bg: '#6B9AC4', light: 'rgba(107, 154, 196, 0.15)' },   // Soft blue
  { bg: '#8A9A91', light: 'rgba(138, 154, 145, 0.15)' },   // Sage gray
]

const useMockData = false

type MainTab = 'personas' | 'allocations'
type PersonaSubTab = 'list' | 'bulk' | 'results'

const MLConfigPage = () => {
  const colors = useV4Colors()
  const isDark = useDarkMode()

  // Main tab state
  const [mainTab, setMainTab] = useState<MainTab>('personas')
  const [personaSubTab, setPersonaSubTab] = useState<PersonaSubTab>('list')

  // Personas state
  const [personas, setPersonas] = useState<Persona[]>([])
  const [selectedPersona, setSelectedPersona] = useState<Persona | null>(null)
  const [isPersonaModalOpen, setIsPersonaModalOpen] = useState(false)
  const [isCreatePersonaMode, setIsCreatePersonaMode] = useState(false)
  const [loadingPersonas, setLoadingPersonas] = useState(true)

  // Allocations state
  const [strategies, setStrategies] = useState<AllocationStrategy[]>([])
  const [selectedStrategy, setSelectedStrategy] = useState<AllocationStrategy | null>(null)
  const [isStrategyModalOpen, setIsStrategyModalOpen] = useState(false)
  const [isCreateStrategyMode, setIsCreateStrategyMode] = useState(false)
  const [isComponentModalOpen, setIsComponentModalOpen] = useState(false)
  const [loadingStrategies, setLoadingStrategies] = useState(true)

  // Common state
  const [error, setError] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)

  // Classification results state (for viewing saved results)
  const [classificationLogs, setClassificationLogs] = useState<ClassificationLog[]>([])
  const [classificationStats, setClassificationStats] = useState<ClassificationStats | null>(null)
  const [loadingResults, setLoadingResults] = useState(false)

  // Bulk create state
  const [bulkPersonas, setBulkPersonas] = useState<Array<{
    name: string
    slug: string
    description: string
    riskBand: string
    colorPrimary: string
    colorSecondary: string
  }>>([{ name: '', slug: '', description: '', riskBand: 'Balanced Growth', colorPrimary: '#2563EB', colorSecondary: '#5856D6' }])
  const [bulkLoading, setBulkLoading] = useState(false)

  // Form states
  const [personaForm, setPersonaForm] = useState({
    name: '',
    slug: '',
    description: '',
    riskBand: 'Balanced Growth',
    iconName: '',
    colorPrimary: '#2563EB',
    colorSecondary: '#5856D6',
    isActive: true,
  })

  const [strategyForm, setStrategyForm] = useState({
    name: '',
    personaId: '',
    description: '',
    version: '1.0.0',
    isActive: true,
  })

  const [componentForm, setComponentForm] = useState({
    label: '',
    allocationPercent: 0,
    note: '',
  })

  // Load data
  useEffect(() => {
    loadPersonas()
    loadStrategies()
  }, [])

  useEffect(() => {
    if (personaSubTab === 'results') {
      loadClassificationResults()
    }
  }, [personaSubTab])

  const loadPersonas = async () => {
    setLoadingPersonas(true)
    try {
      if (useMockData) {
        const mockPersonas: Persona[] = personaProfiles.map((p, i) => ({
          id: `persona-${i + 1}`,
          name: p.name,
          slug: p.name.toLowerCase().replace(/\s+/g, '-'),
          description: p.description,
          riskBand: p.riskBand,
          iconName: 'chart',
          colorPrimary: '#2563EB',
          colorSecondary: '#5856D6',
          displayOrder: i,
          isActive: true,
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          rules: [],
          insights: [],
        }))
        setPersonas(mockPersonas)
      } else {
        const data = await personasApi.list()
        setPersonas(data)
      }
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoadingPersonas(false)
    }
  }

  const loadStrategies = async () => {
    setLoadingStrategies(true)
    try {
      if (useMockData) {
        setStrategies([])
      } else {
        const data = await allocationsApi.list()
        setStrategies(data)
      }
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoadingStrategies(false)
    }
  }

  const loadClassificationResults = async () => {
    setLoadingResults(true)
    try {
      const [logs, stats] = await Promise.all([
        personasApi.getClassificationResults({ limit: 50 }),
        personasApi.getClassificationStats(),
      ])
      setClassificationLogs(logs)
      setClassificationStats(stats)
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoadingResults(false)
    }
  }

  // Persona handlers
  const handleCreatePersona = () => {
    setIsCreatePersonaMode(true)
    setPersonaForm({
      name: '', slug: '', description: '', riskBand: 'Balanced Growth',
      iconName: '', colorPrimary: '#2563EB', colorSecondary: '#5856D6', isActive: true,
    })
    setIsPersonaModalOpen(true)
  }

  const handleEditPersona = (persona: Persona) => {
    setIsCreatePersonaMode(false)
    setSelectedPersona(persona)
    setPersonaForm({
      name: persona.name,
      slug: persona.slug,
      description: persona.description || '',
      riskBand: persona.riskBand,
      iconName: persona.iconName || '',
      colorPrimary: persona.colorPrimary || '#2563EB',
      colorSecondary: persona.colorSecondary || '#5856D6',
      isActive: persona.isActive,
    })
    setIsPersonaModalOpen(true)
  }

  const handleSavePersona = async () => {
    try {
      if (isCreatePersonaMode) {
        await personasApi.create(personaForm)
      } else if (selectedPersona) {
        await personasApi.update(selectedPersona.id, personaForm)
      }
      await loadPersonas()
      setIsPersonaModalOpen(false)
      setSuccessMessage(isCreatePersonaMode ? 'Persona created successfully' : 'Persona updated successfully')
    } catch (err: any) {
      setError(err.message)
    }
  }

  const handleDeletePersona = async (id: string) => {
    if (!confirm('Are you sure you want to delete this persona?')) return
    try {
      await personasApi.delete(id)
      await loadPersonas()
    } catch (err: any) {
      setError(err.message)
    }
  }

  // Bulk create handlers
  const addBulkPersonaRow = () => {
    setBulkPersonas([...bulkPersonas, { name: '', slug: '', description: '', riskBand: 'Balanced Growth', colorPrimary: '#2563EB', colorSecondary: '#5856D6' }])
  }

  const removeBulkPersonaRow = (index: number) => {
    setBulkPersonas(bulkPersonas.filter((_, i) => i !== index))
  }

  const updateBulkPersona = (index: number, field: string, value: string) => {
    const updated = [...bulkPersonas]
    updated[index] = { ...updated[index], [field]: value }
    if (field === 'name') {
      updated[index].slug = value.toLowerCase().replace(/\s+/g, '-')
    }
    setBulkPersonas(updated)
  }

  const handleBulkCreate = async () => {
    const validPersonas = bulkPersonas.filter(p => p.name && p.slug)
    if (validPersonas.length === 0) {
      setError('Please add at least one valid persona with name and slug')
      return
    }
    setBulkLoading(true)
    try {
      const result = await personasApi.bulkCreate(validPersonas.map(p => ({ ...p, isActive: true })))
      if (result.created.length > 0) {
        setSuccessMessage(`Successfully created ${result.created.length} persona(s)`)
        await loadPersonas()
        setBulkPersonas([{ name: '', slug: '', description: '', riskBand: 'Balanced Growth', colorPrimary: '#2563EB', colorSecondary: '#5856D6' }])
      }
      if (result.failed.length > 0) {
        setError(`Failed to create ${result.failed.length} persona(s)`)
      }
    } catch (err: any) {
      setError(err.message)
    } finally {
      setBulkLoading(false)
    }
  }

  // Strategy handlers
  const handleCreateStrategy = () => {
    setIsCreateStrategyMode(true)
    setStrategyForm({ name: '', personaId: '', description: '', version: '1.0.0', isActive: true })
    setIsStrategyModalOpen(true)
  }

  const handleEditStrategy = (strategy: AllocationStrategy) => {
    setIsCreateStrategyMode(false)
    setSelectedStrategy(strategy)
    setStrategyForm({
      name: strategy.name,
      personaId: strategy.personaId,
      description: strategy.description || '',
      version: strategy.version,
      isActive: strategy.isActive,
    })
    setIsStrategyModalOpen(true)
  }

  const handleSaveStrategy = async () => {
    try {
      if (isCreateStrategyMode) {
        await allocationsApi.create(strategyForm)
      } else if (selectedStrategy) {
        await allocationsApi.update(selectedStrategy.id, strategyForm)
      }
      await loadStrategies()
      setIsStrategyModalOpen(false)
      setSuccessMessage(isCreateStrategyMode ? 'Strategy created successfully' : 'Strategy updated successfully')
    } catch (err: any) {
      setError(err.message)
    }
  }

  const handleDeleteStrategy = async (id: string) => {
    if (!confirm('Are you sure you want to delete this strategy?')) return
    try {
      await allocationsApi.delete(id)
      await loadStrategies()
    } catch (err: any) {
      setError(err.message)
    }
  }

  const handleAddComponent = (strategy: AllocationStrategy) => {
    setSelectedStrategy(strategy)
    setComponentForm({ label: '', allocationPercent: 0, note: '' })
    setIsComponentModalOpen(true)
  }

  const handleSaveComponent = async () => {
    if (!selectedStrategy) return
    try {
      await allocationsApi.addComponent(selectedStrategy.id, componentForm)
      await loadStrategies()
      setIsComponentModalOpen(false)
    } catch (err: any) {
      setError(err.message)
    }
  }

  const handleDeleteComponent = async (strategyId: string, componentId: string) => {
    try {
      await allocationsApi.deleteComponent(strategyId, componentId)
      await loadStrategies()
    } catch (err: any) {
      setError(err.message)
    }
  }

  const getTotalAllocation = (components?: AllocationComponent[]) => {
    return components?.reduce((sum, c) => sum + c.allocationPercent, 0) || 0
  }

  const getRiskBandStyle = (band: string) => {
    switch (band) {
      case 'Capital Protection':
        return { bg: isDark ? 'rgba(16, 185, 129, 0.15)' : 'rgba(16, 185, 129, 0.1)', color: colors.success }
      case 'Balanced Growth':
        return { bg: isDark ? 'rgba(96, 165, 250, 0.15)' : 'rgba(37, 99, 235, 0.1)', color: colors.primary }
      case 'Accelerated Growth':
        return { bg: isDark ? 'rgba(167, 139, 250, 0.15)' : 'rgba(124, 58, 237, 0.1)', color: colors.secondary }
      default:
        return { bg: colors.chipBg, color: colors.textSecondary }
    }
  }

  const mainTabs = [
    { id: 'personas' as MainTab, label: 'Personas', icon: ICONS.user },
    { id: 'allocations' as MainTab, label: 'Allocations', icon: ICONS.pieChart },
  ]

  const personaSubTabs = [
    { id: 'list' as PersonaSubTab, label: 'All Personas', icon: ICONS.user },
    { id: 'bulk' as PersonaSubTab, label: 'Bulk Create', icon: ICONS.copy },
    { id: 'results' as PersonaSubTab, label: 'Results', icon: ICONS.chart },
  ]

  return (
    <AdminLayout title="ML Configuration">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Page Header */}
        <div className="mb-6">
          <p className="text-sm" style={{ color: colors.textSecondary }}>
            Configure investor personas and allocation strategies for the ML recommendation engine.
          </p>
        </div>

        {/* Main Tabs */}
        <div className="flex gap-2 mb-6">
          {mainTabs.map(tab => (
            <button
              key={tab.id}
              onClick={() => setMainTab(tab.id)}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-full font-medium text-sm transition-all ${
                mainTab === tab.id ? 'text-white' : ''
              }`}
              style={{
                background: mainTab === tab.id
                  ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                  : colors.chipBg,
                color: mainTab === tab.id ? 'white' : colors.textSecondary,
                border: `1px solid ${mainTab === tab.id ? 'transparent' : colors.chipBorder}`,
              }}
            >
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={tab.icon} />
              </svg>
              {tab.label}
            </button>
          ))}
        </div>

        {/* Messages */}
        {successMessage && (
          <div
            className="mb-6 p-4 rounded-xl flex items-center justify-between"
            style={{ background: isDark ? 'rgba(52, 211, 153, 0.15)' : 'rgba(16, 185, 129, 0.1)', border: `1px solid ${colors.success}` }}
          >
            <span style={{ color: colors.success }}>{successMessage}</span>
            <button onClick={() => setSuccessMessage(null)} className="text-sm underline" style={{ color: colors.success }}>Dismiss</button>
          </div>
        )}
        {error && (
          <div
            className="mb-6 p-4 rounded-xl flex items-center justify-between"
            style={{ background: isDark ? 'rgba(248, 113, 113, 0.15)' : 'rgba(239, 68, 68, 0.1)', border: `1px solid ${colors.error}` }}
          >
            <span style={{ color: colors.error }}>{error}</span>
            <button onClick={() => setError(null)} className="text-sm underline" style={{ color: colors.error }}>Dismiss</button>
          </div>
        )}

        {/* PERSONAS TAB */}
        {mainTab === 'personas' && (
          <>
            {/* Sub-tabs */}
            <div className="flex items-center justify-between mb-6">
              <div className="flex gap-2 overflow-x-auto pb-2">
                {personaSubTabs.map(tab => (
                  <button
                    key={tab.id}
                    onClick={() => setPersonaSubTab(tab.id)}
                    className="flex items-center gap-2 px-3 py-2 rounded-lg font-medium text-xs transition-all whitespace-nowrap"
                    style={{
                      background: personaSubTab === tab.id ? colors.chipBg : 'transparent',
                      color: personaSubTab === tab.id ? colors.primary : colors.textSecondary,
                      border: `1px solid ${personaSubTab === tab.id ? colors.chipBorder : 'transparent'}`,
                    }}
                  >
                    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={tab.icon} />
                    </svg>
                    {tab.label}
                  </button>
                ))}
              </div>
              {personaSubTab === 'list' && (
                <button
                  onClick={handleCreatePersona}
                  className="flex items-center gap-2 px-4 py-2 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
                  style={{
                    background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`,
                    boxShadow: `0 4px 14px ${colors.glassShadow}`
                  }}
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.plus} />
                  </svg>
                  Add Persona
                </button>
              )}
            </div>

            {/* Personas List */}
            {personaSubTab === 'list' && (
              loadingPersonas ? (
                <div className="flex items-center justify-center py-12">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2" style={{ borderColor: colors.primary }} />
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {personas.map((persona) => {
                    const riskStyle = getRiskBandStyle(persona.riskBand)
                    return (
                      <div
                        key={persona.id}
                        className="p-5 rounded-xl transition-all hover:shadow-lg"
                        style={{
                          background: colors.cardBackground,
                          border: `1px solid ${colors.cardBorder}`,
                          boxShadow: `0 4px 24px ${colors.glassShadow}`
                        }}
                      >
                        <div className="flex items-start justify-between mb-4">
                          <div className="flex items-center gap-3">
                            <div
                              className="w-12 h-12 rounded-xl flex items-center justify-center text-white font-bold text-lg"
                              style={{ background: `linear-gradient(135deg, ${persona.colorPrimary}, ${persona.colorSecondary})` }}
                            >
                              {persona.name.charAt(0)}
                            </div>
                            <div>
                              <h3 className="text-sm font-semibold" style={{ color: colors.textPrimary }}>{persona.name}</h3>
                              <span
                                className="text-xs px-2 py-0.5 rounded mt-1 inline-block"
                                style={{ background: riskStyle.bg, color: riskStyle.color }}
                              >
                                {persona.riskBand}
                              </span>
                            </div>
                          </div>
                          <div
                            className="flex items-center gap-1.5 px-2 py-1 rounded"
                            style={{ background: persona.isActive ? (isDark ? 'rgba(52, 211, 153, 0.15)' : 'rgba(16, 185, 129, 0.1)') : colors.chipBg }}
                          >
                            <span className="w-2 h-2 rounded-full" style={{ background: persona.isActive ? colors.success : colors.textTertiary }} />
                            <span className="text-xs" style={{ color: persona.isActive ? colors.success : colors.textTertiary }}>
                              {persona.isActive ? 'Active' : 'Inactive'}
                            </span>
                          </div>
                        </div>
                        <p className="text-sm mb-4 line-clamp-2" style={{ color: colors.textSecondary }}>{persona.description}</p>
                        <div className="flex items-center gap-4 mb-4">
                          <div className="flex items-center gap-2 px-3 py-2 rounded-xl flex-1" style={{ background: colors.chipBg, border: `1px solid ${colors.chipBorder}` }}>
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.primary }}>
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.rules} />
                            </svg>
                            <span className="text-xs font-medium" style={{ color: colors.textSecondary }}>{persona.rules?.length || 0} Rules</span>
                          </div>
                          <div className="flex items-center gap-2 px-3 py-2 rounded-xl flex-1" style={{ background: colors.chipBg, border: `1px solid ${colors.chipBorder}` }}>
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.primary }}>
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.insights} />
                            </svg>
                            <span className="text-xs font-medium" style={{ color: colors.textSecondary }}>{persona.insights?.length || 0} Insights</span>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => handleEditPersona(persona)}
                            className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-full text-sm font-medium transition-all hover:opacity-80"
                            style={{ background: colors.chipBg, color: colors.primary, border: `1px solid ${colors.chipBorder}` }}
                          >
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.edit} />
                            </svg>
                            Edit
                          </button>
                          <button
                            onClick={() => handleDeletePersona(persona.id)}
                            className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-full text-sm font-medium transition-all hover:opacity-80"
                            style={{ background: isDark ? 'rgba(248, 113, 113, 0.15)' : 'rgba(239, 68, 68, 0.1)', color: colors.error }}
                          >
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.trash} />
                            </svg>
                          </button>
                        </div>
                      </div>
                    )
                  })}
                  {personas.length === 0 && (
                    <div className="col-span-full p-12 rounded-xl text-center" style={{ background: colors.cardBackground, border: `1px solid ${colors.cardBorder}` }}>
                      <div className="w-16 h-16 rounded-xl flex items-center justify-center mx-auto mb-4" style={{ background: colors.chipBg }}>
                        <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.textTertiary }}>
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.user} />
                        </svg>
                      </div>
                      <h3 className="text-base font-semibold mb-2" style={{ color: colors.textPrimary }}>No Personas Yet</h3>
                      <p className="text-sm mb-4" style={{ color: colors.textSecondary }}>Create your first investor persona to get started.</p>
                      <button
                        onClick={handleCreatePersona}
                        className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
                        style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.plus} />
                        </svg>
                        Add Persona
                      </button>
                    </div>
                  )}
                </div>
              )
            )}

            {/* Bulk Create */}
            {personaSubTab === 'bulk' && (
              <div className="p-6 rounded-xl" style={{ background: colors.cardBackground, border: `1px solid ${colors.cardBorder}` }}>
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h2 className="text-lg font-bold" style={{ color: colors.textPrimary }}>Bulk Create Personas</h2>
                    <p className="text-sm mt-1" style={{ color: colors.textSecondary }}>Create multiple personas at once</p>
                  </div>
                  <button
                    onClick={addBulkPersonaRow}
                    className="flex items-center gap-2 px-4 py-2 rounded-full font-medium text-sm transition-all hover:opacity-80"
                    style={{ background: colors.chipBg, color: colors.primary, border: `1px solid ${colors.chipBorder}` }}
                  >
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.plus} />
                    </svg>
                    Add Row
                  </button>
                </div>
                <div className="space-y-4">
                  {bulkPersonas.map((persona, index) => (
                    <div key={index} className="p-4 rounded-xl" style={{ background: colors.chipBg, border: `1px solid ${colors.chipBorder}` }}>
                      <div className="flex items-center justify-between mb-3">
                        <span className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>PERSONA {index + 1}</span>
                        {bulkPersonas.length > 1 && (
                          <button onClick={() => removeBulkPersonaRow(index)} className="p-1.5 rounded-lg transition-all hover:opacity-70" style={{ background: isDark ? 'rgba(248, 113, 113, 0.15)' : 'rgba(239, 68, 68, 0.1)' }}>
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.error }}>
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.trash} />
                            </svg>
                          </button>
                        )}
                      </div>
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                        <div>
                          <label className="block text-xs font-medium mb-1" style={{ color: colors.textSecondary }}>Name</label>
                          <input
                            type="text"
                            value={persona.name}
                            onChange={(e) => updateBulkPersona(index, 'name', e.target.value)}
                            className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                            style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                            placeholder="Persona name"
                          />
                        </div>
                        <div>
                          <label className="block text-xs font-medium mb-1" style={{ color: colors.textSecondary }}>Slug</label>
                          <input
                            type="text"
                            value={persona.slug}
                            onChange={(e) => updateBulkPersona(index, 'slug', e.target.value)}
                            className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                            style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                            placeholder="persona-slug"
                          />
                        </div>
                        <div>
                          <label className="block text-xs font-medium mb-1" style={{ color: colors.textSecondary }}>Risk Band</label>
                          <select
                            value={persona.riskBand}
                            onChange={(e) => updateBulkPersona(index, 'riskBand', e.target.value)}
                            className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                            style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                          >
                            <option value="Capital Protection">Capital Protection</option>
                            <option value="Balanced Growth">Balanced Growth</option>
                            <option value="Accelerated Growth">Accelerated Growth</option>
                          </select>
                        </div>
                        <div className="md:col-span-3">
                          <label className="block text-xs font-medium mb-1" style={{ color: colors.textSecondary }}>Description</label>
                          <input
                            type="text"
                            value={persona.description}
                            onChange={(e) => updateBulkPersona(index, 'description', e.target.value)}
                            className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                            style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                            placeholder="Brief description"
                          />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
                <div className="flex justify-end mt-6">
                  <button
                    onClick={handleBulkCreate}
                    disabled={bulkLoading}
                    className="flex items-center gap-2 px-6 py-2.5 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg disabled:opacity-50"
                    style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                  >
                    {bulkLoading ? (
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                    ) : (
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.check} />
                      </svg>
                    )}
                    Create {bulkPersonas.filter(p => p.name && p.slug).length} Persona(s)
                  </button>
                </div>
              </div>
            )}

            {/* Classification Results */}
            {personaSubTab === 'results' && (
              <div className="space-y-6">
                {classificationStats && (
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div className="p-4 rounded-xl" style={{ background: colors.cardBackground, border: `1px solid ${colors.cardBorder}` }}>
                      <span className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>TOTAL CLASSIFICATIONS</span>
                      <p className="text-2xl font-bold mt-1" style={{ color: colors.textPrimary }}>{classificationStats.totalClassifications}</p>
                    </div>
                    {classificationStats.personas.slice(0, 3).map(p => (
                      <div key={p.id} className="p-4 rounded-xl" style={{ background: colors.cardBackground, border: `1px solid ${colors.cardBorder}` }}>
                        <span className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>{p.name}</span>
                        <p className="text-2xl font-bold mt-1" style={{ color: colors.textPrimary }}>{p.userCount}</p>
                        <span className="text-xs" style={{ color: colors.textTertiary }}>users assigned</span>
                      </div>
                    ))}
                  </div>
                )}
                <div className="rounded-xl overflow-hidden" style={{ background: colors.cardBackground, border: `1px solid ${colors.cardBorder}` }}>
                  <div className="p-4 border-b" style={{ borderColor: colors.chipBorder }}>
                    <h2 className="text-lg font-bold" style={{ color: colors.textPrimary }}>Recent Classifications</h2>
                  </div>
                  {loadingResults ? (
                    <div className="flex items-center justify-center py-12">
                      <div className="animate-spin rounded-full h-8 w-8 border-b-2" style={{ borderColor: colors.primary }} />
                    </div>
                  ) : classificationLogs.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-12 text-center">
                      <p className="text-sm" style={{ color: colors.textSecondary }}>No classification results yet</p>
                    </div>
                  ) : (
                    <div className="overflow-x-auto">
                      <table className="w-full">
                        <thead>
                          <tr style={{ background: `${colors.primary}08` }}>
                            <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>Date</th>
                            <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>User</th>
                            <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>Persona</th>
                            <th className="text-left text-xs font-semibold uppercase tracking-wide px-4 py-3" style={{ color: colors.primary }}>Confidence</th>
                          </tr>
                        </thead>
                        <tbody>
                          {classificationLogs.map((log, index) => (
                            <tr
                              key={log.id}
                              className="transition-all"
                              style={{
                                background: 'transparent',
                                borderBottom: `1px solid ${colors.cardBorder}`,
                              }}
                              onMouseEnter={(e) => e.currentTarget.style.background = colors.chipBg}
                              onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                            >
                              <td className="px-4 py-3">
                                <span className="text-sm" style={{ color: colors.textPrimary }}>{new Date(log.createdAt).toLocaleDateString()}</span>
                              </td>
                              <td className="px-4 py-3">
                                <span className="text-sm" style={{ color: colors.textPrimary }}>{log.user?.profile?.name || 'Anonymous'}</span>
                              </td>
                              <td className="px-4 py-3">
                                <span className="text-xs px-2 py-1 rounded font-medium" style={{ background: colors.chipBg, color: colors.primary }}>
                                  {log.prediction?.personaSlug || 'Unknown'}
                                </span>
                              </td>
                              <td className="px-4 py-3">
                                <span className="text-sm font-bold" style={{ color: colors.primary }}>{(log.confidence * 100).toFixed(1)}%</span>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              </div>
            )}
          </>
        )}

        {/* ALLOCATIONS TAB */}
        {mainTab === 'allocations' && (
          <>
            <div className="flex items-center justify-end mb-6">
              <button
                onClick={handleCreateStrategy}
                className="flex items-center gap-2 px-4 py-2 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
                style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
              >
                <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.plus} />
                </svg>
                Add Strategy
              </button>
            </div>

            {loadingStrategies ? (
              <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2" style={{ borderColor: colors.primary }} />
              </div>
            ) : strategies.length === 0 ? (
              <div className="p-12 rounded-xl text-center" style={{ background: colors.cardBackground, border: `1px solid ${colors.cardBorder}` }}>
                <div className="w-16 h-16 rounded-xl flex items-center justify-center mx-auto mb-4" style={{ background: colors.chipBg }}>
                  <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor" style={{ color: colors.textTertiary }}>
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d={ICONS.pieChart} />
                  </svg>
                </div>
                <h3 className="text-base font-semibold mb-2" style={{ color: colors.textPrimary }}>No Allocation Strategies</h3>
                <p className="text-sm mb-4" style={{ color: colors.textSecondary }}>Create your first allocation strategy to get started.</p>
                <button
                  onClick={handleCreateStrategy}
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full font-semibold text-sm text-white"
                  style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}
                >
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={ICONS.plus} />
                  </svg>
                  Add Strategy
                </button>
              </div>
            ) : (
              <div className="space-y-4">
                {strategies.map((strategy) => {
                  const totalAllocation = getTotalAllocation(strategy.components)
                  return (
                    <div key={strategy.id} className="rounded-xl overflow-hidden" style={{ background: colors.cardBackground, border: `1px solid ${colors.cardBorder}` }}>
                      <div className="p-5">
                        <div className="flex items-start justify-between mb-4">
                          <div className="flex items-start gap-4">
                            <div className="w-12 h-12 rounded-xl flex items-center justify-center text-white" style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}>
                              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                                <path strokeLinecap="round" strokeLinejoin="round" d={ICONS.pieChart} />
                              </svg>
                            </div>
                            <div>
                              <div className="flex items-center gap-2 mb-1">
                                <h3 className="text-base font-semibold" style={{ color: colors.textPrimary }}>{strategy.name}</h3>
                                <span className="text-xs px-2 py-0.5 rounded" style={{ background: `${colors.primary}15`, color: colors.primary }}>v{strategy.version}</span>
                                {strategy.isActive ? (
                                  <span className="text-xs px-2 py-0.5 rounded" style={{ background: `${colors.success}15`, color: colors.success }}>Active</span>
                                ) : (
                                  <span className="text-xs px-2 py-0.5 rounded" style={{ background: colors.chipBg, color: colors.textTertiary }}>Inactive</span>
                                )}
                              </div>
                              <p className="text-sm" style={{ color: colors.textSecondary }}>{strategy.description}</p>
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            <button onClick={() => handleEditStrategy(strategy)} className="px-3 py-1.5 rounded-full text-xs font-medium" style={{ background: colors.chipBg, color: colors.textSecondary }}>Edit</button>
                            <button onClick={() => handleDeleteStrategy(strategy.id)} className="px-3 py-1.5 rounded-full text-xs font-medium" style={{ background: `${colors.error}10`, color: colors.error }}>Delete</button>
                          </div>
                        </div>

                        <div className="mb-4">
                          <div className="flex items-center justify-between mb-3">
                            <span className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>Allocation Components</span>
                            <div className="flex items-center gap-3">
                              <span className="text-xs font-medium" style={{ color: totalAllocation === 100 ? colors.success : colors.warning }}>Total: {totalAllocation}%</span>
                              <button onClick={() => handleAddComponent(strategy)} className="text-xs font-medium flex items-center gap-1" style={{ color: colors.primary }}>
                                <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                                  <path strokeLinecap="round" strokeLinejoin="round" d={ICONS.plus} />
                                </svg>
                                Add Component
                              </button>
                            </div>
                          </div>
                          <div className="h-10 rounded-xl overflow-hidden flex mb-4" style={{ background: colors.chipBg }}>
                            {strategy.components?.map((comp, index) => {
                              const color = ALLOCATION_COLORS[index % ALLOCATION_COLORS.length]
                              return (
                                <div key={comp.id} className="flex items-center justify-center text-white text-xs font-semibold" style={{ width: `${comp.allocationPercent}%`, background: color.bg }} title={`${comp.label}: ${comp.allocationPercent}%`}>
                                  {comp.allocationPercent >= 12 && `${comp.allocationPercent}%`}
                                </div>
                              )
                            })}
                          </div>
                          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                            {strategy.components?.map((comp, index) => {
                              const color = ALLOCATION_COLORS[index % ALLOCATION_COLORS.length]
                              return (
                                <div key={comp.id} className="p-3 rounded-xl" style={{ background: isDark ? `${color.bg}25` : color.light, borderLeft: `3px solid ${color.bg}` }}>
                                  <div className="flex items-center justify-between mb-1">
                                    <span className="text-sm font-medium" style={{ color: colors.textPrimary }}>{comp.label}</span>
                                    <button onClick={() => handleDeleteComponent(strategy.id, comp.id)} className="w-5 h-5 rounded flex items-center justify-center" style={{ background: isDark ? 'rgba(248, 113, 113, 0.2)' : 'rgba(239, 68, 68, 0.1)', color: colors.error }}>
                                      <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                                        <path strokeLinecap="round" strokeLinejoin="round" d={ICONS.close} />
                                      </svg>
                                    </button>
                                  </div>
                                  <div className="text-lg font-bold" style={{ color: isDark ? '#FFFFFF' : color.bg }}>{comp.allocationPercent}%</div>
                                  {comp.note && <div className="text-xs mt-1" style={{ color: colors.textSecondary }}>{comp.note}</div>}
                                </div>
                              )
                            })}
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </>
        )}

        {/* Persona Modal */}
        <AdminModal isOpen={isPersonaModalOpen} onClose={() => setIsPersonaModalOpen(false)} title={isCreatePersonaMode ? 'Create Persona' : 'Edit Persona'} size="lg">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>NAME</label>
              <input
                type="text"
                value={personaForm.name}
                onChange={(e) => setPersonaForm({ ...personaForm, name: e.target.value, slug: e.target.value.toLowerCase().replace(/\s+/g, '-') })}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                placeholder="e.g., Balanced Voyager"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>SLUG</label>
              <input
                type="text"
                value={personaForm.slug}
                onChange={(e) => setPersonaForm({ ...personaForm, slug: e.target.value })}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>DESCRIPTION</label>
              <textarea
                value={personaForm.description}
                onChange={(e) => setPersonaForm({ ...personaForm, description: e.target.value })}
                className="w-full px-4 py-3 rounded-xl text-sm focus:outline-none resize-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                rows={3}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>RISK BAND</label>
              <select
                value={personaForm.riskBand}
                onChange={(e) => setPersonaForm({ ...personaForm, riskBand: e.target.value })}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              >
                <option value="Capital Protection">Capital Protection</option>
                <option value="Balanced Growth">Balanced Growth</option>
                <option value="Accelerated Growth">Accelerated Growth</option>
              </select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>PRIMARY COLOR</label>
                <input type="color" value={personaForm.colorPrimary} onChange={(e) => setPersonaForm({ ...personaForm, colorPrimary: e.target.value })} className="w-full h-10 rounded-xl cursor-pointer" />
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>SECONDARY COLOR</label>
                <input type="color" value={personaForm.colorSecondary} onChange={(e) => setPersonaForm({ ...personaForm, colorSecondary: e.target.value })} className="w-full h-10 rounded-xl cursor-pointer" />
              </div>
            </div>
            <div className="flex items-center gap-3 pt-4">
              <button onClick={() => setIsPersonaModalOpen(false)} className="flex-1 py-2.5 rounded-full font-semibold text-sm" style={{ background: colors.chipBg, color: colors.textPrimary }}>Cancel</button>
              <button onClick={handleSavePersona} className="flex-1 py-2.5 rounded-full font-semibold text-sm text-white" style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}>
                {isCreatePersonaMode ? 'Create' : 'Save Changes'}
              </button>
            </div>
          </div>
        </AdminModal>

        {/* Strategy Modal */}
        <AdminModal isOpen={isStrategyModalOpen} onClose={() => setIsStrategyModalOpen(false)} title={isCreateStrategyMode ? 'Create Strategy' : 'Edit Strategy'} size="lg">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>NAME</label>
              <input
                type="text"
                value={strategyForm.name}
                onChange={(e) => setStrategyForm({ ...strategyForm, name: e.target.value })}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                placeholder="e.g., Conservative Shield Strategy"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>DESCRIPTION</label>
              <textarea
                value={strategyForm.description}
                onChange={(e) => setStrategyForm({ ...strategyForm, description: e.target.value })}
                className="w-full px-4 py-3 rounded-xl text-sm focus:outline-none resize-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                rows={3}
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>VERSION</label>
                <input
                  type="text"
                  value={strategyForm.version}
                  onChange={(e) => setStrategyForm({ ...strategyForm, version: e.target.value })}
                  className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                  style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                />
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>PERSONA ID</label>
                <select
                  value={strategyForm.personaId}
                  onChange={(e) => setStrategyForm({ ...strategyForm, personaId: e.target.value })}
                  className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                  style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                >
                  <option value="">Select persona...</option>
                  {personas.map(p => (
                    <option key={p.id} value={p.id}>{p.name}</option>
                  ))}
                </select>
              </div>
            </div>
            <div className="flex items-center gap-3 pt-4">
              <button onClick={() => setIsStrategyModalOpen(false)} className="flex-1 py-2.5 rounded-full font-semibold text-sm" style={{ background: colors.chipBg, color: colors.textPrimary }}>Cancel</button>
              <button onClick={handleSaveStrategy} className="flex-1 py-2.5 rounded-full font-semibold text-sm text-white" style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}>
                {isCreateStrategyMode ? 'Create' : 'Save Changes'}
              </button>
            </div>
          </div>
        </AdminModal>

        {/* Component Modal */}
        <AdminModal isOpen={isComponentModalOpen} onClose={() => setIsComponentModalOpen(false)} title="Add Component" size="md">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>LABEL</label>
              <input
                type="text"
                value={componentForm.label}
                onChange={(e) => setComponentForm({ ...componentForm, label: e.target.value })}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                placeholder="e.g., Large Cap Equity"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>ALLOCATION %</label>
              <input
                type="number"
                min="0"
                max="100"
                value={componentForm.allocationPercent}
                onChange={(e) => setComponentForm({ ...componentForm, allocationPercent: parseInt(e.target.value) || 0 })}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
              />
            </div>
            <div>
              <label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>NOTE</label>
              <input
                type="text"
                value={componentForm.note}
                onChange={(e) => setComponentForm({ ...componentForm, note: e.target.value })}
                className="w-full h-10 px-4 rounded-xl text-sm focus:outline-none"
                style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
                placeholder="Optional note"
              />
            </div>
            <div className="flex items-center gap-3 pt-4">
              <button onClick={() => setIsComponentModalOpen(false)} className="flex-1 py-2.5 rounded-full font-semibold text-sm" style={{ background: colors.chipBg, color: colors.textPrimary }}>Cancel</button>
              <button onClick={handleSaveComponent} className="flex-1 py-2.5 rounded-full font-semibold text-sm text-white" style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)` }}>Add Component</button>
            </div>
          </div>
        </AdminModal>
      </div>
    </AdminLayout>
  )
}

export default MLConfigPage
