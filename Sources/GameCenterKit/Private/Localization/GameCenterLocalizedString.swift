import Foundation

enum GameCenterLocalizedString {
    static func string(
        _ key: String,
        localization: String? = nil,
        bundle: Bundle = .module
    ) -> String {
        localizedBundle(for: localization, in: bundle)
            .localizedString(forKey: key, value: nil, table: "Localizable")
    }

    static func format(
        _ key: String,
        localization: String? = nil,
        bundle: Bundle = .module,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: string(key, localization: localization, bundle: bundle),
            locale: Locale.current,
            arguments: arguments
        )
    }

    private static func localizedBundle(
        for localization: String?,
        in bundle: Bundle
    ) -> Bundle {
        guard
            let localization,
            let path = bundle.path(forResource: localization, ofType: "lproj"),
            let localizedBundle = Bundle(path: path)
        else {
            return bundle
        }

        return localizedBundle
    }
}
