@preconcurrency import GameKit

#if DEBUG
public func resetGameCenterAchievements() {
    Task {
        do {
            try await GKAchievement.resetAchievements()
            print("reset success")
        } catch {
            print(error)
        }
    }
}
#endif
