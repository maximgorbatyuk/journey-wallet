import SwiftUI
import QuickLook

struct FolderContentsView: View {
    let folder: StorageItem

    @State private var files: [StorageItem] = []
    @State private var journeyName: String?
    @State private var selectedFile: StorageItem?
    @State private var showDeleteConfirmation = false
    @State private var fileToDelete: StorageItem?
    @State private var isLoading = true

    private let service = DocumentStorageService.shared
    private let journeysRepository = DatabaseManager.shared.journeysRepository

    var body: some View {
        List {
            if let journeyId = UUID(uuidString: folder.name) {
                if let name = journeyName {
                    Section {
                        HStack {
                            Image(systemName: "suitcase.fill")
                                .foregroundColor(.blue)
                            Text("Journey: \(name)")
                                .font(.subheadline)
                        }
                    }
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if files.isEmpty {
                Section {
                    Text(L("developer.document_storage.no_files"))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                Section {
                    ForEach(files) { file in
                        FileRow(item: file)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showDeleteConfirmation = true
                                } label: {
                                    Label(L("Delete"), systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedFile = file
                            }
                    }
                }
            }
        }
        .navigationTitle(String(folder.name.prefix(12)) + (folder.name.count > 12 ? "..." : ""))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFile) { file in
            FileDetailView(file: file, journeyName: journeyName)
        }
        .alert(L("developer.document_storage.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Delete"), role: .destructive) {
                if let file = fileToDelete {
                    deleteFile(file)
                }
            }
        } message: {
            Text(L("developer.document_storage.delete_confirm.message"))
        }
        .onAppear {
            loadData()
            loadJourneyName()
        }
    }

    private func loadData() {
        isLoading = true
        let items = service.getContents(of: folder.url)
        files = items.filter { !$0.isDirectory }
        isLoading = false
    }

    private func loadJourneyName() {
        guard let journeyId = UUID(uuidString: folder.name) else { return }
        let journeys = journeysRepository?.fetchAll()
        journeyName = journeys?.first { $0.id == journeyId }?.name
    }

    private func deleteFile(_ file: StorageItem) {
        _ = service.deleteItem(at: file.url)
        files.removeAll { $0.id == file.id }
    }
}
