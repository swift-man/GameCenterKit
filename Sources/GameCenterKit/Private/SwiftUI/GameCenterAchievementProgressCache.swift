import Foundation

struct GameCenterAchievementProgressCache: Sendable {
    var load: @Sendable (any GameCenterAchievementClientProtocol) async throws -> [GameCenterAchievementProgress]
    var markCompleted: @Sendable (String) async -> Void
    var invalidate: @Sendable () async -> Void
}

extension GameCenterAchievementProgressCache {
    static let live: Self = {
        let store = GameCenterAchievementProgressStore()
        return Self(
            load: { client in
                try await store.load(using: client)
            },
            markCompleted: { achievementID in
                await store.markCompleted(achievementID)
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
        markCompleted: { _ in },
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
    private var locallyCompletedAchievementIDs: Set<String> = []

    init(ttl: TimeInterval = 3) {
        self.ttl = ttl
    }

    func load(using client: any GameCenterAchievementClientProtocol) async throws -> [GameCenterAchievementProgress] {
        let now = Date()
        if let cacheEntry, cacheEntry.expiresAt > now {
            return mergingLocallyCompletedAchievements(into: cacheEntry.achievements)
        }

        if let inFlightLoad {
            return mergingLocallyCompletedAchievements(
                into: try await achievements(from: inFlightLoad)
            )
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
            let achievements = mergingLocallyCompletedAchievements(
                into: try await achievements(from: inFlightLoad)
            )
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
        guard cacheEntry != nil || inFlightLoad != nil || !locallyCompletedAchievementIDs.isEmpty else {
            return false
        }

        invalidationGeneration += 1
        cacheEntry = nil
        locallyCompletedAchievementIDs.removeAll()
        inFlightLoad?.task.cancel()
        inFlightLoad = nil
        return true
    }

    func markCompleted(_ achievementID: String) {
        locallyCompletedAchievementIDs.insert(achievementID)
        guard var cacheEntry else { return }

        cacheEntry.achievements = mergingLocallyCompletedAchievements(
            into: cacheEntry.achievements
        )
        self.cacheEntry = cacheEntry
    }

    private func achievements(from inFlightLoad: InFlightLoad) async throws -> [GameCenterAchievementProgress] {
        let result = await inFlightLoad.task.result
        guard inFlightLoad.generation == invalidationGeneration else {
            throw CancellationError()
        }

        return try result.get()
    }

    private func mergingLocallyCompletedAchievements(
        into achievements: [GameCenterAchievementProgress]
    ) -> [GameCenterAchievementProgress] {
        var mergedAchievements = achievements
        var existingIDs = Set(achievements.map(\.id))

        for index in mergedAchievements.indices
        where locallyCompletedAchievementIDs.contains(mergedAchievements[index].id) {
            mergedAchievements[index].percentComplete = 100
            mergedAchievements[index].isCompleted = true
        }

        for achievementID in locallyCompletedAchievementIDs
        where existingIDs.insert(achievementID).inserted {
            mergedAchievements.append(
                GameCenterAchievementProgress(
                    id: achievementID,
                    percentComplete: 100,
                    isCompleted: true
                )
            )
        }

        return mergedAchievements
    }
}
