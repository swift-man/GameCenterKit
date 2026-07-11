extension Array where Element == GameCenterGoalProgressInput {
    var gameCenterCompletedGoalCount: Int {
        count { $0.currentValue >= $0.goal.targetValue }
    }
}
