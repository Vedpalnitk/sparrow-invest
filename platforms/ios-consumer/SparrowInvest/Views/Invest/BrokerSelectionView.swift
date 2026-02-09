//
//  BrokerSelectionView.swift
//  SparrowInvest
//
//  Broker selection for self-directed users
//

import SwiftUI

struct Broker: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let appScheme: String?  // URL scheme to open app
    let webURL: String
}

struct BrokerSelectionView: View {
    let fund: Fund
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showManualEntry = false

    private let brokers: [Broker] = [
        Broker(name: "Zerodha Coin", icon: "chart.line.uptrend.xyaxis", appScheme: "zerodha://", webURL: "https://coin.zerodha.com"),
        Broker(name: "Groww", icon: "leaf.fill", appScheme: "groww://", webURL: "https://groww.in"),
        Broker(name: "Kuvera", icon: "k.circle.fill", appScheme: nil, webURL: "https://kuvera.in"),
        Broker(name: "Paytm Money", icon: "indianrupeesign.circle.fill", appScheme: "paytmmoney://", webURL: "https://paytmmoney.com"),
        Broker(name: "ET Money", icon: "e.circle.fill", appScheme: nil, webURL: "https://etmoney.com")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Fund Info Header
                    fundInfoHeader

                    // Broker List
                    brokerListSection

                    // Manual Entry Section
                    manualEntrySection
                }
                .padding(AppTheme.Spacing.medium)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Choose Broker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualPortfolioEntryView()
            }
        }
    }

    // MARK: - Fund Info Header

    private var fundInfoHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(spacing: AppTheme.Spacing.medium) {
                // Fund Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                        .fill(Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.1))
                        .frame(width: 48, height: 48)

                    Text(fund.initials)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(fund.shortName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)

                    Text("Select a broker to invest in this fund")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Broker List Section

    private var brokerListSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("INVESTMENT PLATFORMS")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(spacing: 0) {
                ForEach(Array(brokers.enumerated()), id: \.element.id) { index, broker in
                    Button(action: { openBroker(broker) }) {
                        HStack(spacing: AppTheme.Spacing.medium) {
                            // Broker icon
                            ZStack {
                                Circle()
                                    .fill(brokerColor(for: broker).opacity(colorScheme == .dark ? 0.15 : 0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: broker.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(brokerColor(for: broker))
                            }

                            Text(broker.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(AppTheme.Spacing.medium)
                    }

                    if index < brokers.count - 1 {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Manual Entry Section

    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            Text("AFTER INVESTING")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
                .tracking(1)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text("Track your investment")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }

                    Text("After investing through your broker, add your investment manually or upload a portfolio screenshot to track it in SparrowInvest.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Button(action: { showManualEntry = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("Add Investment Manually")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Color.blue.opacity(colorScheme == .dark ? 0.15 : 0.1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(sectionBackground)
            .overlay(sectionBorder)
            .shadow(color: sectionShadow, radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Actions

    private func openBroker(_ broker: Broker) {
        // Try to open app first, fallback to web
        if let scheme = broker.appScheme,
           let url = URL(string: scheme),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: broker.webURL) {
            UIApplication.shared.open(url)
        }
    }

    private func brokerColor(for broker: Broker) -> Color {
        switch broker.name {
        case "Zerodha Coin": return .orange
        case "Groww": return .green
        case "Kuvera": return .blue
        case "Paytm Money": return .cyan
        case "ET Money": return .purple
        default: return .blue
        }
    }

    // MARK: - Styling

    private var sectionShadow: Color {
        colorScheme == .dark ? .clear : .black.opacity(0.08)
    }

    @ViewBuilder
    private var sectionBackground: some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color.black.opacity(0.4))
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
        } else {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(Color(uiColor: .white))
        }
    }

    private var sectionBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
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
                            .init(color: .black.opacity(0.1), location: 0),
                            .init(color: .black.opacity(0.05), location: 0.3),
                            .init(color: .black.opacity(0.03), location: 0.7),
                            .init(color: .black.opacity(0.07), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                lineWidth: 1
            )
    }
}

#Preview {
    BrokerSelectionView(fund: Fund(
        id: "119598",
        schemeCode: 119598,
        schemeName: "Parag Parikh Flexi Cap Fund Direct Growth",
        category: "Flexi Cap",
        assetClass: "equity",
        nav: 78.45,
        navDate: Date(),
        returns: FundReturns(oneMonth: 2.5, threeMonth: 5.8, sixMonth: 12.3, oneYear: 22.4, threeYear: 18.7, fiveYear: 19.2),
        aum: 48520,
        expenseRatio: 0.63,
        riskRating: 4,
        minSIP: 1000,
        minLumpSum: 1000,
        fundManager: "Rajeev Thakkar",
        fundHouse: "PPFAS"
    ))
}
