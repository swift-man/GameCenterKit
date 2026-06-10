import XCTest
@testable import GameCenterKit

final class GameCenterConfigurationTests: XCTestCase {
    func testLeaderboardLookup() {
        let configuration = GameCenterConfiguration(
            leaderboardIDs: [
                .daily: "daily-id",
                .weekly: "weekly-id",
                .monthly: "monthly-id",
            ],
            goalAchievements: [
                "score-1000": "achievement-id",
            ]
        )

        XCTAssertEqual(configuration.leaderboardID(for: .daily), "daily-id")
        XCTAssertEqual(configuration.leaderboardID(for: .weekly), "weekly-id")
        XCTAssertEqual(configuration.leaderboardID(for: .monthly), "monthly-id")
        XCTAssertEqual(configuration.achievementID(for: "score-1000"), "achievement-id")
        XCTAssertNil(configuration.achievementID(for: "unknown"))
    }
}
