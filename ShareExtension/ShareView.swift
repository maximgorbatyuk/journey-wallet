import SwiftUI

/// SwiftUI view for the Share Extension interface.
/// Handles both file sharing and text/URL sharing flows.
struct ShareView: View {
    @ObservedObject var viewModel: ShareViewModel

    var body: some View {
        NavigationView {
            content
                .navigationTitle(L("share.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L("Cancel")) {
                            viewModel.cancel()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(L("Save")) {
                            viewModel.save()
                        }
                        .disabled(!viewModel.canSave)
                        .fontWeight(.semibold)
                    }
                }
        }
        .overlay {
            if viewModel.isSaving {
                savingOverlay
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            Form {
                if viewModel.isFileBased {
                    filesSection
                } else {
                    contentPreviewSection
                    entityTypeSection
                    entityFormSection
                }

                journeySection

                if let error = viewModel.errorMessage {
                    errorSection(error)
                }
            }
        }
    }

    // MARK: - File Sharing

    private var filesSection: some View {
        Section(header: Text(L("share.file_section"))) {
            ForEach(viewModel.files.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 12) {
                    // Original file info (not editable)
                    HStack(spacing: 12) {
                        fileIcon(for: viewModel.files[index].fileExtension)

                        Text(viewModel.files[index].originalName)
                            .font(.body)
                    }

                    // Optional custom name input
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("share.document_name") + " (" + L("Optional") + ")")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField(L("share.document_name_placeholder"), text: $viewModel.files[index].customName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Text/URL Sharing

    private var contentPreviewSection: some View {
        Section(header: Text(L("share.content_preview"))) {
            VStack(alignment: .leading, spacing: 8) {
                if let url = viewModel.sharedURL {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text(url.host ?? url.absoluteString)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }

                Text(viewModel.sharedText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(5)
            }
            .padding(.vertical, 4)
        }
    }

    private var entityTypeSection: some View {
        Section(header: Text(L("share.entity_type.title"))) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ShareEntityType.allCases) { entityType in
                    EntityTypeButton(
                        entityType: entityType,
                        isSelected: viewModel.selectedEntityType == entityType
                    ) {
                        viewModel.selectedEntityType = entityType
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var entityFormSection: some View {
        Section(header: Text(L("share.form.details"))) {
            // URL hint for Place entity type
            if viewModel.selectedEntityType == .place && viewModel.sharedURL != nil {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text(L("share.place.url_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Title field
            VStack(alignment: .leading, spacing: 4) {
                Text(L("share.form.title"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField(L("share.form.title_placeholder"), text: $viewModel.entityTitle)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.vertical, 4)

            // Booking reference (for transport, hotel, car rental)
            if [.transport, .hotel, .carRental].contains(viewModel.selectedEntityType) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("share.form.booking_ref"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextField(L("share.form.booking_ref_placeholder"), text: $viewModel.bookingReference)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.vertical, 4)
            }

            // Notes field
            VStack(alignment: .leading, spacing: 4) {
                Text(L("share.form.notes"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $viewModel.entityNotes)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Journey Section

    private var journeySection: some View {
        Section(header: Text(L("share.journey_section"))) {
            if viewModel.journeys.isEmpty {
                noJourneysView
            } else {
                Picker(L("share.journey_section"), selection: $viewModel.selectedJourneyId) {
                    ForEach(viewModel.journeys) { journey in
                        journeyRow(journey)
                            .tag(journey.id as UUID?)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
    }

    private var noJourneysView: some View {
        VStack(spacing: 12) {
            Image(systemName: "suitcase")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text(L("share.no_journeys"))
                .font(.headline)
                .foregroundColor(.gray)

            Text(L("share.no_journeys_hint"))
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func journeyRow(_ journey: Journey) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(journey.name)
                    .font(.body)

                if !journey.destination.isEmpty {
                    Text(journey.destination)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if journey.isActive {
                Text(L("Active"))
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(4)
            }
        }
    }

    // MARK: - Error & Saving

    private func errorSection(_ message: String) -> some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .foregroundColor(.red)
            }
        }
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text(L("share.saving"))
                    .font(.headline)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }

    // MARK: - Helpers

    private func fileIcon(for extension: String) -> some View {
        let iconName: String
        let color: Color

        switch `extension`.lowercased() {
        case "pdf":
            iconName = "doc.fill"
            color = .red
        case "jpg", "jpeg", "png", "heic":
            iconName = "photo.fill"
            color = .blue
        default:
            iconName = "doc.fill"
            color = .gray
        }

        return Image(systemName: iconName)
            .font(.title2)
            .foregroundColor(color)
            .frame(width: 32)
    }
}

// MARK: - Entity Type Button

struct EntityTypeButton: View {
    let entityType: ShareEntityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: entityType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(entityType.title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
