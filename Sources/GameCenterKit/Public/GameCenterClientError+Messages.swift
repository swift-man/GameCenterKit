import Foundation

extension GameCenterClientError: LocalizedError {
    public var errorDescription: String? {
        userFacingMessage
    }
}

extension GameCenterClientError {
    public var userFacingMessage: String {
        gameCenterClientErrorMessage(self)
    }
}
