//
//  PortfolioInputView.swift
//  SparrowInvest
//
//  View for manually inputting/editing portfolio holdings for AI analysis
//

import SwiftUI

struct PortfolioInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var portfolioStore: PortfolioStore
    @Environment(AnalysisProfileStore.self) var analysisStore
    @State private var showAddHolding = false
    @State private var holdingToEdit: AnalysisHolding?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Header Card
                    PortfolioInputHeader()

                    // Import from Existing Portfolio
                    if !portfolioStore.holdings.isEmpty {
                        ImportFromPortfolioCard(
                            holdingsCount: portfolioStore.holdings.count,
                            totalValue: portfolioStore.portfolio.totalValue
                        ) {
                            analysisStore.importFromPortfolio(portfolioStore.holdings)
                        }
                    }

                    // Holdings List
                    if let portfolio = analysisStore.analysisPortfolio, !portfolio.holdings.isEmpty {
                        HoldingsListSection(
                            holdings: portfolio.holdings,
                            onEdit: { holding in holdingToEdit = holding },
                            onDelete: { id in analysisStore.removeHolding(id: id) }
                        )
                    } else {
                        EmptyAnalysisHoldingsView {
                            showAddHolding = true
                        }
                    }

                    // Add Holding Button
                    if analysisStore.analysisPortfolio != nil {
                        AddHoldingButton {
                            showAddHolding = true
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("My Portfolio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddHolding) {
                AddHoldingView()
            }
            .sheet(item: $holdingToEdit) { holding in
                AddHoldingView(existingHolding: holding)
            }
        }
    }
}

// MARK: - Portfolio Input Header

struct PortfolioInputHeader: View {
    @Environment(AnalysisProfileStore.self) var analysisStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.compact) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio for Analysis")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)

                    Text("Add your holdings to get AI insights")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if let portfolio = analysisStore.analysisPortfolio, !portfolio.holdings.isEmpty {
                Divider()

                // Summary Stats
                HStack(spacing: 0) {
                    PortfolioStatItem(
                        label: "Holdings",
                        value: "\(portfolio.holdings.count)",
                        color: .blue
                    )

                    Divider()
                        .frame(height: 36)

                    PortfolioStatItem(
                        label: "Invested",
                        value: portfolio.totalInvestedAmount.compactCurrencyFormatted,
                        color: .primary
                    )

                    Divider()
                        .frame(height: 36)

                    PortfolioStatItem(
                        label: "Returns",
                        value: portfolio.returnsPercentage.percentFormatted,
                        color: portfolio.returnsPercentage >= 0 ? .green : .red
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.15), location: 0),
                            .init(color: .black.opacity(0.08), location: 0.3),
                            .init(color: .black.opacity(0.05), location: 0.7),
                            .init(color: .black.opacity(0.12), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

struct PortfolioStatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Import from Portfolio Card

struct ImportFromPortfolioCard: View {
    let holdingsCount: Int
    let totalValue: Double
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.blue)
                Text("IMPORT FROM EXISTING PORTFOLIO")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.blue)
                    .tracking(1)
            }

            Text("Import your \(holdingsCount) holdings worth \(totalValue.compactCurrencyFormatted) from your connected portfolio")
                .font(.system(size: 13, weight: .light))
                .foregroundColor(.secondary)

            Button(action: action) {
                HStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 14, weight: .light))
                    Text("Import Holdings")
                        .font(.system(size: 14, weight: .regular))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                )
            }
        }
        .padding(AppTheme.Spacing.medium)
        .listItemCardStyle(cornerRadius: AppTheme.CornerRadius.large)
    }
}

// MARK: - Holdings List Section

struct HoldingsListSection: View {
    let holdings: [AnalysisHolding]
    let onEdit: (AnalysisHolding) -> Void
    let onDelete: (String) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("YOUR HOLDINGS")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.blue)
                .tracking(1)

            ForEach(holdings) { holding in
                HoldingInputCard(
                    holding: holding,
                    onEdit: { onEdit(holding) },
                    onDelete: { onDelete(holding.id) }
                )
            }
        }
    }
}

struct HoldingInputCard: View {
    let holding: AnalysisHolding
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.compact) {
            // Fund Icon
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .fill(holding.assetClass.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(String(holding.fundName.prefix(2)).uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(holding.assetClass.color)
            }

            // Fund Details
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.fundName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("\(holding.category) • \(holding.units.formatted()) units")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Value & Returns
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.currentValue.currencyFormatted)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)

                Text(holding.returnsPercentage.percentFormatted)
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(holding.returnsPercentage >= 0 ? .green : .red)
            }

            // Actions Menu
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(AppTheme.Spacing.compact)
        .listItemCardStyle()
    }
}

// MARK: - Empty Holdings View

struct EmptyAnalysisHoldingsView: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Color(uiColor: .tertiaryLabel))

            VStack(spacing: 4) {
                Text("No Holdings Added")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)

                Text("Add your mutual fund holdings to get AI-powered insights and recommendations")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("Add Your First Holding")
                        .font(.system(size: 14, weight: .regular))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xLarge)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .background(cardBackground)
        .overlay(cardBorder)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
                .fill(Color.white)
        }
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xLarge, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.4), location: 0),
                            .init(color: .white.opacity(0.15), location: 0.3),
                            .init(color: .white.opacity(0.05), location: 0.7),
                            .init(color: .white.opacity(0.1), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.15), location: 0),
                            .init(color: .black.opacity(0.08), location: 0.3),
                            .init(color: .black.opacity(0.05), location: 0.7),
                            .init(color: .black.opacity(0.12), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

// MARK: - Add Holding Button

struct AddHoldingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Add Another Holding")
                    .font(.system(size: 14, weight: .regular))
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        }
    }
}

