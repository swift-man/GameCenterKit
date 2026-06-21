# GameCenterKit

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
