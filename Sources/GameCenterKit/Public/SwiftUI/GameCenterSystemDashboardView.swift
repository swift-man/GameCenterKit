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
    @Environment(\.dismiss) private var dismiss

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
        Coordinator(onDismiss: onDismiss, dismiss: dismiss)
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

    public func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {
        context.coordinator.update(onDismiss: onDismiss, dismiss: dismiss)
    }

    public final class Coordinator: NSObject, @MainActor GKGameCenterControllerDelegate {
        private var onDismiss: (@MainActor () -> Void)?
        private var dismiss: DismissAction

        init(onDismiss: (@MainActor () -> Void)?, dismiss: DismissAction) {
            self.onDismiss = onDismiss
            self.dismiss = dismiss
        }

        func update(onDismiss: (@MainActor () -> Void)?, dismiss: DismissAction) {
            self.onDismiss = onDismiss
            self.dismiss = dismiss
        }

        public func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            let onDismiss = onDismiss
            let dismiss = dismiss

            Task { @MainActor in
                if let onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            }
        }
    }
}

@MainActor
public enum GameCenterUIKitPresenter {
    public static func present(_ viewController: UIViewController) async {
        _ = await presentIfAvailable(viewController)
    }

    public static func presentRequired(_ viewController: UIViewController) async throws {
        guard await presentIfAvailable(viewController) else {
            throw GameCenterClientError.authenticationPresentationRequired
        }
    }

    private static func presentIfAvailable(_ viewController: UIViewController) async -> Bool {
        guard let presenter = UIApplication.shared.gameCenterTopMostViewController else {
            return false
        }

        await withCheckedContinuation { continuation in
            presenter.present(viewController, animated: true) {
                continuation.resume()
            }
        }

        return true
    }
}
#endif
