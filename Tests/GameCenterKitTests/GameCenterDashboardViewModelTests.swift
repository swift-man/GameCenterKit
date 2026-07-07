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
}
