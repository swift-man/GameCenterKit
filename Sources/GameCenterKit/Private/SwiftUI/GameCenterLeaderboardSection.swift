import MaterialDesignColorSwiftUI
import ShimmerUI
import SwiftUI

struct GameCenterLeaderboardSection: View {
    @ObservedObject var model: GameCenterDashboardViewModel
    var showsPlayerScopePicker: Bool = true

    @Environment(\.materialTheme) private var materialTheme

    #if canImport(UIKit) && !os(watchOS)
    @State private var systemLeaderboard: GameCenterSystemDashboardMode?
    #endif

    var body: some View {
        VStack(spacing: 12) {
            if model.leaderboardCategories.count > 1 {
                categoryPicker
            }

            rankingPicker

            if showsPlayerScopePicker {
                playerScopePicker
            }

            content
        }
        .task(id: refreshKey) {
            await model.refresh()
        }
        #if canImport(UIKit) && !os(watchOS)
        .sheet(item: $systemLeaderboard) { mode in
            GameCenterSystemDashboardView(mode: mode) {
                systemLeaderboard = nil
            }
        }
        #endif
    }

    private var refreshKey: RefreshKey {
        RefreshKey(
            selectedCategoryID: model.selectedCategoryID,
            rankingScope: model.selectedScope,
            playerScope: model.playerScope
        )
    }

    private var categoryPicker: some View {
        let scheme = materialTheme.colorScheme

        return HStack(spacing: 8) {
            Text("종류")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(scheme.onSurfaceVariant.color)

            Spacer(minLength: 8)

            Picker("랭킹 종류", selection: $model.selectedCategoryID) {
                ForEach(model.leaderboardCategories) { category in
                    Text(category.title).tag(category.id)
                }
            }
            .pickerStyle(.menu)
            .tint(scheme.primary.color)
        }
        .frame(maxWidth: .infinity)
    }

    private var rankingPicker: some View {
        Picker("랭킹", selection: $model.selectedScope) {
            ForEach(GameCenterRankingScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .tint(materialTheme.colorScheme.primary.color)
    }

    private var playerScopePicker: some View {
        Picker("범위", selection: $model.playerScope) {
            ForEach(GameCenterPlayerScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .tint(materialTheme.colorScheme.primary.color)
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            skeleton
        } else if let errorMessage = model.errorMessage {
            GameCenterEmptyStateView(
                title: "불러오기 실패",
                systemImage: "exclamationmark.triangle",
                message: errorMessage
            )
        } else if let snapshot = model.snapshot, !snapshot.entries.isEmpty {
            LazyVStack(spacing: 2) {
                ForEach(snapshot.entries) { entry in
                    GameCenterLeaderboardRow(
                        entry: entry,
                        isLocalPlayer: isLocalPlayer(entry, in: snapshot)
                    )
                    #if canImport(UIKit) && !os(watchOS)
                    .onTapGesture {
                        systemLeaderboard = .leaderboard(
                            id: snapshot.request.leaderboardID,
                            rankingScope: snapshot.request.rankingScope,
                            playerScope: snapshot.request.playerScope
                        )
                    }
                    .accessibilityAddTraits(.isButton)
                    #endif
                }
            }
        } else {
            GameCenterEmptyStateView(
                title: "랭킹 없음",
                systemImage: "trophy",
                message: nil
            )
        }
    }

    private var skeleton: some View {
        ShimmerLoadingUI.Container(configuration: materialTheme.gameCenterShimmerConfiguration) {
            LazyVStack(spacing: 2) {
                ForEach(0 ..< 8, id: \.self) { _ in
                    GameCenterLeaderboardSkeletonRow()
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func isLocalPlayer(_ entry: GameCenterLeaderboardEntry, in snapshot: GameCenterLeaderboardSnapshot) -> Bool {
        if let localPlayerEntry = snapshot.localPlayerEntry {
            return entry.gamePlayerID == localPlayerEntry.gamePlayerID
        }

        return entry.gamePlayerID == model.player?.gamePlayerID
    }

    private struct RefreshKey: Equatable {
        var selectedCategoryID: String
        var rankingScope: GameCenterRankingScope
        var playerScope: GameCenterPlayerScope
    }
}

private struct GameCenterLeaderboardSkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            ShimmerLoadingUI.Block(.circle)
                .frame(width: 30, height: 30)

            ShimmerLoadingUI.Block(.capsule)
                .frame(width: 132, height: 16)

            Spacer(minLength: 8)

            ShimmerLoadingUI.Block(.capsule)
                .frame(width: 58, height: 16)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}
