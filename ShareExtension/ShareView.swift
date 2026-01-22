import SwiftUI

/// SwiftUI view for the Share Extension interface.
/// Allows user to select a journey and customize the document name before saving.
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
                filesSection
                journeySection

                if let error = viewModel.errorMessage {
                    errorSection(error)
                }
            }
        }
    }

    private var filesSection: some View {
        Section(header: Text(L("share.file_section"))) {
            ForEach(viewModel.files.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    fileIcon(for: viewModel.files[index].fileExtension)

                    VStack(alignment: .leading, spacing: 4) {
                        TextField(L("share.document_name"), text: $viewModel.files[index].displayName)
                            .font(.body)

                        Text(viewModel.files[index].originalName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

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
