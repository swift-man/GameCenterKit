import Dependencies
import XCTest
@testable import GameCenterKit

@MainActor
final class GameCenterDashboardViewModelTests: XCTestCase {
    func testNormalizesDeprecatedMonthlySelection() {
        let model = GameCenterDashboardViewModel(
            configuration: GameCenterConfiguration(
                leaderboardIDs: [.allTime: "all-time-id"]
            ),
            selectedScope: .monthly
        )

        XCTAssertEqual(model.selectedScope, .allTime)

        model.selectedScope = .monthly

        XCTAssertEqual(model.selectedScope, .allTime)
    }

    func testNormalizesInvalidLeaderboardCategorySelection() {
        let model = GameCenterDashboardViewModel(
            configuration: GameCenterConfiguration(
                leaderboardCategories: [
                    GameCenterLeaderboardCategory(
                        id: "ipad",
                        title: "iPad 랭킹",
                        leaderboardIDs: [.daily: "ipad-daily-id"]
                    ),
                ]
            ),
            selectedCategoryID: "missing"
        )

        XCTAssertEqual(model.selectedCategoryID, "ipad")

        model.selectedCategoryID = "missing"

        XCTAssertEqual(model.selectedCategoryID, "ipad")
    }

    func testRefreshUsesSelectedLeaderboardCategory() async {
        let configuration = GameCenterConfiguration(
            leaderboardCategories: [
                GameCenterLeaderboardCategory(
                    id: "ipad",
                    title: "iPad 랭킹",
                    leaderboardIDs: [.daily: "ipad-daily-id"]
                ),
                GameCenterLeaderboardCategory(
                    id: "ipad.keyboard",
                    title: "iPad 하드웨어 키보드 랭킹",
                    leaderboardIDs: [.daily: "keyboard-daily-id"]
                ),
            ]
        )
        let request = GameCenterLeaderboardRequest(
            leaderboardID: "keyboard-daily-id",
            rankingScope: .daily
        )
        let snapshot = GameCenterLeaderboardSnapshot(
            request: request,
            entries: []
        )
        let preview = PreviewGameCenterClient(
            snapshots: ["keyboard-daily-id": snapshot]
        )

        await withDependencies {
            $0.gameCenterAuthenticationClient = preview
            $0.gameCenterLeaderboardClient = preview
            $0.gameCenterPlayerPhotoClient = preview
        } operation: {
            let model = GameCenterDashboardViewModel(
                configuration: configuration,
                selectedCategoryID: "ipad.keyboard"
            )

            await model.refresh()

            XCTAssertEqual(model.selectedCategoryID, "ipad.keyboard")
            XCTAssertEqual(model.snapshot?.request.leaderboardID, "keyboard-daily-id")
        }
    }
}
