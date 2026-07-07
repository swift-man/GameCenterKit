@preconcurrency import GameKit

#if DEBUG
public func resetGameCenterAchievements() {
    GKAchievement.resetAchievements { error in
        print(error ?? "reset success")
    }
}
#endif
