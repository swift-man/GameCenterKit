import Foundation

func gameCenterDisplayMessage(for error: Error) -> String {
    if let gameCenterError = error as? GameCenterClientError {
        return gameCenterError.userFacingMessage
    }

    if
        let localizedError = error as? LocalizedError,
        let errorDescription = localizedError.errorDescription,
        !errorDescription.isEmpty
    {
        return errorDescription
    }

    return GameCenterLocalizedString.string("error.request_failed")
}
