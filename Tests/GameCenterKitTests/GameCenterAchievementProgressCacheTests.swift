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
            try await store.load(using: client)
        }

        await fulfillment(of: [loadStartedExpectation], timeout: 1)

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
            try await store.load(using: client)
        }

        await fulfillment(of: [loadStartedExpectation], timeout: 1)

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
    private let achievements: [GameCenterAchievementProgress]
    private let delayNanoseconds: UInt64
    private let ignoresCancellation: Bool
    private let failsAfterDelay: Bool
    private let onFirstLoadStart: @Sendable () -> Void
    private var loadCount = 0

    init(
        achievements: [GameCenterAchievementProgress],
        delayNanoseconds: UInt64 = 0,
        ignoresCancellation: Bool = false,
        failsAfterDelay: Bool = false,
        onFirstLoadStart: @escaping @Sendable () -> Void = {}
    ) {
        self.achievements = achievements
        self.delayNanoseconds = delayNanoseconds
        self.ignoresCancellation = ignoresCancellation
        self.failsAfterDelay = failsAfterDelay
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
}

private enum AchievementLoadError: Error {
    case failed
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
