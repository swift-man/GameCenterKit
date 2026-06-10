import Foundation

public struct PreviewGameCenterClient:
    GameCenterClientProtocol,
    GameCenterRecurringLeaderboardClientProtocol,
    GameCenterAccessPointClientProtocol,
    GameCenterFriendsClientProtocol,
    GameCenterChallengeClientProtocol,
    GameCenterActivityClientProtocol
{
    public var player: GameCenterPlayer
    public var snapshots: [String: GameCenterLeaderboardSnapshot]
    public var achievements: [GameCenterAchievementProgress]
    public var leaderboards: [GameCenterLeaderboard]
    public var friends: [GameCenterPlayer]
    public var challengeDefinitions: [GameCenterChallengeDefinition]
    public var activityDefinitions: [GameCenterGameActivityDefinition]
    public var activities: [String: GameCenterGameActivity]

    public init(
        player: GameCenterPlayer = .preview,
        snapshots: [String: GameCenterLeaderboardSnapshot] = [:],
        achievements: [GameCenterAchievementProgress] = [],
        leaderboards: [GameCenterLeaderboard] = [],
        friends: [GameCenterPlayer] = [],
        challengeDefinitions: [GameCenterChallengeDefinition] = [],
        activityDefinitions: [GameCenterGameActivityDefinition] = [],
        activities: [String: GameCenterGameActivity] = [:]
    ) {
        self.player = player
        self.snapshots = snapshots
        self.achievements = achievements
        self.leaderboards = leaderboards
        self.friends = friends
        self.challengeDefinitions = challengeDefinitions
        self.activityDefinitions = activityDefinitions
        self.activities = activities
    }

    @MainActor
    public var isAuthenticated: Bool {
        player.isAuthenticated
    }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    public func authenticate(presenting presenter: GameCenterAuthenticationPresenter? = nil) async throws -> GameCenterPlayer {
        player
    }
    #endif

    @MainActor
    public func localPlayer() async throws -> GameCenterPlayer {
        player
    }

    public func loadLeaderboard(_ request: GameCenterLeaderboardRequest) async throws -> GameCenterLeaderboardSnapshot {
        if let snapshot = snapshots[request.leaderboardID] {
            return snapshot
        }

        return GameCenterLeaderboardSnapshot(
            request: request,
            localPlayerEntry: GameCenterLeaderboardEntry(
                id: player.gamePlayerID,
                rank: 4,
                score: 820,
                formattedScore: "820",
                displayName: player.displayName,
                gamePlayerID: player.gamePlayerID
            ),
            entries: [
                GameCenterLeaderboardEntry(
                    id: "preview-1",
                    rank: 1,
                    score: 1_240,
                    formattedScore: "1,240",
                    displayName: "Player One",
                    gamePlayerID: "preview-1"
                ),
                GameCenterLeaderboardEntry(
                    id: "preview-2",
                    rank: 2,
                    score: 1_010,
                    formattedScore: "1,010",
                    displayName: "Player Two",
                    gamePlayerID: "preview-2"
                ),
                GameCenterLeaderboardEntry(
                    id: player.gamePlayerID,
                    rank: 4,
                    score: 820,
                    formattedScore: "820",
                    displayName: player.displayName,
                    gamePlayerID: player.gamePlayerID
                ),
            ],
            totalPlayerCount: 42
        )
    }

    public func submitScore(_ score: Int, leaderboardIDs: [String], context: Int = 0) async throws {}

    public func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        achievements
    }

    public func reportAchievement(_ report: GameCenterAchievementReport) async throws {}

    public func loadLeaderboards(IDs: [String]? = nil) async throws -> [GameCenterLeaderboard] {
        guard let IDs else {
            return leaderboards
        }

        return leaderboards.filter { IDs.contains($0.id) }
    }

    public func loadPreviousOccurrence(leaderboardID: String) async throws -> GameCenterLeaderboard? {
        leaderboards.first { $0.id == leaderboardID && $0.kind == .recurring }
    }

    @MainActor
    public func configureAccessPoint(_ configuration: GameCenterAccessPointConfiguration) async {}

    @MainActor
    public func triggerAccessPoint(_ destination: GameCenterAccessPointDestination) async throws {}

    public func loadFriendsAuthorizationStatus() async throws -> GameCenterFriendsAuthorizationStatus {
        .authorized
    }

    public func loadFriends() async throws -> [GameCenterPlayer] {
        friends
    }

    public func loadFriends(identifiedBy identifiers: [String]) async throws -> [GameCenterPlayer] {
        friends.filter { identifiers.contains($0.gamePlayerID) || identifiers.contains($0.teamPlayerID) }
    }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    public func presentFriendRequestCreator() async throws {}
    #endif

    public func loadChallengeDefinitions() async throws -> [GameCenterChallengeDefinition] {
        challengeDefinitions
    }

    public func hasActiveChallenges(challengeDefinitionID: String) async throws -> Bool {
        challengeDefinitions.contains { $0.id == challengeDefinitionID }
    }

    @MainActor
    public func triggerChallengeCreation(challengeDefinitionID: String) async throws {}

    public func loadGameActivityDefinitions(IDs: [String]? = nil) async throws -> [GameCenterGameActivityDefinition] {
        guard let IDs else {
            return activityDefinitions
        }

        return activityDefinitions.filter { IDs.contains($0.id) }
    }

    public func hasPendingGameActivities() async -> Bool {
        false
    }

    public func startGameActivity(definitionID: String, partyCode: String? = nil) async throws -> GameCenterGameActivity {
        if let activity = activities.values.first(where: { $0.definitionID == definitionID }) {
            return activity
        }

        return GameCenterGameActivity(
            id: "preview-activity-\(definitionID)",
            definitionID: definitionID,
            properties: [:],
            state: .active,
            partyCode: partyCode,
            creationDate: Date(),
            startDate: Date()
        )
    }

    public func updateGameActivityProperties(activityID: String, properties: [String: String]) async throws -> GameCenterGameActivity {
        var activity = try previewActivity(id: activityID)
        activity.properties = properties
        return activity
    }

    public func setScore(_ score: Int, leaderboardID: String, activityID: String, context: Int = 0) async throws {}

    public func setAchievementProgress(_ percentComplete: Double, achievementID: String, activityID: String) async throws {}

    public func setAchievementCompleted(achievementID: String, activityID: String) async throws {}

    public func pauseGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        var activity = try previewActivity(id: activityID)
        activity.state = .paused
        return activity
    }

    public func resumeGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        var activity = try previewActivity(id: activityID)
        activity.state = .active
        activity.lastResumeDate = Date()
        return activity
    }

    public func endGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        var activity = try previewActivity(id: activityID)
        activity.state = .ended
        activity.endDate = Date()
        return activity
    }

    public func setGameActivityHandler(_ handler: (@Sendable (GameCenterPlayer, GameCenterGameActivity) async -> Bool)?) async {}
}

