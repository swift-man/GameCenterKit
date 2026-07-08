# GameCenterKit

![Badge - Swift](https://img.shields.io/badge/Swift-6.0-white.svg?style=flat-square&logo=Swift)
![Badge - SwiftUI](https://img.shields.io/badge/SwiftUI-001b87.svg?style=flat-square&logo=Swift&logoColor=black)
![Badge - Version](https://img.shields.io/badge/Version-0.2.0-1177AA?style=flat-square)
![Badge - Swift Package Manager](https://img.shields.io/badge/SPM-compatible-orange?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/macOS-v12.0-yellow?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/iOS-v15.0-yellow?style=flat-square)
![Badge - Platform](https://img.shields.io/badge/visionOS-v1.0-yellow?style=flat-square)

Swift Package for reusable Game Center interfaces.

## Usage

GameCenterKit exposes protocol-first clients through
`pointfreeco/swift-dependencies`, so apps can depend on interfaces instead of live
GameKit adapters.

```swift
import Dependencies
import GameCenterKit

struct ProfileFeature {
    @Dependency(\.gameCenterAuthenticationClient) var authenticationClient
    @Dependency(\.gameCenterPlayerPhotoClient) var playerPhotoClient

    func loadProfile() async throws -> (GameCenterPlayer, GameCenterPlayerPhoto?) {
        let player = try await authenticationClient.localPlayer()
        let photo = try? await playerPhotoClient.loadLocalPlayerPhoto(size: .small)
        return (player, photo)
    }
}
```

Use `PreviewGameCenterClient` in previews and tests to inject players, friends,
leaderboards, achievements, activities, and player photos without touching live
Game Center state.

## SwiftUI Dashboard

Apps provide the Material theme so GameCenterKit can apply Material 3 color roles
consistently across cards, buttons, loading placeholders, and text.

```swift
import GameCenterKit
import MaterialDesignColorSwiftUI

let theme = try MaterialTheme.custom(
    appearance: .light,
    overrides: [
        .primary: "#6750A4",
        .onPrimary: "#FFFFFF",
        .surface: "#FFFBFE",
        .onSurface: "#1C1B1F",
    ],
    sourceColor: "#6750A4"
)

GameCenterMainView(
    configuration: GameCenterConfiguration(
        leaderboardCategories: [
            GameCenterLeaderboardCategory(
                id: "ipad",
                title: "iPad Ranking",
                leaderboardIDs: [
                    .daily: "ipad.daily",
                    .weekly: "ipad.weekly",
                    .allTime: "ipad.all-time",
                ]
            ),
            GameCenterLeaderboardCategory(
                id: "ipad.keyboard",
                title: "iPad Hardware Keyboard Ranking",
                leaderboardIDs: [
                    .daily: "ipad-keyboard.daily",
                    .weekly: "ipad-keyboard.weekly",
                    .allTime: "ipad-keyboard.all-time",
                ]
            ),
        ]
    ),
    theme: theme
)
```

For single-board games, the existing `leaderboardIDs` initializer still works:

```swift
GameCenterConfiguration(
    leaderboardIDs: [
        .daily: "score.daily",
        .weekly: "score.weekly",
        .allTime: "score.all-time",
    ]
)
```
