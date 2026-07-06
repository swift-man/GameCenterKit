import Foundation

public struct GameCenterConfiguration: Equatable, Sendable {
    public var leaderboardIDs: [GameCenterRankingScope: String]
    public var goalAchievements: [String: String]

    public init(
        leaderboardIDs: [GameCenterRankingScope: String],
        goalAchievements: [String: String] = [:]
    ) {
        self.leaderboardIDs = leaderboardIDs
        self.goalAchievements = goalAchievements
    }

    public func leaderboardID(for scope: GameCenterRankingScope) -> String? {
        switch scope {
        case .allTime:
            return leaderboardIDs[.allTime] ?? leaderboardIDs[.monthly]
        case .monthly:
            return leaderboardIDs[.monthly] ?? leaderboardIDs[.allTime]
        default:
            return leaderboardIDs[scope]
        }
    }

    public func achievementID(for goalID: String) -> String? {
        goalAchievements[goalID]
    }
}

public enum GameCenterRankingScope: String, CaseIterable, Identifiable, Sendable {
    case daily
    case weekly
    case allTime
    /// Compatibility alias for older integrations.
    ///
    /// GameKit does not provide a monthly leaderboard time scope, so this case
    /// is treated as `allTime` and hidden from `allCases`.
    case monthly

    public static var allCases: [GameCenterRankingScope] {
        [.daily, .weekly, .allTime]
    }

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .daily:
            return "일일"
        case .weekly:
            return "주간"
        case .allTime:
            return "전체"
        case .monthly:
            return "전체"
        }
    }
}

public enum GameCenterPlayerScope: String, CaseIterable, Identifiable, Sendable {
    case global
    case friendsOnly

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .global:
            return "전체"
        case .friendsOnly:
            return "친구"
        }
    }
}
