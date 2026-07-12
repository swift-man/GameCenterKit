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
                _ = await store.invalidate()
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

    private struct InFlightLoad {
        var id: Int
        var generation: Int
        var task: Task<[GameCenterAchievementProgress], Error>
    }

    private let ttl: TimeInterval
    private var cacheEntry: CacheEntry?
    private var inFlightLoad: InFlightLoad?
    private var nextLoadID = 0
    private var invalidationGeneration = 0

    init(ttl: TimeInterval = 3) {
        self.ttl = ttl
    }

    func load(using client: any GameCenterAchievementClientProtocol) async throws -> [GameCenterAchievementProgress] {
        let now = Date()
        if let cacheEntry, cacheEntry.expiresAt > now {
            return cacheEntry.achievements
        }

        if let inFlightLoad {
            return try await achievements(from: inFlightLoad)
        }

        let generation = invalidationGeneration
        let loadID = nextLoadID
        nextLoadID += 1
        let task = Task {
            try await client.loadAchievements()
        }
        let inFlightLoad = InFlightLoad(
            id: loadID,
            generation: generation,
            task: task
        )
        self.inFlightLoad = inFlightLoad

        do {
            let achievements = try await achievements(from: inFlightLoad)
            if self.inFlightLoad?.id == loadID {
                cacheEntry = CacheEntry(
                    achievements: achievements,
                    expiresAt: Date().addingTimeInterval(ttl)
                )
                self.inFlightLoad = nil
            }
            return achievements
        } catch {
            if self.inFlightLoad?.id == loadID {
                self.inFlightLoad = nil
            }
            throw error
        }
    }

    @discardableResult
    func invalidate() -> Bool {
        guard cacheEntry != nil || inFlightLoad != nil else {
            return false
        }

        invalidationGeneration += 1
        cacheEntry = nil
        inFlightLoad?.task.cancel()
        inFlightLoad = nil
        return true
    }

    private func achievements(from inFlightLoad: InFlightLoad) async throws -> [GameCenterAchievementProgress] {
        let achievements = try await inFlightLoad.task.value
        guard inFlightLoad.generation == invalidationGeneration else {
            throw CancellationError()
        }

        return achievements
    }
}
