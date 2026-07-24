import Dependencies

extension DependencyValues {
    public var gameCenterClient: any GameCenterClientProtocol {
        get { self[GameCenterClientDependencyKey.self] }
        set { self[GameCenterClientDependencyKey.self] = newValue }
    }

    public var gameCenterAuthenticationClient: any GameCenterAuthenticationClientProtocol {
        get { self[GameCenterAuthenticationClientDependencyKey.self] }
        set { self[GameCenterAuthenticationClientDependencyKey.self] = newValue }
    }

    public var gameCenterLeaderboardClient: any GameCenterLeaderboardClientProtocol {
        get { self[GameCenterLeaderboardClientDependencyKey.self] }
        set { self[GameCenterLeaderboardClientDependencyKey.self] = newValue }
    }

    public var gameCenterRecurringLeaderboardClient: any GameCenterRecurringLeaderboardClientProtocol {
        get { self[GameCenterRecurringLeaderboardClientDependencyKey.self] }
        set { self[GameCenterRecurringLeaderboardClientDependencyKey.self] = newValue }
    }

    public var gameCenterAchievementClient: any GameCenterAchievementClientProtocol {
        get { self[GameCenterAchievementClientDependencyKey.self] }
        set { self[GameCenterAchievementClientDependencyKey.self] = newValue }
    }

    public var gameCenterAchievementFeedbackClient: any GameCenterAchievementFeedbackClientProtocol {
        get { self[GameCenterAchievementFeedbackClientDependencyKey.self] }
        set { self[GameCenterAchievementFeedbackClientDependencyKey.self] = newValue }
    }

    public var gameCenterAccessPointClient: any GameCenterAccessPointClientProtocol {
        get { self[GameCenterAccessPointClientDependencyKey.self] }
        set { self[GameCenterAccessPointClientDependencyKey.self] = newValue }
    }

    public var gameCenterFriendsClient: any GameCenterFriendsClientProtocol {
        get { self[GameCenterFriendsClientDependencyKey.self] }
        set { self[GameCenterFriendsClientDependencyKey.self] = newValue }
    }

    public var gameCenterPlayerPhotoClient: any GameCenterPlayerPhotoClientProtocol {
        get { self[GameCenterPlayerPhotoClientDependencyKey.self] }
        set { self[GameCenterPlayerPhotoClientDependencyKey.self] = newValue }
    }

    public var gameCenterChallengeClient: any GameCenterChallengeClientProtocol {
        get { self[GameCenterChallengeClientDependencyKey.self] }
        set { self[GameCenterChallengeClientDependencyKey.self] = newValue }
    }

    public var gameCenterActivityClient: any GameCenterActivityClientProtocol {
        get { self[GameCenterActivityClientDependencyKey.self] }
        set { self[GameCenterActivityClientDependencyKey.self] = newValue }
    }
}
