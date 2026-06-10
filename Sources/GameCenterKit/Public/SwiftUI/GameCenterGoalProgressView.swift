import Dependencies
import SwiftUI

public struct GameCenterGoalProgressView: View {
    private let goal: GameCenterGoal
    private let currentValue: Int
    private let reportsAchievementOnCompletion: Bool

    @State private var didReportAchievement = false
    @State private var isReportingAchievement = false
    @State private var errorMessage: String?

    @Dependency(\.gameCenterAchievementClient) private var achievementClient

    public init(
        goal: GameCenterGoal,
        currentValue: Int,
        reportsAchievementOnCompletion: Bool = true
    ) {
        self.goal = goal
        self.currentValue = currentValue
        self.reportsAchievementOnCompletion = reportsAchievementOnCompletion
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text("\(min(currentValue, goal.targetValue))/\(goal.targetValue)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)

            HStack {
                Text(isCompleted ? "목표 달성" : "진행 중")
                    .font(.footnote)
                    .foregroundStyle(isCompleted ? .primary : .secondary)

                Spacer()

                if shouldShowReportButton {
                    Button {
                        Task { await reportAchievement() }
                    } label: {
                        if isReportingAchievement {
                            ProgressView()
                        } else {
                            Text(didReportAchievement ? "완료됨" : "달성 보고")
                        }
                    }
                    .disabled(isReportingAchievement || didReportAchievement)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: goal.achievementID) {
            await syncReportedAchievementState()
        }
    }

    private var progress: Double {
        guard goal.targetValue > 0 else {
            return 1
        }

        return min(Double(currentValue) / Double(goal.targetValue), 1)
    }

    private var isCompleted: Bool {
        currentValue >= goal.targetValue
    }

    private var shouldShowReportButton: Bool {
        reportsAchievementOnCompletion && isCompleted && goal.achievementID != nil
    }

    private func reportAchievement() async {
        guard let achievementID = goal.achievementID else {
            return
        }

        isReportingAchievement = true
        errorMessage = nil

        defer {
            isReportingAchievement = false
        }

        do {
            try await achievementClient.reportAchievement(
                achievementID: achievementID,
                percentComplete: 100,
                showsCompletionBanner: true
            )
            didReportAchievement = true
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func syncReportedAchievementState() async {
        guard let achievementID = goal.achievementID else {
            didReportAchievement = false
            return
        }

        do {
            let achievements = try await achievementClient.loadAchievements()
            guard let progress = achievements.first(where: { $0.id == achievementID }) else {
                didReportAchievement = false
                return
            }

            didReportAchievement = progress.isCompleted || progress.percentComplete >= 100
        } catch {
            didReportAchievement = false
        }
    }
}
