import Foundation
@preconcurrency import GameKit

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

struct LiveGameCenterClient:
    GameCenterClientProtocol,
    GameCenterRecurringLeaderboardClientProtocol,
    GameCenterAccessPointClientProtocol,
    GameCenterFriendsClientProtocol,
    GameCenterPlayerPhotoClientProtocol,
    GameCenterChallengeClientProtocol,
    GameCenterActivityClientProtocol
{
    init() {}

    @MainActor
    var isAuthenticated: Bool {
        GKLocalPlayer.local.isAuthenticated
    }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    func authenticate(presenting presenter: GameCenterAuthenticationPresenter? = nil) async throws -> GameCenterPlayer {
        try await LiveGameCenterAuthenticationCoordinator.shared.authenticate(presenting: presenter)
    }
    #endif

    @MainActor
    func localPlayer() async throws -> GameCenterPlayer {
        guard GKLocalPlayer.local.isAuthenticated else {
            throw GameCenterClientError.notAuthenticated
        }

        return GameCenterPlayer(localPlayer: GKLocalPlayer.local)
    }

    func loadLeaderboard(_ request: GameCenterLeaderboardRequest) async throws -> GameCenterLeaderboardSnapshot {
        let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [request.leaderboardID])
        guard let leaderboard = leaderboards.first else {
            throw GameCenterClientError.leaderboardNotFound(request.leaderboardID)
        }

        let result = try await leaderboard.loadEntries(
            for: request.playerScope.gameKitPlayerScope,
            timeScope: request.rankingScope.gameKitTimeScope,
            range: request.nsRange
        )
        let (localPlayerEntry, entries, totalPlayerCount) = result

        return GameCenterLeaderboardSnapshot(
            request: request,
            localPlayerEntry: localPlayerEntry.map(GameCenterLeaderboardEntry.init(entry:)),
            entries: entries.map(GameCenterLeaderboardEntry.init(entry:)),
            totalPlayerCount: totalPlayerCount
        )
    }

    func submitScore(_ score: Int, leaderboardIDs: [String], context: Int = 0) async throws {
        try await GKLeaderboard.submitScore(
            score,
            context: context,
            player: GKLocalPlayer.local,
            leaderboardIDs: leaderboardIDs
        )
    }

    func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        let achievements = try await GKAchievement.loadAchievements()
        return achievements.map(GameCenterAchievementProgress.init(achievement:))
    }

    func reportAchievement(_ report: GameCenterAchievementReport) async throws {
        let achievement = GKAchievement(identifier: report.achievementID)
        achievement.percentComplete = min(max(report.percentComplete, 0), 100)
        achievement.showsCompletionBanner = report.showsCompletionBanner
        try await GKAchievement.report([achievement])
    }

    func loadLeaderboards(IDs: [String]? = nil) async throws -> [GameCenterLeaderboard] {
        let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: IDs)
        return leaderboards.map(GameCenterLeaderboard.init(leaderboard:))
    }

    func loadPreviousOccurrence(leaderboardID: String) async throws -> GameCenterLeaderboard? {
        let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
        guard let leaderboard = leaderboards.first else {
            throw GameCenterClientError.leaderboardNotFound(leaderboardID)
        }

        return try await leaderboard.loadPreviousOccurrence().map(GameCenterLeaderboard.init(leaderboard:))
    }

    @MainActor
    func configureAccessPoint(_ configuration: GameCenterAccessPointConfiguration) async {
        GKAccessPoint.shared.isActive = configuration.isActive
        GKAccessPoint.shared.location = configuration.location.gameKitLocation
    }

    @MainActor
    func triggerAccessPoint(_ destination: GameCenterAccessPointDestination) async throws {
        switch destination {
        case .dashboard:
            await triggerAccessPoint()
        case .profile:
            await triggerAccessPoint(state: .localPlayerProfile)
        case .achievements:
            await triggerAccessPoint(state: .achievements)
        case .leaderboards:
            await triggerAccessPoint(state: .leaderboards)
        case let .leaderboard(id, playerScope, rankingScope):
            guard #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point leaderboard deep link requires iOS 18, macOS 15, or visionOS 2.")
            }

            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.trigger(
                    leaderboardID: id,
                    playerScope: playerScope.gameKitPlayerScope,
                    timeScope: rankingScope.gameKitTimeScope
                ) {
                    continuation.resume()
                }
            }
        case let .achievement(id):
            guard #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point achievement deep link requires iOS 18, macOS 15, or visionOS 2.")
            }

            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.trigger(achievementID: id) {
                    continuation.resume()
                }
            }
        case let .leaderboardSet(id):
            guard #available(iOS 18.0, macOS 15.0, visionOS 2.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point leaderboard set deep link requires iOS 18, macOS 15, or visionOS 2.")
            }

            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.trigger(leaderboardSetID: id) {
                    continuation.resume()
                }
            }
        case .playTogether:
            #if os(iOS) || os(macOS)
            guard #available(iOS 26.0, macOS 26.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point play together requires iOS 26 or macOS 26.")
            }
            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.triggerForPlayTogether {
                    continuation.resume()
                }
            }
            #else
            throw GameCenterClientError.unsupportedPlatform("Access Point play together is unavailable on this platform.")
            #endif
        case .challenges:
            #if os(iOS) || os(macOS)
            guard #available(iOS 26.0, macOS 26.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point challenges requires iOS 26 or macOS 26.")
            }
            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.triggerForChallenges {
                    continuation.resume()
                }
            }
            #else
            throw GameCenterClientError.unsupportedPlatform("Access Point challenges is unavailable on this platform.")
            #endif
        case let .challengeDefinition(id):
            #if os(iOS) || os(macOS)
            guard #available(iOS 26.0, macOS 26.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point challenge creation requires iOS 26 or macOS 26.")
            }
            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.trigger(challengeDefinitionID: id) {
                    continuation.resume()
                }
            }
            #else
            throw GameCenterClientError.unsupportedPlatform("Access Point challenge creation is unavailable on this platform.")
            #endif
        case let .gameActivityDefinition(id):
            #if os(iOS) || os(macOS)
            guard #available(iOS 26.0, macOS 26.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point game activity creation requires iOS 26 or macOS 26.")
            }
            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.trigger(gameActivityDefinitionID: id) {
                    continuation.resume()
                }
            }
            #else
            throw GameCenterClientError.unsupportedPlatform("Access Point game activity creation is unavailable on this platform.")
            #endif
        case .friending:
            #if os(iOS) || os(macOS)
            guard #available(iOS 26.0, macOS 26.0, *) else {
                throw GameCenterClientError.unsupportedPlatform("Access Point friending requires iOS 26 or macOS 26.")
            }
            await withCheckedContinuation { continuation in
                GKAccessPoint.shared.triggerForFriending {
                    continuation.resume()
                }
            }
            #else
            throw GameCenterClientError.unsupportedPlatform("Access Point friending is unavailable on this platform.")
            #endif
        }
    }

    func loadFriendsAuthorizationStatus() async throws -> GameCenterFriendsAuthorizationStatus {
        try await withCheckedThrowingContinuation { continuation in
            GKLocalPlayer.local.loadFriendsAuthorizationStatus { authorizationStatus, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: GameCenterFriendsAuthorizationStatus(authorizationStatus: authorizationStatus))
            }
        }
    }

    func loadFriends() async throws -> [GameCenterPlayer] {
        try await withCheckedThrowingContinuation { continuation in
            GKLocalPlayer.local.loadFriends { players, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (players ?? []).map(GameCenterPlayer.init(player:)))
            }
        }
    }

    func loadFriends(identifiedBy identifiers: [String]) async throws -> [GameCenterPlayer] {
        try await withCheckedThrowingContinuation { continuation in
            GKLocalPlayer.local.loadFriends(identifiedBy: identifiers) { players, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (players ?? []).map(GameCenterPlayer.init(player:)))
            }
        }
    }

    func loadLocalPlayerPhoto(size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto {
        guard GKLocalPlayer.local.isAuthenticated else {
            throw GameCenterClientError.notAuthenticated
        }

        return try await loadPhoto(
            for: GKLocalPlayer.local,
            playerID: GKLocalPlayer.local.gamePlayerID,
            size: size
        )
    }

    func loadFriendPhoto(identifiedBy identifier: String, size: GameCenterPlayerPhotoSize) async throws -> GameCenterPlayerPhoto {
        guard GKLocalPlayer.local.isAuthenticated else {
            throw GameCenterClientError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            GKLocalPlayer.local.loadFriends(identifiedBy: [identifier]) { players, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let player = players?.first else {
                    continuation.resume(throwing: GameCenterClientError.playerNotFound(identifier))
                    return
                }

                loadPhoto(
                    for: player,
                    playerID: player.gamePlayerID,
                    size: size,
                    continuation: continuation
                )
            }
        }
    }

    #if canImport(UIKit) && !os(watchOS)
    @MainActor
    func presentFriendRequestCreator() async throws {
        guard #available(iOS 15.0, visionOS 1.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Friend request creator requires iOS 15 or visionOS 1.")
        }
        guard let viewController = UIApplication.shared.gameCenterTopMostViewController else {
            throw GameCenterClientError.authenticationPresentationRequired
        }

        try GKLocalPlayer.local.presentFriendRequestCreator(from: viewController)
    }
    #elseif canImport(AppKit)
    @MainActor
    func presentFriendRequestCreator() async throws {
        throw GameCenterClientError.unsupportedPlatform("Friend request creator is not implemented for this platform. Use Access Point friending where available.")
    }
    #elseif canImport(UIKit)
    @MainActor
    func presentFriendRequestCreator() async throws {
        throw GameCenterClientError.unsupportedPlatform("Friend request creator is unavailable on this platform. Use Access Point friending where available.")
    }
    #endif

    func loadChallengeDefinitions() async throws -> [GameCenterChallengeDefinition] {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, watchOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Challenges require iOS 26, macOS 26, visionOS 26, or watchOS 26.")
        }

        return try await GKChallengeDefinition.all.map(GameCenterChallengeDefinition.init(challengeDefinition:))
    }

    func hasActiveChallenges(challengeDefinitionID: String) async throws -> Bool {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, watchOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Challenges require iOS 26, macOS 26, visionOS 26, or watchOS 26.")
        }

        let challengeDefinition = try await challengeDefinition(id: challengeDefinitionID)
        return try await withCheckedThrowingContinuation { continuation in
            challengeDefinition.hasActiveChallenges { hasActiveChallenges, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: hasActiveChallenges)
            }
        }
    }

    @MainActor
    func triggerChallengeCreation(challengeDefinitionID: String) async throws {
        try await triggerAccessPoint(.challengeDefinition(id: challengeDefinitionID))
    }

    func loadGameActivityDefinitions(IDs: [String]? = nil) async throws -> [GameCenterGameActivityDefinition] {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        let definitions: [GKGameActivityDefinition]
        if let IDs {
            definitions = try await GKGameActivityDefinition.loadGameActivityDefinitions(IDs: IDs)
        } else {
            definitions = try await GKGameActivityDefinition.all
        }

        return definitions.map(GameCenterGameActivityDefinition.init(activityDefinition:))
    }

    func hasPendingGameActivities() async -> Bool {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            return false
        }

        return await GKGameActivity.hasPendingGameActivities
    }

    func startGameActivity(definitionID: String, partyCode: String? = nil) async throws -> GameCenterGameActivity {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        return try await LiveGameCenterActivityRegistry.shared.start(
            definitionID: definitionID,
            partyCode: partyCode
        )
    }

    func updateGameActivityProperties(activityID: String, properties: [String: String]) async throws -> GameCenterGameActivity {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        return try await LiveGameCenterActivityRegistry.shared.updateProperties(
            id: activityID,
            properties: properties
        )
    }

    func setScore(_ score: Int, leaderboardID: String, activityID: String, context: Int = 0) async throws {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        try await LiveGameCenterActivityRegistry.shared.setScore(
            id: activityID,
            leaderboardID: leaderboardID,
            score: score,
            context: context
        )
    }

    func setAchievementProgress(_ percentComplete: Double, achievementID: String, activityID: String) async throws {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        try await LiveGameCenterActivityRegistry.shared.setAchievementProgress(
            id: activityID,
            achievementID: achievementID,
            percentComplete: percentComplete
        )
    }

    func setAchievementCompleted(achievementID: String, activityID: String) async throws {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        try await LiveGameCenterActivityRegistry.shared.setAchievementCompleted(
            id: activityID,
            achievementID: achievementID
        )
    }

    func pauseGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        return try await LiveGameCenterActivityRegistry.shared.pause(id: activityID)
    }

    func resumeGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        return try await LiveGameCenterActivityRegistry.shared.resume(id: activityID)
    }

    func endGameActivity(activityID: String) async throws -> GameCenterGameActivity {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            throw GameCenterClientError.unsupportedPlatform("Activities require iOS 26, macOS 26, or visionOS 26.")
        }

        return try await LiveGameCenterActivityRegistry.shared.end(id: activityID)
    }

    func setGameActivityHandler(_ handler: (@Sendable (GameCenterPlayer, GameCenterGameActivity) async -> Bool)?) async {
        guard #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) else {
            return
        }

        await LiveGameCenterActivityRegistry.shared.setHandler(handler)
    }
}

