func gameCenterRankingScopeTitle(
    _ scope: GameCenterRankingScope,
    localization: String? = nil
) -> String {
    let key: String

    switch scope {
    case .daily:
        key = "ranking_scope.daily"
    case .weekly:
        key = "ranking_scope.weekly"
    case .allTime, .monthly:
        key = "ranking_scope.all_time"
    }

    return GameCenterLocalizedString.string(key, localization: localization)
}

func gameCenterPlayerScopeTitle(
    _ scope: GameCenterPlayerScope,
    localization: String? = nil
) -> String {
    let key: String

    switch scope {
    case .global:
        key = "player_scope.global"
    case .friendsOnly:
        key = "player_scope.friends"
    }

    return GameCenterLocalizedString.string(key, localization: localization)
}

func gameCenterClientErrorMessage(
    _ error: GameCenterClientError,
    localization: String? = nil
) -> String {
    switch error {
    case .notAuthenticated:
        return GameCenterLocalizedString.string(
            "error.not_authenticated",
            localization: localization
        )
    case .authenticationPresentationRequired:
        return GameCenterLocalizedString.string(
            "error.authentication_presentation_required",
            localization: localization
        )
    case let .leaderboardNotConfigured(scope):
        return GameCenterLocalizedString.format(
            "error.leaderboard_not_configured",
            localization: localization,
            gameCenterRankingScopeTitle(scope, localization: localization)
        )
    case .leaderboardNotFound:
        return GameCenterLocalizedString.string(
            "error.leaderboard_not_found",
            localization: localization
        )
    case .playerNotFound:
        return GameCenterLocalizedString.string(
            "error.player_not_found",
            localization: localization
        )
    case .playerPhotoUnavailable:
        return GameCenterLocalizedString.string(
            "error.player_photo_unavailable",
            localization: localization
        )
    case .challengeNotFound:
        return GameCenterLocalizedString.string(
            "error.challenge_not_found",
            localization: localization
        )
    case .activityNotFound:
        return GameCenterLocalizedString.string(
            "error.activity_not_found",
            localization: localization
        )
    case .unsupportedPlatform:
        return GameCenterLocalizedString.string(
            "error.unsupported_platform",
            localization: localization
        )
    }
}
