import SwiftUI

struct GameCenterEmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String?

    var body: some View {
        if #available(iOS 17.0, macOS 14.0, visionOS 1.0, *) {
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
            } description: {
                if let message {
                    Text(message)
                }
            }
        } else {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.headline)

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .padding()
        }
    }
}
