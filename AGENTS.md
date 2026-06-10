# AGENTS.md

## 설계 원칙

- SOLID 원칙을 우선한다.
- 앱이 구체 구현체에 직접 의존하지 않도록 public API는 프로토콜과 값 타입 중심으로 설계한다.
- 외부 앱에서 접근해야 하는 타입, 프로토콜, SwiftUI View는 `Sources/GameCenterKit/Public` 아래에 둔다.
- `internal`, `fileprivate`, `private` 구현과 GameKit 어댑터, 매핑, dependency key는 `Sources/GameCenterKit/Private` 아래에 둔다.
- `public extension`은 사용하지 않는다. 항상 `extension Type { public ... }` 형태로 선언한다.
- Game Center entitlement, App Store Connect leaderboard ID, achievement ID는 사용하는 앱이 소유하고 패키지는 주입받는다.

## GitHub

- PR 제목에는 `[Codex]`를 붙이지 않는다.
- PR 제목과 커밋 메시지는 `feat.`, `fix.`, `docs.`, `chore.`, `hotfix.`, `env.` 등 의미 있는 prefix로 시작한다.
- Draft PR을 만들지 말고 즉시 Ready 상태의 PR을 만든다.
