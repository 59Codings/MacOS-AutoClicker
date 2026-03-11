
import Foundation

class LanguageManager {
    static var availableLanguages: [(id: String, name: String)] {
        let preferred = Locale.preferredLanguages
        return preferred.map { lang in
            let loc = Locale(identifier: lang)
            let name = loc.localizedString(forIdentifier: lang) ?? lang
            return (id: lang, name: name.capitalized)
        }
    }
}
