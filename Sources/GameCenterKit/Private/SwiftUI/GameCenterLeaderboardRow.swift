import SwiftUI

struct GameCenterLeaderboardRow: View {
    let entry: GameCenterLeaderboardEntry
    let isLocalPlayer: Bool

    var body: some View {
        HStack(spacing: 12) {
            GameCenterRankBadge(rank: entry.rank)

            Text(entry.displayName)
                .font(.body)
                .fontWeight(isLocalPlayer ? .semibold : .regular)
                .lineLimit(1)

            if isLocalPlayer {
                Text("나")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
            }

            Spacer(minLength: 8)

            Text(entry.formattedScore)
                .font(.body.monospacedDigit())
                .foregroundStyle(isLocalPlayer ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background {
            if isLocalPlayer {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
            }
        }
        .contentShape(Rectangle())
    }
}

struct GameCenterRankBadge: View {
    let rank: Int

    var body: some View {
        Group {
            if let medalColor {
                Text("\(rank)")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(medalColor, in: Circle())
            } else {
                Text("\(rank)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
            }
        }
        .frame(width: 34, alignment: .center)
    }

    private var medalColor: Color? {
        switch rank {
        case 1:
            return Color(red: 0.95, green: 0.77, blue: 0.30)
        case 2:
            return Color(red: 0.72, green: 0.74, blue: 0.78)
        case 3:
            return Color(red: 0.80, green: 0.55, blue: 0.34)
        default:
            return nil
        }
    }
}
