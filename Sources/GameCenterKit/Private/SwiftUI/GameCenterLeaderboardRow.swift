import MaterialDesignColorSwiftUI
import SwiftUI

struct GameCenterLeaderboardRow: View {
    let entry: GameCenterLeaderboardEntry
    let isLocalPlayer: Bool

    @Environment(\.materialTheme) private var materialTheme

    var body: some View {
        let scheme = materialTheme.colorScheme

        HStack(spacing: 12) {
            GameCenterRankBadge(rank: entry.rank)

            Text(entry.displayName)
                .font(.body)
                .fontWeight(isLocalPlayer ? .semibold : .regular)
                .foregroundStyle(scheme.onSurface.color)
                .lineLimit(1)

            if isLocalPlayer {
                Text("나")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(scheme.onPrimary.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(scheme.primary.color, in: Capsule())
            }

            Spacer(minLength: 8)

            Text(entry.formattedScore)
                .font(.body.monospacedDigit())
                .foregroundStyle(
                    isLocalPlayer
                        ? AnyShapeStyle(scheme.primary.color)
                        : AnyShapeStyle(scheme.onSurfaceVariant.color)
                )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background {
            if isLocalPlayer {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(scheme.primaryContainer.color.opacity(0.32))
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let mine = isLocalPlayer ? ", 나" : ""
        return "\(entry.rank)위\(mine), \(entry.displayName), \(entry.formattedScore)점"
    }
}

struct GameCenterRankBadge: View {
    let rank: Int

    @Environment(\.materialTheme) private var materialTheme

    var body: some View {
        let scheme = materialTheme.colorScheme

        Group {
            if let medalStyle {
                Text("\(rank)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(medalStyle.foreground)
                    .frame(width: 30, height: 30)
                    .background(medalStyle.background, in: Circle())
            } else {
                Text("\(rank)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(scheme.onSurfaceVariant.color)
                    .frame(width: 30, height: 30)
            }
        }
        .frame(width: 34, alignment: .center)
    }

    private var medalStyle: (background: Color, foreground: Color)? {
        let scheme = materialTheme.colorScheme

        switch rank {
        case 1:
            return (
                scheme.tertiaryContainer.color,
                scheme.onTertiaryContainer.color
            )
        case 2:
            return (
                scheme.secondaryContainer.color,
                scheme.onSecondaryContainer.color
            )
        case 3:
            return (
                scheme.primaryContainer.color,
                scheme.onPrimaryContainer.color
            )
        default:
            return nil
        }
    }
}
