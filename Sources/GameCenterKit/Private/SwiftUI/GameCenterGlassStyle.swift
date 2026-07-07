import MaterialDesignColorSwiftUI
import SwiftUI

extension View {
    func gameCenterGlass<S: Shape>(in shape: S) -> some View {
        modifier(GameCenterMaterialCardModifier(shape: shape))
    }

    func gameCenterGlassCard(cornerRadius: CGFloat = 18) -> some View {
        gameCenterGlass(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func gameCenterGlassButton(isProminent: Bool = false) -> some View {
        modifier(GameCenterMaterialButtonModifier(isProminent: isProminent))
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

    @ViewBuilder
    func gameCenterSheetDetents() -> some View {
        if #available(iOS 16.0, macOS 13.0, visionOS 1.0, *) {
            presentationDetents([.medium, .large])
        } else {
            self
        }
    }
}

private struct GameCenterMaterialCardModifier<S: Shape>: ViewModifier {
    let shape: S

    @Environment(\.materialTheme) private var theme

    func body(content: Content) -> some View {
        let scheme = theme.colorScheme

        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            // Liquid Glass는 컨트롤/카드 레이어로 두되, MD3 색은 옅은 틴트로만 얹어
            // 글래스가 콘텐츠를 비추도록 한다. 하드 테두리는 두지 않는다.
            content
                .background(scheme.surfaceContainer.color.opacity(0.28), in: shape)
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(scheme.surfaceContainer.color, in: shape)
                .overlay {
                    shape
                        .stroke(scheme.outlineVariant.color.opacity(0.5), lineWidth: 1)
                }
        }
    }
}

private struct GameCenterMaterialButtonModifier: ViewModifier {
    let isProminent: Bool

    @Environment(\.materialTheme) private var theme

    func body(content: Content) -> some View {
        let scheme = theme.colorScheme

        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
            if isProminent {
                content
                    .tint(scheme.primary.color)
                    .foregroundStyle(scheme.onPrimary.color)
                    .buttonStyle(.glassProminent)
            } else {
                content
                    .tint(scheme.primary.color)
                    .foregroundStyle(scheme.primary.color)
                    .buttonStyle(.glass)
            }
        } else {
            if isProminent {
                content
                    .tint(scheme.primary.color)
                    .foregroundStyle(scheme.onPrimary.color)
                    .buttonStyle(.borderedProminent)
            } else {
                content
                    .tint(scheme.primary.color)
                    .foregroundStyle(scheme.primary.color)
                    .buttonStyle(.bordered)
            }
        }
    }
}
