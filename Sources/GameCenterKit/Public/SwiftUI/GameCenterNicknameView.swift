import Dependencies
import SwiftUI

public struct GameCenterNicknameView: View {
    private let showsProfileButton: Bool

    @State private var player: GameCenterPlayer?
    @State private var errorMessage: String?

    #if canImport(UIKit) && !os(watchOS)
    @State private var showsProfile = false
    #endif

    @Dependency(\.gameCenterAuthenticationClient) private var authenticationClient

    public init(showsProfileButton: Bool = true) {
        self.showsProfileButton = showsProfileButton
    }

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player?.displayName ?? "닉네임 없음")
                    .font(.headline)
                    .lineLimit(1)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            #if canImport(UIKit) && !os(watchOS)
            if showsProfileButton {
                Button {
                    showsProfile = true
                } label: {
                    Image(systemName: "person.crop.circle.badge.gearshape")
                        .imageScale(.large)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Game Center 닉네임 설정")
            }
            #endif
        }
        .task {
            await loadPlayer()
        }
        #if canImport(UIKit) && !os(watchOS)
        .sheet(isPresented: $showsProfile) {
            GameCenterSystemDashboardView(mode: .profile) {
                showsProfile = false
            }
        }
        #endif
    }

    private func loadPlayer() async {
        do {
            player = try await authenticationClient.localPlayer()
            errorMessage = nil
        } catch {
            errorMessage = String(describing: error)
        }
    }
}
