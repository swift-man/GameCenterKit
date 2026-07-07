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
    #if DEBUG
    @State private var isResettingAchievements = false
    @State private var resetAchievementsMessage: String?
    #endif

    private let theme: MaterialTheme
    private let goals: [GameCenterGoalProgressInput]
    private let showsProfileChip: Bool
    private let showsPlayerScopePicker: Bool

    #if DEBUG
    @Dependency(\.gameCenterAchievementClient) private var achievementClient
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
        showsPlayerScopePicker: Bool = true
    ) {
        self.theme = theme
        self.goals = goals
        self.showsProfileChip = showsProfileChip
        self.showsPlayerScopePicker = showsPlayerScopePicker
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
                    GameCenterNicknameView(detailText: localPlayerDetailText)
                }

                if !goals.isEmpty {
                    missionsSection
                }

                sectionHeader("리더보드")

                GameCenterLeaderboardSection(
                    model: model,
                    showsPlayerScopePicker: showsPlayerScopePicker
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
            GameCenterGoalsPopupView(goals: goals)
                .materialTheme(theme)
                .gameCenterSheetDetents()
        }
        #if DEBUG
        .alert(
            "Game Center Debug",
            isPresented: resetAchievementsMessageBinding
        ) {
            Button("확인", role: .cancel) {
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
            sectionHeader("미션")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(goals) { input in
                        GameCenterGoalProgressView(
                            goal: input.goal,
                            currentValue: input.currentValue,
                            reportsAchievementOnCompletion: input.reportsAchievementOnCompletion,
                            style: .square
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
            .gameCenterGlassButton(isProminent: completedGoalCount == goals.count)
            .accessibilityLabel("목표 달성")
            .accessibilityValue("\(completedGoalCount)/\(goals.count)")
        }
    }

    @ViewBuilder
    private var goalsButtonLabel: some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            HStack(spacing: 6) {
                Image(systemName: goalsButtonSystemImage)
                    .imageScale(.medium)
                Text("목표")
                    .font(.subheadline.weight(.semibold))
            }
        } else {
            Image(systemName: goalsButtonSystemImage)
                .imageScale(.large)
        }
    }

    private var goalsButtonSystemImage: String {
        completedGoalCount == goals.count ? "checkmark.seal.fill" : "target"
    }

    private var completedGoalCount: Int {
        goals.filter { $0.currentValue >= $0.goal.targetValue }.count
    }

    private var goalsToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }

    #if DEBUG
    private var debugToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
        #else
        .topBarLeading
        #endif
    }

    private var debugToolbarContent: some View {
        Menu {
            Button(role: .destructive) {
                Task { await resetAchievementsFromDebugMenu() }
            } label: {
                Label("테스트 계정 업적 초기화", systemImage: "arrow.counterclockwise.circle")
            }
            .disabled(isResettingAchievements)
        } label: {
            Image(systemName: "wrench.and.screwdriver")
                .imageScale(.large)
        }
        .gameCenterGlassButton()
        .accessibilityLabel("Game Center 디버그 메뉴")
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
            resetAchievementsMessage = "Achievements reset"
        } catch {
            resetAchievementsMessage = "Achievement reset failed: \(error)"
        }
    }
    #endif
}

private extension View {
    @ViewBuilder
    func gameCenterRankingNavigationTitle() -> some View {
        #if os(iOS) || os(visionOS)
        navigationTitle("랭킹")
            .navigationBarTitleDisplayMode(.large)
        #else
        navigationTitle("랭킹")
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
