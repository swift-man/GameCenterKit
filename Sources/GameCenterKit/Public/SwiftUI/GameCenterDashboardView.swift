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

    public var body: some View {
        VStack(spacing: 16) {
            header
            rankingPicker

            if showsPlayerScopePicker {
                playerScopePicker
            }

            leaderboardContent
        }
        .padding()
        .task {
            await model.refresh()
        }
        .onChange(of: model.selectedScope) { _ in
            Task { await model.refresh() }
        }
        .onChange(of: model.playerScope) { _ in
            Task { await model.refresh() }
        }
        #if canImport(UIKit) && !os(watchOS)
        .sheet(item: $systemDashboardMode) { mode in
            GameCenterSystemDashboardView(mode: mode)
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
                .buttonStyle(.bordered)
                .accessibilityLabel("Game Center 프로필")
            }
            #endif
        }
    }

    private var rankingPicker: some View {
        Picker("랭킹", selection: $model.selectedScope) {
            ForEach(GameCenterRankingScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }

    private var playerScopePicker: some View {
        Picker("범위", selection: $model.playerScope) {
            ForEach(GameCenterPlayerScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var leaderboardContent: some View {
        if model.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 160)
        } else if let errorMessage = model.errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 160)
        } else if let snapshot = model.snapshot, !snapshot.entries.isEmpty {
            List(snapshot.entries) { entry in
                HStack(spacing: 12) {
                    Text("#\(entry.rank)")
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 48, alignment: .leading)

                    Text(entry.displayName)
                        .font(.body)
                        .lineLimit(1)

                    Spacer()

                    Text(entry.formattedScore)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        } else {
            Text("랭킹 없음")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 160)
        }
    }
}
