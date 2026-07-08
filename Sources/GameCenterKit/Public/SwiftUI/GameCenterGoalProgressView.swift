import Dependencies
import MaterialDesignColorSwiftUI
import ShimmerUI
import SwiftUI

public enum GameCenterGoalProgressViewStyle: Sendable {
    case fullWidth
    case square
}

public struct GameCenterGoalProgressView: View {
    private let goal: GameCenterGoal
    private let currentValue: Int
    private let reportsAchievementOnCompletion: Bool
    private let style: GameCenterGoalProgressViewStyle
    private let theme: MaterialTheme?

    @State private var didReportAchievement = false
    @State private var isReportingAchievement = false
    @State private var errorMessage: String?

    @Environment(\.materialTheme) private var materialTheme
    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient
    @Dependency(\.gameCenterAchievementClient) private var achievementClient

    private var effectiveTheme: MaterialTheme {
        theme ?? materialTheme
    }

    public init(
        goal: GameCenterGoal,
        currentValue: Int,
        theme: MaterialTheme,
        reportsAchievementOnCompletion: Bool = true,
        style: GameCenterGoalProgressViewStyle = .fullWidth
    ) {
        self.goal = goal
        self.currentValue = currentValue
        self.reportsAchievementOnCompletion = reportsAchievementOnCompletion
        self.style = style
        self.theme = theme
    }

    init(
        goal: GameCenterGoal,
        currentValue: Int,
        reportsAchievementOnCompletion: Bool = true,
        style: GameCenterGoalProgressViewStyle = .fullWidth
    ) {
        self.goal = goal
        self.currentValue = currentValue
        self.reportsAchievementOnCompletion = reportsAchievementOnCompletion
        self.style = style
        self.theme = nil
    }

    public var body: some View {
        content
            .task(id: achievementSyncID) {
                await syncReportedAchievementState()
            }
            .gameCenterProvidedMaterialTheme(theme)
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .fullWidth:
            fullWidthContent
        case .square:
            squareContent
        }
    }

    private var fullWidthContent: some View {
        let scheme = effectiveTheme.colorScheme

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(scheme.onSurface.color)

                Spacer()

                Text("\(min(currentValue, goal.targetValue))/\(goal.targetValue)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(scheme.onSurfaceVariant.color)
                    .gameCenterNumericTransition()
                    .animation(.default, value: currentValue)
            }

            ProgressView(value: progress)
                .tint(isCompleted ? scheme.tertiary.color : scheme.primary.color)

            HStack {
                Label(
                    isCompleted ? "목표 달성" : "진행 중",
                    systemImage: isCompleted ? "checkmark.seal.fill" : "flame"
                )
                .font(.footnote)
                .foregroundStyle(isCompleted ? AnyShapeStyle(scheme.tertiary.color) : AnyShapeStyle(scheme.onSurfaceVariant.color))
                .gameCenterCompletionBounce(isCompleted: isCompleted)

                Spacer()

                if shouldShowReportButton {
                    Button {
                        Task { await reportAchievement() }
                    } label: {
                        if isReportingAchievement {
                            reportingPlaceholder(width: 68, height: 18)
                        } else {
                            Text(didReportAchievement ? "완료됨" : "달성 보고")
                        }
                    }
                    .gameCenterGlassButton(isProminent: true)
                    .disabled(isReportingAchievement || didReportAchievement)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(scheme.error.color)
            }
        }
        .padding(16)
        .gameCenterGlassCard()
    }

    private var squareContent: some View {
        let scheme = effectiveTheme.colorScheme

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Image(systemName: isCompleted ? "checkmark.seal.fill" : "target")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isCompleted ? scheme.tertiary.color : scheme.primary.color)
                    .gameCenterCompletionBounce(isCompleted: isCompleted)

                Spacer()

                Text(progressPercentText)
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(scheme.onSurfaceVariant.color)
                    .gameCenterNumericTransition()
                    .animation(.default, value: currentValue)
            }

            Spacer(minLength: 6)

            Text(goal.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scheme.onSurface.color)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            ProgressView(value: progress)
                .tint(isCompleted ? scheme.tertiary.color : scheme.primary.color)

            Text("\(min(currentValue, goal.targetValue))/\(goal.targetValue)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(scheme.onSurfaceVariant.color)
                .lineLimit(1)
                .gameCenterNumericTransition()
                .animation(.default, value: currentValue)

            if shouldShowReportButton {
                Button {
                    Task { await reportAchievement() }
                } label: {
                    if isReportingAchievement {
                        reportingPlaceholder(width: 62, height: 16)
                    } else {
                        Label(
                            didReportAchievement ? "완료됨" : "달성 보고",
                            systemImage: didReportAchievement ? "checkmark" : "arrow.up.circle"
                        )
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    }
                }
                .gameCenterGlassButton(isProminent: !didReportAchievement)
                .disabled(isReportingAchievement || didReportAchievement)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(scheme.error.color)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .gameCenterGlassCard(cornerRadius: 20)
    }

    private var progress: Double {
        guard goal.targetValue > 0 else {
            return 1
        }

        return max(0, min(Double(currentValue) / Double(goal.targetValue), 1))
    }

    private var isCompleted: Bool {
        currentValue >= goal.targetValue
    }

    private var shouldShowReportButton: Bool {
        reportsAchievementOnCompletion && isCompleted && goal.achievementID != nil
    }

    private var achievementSyncID: AchievementSyncID {
        AchievementSyncID(
            achievementID: goal.achievementID,
            isAuthenticated: authenticationClient.isAuthenticated
        )
    }

    private var progressPercentText: String {
        "\(Int((progress * 100).rounded()))%"
    }

    private func reportingPlaceholder(width: CGFloat, height: CGFloat) -> some View {
        ShimmerLoadingUI.Container(configuration: effectiveTheme.gameCenterShimmerConfiguration) {
            ShimmerLoadingUI.Block(.capsule)
                .frame(width: width, height: height)
        }
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
            return
        }
    }
}

private struct AchievementSyncID: Equatable {
    var achievementID: String?
    var isAuthenticated: Bool
}
