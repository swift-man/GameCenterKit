import Dependencies
import SwiftUI

public struct GameCenterNicknameView: View {
    private let showsProfileButton: Bool

    @State private var player: GameCenterPlayer?
    @State private var playerPhoto: GameCenterPlayerPhoto?
    @State private var errorMessage: String?

    #if canImport(UIKit) && !os(watchOS)
    @State private var showsProfile = false
    #endif

    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient
    @Dependency(\.gameCenterPlayerPhotoClient) private var playerPhotoClient

    public init(showsProfileButton: Bool = true) {
        self.showsProfileButton = showsProfileButton
    }

    public var body: some View {
        HStack(spacing: 12) {
            GameCenterPlayerAvatarView(
                photo: playerPhoto,
                systemImageName: "person.crop.circle"
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(player?.displayName ?? "닉네임 없음")
                    .font(.headline)
                    .lineLimit(1)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if player != nil {
                    Text("Game Center")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            #if canImport(UIKit) && !os(watchOS)
            if showsProfileButton {
                Button {
                    showsProfile = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.gearshape")
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

    @MainActor
    private func loadPlayer() async {
        do {
            player = try await authenticationClient.localPlayer()
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
