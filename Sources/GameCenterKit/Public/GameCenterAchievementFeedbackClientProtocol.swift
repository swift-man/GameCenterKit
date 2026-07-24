//
//  GameCenterAchievementFeedbackClientProtocol.swift
//  GameCenterKit
//
//  Created by gorani. on 2026/07/24.
//

/// 목표 달성 피드백을 앱별 설정과 분리해 재사용하기 위한 클라이언트다.
public protocol GameCenterAchievementFeedbackClientProtocol: Sendable {
    @MainActor
    func playAchievementUnlockedSound()
}
