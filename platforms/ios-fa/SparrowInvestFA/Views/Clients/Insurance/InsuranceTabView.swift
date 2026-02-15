import SwiftUI

struct InsuranceTabView: View {
    let clientId: String
    @StateObject private var store = InsuranceStore()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAddPolicy = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            // Gap Analysis Card
            GapAnalysisCard(gapAnalysis: store.gapAnalysis)

            // Header with count + add button
            HStack {
                Text("Insurance Policies (\(store.policies.count))")
                    .font(AppTheme.Typography.accent(15))
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    showAddPolicy = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add Policy")
                            .font(AppTheme.Typography.accent(13))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(AppTheme.primaryGradient)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)

            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xxxLarge)
            } else if store.policies.isEmpty {
                emptyState
            } else {
                ForEach(store.policies) { policy in
                    policyCard(policy)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .sheet(isPresented: $showAddPolicy) {
            AddInsurancePolicySheet(clientId: clientId, store: store)
        }
        .task {
            await store.loadPolicies(clientId: clientId)
            await store.loadGapAnalysis(clientId: clientId)
        }
    }

    // MARK: - Policy Card

    private func policyCard(_ policy: InsurancePolicy) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.compact) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                // Type icon
                ZStack {
                    Circle()
                        .fill(policy.statusColor.opacity(0.12))
                        .frame(width: 36, height: 36)

                    Image(systemName: policy.typeIcon)
                        .font(.system(size: 15))
                        .foregroundColor(policy.statusColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(policy.provider)
                        .font(AppTheme.Typography.accent(14))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(policy.typeLabel)
                        .font(AppTheme.Typography.body(12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status badge
                Text(policy.statusLabel)
                    .font(AppTheme.Typography.label(10))
                    .foregroundColor(policy.statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(policy.statusColor.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Details grid
            HStack(spacing: AppTheme.Spacing.small) {
                detailItem(label: "Sum Assured", value: policy.formattedSumAssured)
                detailItem(label: "Premium", value: "\(policy.formattedPremium)/\(policy.premiumFrequency.prefix(1).lowercased() == "a" ? "yr" : policy.premiumFrequency.prefix(1).lowercased() == "m" ? "mo" : "qtr")")
                detailItem(label: "Policy #", value: policy.policyNumber)
            }

            // Nominees if present
            if let nominees = policy.nominees, !nominees.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(nominees)
                        .font(AppTheme.Typography.label(11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.leading, 4)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(policy.isLifeCover ? AppTheme.primary : (policy.isHealthCover ? Color(hex: "10B981") : Color(hex: "F59E0B")))
                .frame(width: 4)
        }
        .glassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.compact)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    _ = await store.deletePolicy(clientId: clientId, policyId: policy.id)
                    await store.loadGapAnalysis(clientId: clientId)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Detail Item

    private func detailItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTheme.Typography.label(9))
                .foregroundColor(.secondary)
            Text(value)
                .font(AppTheme.Typography.accent(12))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: "shield")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No insurance policies")
                .font(AppTheme.Typography.headline(17))
                .foregroundColor(.primary)

            Text("Tap \"Add Policy\" to record your client's insurance coverage")
                .font(AppTheme.Typography.body(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxxLarge)
    }
}
