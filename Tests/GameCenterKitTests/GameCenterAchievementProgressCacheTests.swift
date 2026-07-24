import XCTest
@testable import GameCenterKit

final class GameCenterAchievementProgressCacheTests: XCTestCase {
    func testStoreCoalescesConcurrentLoadsAndUsesCachedResult() async throws {
        let achievements = [
            GameCenterAchievementProgress(
                id: "achievement.score-100",
                percentComplete: 100,
                isCompleted: true
            ),
        ]
        let client = CountingAchievementClient(
            achievements: achievements,
            delayNanoseconds: 50_000_000
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)

        async let firstLoad = store.load(playerID: "player-a", using: client)
        async let secondLoad = store.load(playerID: "player-a", using: client)

        let firstAchievements = try await firstLoad
        let secondAchievements = try await secondLoad

        XCTAssertEqual(firstAchievements, achievements)
        XCTAssertEqual(secondAchievements, achievements)
        let concurrentLoadCallCount = await client.loadCallCount()
        XCTAssertEqual(concurrentLoadCallCount, 1)

        _ = try await store.load(playerID: "player-a", using: client)

        let cachedLoadCallCount = await client.loadCallCount()
        XCTAssertEqual(cachedLoadCallCount, 1)

        await store.invalidate(playerID: "player-a")
        _ = try await store.load(playerID: "player-a", using: client)

        let invalidatedLoadCallCount = await client.loadCallCount()
        XCTAssertEqual(invalidatedLoadCallCount, 2)
    }

    func testStoreAllowsRetryAfterTransientLoadFailure() async throws {
        let achievements = [
            GameCenterAchievementProgress(
                id: "achievement.score-100",
                percentComplete: 0,
                isCompleted: false
            ),
        ]
        let client = CountingAchievementClient(
            achievements: achievements,
            failuresBeforeSuccess: 1
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)

        do {
            _ = try await store.load(playerID: "player-a", using: client)
            XCTFail("Expected the first load to fail")
        } catch AchievementLoadError.failed {
        }

        let retriedAchievements = try await store.load(playerID: "player-a", using: client)

        XCTAssertEqual(retriedAchievements, achievements)
        let loadCallCount = await client.loadCallCount()
        XCTAssertEqual(loadCallCount, 2)
    }

    func testInvalidatePreventsInFlightLoadFromRepopulatingCache() async throws {
        let loadStartedExpectation = expectation(description: "Achievement load started")
        let loadStarted = SendableExpectation(loadStartedExpectation)
        let achievements = [
            GameCenterAchievementProgress(
                id: "achievement.score-100",
                percentComplete: 100,
                isCompleted: true
            ),
        ]
        let client = CountingAchievementClient(
            achievements: achievements,
            delayNanoseconds: 50_000_000,
            ignoresCancellation: true,
            onFirstLoadStart: {
                loadStarted.fulfill()
            }
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)

        let inFlightLoad = Task {
            try await store.load(playerID: "player-a", using: client)
        }

        await fulfillment(of: [loadStartedExpectation], timeout: 1)

        let inFlightInvalidationChangedState = await store.invalidate(playerID: "player-a")
        let repeatedInvalidationChangedState = await store.invalidate(playerID: "player-a")

        XCTAssertTrue(inFlightInvalidationChangedState)
        XCTAssertFalse(repeatedInvalidationChangedState)

        do {
            _ = try await inFlightLoad.value
            XCTFail("Expected invalidated in-flight load to be cancelled")
        } catch is CancellationError {
        }

        _ = try await store.load(playerID: "player-a", using: client)

        let loadCallCount = await client.loadCallCount()
        XCTAssertEqual(loadCallCount, 2)
    }

