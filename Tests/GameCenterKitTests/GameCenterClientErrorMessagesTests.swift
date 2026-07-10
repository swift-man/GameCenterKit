import XCTest
@testable import GameCenterKit

final class GameCenterClientErrorMessagesTests: XCTestCase {
    func testClientErrorProvidesLocalizedUserFacingMessage() {
        XCTAssertEqual(
            gameCenterClientErrorMessage(.notAuthenticated, localization: "ko"),
            "Game Center 로그인이 필요합니다."
        )
        XCTAssertEqual(
            gameCenterClientErrorMessage(.leaderboardNotConfigured(.weekly), localization: "en"),
            "Weekly ranking is not configured."
        )
        XCTAssertEqual(
            gameCenterClientErrorMessage(.leaderboardNotConfigured(.weekly), localization: "ko"),
            "주간 랭킹이 설정되지 않았습니다."
        )
    }

    func testLocalizedErrorUsesBundleLocalization() {
        let supportedValues = [
            "Unable to present the Game Center sign-in screen.",
            "Game Center 로그인 화면을 표시할 수 없습니다.",
        ]

        XCTAssertEqual(
            GameCenterClientError.authenticationPresentationRequired.localizedDescription,
            GameCenterClientError.authenticationPresentationRequired.userFacingMessage
        )
        XCTAssertTrue(
            supportedValues.contains(
                GameCenterClientError.authenticationPresentationRequired.userFacingMessage
            )
        )
    }

    func testDisplayMessagePrefersGameCenterErrorMapping() {
        XCTAssertTrue(
            [
                "Unable to load the player photo.",
                "플레이어 사진을 불러올 수 없습니다.",
            ].contains(
                gameCenterDisplayMessage(
                    for: GameCenterClientError.playerPhotoUnavailable("player-id")
                )
            )
        )
    }
}
