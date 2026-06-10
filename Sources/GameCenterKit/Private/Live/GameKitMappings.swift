import Foundation
@preconcurrency import GameKit

extension GameCenterPlayer {
    init(player: GKPlayer) {
        self.init(
            gamePlayerID: player.gamePlayerID,
            teamPlayerID: player.teamPlayerID,
            displayName: player.displayName,
            isAuthenticated: false
        )
    }

    init(localPlayer: GKLocalPlayer) {
        self.init(
            gamePlayerID: localPlayer.gamePlayerID,
            teamPlayerID: localPlayer.teamPlayerID,
            displayName: localPlayer.displayName,
            isAuthenticated: localPlayer.isAuthenticated,
            isUnderage: localPlayer.isUnderage,
            isMultiplayerGamingRestricted: localPlayer.isMultiplayerGamingRestricted,
            isPersonalizedCommunicationRestricted: localPlayer.isPersonalizedCommunicationRestricted
        )
    }
}

extension GameCenterLeaderboardEntry {
    init(entry: GKLeaderboard.Entry) {
        self.init(
            id: entry.player.gamePlayerID,
            rank: entry.rank,
            score: entry.score,
            formattedScore: entry.formattedScore,
            displayName: entry.player.displayName,
            gamePlayerID: entry.player.gamePlayerID,
            date: entry.date
        )
    }
}

extension GameCenterLeaderboard {
    init(leaderboard: GKLeaderboard) {
        var details: String?
        var releaseState: GameCenterReleaseState?
        var activityIdentifier: String?
        var activityProperties: [String: String] = [:]
        var isHidden: Bool?

        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, watchOS 26.0, *) {
            details = leaderboard.leaderboardDescription
            releaseState = GameCenterReleaseState(releaseState: leaderboard.releaseState)
            activityIdentifier = leaderboard.activityIdentifier
            activityProperties = leaderboard.activityProperties
            isHidden = leaderboard.isHidden
        }

        self.init(
            id: leaderboard.baseLeaderboardID,
            title: leaderboard.title,
            groupIdentifier: leaderboard.groupIdentifier,
            kind: GameCenterLeaderboardKind(leaderboardType: leaderboard.type),
            startDate: leaderboard.startDate,
            nextStartDate: leaderboard.nextStartDate,
            duration: leaderboard.duration,
            details: details,
            releaseState: releaseState,
            activityIdentifier: activityIdentifier,
            activityProperties: activityProperties,
            isHidden: isHidden
        )
    }
}

extension GameCenterAchievementProgress {
    init(achievement: GKAchievement) {
        self.init(
            id: achievement.identifier,
            percentComplete: achievement.percentComplete,
            isCompleted: achievement.isCompleted,
            lastReportedDate: achievement.lastReportedDate
        )
    }
}

extension GameCenterChallengeDefinition {
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, watchOS 26.0, *)
    init(challengeDefinition: GKChallengeDefinition) {
        self.init(
            id: challengeDefinition.identifier,
            groupIdentifier: challengeDefinition.groupIdentifier,
            title: challengeDefinition.title,
            details: challengeDefinition.details,
            durationOptions: challengeDefinition.durationOptions,
            isRepeatable: challengeDefinition.isRepeatable,
            leaderboardID: challengeDefinition.leaderboard?.baseLeaderboardID,
            releaseState: GameCenterReleaseState(releaseState: challengeDefinition.releaseState)
        )
    }
}

extension GameCenterGameActivityDefinition {
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    init(activityDefinition: GKGameActivityDefinition) {
        self.init(
            id: activityDefinition.identifier,
            groupIdentifier: activityDefinition.groupIdentifier,
            title: activityDefinition.title,
            details: activityDefinition.details,
            defaultProperties: activityDefinition.defaultProperties,
            fallbackURL: activityDefinition.fallbackURL,
            supportsPartyCode: activityDefinition.supportsPartyCode,
            supportsUnlimitedPlayers: activityDefinition.supportsUnlimitedPlayers,
            playStyle: GameCenterGameActivityPlayStyle(playStyle: activityDefinition.playStyle),
            releaseState: GameCenterReleaseState(releaseState: activityDefinition.releaseState)
        )
    }
}

extension GameCenterGameActivity {
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    init(activity: GKGameActivity) {
        self.init(
            id: activity.identifier,
            definitionID: activity.activityDefinition.identifier,
            properties: activity.properties,
            state: GameCenterGameActivityState(activityState: activity.state),
            partyCode: activity.partyCode,
            partyURL: activity.partyURL,
            creationDate: activity.creationDate,
            startDate: activity.startDate,
            lastResumeDate: activity.lastResumeDate,
            endDate: activity.endDate,
            duration: activity.duration
        )
    }
}

extension GameCenterLeaderboardRequest {
    var nsRange: NSRange {
        NSRange(location: range.lowerBound, length: range.count)
    }
}

extension GameCenterRankingScope {
    var gameKitTimeScope: GKLeaderboard.TimeScope {
        switch self {
        case .daily:
            return .today
        case .weekly:
            return .week
        case .monthly:
            return .allTime
        }
    }
}

extension GameCenterPlayerScope {
    var gameKitPlayerScope: GKLeaderboard.PlayerScope {
        switch self {
        case .global:
            return .global
        case .friendsOnly:
            return .friendsOnly
        }
    }
}

extension GameCenterLeaderboardKind {
    init(leaderboardType: GKLeaderboard.LeaderboardType) {
        switch leaderboardType {
        case .classic:
            self = .classic
        case .recurring:
            self = .recurring
        @unknown default:
            self = .unknown
        }
    }
}

extension GameCenterReleaseState {
    @available(iOS 18.4, macOS 15.4, visionOS 2.4, watchOS 11.4, *)
    init(releaseState: GKReleaseState) {
        if releaseState.contains(.released) {
            self = .released
        } else if releaseState.contains(.prereleased) {
            self = .prereleased
        } else {
            self = .unknown
        }
    }
}

extension GameCenterAccessPointLocation {
    var gameKitLocation: GKAccessPoint.Location {
        switch self {
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        }
    }
}

extension GameCenterFriendsAuthorizationStatus {
    init(authorizationStatus: GKFriendsAuthorizationStatus) {
        switch authorizationStatus {
        case .notDetermined:
            self = .notDetermined
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .authorized:
            self = .authorized
        @unknown default:
            self = .unknown
        }
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension GameCenterGameActivityPlayStyle {
    init(playStyle: GKGameActivityPlayStyle) {
        switch playStyle {
        case .unspecified:
            self = .unspecified
        case .synchronous:
            self = .synchronous
        case .asynchronous:
            self = .asynchronous
        @unknown default:
            self = .unspecified
        }
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension GameCenterGameActivityState {
    init(activityState: GKGameActivity.State) {
        switch activityState {
        case .initialized:
            self = .initialized
        case .active:
            self = .active
        case .paused:
            self = .paused
        case .ended:
            self = .ended
        @unknown default:
            self = .unknown
        }
    }
}
