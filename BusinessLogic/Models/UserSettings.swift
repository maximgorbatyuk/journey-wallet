enum UserSettingKey: String {
    case currency = "currency"
}

// New: supported app languages
enum AppLanguage: String, CaseIterable, Codable {
    case en = "en"
    case de = "de"
    case ru = "ru"
    case kk = "kk"
    case tr = "tr"
    case uk = "uk"

    var displayName: String {
        switch self {
            case .en: return "🇬🇧 English"
            case .de: return "🇩🇪 Deutsch"
            case .ru: return "🇷🇺 Русский"
            case .kk: return "🇰🇿 Қазақша"
            case .tr: return "🇹🇷 Türkçe"
            case .uk: return "🇺🇦 Українська"
        }
    }
}

// Add key constant for language
extension UserSettingKey {
    static let language = UserSettingKey(rawValue: "language")!
}

// Color scheme preference
enum AppColorScheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return L("settings.color_scheme.system")
        case .light: return L("settings.color_scheme.light")
        case .dark: return L("settings.color_scheme.dark")
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}