public struct UnimplementedGameCenterClient:
    GameCenterClientProtocol,
    GameCenterRecurringLeaderboardClientProtocol,
    GameCenterAccessPointClientProtocol,
    GameCenterFriendsClientProtocol,
    GameCenterChallengeClientProtocol,
    GameCenterActivityClientProtocol
{
    public init() {}

    @MainActor
    public var isAuthenticated: Bool {
        false
    }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    public func authenticate(presenting presenter: GameCenterAuthenticationPresenter? = nil) async throws -> GameCenterPlayer {
        throw GameCenterClientError.notAuthenticated
    }
    #endif

    @MainActor
    public func localPlayer() async throws -> GameCenterPlayer {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadLeaderboard(_ request: GameCenterLeaderboardRequest) async throws -> GameCenterLeaderboardSnapshot {
        throw GameCenterClientError.notAuthenticated
    }

    public func submitScore(_ score: Int, leaderboardIDs: [String], context: Int = 0) async throws {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        throw GameCenterClientError.notAuthenticated
    }

    public func reportAchievement(_ report: GameCenterAchievementReport) async throws {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadLeaderboards(IDs: [String]? = nil) async throws -> [GameCenterLeaderboard] {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadPreviousOccurrence(leaderboardID: String) async throws -> GameCenterLeaderboard? {
        throw GameCenterClientError.notAuthenticated
    }

    @MainActor
    public func configureAccessPoint(_ configuration: GameCenterAccessPointConfiguration) async {}

    @MainActor
    public func triggerAccessPoint(_ destination: GameCenterAccessPointDestination) async throws {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadFriendsAuthorizationStatus() async throws -> GameCenterFriendsAuthorizationStatus {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadFriends() async throws -> [GameCenterPlayer] {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadFriends(identifiedBy identifiers: [String]) async throws -> [GameCenterPlayer] {
        throw GameCenterClientError.notAuthenticated
    }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    public func presentFriendRequestCreator() async throws {
        throw GameCenterClientError.notAuthenticated
    }
    #endif

    public func loadChallengeDefinitions() async throws -> [GameCenterChallengeDefinition] {
        throw GameCenterClientError.notAuthenticated
    }

    public func hasActiveChallenges(challengeDefinitionID: String) async throws -> Bool {
        throw GameCenterClientError.notAuthenticated
    }

    @MainActor
    public func triggerChallengeCreation(challengeDefinitionID: String) async throws {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadGameActivityDefinitions(IDs: [String]? = nil) async throws -> [GameCenterGameActivityDefinition] {
        throw GameCenterClientError.notAuthenticated
    }

    public func hasPendingGameActivities() async -> Bool {
        false
    }

    public func startGameActivity(definitionID: String, partyCode: String? = nil) async throws -> GameCenterGameActivity {
        throw GameCenterClientError.notAuthenticated
    }

    public func updateGameActivityProperties(activityID: String, properties: [String: String]) async throws -> GameCenterGameActivity {
        throw GameCenterClientError.notAuthenticated
    }

    public func setScore(_ score: Int, leaderboardID: String, activityID: String, context: Int = 0) async throws {
        throw GameCenterClientError.notAuthenticated
    }

    public func setAchievementProgress(_ percentComplete: Double, achievementID: String, activityID: String) async throws {
        throw GameCenterClientError.notAuthenticated
    }

    public func setAchievementCompleted(achievementID: String, activityID: String) async throws {
        throw GameCenterClientError.notAuthenticated
    }

    public func pauseGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        throw GameCenterClientError.notAuthenticated
    }

    public func resumeGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        throw GameCenterClientError.notAuthenticated
    }

    public func endGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        throw GameCenterClientError.notAuthenticated
    }

    public func setGameActivityHandler(_ handler: (@Sendable (GameCenterPlayer, GameCenterGameActivity) async -> Bool)?) async {}
}

extension GameCenterPlayer {
    public static let preview = GameCenterPlayer(
        gamePlayerID: "preview-player",
        teamPlayerID: "preview-team-player",
        displayName: "Preview Player",
        isAuthenticated: true
    )
}

private extension PreviewGameCenterClient {
    func previewActivity(id: String) throws -> GameCenterGameActivity {
        guard let activity = activities[id] else {
            throw GameCenterClientError.activityNotFound(id)
        }

        return activity
    }
}
