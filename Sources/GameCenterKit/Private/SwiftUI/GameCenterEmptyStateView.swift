import MaterialDesignColorSwiftUI
import SwiftUI

struct GameCenterEmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String?

    var body: some View {
        let scheme = materialTheme.colorScheme

        if #available(iOS 17.0, macOS 14.0, visionOS 1.0, *) {
            ContentUnavailableView {
                Label(title, systemImage: systemImage)
                    .foregroundStyle(scheme.onSurface.color)
            } description: {
                if let message {
                    Text(message)
                        .foregroundStyle(scheme.onSurfaceVariant.color)
                }
            }
            .tint(scheme.primary.color)
        } else {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(scheme.primary.color)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(scheme.onSurface.color)

                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(scheme.onSurfaceVariant.color)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .padding()
        }
    }

    @Environment(\.materialTheme) private var materialTheme
}
