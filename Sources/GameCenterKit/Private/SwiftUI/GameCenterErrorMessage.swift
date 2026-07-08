import Foundation

func gameCenterDisplayMessage(for error: Error) -> String {
    if let gameCenterError = error as? GameCenterClientError {
        return gameCenterError.userFacingMessage
    }

    let localizedDescription = (error as NSError).localizedDescription
    if localizedDescription.isEmpty {
        return "Game Center 요청을 완료하지 못했습니다."
    }

    return localizedDescription
}
