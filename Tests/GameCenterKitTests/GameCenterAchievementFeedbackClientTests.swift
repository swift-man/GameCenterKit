//
//  GameCenterAchievementFeedbackClientTests.swift
//  GameCenterKitTests
//
//  Created by gorani. on 2026/07/24.
//

import AVFoundation
import Dependencies
import XCTest
@testable import GameCenterKit

final class GameCenterAchievementFeedbackClientTests: XCTestCase {
    func testAchievementUnlockedSoundIsBundled() {
        XCTAssertNotNil(GameCenterAchievementSoundResource.url)
    }

    func testAchievementUnlockedSoundCanBeDecoded() throws {
        let soundURL = try XCTUnwrap(GameCenterAchievementSoundResource.url)
        let player = try AVAudioPlayer(contentsOf: soundURL)

        XCTAssertGreaterThan(player.duration, 0)
    }

    @MainActor
    func testFeedbackClientCanBeOverridden() {
        let recorder = AchievementFeedbackRecorder()

        withDependencies {
            $0.gameCenterAchievementFeedbackClient = StubAchievementFeedbackClient {
                recorder.playCount += 1
            }
        } operation: {
            @Dependency(\.gameCenterAchievementFeedbackClient) var feedbackClient
            feedbackClient.playAchievementUnlockedSound()
        }

        XCTAssertEqual(recorder.playCount, 1)
    }
}

@MainActor
private final class AchievementFeedbackRecorder {
    var playCount = 0
}

private struct StubAchievementFeedbackClient: GameCenterAchievementFeedbackClientProtocol {
    let play: @MainActor @Sendable () -> Void

    init(play: @MainActor @escaping @Sendable () -> Void) {
        self.play = play
    }

    @MainActor
    func playAchievementUnlockedSound() {
        play()
    }
}
