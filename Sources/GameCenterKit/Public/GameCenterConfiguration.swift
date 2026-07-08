import Foundation

public struct GameCenterLeaderboardCategory: Identifiable, Equatable, Sendable {
    static let defaultID = "default"
    static let defaultTitle = "랭킹"

    public var id: String
    public var title: String
    public var leaderboardIDs: [GameCenterRankingScope: String]

    public init(
        id: String,
        title: String,
        leaderboardIDs: [GameCenterRankingScope: String]
    ) {
        self.id = id
        self.title = title
        self.leaderboardIDs = leaderboardIDs
    }

    public func leaderboardID(for scope: GameCenterRankingScope) -> String? {
        switch scope {
        case .allTime:
            return leaderboardIDs[.allTime] ?? leaderboardIDs[.monthly]
        case .monthly:
            return leaderboardIDs[.monthly] ?? leaderboardIDs[.allTime]
        case .daily, .weekly:
            return leaderboardIDs[scope]
        }
    }
}

public struct GameCenterConfiguration: Equatable, Sendable {
    public var leaderboardCategories: [GameCenterLeaderboardCategory] {
        didSet {
            if leaderboardCategories.isEmpty {
                leaderboardCategories = [Self.defaultLeaderboardCategory(leaderboardIDs: [:])]
            }
        }
    }
    public var goalAchievements: [String: String]

    public var leaderboardIDs: [GameCenterRankingScope: String] {
        get {
            leaderboardCategories.first?.leaderboardIDs ?? [:]
        }
        set {
            if leaderboardCategories.isEmpty {
                leaderboardCategories = [
                    GameCenterLeaderboardCategory(
                        id: GameCenterLeaderboardCategory.defaultID,
                        title: GameCenterLeaderboardCategory.defaultTitle,
                        leaderboardIDs: newValue
                    ),
                ]
            } else {
                leaderboardCategories[0].leaderboardIDs = newValue
            }
        }
    }

    public init(
        leaderboardIDs: [GameCenterRankingScope: String],
        goalAchievements: [String: String] = [:]
    ) {
        self.leaderboardCategories = [
            Self.defaultLeaderboardCategory(leaderboardIDs: leaderboardIDs),
        ]
        self.goalAchievements = goalAchievements
    }

    public init(
        leaderboardCategories: [GameCenterLeaderboardCategory],
        goalAchievements: [String: String] = [:]
    ) {
        self.leaderboardCategories = Self.normalizedLeaderboardCategories(leaderboardCategories)
        self.goalAchievements = goalAchievements
    }

    public func leaderboardID(for scope: GameCenterRankingScope) -> String? {
        leaderboardID(for: scope, categoryID: nil)
    }

    public func leaderboardID(for scope: GameCenterRankingScope, categoryID: String?) -> String? {
        leaderboardCategory(id: categoryID)?.leaderboardID(for: scope)
    }

    public func leaderboardCategory(id: String?) -> GameCenterLeaderboardCategory? {
        guard let id, !id.isEmpty else {
            return leaderboardCategories.first
        }

        return leaderboardCategories.first { $0.id == id }
    }

    public func achievementID(for goalID: String) -> String? {
        goalAchievements[goalID]
    }

    private static func normalizedLeaderboardCategories(
        _ leaderboardCategories: [GameCenterLeaderboardCategory]
    ) -> [GameCenterLeaderboardCategory] {
        if leaderboardCategories.isEmpty {
            return [defaultLeaderboardCategory(leaderboardIDs: [:])]
        }

        return leaderboardCategories
    }

    private static func defaultLeaderboardCategory(
        leaderboardIDs: [GameCenterRankingScope: String]
    ) -> GameCenterLeaderboardCategory {
        GameCenterLeaderboardCategory(
            id: GameCenterLeaderboardCategory.defaultID,
            title: GameCenterLeaderboardCategory.defaultTitle,
            leaderboardIDs: leaderboardIDs
        )
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
