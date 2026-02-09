import Foundation
import SwiftUI

// MARK: - API Response Models

/// Goal response from /api/v1/me/goals (camelCase from backend)
struct GoalResponse: Decodable {
    let id: String
    let name: String
    let category: String
    let icon: String?
    let targetAmount: Double
    let currentAmount: Double
    let targetDate: String
    let monthlySip: Double?
    let linkedFundCodes: [String]?
    let status: String
    let priority: Int?
    let notes: String?
    let progress: Double?
    let daysRemaining: Int?
    let createdAt: String
    let updatedAt: String

    func toGoal() -> Goal {
        let categoryEnum: GoalCategory = {
            switch category.uppercased() {
            case "RETIREMENT": return .retirement
            case "EDUCATION": return .education
            case "HOME": return .home
            case "CAR": return .car
            case "VACATION", "TRAVEL": return .vacation
            case "WEDDING": return .wedding
            case "EMERGENCY": return .emergency
            case "WEALTH", "WEALTH_BUILDING": return .wealth
            default: return .custom
            }
        }()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let targetDateValue = dateFormatter.date(from: targetDate) ?? Date()

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdAtDate = isoFormatter.date(from: createdAt) ?? Date()

        return Goal(
            id: id,
            name: name,
            icon: icon ?? categoryEnum.icon,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: targetDateValue,
            category: categoryEnum,
            linkedFunds: linkedFundCodes ?? [],
            monthlySIP: monthlySip,
            createdAt: createdAtDate
        )
    }
}

/// Request to create a new goal (camelCase for backend)
struct CreateGoalRequest: Encodable {
    let name: String
    let category: String
    let icon: String?
    let targetAmount: Double
    let targetDate: String
    let currentAmount: Double?
    let monthlySip: Double?
    let linkedFundCodes: [String]?
    let notes: String?
    let priority: Int?
}

/// Request to update a goal (camelCase for backend)
struct UpdateGoalRequest: Encodable {
    let name: String?
    let category: String?
    let icon: String?
    let targetAmount: Double?
    let targetDate: String?
    let currentAmount: Double?
    let monthlySip: Double?
    let linkedFundCodes: [String]?
    let notes: String?
    let status: String?
    let priority: Int?
}

// MARK: - Goals Store

@MainActor
class GoalsStore: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let apiService = APIService.shared

    init() {
        loadMockData()
    }

    func fetchGoals() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: [GoalResponse] = try await apiService.get("/me/goals")
            self.goals = response.map { $0.toGoal() }
            self.error = nil
        } catch {
            self.error = error
            // Fallback to mock data for development
            print("Failed to fetch goals from API: \(error). Using mock data.")
            loadMockData()
        }
    }

    func createGoal(_ goal: Goal) async throws {
        isLoading = true
        defer { isLoading = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let request = CreateGoalRequest(
            name: goal.name,
            category: goal.category.rawValue.uppercased().replacingOccurrences(of: " ", with: "_"),
            icon: goal.icon,
            targetAmount: goal.targetAmount,
            targetDate: dateFormatter.string(from: goal.targetDate),
            currentAmount: goal.currentAmount,
            monthlySip: goal.monthlySIP,
            linkedFundCodes: goal.linkedFunds.isEmpty ? nil : goal.linkedFunds,
            notes: nil,
            priority: nil
        )

        let response: GoalResponse = try await apiService.post("/me/goals", body: request)
        goals.append(response.toGoal())
    }

    func updateGoal(_ goal: Goal) async throws {
        isLoading = true
        defer { isLoading = false }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let request = UpdateGoalRequest(
            name: goal.name,
            category: nil,
            icon: goal.icon,
            targetAmount: goal.targetAmount,
            targetDate: dateFormatter.string(from: goal.targetDate),
            currentAmount: goal.currentAmount,
            monthlySip: goal.monthlySIP,
            linkedFundCodes: goal.linkedFunds,
            notes: nil,
            status: nil,
            priority: nil
        )

        let response: GoalResponse = try await apiService.put("/me/goals/\(goal.id)", body: request)

        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = response.toGoal()
        }
    }

    func deleteGoal(_ goalId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        try await apiService.delete("/me/goals/\(goalId)")
        goals.removeAll { $0.id == goalId }
    }

    /// Link a fund to a goal by updating the goal's linkedFundCodes
    func linkFund(_ fundCode: String, toGoal goalId: String) async throws {
        guard let goal = goals.first(where: { $0.id == goalId }) else { return }
        var updatedFunds = goal.linkedFunds
        if !updatedFunds.contains(fundCode) {
            updatedFunds.append(fundCode)
        }
        let request = UpdateGoalRequest(
            name: nil, category: nil, icon: nil, targetAmount: nil,
            targetDate: nil, currentAmount: nil, monthlySip: nil,
            linkedFundCodes: updatedFunds, notes: nil, status: nil, priority: nil
        )
        _ = try await apiService.put("/me/goals/\(goalId)", body: request) as GoalResponse
        await fetchGoals()
    }

    /// Unlink a fund from a goal by updating the goal's linkedFundCodes
    func unlinkFund(_ fundCode: String, fromGoal goalId: String) async throws {
        guard let goal = goals.first(where: { $0.id == goalId }) else { return }
        let updatedFunds = goal.linkedFunds.filter { $0 != fundCode }
        let request = UpdateGoalRequest(
            name: nil, category: nil, icon: nil, targetAmount: nil,
            targetDate: nil, currentAmount: nil, monthlySip: nil,
            linkedFundCodes: updatedFunds, notes: nil, status: nil, priority: nil
        )
        _ = try await apiService.put("/me/goals/\(goalId)", body: request) as GoalResponse
        await fetchGoals()
    }

    // Synchronous add for simple UI operations (local only)
    func addGoal(_ goal: Goal) {
        goals.append(goal)
    }

    private func loadMockData() {
        goals = [
            Goal(
                id: "1",
                name: "Home Down Payment",
                icon: "house.fill",
                targetAmount: 500000,
                currentAmount: 310000,
                targetDate: Date().addingTimeInterval(86400 * 365 * 2),
                category: .home,
                linkedFunds: ["119598", "119775"],
                monthlySIP: 12500,
                createdAt: Date().addingTimeInterval(-86400 * 365)
            ),
            Goal(
                id: "2",
                name: "Retirement Fund",
                icon: "beach.umbrella",
                targetAmount: 10000000,
                currentAmount: 850000,
                targetDate: Date().addingTimeInterval(86400 * 365 * 25),
                category: .retirement,
                linkedFunds: ["119598", "120503"],
                monthlySIP: 15000,
                createdAt: Date().addingTimeInterval(-86400 * 365 * 2)
            ),
            Goal(
                id: "3",
                name: "Emergency Fund",
                icon: "cross.case.fill",
                targetAmount: 300000,
                currentAmount: 300000,
                targetDate: Date().addingTimeInterval(-86400 * 30),
                category: .emergency,
                linkedFunds: ["119775"],
                monthlySIP: nil,
                createdAt: Date().addingTimeInterval(-86400 * 365)
            )
        ]
    }
}
