#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIApplication {
    var gameCenterTopMostViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController?
            .gameCenterTopMostPresentedViewController
    }
}

extension UIViewController {
    var gameCenterTopMostPresentedViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.gameCenterTopMostPresentedViewController
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.gameCenterTopMostPresentedViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.gameCenterTopMostPresentedViewController
        }

        return self
    }
}
#endif
