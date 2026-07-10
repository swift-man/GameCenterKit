import XCTest
@testable import GameCenterKit

final class GameCenterLocalizedStringTests: XCTestCase {
    private let localizedKeys = [
        "accessibility.debug.menu",
        "accessibility.goals.button",
        "accessibility.goals.value",
        "accessibility.leaderboard_row",
        "accessibility.leaderboard_row.current_player",
        "accessibility.nickname.settings",
        "accessibility.profile",
        "error.activity_not_found",
        "error.authentication_presentation_required",
        "error.challenge_not_found",
        "error.leaderboard_not_configured",
        "error.leaderboard_not_found",
        "error.not_authenticated",
        "error.player_not_found",
        "error.player_photo_unavailable",
        "error.request_failed",
        "error.unsupported_platform",
        "player_scope.friends",
        "player_scope.global",
        "ranking_scope.all_time",
        "ranking_scope.daily",
        "ranking_scope.weekly",
        "ui.action.confirm",
        "ui.debug.achievement_reset",
        "ui.debug.achievement_reset.failure",
        "ui.debug.achievement_reset.success",
        "ui.debug.title",
        "ui.goal.action.completed",
        "ui.goal.action.report",
        "ui.goal.status.completed",
        "ui.goal.status.in_progress",
        "ui.goals.completion_title",
        "ui.goals.title",
        "ui.leaderboard.category",
        "ui.leaderboard.category_picker",
        "ui.leaderboard.current_player_badge",
        "ui.leaderboard.empty",
        "ui.leaderboard.load_failed",
        "ui.leaderboard.player_scope_picker",
        "ui.leaderboard.scope_picker",
        "ui.leaderboard.section_title",
        "ui.leaderboard.title",
        "ui.missions.title",
        "ui.nickname.none",
    ]

    func testEveryLocalizedKeyExistsInSupportedLocalizations() {
        for localization in ["en", "ko"] {
            for key in localizedKeys {
                XCTAssertNotEqual(
                    GameCenterLocalizedString.string(key, localization: localization),
                    key,
                    "Missing \(key) in \(localization) localization"
                )
            }
        }
    }

    func testAccessibilityStringsLoadByLocalization() {
        XCTAssertEqual(
            GameCenterLocalizedString.string(
                "accessibility.goals.button",
                localization: "en"
            ),
            "Goal completion"
        )
        XCTAssertEqual(
            GameCenterLocalizedString.string(
                "accessibility.goals.button",
                localization: "ko"
            ),
            "목표 달성"
        )
    }

    func testScopeTitlesLoadByLocalization() {
        XCTAssertEqual(gameCenterRankingScopeTitle(.daily, localization: "en"), "Daily")
        XCTAssertEqual(gameCenterRankingScopeTitle(.weekly, localization: "ko"), "주간")
        XCTAssertEqual(gameCenterRankingScopeTitle(.monthly, localization: "en"), "All Time")
        XCTAssertEqual(gameCenterPlayerScopeTitle(.global, localization: "en"), "Global")
        XCTAssertEqual(gameCenterPlayerScopeTitle(.friendsOnly, localization: "ko"), "친구")
    }

    func testAccessibilityStringsUseBundleFallbackLocalization() {
        let supportedValues = ["Game Center profile", "Game Center 프로필"]

        XCTAssertTrue(
            supportedValues.contains(
                GameCenterLocalizedString.string("accessibility.profile")
            )
        )
        XCTAssertTrue(
            supportedValues.contains(
                GameCenterLocalizedString.string(
                    "accessibility.profile",
                    localization: "unsupported"
                )
            )
        )
    }

    func testAccessibilityFormatStringsLoadByLocalization() {
        XCTAssertEqual(
            GameCenterLocalizedString.format(
                "accessibility.goals.value",
                localization: "en",
                2,
                5
            ),
            "2 of 5 goals completed"
        )
        XCTAssertEqual(
            GameCenterLocalizedString.format(
                "accessibility.goals.value",
                localization: "ko",
                2,
                5
            ),
            "목표 5개 중 2개 완료"
        )
        XCTAssertEqual(
            GameCenterLocalizedString.format(
                "accessibility.leaderboard_row",
                localization: "en",
                2,
                "Player",
                "500"
            ),
            "Rank 2, Player, 500 points"
        )
        XCTAssertEqual(
            GameCenterLocalizedString.format(
                "accessibility.leaderboard_row",
                localization: "ko",
                2,
                "Player",
                "500"
            ),
            "2위, Player, 500점"
        )
        XCTAssertEqual(
            GameCenterLocalizedString.format(
                "accessibility.leaderboard_row.current_player",
                localization: "en",
                1,
                "Player",
                "1,000"
            ),
            "Rank 1, current player, Player, 1,000 points"
        )
        XCTAssertEqual(
            GameCenterLocalizedString.format(
                "accessibility.leaderboard_row.current_player",
                localization: "ko",
                1,
                "Player",
                "1,000"
            ),
            "1위, 나, Player, 1,000점"
        )
    }
}
