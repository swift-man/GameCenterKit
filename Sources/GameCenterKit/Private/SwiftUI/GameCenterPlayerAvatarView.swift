import SwiftUI

struct GameCenterPlayerAvatarView: View {
    var photo: GameCenterPlayerPhoto?
    var systemImageName: String = "person.crop.circle"
    var size: CGFloat = 40

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = photo?.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
            #elseif canImport(AppKit)
            if let image = photo?.nsImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.secondary.opacity(0.2), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        Image(systemName: systemImageName)
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(size * 0.14)
    }
}
