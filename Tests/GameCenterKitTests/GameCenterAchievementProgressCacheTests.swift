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

        while await client.loadCallCount() == 0 {
            try await Task.sleep(nanoseconds: 1_000_000)
        }

        await store.invalidate()

        do {
            _ = try await inFlightLoad.value
            XCTFail("Expected invalidated in-flight load to be cancelled")
        } catch is CancellationError {
        }

        _ = try await store.load(using: client)

        let loadCallCount = await client.loadCallCount()
        XCTAssertEqual(loadCallCount, 2)
    }
}

private actor CountingAchievementClient: GameCenterAchievementClientProtocol {
    private let achievements: [GameCenterAchievementProgress]
    private let delayNanoseconds: UInt64
    private let ignoresCancellation: Bool
    private var loadCount = 0

    init(
        achievements: [GameCenterAchievementProgress],
        delayNanoseconds: UInt64 = 0,
        ignoresCancellation: Bool = false
    ) {
        self.achievements = achievements
        self.delayNanoseconds = delayNanoseconds
        self.ignoresCancellation = ignoresCancellation
    }

    func loadAchievements() async throws -> [GameCenterAchievementProgress] {
        loadCount += 1

        if delayNanoseconds > 0 {
            do {
                try await Task.sleep(nanoseconds: delayNanoseconds)
            } catch is CancellationError where ignoresCancellation {
            }
        }

        return achievements
    }

    func reportAchievement(_ report: GameCenterAchievementReport) async throws {}

    func resetAchievements() async throws {}

    func loadCallCount() -> Int {
        loadCount
    }
}
