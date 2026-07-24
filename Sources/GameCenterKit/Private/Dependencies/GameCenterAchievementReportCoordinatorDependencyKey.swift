//
//  GameCenterAchievementReportCoordinatorDependencyKey.swift
//  GameCenterKit
//
//  Created by gorani. on 2026/07/25.
//

import Dependencies

enum GameCenterAchievementReportCoordinatorDependencyKey: DependencyKey {
    static let liveValue = GameCenterAchievementReportCoordinator.live
    static let previewValue = GameCenterAchievementReportCoordinator.passthrough
    static let testValue = GameCenterAchievementReportCoordinator.passthrough
}

extension DependencyValues {
    var gameCenterAchievementReportCoordinator: GameCenterAchievementReportCoordinator {
        get { self[GameCenterAchievementReportCoordinatorDependencyKey.self] }
        set { self[GameCenterAchievementReportCoordinatorDependencyKey.self] = newValue }
    }
}