private extension LiveGameCenterClient {
    func loadPhoto(
        for player: GKPlayer,
        playerID: String,
        size: GameCenterPlayerPhotoSize
    ) async throws -> GameCenterPlayerPhoto {
        try await withCheckedThrowingContinuation { continuation in
            loadPhoto(
                for: player,
                playerID: playerID,
                size: size,
                continuation: continuation
            )
        }
    }

    func loadPhoto(
        for player: GKPlayer,
        playerID: String,
        size: GameCenterPlayerPhotoSize,
        continuation: CheckedContinuation<GameCenterPlayerPhoto, Error>
    ) {
        #if canImport(UIKit)
        player.loadPhoto(for: size.gameKitPhotoSize) { photo, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }

            guard let data = photo?.pngData() else {
                continuation.resume(throwing: GameCenterClientError.playerPhotoUnavailable(playerID))
                return
            }

            continuation.resume(
                returning: GameCenterPlayerPhoto(
                    playerID: playerID,
                    size: size,
                    data: data
                )
            )
        }
        #elseif canImport(AppKit)
        player.loadPhoto(for: size.gameKitPhotoSize) { photo, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }

            guard let data = photo?.tiffRepresentation else {
                continuation.resume(throwing: GameCenterClientError.playerPhotoUnavailable(playerID))
                return
            }

