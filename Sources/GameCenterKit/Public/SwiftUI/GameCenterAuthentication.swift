import Dependencies
import SwiftUI

extension View {
    /// 앱 시작 시 Game Center 인증을 즉시 트리거한다.
    ///
    /// 앱의 루트 뷰에 붙이면 `GKLocalPlayer.authenticateHandler`가 가능한 한 이른
    /// 시점에 설정되어, 필요하면 로그인 화면을 자동으로 표시하고, 인증이 끝나면
    /// 하위의 Game Center 뷰들이 데이터를 곧바로 불러온다.
    ///
    /// ```swift
    /// RootTabView()
    ///     .gameCenterAuthentication { result in
    ///         if case let .failure(error) = result {
    ///             // 로깅 등 처리
    ///         }
    ///     }
    /// ```
    public func gameCenterAuthentication(
        onResult: (@MainActor @Sendable (Result<GameCenterPlayer, Error>) -> Void)? = nil
    ) -> some View {
        modifier(GameCenterAuthenticationModifier(onResult: onResult))
    }
}

private struct GameCenterAuthenticationModifier: ViewModifier {
    let onResult: (@MainActor @Sendable (Result<GameCenterPlayer, Error>) -> Void)?

    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient

    func body(content: Content) -> some View {
        content.task {
            await authenticate()
        }
    }

    @MainActor
    private func authenticate() async {
        do {
            let player = try await authenticationClient.authenticatedPlayerUsingDefaultPresenter()
            onResult?(.success(player))
        } catch is CancellationError {
            // 뷰가 사라져 인증 태스크가 취소된 경우이므로 결과를 전달하지 않는다.
        } catch {
            onResult?(.failure(error))
        }
    }
}

extension GameCenterAuthenticationClientProtocol {
    /// 플랫폼 기본 프레젠터로 인증을 보장한 뒤 로컬 플레이어를 반환한다.
    ///
    /// 이미 인증돼 있으면 즉시 반환하고, 아니면 로그인 화면을 최상위 뷰 컨트롤러에
    /// 표시한다. 동시 호출은 `LiveGameCenterClient` 쪽에서 하나의 인증 흐름으로 합쳐진다.
    @MainActor
    func authenticatedPlayerUsingDefaultPresenter() async throws -> GameCenterPlayer {
        #if canImport(UIKit) && !os(watchOS)
        return try await authenticate(presenting: { viewController in
            try await GameCenterUIKitPresenter.presentRequired(viewController)
        })
        #elseif canImport(AppKit)
        return try await authenticate(presenting: nil)
        #else
        return try await localPlayer()
        #endif
    }
}
