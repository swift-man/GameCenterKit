import Dependencies
import XCTest
@testable import GameCenterKit

final class GameCenterDependencyTests: XCTestCase {
    @MainActor
    func testOverridesGameCenterClientThroughDependencyValues() async throws {
        let expectedPlayer = GameCenterPlayer(
            gamePlayerID: "stub-player",
            teamPlayerID: "stub-team",
            displayName: "Stub Player",
            isAuthenticated: true
        )

        let player = try await withDependencies {
            $0.gameCenterClient = StubGameCenterClient(player: expectedPlayer)
        } operation: {
            @Dependency(\.gameCenterClient) var gameCenterClient
            return try await gameCenterClient.localPlayer()
        }

        XCTAssertEqual(player, expectedPlayer)
    }

    func testOverridesCapabilitySpecificDependencies() async throws {
        let expectedFriend = GameCenterPlayer(
            gamePlayerID: "friend-player",
            teamPlayerID: "friend-team",
            displayName: "Friend Player",
            isAuthenticated: false
        )
        let expectedActivityDefinition = GameCenterGameActivityDefinition(
            id: "activity.score-attack",
            title: "Score Attack",
            supportsPartyCode: true,
            playStyle: .synchronous
        )

        let result = try await withDependencies {
            let preview = PreviewGameCenterClient(
                friends: [expectedFriend],
                activityDefinitions: [expectedActivityDefinition]
            )
            $0.gameCenterFriendsClient = preview
            $0.gameCenterActivityClient = preview
        } operation: {
            @Dependency(\.gameCenterFriendsClient) var friendsClient
            @Dependency(\.gameCenterActivityClient) var activityClient

            let friends = try await friendsClient.loadFriends()
            let activities = try await activityClient.loadGameActivityDefinitions(IDs: nil)
            return (friends, activities)
        }

        XCTAssertEqual(result.0, [expectedFriend])
        XCTAssertEqual(result.1, [expectedActivityDefinition])
    }
}

private struct StubGameCenterClient: GameCenterClientProtocol {
    var player: GameCenterPlayer

    @MainActor
    var isAuthenticated: Bool {
        player.isAuthenticated
    }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    func authenticate(presenting presenter: GameCenterAuthenticationPresenter?) async throws -> GameCenterPlayer {
        player
    }
    #endif

    @MainActor
    func localPlayer() async throws -> GameCenterPlayer {
        player
    }

    func loadLeaderboard(_ request: GameCenterLeaderboardRequest) async throws -> GameCenterLeaderboardSnapshot {
        GameCenterLeaderboardSnapshot(request: request, entries: [])
    }

    func submitScore(_ score: Int, leaderboardIDs: [String], context: Int) async throws {}

    func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        []
    }

    func reportAchievement(_ report: GameCenterAchievementReport) async throws {}
}
