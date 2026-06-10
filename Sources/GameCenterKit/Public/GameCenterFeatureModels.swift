import Foundation

public enum GameCenterLeaderboardKind: String, Equatable, Sendable {
    case classic
    case recurring
    case unknown
}

public struct GameCenterLeaderboard: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String?
    public var groupIdentifier: String?
    public var kind: GameCenterLeaderboardKind
    public var startDate: Date?
    public var nextStartDate: Date?
    public var duration: TimeInterval
    public var details: String?
    public var releaseState: GameCenterReleaseState?
    public var activityIdentifier: String?
    public var activityProperties: [String: String]
    public var isHidden: Bool?

    public init(
        id: String,
        title: String? = nil,
        groupIdentifier: String? = nil,
        kind: GameCenterLeaderboardKind = .unknown,
        startDate: Date? = nil,
        nextStartDate: Date? = nil,
        duration: TimeInterval = 0,
        details: String? = nil,
        releaseState: GameCenterReleaseState? = nil,
        activityIdentifier: String? = nil,
        activityProperties: [String: String] = [:],
        isHidden: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.groupIdentifier = groupIdentifier
        self.kind = kind
        self.startDate = startDate
        self.nextStartDate = nextStartDate
        self.duration = duration
        self.details = details
        self.releaseState = releaseState
        self.activityIdentifier = activityIdentifier
        self.activityProperties = activityProperties
        self.isHidden = isHidden
    }
}

public enum GameCenterReleaseState: String, Equatable, Sendable {
    case unknown
    case released
    case prereleased
}

public enum GameCenterAccessPointLocation: String, Equatable, Sendable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}

public struct GameCenterAccessPointConfiguration: Equatable, Sendable {
    public var isActive: Bool
    public var location: GameCenterAccessPointLocation

    public init(
        isActive: Bool,
        location: GameCenterAccessPointLocation = .topLeading
    ) {
        self.isActive = isActive
        self.location = location
    }
}

public enum GameCenterAccessPointDestination: Equatable, Sendable {
    case dashboard
    case profile
    case achievements
    case leaderboards
    case leaderboard(id: String, playerScope: GameCenterPlayerScope = .global, rankingScope: GameCenterRankingScope = .daily)
    case achievement(id: String)
    case leaderboardSet(id: String)
    case playTogether
    case challenges
    case challengeDefinition(id: String)
    case gameActivityDefinition(id: String)
    case friending
}

public enum GameCenterFriendsAuthorizationStatus: String, Equatable, Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized
    case unknown
}

public struct GameCenterChallengeDefinition: Identifiable, Equatable, Sendable {
    public var id: String
    public var groupIdentifier: String?
    public var title: String
    public var details: String?
    public var durationOptions: [DateComponents]
    public var isRepeatable: Bool
    public var leaderboardID: String?
    public var releaseState: GameCenterReleaseState

    public init(
        id: String,
        groupIdentifier: String? = nil,
        title: String,
        details: String? = nil,
        durationOptions: [DateComponents] = [],
        isRepeatable: Bool,
        leaderboardID: String? = nil,
        releaseState: GameCenterReleaseState = .unknown
    ) {
        self.id = id
        self.groupIdentifier = groupIdentifier
        self.title = title
        self.details = details
        self.durationOptions = durationOptions
        self.isRepeatable = isRepeatable
        self.leaderboardID = leaderboardID
        self.releaseState = releaseState
    }
}

public enum GameCenterGameActivityPlayStyle: String, Equatable, Sendable {
    case unspecified
    case synchronous
    case asynchronous
}

public enum GameCenterGameActivityState: String, Equatable, Sendable {
    case initialized
    case active
    case paused
    case ended
    case unknown
}

public struct GameCenterGameActivityDefinition: Identifiable, Equatable, Sendable {
    public var id: String
    public var groupIdentifier: String?
    public var title: String
    public var details: String?
    public var defaultProperties: [String: String]
    public var fallbackURL: URL?
    public var supportsPartyCode: Bool
    public var supportsUnlimitedPlayers: Bool
    public var playStyle: GameCenterGameActivityPlayStyle
    public var releaseState: GameCenterReleaseState

    public init(
        id: String,
        groupIdentifier: String? = nil,
        title: String,
        details: String? = nil,
        defaultProperties: [String: String] = [:],
        fallbackURL: URL? = nil,
        supportsPartyCode: Bool = false,
        supportsUnlimitedPlayers: Bool = false,
        playStyle: GameCenterGameActivityPlayStyle = .unspecified,
        releaseState: GameCenterReleaseState = .unknown
    ) {
        self.id = id
        self.groupIdentifier = groupIdentifier
        self.title = title
        self.details = details
        self.defaultProperties = defaultProperties
        self.fallbackURL = fallbackURL
        self.supportsPartyCode = supportsPartyCode
        self.supportsUnlimitedPlayers = supportsUnlimitedPlayers
        self.playStyle = playStyle
        self.releaseState = releaseState
    }
}

public struct GameCenterGameActivity: Identifiable, Equatable, Sendable {
    public var id: String
    public var definitionID: String
    public var properties: [String: String]
    public var state: GameCenterGameActivityState
    public var partyCode: String?
    public var partyURL: URL?
    public var creationDate: Date
    public var startDate: Date?
    public var lastResumeDate: Date?
    public var endDate: Date?
    public var duration: TimeInterval

    public init(
        id: String,
        definitionID: String,
        properties: [String: String] = [:],
        state: GameCenterGameActivityState = .unknown,
        partyCode: String? = nil,
        partyURL: URL? = nil,
        creationDate: Date,
        startDate: Date? = nil,
        lastResumeDate: Date? = nil,
        endDate: Date? = nil,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.definitionID = definitionID
        self.properties = properties
        self.state = state
        self.partyCode = partyCode
        self.partyURL = partyURL
        self.creationDate = creationDate
        self.startDate = startDate
        self.lastResumeDate = lastResumeDate
        self.endDate = endDate
        self.duration = duration
    }
}
