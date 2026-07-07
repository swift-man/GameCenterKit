import MaterialDesignColorSwiftUI
import ShimmerUI
import SwiftUI

extension MaterialTheme {
    var gameCenterShimmerConfiguration: ShimmerConfiguration {
        ShimmerConfiguration(
            baseColor: colorScheme.surfaceContainerHigh.color,
            highlightColor: colorScheme.surfaceContainerHighest.color,
            duration: 1.15
        )
    }
}

extension View {
    @ViewBuilder
    func gameCenterProvidedMaterialTheme(_ theme: MaterialTheme?) -> some View {
        if let theme {
            materialTheme(theme)
        } else {
            self
        }
    }
}