// MARK: - Add Holding View

struct AddHoldingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AnalysisProfileStore.self) var analysisStore
    var existingHolding: AnalysisHolding?

    @State private var fundName: String = ""
    @State private var category: String = "Equity"
    @State private var assetClass: Holding.AssetClass = .equity
    @State private var investedAmount: String = ""
    @State private var currentValue: String = ""
    @State private var units: String = ""

    private let categories = ["Equity", "Debt", "Hybrid", "ELSS", "Index", "Gold"]
    private let assetClasses: [Holding.AssetClass] = [.equity, .debt, .hybrid, .gold, .other]

    init(existingHolding: AnalysisHolding? = nil) {
        self.existingHolding = existingHolding

        if let holding = existingHolding {
            _fundName = State(initialValue: holding.fundName)
            _category = State(initialValue: holding.category)
            _assetClass = State(initialValue: holding.assetClass)
            _investedAmount = State(initialValue: String(format: "%.0f", holding.investedAmount))
            _currentValue = State(initialValue: String(format: "%.0f", holding.currentValue))
            _units = State(initialValue: String(format: "%.3f", holding.units))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Fund Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FUND NAME")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.blue)
                            .tracking(1)

                        TextField("Enter fund name", text: $fundName)
                            .font(.system(size: 16, weight: .light))
                            .padding(AppTheme.Spacing.medium)
                            .background(fieldBackground)
                            .overlay(fieldBorder)
                    }

                    // Category Selection
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CATEGORY")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.blue)
                            .tracking(1)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    CategoryChip(
                                        label: cat,
                                        isSelected: category == cat
                                    ) {
                                        category = cat
                                        // Update asset class based on category
                                        switch cat {
                                        case "Equity", "ELSS", "Index": assetClass = .equity
                                        case "Debt": assetClass = .debt
                                        case "Hybrid": assetClass = .hybrid
                                        case "Gold": assetClass = .gold
                                        default: assetClass = .other
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Investment Details
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
                        Text("INVESTMENT DETAILS")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.blue)
                            .tracking(1)

                        // Amount Invested
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amount Invested (₹)")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.secondary)

                            TextField("0", text: $investedAmount)
                                .font(.system(size: 16, weight: .light))
                                .keyboardType(.numberPad)
                                .padding(AppTheme.Spacing.medium)
                                .background(fieldBackground)
                                .overlay(fieldBorder)
                        }

                        // Current Value
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Value (₹)")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.secondary)

                            TextField("0", text: $currentValue)
                                .font(.system(size: 16, weight: .light))
                                .keyboardType(.numberPad)
                                .padding(AppTheme.Spacing.medium)
                                .background(fieldBackground)
                                .overlay(fieldBorder)
                        }

                        // Units
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Units Held")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.secondary)

                            TextField("0.000", text: $units)
                                .font(.system(size: 16, weight: .light))
                                .keyboardType(.decimalPad)
                                .padding(AppTheme.Spacing.medium)
                                .background(fieldBackground)
                                .overlay(fieldBorder)
                        }
                    }
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(existingHolding == nil ? "Add Holding" : "Edit Holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHolding()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !fundName.isEmpty &&
        Double(investedAmount) != nil &&
        Double(currentValue) != nil &&
        Double(units) != nil
    }

    private func saveHolding() {
        let holding = AnalysisHolding(
            id: existingHolding?.id ?? UUID().uuidString,
            fundName: fundName,
            category: category,
            assetClass: assetClass,
            investedAmount: Double(investedAmount) ?? 0,
            currentValue: Double(currentValue) ?? 0,
            units: Double(units) ?? 0
        )

        if existingHolding != nil {
            analysisStore.updateHolding(holding)
        } else {
            analysisStore.addHolding(holding)
        }
        dismiss()
    }

    @ViewBuilder
    private var fieldBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white.opacity(0.06))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.white)
        }
    }

    private var fieldBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
            .stroke(
                colorScheme == .dark
                    ? LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.25), location: 0),
                            .init(color: .white.opacity(0.1), location: 0.5),
                            .init(color: .white.opacity(0.15), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                    : LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.12), location: 0),
                            .init(color: .black.opacity(0.06), location: 0.5),
                            .init(color: .black.opacity(0.10), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(chipBackground)
                .overlay(chipBorder)
        }
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        } else if colorScheme == .dark {
            Capsule()
                .fill(Color.white.opacity(0.06))
        } else {
            Capsule()
                .fill(Color.white)
        }
    }

    @ViewBuilder
    private var chipBorder: some View {
        if !isSelected {
            Capsule()
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1),
                    lineWidth: 1
                )
        }
    }
}

#Preview {
    PortfolioInputView()
        .environmentObject(PortfolioStore())
        .environment(AnalysisProfileStore())
}
