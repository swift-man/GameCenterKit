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
        leaderboardIDs[scope]
    }

    public func achievementID(for goalID: String) -> String? {
        goalAchievements[goalID]
    }
}

public enum GameCenterRankingScope: String, CaseIterable, Identifiable, Sendable {
    case daily
    case weekly
    case monthly

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .daily:
            return "일일"
        case .weekly:
            return "주간"
        case .monthly:
            return "월간"
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
