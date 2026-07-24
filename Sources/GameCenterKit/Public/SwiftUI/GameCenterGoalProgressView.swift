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
    private let syncTrigger: Int
    private let authenticatedPlayerID: String?
    private let isAchievementSoundEnabled: Bool
    private let onAchievementReported: () -> Void

    @State private var didReportAchievement = false
    @State private var isReportingAchievement = false
    @State private var isAchievementStateSynced = false
    @State private var syncedPlayerID: String?
    @State private var achievementSyncGeneration: UInt = 0
    @State private var achievementSyncRetryState = AchievementSyncRetryState()
    @State private var achievementReportErrorState = AchievementReportErrorState()

    @Environment(\.materialTheme) private var materialTheme
    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient
    @Dependency(\.gameCenterAchievementClient) private var achievementClient
    @Dependency(\.gameCenterAchievementFeedbackClient) private var achievementFeedbackClient
    @Dependency(\.gameCenterAchievementProgressCache) private var achievementProgressCache
    @Dependency(\.gameCenterAchievementReportCoordinator) private var achievementReportCoordinator

    private var effectiveTheme: MaterialTheme {
        theme ?? materialTheme
    }

    public init(
        goal: GameCenterGoal,
        currentValue: Int,
        theme: MaterialTheme? = nil,
        reportsAchievementOnCompletion: Bool = true,
        style: GameCenterGoalProgressViewStyle = .fullWidth,
        syncTrigger: Int = 0,
        authenticatedPlayerID: String? = nil,
        isAchievementSoundEnabled: Bool = false,
        onAchievementReported: @escaping () -> Void = {}
    ) {
        self.goal = goal
        self.currentValue = currentValue
        self.reportsAchievementOnCompletion = reportsAchievementOnCompletion
        self.style = style
        self.theme = theme
        self.syncTrigger = syncTrigger
        self.authenticatedPlayerID = authenticatedPlayerID
        self.isAchievementSoundEnabled = isAchievementSoundEnabled
        self.onAchievementReported = onAchievementReported
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
                    GameCenterLocalizedString.string(
                        isCompleted
                            ? "ui.goal.status.completed"
                            : "ui.goal.status.in_progress"
                    ),
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
                            Text(
                                GameCenterLocalizedString.string(
                                    didReportAchievement
                                        ? "ui.goal.action.completed"
                                        : "ui.goal.action.report"
                                )
                            )
                        }
                    }
                    .gameCenterGlassButton(isProminent: true)
                    .disabled(isReportingAchievement || didReportAchievement || !isAchievementStateSynced)
                }
            }

            if let displayedErrorMessage {
                Text(displayedErrorMessage)
                    .font(.caption)
                    .foregroundStyle(scheme.error.color)
            }

            if achievementSyncRetryState.canRetry {
                Button {
                    retryAchievementSync()
                } label: {
                    Label(
                        GameCenterLocalizedString.string("ui.action.retry"),
                        systemImage: "arrow.clockwise"
                    )
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(scheme.primary.color)
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
                            GameCenterLocalizedString.string(
                                didReportAchievement
                                    ? "ui.goal.action.completed"
                                    : "ui.goal.action.report"
                            ),
                            systemImage: didReportAchievement ? "checkmark" : "arrow.up.circle"
                        )
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    }
                }
                .gameCenterGlassButton(isProminent: !didReportAchievement)
                .disabled(isReportingAchievement || didReportAchievement || !isAchievementStateSynced)
            }

            if let displayedErrorMessage {
                Text(displayedErrorMessage)
                    .font(.caption2)
                    .foregroundStyle(scheme.error.color)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }

            if achievementSyncRetryState.canRetry {
                Button {
                    retryAchievementSync()
                } label: {
                    Label(
                        GameCenterLocalizedString.string("ui.action.retry"),
                        systemImage: "arrow.clockwise"
                    )
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(scheme.primary.color)
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

    private var displayedErrorMessage: String? {
        achievementSyncRetryState.errorMessage
            ?? achievementReportErrorState.message(for: achievementSyncID)
    }

    private var achievementSyncID: AchievementSyncID {
        AchievementSyncID(
            achievementID: goal.achievementID,
            isAuthenticated: authenticationClient.isAuthenticated,
            authenticatedPlayerID: authenticatedPlayerID,
            syncTrigger: syncTrigger,
            retryTrigger: achievementSyncRetryState.retryTrigger
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

    @MainActor
    private func reportAchievement() async {
        guard let achievementID = goal.achievementID,
              isAchievementStateSynced,
              let syncedPlayerID
        else {
            return
        }

        let expectedSyncID = achievementSyncID
        let expectedPlayerID = syncedPlayerID
        isReportingAchievement = true
        achievementReportErrorState.clear()

        defer {
            isReportingAchievement = false
        }

        do {
            let result = try await achievementReportCoordinator.report(
                syncedPlayerID,
                GameCenterAchievementReport(
                    achievementID: achievementID,
                    percentComplete: 100,
                    showsCompletionBanner: true
                ),
                authenticationClient,
                achievementClient
            )
            await achievementProgressCache.markCompleted(expectedPlayerID, achievementID)

            guard isCurrentReportContext(
                expectedSyncID: expectedSyncID,
                expectedPlayerID: expectedPlayerID
            ) else {
                return
            }
            if isAchievementSoundEnabled, case .reported = result {
                achievementFeedbackClient.playAchievementUnlockedSound()
            }
            didReportAchievement = true
            onAchievementReported()
        } catch {
            guard isCurrentReportContext(
                expectedSyncID: expectedSyncID,
                expectedPlayerID: expectedPlayerID
            ) else {
                return
            }
            achievementReportErrorState.fail(
                with: gameCenterDisplayMessage(for: error),
                syncID: expectedSyncID
            )
            await syncReportedAchievementState()
        }
    }

    @MainActor
    private func syncReportedAchievementState() async {
        guard !Task.isCancelled else { return }

        achievementSyncGeneration &+= 1
        let expectedGeneration = achievementSyncGeneration
        let expectedSyncID = achievementSyncID
        isAchievementStateSynced = false
        achievementSyncRetryState.beginSync()

        guard let achievementID = goal.achievementID else {
            didReportAchievement = false
            syncedPlayerID = nil
            isAchievementStateSynced = true
            return
        }

        guard authenticationClient.isAuthenticated else {
            didReportAchievement = false
            syncedPlayerID = nil
            await achievementProgressCache.invalidate(nil)
            return
        }

        do {
            let localPlayer = try await authenticationClient.localPlayer()
            guard isCurrentSync(
                expectedSyncID: expectedSyncID,
                expectedGeneration: expectedGeneration
            ) else {
                return
            }
            guard localPlayer.isAuthenticated,
                  authenticatedPlayerID == nil || localPlayer.gamePlayerID == authenticatedPlayerID
            else {
                didReportAchievement = false
                syncedPlayerID = nil
                return
            }

            let playerID = localPlayer.gamePlayerID
            let achievements = try await achievementProgressCache.load(playerID, achievementClient)
            guard isCurrentSync(
                expectedSyncID: expectedSyncID,
                expectedGeneration: expectedGeneration
            ) else {
                return
            }
            let refreshedPlayer = try await authenticationClient.localPlayer()
            guard isCurrentSync(
                expectedSyncID: expectedSyncID,
                expectedGeneration: expectedGeneration
            ) else {
                return
            }
            guard refreshedPlayer.isAuthenticated, refreshedPlayer.gamePlayerID == playerID else {
                didReportAchievement = false
                syncedPlayerID = nil
                return
            }

            syncedPlayerID = playerID
            guard let progress = achievements.first(where: { $0.id == achievementID }) else {
                didReportAchievement = false
                isAchievementStateSynced = true
                return
            }

            didReportAchievement = progress.isCompleted || progress.percentComplete >= 100
            if didReportAchievement {
                achievementReportErrorState.clear(ifMatching: expectedSyncID)
            }
            isAchievementStateSynced = true
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentSync(
                expectedSyncID: expectedSyncID,
                expectedGeneration: expectedGeneration
            ) else {
                return
            }
            achievementSyncRetryState.fail(with: gameCenterDisplayMessage(for: error))
        }
    }

    @MainActor
    private func retryAchievementSync() {
        achievementSyncRetryState.retry()
    }

    @MainActor
    private func isCurrentSync(
        expectedSyncID: AchievementSyncID,
        expectedGeneration: UInt
    ) -> Bool {
        canApplyAchievementSyncResult(
            expectedSyncID: expectedSyncID,
            currentSyncID: achievementSyncID,
            expectedGeneration: expectedGeneration,
            currentGeneration: achievementSyncGeneration
        )
    }

    @MainActor
    private func isCurrentReportContext(
        expectedSyncID: AchievementSyncID,
        expectedPlayerID: String
    ) -> Bool {
        !Task.isCancelled
            && achievementSyncID == expectedSyncID
            && syncedPlayerID == expectedPlayerID
    }
}

struct AchievementSyncID: Equatable {
    var achievementID: String?
    var isAuthenticated: Bool
    var authenticatedPlayerID: String?
    var syncTrigger: Int
    var retryTrigger: UInt = 0
}

struct AchievementSyncRetryState: Equatable {
    private(set) var errorMessage: String?
    private(set) var retryTrigger: UInt = 0

    var canRetry: Bool {
        errorMessage != nil
    }

    mutating func beginSync() {
        errorMessage = nil
    }

    mutating func fail(with message: String) {
        errorMessage = message
    }

    mutating func retry() {
        errorMessage = nil
        retryTrigger &+= 1
    }
}

struct AchievementReportErrorState: Equatable {
    private(set) var message: String?
    private(set) var syncID: AchievementSyncID?

    func message(for currentSyncID: AchievementSyncID) -> String? {
        guard syncID == currentSyncID else { return nil }
        return message
    }

    mutating func fail(with message: String, syncID: AchievementSyncID) {
        self.message = message
        self.syncID = syncID
    }

    mutating func clear(ifMatching expectedSyncID: AchievementSyncID) {
        guard syncID == expectedSyncID else { return }
        clear()
    }

    mutating func clear() {
        message = nil
        syncID = nil
    }
}

func canApplyAchievementSyncResult(
    expectedSyncID: AchievementSyncID,
    currentSyncID: AchievementSyncID,
    expectedGeneration: UInt,
    currentGeneration: UInt
) -> Bool {
    !Task.isCancelled
        && expectedSyncID == currentSyncID
        && expectedGeneration == currentGeneration
}