            continuation.resume(
                returning: GameCenterPlayerPhoto(
                    playerID: playerID,
                    size: size,
                    data: data
                )
            )
        }
        #else
        continuation.resume(
            throwing: GameCenterClientError.unsupportedPlatform("Player photos require UIKit or AppKit.")
        )
        #endif
    }

    @MainActor
    func triggerAccessPoint() async {
        await withCheckedContinuation { continuation in
            GKAccessPoint.shared.trigger {
                continuation.resume()
            }
        }
    }

    @MainActor
    func triggerAccessPoint(state: GKGameCenterViewControllerState) async {
        await withCheckedContinuation { continuation in
            GKAccessPoint.shared.trigger(state: state) {
                continuation.resume()
            }
        }
    }

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, watchOS 26.0, *)
    func challengeDefinition(id: String) async throws -> GKChallengeDefinition {
        let definitions = try await GKChallengeDefinition.all
        guard let definition = definitions.first(where: { $0.identifier == id }) else {
            throw GameCenterClientError.challengeNotFound(id)
        }

        return definition
    }
}

@MainActor
private final class LiveGameCenterAuthenticationCoordinator {
    static let shared = LiveGameCenterAuthenticationCoordinator()

    private var inFlightAuthentication: Task<GameCenterPlayer, Error>?

