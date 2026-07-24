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
    static var url: URL? {
        Bundle.module.url(forResource: "achievement-unlocked", withExtension: "mp3")
    }
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

            prepareAudioSessionForPlayback()
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

    /// 호스트가 오디오 정책을 정하지 않은 기본 세션에서만 비독점 카테고리로 전환한다.
    /// 게임이 이미 재생·녹음 카테고리를 구성했다면 패키지는 그 전역 정책을 변경하지 않는다.
    private func prepareAudioSessionForPlayback() {
        #if os(iOS) || os(visionOS)
        let session = AVAudioSession.sharedInstance()
        guard session.category == .soloAmbient else { return }

        do {
            try session.setCategory(.ambient)
        } catch {
            logger.error(
                "Achievement sound audio session configuration failed: \(String(describing: error), privacy: .public)"
            )
        }
        #endif
    }
}
