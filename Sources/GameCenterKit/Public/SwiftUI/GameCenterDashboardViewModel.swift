import Dependencies
import Foundation

@MainActor
public final class GameCenterDashboardViewModel: ObservableObject {
    @Published public private(set) var player: GameCenterPlayer?
    @Published public private(set) var playerPhoto: GameCenterPlayerPhoto?
    @Published public private(set) var snapshot: GameCenterLeaderboardSnapshot?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public var selectedScope: GameCenterRankingScope
    @Published public var playerScope: GameCenterPlayerScope

    private let configuration: GameCenterConfiguration
    private let range: Range<Int>
    private var refreshGeneration = 0

    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient
    @Dependency(\.gameCenterLeaderboardClient) private var leaderboardClient
    @Dependency(\.gameCenterPlayerPhotoClient) private var playerPhotoClient

    public init(
        configuration: GameCenterConfiguration,
        selectedScope: GameCenterRankingScope = .daily,
        playerScope: GameCenterPlayerScope = .global,
        range: Range<Int> = 1..<51
    ) {
        self.configuration = configuration
        self.selectedScope = selectedScope
        self.playerScope = playerScope
        self.range = range
    }

    public func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        let requestedScope = selectedScope
        let requestedPlayerScope = playerScope

        isLoading = true
        errorMessage = nil

        defer {
            if isCurrentRefresh(
                generation: generation,
                selectedScope: requestedScope,
                playerScope: requestedPlayerScope
            ) {
                isLoading = false
            }
        }

        do {
            let loadedPlayer = try? await authenticationClient.localPlayer()
            let loadedPlayerPhoto = try? await playerPhotoClient.loadLocalPlayerPhoto(size: .small)

            guard let leaderboardID = configuration.leaderboardID(for: requestedScope) else {
                throw GameCenterClientError.leaderboardNotConfigured(requestedScope)
            }

            let loadedSnapshot = try await leaderboardClient.loadLeaderboard(
                GameCenterLeaderboardRequest(
                    leaderboardID: leaderboardID,
                    rankingScope: requestedScope,
                    playerScope: requestedPlayerScope,
                    range: range
                )
            )

            guard isCurrentRefresh(
                generation: generation,
                selectedScope: requestedScope,
                playerScope: requestedPlayerScope
            ) else {
                return
            }

            player = loadedPlayer
            playerPhoto = loadedPlayerPhoto
            snapshot = loadedSnapshot
        } catch {
            guard isCurrentRefresh(
                generation: generation,
                selectedScope: requestedScope,
                playerScope: requestedPlayerScope
            ) else {
                return
            }

            snapshot = nil
            errorMessage = String(describing: error)
        }
    }

    private func isCurrentRefresh(
        generation: Int,
        selectedScope: GameCenterRankingScope,
        playerScope: GameCenterPlayerScope
    ) -> Bool {
        generation == refreshGeneration &&
            selectedScope == self.selectedScope &&
            playerScope == self.playerScope
    }
}
