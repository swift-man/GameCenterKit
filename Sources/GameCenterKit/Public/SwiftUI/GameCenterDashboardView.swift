import MaterialDesignColorSwiftUI
import SwiftUI

public struct GameCenterDashboardView: View {
    @StateObject private var model: GameCenterDashboardViewModel
    @State private var dashboardRefreshTrigger = 0

    private let theme: MaterialTheme
    private let showsSystemProfileButton: Bool
    private let showsPlayerScopePicker: Bool

    #if canImport(UIKit) && !os(watchOS)
    @State private var systemDashboardMode: GameCenterSystemDashboardMode?
    #endif

    public init(
        configuration: GameCenterConfiguration,
        theme: MaterialTheme,
        selectedCategoryID: String? = nil,
        selectedScope: GameCenterRankingScope = .daily,
        playerScope: GameCenterPlayerScope = .global,
        range: Range<Int> = 1..<51,
        showsSystemProfileButton: Bool = true,
        showsPlayerScopePicker: Bool = true
    ) {
        self.theme = theme
        self.showsSystemProfileButton = showsSystemProfileButton
        self.showsPlayerScopePicker = showsPlayerScopePicker
        _model = StateObject(
            wrappedValue: GameCenterDashboardViewModel(
                configuration: configuration,
                selectedCategoryID: selectedCategoryID,
                selectedScope: selectedScope,
                playerScope: playerScope,
                range: range
            )
        )
    }

    public init(
        model: GameCenterDashboardViewModel,
        theme: MaterialTheme,
        showsSystemProfileButton: Bool = true,
        showsPlayerScopePicker: Bool = true
    ) {
        self.theme = theme
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
                    showsPlayerScopePicker: showsPlayerScopePicker,
                    refreshTrigger: dashboardRefreshTrigger
                )
            }
            .padding()
        }
        .background(theme.colorScheme.surface.color)
        .materialTheme(theme)
        #if canImport(UIKit) && !os(watchOS)
        .sheet(
            item: $systemDashboardMode,
            onDismiss: {
                dashboardRefreshTrigger += 1
            }
        ) { mode in
            GameCenterSystemDashboardView(mode: mode) {
                systemDashboardMode = nil
            }
        }
        #endif
    }

    private var header: some View {
        let scheme = theme.colorScheme

        return HStack(alignment: .center, spacing: 12) {
            GameCenterPlayerAvatarView(photo: model.playerPhoto)

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    model.player?.displayName
                        ?? GameCenterLocalizedString.string("ui.nickname.none")
                )
                    .font(.headline)
                    .foregroundStyle(scheme.onSurface.color)

                if let localEntry = model.snapshot?.localPlayerEntry {
                    Text("#\(localEntry.rank) · \(localEntry.formattedScore)")
                        .font(.subheadline)
                        .foregroundStyle(scheme.onSurfaceVariant.color)
                        .gameCenterNumericTransition()
                        .animation(.default, value: localEntry.score)
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
                .accessibilityLabel(GameCenterLocalizedString.string("accessibility.profile"))
            }
            #endif
        }
    }
}
