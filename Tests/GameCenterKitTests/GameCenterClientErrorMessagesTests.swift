import XCTest
@testable import GameCenterKit

final class GameCenterClientErrorMessagesTests: XCTestCase {
    func testClientErrorProvidesUserFacingMessage() {
        XCTAssertEqual(
            GameCenterClientError.notAuthenticated.userFacingMessage,
            "Game Center 로그인이 필요합니다."
        )
        XCTAssertEqual(
            GameCenterClientError.leaderboardNotConfigured(.weekly).userFacingMessage,
            "주간 랭킹이 설정되지 않았습니다."
        )
        XCTAssertEqual(
            GameCenterClientError.authenticationPresentationRequired.localizedDescription,
            "Game Center 로그인 화면을 표시할 수 없습니다."
        )
    }

    func testDisplayMessagePrefersGameCenterErrorMapping() {
        XCTAssertEqual(
            gameCenterDisplayMessage(for: GameCenterClientError.playerPhotoUnavailable("player-id")),
            "플레이어 사진을 불러올 수 없습니다."
        )
    }
}
