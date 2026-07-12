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

        async let firstLoad = store.load(using: client)
        async let secondLoad = store.load(using: client)

        let firstAchievements = try await firstLoad
        let secondAchievements = try await secondLoad

        XCTAssertEqual(firstAchievements, achievements)
        XCTAssertEqual(secondAchievements, achievements)
        let concurrentLoadCallCount = await client.loadCallCount()
        XCTAssertEqual(concurrentLoadCallCount, 1)

        _ = try await store.load(using: client)

        let cachedLoadCallCount = await client.loadCallCount()
        XCTAssertEqual(cachedLoadCallCount, 1)

        await store.invalidate()
        _ = try await store.load(using: client)

        let invalidatedLoadCallCount = await client.loadCallCount()
        XCTAssertEqual(invalidatedLoadCallCount, 2)
    }

    func testInvalidatePreventsInFlightLoadFromRepopulatingCache() async throws {
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
            ignoresCancellation: true
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)

        let inFlightLoad = Task {
            try await store.load(using: client)
        }

        await client.waitForLoadCallCount(1)

        let inFlightInvalidationChangedState = await store.invalidate()
        let repeatedInvalidationChangedState = await store.invalidate()

        XCTAssertTrue(inFlightInvalidationChangedState)
        XCTAssertFalse(repeatedInvalidationChangedState)

        do {
            _ = try await inFlightLoad.value
            XCTFail("Expected invalidated in-flight load to be cancelled")
        } catch is CancellationError {
        }

        _ = try await store.load(using: client)

        let loadCallCount = await client.loadCallCount()
        XCTAssertEqual(loadCallCount, 2)
    }

    func testInvalidateTakesPrecedenceOverInFlightLoadFailure() async throws {
        let client = CountingAchievementClient(
            achievements: [],
            delayNanoseconds: 50_000_000,
            ignoresCancellation: true,
            failsAfterDelay: true
        )
        let store = GameCenterAchievementProgressStore(ttl: 30)
        let inFlightLoad = Task {
            try await store.load(using: client)
        }

        await client.waitForLoadCallCount(1)

        await store.invalidate()

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

        let initialInvalidationChangedState = await store.invalidate()
        XCTAssertFalse(initialInvalidationChangedState)

        _ = try await store.load(using: client)

        let cachedInvalidationChangedState = await store.invalidate()
        let repeatedInvalidationChangedState = await store.invalidate()

        XCTAssertTrue(cachedInvalidationChangedState)
        XCTAssertFalse(repeatedInvalidationChangedState)
    }
}

private actor CountingAchievementClient: GameCenterAchievementClientProtocol {
    private struct LoadCountWaiter {
        var expectedCount: Int
        var continuation: CheckedContinuation<Void, Never>
    }

    private let achievements: [GameCenterAchievementProgress]
    private let delayNanoseconds: UInt64
    private let ignoresCancellation: Bool
    private let failsAfterDelay: Bool
    private var loadCount = 0
    private var loadCountWaiters: [LoadCountWaiter] = []

    init(
        achievements: [GameCenterAchievementProgress],
        delayNanoseconds: UInt64 = 0,
        ignoresCancellation: Bool = false,
        failsAfterDelay: Bool = false
    ) {
        self.achievements = achievements
        self.delayNanoseconds = delayNanoseconds
        self.ignoresCancellation = ignoresCancellation
        self.failsAfterDelay = failsAfterDelay
    }

    func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        loadCount += 1
        resumeLoadCountWaiters()

        if delayNanoseconds > 0 {
            do {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            } catch is CancellationError where ignoresCancellation {
            }
        }

        if failsAfterDelay {
            throw AchievementLoadError.failed
        }

        return achievements
    }

    func reportAchievement(_ report: GameCenterAchievementReport) async throws {}

    func resetAchievements() async throws {}

    func loadCallCount() -> Int {
        loadCount
    }

    func waitForLoadCallCount(_ expectedCount: Int) async {
        guard loadCount < expectedCount else {
            return
        }

        await withCheckedContinuation { continuation in
            loadCountWaiters.append(
                LoadCountWaiter(
                    expectedCount: expectedCount,
                    continuation: continuation
                )
            )
        }
    }

    private func resumeLoadCountWaiters() {
        var pendingWaiters: [LoadCountWaiter] = []

        for waiter in loadCountWaiters {
            if loadCount >= waiter.expectedCount {
                waiter.continuation.resume()
            } else {
                pendingWaiters.append(waiter)
            }
        }

        loadCountWaiters = pendingWaiters
    }
}

private enum AchievementLoadError: Error {
    case failed
}
