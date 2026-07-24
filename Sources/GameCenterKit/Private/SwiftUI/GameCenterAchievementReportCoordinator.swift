//
//  GameCenterAchievementReportCoordinator.swift
//  GameCenterKit
//
//  Created by gorani. on 2026/07/25.
//

import Foundation

enum GameCenterAchievementReportResult: Sendable {
    case reported
    case joinedExistingReport
    case alreadyReported
}

struct GameCenterAchievementReportCoordinator: Sendable {
    var report: @Sendable (
        String,
        GameCenterAchievementReport,
        any GameCenterAuthenticationClientProtocol,
        any GameCenterAchievementClientProtocol
    ) async throws -> GameCenterAchievementReportResult
    var invalidate: @Sendable (String?) async -> Void
}

extension GameCenterAchievementReportCoordinator {
    static let live: Self = {
        let store = GameCenterAchievementReportStore()
        return Self(
            report: { playerID, report, authenticationClient, achievementClient in
                try await store.report(
                    playerID: playerID,
                    report: report,
                    authenticationClient: authenticationClient,
                    achievementClient: achievementClient
                )
            },
            invalidate: { playerID in
                await store.invalidate(playerID: playerID)
            }
        )
    }()

    static let passthrough = Self(
        report: { _, report, _, achievementClient in
            try await achievementClient.reportAchievement(report)
            return .reported
        },
        invalidate: { _ in }
    )
}

actor GameCenterAchievementReportStore {
    private struct ReportKey: Hashable {
        var playerID: String
        var achievementID: String
    }

    private struct InvalidationContext: Equatable {
        var globalToken: UUID
        var playerToken: UUID?
    }

    private struct InFlightReport {
        var id: UUID
        var invalidationContext: InvalidationContext
        var task: Task<Void, Error>
    }

    private var inFlightReports: [ReportKey: InFlightReport] = [:]
    private var completedReportKeys: Set<ReportKey> = []
    private var globalInvalidationToken = UUID()
    private var playerInvalidationTokens: [String: UUID] = [:]

    func report(
        playerID: String,
        report: GameCenterAchievementReport,
        authenticationClient: any GameCenterAuthenticationClientProtocol,
        achievementClient: any GameCenterAchievementClientProtocol
    ) async throws -> GameCenterAchievementReportResult {
        let key = ReportKey(playerID: playerID, achievementID: report.achievementID)
        guard !completedReportKeys.contains(key) else {
            return .alreadyReported
        }

        if let inFlightReport = inFlightReports[key] {
            try await inFlightReport.task.value
            guard isCurrent(
                inFlightReport.invalidationContext,
                playerID: playerID
            ) else {
                throw CancellationError()
            }
            return .joinedExistingReport
        }

        let reportID = UUID()
        let invalidationContext = invalidationContext(for: playerID)
        let task = Task {
            guard await authenticationClient.isAuthenticated,
                  let localPlayer = try? await authenticationClient.localPlayer(),
                  localPlayer.gamePlayerID == playerID
            else {
                throw GameCenterClientError.notAuthenticated
            }

            try Task.checkCancellation()
            try await achievementClient.reportAchievement(report)
        }
        inFlightReports[key] = InFlightReport(
            id: reportID,
            invalidationContext: invalidationContext,
            task: task
        )

        do {
            try await task.value
            guard isCurrent(invalidationContext, playerID: playerID),
                  inFlightReports[key]?.id == reportID
            else {
                throw CancellationError()
            }
            completedReportKeys.insert(key)
            removeReport(key: key, id: reportID)
            return .reported
        } catch {
            removeReport(key: key, id: reportID)
            throw error
        }
    }

    func invalidate(playerID: String?) {
        guard let playerID else {
            globalInvalidationToken = UUID()
            playerInvalidationTokens.removeAll()
            inFlightReports.values.forEach { $0.task.cancel() }
            inFlightReports.removeAll()
            completedReportKeys.removeAll()
            return
        }

        playerInvalidationTokens[playerID] = UUID()
        let matchingKeys = inFlightReports.keys.filter { $0.playerID == playerID }
        for key in matchingKeys {
            inFlightReports[key]?.task.cancel()
            inFlightReports[key] = nil
        }
        completedReportKeys = Set(
            completedReportKeys.filter { $0.playerID != playerID }
        )
    }

    private func invalidationContext(for playerID: String) -> InvalidationContext {
        InvalidationContext(
            globalToken: globalInvalidationToken,
            playerToken: playerInvalidationTokens[playerID]
        )
    }

    private func isCurrent(
        _ context: InvalidationContext,
        playerID: String
    ) -> Bool {
        context == invalidationContext(for: playerID)
    }

    private func removeReport(key: ReportKey, id: UUID) {
        guard inFlightReports[key]?.id == id else { return }
        inFlightReports[key] = nil
    }
}
