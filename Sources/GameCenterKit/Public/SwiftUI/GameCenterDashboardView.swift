import SwiftUI

public struct GameCenterDashboardView: View {
    @StateObject private var model: GameCenterDashboardViewModel

    private let showsSystemProfileButton: Bool
    private let showsPlayerScopePicker: Bool

    #if canImport(UIKit) && !os(watchOS)
    @State private var systemDashboardMode: GameCenterSystemDashboardMode?
    #endif

    public init(
        configuration: GameCenterConfiguration,
        selectedScope: GameCenterRankingScope = .daily,
        playerScope: GameCenterPlayerScope = .global,
        range: Range<Int> = 1..<51,
        showsSystemProfileButton: Bool = true,
        showsPlayerScopePicker: Bool = true
    ) {
        self.showsSystemProfileButton = showsSystemProfileButton
        self.showsPlayerScopePicker = showsPlayerScopePicker
        _model = StateObject(
            wrappedValue: GameCenterDashboardViewModel(
                configuration: configuration,
                selectedScope: selectedScope,
                playerScope: playerScope,
                range: range
            )
        )
    }

    public init(
        model: GameCenterDashboardViewModel,
        showsSystemProfileButton: Bool = true,
        showsPlayerScopePicker: Bool = true
    ) {
        self.showsSystemProfileButton = showsSystemProfileButton
        self.showsPlayerScopePicker = showsPlayerScopePicker
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                GameCenterLeaderboardSection(
                    model: model,
                    showsPlayerScopePicker: showsPlayerScopePicker
                )
            }
            .padding()
        }
        #if canImport(UIKit) && !os(watchOS)
        .sheet(item: $systemDashboardMode) { mode in
            GameCenterSystemDashboardView(mode: mode) {
                systemDashboardMode = nil
            }
        }
        #endif
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.player?.displayName ?? "Game Center")
                    .font(.headline)

                if let localEntry = model.snapshot?.localPlayerEntry {
                    Text("#\(localEntry.rank) · \(localEntry.formattedScore)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .gameCenterNumericTransition()
                }
            }

            Spacer()

            #if canImport(UIKit) && !os(watchOS)
            if showsSystemProfileButton {
                Button {
                    systemDashboardMode = .profile
                } label: {
                    Image(systemName: "person.crop.circle")
                        .imageScale(.large)
                }
                .gameCenterGlassButton()
                .accessibilityLabel("Game Center 프로필")
            }
            #endif
        }
    }
}
