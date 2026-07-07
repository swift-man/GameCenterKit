import SwiftUI

struct GameCenterLeaderboardSection: View {
    @ObservedObject var model: GameCenterDashboardViewModel
    var showsPlayerScopePicker: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            rankingPicker

            if showsPlayerScopePicker {
                playerScopePicker
            }

            content
        }
        .task(id: refreshKey) {
            await model.refresh()
        }
    }

    private var refreshKey: RefreshKey {
        RefreshKey(rankingScope: model.selectedScope, playerScope: model.playerScope)
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
        LazyVStack(spacing: 2) {
            ForEach(0 ..< 8, id: \.self) { _ in
                GameCenterLeaderboardRow(entry: .redactedPlaceholder, isLocalPlayer: false)
            }
        }
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private func isLocalPlayer(_ entry: GameCenterLeaderboardEntry, in snapshot: GameCenterLeaderboardSnapshot) -> Bool {
        if let localPlayerEntry = snapshot.localPlayerEntry {
            return entry.gamePlayerID == localPlayerEntry.gamePlayerID
        }

        return entry.gamePlayerID == model.player?.gamePlayerID
    }

    private struct RefreshKey: Equatable {
        var rankingScope: GameCenterRankingScope
        var playerScope: GameCenterPlayerScope
    }
}

extension GameCenterLeaderboardEntry {
    static let redactedPlaceholder = GameCenterLeaderboardEntry(
        id: "placeholder",
        rank: 8,
        score: 0,
        formattedScore: "0,000",
        displayName: "Player Name",
        gamePlayerID: "placeholder"
    )
}
