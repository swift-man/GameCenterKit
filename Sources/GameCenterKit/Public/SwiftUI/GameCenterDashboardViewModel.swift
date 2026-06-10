import Dependencies
import Foundation

@MainActor
public final class GameCenterDashboardViewModel: ObservableObject {
    @Published public private(set) var player: GameCenterPlayer?
    @Published public private(set) var snapshot: GameCenterLeaderboardSnapshot?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public var selectedScope: GameCenterRankingScope
    @Published public var playerScope: GameCenterPlayerScope

    private let configuration: GameCenterConfiguration
    private let range: Range<Int>

    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient
    @Dependency(\.gameCenterLeaderboardClient) private var leaderboardClient

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
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            player = try? await authenticationClient.localPlayer()

            guard let leaderboardID = configuration.leaderboardID(for: selectedScope) else {
                throw GameCenterClientError.leaderboardNotConfigured(selectedScope)
            }

            snapshot = try await leaderboardClient.loadLeaderboard(
                GameCenterLeaderboardRequest(
                    leaderboardID: leaderboardID,
                    rankingScope: selectedScope,
                    playerScope: playerScope,
                    range: range
                )
            )
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
