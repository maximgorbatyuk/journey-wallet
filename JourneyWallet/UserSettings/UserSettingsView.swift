import SwiftUI
import StoreKit

struct UserSettingsView: SwiftUICore.View {

    @State var showAppUpdateButton: Bool = false

    @StateObject private var viewModel = UserSettingsViewModel(
        environment: EnvironmentService.shared,
        db: DatabaseManager.shared,
        developerMode: DeveloperModeManager.shared)

    @State private var showEditCurrencyModal: Bool = false
    @State private var isNotificationsEnabled: Bool = false

    @State private var showingAppAboutModal = false
    @State private var confirmationModalDialogData = ConfirmationData.empty
    @State private var showDeveloperModeAlert = false
    @State private var showExportShareSheet = false
    @State private var exportFileURL: URL?
    @State private var showImportFilePicker = false

    // Random data generation
    @State private var showJourneyPickerForRandomData = false
    @State private var selectedJourneyForRandomData: Journey?
    @State private var showRandomDataConfirmation = false

    @ObservedObject private var analytics = AnalyticsService.shared
    @ObservedObject private var notificationsManager = NotificationManager.shared
    @ObservedObject private var environment = EnvironmentService.shared
    @ObservedObject private var developerMode = DeveloperModeManager.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    @Environment(\.requestReview) var requestReview

    var body: some SwiftUICore.View {
        NavigationView {

            Form {
                
                if (showAppUpdateButton) {
                    HStack {
                        Text(L("App update available"))
                            .fontWeight(.semibold)
                            .font(.system(size: 16, weight: .bold))
                        
                        Spacer()

                        Button(action: {
                            analytics.trackEvent("app_update_button_clicked", properties: [
                                "screen": "user_settings_screen",
                                "button_name": "update_app"
                            ])

                            if let url = URL(string: environment.getAppStoreAppLink()) {
                                viewModel.openWebURL(url)
                            }
                        }) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 28))
                        }
                    }
                    .padding(8)
                    .listRowBackground(Color.yellow.opacity(0.2))
                    .background(Color.clear)
                }