    func testInvalidateTakesPrecedenceOverInFlightLoadFailure() async throws {
        let loadStartedExpectation = expectation(description: "Failing achievement load started")
        let loadStarted = SendableExpectation(loadStartedExpectation)
        let client = CountingAchievementClient(
            achievements: [],
            delayNanoseconds: 50_000_000,
            ignoresCancellation: true,
            failsAfterDelay: true,
            onFirstLoadStart: {
                loadStarted.fulfill()
            }
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)
        let inFlightLoad = Task {
            try await store.load(playerID: "player-a", using: client)
        }

        await fulfillment(of: [loadStartedExpectation], timeout: 1)

        await store.invalidate(playerID: "player-a")

        do {
            _ = try await inFlightLoad.value
            XCTFail("Expected invalidation to take precedence over the load failure")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testInvalidateSkipsRepeatedEmptyInvalidations() async throws {
        let client = CountingAchievementClient(achievements: [])
        let store = GameCenterAchievementProgressStore(ttl: 30)

        let initialInvalidationChangedState = await store.invalidate(playerID: "player-a")
        XCTAssertFalse(initialInvalidationChangedState)

        _ = try await store.load(playerID: "player-a", using: client)

        let cachedInvalidationChangedState = await store.invalidate(playerID: "player-a")
        let repeatedInvalidationChangedState = await store.invalidate(playerID: "player-a")

        XCTAssertTrue(cachedInvalidationChangedState)
        XCTAssertFalse(repeatedInvalidationChangedState)
    }

    func testMarkCompletedImmediatelyUpdatesCachedAchievement() async throws {
        let client = CountingAchievementClient(
            achievements: [
                GameCenterAchievementProgress(
                    id: "achievement.score-100",
                    percentComplete: 50,
                    isCompleted: false
                ),
            ]
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)
        _ = try await store.load(playerID: "player-a", using: client)

        await store.markCompleted("achievement.score-100", playerID: "player-a")
        let achievements = try await store.load(playerID: "player-a", using: client)

        XCTAssertEqual(achievements.first?.percentComplete, 100)
        XCTAssertEqual(achievements.first?.isCompleted, true)
        let loadCallCount = await client.loadCallCount()
        XCTAssertEqual(loadCallCount, 1)
    }

    func testMarkCompletedAddsMissingAchievementAndInvalidateClearsIt() async throws {
        let client = CountingAchievementClient(achievements: [])
        let store = GameCenterAchievementProgressStore(ttl: 30)
        _ = try await store.load(playerID: "player-a", using: client)

        await store.markCompleted("achievement.score-100", playerID: "player-a")
        let markedAchievements = try await store.load(playerID: "player-a", using: client)
        XCTAssertEqual(markedAchievements.map(\.id), ["achievement.score-100"])
        XCTAssertEqual(markedAchievements.first?.isCompleted, true)

        await store.invalidate(playerID: "player-a")
        let reloadedAchievements = try await store.load(playerID: "player-a", using: client)
        XCTAssertTrue(reloadedAchievements.isEmpty)
    }

    func testMarkCompletedDuringInFlightLoadIsMergedIntoResult() async throws {
        let loadStartedExpectation = expectation(description: "Achievement load started")
        let loadStarted = SendableExpectation(loadStartedExpectation)
        let client = CountingAchievementClient(
            achievements: [],
            delayNanoseconds: 50_000_000,
            onFirstLoadStart: {
                loadStarted.fulfill()
            }
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)
        let inFlightLoad = Task {
            try await store.load(playerID: "player-a", using: client)
        }

        await fulfillment(of: [loadStartedExpectation], timeout: 1)
        let coalescedLoad = Task {
            try await store.load(playerID: "player-a", using: client)
        }
        await Task.yield()
        await store.markCompleted("achievement.score-100", playerID: "player-a")
        let achievements = try await inFlightLoad.value
        let coalescedAchievements = try await coalescedLoad.value

        XCTAssertEqual(achievements.map(\.id), ["achievement.score-100"])
        XCTAssertEqual(achievements.first?.isCompleted, true)
        XCTAssertEqual(coalescedAchievements.map(\.id), ["achievement.score-100"])
        XCTAssertEqual(coalescedAchievements.first?.isCompleted, true)
        let loadCallCount = await client.loadCallCount()
        XCTAssertEqual(loadCallCount, 1)
    }

    func testStoreKeepsCachedAndLocallyCompletedAchievementsSeparateByPlayer() async throws {
        let playerAClient = CountingAchievementClient(
            achievements: [
                GameCenterAchievementProgress(
                    id: "achievement.player-a",
                    percentComplete: 100,
                    isCompleted: true
                ),
            ]
        )
        let playerBClient = CountingAchievementClient(achievements: [])
        let store = GameCenterAchievementProgressStore(ttl: 30)

        _ = try await store.load(playerID: "player-a", using: playerAClient)
        _ = try await store.load(playerID: "player-b", using: playerBClient)
        await store.markCompleted("achievement.local-a", playerID: "player-a")

        let playerAAchievements = try await store.load(playerID: "player-a", using: playerAClient)
        let playerBAchievements = try await store.load(playerID: "player-b", using: playerBClient)

        XCTAssertEqual(
            Set(playerAAchievements.map(\.id)),
            ["achievement.player-a", "achievement.local-a"]
        )
        XCTAssertTrue(playerBAchievements.isEmpty)
    }

    func testReportStoreCoalescesSameAchievementForSamePlayer() async throws {
        let store = GameCenterAchievementReportStore()
        let client = CountingReportAchievementClient(delayNanoseconds: 50_000_000)
        let authenticationClient = AuthenticatedPlayerClient(playerID: "player-a")
        let report = GameCenterAchievementReport(
            achievementID: "achievement.score-100",
            percentComplete: 100,
            showsCompletionBanner: true
        )

        async let firstResult = store.report(
            playerID: "player-a",
            report: report,
            authenticationClient: authenticationClient,
            achievementClient: client
        )
        async let secondResult = store.report(
            playerID: "player-a",
            report: report,
            authenticationClient: authenticationClient,
            achievementClient: client
        )

        let results = try await [firstResult, secondResult]
        let reportedCount = results.reduce(into: 0) { count, result in
            if case .reported = result {
                count += 1
            }
        }
        let joinedCount = results.reduce(into: 0) { count, result in
            if case .joinedExistingReport = result {
                count += 1
            }
        }

        XCTAssertEqual(reportedCount, 1)
        XCTAssertEqual(joinedCount, 1)
        let reportCallCount = await client.reportCallCount()
        XCTAssertEqual(reportCallCount, 1)

        let repeatedResult = try await store.report(
            playerID: "player-a",
            report: report,
            authenticationClient: authenticationClient,
            achievementClient: client
        )
        if case .alreadyReported = repeatedResult {
        } else {
            XCTFail("Expected completed reports to stay coalesced")
        }
        let repeatedReportCallCount = await client.reportCallCount()
        XCTAssertEqual(repeatedReportCallCount, 1)
    }

    func testReportStoreInvalidationRejectsCancellationIgnoringCompletion() async throws {
        let reportStartedExpectation = expectation(description: "Achievement report started")
        let reportStarted = SendableExpectation(reportStartedExpectation)
        let store = GameCenterAchievementReportStore()
        let client = ControlledReportAchievementClient(
            onFirstReportStart: {
                reportStarted.fulfill()
            }
        )
        let authenticationClient = AuthenticatedPlayerClient(playerID: "player-a")
        let report = GameCenterAchievementReport(
            achievementID: "achievement.score-100",
            percentComplete: 100,
            showsCompletionBanner: true
        )

        let invalidatedReport = Task {
            try await store.report(
                playerID: "player-a",
                report: report,
                authenticationClient: authenticationClient,
                achievementClient: client
            )
        }
        await fulfillment(of: [reportStartedExpectation], timeout: 1)

        await store.invalidate(playerID: "player-a")
        await client.resumeFirstReport()

        do {
            _ = try await invalidatedReport.value
            XCTFail("Expected the invalidated report to be rejected")
        } catch is CancellationError {
        }

        let retriedResult = try await store.report(
            playerID: "player-a",
            report: report,
            authenticationClient: authenticationClient,
            achievementClient: client
        )
        if case .reported = retriedResult {
        } else {
            XCTFail("Expected a new report after invalidation")
        }
        let reportCallCount = await client.reportCallCount()
        XCTAssertEqual(reportCallCount, 2)
    }

    func testReportStoreResetWaitsForCancellationIgnoringReport() async throws {
        let reportStartedExpectation = expectation(description: "Achievement report started")
        let reportStarted = SendableExpectation(reportStartedExpectation)
        let store = GameCenterAchievementReportStore()
        let client = ControlledReportAchievementClient(
            onFirstReportStart: {
                reportStarted.fulfill()
            }
        )
        let authenticationClient = AuthenticatedPlayerClient(playerID: "player-a")
        let report = GameCenterAchievementReport(
            achievementID: "achievement.score-100",
            percentComplete: 100,
            showsCompletionBanner: true
        )

        let inFlightReport = Task {
            try await store.report(
                playerID: "player-a",
                report: report,
                authenticationClient: authenticationClient,
                achievementClient: client
            )
        }
        await fulfillment(of: [reportStartedExpectation], timeout: 1)

        let resetTask = Task {
            try await store.resetAchievements(using: client)
        }
        try await Task.sleep(nanoseconds: 20_000_000)
        let resetCountBeforeReportCompletion = await client.resetCallCount()
        XCTAssertEqual(resetCountBeforeReportCompletion, 0)

        await client.resumeFirstReport()
        try await resetTask.value

        do {
            _ = try await inFlightReport.value
            XCTFail("Expected the report invalidated by reset to be rejected")
        } catch is CancellationError {
        }

        let operationEvents = await client.operationEvents()
        XCTAssertEqual(operationEvents, [.reportStarted, .reportCompleted, .reset])

        let retriedResult = try await store.report(
            playerID: "player-a",
            report: report,
            authenticationClient: authenticationClient,
            achievementClient: client
        )
        if case .reported = retriedResult {
        } else {
            XCTFail("Expected a new report after achievement reset")
        }
        let reportCallCount = await client.reportCallCount()
        XCTAssertEqual(reportCallCount, 2)
    }

    func testAchievementSyncRejectsCancelledOrStaleResults() async {
        let playerASyncID = AchievementSyncID(
            achievementID: "achievement.score-100",
            isAuthenticated: true,
            authenticatedPlayerID: "player-a",
            syncTrigger: 0
        )
        let playerBSyncID = AchievementSyncID(
            achievementID: "achievement.score-100",
            isAuthenticated: true,
            authenticatedPlayerID: "player-b",
            syncTrigger: 0
        )

        XCTAssertFalse(
            canApplyAchievementSyncResult(
                expectedSyncID: playerASyncID,
                currentSyncID: playerBSyncID,
                expectedGeneration: 1,
                currentGeneration: 2
            )
        )
        XCTAssertFalse(
            canApplyAchievementSyncResult(
                expectedSyncID: playerBSyncID,
                currentSyncID: playerBSyncID,
                expectedGeneration: 1,
                currentGeneration: 2
            )
        )

        let cancelledResult = await Task {
            withUnsafeCurrentTask { task in
                task?.cancel()
            }
            return canApplyAchievementSyncResult(
                expectedSyncID: playerBSyncID,
                currentSyncID: playerBSyncID,
                expectedGeneration: 2,
                currentGeneration: 2
            )
        }.value
        XCTAssertFalse(cancelledResult)

        XCTAssertTrue(
            canApplyAchievementSyncResult(
                expectedSyncID: playerBSyncID,
                currentSyncID: playerBSyncID,
                expectedGeneration: 2,
                currentGeneration: 2
            )
        )
    }

    func testAchievementSyncRetryClearsFailureAndChangesTaskIdentity() {
        var retryState = AchievementSyncRetryState()
        retryState.fail(with: "Temporary failure")

        let failedSyncID = AchievementSyncID(
            achievementID: "achievement.score-100",
            isAuthenticated: true,
            authenticatedPlayerID: "player-a",
            syncTrigger: 0,
            retryTrigger: retryState.retryTrigger
        )
        XCTAssertTrue(retryState.canRetry)

        retryState.retry()

        let retriedSyncID = AchievementSyncID(
            achievementID: "achievement.score-100",
            isAuthenticated: true,
            authenticatedPlayerID: "player-a",
            syncTrigger: 0,
            retryTrigger: retryState.retryTrigger
        )
        XCTAssertFalse(retryState.canRetry)
        XCTAssertNotEqual(retriedSyncID, failedSyncID)
    }

    func testAchievementReportErrorIsScopedAndClearedBySuccessfulSync() {
        let playerASyncID = AchievementSyncID(
            achievementID: "achievement.score-100",
            isAuthenticated: true,
            authenticatedPlayerID: "player-a",
            syncTrigger: 0
        )
        let playerBSyncID = AchievementSyncID(
            achievementID: "achievement.score-100",
            isAuthenticated: true,
            authenticatedPlayerID: "player-b",
            syncTrigger: 0
        )
        var errorState = AchievementReportErrorState()

        errorState.fail(with: "Temporary failure", syncID: playerASyncID)

        XCTAssertEqual(errorState.message(for: playerASyncID), "Temporary failure")
        XCTAssertNil(errorState.message(for: playerBSyncID))

        errorState.clear(ifMatching: playerBSyncID)
        XCTAssertEqual(errorState.message(for: playerASyncID), "Temporary failure")

        errorState.clear(ifMatching: playerASyncID)
        XCTAssertNil(errorState.message(for: playerASyncID))
    }
}

private actor CountingAchievementClient: GameCenterAchievementClientProtocol {
    private let achievements: [GameCenterAchievementProgress]
    private let delayNanoseconds: UInt64
    private let ignoresCancellation: Bool
    private let failsAfterDelay: Bool
    private let onFirstLoadStart: @Sendable () -> Void
    private var remainingFailures: Int
    private var loadCount = 0

    init(
        achievements: [GameCenterAchievementProgress],
        delayNanoseconds: UInt64 = 0,
        ignoresCancellation: Bool = false,
        failsAfterDelay: Bool = false,
        failuresBeforeSuccess: Int = 0,
        onFirstLoadStart: @escaping @Sendable () -> Void = {}
    ) {
        self.achievements = achievements
        self.delayNanoseconds = delayNanoseconds
        self.ignoresCancellation = ignoresCancellation
        self.failsAfterDelay = failsAfterDelay
        self.remainingFailures = max(0, failuresBeforeSuccess)
        self.onFirstLoadStart = onFirstLoadStart
    }

    func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        loadCount += 1
        if loadCount == 1 {
            onFirstLoadStart()
        }

        if delayNanoseconds > 0 {
            do {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            } catch is CancellationError where ignoresCancellation {
            }
        }

        if failsAfterDelay || remainingFailures > 0 {
            remainingFailures = max(0, remainingFailures - 1)
            throw AchievementLoadError.failed
        }

        return achievements
    }

    func reportAchievement(_ report: GameCenterAchievementReport) async throws {}

    func resetAchievements() async throws {}

    func loadCallCount() -> Int {
        loadCount
    }
}

private enum AchievementLoadError: Error {
    case failed
}

private struct AuthenticatedPlayerClient: GameCenterAuthenticationClientProtocol {
    let playerID: String

