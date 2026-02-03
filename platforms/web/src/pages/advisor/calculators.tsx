/**
 * Financial Calculators Page
 *
 * Interactive calculators for mutual fund planning.
 * Features: SIP, Lumpsum, Goal, SWP, and Retirement calculators
 */

import { useState } from 'react'
import AdvisorLayout from '@/components/layout/AdvisorLayout'
import { useFATheme, formatCurrency } from '@/utils/fa'
import {
  FACard,
  FAInput,
  FAButton,
  FASectionHeader,
} from '@/components/advisor/shared'

type CalculatorType = 'sip' | 'lumpsum' | 'goal' | 'swp' | 'retirement'

interface CalculatorConfig {
  id: CalculatorType
  name: string
  description: string
  icon: string
}

const CALCULATORS: CalculatorConfig[] = [
  {
    id: 'sip',
    name: 'SIP Calculator',
    description: 'Calculate future value of systematic investments',
    icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15',
  },
  {
    id: 'lumpsum',
    name: 'Lumpsum Calculator',
    description: 'Calculate returns on one-time investment',
    icon: 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
  },
  {
    id: 'goal',
    name: 'Goal Calculator',
    description: 'Find required SIP to achieve your goal',
    icon: 'M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z',
  },
  {
    id: 'swp',
    name: 'SWP Calculator',
    description: 'Plan systematic withdrawals from corpus',
    icon: 'M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1',
  },
  {
    id: 'retirement',
    name: 'Retirement Calculator',
    description: 'Calculate corpus needed for retirement',
    icon: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z',
  },
]

