/**
 * Prospects Page
 *
 * Manage sales pipeline and prospect relationships.
 * Includes pipeline view, list view, and conversion flow.
 */

import { useState } from 'react'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatCurrency, getStageColor } from '@/utils/fa'
import { Prospect, ProspectStage, LeadSource, ProspectFormData, ClientFormData } from '@/utils/faTypes'
import {
  FACard,
  FAStatCard,
  FAChip,
  FASearchInput,
  FASelect,
  FAButton,
  FAEmptyState,
  FAIconButton,
} from '@/components/advisor/shared'
import ProspectFormModal from '@/components/advisor/ProspectFormModal'
import ConvertToClientModal from '@/components/advisor/ConvertToClientModal'

// Pipeline stages
const STAGES: ProspectStage[] = ['Discovery', 'Analysis', 'Proposal', 'Negotiation', 'Closed Won', 'Closed Lost']

// Mock prospects data
const mockProspects: Prospect[] = [
  { id: '1', name: 'Ananya Reddy', email: 'ananya.reddy@email.com', phone: '+91 98765 11111', potentialAum: 5000000, stage: 'Negotiation', source: 'Referral', nextAction: 'Send final proposal', nextActionDate: '2024-01-22', createdAt: '2024-01-05', notes: 'Interested in aggressive growth funds' },
  { id: '2', name: 'Karthik Menon', email: 'karthik.m@email.com', phone: '+91 98765 22222', potentialAum: 2500000, stage: 'Analysis', source: 'Website', nextAction: 'Complete risk profiling', nextActionDate: '2024-01-23', createdAt: '2024-01-10', notes: 'First-time investor, needs education' },
  { id: '3', name: 'Deepa Nair', email: 'deepa.nair@email.com', phone: '+91 98765 33333', potentialAum: 7500000, stage: 'Discovery', source: 'LinkedIn', nextAction: 'Schedule intro call', nextActionDate: '2024-01-21', createdAt: '2024-01-15', notes: 'HNI, currently with competitor' },
  { id: '4', name: 'Rohit Verma', email: 'rohit.v@email.com', phone: '+91 98765 44444', potentialAum: 3200000, stage: 'Proposal', source: 'Referral', nextAction: 'Follow up on proposal', nextActionDate: '2024-01-24', createdAt: '2024-01-08', notes: 'Interested in tax saving options' },
  { id: '5', name: 'Sunita Agarwal', email: 'sunita.a@email.com', phone: '+91 98765 55555', potentialAum: 12000000, stage: 'Negotiation', source: 'Event', nextAction: 'Negotiate fees', nextActionDate: '2024-01-25', createdAt: '2024-01-02', notes: 'Family office, long-term relationship potential' },
  { id: '6', name: 'Manish Joshi', email: 'manish.j@email.com', phone: '+91 98765 66666', potentialAum: 1800000, stage: 'Discovery', source: 'Cold Call', nextAction: 'Send intro materials', nextActionDate: '2024-01-26', createdAt: '2024-01-18', notes: 'Young professional, starting investment journey' },
  { id: '7', name: 'Prerna Singh', email: 'prerna.s@email.com', phone: '+91 98765 77777', potentialAum: 4500000, stage: 'Closed Won', source: 'Referral', nextAction: 'Onboard client', nextActionDate: '2024-01-20', createdAt: '2023-12-15', notes: 'Successfully converted!' },
  { id: '8', name: 'Ashok Pillai', email: 'ashok.p@email.com', phone: '+91 98765 88888', potentialAum: 2000000, stage: 'Closed Lost', source: 'Website', nextAction: '-', nextActionDate: '', createdAt: '2023-12-20', notes: 'Went with another advisor' },
]

