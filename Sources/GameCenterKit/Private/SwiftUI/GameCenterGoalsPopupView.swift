import MaterialDesignColorSwiftUI
import SwiftUI

struct GameCenterGoalsPopupView: View {
    let goals: [GameCenterGoalProgressInput]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        ]

    @Environment(\.materialTheme) private var materialTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(goals) { input in
                        GameCenterGoalProgressView(
                            goal: input.goal,
                            currentValue: input.currentValue,
                            reportsAchievementOnCompletion: input.reportsAchievementOnCompletion,
                            style: .square
                        )
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .padding(16)
        .frame(minWidth: 320, idealWidth: 380, maxWidth: 520, minHeight: 360, idealHeight: 480)
        .background(materialTheme.colorScheme.surface.color)
    }

    private var header: some View {
        let scheme = materialTheme.colorScheme

        return HStack(spacing: 12) {
            Label("목표 달성", systemImage: "target")
                .font(.headline.weight(.semibold))
                .foregroundStyle(scheme.onSurface.color)
                .labelStyle(.titleAndIcon)

            Spacer()

            Text("\(completedGoalCount)/\(goals.count)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(scheme.onSurfaceVariant.color)
                .gameCenterNumericTransition()
                .animation(.default, value: completedGoalCount)
        }
        .padding(14)
        .gameCenterGlassCard(cornerRadius: 20)
    }

    private var completedGoalCount: Int {
        goals.filter { $0.currentValue >= $0.goal.targetValue }.count
    }
}
