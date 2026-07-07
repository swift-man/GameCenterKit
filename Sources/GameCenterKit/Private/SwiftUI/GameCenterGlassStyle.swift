import SwiftUI

extension View {
    @ViewBuilder
    func gameCenterGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    func gameCenterGlassCard(cornerRadius: CGFloat = 18) -> some View {
        gameCenterGlass(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    func gameCenterGlassButton(isProminent: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            if isProminent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else {
            if isProminent {
                buttonStyle(.borderedProminent)
            } else {
                buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    func gameCenterNumericTransition() -> some View {
        if #available(iOS 16.0, macOS 13.0, visionOS 1.0, *) {
            contentTransition(.numericText())
        } else {
            self
        }
    }

    @ViewBuilder
    func gameCenterCompletionBounce(isCompleted: Bool) -> some View {
        if #available(iOS 17.0, macOS 14.0, visionOS 1.0, *) {
            symbolEffect(.bounce, value: isCompleted)
        } else {
            self
        }
    }
}
