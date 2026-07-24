import Dependencies
import MaterialDesignColorSwiftUI
import SwiftUI

public struct GameCenterGoalProgressInput: Identifiable, Equatable, Sendable {
    public var goal: GameCenterGoal
    public var currentValue: Int
    public var reportsAchievementOnCompletion: Bool

    public var id: String { goal.id }

    public init(
        goal: GameCenterGoal,
        currentValue: Int,
        reportsAchievementOnCompletion: Bool = true
    ) {
        self.goal = goal
        self.currentValue = currentValue
        self.reportsAchievementOnCompletion = reportsAchievementOnCompletion
    }
}

/// Game Center 탭 하나에 들어가는 메인 화면.
///
/// 프로필 칩 · 미션 카드 · 리더보드를 단일 `ScrollView`로 묶어, iOS 26의
/// 떠 있는 탭바 최소화와 스크롤 엣지 글래스 효과가 자연스럽게 동작하도록 구성한다.
/// 탭바 자체는 이 패키지를 사용하는 앱이 소유하며, 이 뷰는 그 탭의 콘텐츠다.
public struct GameCenterMainView: View {
    @StateObject private var model: GameCenterDashboardViewModel
    @State private var isGoalsPopupPresented = false
    @State private var leaderboardRefreshTrigger = 0
    @State private var achievementSyncTrigger = 0
    #if DEBUG
    @State private var isResettingAchievements = false
    @State private var resetAchievementsMessage: String?
    #endif

    private let theme: MaterialTheme
    private let goals: [GameCenterGoalProgressInput]
    private let showsProfileChip: Bool
    private let showsPlayerScopePicker: Bool
    private let isAchievementSoundEnabled: Bool

    #if DEBUG
    @Dependency(\.gameCenterAchievementClient) private var achievementClient
    @Dependency(\.gameCenterAchievementProgressCache) private var achievementProgressCache
    #endif

