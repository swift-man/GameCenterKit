import Dependencies
import Foundation
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

    func testOverridesPlayerPhotoDependency() async throws {
        let expectedPhoto = GameCenterPlayerPhoto(
            playerID: GameCenterPlayer.preview.gamePlayerID,
            size: .small,
            data: Data([0x01, 0x02, 0x03])
        )
        let preview = PreviewGameCenterClient(
            playerPhotos: [
                GameCenterPlayerPhotoRequest(
                    playerID: GameCenterPlayer.preview.gamePlayerID,
                    size: .small
                ): expectedPhoto,
            ]
        )

        let photo = try await withDependencies {
            $0.gameCenterPlayerPhotoClient = preview
        } operation: {
            @Dependency(\.gameCenterPlayerPhotoClient) var photoClient
            return try await photoClient.loadLocalPlayerPhoto(size: .small)
        }

        XCTAssertEqual(photo, expectedPhoto)
    }

    func testPreviewLoadsFriendPhotoByTeamPlayerID() async throws {
        let friend = GameCenterPlayer(
            gamePlayerID: "friend-player",
            teamPlayerID: "friend-team",
            displayName: "Friend Player",
            isAuthenticated: false
        )
        let expectedPhoto = GameCenterPlayerPhoto(
            playerID: friend.gamePlayerID,
            size: .normal,
            data: Data([0x04, 0x05, 0x06])
        )
        let client = PreviewGameCenterClient(
            friends: [friend],
            playerPhotos: [
                GameCenterPlayerPhotoRequest(
                    playerID: friend.gamePlayerID,
                    size: .normal
                ): expectedPhoto,
            ]
        )

        let photo = try await client.loadFriendPhoto(identifiedBy: friend.teamPlayerID)

        XCTAssertEqual(photo, expectedPhoto)
    }

    func testPreviewLoadsFriendPhotoByGamePlayerIDFromTeamPlayerPhoto() async throws {
        let friend = GameCenterPlayer(
            gamePlayerID: "friend-player",
            teamPlayerID: "friend-team",
            displayName: "Friend Player",
            isAuthenticated: false
        )
        let expectedPhoto = GameCenterPlayerPhoto(
            playerID: friend.teamPlayerID,
            size: .small,
            data: Data([0x07, 0x08, 0x09])
        )
        let client = PreviewGameCenterClient(
            friends: [friend],
            playerPhotos: [
                GameCenterPlayerPhotoRequest(
                    playerID: friend.teamPlayerID,
                    size: .small
                ): expectedPhoto,
            ]
        )

        let photo = try await client.loadFriendPhoto(identifiedBy: friend.gamePlayerID, size: .small)

        XCTAssertEqual(photo, expectedPhoto)
    }

    func testPreviewActivityLifecycleStoresStartedActivity() async throws {
        let client = PreviewGameCenterClient()

        let started = try await client.startGameActivity(
            definitionID: "activity.score-attack",
            partyCode: "ABCD"
        )
        let updated = try await client.updateGameActivityProperties(
            activityID: started.id,
            properties: ["round": "1"]
        )
        let paused = try await client.pauseGameActivity(activityID: started.id)
        let resumed = try await client.resumeGameActivity(activityID: started.id)
        let ended = try await client.endGameActivity(activityID: started.id)
        let activities = await client.activities

        XCTAssertEqual(updated.id, started.id)
        XCTAssertEqual(updated.properties, ["round": "1"])
        XCTAssertEqual(paused.state, .paused)
        XCTAssertEqual(resumed.state, .active)
        XCTAssertEqual(ended.state, .ended)
        XCTAssertEqual(ended.partyCode, "ABCD")
        XCTAssertEqual(activities[started.id], ended)
    }

    func testOverridesAchievementResetDependency() async throws {
        let preview = PreviewGameCenterClient()

        try await withDependencies {
            $0.gameCenterAchievementClient = preview
        } operation: {
            @Dependency(\.gameCenterAchievementClient) var achievementClient
            try await achievementClient.resetAchievements()
        }
    }

    @MainActor
    func testDashboardRefreshClearsSnapshotOnCurrentFailure() async {
        let request = GameCenterLeaderboardRequest(
            leaderboardID: "daily-id",
            rankingScope: .daily
        )
        let dailySnapshot = GameCenterLeaderboardSnapshot(
            request: request,
            entries: [
                GameCenterLeaderboardEntry(
                    id: "daily-leader",
                    rank: 1,
                    score: 100,
                    formattedScore: "100",
                    displayName: "Daily Leader",
                    gamePlayerID: "daily-leader"
                ),
            ]
        )
        let preview = PreviewGameCenterClient(
            snapshots: ["daily-id": dailySnapshot],
            playerPhotos: [
                GameCenterPlayerPhotoRequest(
                    playerID: GameCenterPlayer.preview.gamePlayerID,
                    size: .small
                ): GameCenterPlayerPhoto(
                    playerID: GameCenterPlayer.preview.gamePlayerID,
                    size: .small,
                    data: Data([0x01, 0x02, 0x03])
                ),
            ]
        )

        await withDependencies {
            $0.gameCenterAuthenticationClient = preview
            $0.gameCenterLeaderboardClient = preview
            $0.gameCenterPlayerPhotoClient = preview
        } operation: {
            let model = GameCenterDashboardViewModel(
                configuration: GameCenterConfiguration(
                    leaderboardIDs: [.daily: "daily-id"]
                )
            )

            await model.refresh()
            XCTAssertEqual(model.player, GameCenterPlayer.preview)
            XCTAssertNotNil(model.playerPhoto)
            XCTAssertEqual(model.snapshot, dailySnapshot)

            model.selectedScope = .weekly
            await model.refresh()

            XCTAssertNil(model.player)
            XCTAssertNil(model.playerPhoto)
            XCTAssertNil(model.snapshot)
            XCTAssertEqual(model.errorMessage, "주간 랭킹이 설정되지 않았습니다.")
        }
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

    func resetAchievements() async throws {}
}