const CalculatorsPage = () => {
  const { colors, isDark } = useFATheme()
  const [activeCalculator, setActiveCalculator] = useState<CalculatorType>('sip')

  // SIP Calculator State
  const [sipAmount, setSipAmount] = useState(25000)
  const [sipYears, setSipYears] = useState(10)
  const [sipReturn, setSipReturn] = useState(12)

  // Lumpsum Calculator State
  const [lumpsumAmount, setLumpsumAmount] = useState(500000)
  const [lumpsumYears, setLumpsumYears] = useState(10)
  const [lumpsumReturn, setLumpsumReturn] = useState(12)

  // Goal Calculator State
  const [goalTarget, setGoalTarget] = useState(5000000)
  const [goalYears, setGoalYears] = useState(10)
  const [goalReturn, setGoalReturn] = useState(12)

  // SWP Calculator State
  const [swpCorpus, setSwpCorpus] = useState(5000000)
  const [swpWithdrawal, setSwpWithdrawal] = useState(50000)
  const [swpReturn, setSwpReturn] = useState(8)

  // Retirement Calculator State
  const [retCurrentAge, setRetCurrentAge] = useState(35)
  const [retRetireAge, setRetRetireAge] = useState(60)
  const [retLifeExpectancy, setRetLifeExpectancy] = useState(85)
  const [retMonthlyExpense, setRetMonthlyExpense] = useState(50000)
  const [retInflation, setRetInflation] = useState(6)
  const [retPreReturn, setRetPreReturn] = useState(12)
  const [retPostReturn, setRetPostReturn] = useState(8)

  // Calculation functions
  const calculateSIP = () => {
    const monthlyRate = sipReturn / 100 / 12
    const months = sipYears * 12
    const futureValue = sipAmount * (((Math.pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate))
    const invested = sipAmount * months
    const returns = futureValue - invested
    return { futureValue, invested, returns }
  }

  const calculateLumpsum = () => {
    const rate = lumpsumReturn / 100
    const futureValue = lumpsumAmount * Math.pow(1 + rate, lumpsumYears)
    const returns = futureValue - lumpsumAmount
    return { futureValue, invested: lumpsumAmount, returns }
  }

  const calculateGoalSIP = () => {
    const monthlyRate = goalReturn / 100 / 12
    const months = goalYears * 12
    const sipRequired = goalTarget / ((((Math.pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate)))
    const totalInvestment = sipRequired * months
    return { sipRequired, totalInvestment, target: goalTarget }
  }

  const calculateSWP = () => {
    const monthlyRate = swpReturn / 100 / 12
    let balance = swpCorpus
    let months = 0
    const maxMonths = 1200 // 100 years max

    while (balance > swpWithdrawal && months < maxMonths) {
      balance = balance * (1 + monthlyRate) - swpWithdrawal
      months++
    }

    const years = Math.floor(months / 12)
    const remainingMonths = months % 12
    const totalWithdrawn = swpWithdrawal * months
    return { years, months: remainingMonths, totalWithdrawn, exhausted: balance <= swpWithdrawal }
  }

  const calculateRetirement = () => {
    const yearsToRetire = retRetireAge - retCurrentAge
    const yearsInRetirement = retLifeExpectancy - retRetireAge

    // Inflate current expense to retirement
    const inflatedExpense = retMonthlyExpense * Math.pow(1 + retInflation / 100, yearsToRetire)

    // Calculate corpus needed at retirement (considering post-retirement returns)
    const monthlyPostRate = retPostReturn / 100 / 12
    const retirementMonths = yearsInRetirement * 12

    // PV of annuity
    const corpusNeeded = inflatedExpense * ((1 - Math.pow(1 + monthlyPostRate, -retirementMonths)) / monthlyPostRate)

    // Calculate SIP needed
    const monthlyPreRate = retPreReturn / 100 / 12
    const savingMonths = yearsToRetire * 12
    const sipNeeded = corpusNeeded / ((((Math.pow(1 + monthlyPreRate, savingMonths) - 1) / monthlyPreRate) * (1 + monthlyPreRate)))

    return {
      corpusNeeded,
      sipNeeded,
      inflatedExpense,
      yearsToRetire,
      yearsInRetirement,
    }
  }

  const sipResult = calculateSIP()
  const lumpsumResult = calculateLumpsum()
  const goalResult = calculateGoalSIP()
  const swpResult = calculateSWP()
  const retirementResult = calculateRetirement()

  const renderProgressBar = (invested: number, total: number) => {
    const percentage = (invested / total) * 100
    return (
      <div className="mt-4">
        <div className="flex justify-between text-xs mb-2">
          <span style={{ color: colors.textSecondary }}>Investment vs Returns</span>
        </div>
        <div className="h-4 rounded-full overflow-hidden flex" style={{ background: colors.progressBg }}>
          <div
            className="h-full"
            style={{
              width: `${percentage}%`,
              background: colors.primary,
            }}
          />
          <div
            className="h-full"
            style={{
              width: `${100 - percentage}%`,
              background: colors.success,
            }}
          />
        </div>
        <div className="flex justify-between text-xs mt-2">
          <span style={{ color: colors.primary }}>Invested: {percentage.toFixed(0)}%</span>
          <span style={{ color: colors.success }}>Returns: {(100 - percentage).toFixed(0)}%</span>
        </div>
      </div>
    )
  }

  const renderCalculator = () => {
    switch (activeCalculator) {
      case 'sip':
        return (
          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-6">
              <FAInput
                label="Monthly SIP Amount"
                type="number"
                value={sipAmount}
                onChange={(e) => setSipAmount(Number(e.target.value))}
                helperText="Amount you can invest monthly"
              />
              <FAInput
                label="Investment Period (Years)"
                type="number"
                value={sipYears}
                onChange={(e) => setSipYears(Number(e.target.value))}
                helperText="Duration of investment"
              />
              <FAInput
                label="Expected Return (%)"
                type="number"
                value={sipReturn}
                onChange={(e) => setSipReturn(Number(e.target.value))}
                helperText="Expected annual return rate"
              />
            </div>
            <div
              className="p-6 rounded-2xl"
              style={{
                background: isDark
                  ? 'rgba(147, 197, 253, 0.08)'
                  : 'rgba(59, 130, 246, 0.04)',
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              <h3 className="text-sm font-semibold uppercase tracking-wider mb-6" style={{ color: colors.primary }}>
                Results
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Total Investment</span>
                  <span className="text-lg font-bold" style={{ color: colors.textPrimary }}>
                    {formatCurrency(sipResult.invested)}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Expected Returns</span>
                  <span className="text-lg font-bold" style={{ color: colors.success }}>
                    {formatCurrency(sipResult.returns)}
                  </span>
                </div>
                <div className="h-px" style={{ background: colors.cardBorder }} />
                <div className="flex justify-between items-center">
                  <span className="font-medium" style={{ color: colors.textPrimary }}>Future Value</span>
                  <span className="text-2xl font-bold" style={{ color: colors.primary }}>
                    {formatCurrency(sipResult.futureValue)}
                  </span>
                </div>
              </div>
              {renderProgressBar(sipResult.invested, sipResult.futureValue)}
            </div>
          </div>
        )

      case 'lumpsum':
        return (
          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-6">
              <FAInput
                label="Investment Amount"
                type="number"
                value={lumpsumAmount}
                onChange={(e) => setLumpsumAmount(Number(e.target.value))}
                helperText="One-time investment amount"
              />
              <FAInput
                label="Investment Period (Years)"
                type="number"
                value={lumpsumYears}
                onChange={(e) => setLumpsumYears(Number(e.target.value))}
                helperText="Duration of investment"
              />
              <FAInput
                label="Expected Return (%)"
                type="number"
                value={lumpsumReturn}
                onChange={(e) => setLumpsumReturn(Number(e.target.value))}
                helperText="Expected annual return rate"
              />
            </div>
            <div
              className="p-6 rounded-2xl"
              style={{
                background: isDark
                  ? 'rgba(147, 197, 253, 0.08)'
                  : 'rgba(59, 130, 246, 0.04)',
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              <h3 className="text-sm font-semibold uppercase tracking-wider mb-6" style={{ color: colors.primary }}>
                Results
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Total Investment</span>
                  <span className="text-lg font-bold" style={{ color: colors.textPrimary }}>
                    {formatCurrency(lumpsumResult.invested)}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Expected Returns</span>
                  <span className="text-lg font-bold" style={{ color: colors.success }}>
                    {formatCurrency(lumpsumResult.returns)}
                  </span>
                </div>
                <div className="h-px" style={{ background: colors.cardBorder }} />
                <div className="flex justify-between items-center">
                  <span className="font-medium" style={{ color: colors.textPrimary }}>Future Value</span>
                  <span className="text-2xl font-bold" style={{ color: colors.primary }}>
                    {formatCurrency(lumpsumResult.futureValue)}
                  </span>
                </div>
              </div>
              {renderProgressBar(lumpsumResult.invested, lumpsumResult.futureValue)}
              <div className="mt-6 p-4 rounded-xl" style={{ background: colors.chipBg }}>
                <p className="text-sm" style={{ color: colors.textSecondary }}>
                  CAGR: <span className="font-bold" style={{ color: colors.primary }}>{lumpsumReturn}%</span>
                </p>
                <p className="text-xs mt-1" style={{ color: colors.textTertiary }}>
                  Your money will grow {((lumpsumResult.futureValue / lumpsumResult.invested)).toFixed(1)}x in {lumpsumYears} years
                </p>
              </div>
            </div>
          </div>
        )

      case 'goal':
        return (
          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-6">
              <FAInput
                label="Target Amount"
                type="number"
                value={goalTarget}
                onChange={(e) => setGoalTarget(Number(e.target.value))}
                helperText="Amount you want to accumulate"
              />
              <FAInput
                label="Time Period (Years)"
                type="number"
                value={goalYears}
                onChange={(e) => setGoalYears(Number(e.target.value))}
                helperText="Time to achieve goal"
              />
              <FAInput
                label="Expected Return (%)"
                type="number"
                value={goalReturn}
                onChange={(e) => setGoalReturn(Number(e.target.value))}
                helperText="Expected annual return rate"
              />
            </div>
            <div
              className="p-6 rounded-2xl"
              style={{
                background: isDark
                  ? 'rgba(147, 197, 253, 0.08)'
                  : 'rgba(59, 130, 246, 0.04)',
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              <h3 className="text-sm font-semibold uppercase tracking-wider mb-6" style={{ color: colors.primary }}>
                Results
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Required Monthly SIP</span>
                  <span className="text-2xl font-bold" style={{ color: colors.primary }}>
                    {formatCurrency(goalResult.sipRequired)}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Total Investment</span>
                  <span className="text-lg font-bold" style={{ color: colors.textPrimary }}>
                    {formatCurrency(goalResult.totalInvestment)}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Expected Returns</span>
                  <span className="text-lg font-bold" style={{ color: colors.success }}>
                    {formatCurrency(goalResult.target - goalResult.totalInvestment)}
                  </span>
                </div>
                <div className="h-px" style={{ background: colors.cardBorder }} />
                <div className="flex justify-between items-center">
                  <span className="font-medium" style={{ color: colors.textPrimary }}>Target Amount</span>
                  <span className="text-xl font-bold" style={{ color: colors.success }}>
                    {formatCurrency(goalResult.target)}
                  </span>
                </div>
              </div>
              {renderProgressBar(goalResult.totalInvestment, goalResult.target)}
            </div>
          </div>
        )

      case 'swp':
        return (
          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-6">
              <FAInput
                label="Total Corpus"
                type="number"
                value={swpCorpus}
                onChange={(e) => setSwpCorpus(Number(e.target.value))}
                helperText="Total amount available"
              />
              <FAInput
                label="Monthly Withdrawal"
                type="number"
                value={swpWithdrawal}
                onChange={(e) => setSwpWithdrawal(Number(e.target.value))}
                helperText="Amount to withdraw monthly"
              />
              <FAInput
                label="Expected Return (%)"
                type="number"
                value={swpReturn}
                onChange={(e) => setSwpReturn(Number(e.target.value))}
                helperText="Expected return on remaining corpus"
              />
            </div>
            <div
              className="p-6 rounded-2xl"
              style={{
                background: isDark
                  ? 'rgba(147, 197, 253, 0.08)'
                  : 'rgba(59, 130, 246, 0.04)',
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              <h3 className="text-sm font-semibold uppercase tracking-wider mb-6" style={{ color: colors.primary }}>
                Results
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Corpus Lasts</span>
                  <span className="text-2xl font-bold" style={{ color: colors.primary }}>
                    {swpResult.exhausted
                      ? `${swpResult.years} yrs ${swpResult.months} mo`
                      : '100+ years'}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Total Withdrawals</span>
                  <span className="text-lg font-bold" style={{ color: colors.success }}>
                    {formatCurrency(swpResult.totalWithdrawn)}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Initial Corpus</span>
                  <span className="text-lg font-bold" style={{ color: colors.textPrimary }}>
                    {formatCurrency(swpCorpus)}
                  </span>
                </div>
              </div>
              <div className="mt-6 p-4 rounded-xl" style={{ background: colors.chipBg }}>
                <p className="text-sm" style={{ color: colors.textSecondary }}>
                  Withdrawal Rate: <span className="font-bold" style={{ color: colors.primary }}>
                    {((swpWithdrawal * 12 / swpCorpus) * 100).toFixed(1)}% annually
                  </span>
                </p>
                <p className="text-xs mt-1" style={{ color: colors.textTertiary }}>
                  {swpReturn > (swpWithdrawal * 12 / swpCorpus) * 100
                    ? 'Returns exceed withdrawals - corpus will grow!'
                    : 'Adjust withdrawal or return expectations'}
                </p>
              </div>
            </div>
          </div>
        )

      case 'retirement':
        return (
          <div className="grid grid-cols-2 gap-8">
            <div className="space-y-4">
              <div className="grid grid-cols-3 gap-3">
                <FAInput
                  label="Current Age"
                  type="number"
                  value={retCurrentAge}
                  onChange={(e) => setRetCurrentAge(Number(e.target.value))}
                />
                <FAInput
                  label="Retire At"
                  type="number"
                  value={retRetireAge}
                  onChange={(e) => setRetRetireAge(Number(e.target.value))}
                />
                <FAInput
                  label="Life Expect."
                  type="number"
                  value={retLifeExpectancy}
                  onChange={(e) => setRetLifeExpectancy(Number(e.target.value))}
                />
              </div>
              <FAInput
                label="Monthly Expenses (Today)"
                type="number"
                value={retMonthlyExpense}
                onChange={(e) => setRetMonthlyExpense(Number(e.target.value))}
                helperText="Current monthly expenses"
              />
              <div className="grid grid-cols-3 gap-3">
                <FAInput
                  label="Inflation %"
                  type="number"
                  value={retInflation}
                  onChange={(e) => setRetInflation(Number(e.target.value))}
                />
                <FAInput
                  label="Pre-Ret. %"
                  type="number"
                  value={retPreReturn}
                  onChange={(e) => setRetPreReturn(Number(e.target.value))}
                />
                <FAInput
                  label="Post-Ret. %"
                  type="number"
                  value={retPostReturn}
                  onChange={(e) => setRetPostReturn(Number(e.target.value))}
                />
              </div>
            </div>
            <div
              className="p-6 rounded-2xl"
              style={{
                background: isDark
                  ? 'rgba(147, 197, 253, 0.08)'
                  : 'rgba(59, 130, 246, 0.04)',
                border: `1px solid ${colors.cardBorder}`,
              }}
            >
              <h3 className="text-sm font-semibold uppercase tracking-wider mb-6" style={{ color: colors.primary }}>
                Retirement Plan
              </h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Corpus Needed</span>
                  <span className="text-2xl font-bold" style={{ color: colors.primary }}>
                    {formatCurrency(retirementResult.corpusNeeded)}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Monthly SIP Required</span>
                  <span className="text-xl font-bold" style={{ color: colors.success }}>
                    {formatCurrency(retirementResult.sipNeeded)}
                  </span>
                </div>
                <div className="h-px" style={{ background: colors.cardBorder }} />
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Expense at Retirement</span>
                  <span className="font-bold" style={{ color: colors.textPrimary }}>
                    {formatCurrency(retirementResult.inflatedExpense)}/mo
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Years to Retire</span>
                  <span className="font-bold" style={{ color: colors.textPrimary }}>
                    {retirementResult.yearsToRetire} years
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span style={{ color: colors.textSecondary }}>Years in Retirement</span>
                  <span className="font-bold" style={{ color: colors.textPrimary }}>
                    {retirementResult.yearsInRetirement} years
                  </span>
                </div>
              </div>
              <div className="mt-6 p-4 rounded-xl" style={{ background: colors.chipBg }}>
                <p className="text-xs" style={{ color: colors.textTertiary }}>
                  Start investing {formatCurrency(retirementResult.sipNeeded)}/month to build a corpus of{' '}
                  {formatCurrency(retirementResult.corpusNeeded)} for a comfortable retirement.
                </p>
              </div>
            </div>
          </div>
        )
    }
  }

  return (
    <AdvisorLayout title="Financial Calculators">
      <div style={{ background: colors.background, minHeight: '100%', margin: '-2rem', padding: '2rem' }}>
        {/* Header */}
        <div className="mb-8">
          <p className="text-sm" style={{ color: colors.textSecondary }}>
            Plan investments with interactive financial calculators
          </p>
        </div>

        {/* Calculator Selector */}
        <div className="grid grid-cols-5 gap-3 mb-8">
          {CALCULATORS.map(calc => (
            <button
              key={calc.id}
              onClick={() => setActiveCalculator(calc.id)}
              className="p-4 rounded-xl transition-all hover:-translate-y-0.5 text-left"
              style={{
                background: activeCalculator === calc.id
                  ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                  : colors.cardBackground,
                border: `1px solid ${activeCalculator === calc.id ? 'transparent' : colors.cardBorder}`,
                boxShadow: `0 2px 10px ${colors.glassShadow}`,
              }}
            >
              <div
                className="w-10 h-10 rounded-lg flex items-center justify-center mb-3"
                style={{
                  background: activeCalculator === calc.id
                    ? 'rgba(255, 255, 255, 0.2)'
                    : colors.chipBg,
                }}
              >
                <svg
                  className="w-5 h-5"
                  style={{ color: activeCalculator === calc.id ? '#FFFFFF' : colors.primary }}
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2}
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d={calc.icon} />
                </svg>
              </div>
              <p
                className="text-sm font-semibold"
                style={{ color: activeCalculator === calc.id ? '#FFFFFF' : colors.textPrimary }}
              >
                {calc.name}
              </p>
              <p
                className="text-xs mt-1"
                style={{ color: activeCalculator === calc.id ? 'rgba(255,255,255,0.8)' : colors.textTertiary }}
              >
                {calc.description}
              </p>
            </button>
          ))}
        </div>

        {/* Active Calculator */}
        <FACard>
          <FASectionHeader
            title={CALCULATORS.find(c => c.id === activeCalculator)?.name || ''}
          />
          <div className="mt-6">
            {renderCalculator()}
          </div>
        </FACard>

        {/* Tips Section */}
        <div className="grid grid-cols-3 gap-4 mt-8">
          <div
            className="p-4 rounded-xl"
            style={{
              background: isDark
                ? 'rgba(147, 197, 253, 0.08)'
                : 'rgba(59, 130, 246, 0.04)',
              border: `1px solid ${colors.cardBorder}`,
            }}
          >
            <div className="flex items-center gap-3 mb-2">
              <div
                className="w-8 h-8 rounded-lg flex items-center justify-center"
                style={{ background: `${colors.primary}15` }}
              >
                <svg className="w-4 h-4" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
              </div>
              <span className="font-medium" style={{ color: colors.textPrimary }}>Power of Compounding</span>
            </div>
            <p className="text-xs" style={{ color: colors.textSecondary }}>
              Start early and stay invested. Even small amounts grow significantly over time through compound returns.
            </p>
          </div>
          <div
            className="p-4 rounded-xl"
            style={{
              background: isDark
                ? 'rgba(147, 197, 253, 0.08)'
                : 'rgba(59, 130, 246, 0.04)',
              border: `1px solid ${colors.cardBorder}`,
            }}
          >
            <div className="flex items-center gap-3 mb-2">
              <div
                className="w-8 h-8 rounded-lg flex items-center justify-center"
                style={{ background: `${colors.warning}15` }}
              >
                <svg className="w-4 h-4" style={{ color: colors.warning }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
              <span className="font-medium" style={{ color: colors.textPrimary }}>Inflation Impact</span>
            </div>
            <p className="text-xs" style={{ color: colors.textSecondary }}>
              Factor in 6-7% annual inflation when planning goals. Your future expenses will be higher than today.
            </p>
          </div>
          <div
            className="p-4 rounded-xl"
            style={{
              background: isDark
                ? 'rgba(147, 197, 253, 0.08)'
                : 'rgba(59, 130, 246, 0.04)',
              border: `1px solid ${colors.cardBorder}`,
            }}
          >
            <div className="flex items-center gap-3 mb-2">
              <div
                className="w-8 h-8 rounded-lg flex items-center justify-center"
                style={{ background: `${colors.success}15` }}
              >
                <svg className="w-4 h-4" style={{ color: colors.success }} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <span className="font-medium" style={{ color: colors.textPrimary }}>SIP Step-Up</span>
            </div>
            <p className="text-xs" style={{ color: colors.textSecondary }}>
              Increase your SIP by 10% annually. This simple habit can significantly boost your final corpus.
            </p>
          </div>
        </div>
      </div>
    </AdvisorLayout>
  )
}

export default CalculatorsPage
