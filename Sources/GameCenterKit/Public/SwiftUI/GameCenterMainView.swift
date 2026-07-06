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

    private let goals: [GameCenterGoalProgressInput]
    private let showsProfileChip: Bool
    private let showsPlayerScopePicker: Bool

    public init(
        configuration: GameCenterConfiguration,
        goals: [GameCenterGoalProgressInput] = [],
        selectedScope: GameCenterRankingScope = .daily,
        playerScope: GameCenterPlayerScope = .global,
        range: Range<Int> = 1..<51,
        showsProfileChip: Bool = true,
        showsPlayerScopePicker: Bool = true
    ) {
        self.goals = goals
        self.showsProfileChip = showsProfileChip
        self.showsPlayerScopePicker = showsPlayerScopePicker
        _model = StateObject(
            wrappedValue: GameCenterDashboardViewModel(
                configuration: configuration,
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
                    GameCenterNicknameView()
                }

                if !goals.isEmpty {
                    sectionHeader("미션")

                    VStack(spacing: 12) {
                        ForEach(goals) { input in
                            GameCenterGoalProgressView(
                                goal: input.goal,
                                currentValue: input.currentValue,
                                reportsAchievementOnCompletion: input.reportsAchievementOnCompletion
                            )
                        }
                    }
                }

                sectionHeader("리더보드")

                GameCenterLeaderboardSection(
                    model: model,
                    showsPlayerScopePicker: showsPlayerScopePicker
                )
            }
            .padding()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
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
