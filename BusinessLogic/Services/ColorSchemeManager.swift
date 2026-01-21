import Foundation
import SwiftUI
import Combine

final class ColorSchemeManager: ObservableObject {
    static let shared = ColorSchemeManager()

    @Published var currentScheme: AppColorScheme

    private init() {
        // Read saved color scheme from DB if available, otherwise default to system
        if let repo = DatabaseManager.shared.userSettingsRepository {
            self.currentScheme = repo.fetchColorScheme()
        } else {
            self.currentScheme = .system
        }
    }

    func setScheme(_ scheme: AppColorScheme) throws {
        guard scheme != currentScheme else { return }
        currentScheme = scheme

        let success = DatabaseManager.shared.userSettingsRepository?.upsertColorScheme(scheme) ?? false
        if !success {
            throw RuntimeError("Failed to save selected color scheme to DB")
        }
    }

    /// Returns the SwiftUI ColorScheme to apply, or nil for system default
    var preferredColorScheme: ColorScheme? {
        switch currentScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
