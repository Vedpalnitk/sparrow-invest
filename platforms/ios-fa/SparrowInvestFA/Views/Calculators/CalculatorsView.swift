import SwiftUI

struct CalculatorsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    @State private var selectedCalculator = 0

    private let calculatorTypes = ["SIP", "Lumpsum", "Goal", "SWP", "Retirement"]
    private let calculatorIcons = [
        "arrow.triangle.2.circlepath", "banknote", "target",
        "arrow.down.circle", "figure.walk"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Calculator Selector
                    calculatorSelector

                    // Active Calculator
                    switch selectedCalculator {
                    case 0: SIPCalculatorView()
                    case 1: LumpsumCalculatorView()
                    case 2: GoalPlannerView()
                    case 3: SWPPlannerView()
                    case 4: RetirementPlannerView()
                    default: SIPCalculatorView()
                    }

                    Spacer().frame(height: AppTheme.Spacing.xxxLarge)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
            .background(AppTheme.pageBackground(colorScheme: colorScheme))
            .navigationTitle("Calculators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Calculator Selector

    private var calculatorSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.small) {
                ForEach(0..<calculatorTypes.count, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCalculator = index
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: calculatorIcons[index])
                                .font(.system(size: iPad ? 15 : 13))

                            Text(calculatorTypes[index])
                                .font(AppTheme.Typography.accent(iPad ? 15 : 13))
                        }
                        .padding(.horizontal, AppTheme.Spacing.compact)
                        .padding(.vertical, AppTheme.Spacing.small)
                        .foregroundColor(selectedCalculator == index ? .white : .primary)
                        .background(
                            Capsule()
                                .fill(selectedCalculator == index
                                      ? AnyShapeStyle(LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                      : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.9)))
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedCalculator == index ? Color.clear : (colorScheme == .dark ? Color.white.opacity(0.12) : AppTheme.primary.opacity(0.1)), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Slider Input Row

private struct CalcSliderInput: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let format: SliderFormat
    let color: Color

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    enum SliderFormat {
        case currency, percent, years, age
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text(label)
                    .font(AppTheme.Typography.label(iPad ? 14 : 12))
                    .foregroundColor(.secondary)

                Spacer()

                Text(formattedValue)
                    .font(AppTheme.Typography.numeric(iPad ? 19 : 16))
                    .foregroundColor(.primary)
            }

            Slider(value: value, in: range, step: step)
                .tint(color)
        }
    }

    private var formattedValue: String {
        let v = value.wrappedValue
        switch format {
        case .currency:
            return AppTheme.formatCurrencyWithSymbol(v)
        case .percent:
            return String(format: "%.1f%%", v)
        case .years:
            return "\(Int(v)) yrs"
        case .age:
            return "\(Int(v))"
        }
    }
}

// MARK: - Result Row

private struct CalcResultRow: View {
    let label: String
    let value: String
    let color: Color

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.Typography.accent(iPad ? 17 : 14))
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.numeric(iPad ? 21 : 18))
                .foregroundColor(color)
        }
    }
}

// MARK: - Results Card

private struct CalcResultsCard<Content: View>: View {
    let title: String
    let invested: Double
    let total: Double
    @ViewBuilder let content: Content

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var iPad: Bool { sizeClass == .regular }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.accent(iPad ? 18 : 15))
                    .foregroundColor(.primary)
                Spacer()
            }

            content

            if total > 0 && invested > 0 {
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.success.opacity(0.15))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.info],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * min(invested / total, 1.0), height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(AppTheme.primary).frame(width: 6, height: 6)
                            Text("Invested")
                                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(AppTheme.success.opacity(0.3)).frame(width: 6, height: 6)
                            Text("Returns")
                                .font(AppTheme.Typography.label(iPad ? 12 : 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large)
    }
}

// MARK: - SIP Calculator

private struct SIPCalculatorView: View {
    @State private var monthlyAmount: Double = 10000
    @State private var years: Double = 10
    @State private var returnRate: Double = 12
    @State private var stepUp: Double = 0