    @MainActor
    var isAuthenticated: Bool { true }

    #if canImport(UIKit) || canImport(AppKit)
    @MainActor
    func authenticate(
        presenting presenter: GameCenterAuthenticationPresenter?
    ) async throws -> GameCenterPlayer {
        try await localPlayer()
    }
    #endif

    @MainActor
    func localPlayer() async throws -> GameCenterPlayer {
        GameCenterPlayer(
            gamePlayerID: playerID,
            teamPlayerID: "\(playerID)-team",
            displayName: playerID,
            isAuthenticated: true
        )
    }
}

private actor CountingReportAchievementClient: GameCenterAchievementClientProtocol {
    private let delayNanoseconds: UInt64
    private var reportCount = 0

    init(delayNanoseconds: UInt64) {
        self.delayNanoseconds = delayNanoseconds
    }

    func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        []
    }

    func reportAchievement(_ report: GameCenterAchievementReport) async throws {
        reportCount += 1
        try await Task.sleep(nanoseconds: delayNanoseconds)
    }

    func resetAchievements() async throws {}

    func reportCallCount() -> Int {
        reportCount
    }
}

private actor ControlledReportAchievementClient: GameCenterAchievementClientProtocol {
    enum OperationEvent: Equatable {
        case reportStarted
        case reportCompleted
        case reset
    }

    private let onFirstReportStart: @Sendable () -> Void
    private var firstReportContinuation: CheckedContinuation<Void, Never>?
    private var reportCount = 0
    private var resetCount = 0
    private var events: [OperationEvent] = []

    init(onFirstReportStart: @escaping @Sendable () -> Void) {
        self.onFirstReportStart = onFirstReportStart
    }

    func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        []
    }

    func reportAchievement(_ report: GameCenterAchievementReport) async throws {
        reportCount += 1
        guard reportCount == 1 else { return }

        events.append(.reportStarted)
        onFirstReportStart()
        await withCheckedContinuation { continuation in
            firstReportContinuation = continuation
        }
        events.append(.reportCompleted)
    }

    func resetAchievements() async throws {
        resetCount += 1
        events.append(.reset)
    }

    func resumeFirstReport() {
        firstReportContinuation?.resume()
        firstReportContinuation = nil
    }

    func reportCallCount() -> Int {
        reportCount
    }

    func resetCallCount() -> Int {
        resetCount
    }

    func operationEvents() -> [OperationEvent] {
        events
    }
}

private final class SendableExpectation: @unchecked Sendable {
    private let expectation: XCTestExpectation

    init(_ expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func fulfill() {
        expectation.fulfill()
    }
}
