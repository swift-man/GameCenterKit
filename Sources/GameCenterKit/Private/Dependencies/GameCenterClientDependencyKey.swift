import Dependencies

enum GameCenterClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterAuthenticationClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterAuthenticationClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterAuthenticationClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterAuthenticationClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterLeaderboardClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterLeaderboardClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterLeaderboardClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterLeaderboardClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterRecurringLeaderboardClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterRecurringLeaderboardClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterRecurringLeaderboardClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterRecurringLeaderboardClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterAchievementClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterAchievementClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterAchievementClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterAchievementClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterAccessPointClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterAccessPointClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterAccessPointClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterAccessPointClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterFriendsClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterFriendsClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterFriendsClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterFriendsClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterChallengeClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterChallengeClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterChallengeClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterChallengeClientProtocol = UnimplementedGameCenterClient()
}

enum GameCenterActivityClientDependencyKey: DependencyKey {
    static let liveValue: any GameCenterActivityClientProtocol = LiveGameCenterClient()
    static let previewValue: any GameCenterActivityClientProtocol = PreviewGameCenterClient()
    static let testValue: any GameCenterActivityClientProtocol = UnimplementedGameCenterClient()
}