    func authenticate(presenting presenter: GameCenterAuthenticationPresenter?) async throws -> GameCenterPlayer {
        if GKLocalPlayer.local.isAuthenticated {
            return GameCenterPlayer(localPlayer: GKLocalPlayer.local)
        }

        if let inFlightAuthentication {
            return try await inFlightAuthentication.value
        }

        let task = Task { @MainActor in
            try await Self.performAuthentication(presenting: presenter)
        }
        inFlightAuthentication = task

        defer {
            inFlightAuthentication = nil
        }

        return try await task.value
    }

    private static func performAuthentication(presenting presenter: GameCenterAuthenticationPresenter?) async throws -> GameCenterPlayer {
        try await withCheckedThrowingContinuation { continuation in
            let state = AuthenticationContinuation(continuation: continuation)

            GKLocalPlayer.local.authenticateHandler = { viewController, error in
                Task { @MainActor in
                    if let viewController {
                        guard let presenter else {
                            GKLocalPlayer.local.authenticateHandler = nil
                            state.resume(throwing: GameCenterClientError.authenticationPresentationRequired)
                            return
                        }

                        await presenter(viewController)
                        return
                    }

                    if let error {
                        GKLocalPlayer.local.authenticateHandler = nil
                        state.resume(throwing: error)
                        return
                    }

                    guard GKLocalPlayer.local.isAuthenticated else {
                        GKLocalPlayer.local.authenticateHandler = nil
                        state.resume(throwing: GameCenterClientError.notAuthenticated)
                        return
                    }

                    GKLocalPlayer.local.authenticateHandler = nil
                    state.resume(returning: GameCenterPlayer(localPlayer: GKLocalPlayer.local))
                }
            }
        }
    }
}

@MainActor
private final class AuthenticationContinuation {
    private var continuation: CheckedContinuation<GameCenterPlayer, Error>?

