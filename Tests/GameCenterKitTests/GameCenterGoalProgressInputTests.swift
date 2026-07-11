import XCTest
@testable import GameCenterKit

final class GameCenterGoalProgressInputTests: XCTestCase {
    func testCompletedGoalCountIncludesValuesAtOrAboveTarget() {
        let goals = [
            makeInput(id: "in-progress", currentValue: 9, targetValue: 10),
            makeInput(id: "completed", currentValue: 10, targetValue: 10),
            makeInput(id: "exceeded", currentValue: 11, targetValue: 10),
        ]

        XCTAssertEqual(goals.gameCenterCompletedGoalCount, 2)
    }

    func testCompletedGoalCountIsZeroForEmptyGoals() {
        let goals: [GameCenterGoalProgressInput] = []

        XCTAssertEqual(goals.gameCenterCompletedGoalCount, 0)
    }

    private func makeInput(
        id: String,
        currentValue: Int,
        targetValue: Int
    ) -> GameCenterGoalProgressInput {
        GameCenterGoalProgressInput(
            goal: GameCenterGoal(
                id: id,
                title: id,
                targetValue: targetValue
            ),
            currentValue: currentValue
        )
    }
}
