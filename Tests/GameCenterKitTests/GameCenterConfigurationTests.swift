import XCTest
@testable import GameCenterKit

final class GameCenterConfigurationTests: XCTestCase {
    func testLeaderboardLookup() {
        let configuration = GameCenterConfiguration(
            leaderboardIDs: [
                .daily: "daily-id",
                .weekly: "weekly-id",
                .allTime: "all-time-id",
            ],
            goalAchievements: [
                "score-1000": "achievement-id",
            ]
        )

        XCTAssertEqual(configuration.leaderboardID(for: .daily), "daily-id")
        XCTAssertEqual(configuration.leaderboardID(for: .weekly), "weekly-id")
        XCTAssertEqual(configuration.leaderboardID(for: .allTime), "all-time-id")
        XCTAssertEqual(configuration.leaderboardID(for: .monthly), "all-time-id")
        XCTAssertEqual(configuration.achievementID(for: "score-1000"), "achievement-id")
        XCTAssertNil(configuration.achievementID(for: "unknown"))
    }

    func testAllTimeFallsBackToDeprecatedMonthlyLeaderboardID() {
        let configuration = GameCenterConfiguration(
            leaderboardIDs: [
                .monthly: "legacy-monthly-id",
            ]
        )

        XCTAssertEqual(configuration.leaderboardID(for: .allTime), "legacy-monthly-id")
    }

    func testRankingScopeAllCasesExcludesDeprecatedMonthlyScope() {
        XCTAssertEqual(GameCenterRankingScope.allCases, [.daily, .weekly, .allTime])
    }
}