    init(continuation: CheckedContinuation<GameCenterPlayer, Error>) {
        self.continuation = continuation
    }

    func resume(returning player: GameCenterPlayer) {
        continuation?.resume(returning: player)
        continuation = nil
    }

    func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

#if os(iOS) || os(macOS) || os(visionOS)
@MainActor
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
private final class LiveGameCenterActivityRegistry {
    static let shared = LiveGameCenterActivityRegistry()

    private var activities: [String: GKGameActivity] = [:]
    private var handler: (@Sendable (GameCenterPlayer, GameCenterGameActivity) async -> Bool)?
    private var listener: LiveGameCenterActivityListener?

    func start(definitionID: String, partyCode: String?) async throws -> GameCenterGameActivity {
        let definitions = try await GKGameActivityDefinition.loadGameActivityDefinitions(IDs: [definitionID])
        guard let definition = definitions.first else {
            throw GameCenterClientError.activityNotFound(definitionID)
        }

        let activity: GKGameActivity
        if let partyCode {
            activity = try GKGameActivity.start(definition: definition, partyCode: partyCode)
        } else {
            activity = try GKGameActivity.start(definition: definition)
        }

        return store(activity)
    }

    func store(_ activity: GKGameActivity) -> GameCenterGameActivity {
        activities[activity.identifier] = activity
        return GameCenterGameActivity(activity: activity)
    }

    func updateProperties(id: String, properties: [String: String]) throws -> GameCenterGameActivity {
        let activity = try activity(id: id)
        activity.properties = properties
        return GameCenterGameActivity(activity: activity)
    }

    func setScore(id: String, leaderboardID: String, score: Int, context: Int) async throws {
        let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
        guard let leaderboard = leaderboards.first else {
            throw GameCenterClientError.leaderboardNotFound(leaderboardID)
        }

        let activity = try activity(id: id)
        activity.setScore(on: leaderboard, to: score, context: context)
    }

    func setAchievementProgress(id: String, achievementID: String, percentComplete: Double) throws {
        let activity = try activity(id: id)
        let achievement = GKAchievement(identifier: achievementID)
        activity.setProgress(on: achievement, to: min(max(percentComplete, 0), 100))
    }

    func setAchievementCompleted(id: String, achievementID: String) throws {
        let activity = try activity(id: id)
        activity.setAchievementCompleted(GKAchievement(identifier: achievementID))
    }

    func pause(id: String) throws -> GameCenterGameActivity {
        let activity = try activity(id: id)
        activity.pause()
        return GameCenterGameActivity(activity: activity)
    }

    func resume(id: String) throws -> GameCenterGameActivity {
        let activity = try activity(id: id)
        activity.resume()
        return GameCenterGameActivity(activity: activity)
    }

    func end(id: String) throws -> GameCenterGameActivity {
        let activity = try activity(id: id)
        activity.end()
        return GameCenterGameActivity(activity: activity)
    }

    private func activity(id: String) throws -> GKGameActivity {
        guard let activity = activities[id] else {
            throw GameCenterClientError.activityNotFound(id)
        }

        return activity
    }

    func setHandler(_ handler: (@Sendable (GameCenterPlayer, GameCenterGameActivity) async -> Bool)?) {
        self.handler = handler

        if handler == nil {
            if let listener {
                GKLocalPlayer.local.unregisterListener(listener)
            }
            listener = nil
            return
        }

        guard listener == nil else {
            return
        }

        let listener = LiveGameCenterActivityListener(registry: self)
        self.listener = listener
        GKLocalPlayer.local.register(listener)
    }

    func handle(
        player: GameCenterPlayer,
        activity: GKGameActivity
    ) async -> Bool {
        let activity = store(activity)
        guard let handler else {
            return false
        }

        return await handler(player, activity)
    }
}

@MainActor
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
private final class LiveGameCenterActivityListener: NSObject, @MainActor GKLocalPlayerListener, @unchecked Sendable {
    private let registry: LiveGameCenterActivityRegistry

    init(registry: LiveGameCenterActivityRegistry) {
        self.registry = registry
    }

    func player(
        _ player: GKPlayer,
        wantsToPlay activity: GKGameActivity,
        completionHandler: @escaping @Sendable (Bool) -> Void
    ) {
        let registry = registry
        let player = GameCenterPlayer(player: player)

        Task { @MainActor in
            let handled = await registry.handle(
                player: player,
                activity: activity
            )
            completionHandler(handled)
        }
    }
}
#endif
