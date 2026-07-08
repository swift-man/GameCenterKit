import Dependencies

enum GameCenterAchievementProgressCacheDependencyKey: DependencyKey {
    static let liveValue = GameCenterAchievementProgressCache.live
    static let previewValue = GameCenterAchievementProgressCache.passthrough
    static let testValue = GameCenterAchievementProgressCache.passthrough
}

extension DependencyValues {
    var gameCenterAchievementProgressCache: GameCenterAchievementProgressCache {
        get { self[GameCenterAchievementProgressCacheDependencyKey.self] }
        set { self[GameCenterAchievementProgressCacheDependencyKey.self] = newValue }
    }
}
