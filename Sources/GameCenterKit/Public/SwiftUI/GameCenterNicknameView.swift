import Dependencies
import MaterialDesignColorSwiftUI
import ShimmerUI
import SwiftUI

public struct GameCenterNicknameView: View {
    private let theme: MaterialTheme?
    private let showsProfileButton: Bool
    private let detailText: String?

    @State private var player: GameCenterPlayer?
    @State private var playerPhoto: GameCenterPlayerPhoto?
    @State private var isLoading = true
    @State private var errorMessage: String?

    #if canImport(UIKit) && !os(watchOS)
    @State private var showsProfile = false
    #endif

    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient
    @Dependency(\.gameCenterPlayerPhotoClient) private var playerPhotoClient
    @Environment(\.materialTheme) private var materialTheme

    private var effectiveTheme: MaterialTheme {
        theme ?? materialTheme
    }

    public init(theme: MaterialTheme, showsProfileButton: Bool = true) {
        self.theme = theme
        self.showsProfileButton = showsProfileButton
        self.detailText = nil
    }

    init(showsProfileButton: Bool = true, detailText: String? = nil) {
        self.theme = nil
        self.showsProfileButton = showsProfileButton
        self.detailText = detailText
    }

    public var body: some View {
        HStack(spacing: 12) {
            content

            Spacer(minLength: 8)

            #if canImport(UIKit) && !os(watchOS)
            if showsProfileButton {
                Button {
                    showsProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .imageScale(.large)
                }
                .gameCenterGlassButton()
                .accessibilityLabel("Game Center 닉네임 설정")
            }
            #endif
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .gameCenterGlass(in: Capsule())
        .task {
            await loadPlayer()
        }
        .gameCenterProvidedMaterialTheme(theme)
        #if canImport(UIKit) && !os(watchOS)
        .sheet(
            isPresented: $showsProfile,
            onDismiss: {
                Task { await loadPlayer() }
            }
        ) {
            GameCenterSystemDashboardView(mode: .profile) {
                showsProfile = false
            }
        }
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ShimmerLoadingUI.Container(configuration: effectiveTheme.gameCenterShimmerConfiguration) {
                loadingContent
            }
        } else {
            loadedContent
        }
    }

    private var loadingContent: some View {
        HStack(spacing: 12) {
            ShimmerLoadingUI.Block(.circle)
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 6) {
                ShimmerLoadingUI.Block(.capsule)
                    .frame(width: 128, height: 16)

                ShimmerLoadingUI.Block(.capsule)
                    .frame(width: 92, height: 12)
            }
        }
    }

    private var loadedContent: some View {
        let scheme = effectiveTheme.colorScheme

        return HStack(spacing: 12) {
            GameCenterPlayerAvatarView(
                photo: playerPhoto,
                systemImageName: "person.crop.circle"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(player?.displayName ?? "닉네임 없음")
                    .font(.headline)
                    .foregroundStyle(scheme.onSurface.color)
                    .lineLimit(1)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(scheme.error.color)
                        .lineLimit(1)
                } else if let detailText {
                    Text(detailText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(scheme.onSurfaceVariant.color)
                        .gameCenterNumericTransition()
                        .animation(.default, value: detailText)
                } else if player != nil {
                    Text("Game Center")
                        .font(.caption)
                        .foregroundStyle(scheme.onSurfaceVariant.color)
                }
            }
        }
    }

    @MainActor
    private func loadPlayer() async {
        isLoading = true
        defer { isLoading = false }

        do {
            player = try await authenticationClient.authenticatedPlayerUsingDefaultPresenter()
            playerPhoto = try await loadLocalPlayerPhotoIfAvailable()
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            player = nil
            playerPhoto = nil
            errorMessage = String(describing: error)
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
