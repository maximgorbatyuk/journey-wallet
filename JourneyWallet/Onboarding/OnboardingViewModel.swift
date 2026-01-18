import Foundation

class OnboardingViewModel: ObservableObject {

    var languageManager = LocalizationManager.shared
    var selectedLanguage: AppLanguage

    var pages: [OnboardingPageViewModelItem] = []
    var totalPages: Int = 0

    init() {
        selectedLanguage = languageManager.currentLanguage
        recreatePages()
    }

    func setLanguage(_ language: AppLanguage) {
        selectedLanguage = language
        recreatePages()
    }

    func getLocalizedString(_ key: String) -> String {
        return languageManager.localizedString(forKey: key)
    }

    func recreatePages() {

        pages = [
            OnboardingPageViewModelItem(
                icon: "suitcase.fill",
                title: L("onboarding.track_journeys", language: selectedLanguage),
                description: L("onboarding.track_journeys__subtitle", language: selectedLanguage),
                color: .orange
            ),
            OnboardingPageViewModelItem(
                icon: "doc.text.fill",
                title: L("onboarding.store_bookings", language: selectedLanguage),
                description: L("onboarding.store_bookings__subtitle", language: selectedLanguage),
                color: .blue
            ),
            OnboardingPageViewModelItem(
                icon: "bell.fill",
                title: L("onboarding.travel_reminders", language: selectedLanguage),
                description: L("onboarding.travel_reminders__subtitle", language: selectedLanguage),
                color: .green
            ),
            OnboardingPageViewModelItem(
                icon: "chart.bar.fill",
                title: L("onboarding.view_statistics", language: selectedLanguage),
                description: L("onboarding.view_statistics__subtitle", language: selectedLanguage),
                color: .purple
            ),
        ]
        totalPages = 1 + pages.count
    }
}
