import Foundation

public struct PreviewGameCenterClient:
    GameCenterClientProtocol,
    GameCenterRecurringLeaderboardClientProtocol,
    GameCenterAccessPointClientProtocol,
    GameCenterFriendsClientProtocol,
    GameCenterPlayerPhotoClientProtocol,
    GameCenterChallengeClientProtocol,
    GameCenterActivityClientProtocol
{
    public var player: GameCenterPlayer
    public var snapshots: [String: GameCenterLeaderboardSnapshot]
    public var achievements: [GameCenterAchievementProgress]
    public var leaderboards: [GameCenterLeaderboard]
    public var friends: [GameCenterPlayer]
    public var playerPhotos: [GameCenterPlayerPhotoRequest: GameCenterPlayerPhoto]
    public var challengeDefinitions: [GameCenterChallengeDefinition]
    public var activityDefinitions: [GameCenterGameActivityDefinition]
    private let activityStore: PreviewGameCenterActivityStore

    public var activities: [String: GameCenterGameActivity] {
        get async {
            await activityStore.snapshot()
        }
    }

    public init(
        player: GameCenterPlayer = .preview,
        snapshots: [String: GameCenterLeaderboardSnapshot] = [:],
        achievements: [GameCenterAchievementProgress] = [],
        leaderboards: [GameCenterLeaderboard] = [],
        friends: [GameCenterPlayer] = [],
        playerPhotos: [GameCenterPlayerPhotoRequest: GameCenterPlayerPhoto] = [:],
        challengeDefinitions: [GameCenterChallengeDefinition] = [],
        activityDefinitions: [GameCenterGameActivityDefinition] = [],
        activities: [String: GameCenterGameActivity] = [:]
    ) {
        self.player = player
        self.snapshots = snapshots
        self.achievements = achievements
        self.leaderboards = leaderboards
        self.friends = friends
        self.playerPhotos = playerPhotos
        self.challengeDefinitions = challengeDefinitions
        self.activityDefinitions = activityDefinitions
        self.activityStore = PreviewGameCenterActivityStore(activities: activities)
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

    public func resetAchievements() async throws {}

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

    public func loadLocalPlayerPhoto(size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto {
        try playerPhoto(playerID: player.gamePlayerID, size: size)
    }

    public func loadFriendPhoto(identifiedBy identifier: String, size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto {
        if let photo = playerPhotoIfAvailable(playerID: identifier, size: size) {
            return photo
        }

        guard let friend = friends.first(where: { $0.gamePlayerID == identifier || $0.teamPlayerID == identifier }) else {
            throw GameCenterClientError.playerNotFound(identifier)
        }

        if let photo = playerPhotoIfAvailable(playerID: friend.gamePlayerID, size: size) {
            return photo
        }

        if let photo = playerPhotoIfAvailable(playerID: friend.teamPlayerID, size: size) {
            return photo
        }

        throw GameCenterClientError.playerPhotoUnavailable(friend.gamePlayerID)
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
        if let activity = await activityStore.activity(definitionID: definitionID) {
            return activity
        }

        let activity = GameCenterGameActivity(
            id: "preview-activity-\(definitionID)",
            definitionID: definitionID,
            properties: [:],
            state: .active,
            partyCode: partyCode,
            creationDate: Date(),
            startDate: Date()
        )
        await activityStore.store(activity)
        return activity
    }

    public func updateGameActivityProperties(activityID: String, properties: [String: String]) async throws -> GameCenterGameActivity {
        try await activityStore.updateProperties(id: activityID, properties: properties)
    }

    public func setScore(_ score: Int, leaderboardID: String, activityID: String, context: Int = 0) async throws {
        _ = try await activityStore.activity(id: activityID)
    }

    public func setAchievementProgress(_ percentComplete: Double, achievementID: String, activityID: String) async throws {
        _ = try await activityStore.activity(id: activityID)
    }

    public func setAchievementCompleted(achievementID: String, activityID: String) async throws {
        _ = try await activityStore.activity(id: activityID)
    }

    public func pauseGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        try await activityStore.pause(id: activityID)
    }

    public func resumeGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        try await activityStore.resume(id: activityID)
    }

    public func endGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        try await activityStore.end(id: activityID)
    }

    public func setGameActivityHandler(_ handler: (@Sendable (GameCenterPlayer, GameCenterGameActivity) async -> Bool)?) async {}

    private func playerPhoto(playerID: String, size: GameCenterPlayerPhotoSize) throws -> GameCenterPlayerPhoto {
        guard let photo = playerPhotoIfAvailable(playerID: playerID, size: size) else {
            throw GameCenterClientError.playerPhotoUnavailable(playerID)
        }

        return photo
    }

    private func playerPhotoIfAvailable(playerID: String, size: GameCenterPlayerPhotoSize) -> GameCenterPlayerPhoto? {
        let request = GameCenterPlayerPhotoRequest(playerID: playerID, size: size)
        return playerPhotos[request]
    }
}

public struct UnimplementedGameCenterClient:
    GameCenterClientProtocol,
    GameCenterRecurringLeaderboardClientProtocol,
    GameCenterAccessPointClientProtocol,
    GameCenterFriendsClientProtocol,
    GameCenterPlayerPhotoClientProtocol,
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

    public func resetAchievements() async throws {
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

    public func loadLocalPlayerPhoto(size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto {
        throw GameCenterClientError.notAuthenticated
    }

    public func loadFriendPhoto(identifiedBy identifier: String, size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto {
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

private actor PreviewGameCenterActivityStore {
    private var activities: [String: GameCenterGameActivity]

    init(activities: [String: GameCenterGameActivity]) {
        self.activities = activities
    }

    func activity(id: String) throws -> GameCenterGameActivity {
        guard let activity = activities[id] else {
            throw GameCenterClientError.activityNotFound(id)
        }

        return activity
    }

    func activity(definitionID: String) -> GameCenterGameActivity? {
        activities.values.first { $0.definitionID == definitionID }
    }

    func snapshot() -> [String: GameCenterGameActivity] {
        activities
    }

    func store(_ activity: GameCenterGameActivity) {
        activities[activity.id] = activity
    }

    func updateProperties(id: String, properties: [String: String]) throws -> GameCenterGameActivity {
        var activity = try activity(id: id)
        activity.properties = properties
        activities[id] = activity
        return activity
    }

    func pause(id: String) throws -> GameCenterGameActivity {
        var activity = try activity(id: id)
        activity.state = .paused
        activities[id] = activity
        return activity
    }

    func resume(id: String) throws -> GameCenterGameActivity {
        var activity = try activity(id: id)
        activity.state = .active
        activity.lastResumeDate = Date()
        activities[id] = activity
        return activity
    }

    func end(id: String) throws -> GameCenterGameActivity {
        var activity = try activity(id: id)
        activity.state = .ended
        activity.endDate = Date()
        activities[id] = activity
        return activity
    }
}