    public init(
        configuration: GameCenterConfiguration,
        theme: MaterialTheme,
        goals: [GameCenterGoalProgressInput] = [],
        selectedCategoryID: String? = nil,
        selectedScope: GameCenterRankingScope = .daily,
        playerScope: GameCenterPlayerScope = .global,
        range: Range<Int> = 1..<51,
        showsProfileChip: Bool = true,
        showsPlayerScopePicker: Bool = true,
        isAchievementSoundEnabled: Bool = false
    ) {
        self.theme = theme
        self.goals = goals
        self.showsProfileChip = showsProfileChip
        self.showsPlayerScopePicker = showsPlayerScopePicker
        self.isAchievementSoundEnabled = isAchievementSoundEnabled
        _model = StateObject(
            wrappedValue: GameCenterDashboardViewModel(
                configuration: configuration,
                selectedCategoryID: selectedCategoryID,
                selectedScope: selectedScope,
                playerScope: playerScope,
                range: range
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showsProfileChip {
                    GameCenterNicknameView(detailText: localPlayerDetailText) {
                        leaderboardRefreshTrigger += 1
                    }
                }

                if !goals.isEmpty {
                    missionsSection
                }

                sectionHeader(GameCenterLocalizedString.string("ui.leaderboard.section_title"))

                GameCenterLeaderboardSection(
                    model: model,
                    showsPlayerScopePicker: showsPlayerScopePicker,
                    refreshTrigger: leaderboardRefreshTrigger
                )
            }
            .padding()
        }
        .background(theme.colorScheme.surface.color)
        .materialTheme(theme)
        .gameCenterRankingNavigationTitle()
        .toolbar {
            ToolbarItem(placement: goalsToolbarPlacement) {
                goalsToolbarContent
            }
            #if DEBUG
            ToolbarItem(placement: debugToolbarPlacement) {
                debugToolbarContent
            }
            #endif
        }
        .popover(isPresented: $isGoalsPopupPresented) {
            GameCenterGoalsPopupView(
                goals: goals,
                syncTrigger: achievementSyncTrigger,
                isAchievementSoundEnabled: isAchievementSoundEnabled,
                onAchievementReported: refreshAchievementState
            )
                .materialTheme(theme)
                .gameCenterSheetDetents()
        }
        #if DEBUG
        .alert(
            GameCenterLocalizedString.string("ui.debug.title"),
            isPresented: resetAchievementsMessageBinding
        ) {
            Button(GameCenterLocalizedString.string("ui.action.confirm"), role: .cancel) {
                resetAchievementsMessage = nil
            }
        } message: {
            Text(resetAchievementsMessage ?? "")
        }
        #endif
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundStyle(theme.colorScheme.onSurface.color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var missionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(GameCenterLocalizedString.string("ui.missions.title"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(goals) { input in
                        GameCenterGoalProgressView(
                            goal: input.goal,
                            currentValue: input.currentValue,
                            reportsAchievementOnCompletion: input.reportsAchievementOnCompletion,
                            style: .square,
                            syncTrigger: achievementSyncTrigger,
                            isAchievementSoundEnabled: isAchievementSoundEnabled,
                            onAchievementReported: refreshAchievementState
                        )
                        .frame(width: 160)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var localPlayerDetailText: String? {
        guard let entry = model.snapshot?.localPlayerEntry else {
            return nil
        }

        return "#\(entry.rank) · \(entry.formattedScore)"
    }

    private func refreshAchievementState() {
        achievementSyncTrigger += 1
    }

    @ViewBuilder
    private var goalsToolbarContent: some View {
        if goals.isEmpty {
            EmptyView()
        } else {
            Button {
                isGoalsPopupPresented = true
            } label: {
                goalsButtonLabel
            }
            .gameCenterGlassButton(isProminent: goals.gameCenterCompletedGoalCount == goals.count)
            .accessibilityLabel(GameCenterLocalizedString.string("accessibility.goals.button"))
            .accessibilityValue(
                GameCenterLocalizedString.format(
                    "accessibility.goals.value",
                    goals.gameCenterCompletedGoalCount,
                    goals.count
                )
            )
        }
    }

    @ViewBuilder
    private var goalsButtonLabel: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            HStack(spacing: 6) {
                Image(systemName: goalsButtonSystemImage)
                    .imageScale(.medium)
                Text(GameCenterLocalizedString.string("ui.goals.title"))
                    .font(.subheadline.weight(.semibold))
            }
        } else {
            Image(systemName: goalsButtonSystemImage)
                .imageScale(.large)
        }
    }

    private var goalsButtonSystemImage: String {
        goals.gameCenterCompletedGoalCount == goals.count ? "checkmark.seal.fill" : "target"
    }

    private var goalsToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .primaryAction
        #elseif os(iOS)
        if #available(iOS 16.0, *) {
            return .topBarTrailing
        } else {
            return .navigationBarTrailing
        }
        #else
        return .topBarTrailing
        #endif
    }

    #if DEBUG
    private var debugToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        return .automatic
        #elseif os(iOS)
        if #available(iOS 16.0, *) {
            return .topBarLeading
        } else {
            return .navigationBarLeading
        }
        #else
        return .topBarLeading
        #endif
    }

    private var debugToolbarContent: some View {
        Menu {
            Button(role: .destructive) {
                Task { await resetAchievementsFromDebugMenu() }
            } label: {
                Label(
                    GameCenterLocalizedString.string("ui.debug.achievement_reset"),
                    systemImage: "arrow.counterclockwise.circle"
                )
            }
            .disabled(isResettingAchievements)
        } label: {
            Image(systemName: "wrench.and.screwdriver")
                .imageScale(.large)
        }
        .gameCenterGlassButton()
        .accessibilityLabel(GameCenterLocalizedString.string("accessibility.debug.menu"))
    }

    private var resetAchievementsMessageBinding: Binding<Bool> {
        Binding(
            get: { resetAchievementsMessage != nil },
            set: { isPresented in
                if !isPresented {
                    resetAchievementsMessage = nil
                }
            }
        )
    }

    @MainActor
    private func resetAchievementsFromDebugMenu() async {
        isResettingAchievements = true
        defer { isResettingAchievements = false }

        do {
            try await achievementClient.resetAchievements()
            await achievementProgressCache.invalidate()
            achievementSyncTrigger += 1
            resetAchievementsMessage = GameCenterLocalizedString.string(
                "ui.debug.achievement_reset.success"
            )
        } catch {
            resetAchievementsMessage = GameCenterLocalizedString.format(
                "ui.debug.achievement_reset.failure",
                gameCenterDisplayMessage(for: error)
            )
        }
    }
    #endif
}

private extension View {
    @ViewBuilder
    func gameCenterRankingNavigationTitle() -> some View {
        #if os(iOS) || os(visionOS)
        navigationTitle(GameCenterLocalizedString.string("ui.leaderboard.title"))
            .navigationBarTitleDisplayMode(.large)
        #else
        navigationTitle(GameCenterLocalizedString.string("ui.leaderboard.title"))
        #endif
    }
}

#if DEBUG
#Preview("Game Center 메인") {
    GameCenterMainView(
        configuration: GameCenterConfiguration(
            leaderboardIDs: [
                .daily: "preview.daily",
                .weekly: "preview.weekly",
                .allTime: "preview.all-time",
            ]
        ),
        theme: .light,
        goals: [
            GameCenterGoalProgressInput(
                goal: GameCenterGoal(id: "score", title: "주간 1,000점", targetValue: 1000),
                currentValue: 720
            ),
            GameCenterGoalProgressInput(
                goal: GameCenterGoal(id: "win", title: "10승 달성", targetValue: 10, achievementID: "ach.win"),
                currentValue: 10
            ),
        ]
    )
}
#endif
