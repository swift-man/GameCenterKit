import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public struct GameCenterPlayer: Equatable, Sendable {
    public var gamePlayerID: String
    public var teamPlayerID: String
    public var displayName: String
    public var isAuthenticated: Bool
    public var isUnderage: Bool
    public var isMultiplayerGamingRestricted: Bool
    public var isPersonalizedCommunicationRestricted: Bool

    public init(
        gamePlayerID: String,
        teamPlayerID: String,
        displayName: String,
        isAuthenticated: Bool,
        isUnderage: Bool = false,
        isMultiplayerGamingRestricted: Bool = false,
        isPersonalizedCommunicationRestricted: Bool = false
    ) {
        self.gamePlayerID = gamePlayerID
        self.teamPlayerID = teamPlayerID
        self.displayName = displayName
        self.isAuthenticated = isAuthenticated
        self.isUnderage = isUnderage
        self.isMultiplayerGamingRestricted = isMultiplayerGamingRestricted
        self.isPersonalizedCommunicationRestricted = isPersonalizedCommunicationRestricted
    }
}

public enum GameCenterPlayerPhotoSize: String, CaseIterable, Hashable, Sendable {
    case small
    case normal
}

public struct GameCenterPlayerPhotoRequest: Hashable, Sendable {
    public var playerID: String
    public var size: GameCenterPlayerPhotoSize

    public init(
        playerID: String,
        size: GameCenterPlayerPhotoSize = .normal
    ) {
        self.playerID = playerID
        self.size = size
    }
}

public struct GameCenterPlayerPhoto: Equatable, Sendable {
    public var playerID: String
    public var size: GameCenterPlayerPhotoSize
    public var data: Data

    public init(
        playerID: String,
        size: GameCenterPlayerPhotoSize,
        data: Data
    ) {
        self.playerID = playerID
        self.size = size
        self.data = data
    }
}

#if canImport(UIKit)
extension GameCenterPlayerPhoto {
    public var uiImage: UIImage? {
        UIImage(data: data)
    }
}
#elseif canImport(AppKit)
extension GameCenterPlayerPhoto {
    public var nsImage: NSImage? {
        NSImage(data: data)
    }
}
#endif

public struct GameCenterLeaderboardRequest: Equatable, Sendable {
    public var leaderboardID: String
    public var rankingScope: GameCenterRankingScope
    public var playerScope: GameCenterPlayerScope
    public var range: Range<Int>

    public init(
        leaderboardID: String,
        rankingScope: GameCenterRankingScope,
        playerScope: GameCenterPlayerScope = .global,
        range: Range<Int> = 1..<51
    ) {
        self.leaderboardID = leaderboardID
        self.rankingScope = rankingScope
        self.playerScope = playerScope
        self.range = range
    }
}

public struct GameCenterLeaderboardSnapshot: Equatable, Sendable {
    public var request: GameCenterLeaderboardRequest
    public var localPlayerEntry: GameCenterLeaderboardEntry?
    public var entries: [GameCenterLeaderboardEntry]
    public var totalPlayerCount: Int

    public init(
        request: GameCenterLeaderboardRequest,
        localPlayerEntry: GameCenterLeaderboardEntry? = nil,
        entries: [GameCenterLeaderboardEntry],
        totalPlayerCount: Int = 0
    ) {
        self.request = request
        self.localPlayerEntry = localPlayerEntry
        self.entries = entries
        self.totalPlayerCount = totalPlayerCount
    }
}

public struct GameCenterLeaderboardEntry: Identifiable, Equatable, Sendable {
    public var id: String
    public var rank: Int
    public var score: Int
    public var formattedScore: String
    public var displayName: String
    public var gamePlayerID: String
    public var date: Date?

    public init(
        id: String,
        rank: Int,
        score: Int,
        formattedScore: String,
        displayName: String,
        gamePlayerID: String,
        date: Date? = nil
    ) {
        self.id = id
        self.rank = rank
        self.score = score
        self.formattedScore = formattedScore
        self.displayName = displayName
        self.gamePlayerID = gamePlayerID
        self.date = date
    }
}

public struct GameCenterGoal: Identifiable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var targetValue: Int
    public var achievementID: String?

    public init(
        id: String,
        title: String,
        targetValue: Int,
        achievementID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.targetValue = targetValue
        self.achievementID = achievementID
    }
}

public struct GameCenterAchievementReport: Equatable, Sendable {
    public var achievementID: String
    public var percentComplete: Double
    /// GameKit 시스템 달성 알림을 요청한다. 여러 목표를 개별 보고하면 시스템이 알림을 순서대로 표시한다.
    public var showsCompletionBanner: Bool

    public init(
        achievementID: String,
        percentComplete: Double,
        showsCompletionBanner: Bool = true
    ) {
        self.achievementID = achievementID
        self.percentComplete = percentComplete
        self.showsCompletionBanner = showsCompletionBanner
    }
}

public struct GameCenterAchievementProgress: Identifiable, Equatable, Sendable {
    public var id: String
    public var percentComplete: Double
    public var isCompleted: Bool
    public var lastReportedDate: Date?

    public init(
        id: String,
        percentComplete: Double,
        isCompleted: Bool,
        lastReportedDate: Date? = nil
    ) {
        self.id = id
        self.percentComplete = percentComplete
        self.isCompleted = isCompleted
        self.lastReportedDate = lastReportedDate
    }
}
