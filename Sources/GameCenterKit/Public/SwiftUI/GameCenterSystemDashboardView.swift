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
    private let onDismiss: (@MainActor () -> Void)?

    public init(
        mode: GameCenterSystemDashboardMode,
        onDismiss: (@MainActor () -> Void)? = nil
    ) {
        self.mode = mode
        self.onDismiss = onDismiss
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
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
        private let onDismiss: (@MainActor () -> Void)?

        init(onDismiss: (@MainActor () -> Void)?) {
            self.onDismiss = onDismiss
        }

        public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            guard let onDismiss else {
                gameCenterViewController.dismiss(animated: true)
                return
            }

            Task { @MainActor in
                onDismiss()
            }
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
