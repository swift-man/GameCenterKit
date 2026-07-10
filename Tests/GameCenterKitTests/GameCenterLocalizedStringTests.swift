import XCTest
@testable import GameCenterKit

final class GameCenterLocalizedStringTests: XCTestCase {
    private let accessibilityKeys = [
        "accessibility.debug.menu",
        "accessibility.goals.button",
        "accessibility.goals.value",
        "accessibility.leaderboard_row",
        "accessibility.leaderboard_row.current_player",
        "accessibility.nickname.settings",
        "accessibility.profile",
    ]

    func testEveryAccessibilityKeyExistsInSupportedLocalizations() {
        for localization in ["en", "ko"] {
            for key in accessibilityKeys {
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
