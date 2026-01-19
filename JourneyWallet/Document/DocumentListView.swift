import SwiftUI

struct DocumentListView: View {

    let journeyId: UUID
    private let initialDocumentToOpen: Document?

    @State private var viewModel: DocumentListViewModel
    @State private var showDocumentPicker = false
    @State private var selectedDocument: Document?
    @State private var showDeleteConfirmation = false
    @State private var documentToDelete: Document?
    @State private var hasOpenedInitialDocument = false
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID, initialDocumentToOpen: Document? = nil) {
        self.journeyId = journeyId
        self.initialDocumentToOpen = initialDocumentToOpen
        _viewModel = State(initialValue: DocumentListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            filterChipsView
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Summary bar
            if !viewModel.documents.isEmpty {
                summaryBar
            }

            // Documents list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredDocuments.isEmpty {
                emptyStateView
            } else {
                documentsList
            }
        }
        .background(Color(.systemGray6))
        .navigationTitle(L("document.list.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showDocumentPicker = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("document_list_screen")
            viewModel.loadDocuments()

            // Open initial document if provided
            if let document = initialDocumentToOpen, !hasOpenedInitialDocument {
                hasOpenedInitialDocument = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    selectedDocument = document
                }
            }
        }
        .refreshable {
            viewModel.refreshDocuments()
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(journeyId: journeyId) { success in
                if success {
                    viewModel.refreshDocuments()
                }
            }
        }
        .sheet(item: $selectedDocument) { document in
            DocumentPreviewView(document: document, journeyId: journeyId)
        }
        .alert(L("document.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Delete"), role: .destructive) {
                if let document = documentToDelete {
                    _ = viewModel.deleteDocument(document)
                }
            }
        } message: {
            Text(L("document.delete_confirm.message"))
        }
    }

    // MARK: - Filter Chips

    private var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DocumentFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                    }
                }
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack {
            Label("\(viewModel.totalCount) \(L("document.summary.files"))", systemImage: "doc.fill")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(viewModel.formattedTotalSize)
                .font(.caption)
                .foregroundColor(.orange)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text(L("document.list.empty.title"))
                .font(.headline)
                .foregroundColor(.gray)

            Text(L("document.list.empty.message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text(L("document.list.add_first"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Documents List

    private var documentsList: some View {
        List {
            ForEach(viewModel.filteredDocuments) { document in
                DocumentListRow(document: document)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDocument = document
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            documentToDelete = document
                            showDeleteConfirmation = true
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Document List Row

struct DocumentListRow: View {

    let document: Document

    /// Check if document has a custom name set
    private var hasCustomName: Bool {
        if let name = document.name, !name.isEmpty {
            return true
        }
        return false
    }

    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconBackgroundColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: document.fileType.icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconBackgroundColor)
            }

            // Document info
            VStack(alignment: .leading, spacing: 4) {
                if hasCustomName {
                    // Show custom name as primary, filename as secondary
                    Text(document.name!)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(document.fileName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    // Show filename as primary, filepath as secondary (if available)
                    Text(document.fileName)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if let filePath = document.filePath, !filePath.isEmpty {
                        Text(filePath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        HStack(spacing: 8) {
                            Text(document.fileType.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(document.formattedFileSize)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var iconBackgroundColor: Color {
        switch document.fileType {
        case .pdf:
            return .red
        case .jpeg, .png, .heic:
            return .blue
        case .other:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        DocumentListView(journeyId: UUID())
    }
}
