import SwiftUI

struct MainTabView: SwiftUI.View {

    private var viewModel = MainTabViewModel(
        appVersionChecker: AppVersionChecker(
            environment: EnvironmentService.shared
        )
    )

    @State private var showAppVersionBadge = false

    @ObservedObject private var loc = LocalizationManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: Int = 0

    var body: some SwiftUI.View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Tab 1: Home/Dashboard
                MainView()
                    .tabItem {
                        Label(L("tab.home"), systemImage: "house.fill")
                    }
                    .tint(nil)
                    .tag(0)

                // Tab 2: Current Journey
                JourneyDetailView()
                    .tabItem {
                        Label(L("tab.current_journey"), systemImage: "suitcase.fill")
                    }
                    .tint(nil)
                    .tag(1)

                // Tab 3: All Journeys
                JourneysListView()
                    .tabItem {
                        Label(L("tab.journeys"), systemImage: "list.bullet.rectangle")
                    }
                    .tint(nil)
                    .tag(2)

                // Tab 4: Reminders (placeholder for Phase 10)
                PlaceholderTabView(title: L("tab.reminders"), iconName: "bell.fill")
                    .tabItem {
                        Label(L("tab.reminders"), systemImage: "bell.fill")
                    }
                    .tint(nil)
                    .tag(3)

                // Tab 5: Settings
                UserSettingsView(showAppUpdateButton: showAppVersionBadge)
                    .tabItem {
                        Label(L("tab.settings"), systemImage: "gear")
                    }
                    .tint(nil)
                    .tag(4)
                    .badge(showAppVersionBadge ? "New!" : nil)
            }
            .tint(Color.orange)
            .id(loc.currentLanguage.rawValue)
            .onAppear {
                Task {
                    let appVersionCheckResult = await viewModel.checkAppVersion()
                    showAppVersionBadge = appVersionCheckResult ?? false
                }
            }
        }
    }
}

struct PlaceholderTabView: View {
    let title: String
    let iconName: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: iconName)
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text(title)
                    .font(.title)
                    .foregroundColor(.gray)
                Text("This is a placeholder for your new feature")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle(title)
        }
    }
}

#Preview {
    MainTabView()
}
