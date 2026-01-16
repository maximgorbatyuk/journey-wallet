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
                PlaceholderTabView(title: "Home", iconName: "house.fill")
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tint(nil)
                    .tag(0)

                PlaceholderTabView(title: "Feature 1", iconName: "square.grid.2x2")
                    .tabItem {
                        Label("Feature 1", systemImage: "square.grid.2x2")
                    }
                    .tint(nil)
                    .tag(1)

                PlaceholderTabView(title: "Feature 2", iconName: "rectangle.stack")
                    .tabItem {
                        Label("Feature 2", systemImage: "rectangle.stack")
                    }
                    .tint(nil)
                    .tag(2)

                UserSettingsView(showAppUpdateButton: showAppVersionBadge)
                    .tabItem {
                        Label(L("Settings"), systemImage: "gear")
                    }
                    .tint(nil)
                    .tag(3)
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
