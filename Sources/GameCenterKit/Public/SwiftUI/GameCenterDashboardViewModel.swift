import Dependencies
import Foundation

@MainActor
public final class GameCenterDashboardViewModel: ObservableObject {
    @Published public private(set) var player: GameCenterPlayer?
    @Published public private(set) var playerPhoto: GameCenterPlayerPhoto?
    @Published public private(set) var snapshot: GameCenterLeaderboardSnapshot?
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public var selectedScope: GameCenterRankingScope {
        didSet {
            if selectedScope == .monthly {
                selectedScope = .allTime
            }
        }
    }
    @Published public var selectedCategoryID: String {
        didSet {
            let normalizedCategoryID = normalizedCategoryID(selectedCategoryID)

            if selectedCategoryID != normalizedCategoryID {
                selectedCategoryID = normalizedCategoryID
            }
        }
    }
    @Published public var playerScope: GameCenterPlayerScope

    private let configuration: GameCenterConfiguration
    private let range: Range<Int>
    private var refreshGeneration = 0

    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient
    @Dependency(\.gameCenterLeaderboardClient) private var leaderboardClient
    @Dependency(\.gameCenterPlayerPhotoClient) private var playerPhotoClient

    public init(
        configuration: GameCenterConfiguration,
        selectedCategoryID: String? = nil,
        selectedScope: GameCenterRankingScope = .daily,
        playerScope: GameCenterPlayerScope = .global,
        range: Range<Int> = 1..<51
    ) {
        self.configuration = configuration
        self.selectedCategoryID = selectedCategoryID.flatMap { id in
            configuration.leaderboardCategory(id: id)?.id
        } ?? configuration.leaderboardCategories.first?.id ?? ""
        self.selectedScope = selectedScope.normalizedForDashboardSelection
        self.playerScope = playerScope
        self.range = range
    }

    public var leaderboardCategories: [GameCenterLeaderboardCategory] {
        configuration.leaderboardCategories
    }

    public func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        let requestedCategoryID = selectedCategoryID
        let requestedScope = selectedScope
        let requestedPlayerScope = playerScope

        isLoading = true
        errorMessage = nil

        defer {
            if isCurrentRefresh(
                generation: generation,
                selectedCategoryID: requestedCategoryID,
                selectedScope: requestedScope,
                playerScope: requestedPlayerScope
            ) {
                isLoading = false
            }
        }

        do {
            let loadedPlayer = try await authenticatedPlayerIfAvailable()
            let loadedPlayerPhoto = try await loadLocalPlayerPhotoIfAvailable()

            guard let leaderboardID = configuration.leaderboardID(
                for: requestedScope,
                categoryID: requestedCategoryID
            ) else {
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
                selectedCategoryID: requestedCategoryID,
                selectedScope: requestedScope,
                playerScope: requestedPlayerScope
            ) else {
                return
            }

            player = loadedPlayer
            playerPhoto = loadedPlayerPhoto
            snapshot = loadedSnapshot
        } catch is CancellationError {
            return
        } catch {
            guard isCurrentRefresh(
                generation: generation,
                selectedCategoryID: requestedCategoryID,
                selectedScope: requestedScope,
                playerScope: requestedPlayerScope
            ) else {
                return
            }

            player = nil
            playerPhoto = nil
            snapshot = nil
            errorMessage = String(describing: error)
        }
    }

    private func isCurrentRefresh(
        generation: Int,
        selectedCategoryID: String,
        selectedScope: GameCenterRankingScope,
        playerScope: GameCenterPlayerScope
    ) -> Bool {
        generation == refreshGeneration &&
            selectedCategoryID == self.selectedCategoryID &&
            selectedScope == self.selectedScope &&
            playerScope == self.playerScope
    }

    private func normalizedCategoryID(_ categoryID: String) -> String {
        if configuration.leaderboardCategory(id: categoryID) != nil {
            return categoryID
        }

        return configuration.leaderboardCategories.first?.id ?? ""
    }

    private func authenticatedPlayerIfAvailable() async throws -> GameCenterPlayer? {
        do {
            return try await authenticationClient.authenticatedPlayerUsingDefaultPresenter()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return nil
        }
    }

    private func loadLocalPlayerPhotoIfAvailable() async throws -> GameCenterPlayerPhoto? {
        do {
            return try await playerPhotoClient.loadLocalPlayerPhoto(size: .small)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return nil
        }
    }
}

private extension GameCenterRankingScope {
    var normalizedForDashboardSelection: GameCenterRankingScope {
        switch self {
        case .monthly:
            return .allTime
        case .daily, .weekly, .allTime:
            return self
        }
    }
}
