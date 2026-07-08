import Foundation

struct GameCenterAchievementProgressCache: Sendable {
    var load: @Sendable (any GameCenterAchievementClientProtocol) async throws -> [GameCenterAchievementProgress]
    var invalidate: @Sendable () async -> Void
}

extension GameCenterAchievementProgressCache {
    static let live: Self = {
        let store = GameCenterAchievementProgressStore()
        return Self(
            load: { client in
                try await store.load(using: client)
            },
            invalidate: {
                await store.invalidate()
            }
        )
    }()

    static let passthrough = Self(
        load: { client in
            try await client.loadAchievements()
        },
        invalidate: {}
    )
}

actor GameCenterAchievementProgressStore {
    private struct CacheEntry {
        var achievements: [GameCenterAchievementProgress]
        var expiresAt: Date
    }

    private let ttl: TimeInterval
    private var cacheEntry: CacheEntry?
    private var inFlightTask: Task<[GameCenterAchievementProgress], Error>?

    init(ttl: TimeInterval = 3) {
        self.ttl = ttl
    }

    func load(using client: any GameCenterAchievementClientProtocol) async throws -> [GameCenterAchievementProgress] {
        let now = Date()
        if let cacheEntry, cacheEntry.expiresAt > now {
            return cacheEntry.achievements
        }

        if let inFlightTask {
            return try await inFlightTask.value
        }

        let task = Task {
            try await client.loadAchievements()
        }
        inFlightTask = task

        do {
            let achievements = try await task.value
            cacheEntry = CacheEntry(
                achievements: achievements,
                expiresAt: Date().addingTimeInterval(ttl)
            )
            inFlightTask = nil
            return achievements
        } catch {
            inFlightTask = nil
            throw error
        }
    }

    func invalidate() {
        cacheEntry = nil
    }
}
