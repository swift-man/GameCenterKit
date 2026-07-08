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

    func testRefreshUsesLocalPlayerWithoutPresentingAuthenticationWhenAlreadyAuthenticated() async {
        let authenticationSpy = DashboardAuthenticationSpy(isAuthenticated: true)
        let preview = PreviewGameCenterClient()

        await withDependencies {
            $0.gameCenterAuthenticationClient = authenticationSpy
            $0.gameCenterLeaderboardClient = preview
            $0.gameCenterPlayerPhotoClient = preview
        } operation: {
            let model = GameCenterDashboardViewModel(
                configuration: GameCenterConfiguration(
                    leaderboardIDs: [.daily: "daily-id"]
                )
            )

            await model.refresh()
            await model.refresh()

            XCTAssertEqual(authenticationSpy.authenticateCallCount, 0)
            XCTAssertEqual(authenticationSpy.localPlayerCallCount, 2)
        }
    }

    func testRefreshRequestsDefaultAuthenticationOnlyOnceWhenUnauthenticated() async {
        let authenticationSpy = DashboardAuthenticationSpy(
            isAuthenticated: false,
            authenticateError: GameCenterClientError.notAuthenticated
        )
        let preview = PreviewGameCenterClient()

        await withDependencies {
            $0.gameCenterAuthenticationClient = authenticationSpy
            $0.gameCenterLeaderboardClient = preview
            $0.gameCenterPlayerPhotoClient = preview
        } operation: {
            let model = GameCenterDashboardViewModel(
                configuration: GameCenterConfiguration(
                    leaderboardIDs: [.daily: "daily-id"]
                )
            )

            await model.refresh()
            await model.refresh()

            XCTAssertEqual(authenticationSpy.authenticateCallCount, 1)
            XCTAssertEqual(authenticationSpy.localPlayerCallCount, 0)
        }
    }
}

@MainActor
private final class DashboardAuthenticationSpy: GameCenterAuthenticationClientProtocol, @unchecked Sendable {
    var isAuthenticated: Bool
    private(set) var authenticateCallCount = 0
    private(set) var localPlayerCallCount = 0

    private let player: GameCenterPlayer
    private let authenticateError: Error?

    init(
        isAuthenticated: Bool,
        player: GameCenterPlayer = .preview,
        authenticateError: Error? = nil
    ) {
        self.isAuthenticated = isAuthenticated
        self.player = player
        self.authenticateError = authenticateError
    }

    #if canImport(UIKit) || canImport(AppKit)
    func authenticate(presenting presenter: GameCenterAuthenticationPresenter?) async throws -> GameCenterPlayer {
        authenticateCallCount += 1

        if let authenticateError {
            throw authenticateError
        }

        return player
    }
    #endif

    func localPlayer() async throws -> GameCenterPlayer {
        localPlayerCallCount += 1

        guard isAuthenticated else {
            throw GameCenterClientError.notAuthenticated
        }

        return player
    }
}
