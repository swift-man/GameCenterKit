#if canImport(UIKit) && !os(watchOS)
import GameKit
import SwiftUI
import UIKit

public enum GameCenterSystemDashboardMode: Identifiable, Equatable, Sendable {
    case dashboard
    case profile
    case achievements
    case leaderboard(
        id: String,
        rankingScope: GameCenterRankingScope,
        playerScope: GameCenterPlayerScope
    )

    public var id: String {
        switch self {
        case .dashboard:
            return "dashboard"
        case .profile:
            return "profile"
        case .achievements:
            return "achievements"
        case let .leaderboard(id, rankingScope, playerScope):
            return "leaderboard-\(id)-\(rankingScope.rawValue)-\(playerScope.rawValue)"
        }
    }
}

public struct GameCenterSystemDashboardView: UIViewControllerRepresentable {
    private let mode: GameCenterSystemDashboardMode

    public init(mode: GameCenterSystemDashboardMode) {
        self.mode = mode
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let viewController: GKGameCenterViewController

        switch mode {
        case .dashboard:
            viewController = GKGameCenterViewController(state: .default)
        case .profile:
            viewController = GKGameCenterViewController(state: .localPlayerProfile)
        case .achievements:
            viewController = GKGameCenterViewController(state: .achievements)
        case let .leaderboard(id, rankingScope, playerScope):
            viewController = GKGameCenterViewController(
                leaderboardID: id,
                playerScope: playerScope.gameKitPlayerScope,
                timeScope: rankingScope.gameKitTimeScope
            )
        }

        viewController.gameCenterDelegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    public final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

@MainActor
public enum GameCenterUIKitPresenter {
    public static func present(_ viewController: UIViewController) async {
        guard let presenter = UIApplication.shared.gameCenterTopMostViewController else {
            return
        }

        await withCheckedContinuation { continuation in
            presenter.present(viewController, animated: true) {
                continuation.resume()
            }
        }
    }
}
#endif
