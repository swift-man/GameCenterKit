import Foundation

func gameCenterDisplayMessage(for error: Error) -> String {
    if let gameCenterError = error as? GameCenterClientError {
        return gameCenterError.userFacingMessage
    }

    let localizedDescription = (error as NSError).localizedDescription
    if localizedDescription.isEmpty {
        return GameCenterLocalizedString.string("error.request_failed")
    }

    return localizedDescription
}
