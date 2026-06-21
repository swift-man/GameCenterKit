import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
public typealias GameCenterAuthenticationViewController = UIViewController
#elseif canImport(AppKit)
public typealias GameCenterAuthenticationViewController = NSViewController
#endif

#if canImport(UIKit) || canImport(AppKit)
public typealias GameCenterAuthenticationPresenter = @MainActor @Sendable (GameCenterAuthenticationViewController) async -> Void
#endif

public enum GameCenterClientError: Error, Equatable, Sendable {
    case notAuthenticated
    case authenticationPresentationRequired
    case leaderboardNotConfigured(GameCenterRankingScope)
    case leaderboardNotFound(String)
    case playerNotFound(String)
    case playerPhotoUnavailable(String)
    case challengeNotFound(String)
    case activityNotFound(String)
    case unsupportedPlatform(String)
}

public protocol GameCenterAuthenticationClientProtocol: Sendable {
    @MainActor var isAuthenticated: Bool { get }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    func authenticate(presenting presenter: GameCenterAuthenticationPresenter?) async throws -> GameCenterPlayer
    #endif

    @MainActor
    func localPlayer() async throws -> GameCenterPlayer
}

public protocol GameCenterLeaderboardClientProtocol: Sendable {
    func loadLeaderboard(_ request: GameCenterLeaderboardRequest) async throws -> GameCenterLeaderboardSnapshot
    func submitScore(_ score: Int, leaderboardIDs: [String], context: Int) async throws
}

public protocol GameCenterRecurringLeaderboardClientProtocol: Sendable {
    func loadLeaderboards(IDs: [String]?) async throws -> [GameCenterLeaderboard]
    func loadPreviousOccurrence(leaderboardID: String) async throws -> GameCenterLeaderboard?
}

public protocol GameCenterAchievementClientProtocol: Sendable {
    func loadAchievements() async throws -> [GameCenterAchievementProgress]
    func reportAchievement(_ report: GameCenterAchievementReport) async throws
}

public protocol GameCenterAccessPointClientProtocol: Sendable {
    @MainActor
    func configureAccessPoint(_ configuration: GameCenterAccessPointConfiguration) async

    @MainActor
    func triggerAccessPoint(_ destination: GameCenterAccessPointDestination) async throws
}

public protocol GameCenterFriendsClientProtocol: Sendable {
    func loadFriendsAuthorizationStatus() async throws -> GameCenterFriendsAuthorizationStatus
    func loadFriends() async throws -> [GameCenterPlayer]
    func loadFriends(identifiedBy identifiers: [String]) async throws -> [GameCenterPlayer]

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    func presentFriendRequestCreator() async throws
    #endif
}

public protocol GameCenterPlayerPhotoClientProtocol: Sendable {
    func loadLocalPlayerPhoto(size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto
    func loadFriendPhoto(identifiedBy identifier: String, size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto
}

public protocol GameCenterChallengeClientProtocol: Sendable {
    func loadChallengeDefinitions() async throws -> [GameCenterChallengeDefinition]
    func hasActiveChallenges(challengeDefinitionID: String) async throws -> Bool

    @MainActor
    func triggerChallengeCreation(challengeDefinitionID: String) async throws
}

public protocol GameCenterActivityClientProtocol: Sendable {
    func loadGameActivityDefinitions(IDs: [String]?) async throws -> [GameCenterGameActivityDefinition]
    func hasPendingGameActivities() async -> Bool
    func startGameActivity(definitionID: String, partyCode: String?) async throws -> GameCenterGameActivity
    func updateGameActivityProperties(activityID: String, properties: [String: String]) async throws -> GameCenterGameActivity
    func setScore(_ score: Int, leaderboardID: String, activityID: String, context: Int) async throws
    func setAchievementProgress(_ percentComplete: Double, achievementID: String, activityID: String) async throws
    func setAchievementCompleted(achievementID: String, activityID: String) async throws
    func pauseGameActivity(activityID: String) async throws -> GameCenterGameActivity
    func resumeGameActivity(activityID: String) async throws -> GameCenterGameActivity
    func endGameActivity(activityID: String) async throws -> GameCenterGameActivity
    func setGameActivityHandler(_ handler: (@Sendable (GameCenterPlayer, GameCenterGameActivity) async -> Bool)?) async
}

public protocol GameCenterClientProtocol:
    GameCenterAuthenticationClientProtocol,
    GameCenterLeaderboardClientProtocol,
    GameCenterAchievementClientProtocol
{}

extension GameCenterLeaderboardClientProtocol {
    public func submitScore(_ score: Int, leaderboardID: String, context: Int = 0) async throws {
        try await submitScore(score, leaderboardIDs: [leaderboardID], context: context)
    }
}

extension GameCenterAchievementClientProtocol {
    public func reportAchievement(
        achievementID: String,
        percentComplete: Double,
        showsCompletionBanner: Bool = true
    ) async throws {
        try await reportAchievement(
            GameCenterAchievementReport(
                achievementID: achievementID,
                percentComplete: percentComplete,
                showsCompletionBanner: showsCompletionBanner
            )
        )
    }
}

extension GameCenterPlayerPhotoClientProtocol {
    public func loadLocalPlayerPhoto() async throws -> GameCenterPlayerPhoto {
        try await loadLocalPlayerPhoto(size: .normal)
    }

    public func loadFriendPhoto(identifiedBy identifier: String) async throws -> GameCenterPlayerPhoto {
        try await loadFriendPhoto(identifiedBy: identifier, size: .normal)
    }
}
