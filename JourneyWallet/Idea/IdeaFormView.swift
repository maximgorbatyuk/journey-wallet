import SwiftUI

enum IdeaFormMode {
    case add
    case edit(Idea)

    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }

    var existingIdea: Idea? {
        if case .edit(let idea) = self { return idea }
        return nil
    }
}

struct IdeaFormView: View {

    let journeyId: UUID
    let mode: IdeaFormMode
    let onSave: (Idea) -> Void
    let onMove: ((UUID) -> Bool)?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    // Form fields
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var urlString: String = ""
    @State private var isDone: Bool = false

    // Validation
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    // Move sheet
    @State private var showMoveSheet: Bool = false

    init(journeyId: UUID, mode: IdeaFormMode, onSave: @escaping (Idea) -> Void, onMove: ((UUID) -> Bool)? = nil) {
        self.journeyId = journeyId
        self.mode = mode
        self.onSave = onSave
        self.onMove = onMove
    }

    var body: some View {
        NavigationView {
            Form {
                infoSection
                descriptionSection
                urlSection

                if mode.isEditing {
                    statusSection
                }

                if mode.isEditing, onMove != nil {
                    moveSection
                }
            }
            .navigationTitle(mode.isEditing ? L("idea.form.title.edit") : L("idea.form.title.new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveIdea()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                analytics.trackScreen("idea_form_screen")
                loadExistingData()
            }
            .alert(L("idea.form.field.title.required"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveToJourneySheet(
                    currentJourneyId: journeyId,
                    entityName: L("idea.detail.title"),
                    onMove: { newJourneyId in
                        if onMove?(newJourneyId) == true {
                            dismiss()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Form Sections

    private var infoSection: some View {
        Section {
            TextField(L("idea.form.field.title"), text: $title)
        } header: {
            Text(L("idea.form.section.info"))
        }
    }

    private var descriptionSection: some View {
        Section {
            TextEditor(text: $descriptionText)
                .frame(minHeight: 80)
        } header: {
            Text(L("idea.form.section.description"))
        }
    }

    private var urlSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField(L("idea.form.field.url"), text: $urlString)
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

                Text(L("idea.form.field.url.hint"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(L("idea.form.section.link"))
        }
    }

    private var statusSection: some View {
        Section {
            Toggle(L("idea.form.field.done"), isOn: $isDone)
        } header: {
            Text(L("idea.form.section.status"))
        }
    }

    private var moveSection: some View {
        Section {
            Button {
                showMoveSheet = true
            } label: {
                Label(L("idea.form.move_to_journey"), systemImage: "folder")
            }
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

    // MARK: - Private Methods

    private func loadExistingData() {
        if let idea = mode.existingIdea {
            title = idea.title
            descriptionText = idea.description ?? ""
            urlString = idea.url ?? ""
            isDone = idea.isDone
        }
    }

    private func saveIdea() {
        // Validate
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTitle.isEmpty {
            validationMessage = L("idea.form.field.title.required")
            showValidationError = true
            return
        }

        let idea: Idea
        let trimmedUrl = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingIdea = mode.existingIdea {
            // Update existing idea
            idea = Idea(
                id: existingIdea.id,
                journeyId: journeyId,
                title: trimmedTitle,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                url: trimmedUrl.isEmpty ? nil : trimmedUrl,
                isDone: isDone,
                createdAt: existingIdea.createdAt,
                updatedAt: Date()
            )
            analytics.trackEvent("idea_updated", properties: ["idea_id": existingIdea.id.uuidString])
        } else {
            // Create new idea
            idea = Idea(
                journeyId: journeyId,
                title: trimmedTitle,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                url: trimmedUrl.isEmpty ? nil : trimmedUrl
            )
            analytics.trackEvent("idea_created", properties: ["journey_id": journeyId.uuidString])
        }

        onSave(idea)
        dismiss()
    }
}

#Preview {
    IdeaFormView(
        journeyId: UUID(),
        mode: .add,
        onSave: { _ in },
        onMove: nil
    )
}