const ProspectsPage = () => {
  const { colors, isDark } = useFATheme()
  const [prospects, setProspects] = useState<Prospect[]>(mockProspects)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStage, setFilterStage] = useState<string>('all')
  const [viewMode, setViewMode] = useState<'pipeline' | 'list'>('pipeline')

  // Modal states
  const [showProspectForm, setShowProspectForm] = useState(false)
  const [editingProspect, setEditingProspect] = useState<Prospect | null>(null)
  const [showConvertModal, setShowConvertModal] = useState(false)
  const [convertingProspect, setConvertingProspect] = useState<Prospect | null>(null)
  const [showMoveStage, setShowMoveStage] = useState<string | null>(null)

  const filteredProspects = prospects.filter(prospect => {
    const matchesSearch = prospect.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         prospect.email.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStage = filterStage === 'all' || prospect.stage === filterStage
    return matchesSearch && matchesStage
  })

  const activeProspects = prospects.filter(p => !['Closed Won', 'Closed Lost'].includes(p.stage))
  const totalPipelineValue = activeProspects.reduce((sum, p) => sum + p.potentialAum, 0)
  const wonThisMonth = prospects.filter(p => p.stage === 'Closed Won').length
  const wonValue = prospects.filter(p => p.stage === 'Closed Won').reduce((s, p) => s + p.potentialAum, 0)

  const getProspectsByStage = (stage: ProspectStage) => filteredProspects.filter(p => p.stage === stage)

  const handleAddProspect = (data: ProspectFormData) => {
    const newProspect: Prospect = {
      id: `p${Date.now()}`,
      ...data,
      stage: 'Discovery',
      nextAction: 'Schedule intro call',
      nextActionDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      createdAt: new Date().toISOString().split('T')[0],
      notes: data.notes || '',
    }
    setProspects([newProspect, ...prospects])
  }

  const handleEditProspect = (prospect: Prospect) => {
    setEditingProspect(prospect)
    setShowProspectForm(true)
  }

  const handleUpdateProspect = (data: ProspectFormData) => {
    if (editingProspect) {
      setProspects(prospects.map(p =>
        p.id === editingProspect.id
          ? { ...p, ...data }
          : p
      ))
    }
    setEditingProspect(null)
  }

  const handleMoveStage = (prospectId: string, newStage: ProspectStage) => {
    setProspects(prospects.map(p =>
      p.id === prospectId
        ? { ...p, stage: newStage }
        : p
    ))
    setShowMoveStage(null)
  }

  const handleConvertClick = (prospect: Prospect) => {
    // First move to Closed Won if not already
    if (prospect.stage !== 'Closed Won') {
      setProspects(prospects.map(p =>
        p.id === prospect.id
          ? { ...p, stage: 'Closed Won' }
          : p
      ))
    }
    setConvertingProspect(prospect)
    setShowConvertModal(true)
  }

  const handleConvertToClient = (clientData: ClientFormData) => {
    // In a real app, this would create the client via API
    // Remove from prospects list (they're now a client)
    setProspects(prospects.filter(p => p.id !== convertingProspect?.id))
    setConvertingProspect(null)
  }

  return (
    <AdvisorLayout title="Prospects">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <p className="text-sm" style={{ color: colors.textSecondary }}>Track and manage your sales pipeline</p>
          </div>
          <FAButton
            onClick={() => {
              setEditingProspect(null)
              setShowProspectForm(true)
            }}
            className="flex items-center gap-2"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4v16m8-8H4" />
            </svg>
            Add Prospect
          </FAButton>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-4 gap-4 mb-8">
          <FAStatCard
            label="Active Prospects"
            value={activeProspects.length.toString()}
            change="+3 this week"
            accentColor={colors.primary}
          />
          <FAStatCard
            label="Pipeline Value"
            value={formatCurrency(totalPipelineValue)}
            change="Potential AUM"
            accentColor={colors.secondary}
          />
          <FAStatCard
            label="Won This Month"
            value={wonThisMonth.toString()}
            change={formatCurrency(wonValue)}
            accentColor={colors.success}
          />
          <FAStatCard
            label="Conversion Rate"
            value="28%"
            change="+5% vs last month"
            accentColor={colors.warning}
          />
        </div>

        {/* Filters & View Toggle */}
        <FACard className="mb-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4 flex-1">
              <div className="flex-1 max-w-md">
                <FASearchInput
                  placeholder="Search prospects..."
                  value={searchTerm}
                  onChange={setSearchTerm}
                />
              </div>
              <FASelect
                options={[
                  { value: 'all', label: 'All Stages' },
                  ...STAGES.map(stage => ({ value: stage, label: stage }))
                ]}
                value={filterStage}
                onChange={(e) => setFilterStage(e.target.value)}
                containerClassName="w-40"
              />
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setViewMode('pipeline')}
                className="p-2 rounded-lg transition-all"
                style={{
                  background: viewMode === 'pipeline' ? colors.chipBg : 'transparent',
                  color: viewMode === 'pipeline' ? colors.primary : colors.textTertiary
                }}
                title="Pipeline View"
              >
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2" />
                </svg>
              </button>
              <button
                onClick={() => setViewMode('list')}
                className="p-2 rounded-lg transition-all"
                style={{
                  background: viewMode === 'list' ? colors.chipBg : 'transparent',
                  color: viewMode === 'list' ? colors.primary : colors.textTertiary
                }}
                title="List View"
              >
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 10h16M4 14h16M4 18h16" />
                </svg>
              </button>
            </div>
          </div>
        </FACard>

        {/* Pipeline View */}
        {viewMode === 'pipeline' && (
          <div className="grid grid-cols-4 gap-4">
            {(['Discovery', 'Analysis', 'Proposal', 'Negotiation'] as ProspectStage[]).map(stage => (
              <div key={stage}>
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className="w-2 h-2 rounded-full" style={{ background: getStageColor(stage, colors) }} />
                    <span className="text-sm font-semibold" style={{ color: colors.textPrimary }}>{stage}</span>
                  </div>
                  <span
                    className="text-xs px-2 py-0.5 rounded-full"
                    style={{ background: colors.chipBg, color: colors.textSecondary }}
                  >
                    {getProspectsByStage(stage).length}
                  </span>
                </div>
                <div className="space-y-3">
                  {getProspectsByStage(stage).map(prospect => (
                    <div
                      key={prospect.id}
                      className="p-3 rounded-xl cursor-pointer transition-all hover:-translate-y-0.5"
                      style={{
                        background: colors.cardBackground,
                        backdropFilter: 'blur(20px)',
                        border: `1px solid ${colors.cardBorder}`,
                        boxShadow: `0 2px 10px ${colors.glassShadow}`
                      }}
                      onClick={() => handleEditProspect(prospect)}
                    >
                      <div className="flex items-center gap-2 mb-2">
                        <div
                          className="w-8 h-8 rounded-lg flex items-center justify-center text-white font-semibold text-sm"
                          style={{ background: `linear-gradient(135deg, ${getStageColor(prospect.stage, colors)} 0%, ${colors.primaryDark} 100%)` }}
                        >
                          {prospect.name.charAt(0)}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-semibold truncate" style={{ color: colors.textPrimary }}>{prospect.name}</p>
                          <p className="text-xs truncate" style={{ color: colors.textTertiary }}>{prospect.source}</p>
                        </div>
                      </div>
                      <p className="text-lg font-bold" style={{ color: colors.primary }}>{formatCurrency(prospect.potentialAum)}</p>
                      <div className="mt-2 pt-2 flex items-center justify-between" style={{ borderTop: `1px solid ${colors.cardBorder}` }}>
                        <p className="text-xs truncate flex-1" style={{ color: colors.textTertiary }}>Next: {prospect.nextAction}</p>
                        <div className="flex items-center gap-1 ml-2">
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              setShowMoveStage(showMoveStage === prospect.id ? null : prospect.id)
                            }}
                            className="p-1 rounded transition-all hover:scale-110"
                            style={{ background: colors.chipBg, color: colors.primary }}
                            title="Move Stage"
                          >
                            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                              <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                            </svg>
                          </button>
                        </div>
                      </div>

                      {/* Stage Move Dropdown */}
                      {showMoveStage === prospect.id && (
                        <div
                          className="mt-2 p-2 rounded-lg space-y-1"
                          style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}
                          onClick={(e) => e.stopPropagation()}
                        >
                          <p className="text-xs font-semibold mb-2" style={{ color: colors.textSecondary }}>Move to:</p>
                          {STAGES.filter(s => s !== prospect.stage && s !== 'Closed Lost').map(s => (
                            <button
                              key={s}
                              onClick={() => {
                                if (s === 'Closed Won') {
                                  handleConvertClick(prospect)
                                } else {
                                  handleMoveStage(prospect.id, s)
                                }
                              }}
                              className="w-full text-left px-2 py-1.5 rounded text-xs font-medium transition-all hover:bg-opacity-50"
                              style={{
                                color: s === 'Closed Won' ? colors.success : colors.textPrimary,
                                background: s === 'Closed Won' ? `${colors.success}15` : 'transparent',
                              }}
                            >
                              {s === 'Closed Won' ? 'Mark as Won & Convert' : s}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                  {getProspectsByStage(stage).length === 0 && (
                    <div
                      className="p-4 rounded-xl text-center"
                      style={{
                        background: colors.cardBackground,
                        border: `1px dashed ${colors.cardBorder}`
                      }}
                    >
                      <p className="text-xs" style={{ color: colors.textTertiary }}>No prospects</p>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* List View */}
        {viewMode === 'list' && (
          <div className="space-y-3">
            {filteredProspects.map(prospect => (
              <div
                key={prospect.id}
                className="p-4 rounded-2xl transition-all hover:-translate-y-0.5 cursor-pointer"
                style={{
                  background: isDark ? colors.pastelIndigo : colors.pastelPink,
                  border: `1px solid ${colors.cardBorder}`,
                  boxShadow: `0 4px 20px ${colors.glassShadow}`
                }}
                onClick={() => handleEditProspect(prospect)}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div
                      className="w-12 h-12 rounded-xl flex items-center justify-center text-white font-bold text-lg"
                      style={{ background: `linear-gradient(135deg, ${getStageColor(prospect.stage, colors)} 0%, ${colors.primaryDark} 100%)` }}
                    >
                      {prospect.name.charAt(0)}
                    </div>
                    <div>
                      <h3 className="font-semibold" style={{ color: colors.textPrimary }}>{prospect.name}</h3>
                      <p className="text-sm" style={{ color: colors.textSecondary }}>{prospect.email}</p>
                      <div className="flex items-center gap-3 mt-1">
                        <FAChip color={getStageColor(prospect.stage, colors)}>{prospect.stage}</FAChip>
                        <span className="text-xs" style={{ color: colors.textTertiary }}>
                          via {prospect.source}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-8">
                    <div className="text-right">
                      <p className="text-xs uppercase tracking-wider" style={{ color: colors.textTertiary }}>Potential AUM</p>
                      <p className="font-bold" style={{ color: colors.primary }}>{formatCurrency(prospect.potentialAum)}</p>
                    </div>
                    <div className="text-right max-w-[200px]">
                      <p className="text-xs uppercase tracking-wider" style={{ color: colors.textTertiary }}>Next Action</p>
                      <p className="text-sm truncate" style={{ color: colors.textPrimary }}>{prospect.nextAction}</p>
                    </div>
                    <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                      <button
                        className="p-2 rounded-lg transition-all hover:scale-105"
                        style={{ background: colors.chipBg, color: colors.primary }}
                        title="Call"
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                      </button>
                      <button
                        className="p-2 rounded-lg transition-all hover:scale-105"
                        style={{ background: colors.chipBg, color: colors.primary }}
                        title="Email"
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                        </svg>
                      </button>
                      {prospect.stage === 'Closed Won' ? (
                        <button
                          onClick={() => handleConvertClick(prospect)}
                          className="px-3 py-2 rounded-lg text-xs font-semibold transition-all hover:scale-105"
                          style={{
                            background: `linear-gradient(135deg, ${colors.success} 0%, ${colors.primary} 100%)`,
                            color: 'white',
                          }}
                          title="Convert to Client"
                        >
                          Convert
                        </button>
                      ) : (
                        <button
                          onClick={() => setShowMoveStage(showMoveStage === prospect.id ? null : prospect.id)}
                          className="p-2 rounded-lg transition-all hover:scale-105"
                          style={{ background: colors.chipBg, color: colors.primary }}
                          title="Move Stage"
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                          </svg>
                        </button>
                      )}
                    </div>
                  </div>
                </div>

                {/* Stage Move Dropdown (List View) */}
                {showMoveStage === prospect.id && (
                  <div
                    className="mt-4 p-3 rounded-xl flex flex-wrap gap-2"
                    style={{ background: colors.chipBg, border: `1px solid ${colors.cardBorder}` }}
                    onClick={(e) => e.stopPropagation()}
                  >
                    <span className="text-xs font-semibold w-full mb-1" style={{ color: colors.textSecondary }}>Move to:</span>
                    {STAGES.filter(s => s !== prospect.stage).map(s => (
                      <button
                        key={s}
                        onClick={() => {
                          if (s === 'Closed Won') {
                            handleConvertClick(prospect)
                          } else {
                            handleMoveStage(prospect.id, s)
                          }
                        }}
                        className="px-3 py-1.5 rounded-full text-xs font-semibold transition-all hover:scale-105"
                        style={{
                          background: s === 'Closed Won'
                            ? `linear-gradient(135deg, ${colors.success} 0%, ${colors.primary} 100%)`
                            : s === 'Closed Lost'
                            ? `${colors.error}15`
                            : `${getStageColor(s as ProspectStage, colors)}15`,
                          color: s === 'Closed Won'
                            ? 'white'
                            : s === 'Closed Lost'
                            ? colors.error
                            : getStageColor(s as ProspectStage, colors),
                          border: `1px solid ${s === 'Closed Won' ? 'transparent' : getStageColor(s as ProspectStage, colors)}30`,
                        }}
                      >
                        {s === 'Closed Won' ? 'Mark as Won & Convert' : s}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            ))}

            {filteredProspects.length === 0 && (
              <FAEmptyState
                icon={
                  <svg className="w-12 h-12" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M18 18.72a9.094 9.094 0 003.741-.479 3 3 0 00-4.682-2.72m.94 3.198l.001.031c0 .225-.012.447-.037.666A11.944 11.944 0 0112 21c-2.17 0-4.207-.576-5.963-1.584A6.062 6.062 0 016 18.719m12 0a5.971 5.971 0 00-.941-3.197m0 0A5.995 5.995 0 0012 12.75a5.995 5.995 0 00-5.058 2.772m0 0a3 3 0 00-4.681 2.72 8.986 8.986 0 003.74.477m.94-3.197a5.971 5.971 0 00-.94 3.197M15 6.75a3 3 0 11-6 0 3 3 0 016 0zm6 3a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0zm-13.5 0a2.25 2.25 0 11-4.5 0 2.25 2.25 0 014.5 0z" />
                  </svg>
                }
                title="No prospects found"
                description="Try adjusting your search or add a new prospect"
              />
            )}
          </div>
        )}

        {/* Closed Deals Section */}
        {viewMode === 'pipeline' && (
          <div className="mt-8">
            <h3 className="text-sm font-semibold uppercase tracking-wider mb-4" style={{ color: colors.primary }}>
              Closed Deals
            </h3>
            <div className="grid grid-cols-2 gap-4">
              {/* Won */}
              <FACard>
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-8 h-8 rounded-lg flex items-center justify-center"
                      style={{ background: `${colors.success}15`, color: colors.success }}
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <span className="font-semibold" style={{ color: colors.success }}>Won</span>
                  </div>
                  <span className="text-sm font-bold" style={{ color: colors.success }}>
                    {getProspectsByStage('Closed Won').length}
                  </span>
                </div>
                <div className="space-y-2">
                  {getProspectsByStage('Closed Won').map(p => (
                    <div
                      key={p.id}
                      className="p-3 rounded-lg flex items-center justify-between cursor-pointer transition-all hover:scale-[1.01]"
                      style={{ background: `${colors.success}08`, border: `1px solid ${colors.success}20` }}
                      onClick={() => handleConvertClick(p)}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className="w-8 h-8 rounded-lg flex items-center justify-center text-white font-semibold text-sm"
                          style={{ background: colors.success }}
                        >
                          {p.name.charAt(0)}
                        </div>
                        <div>
                          <p className="text-sm font-medium" style={{ color: colors.textPrimary }}>{p.name}</p>
                          <p className="text-xs" style={{ color: colors.textTertiary }}>{p.source}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="font-bold" style={{ color: colors.success }}>{formatCurrency(p.potentialAum)}</p>
                        <button
                          className="text-xs font-semibold underline"
                          style={{ color: colors.primary }}
                        >
                          Convert
                        </button>
                      </div>
                    </div>
                  ))}
                  {getProspectsByStage('Closed Won').length === 0 && (
                    <p className="text-sm text-center py-4" style={{ color: colors.textTertiary }}>
                      No won deals yet
                    </p>
                  )}
                </div>
              </FACard>

              {/* Lost */}
              <FACard>
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-8 h-8 rounded-lg flex items-center justify-center"
                      style={{ background: `${colors.error}15`, color: colors.error }}
                    >
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <span className="font-semibold" style={{ color: colors.error }}>Lost</span>
                  </div>
                  <span className="text-sm font-bold" style={{ color: colors.error }}>
                    {getProspectsByStage('Closed Lost').length}
                  </span>
                </div>
                <div className="space-y-2">
                  {getProspectsByStage('Closed Lost').map(p => (
                    <div
                      key={p.id}
                      className="p-3 rounded-lg flex items-center justify-between"
                      style={{ background: `${colors.error}05`, border: `1px solid ${colors.error}15` }}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className="w-8 h-8 rounded-lg flex items-center justify-center text-white font-semibold text-sm opacity-60"
                          style={{ background: colors.error }}
                        >
                          {p.name.charAt(0)}
                        </div>
                        <div>
                          <p className="text-sm font-medium" style={{ color: colors.textSecondary }}>{p.name}</p>
                          <p className="text-xs" style={{ color: colors.textTertiary }}>{p.notes}</p>
                        </div>
                      </div>
                      <p className="text-sm" style={{ color: colors.textTertiary }}>{formatCurrency(p.potentialAum)}</p>
                    </div>
                  ))}
                  {getProspectsByStage('Closed Lost').length === 0 && (
                    <p className="text-sm text-center py-4" style={{ color: colors.textTertiary }}>
                      No lost deals
                    </p>
                  )}
                </div>
              </FACard>
            </div>
          </div>
        )}
      </div>

      {/* Prospect Form Modal */}
      <ProspectFormModal
        isOpen={showProspectForm}
        onClose={() => {
          setShowProspectForm(false)
          setEditingProspect(null)
        }}
        onSubmit={editingProspect ? handleUpdateProspect : handleAddProspect}
        prospect={editingProspect}
      />

      {/* Convert to Client Modal */}
      <ConvertToClientModal
        isOpen={showConvertModal}
        onClose={() => {
          setShowConvertModal(false)
          setConvertingProspect(null)
        }}
        onConvert={handleConvertToClient}
        prospect={convertingProspect}
      />
    </AdvisorLayout>
  )
}

export default ProspectsPage