                Section(header: Text(L("Base settings"))) {
                    HStack {
                        Picker(L("Language"), selection: $viewModel.selectedLanguage) {
                            ForEach(AppLanguage.allCases, id: \.self) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: viewModel.selectedLanguage) { _, newLang in
                            analytics.trackEvent("language_select_button_clicked", properties: [
                                    "screen": "user_settings_screen",
                                    "button_name": "language_picker",
                                    "new_language": newLang.rawValue
                                ])

                            viewModel.saveLanguage(newLang)
                        }
                    }

                    VStack {
                        HStack {
                            Text(L("Notifications enabled"))
                                .fontWeight(.semibold)
                                .font(.system(size: 16, weight: .bold))

                            Spacer()
                            
                            Toggle("", isOn: $isNotificationsEnabled)
                                .disabled(true)
                                .labelsHidden()
                        }

                        HStack {
                            Text(L("In case you want to change this setting, please open app settings"))
                                .foregroundColor(.secondary)

                            Spacer()
                            Button(L("Open settings")) {
                                analytics.trackEvent("notifications_settings_button_clicked", properties: [
                                        "screen": "user_settings_screen",
                                        "button_name": "notifications_enable_toggler"
                                    ])

                                notificationsManager.checkAndRequestPermission(
                                    completion: {
                                        openSettings()
                                    },
                                    onDeniedNotificationPermission: {
                                        openSettings()
                                    }
                                )
                            }
                        }
                        .font(.caption)
                    }

                    VStack {
                        HStack {
                            Text(L("Currency"))
                                .fontWeight(.semibold)
                                .font(.system(size: 16, weight: .bold))

                            Spacer()

                            Button(action: {
                                analytics.trackEvent("currency_edit_button_clicked", properties: [
                                        "screen": "user_settings_screen",
                                        "button_name": "edit_current_currency"
                                    ])

                                showEditCurrencyModal = true
                            }) {
                                Text(viewModel.defaultCurrency.shortName)
                                    .fontWeight(.semibold)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }

                        HStack {
                            Text(L("It is recommended to set the default currency before adding any expenses."))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    }

                Section(header: Text(L("iCloud Backup"))) {
                    let iCloudAvailable = viewModel.isiCloudAvailable()

                    // iCloud not available warning
                    if !iCloudAvailable {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("iCloud Not Available"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)

                                Text(L("Please sign in to iCloud in Settings to enable backups."))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Manual backup button
                    Button(action: {
                        analytics.trackEvent("icloud_backup_button_clicked", properties: [
                            "screen": "user_settings_screen",
                            "button_name": "create_icloud_backup"
                        ])

                        Task {
                            await viewModel.createiCloudBackup()
                        }
                    }) {
                        HStack {
                            if viewModel.isBackingUp {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "icloud.and.arrow.up")
                                    .foregroundColor(iCloudAvailable ? .blue : .gray)
                            }

                            Text(viewModel.isBackingUp ? L("Creating backup...") : L("Backup Now"))
                                .padding(.leading, 4)
                                .foregroundColor(iCloudAvailable ? .primary : .secondary)
                        }
                    }
                    .disabled(!iCloudAvailable || viewModel.isBackingUp || viewModel.isImporting || viewModel.isExporting || !networkMonitor.isConnected)

                    // Network not available warning
                    if iCloudAvailable && !networkMonitor.isConnected {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "wifi.slash")
                                .foregroundColor(.orange)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("No Internet Connection"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)

                                Text(L("Connect to the internet to create or restore backups."))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    // Last backup timestamp
                    if let lastBackup = viewModel.lastBackupDate {
                        HStack {
                            Text(L("Last backup"))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatBackupDate(lastBackup))
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }

                    // View backups button
                    Button(action: {
                        analytics.trackEvent("view_backups_button_clicked", properties: [
                            "screen": "user_settings_screen",
                            "button_name": "view_backup_history"
                        ])

                        viewModel.showBackupList = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(iCloudAvailable ? .purple : .gray)

                            Text(L("View Backup History"))
                                .padding(.leading, 4)
                                .foregroundColor(iCloudAvailable ? .primary : .secondary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!iCloudAvailable)

                    // Automatic backup toggle
                    Toggle(isOn: Binding(
                        get: { viewModel.isAutomaticBackupEnabled },
                        set: { newValue in
                            viewModel.toggleAutomaticBackup(newValue)
                        }
                    )) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(iCloudAvailable ? .green : .gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("Automatic Backup"))
                                    .foregroundColor(iCloudAvailable ? .primary : .secondary)

                                if let lastAutoBackup = viewModel.lastAutomaticBackupDate {
                                    Text(L("Last: \(formatBackupDate(lastAutoBackup))"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .disabled(!iCloudAvailable)

                    // Info text
                    if iCloudAvailable {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("Automatic backups to iCloud keep your data safe."))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(L("Maximum 5 backups kept, older than 30 days auto-deleted."))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(header: Text(L("Support"))) {
                    Button(action: {
                        analytics.trackEvent("about_app_button_clicked", properties: [
                                "screen": "user_settings_screen",
                                "button_name": "what_is_app_about"
                            ])

                        showingAppAboutModal = true
                    }) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.cyan)

                            Text(L("What is the app about?"))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: UserSettingsViewModel.onboardingCompletedKey)
                        analytics.trackEvent("start_onboarding_again_button_clicked", properties: [
                                "screen": "user_settings_screen",
                                "button_name": "start_onboarding_again"
                            ])
                    }) {
                        HStack {
                            Image(systemName: "figure.wave")
                                .foregroundColor(.green)

                            Text(L("Start onboarding again"))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }

                    Button {
                        analytics.trackEvent("app_rating_review_button_clicked", properties: [
                                "screen": "user_settings_screen",
                                "button_name": "request_app_rating_review"
                            ])

                        requestReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)

                            Text(L("Rate the app"))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }

                    Button {
                        analytics.trackEvent("developer_tg_button_clicked", properties: [
                                "screen": "user_settings_screen",
                                "button_name": "developer_telegram_link"
                            ])

                        if let url = URL(string: environment.getDeveloperTelegramLink()) {
                            viewModel.openWebURL(url)
                        }

                    } label: {
                        HStack {
                            Image(systemName: "ellipses.bubble.fill")
                                .foregroundColor(.blue)

                            Text(L("Contact developer via Telegram"))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section(header: Text(L("About app"))) {
                    Button(action: {
                        viewModel.handleVersionTap()
                    }) {
                        HStack {
                            Label(L("App version"), systemImage: "info.circle")
                            Spacer()
                            Text(environment.getAppVisibleVersion())
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Label(L("Developer"), systemImage: "person")
                        Spacer()
                        Text(environment.getDeveloperName())
                    }

                    if (viewModel.isDevelopmentMode()) {
                        HStack {
                            Label(L("Build"), systemImage: "star.circle")
                            Spacer()
                            Text("Development")
                        }
                    }

                    if (viewModel.isSpecialDeveloperModeEnabled()) {
                        Button(action: {
                            developerMode.disableDeveloperMode()
                        }) {
                            HStack {
                                Label(L("Developer Mode"), systemImage: "hammer.fill")
                                    .foregroundColor(.orange)
                                Spacer()
                                Text("Enabled")
                                    .foregroundColor(.orange)
                                    .fontWeight(.bold)
                            }
                        }
                        .buttonStyle(.plain)

                        
                    }
                }

                Section(header: Text(L("Export & Import"))) {
                    // Export button
                    Button(action: {
                        analytics.trackEvent("export_data_button_clicked", properties: [
                            "screen": "user_settings_screen",
                            "button_name": "export_data"
                        ])

                        Task {
                            if let fileURL = await viewModel.exportData() {
                                exportFileURL = fileURL
                                showExportShareSheet = true
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isExporting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                            }

                            Text(viewModel.isExporting ? L("Preparing export...") : L("Export Data..."))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }
                    .disabled(viewModel.isExporting || viewModel.isImporting)

                    // Import button
                    Button(action: {
                        analytics.trackEvent("import_data_button_clicked", properties: [
                            "screen": "user_settings_screen",
                            "button_name": "import_data"
                        ])

                        showImportFilePicker = true
                    }) {
                        HStack {
                            if viewModel.isImporting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundColor(.orange)
                            }

                            Text(viewModel.isImporting ? L("Importing data...") : L("Import Data..."))
                                .padding(.leading, 4)
                                .foregroundColor(.primary)
                        }
                    }
                    .disabled(viewModel.isExporting || viewModel.isImporting)

                    // Info text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("Export your data to back it up or transfer to another device."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(L("Import will replace all existing data."))
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                if (viewModel.isSpecialDeveloperModeEnabled()) {

                    Section(header: Text(L("Developer section"))) {

                        Button(action: {
                            NotificationManager.shared.requestPermission()
                        }) {
                            Text("Request Permission")
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            _ = NotificationManager.shared.sendNotification(
                                title: "Hello!",
                                body: "This is a test notification"
                            )
                        }) {
                            Text("Send Notification Now")
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            _ = NotificationManager.shared.scheduleNotification(
                                title: "Reminder",
                                body: "5 seconds have passed!",
                                afterSeconds: 5
                            )
                        }) {
                            Text("Schedule for 5 seconds")
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            confirmationModalDialogData = ConfirmationData(
                                title: "Delete all data?",
                                message: "This will permanently delete all data. This action cannot be undone.",
                                action: {
                                    viewModel.deleteAllData()
                                }
                            )
                        }) {
                            Text("Delete all data")
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            analytics.trackEvent("generate_random_data_button_clicked", properties: [
                                "screen": "user_settings_screen",
                                "button_name": "generate_random_data"
                            ])
                            showJourneyPickerForRandomData = true
                        }) {
                            HStack {
                                Image(systemName: "dice.fill")
                                    .foregroundColor(.purple)
                                Text(L("settings.developer.generate_random_data"))
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(L("User settings"))
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showEditCurrencyModal) {
                EditDefaultCurrencyView(
                    selectedCurrency: viewModel.getDefaultCurrency(),
                    onSave: { newCurrency in
                        viewModel.saveDefaultCurrency(newCurrency)
                    })
            }
            .onAppear {
                analytics.trackScreen("user_settings_screen")
                refreshData()
                viewModel.refreshAutomaticBackupState()
            }
            .refreshable {
                refreshData()
            }
            .sheet(isPresented: $showingAppAboutModal) {
                AboutAppSubView()
            }
            .alert(confirmationModalDialogData.title, isPresented: $confirmationModalDialogData.showDialog) {
                Button(confirmationModalDialogData.cancelButtonTitle, role: .cancel) {
                    confirmationModalDialogData = .empty
                }
                Button(confirmationModalDialogData.confirmButtonTitle, role: .destructive) {
                    confirmationModalDialogData.action()
                    confirmationModalDialogData = .empty
                }
            } message: {
                Text(confirmationModalDialogData.message)
            }
            .alert("Developer Mode Activated", isPresented: $developerMode.shouldShowActivationAlert) {
                Button("OK") {
                    developerMode.dismissAlert()
                }
            } message: {
                Text("Developer mode has been enabled. You can now access additional debugging tools and options.")
            }
            .sheet(isPresented: $showExportShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $viewModel.showBackupList) {
                iCloudBackupListView(viewModel: viewModel)
            }
            .fileImporter(
                isPresented: $showImportFilePicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            await viewModel.prepareImport(from: url)
                        }
                    }
                case .failure(let error):
                    viewModel.importError = error.localizedDescription
                }
            }
            .alert(L("Export Error"), isPresented: .constant(viewModel.exportError != nil)) {
                Button(L("OK")) {
                    viewModel.exportError = nil
                }
            } message: {
                if let error = viewModel.exportError {
                    Text(error)
                }
            }
            .alert(L("Import Error"), isPresented: .constant(viewModel.importError != nil)) {
                Button(L("OK")) {
                    viewModel.importError = nil
                }
            } message: {
                if let error = viewModel.importError {
                    Text(error)
                }
            }
            .alert(L("Confirm Import"), isPresented: $viewModel.showImportConfirmation) {
                Button(L("Cancel"), role: .cancel) {
                    viewModel.cancelImport()
                }
                Button(L("Import and Replace All Data"), role: .destructive) {
                    Task {
                        await viewModel.confirmImport()
                    }
                }
            } message: {
                if let preview = viewModel.importPreviewData {
                    Text(buildImportPreviewMessage(preview))
                }
            }
            .sheet(isPresented: $showJourneyPickerForRandomData) {
                JourneyPickerForRandomDataView(
                    onSelect: { journey in
                        selectedJourneyForRandomData = journey
                        showJourneyPickerForRandomData = false
                        showRandomDataConfirmation = true
                    },
                    onCancel: {
                        showJourneyPickerForRandomData = false
                    }
                )
            }
            .alert(L("settings.developer.random_data_confirm_title"), isPresented: $showRandomDataConfirmation) {
                Button(L("Cancel"), role: .cancel) {
                    selectedJourneyForRandomData = nil
                }
                Button(L("settings.developer.random_data_confirm_action"), role: .destructive) {
                    if let journey = selectedJourneyForRandomData {
                        viewModel.generateRandomDataForJourney(journey)
                        selectedJourneyForRandomData = nil
                    }
                }
            } message: {
                Text(L("settings.developer.random_data_confirm_message"))
            }
        }
    }

    private func buildImportPreviewMessage(_ preview: ImportPreviewData) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        return """
        \(L("Source")): \(preview.deviceName)
        \(L("Export Date")): \(dateFormatter.string(from: preview.exportDate))
        \(L("App Version")): \(preview.appVersion)
        \(L("Schema Version")): \(preview.schemaVersion)

        \(L("Data Summary")):
            TODO Here goes summary of records, e.g.:

        ⚠️ \(L("Warning: Importing will DELETE ALL existing data. This cannot be undone."))
        """
    }

    private func refreshData() -> Void {

        notificationsManager.getAuthorizationStatus() { status in
           DispatchQueue.main.async {
               self.isNotificationsEnabled = status == .authorized
           }
       }
    }

    private func formatBackupDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Journey Picker for Random Data

struct JourneyPickerForRandomDataView: View {
    let onSelect: (Journey) -> Void
    let onCancel: () -> Void

    @State private var journeys: [Journey] = []
    @State private var isLoading = true

    private let journeysRepository = DatabaseManager.shared.journeysRepository

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if journeys.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "suitcase")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text(L("settings.developer.no_journeys"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(L("settings.developer.no_journeys_hint"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    List(journeys) { journey in
                        Button(action: {
                            onSelect(journey)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(journey.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(journey.destination)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatDateRange(journey.startDate, journey.endDate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(L("settings.developer.select_journey"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        onCancel()
                    }
                }
            }
            .onAppear {
                loadJourneys()
            }
        }
    }

    private func loadJourneys() {
        isLoading = true
        journeys = journeysRepository?.fetchAll() ?? []
        isLoading = false
    }

    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

#Preview {
    UserSettingsView(showAppUpdateButton: false)
}
