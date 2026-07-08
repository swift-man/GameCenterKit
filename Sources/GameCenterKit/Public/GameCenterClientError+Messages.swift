import Foundation

extension GameCenterClientError: LocalizedError {
    public var errorDescription: String? {
        userFacingMessage
    }
}

extension GameCenterClientError {
    public var userFacingMessage: String {
        switch self {
        case .notAuthenticated:
            return "Game Center 로그인이 필요합니다."
        case .authenticationPresentationRequired:
            return "Game Center 로그인 화면을 표시할 수 없습니다."
        case let .leaderboardNotConfigured(scope):
            return "\(scope.title) 랭킹이 설정되지 않았습니다."
        case .leaderboardNotFound:
            return "랭킹을 찾을 수 없습니다."
        case .playerNotFound:
            return "플레이어를 찾을 수 없습니다."
        case .playerPhotoUnavailable:
            return "플레이어 사진을 불러올 수 없습니다."
        case .challengeNotFound:
            return "챌린지를 찾을 수 없습니다."
        case .activityNotFound:
            return "게임 활동을 찾을 수 없습니다."
        case .unsupportedPlatform:
            return "현재 플랫폼에서 지원하지 않는 Game Center 기능입니다."
        }
    }
}
