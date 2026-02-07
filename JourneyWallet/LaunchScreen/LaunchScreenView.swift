import SwiftUI

struct LaunchScreenView: View {
    private let appVersion: String
    private let developerName: String

    init() {
        self.appVersion = EnvironmentService.shared.getAppVisibleVersion()
        self.developerName = EnvironmentService.shared.getDeveloperName()
    }

    var body: some View {
        ZStack {
            Color.orange.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)

                VStack(spacing: 8) {
                    Text(L("app.name"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(appVersion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(developerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
