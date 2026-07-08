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

    func testLeaderboardCategoryLookup() {
        let configuration = GameCenterConfiguration(
            leaderboardCategories: [
                GameCenterLeaderboardCategory(
                    id: "ipad",
                    title: "iPad 랭킹",
                    leaderboardIDs: [
                        .daily: "ipad-daily-id",
                        .allTime: "ipad-all-time-id",
                    ]
                ),
                GameCenterLeaderboardCategory(
                    id: "ipad.keyboard",
                    title: "iPad 하드웨어 키보드 랭킹",
                    leaderboardIDs: [
                        .daily: "keyboard-daily-id",
                        .weekly: "keyboard-weekly-id",
                    ]
                ),
            ]
        )

        XCTAssertEqual(configuration.leaderboardID(for: .daily, categoryID: "ipad"), "ipad-daily-id")
        XCTAssertEqual(configuration.leaderboardID(for: .monthly, categoryID: "ipad"), "ipad-all-time-id")
        XCTAssertEqual(configuration.leaderboardID(for: .daily, categoryID: "ipad.keyboard"), "keyboard-daily-id")
        XCTAssertEqual(configuration.leaderboardID(for: .weekly, categoryID: "ipad.keyboard"), "keyboard-weekly-id")
        XCTAssertNil(configuration.leaderboardID(for: .allTime, categoryID: "ipad.keyboard"))
        XCTAssertNil(configuration.leaderboardID(for: .daily, categoryID: "missing"))
    }

    func testEmptyLeaderboardCategoriesNormalizeToDefaultCategory() {
        var configuration = GameCenterConfiguration(leaderboardCategories: [])

        XCTAssertEqual(configuration.leaderboardCategories.count, 1)
        XCTAssertEqual(configuration.leaderboardCategories[0].id, GameCenterLeaderboardCategory.defaultID)
        XCTAssertEqual(configuration.leaderboardCategories[0].title, GameCenterLeaderboardCategory.defaultTitle)
        XCTAssertNil(configuration.leaderboardID(for: .daily))

        configuration.leaderboardCategories = []

        XCTAssertEqual(configuration.leaderboardCategories.count, 1)
        XCTAssertEqual(configuration.leaderboardCategories[0].id, GameCenterLeaderboardCategory.defaultID)
    }

    func testRankingScopeAllCasesExcludesDeprecatedMonthlyScope() {
        XCTAssertEqual(GameCenterRankingScope.allCases, [.daily, .weekly, .allTime])
    }
}
