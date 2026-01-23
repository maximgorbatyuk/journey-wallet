import SwiftUI

enum PlaceFormMode {
    case add
    case edit(PlaceToVisit)

    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }

    var existingPlace: PlaceToVisit? {
        if case .edit(let place) = self { return place }
        return nil
    }
}

struct PlaceFormView: View {

    let journeyId: UUID
    let mode: PlaceFormMode
    let onSave: (PlaceToVisit) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    // Form fields
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var category: PlaceCategory = .other
    @State private var hasPlannedDate: Bool = false
    @State private var plannedDate: Date = Date()
    @State private var urlString: String = ""
    @State private var notes: String = ""
    @State private var isVisited: Bool = false

    // Validation
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                placeInfoSection
                urlSection
                categorySection
                dateSection
                notesSection
            }
            .navigationTitle(mode.isEditing ? L("place.form.edit_title") : L("place.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        savePlace()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                analytics.trackScreen("place_form_screen")
                loadExistingData()
            }
            .alert(L("place.form.validation.error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Form Sections

    private var placeInfoSection: some View {
        Section {
            TextField(L("place.form.name"), text: $name)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField(L("place.form.address"), text: $address)
                        .textContentType(.fullStreetAddress)
                        .keyboardType(.default)
                        .autocapitalization(.none)

                    // Copy button for address
                    if !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        CopyButton(text: address)
                    }

                    // Show link icon if address is a URL
                    if isAddressURL {
                        Button(action: openAddressURL) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(L("place.form.address_hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(L("place.form.section.info"))
        }
    }

    // MARK: - URL Section

    private var urlSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField(L("place.form.url"), text: $urlString)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    // Copy button for URL
                    if !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        CopyButton(text: urlString)
                    }

                    if isUrlValid {
                        Button(action: openUrl) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(L("place.form.url_hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(L("place.form.section.url"))
        }
    }

    // MARK: - URL Helpers

    private var isUrlValid: Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }

    private func openUrl() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return }
        UIApplication.shared.open(url)
    }

    private var isAddressURL: Bool {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://")
    }

    private func openAddressURL() {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return }
        UIApplication.shared.open(url)
    }

    private var categorySection: some View {
        Section {
            Picker(L("place.form.category"), selection: $category) {
                ForEach(PlaceCategory.allCases, id: \.self) { cat in
                    Label(cat.displayName, systemImage: cat.icon)
                        .tag(cat)
                }
            }

            if mode.isEditing {
                Toggle(L("place.form.visited"), isOn: $isVisited)
            }
        } header: {
            Text(L("place.form.section.category"))
        }
    }

    private var dateSection: some View {
        Section {
            Toggle(L("place.form.has_planned_date"), isOn: $hasPlannedDate)

            if hasPlannedDate {
                DatePicker(
                    L("place.form.planned_date"),
                    selection: $plannedDate,
                    displayedComponents: [.date]
                )
            }
        } header: {
            Text(L("place.form.section.date"))
        }
    }

    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
        } header: {
            Text(L("place.form.section.notes"))
        }
    }

    // MARK: - Private Methods

    private func loadExistingData() {
        if let place = mode.existingPlace {
            name = place.name
            address = place.address ?? ""
            category = place.category
            isVisited = place.isVisited
            urlString = place.url ?? ""
            notes = place.notes ?? ""

            if let date = place.plannedDate {
                hasPlannedDate = true
                plannedDate = date
            }
        }
    }

    private func savePlace() {
        // Validate
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            validationMessage = L("place.form.validation.name_required")
            showValidationError = true
            return
        }

        let place: PlaceToVisit

        let trimmedUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingPlace = mode.existingPlace {
            // Update existing place
            place = PlaceToVisit(
                id: existingPlace.id,
                journeyId: journeyId,
                name: trimmedName,
                address: address.isEmpty ? nil : address,
                category: category,
                isVisited: isVisited,
                plannedDate: hasPlannedDate ? plannedDate : nil,
                url: trimmedUrl.isEmpty ? nil : trimmedUrl,
                notes: notes.isEmpty ? nil : notes,
                createdAt: existingPlace.createdAt
            )
            analytics.trackEvent("place_updated", properties: ["place_id": existingPlace.id.uuidString])
        } else {
            // Create new place
            place = PlaceToVisit(
                journeyId: journeyId,
                name: trimmedName,
                address: address.isEmpty ? nil : address,
                category: category,
                isVisited: false,
                plannedDate: hasPlannedDate ? plannedDate : nil,
                url: trimmedUrl.isEmpty ? nil : trimmedUrl,
                notes: notes.isEmpty ? nil : notes
            )
            analytics.trackEvent("place_created", properties: [
                "journey_id": journeyId.uuidString,
                "category": category.rawValue
            ])
        }

        onSave(place)
        dismiss()
    }
}

#Preview {
    PlaceFormView(
        journeyId: UUID(),
        mode: .add,
        onSave: { _ in }
    )
}