    private var result: (invested: Double, futureValue: Double) {
        let r = returnRate / 100.0 / 12.0
        let n = Int(years) * 12

        if stepUp == 0 {
            // Standard SIP formula
            if r == 0 { return (monthlyAmount * Double(n), monthlyAmount * Double(n)) }
            let fv = monthlyAmount * ((pow(1 + r, Double(n)) - 1) / r) * (1 + r)
            return (monthlyAmount * Double(n), fv)
        } else {
            // Step-up SIP: yearly increase
            var total = 0.0
            var invested = 0.0
            var currentSip = monthlyAmount
            for year in 0..<Int(years) {
                for _ in 0..<12 {
                    let monthsRemaining = Int(years) * 12 - (year * 12 + (year == 0 ? 0 : 0)) // simplified
                    invested += currentSip
                }
                // Compound each year's SIP contributions
                let monthsInYear = 12
                if r == 0 {
                    total += currentSip * Double(monthsInYear)
                } else {
                    let remainingMonths = Double((Int(years) - year - 1) * 12)
                    let yearFv = currentSip * ((pow(1 + r, Double(monthsInYear)) - 1) / r) * (1 + r)
                    total += yearFv * pow(1 + r, remainingMonths)
                }
                currentSip *= (1 + stepUp / 100.0)
            }
            return (invested, total)
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Inputs
            VStack(spacing: AppTheme.Spacing.compact) {
                CalcSliderInput(label: "Monthly Investment", value: $monthlyAmount,
                                range: 500...500_000, step: 500, format: .currency, color: AppTheme.primary)
                CalcSliderInput(label: "Time Period", value: $years,
                                range: 1...40, step: 1, format: .years, color: AppTheme.info)
                CalcSliderInput(label: "Expected Return", value: $returnRate,
                                range: 1...30, step: 0.5, format: .percent, color: AppTheme.success)
                CalcSliderInput(label: "Annual Step-up", value: $stepUp,
                                range: 0...25, step: 1, format: .percent, color: AppTheme.warning)
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large)

            // Results
            CalcResultsCard(title: "SIP Results", invested: result.invested, total: result.futureValue) {
                VStack(spacing: AppTheme.Spacing.compact) {
                    CalcResultRow(label: "Total Invested", value: AppTheme.formatCurrencyWithSymbol(result.invested), color: .primary)
                    Divider()
                    CalcResultRow(label: "Expected Returns", value: AppTheme.formatCurrencyWithSymbol(result.futureValue - result.invested), color: AppTheme.success)
                    Divider()
                    CalcResultRow(label: "Future Value", value: AppTheme.formatCurrencyWithSymbol(result.futureValue), color: AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Lumpsum Calculator

private struct LumpsumCalculatorView: View {
    @State private var amount: Double = 100_000
    @State private var years: Double = 10
    @State private var returnRate: Double = 12

    private var futureValue: Double {
        amount * pow(1 + returnRate / 100.0, years)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            VStack(spacing: AppTheme.Spacing.compact) {
                CalcSliderInput(label: "Investment Amount", value: $amount,
                                range: 10_000...10_000_000, step: 10_000, format: .currency, color: AppTheme.primary)
                CalcSliderInput(label: "Time Period", value: $years,
                                range: 1...40, step: 1, format: .years, color: AppTheme.info)
                CalcSliderInput(label: "Expected Return", value: $returnRate,
                                range: 1...30, step: 0.5, format: .percent, color: AppTheme.success)
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large)

            CalcResultsCard(title: "Lumpsum Results", invested: amount, total: futureValue) {
                VStack(spacing: AppTheme.Spacing.compact) {
                    CalcResultRow(label: "Total Investment", value: AppTheme.formatCurrencyWithSymbol(amount), color: .primary)
                    Divider()
                    CalcResultRow(label: "Expected Returns", value: AppTheme.formatCurrencyWithSymbol(futureValue - amount), color: AppTheme.success)
                    Divider()
                    CalcResultRow(label: "Future Value", value: AppTheme.formatCurrencyWithSymbol(futureValue), color: AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Goal Planner

private struct GoalPlannerView: View {
    @State private var targetAmount: Double = 1_000_000
    @State private var years: Double = 10
    @State private var returnRate: Double = 12

    private var requiredSip: Double {
        let r = returnRate / 100.0 / 12.0
        let n = Double(Int(years) * 12)
        if r == 0 { return targetAmount / n }
        return targetAmount / (((pow(1 + r, n) - 1) / r) * (1 + r))
    }

    private var totalInvested: Double {
        requiredSip * Double(Int(years) * 12)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            VStack(spacing: AppTheme.Spacing.compact) {
                CalcSliderInput(label: "Target Amount", value: $targetAmount,
                                range: 100_000...100_000_000, step: 100_000, format: .currency, color: AppTheme.primary)
                CalcSliderInput(label: "Time Period", value: $years,
                                range: 1...40, step: 1, format: .years, color: AppTheme.info)
                CalcSliderInput(label: "Expected Return", value: $returnRate,
                                range: 1...30, step: 0.5, format: .percent, color: AppTheme.success)
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large)

            CalcResultsCard(title: "Goal Planner Results", invested: totalInvested, total: targetAmount) {
                VStack(spacing: AppTheme.Spacing.compact) {
                    CalcResultRow(label: "Required Monthly SIP", value: AppTheme.formatCurrencyWithSymbol(requiredSip), color: AppTheme.primary)
                    Divider()
                    CalcResultRow(label: "Total Investment", value: AppTheme.formatCurrencyWithSymbol(totalInvested), color: .primary)
                    Divider()
                    CalcResultRow(label: "Wealth Gain", value: AppTheme.formatCurrencyWithSymbol(targetAmount - totalInvested), color: AppTheme.success)
                }
            }
        }
    }
}

// MARK: - SWP Planner

private struct SWPPlannerView: View {
    @State private var corpus: Double = 5_000_000
    @State private var monthlyWithdrawal: Double = 30_000
    @State private var returnRate: Double = 8

    private var result: (years: Int, months: Int, totalWithdrawn: Double) {
        let monthlyRate = returnRate / 100.0 / 12.0
        var balance = corpus
        var totalMonths = 0
        let maxMonths = 100 * 12

        while balance > 0 && totalMonths < maxMonths {
            balance = balance * (1 + monthlyRate) - monthlyWithdrawal
            totalMonths += 1
            if balance < 0 { break }
        }

        let totalWithdrawn = monthlyWithdrawal * Double(totalMonths)
        return (totalMonths / 12, totalMonths % 12, totalWithdrawn)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            VStack(spacing: AppTheme.Spacing.compact) {
                CalcSliderInput(label: "Total Corpus", value: $corpus,
                                range: 100_000...100_000_000, step: 100_000, format: .currency, color: AppTheme.primary)
                CalcSliderInput(label: "Monthly Withdrawal", value: $monthlyWithdrawal,
                                range: 1_000...1_000_000, step: 1_000, format: .currency, color: AppTheme.warning)
                CalcSliderInput(label: "Expected Return", value: $returnRate,
                                range: 1...20, step: 0.5, format: .percent, color: AppTheme.success)
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large)

            let r = result
            let lasting = r.years >= 100 ? "100+ years" : "\(r.years) yrs \(r.months) mo"

            CalcResultsCard(title: "SWP Results", invested: corpus, total: r.totalWithdrawn) {
                VStack(spacing: AppTheme.Spacing.compact) {
                    CalcResultRow(label: "Corpus Lasts", value: lasting, color: AppTheme.primary)
                    Divider()
                    CalcResultRow(label: "Total Withdrawn", value: AppTheme.formatCurrencyWithSymbol(r.totalWithdrawn), color: AppTheme.success)
                    Divider()
                    CalcResultRow(label: "Initial Corpus", value: AppTheme.formatCurrencyWithSymbol(corpus), color: .primary)
                }
            }
        }
    }
}

// MARK: - Retirement Planner

private struct RetirementPlannerView: View {
    @State private var currentAge: Double = 30
    @State private var retireAt: Double = 60
    @State private var lifeExpectancy: Double = 85
    @State private var monthlyExpenses: Double = 50_000
    @State private var inflation: Double = 6
    @State private var preReturnRate: Double = 12
    @State private var postReturnRate: Double = 8

    private var result: (corpusNeeded: Double, monthlySip: Double, expenseAtRetirement: Double) {
        let yearsToRetire = Double(Int(retireAt) - Int(currentAge))
        let yearsInRetirement = Double(Int(lifeExpectancy) - Int(retireAt))
        guard yearsToRetire > 0, yearsInRetirement > 0 else { return (0, 0, 0) }

        // Inflated monthly expense at retirement
        let inflatedMonthly = monthlyExpenses * pow(1 + inflation / 100.0, yearsToRetire)

        // Corpus needed (present value of annuity at retirement)
        let realRate = ((1 + postReturnRate / 100.0) / (1 + inflation / 100.0)) - 1
        let monthlyReal = realRate / 12.0
        let retirementMonths = yearsInRetirement * 12

        let corpusNeeded: Double
        if monthlyReal == 0 {
            corpusNeeded = inflatedMonthly * retirementMonths
        } else {
            corpusNeeded = inflatedMonthly * ((1 - pow(1 + monthlyReal, -retirementMonths)) / monthlyReal)
        }

        // SIP required to build corpus
        let monthlyPre = preReturnRate / 100.0 / 12.0
        let preMonths = yearsToRetire * 12
        let sipRequired: Double
        if monthlyPre == 0 {
            sipRequired = corpusNeeded / preMonths
        } else {
            sipRequired = corpusNeeded / (((pow(1 + monthlyPre, preMonths) - 1) / monthlyPre) * (1 + monthlyPre))
        }

        return (corpusNeeded, sipRequired, inflatedMonthly)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            VStack(spacing: AppTheme.Spacing.compact) {
                CalcSliderInput(label: "Current Age", value: $currentAge,
                                range: 18...65, step: 1, format: .age, color: AppTheme.primary)
                CalcSliderInput(label: "Retire At", value: $retireAt,
                                range: 30...75, step: 1, format: .age, color: AppTheme.info)
                CalcSliderInput(label: "Life Expectancy", value: $lifeExpectancy,
                                range: 50...100, step: 1, format: .age, color: AppTheme.warning)
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large)

            VStack(spacing: AppTheme.Spacing.compact) {
                CalcSliderInput(label: "Monthly Expenses (Today)", value: $monthlyExpenses,
                                range: 10_000...500_000, step: 5_000, format: .currency, color: AppTheme.primary)
                CalcSliderInput(label: "Inflation", value: $inflation,
                                range: 1...12, step: 0.5, format: .percent, color: AppTheme.error)
                CalcSliderInput(label: "Pre-retirement Return", value: $preReturnRate,
                                range: 1...20, step: 0.5, format: .percent, color: AppTheme.success)
                CalcSliderInput(label: "Post-retirement Return", value: $postReturnRate,
                                range: 1...15, step: 0.5, format: .percent, color: AppTheme.info)
            }
            .glassCard(cornerRadius: AppTheme.CornerRadius.large)

            let r = result
            CalcResultsCard(title: "Retirement Plan", invested: r.monthlySip * Double(Int(retireAt) - Int(currentAge)) * 12, total: r.corpusNeeded) {
                VStack(spacing: AppTheme.Spacing.compact) {
                    CalcResultRow(label: "Corpus Needed", value: AppTheme.formatCurrencyWithSymbol(r.corpusNeeded), color: AppTheme.primary)
                    Divider()
                    CalcResultRow(label: "Monthly SIP Required", value: AppTheme.formatCurrencyWithSymbol(r.monthlySip), color: AppTheme.info)
                    Divider()
                    CalcResultRow(label: "Expense at Retirement", value: AppTheme.formatCurrencyWithSymbol(r.expenseAtRetirement), color: AppTheme.warning)
                }
            }
        }
    }
}
