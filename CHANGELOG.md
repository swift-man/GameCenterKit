# Changelog

All notable changes to GameCenterKit will be documented in this file.

## [0.3.1] - 2026-07-12

### Changed

- Centralized completed-goal counting so the main dashboard and goals popup use the same completion rule.

### Fixed

- Cleared stale reported-achievement state when Game Center progress synchronization fails.
- Locked unsupported explicit localizations to the package's English fallback with regression coverage.

## [0.3.0] - 2026-07-11

### Added

- Added English and Korean package resources for built-in Game Center UI, errors, accessibility labels, and values.

### Fixed

- Made built-in UI and VoiceOver output follow the host app's preferred language instead of always using Korean.
- Localized leaderboard ranks and goal progress as complete phrases so each language can use its natural word order.
- Preserved Game Center formatted score units and pluralization in VoiceOver output without appending duplicate units.

## [0.2.1] - 2026-07-08

### Added

- Added README badges for Swift, SwiftUI, package version, SPM compatibility, and supported platforms.

### Changed

- Added a short-lived achievement progress cache to reduce duplicate GameKit achievement loads across simultaneous goal cards.
- Replaced raw Swift error descriptions in SwiftUI surfaces with user-facing Game Center error messages.
- Normalized empty leaderboard category configuration to the default category to avoid empty selected category IDs.
- Reworked nickname profile refresh after dismissing the Game Center profile sheet to use structured SwiftUI task invalidation.
- Propagated profile sheet dismissals to leaderboard refresh triggers so parent dashboard data can resync after Game Center account changes.

### Fixed

- Invalidated cached achievement progress after achievement reports, DEBUG achievement reset, and authentication loss so stale completion state is not shown.
- Prevented invalidated in-flight achievement loads from repopulating the progress cache after a reset or report race.
- Resynced goal cards after DEBUG achievement reset so local completion state follows the cleared Game Center achievement state.

## [0.2.0] - 2026-07-08

### Added

- Added MaterialDesignColor and ShimmerUI package integrations.
- Added required Material theme injection for public SwiftUI dashboard surfaces and applied Material 3 color roles across dashboard, leaderboard, nickname, goal, empty, button, card, and shimmer states.
- Added leaderboard categories so apps can provide multiple ranking boards such as iPad ranking and iPad hardware keyboard ranking, each with its own daily, weekly, and all-time leaderboard IDs.
- Added a leaderboard category picker that appears when more than one ranking category is configured.
- Added DEBUG achievement reset support through public reset APIs and the Game Center debug menu.
- Added a root `gameCenterAuthentication` view modifier for early Game Center authentication.

## [0.1.0] - 2026-07-07

### Added

- Added the initial Swift Package Manager package structure for GameCenterKit.
- Added protocol-first Game Center clients for authentication, leaderboards, achievements, access point, friends, challenges, game activities, and player photos.
- Added `swift-dependencies` integration so apps can inject live, preview, and test Game Center clients.
- Added SwiftUI views for Game Center dashboard, nickname, profile access, goal progress, and player avatars.
- Added preview implementations and XCTest coverage for configuration lookup, dependency overrides, player photo loading, dashboard refresh failure handling, and activity lifecycle behavior.
- Added README usage guidance for dependency-based Game Center integration.
