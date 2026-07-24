import Foundation

struct GameCenterAchievementProgressCache: Sendable {
    var load: @Sendable (String, any GameCenterAchievementClientProtocol) async throws -> [GameCenterAchievementProgress]
    var markCompleted: @Sendable (String, String) async -> Void
    var invalidate: @Sendable (String?) async -> Void
}

extension GameCenterAchievementProgressCache {
    static let live: Self = {
        let store = GameCenterAchievementProgressStore()
        return Self(
            load: { playerID, client in
                try await store.load(playerID: playerID, using: client)
            },
            markCompleted: { playerID, achievementID in
                await store.markCompleted(achievementID, playerID: playerID)
            },
            invalidate: { playerID in
                _ = await store.invalidate(playerID: playerID)
            }
        )
    }()

    static let passthrough = Self(
        load: { _, client in
            try await client.loadAchievements()
        },
        markCompleted: { _, _ in },
        invalidate: { _ in }
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
    private var cacheEntriesByPlayerID: [String: CacheEntry] = [:]
    private var inFlightLoadsByPlayerID: [String: InFlightLoad] = [:]
    private var nextLoadID = 0
    private var invalidationGenerationByPlayerID: [String: Int] = [:]
    private var locallyCompletedAchievementIDsByPlayerID: [String: Set<String>] = [:]

    init(ttl: TimeInterval = 3) {
        self.ttl = ttl
    }

    func load(
        playerID: String,
        using client: any GameCenterAchievementClientProtocol
    ) async throws -> [GameCenterAchievementProgress] {
        let now = Date()
        if let cacheEntry = cacheEntriesByPlayerID[playerID], cacheEntry.expiresAt > now {
            return mergingLocallyCompletedAchievements(
                into: cacheEntry.achievements,
                playerID: playerID
            )
        }

        if let inFlightLoad = inFlightLoadsByPlayerID[playerID] {
            return mergingLocallyCompletedAchievements(
                into: try await achievements(from: inFlightLoad, playerID: playerID),
                playerID: playerID
            )
        }

        let generation = invalidationGenerationByPlayerID[playerID, default: 0]
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
        inFlightLoadsByPlayerID[playerID] = inFlightLoad

        do {
            let achievements = mergingLocallyCompletedAchievements(
                into: try await achievements(from: inFlightLoad, playerID: playerID),
                playerID: playerID
            )
            if inFlightLoadsByPlayerID[playerID]?.id == loadID {
                cacheEntriesByPlayerID[playerID] = CacheEntry(
                    achievements: achievements,
                    expiresAt: Date().addingTimeInterval(ttl)
                )
                inFlightLoadsByPlayerID[playerID] = nil
            }
            return achievements
        } catch {
            if inFlightLoadsByPlayerID[playerID]?.id == loadID {
                inFlightLoadsByPlayerID[playerID] = nil
            }
            throw error
        }
    }

    @discardableResult
    func invalidate(playerID: String? = nil) -> Bool {
        guard let playerID else {
            let hadState = !cacheEntriesByPlayerID.isEmpty
                || !inFlightLoadsByPlayerID.isEmpty
                || !locallyCompletedAchievementIDsByPlayerID.isEmpty
            guard hadState else { return false }

            let playerIDs = Set(cacheEntriesByPlayerID.keys)
                .union(inFlightLoadsByPlayerID.keys)
                .union(locallyCompletedAchievementIDsByPlayerID.keys)
            for playerID in playerIDs {
                invalidationGenerationByPlayerID[playerID, default: 0] += 1
            }
            inFlightLoadsByPlayerID.values.forEach { $0.task.cancel() }
            cacheEntriesByPlayerID.removeAll()
            inFlightLoadsByPlayerID.removeAll()
            locallyCompletedAchievementIDsByPlayerID.removeAll()
            return true
        }

        let hadState = cacheEntriesByPlayerID[playerID] != nil
            || inFlightLoadsByPlayerID[playerID] != nil
            || locallyCompletedAchievementIDsByPlayerID[playerID] != nil
        guard hadState else { return false }

        invalidationGenerationByPlayerID[playerID, default: 0] += 1
        cacheEntriesByPlayerID[playerID] = nil
        locallyCompletedAchievementIDsByPlayerID[playerID] = nil
        inFlightLoadsByPlayerID[playerID]?.task.cancel()
        inFlightLoadsByPlayerID[playerID] = nil
        return true
    }

    func markCompleted(_ achievementID: String, playerID: String) {
        locallyCompletedAchievementIDsByPlayerID[playerID, default: []].insert(achievementID)
        guard var cacheEntry = cacheEntriesByPlayerID[playerID] else { return }

        cacheEntry.achievements = mergingLocallyCompletedAchievements(
            into: cacheEntry.achievements,
            playerID: playerID
        )
        cacheEntriesByPlayerID[playerID] = cacheEntry
    }

    private func achievements(
        from inFlightLoad: InFlightLoad,
        playerID: String
    ) async throws -> [GameCenterAchievementProgress] {
        let result = await inFlightLoad.task.result
        guard inFlightLoad.generation == invalidationGenerationByPlayerID[playerID, default: 0] else {
            throw CancellationError()
        }

        return try result.get()
    }

    private func mergingLocallyCompletedAchievements(
        into achievements: [GameCenterAchievementProgress],
        playerID: String
    ) -> [GameCenterAchievementProgress] {
        let locallyCompletedAchievementIDs = locallyCompletedAchievementIDsByPlayerID[playerID, default: []]
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
