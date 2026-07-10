import Foundation

enum GameCenterLocalizedString {
    static func string(
        _ key: String,
        localization: String? = nil,
        bundle: Bundle = .module
    ) -> String {
        localizedBundle(
            for: resolvedLocalization(for: localization, in: bundle),
            in: bundle
        )
            .localizedString(forKey: key, value: nil, table: "Localizable")
    }

    static func format(
        _ key: String,
        localization: String? = nil,
        bundle: Bundle = .module,
        _ arguments: CVarArg...
    ) -> String {
        let resolvedLocalization = resolvedLocalization(for: localization, in: bundle)

        return String(
            format: localizedBundle(for: resolvedLocalization, in: bundle)
                .localizedString(forKey: key, value: nil, table: "Localizable"),
            locale: resolvedLocalization.map(Locale.init(identifier:)) ?? .current,
            arguments: arguments
        )
    }

    private static func resolvedLocalization(
        for localization: String?,
        in bundle: Bundle
    ) -> String? {
        guard let localization else {
            return nil
        }

        return Bundle.preferredLocalizations(
            from: bundle.localizations,
            forPreferences: [localization]
        ).first
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
