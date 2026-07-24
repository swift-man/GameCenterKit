//
//  LiveGameCenterAchievementFeedbackClient.swift
//  GameCenterKit
//
//  Created by gorani. on 2026/07/24.
//

import AVFoundation
import Foundation
import OSLog

struct LiveGameCenterAchievementFeedbackClient: GameCenterAchievementFeedbackClientProtocol {
    @MainActor
    func playAchievementUnlockedSound() {
        GameCenterAchievementSoundPlayer.shared.play()
    }
}

struct NoopGameCenterAchievementFeedbackClient: GameCenterAchievementFeedbackClientProtocol {
    @MainActor
    func playAchievementUnlockedSound() {}
}

enum GameCenterAchievementSoundResource {
    static let url = Bundle.module.url(forResource: "achievement-unlocked", withExtension: "mp3")
}

@MainActor
private final class GameCenterAchievementSoundPlayer: NSObject, @preconcurrency AVAudioPlayerDelegate {
    static let shared = GameCenterAchievementSoundPlayer()

    private let logger = Logger(subsystem: "GameCenterKit", category: "AchievementSound")

    /// 목표가 연속 달성되어도 앞선 사운드를 중단하지 않도록 재생 중인 플레이어를 각각 유지한다.
    private var activePlayers: [AVAudioPlayer] = []

    func play() {
        do {
            guard let soundURL = GameCenterAchievementSoundResource.url else {
                logger.error("Achievement sound resource is missing.")
                return
            }

            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.delegate = self
            player.prepareToPlay()
            activePlayers.append(player)

            if !player.play() {
                remove(player)
                logger.error("Achievement sound playback did not start.")
            }
        } catch {
            logger.error(
                "Achievement sound playback failed: \(String(describing: error), privacy: .public)"
            )
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        remove(player)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        remove(player)
    }

    private func remove(_ player: AVAudioPlayer) {
        activePlayers.removeAll { $0 === player }
    }

}
