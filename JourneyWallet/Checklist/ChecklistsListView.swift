import SwiftUI

struct ChecklistsListView: View {
    let journeyId: UUID

    @State private var viewModel: ChecklistsListViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: ChecklistsListViewModel(journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.checklists.isEmpty {
                emptyStateView
            } else {
                checklistsList
            }
        }
        .navigationTitle(L("checklists.title"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_checklist_button_clicked", properties: ["journey_id": journeyId.uuidString])
                    viewModel.showAddChecklistSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("checklists_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddChecklistSheet) {
            ChecklistFormView { name in
                viewModel.addChecklist(name: name)
                analytics.trackEvent("checklist_created", properties: ["journey_id": journeyId.uuidString])
            }
        }
        .sheet(item: $viewModel.checklistToEdit) { checklist in
            ChecklistFormView(existingChecklist: checklist) { name in
                var updated = checklist
                updated.name = name
                viewModel.updateChecklist(updated)
                analytics.trackEvent("checklist_edited", properties: ["checklist_id": checklist.id.uuidString])
            }
        }
        .sheet(item: $viewModel.checklistToView) { checklist in
            NavigationView {
                ChecklistDetailView(checklist: checklist, journeyId: journeyId)
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(L("checklists.empty"), systemImage: "checklist")
        } description: {
            Text(L("checklists.empty.description"))
        } actions: {
            Button(action: {
                viewModel.showAddChecklistSheet = true
            }) {
                Text(L("checklists.add"))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var checklistsList: some View {
        List {
            ForEach(viewModel.checklists) { checklist in
                ChecklistRow(
                    checklist: checklist,
                    progress: viewModel.getProgress(for: checklist.id)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.checklistToView = checklist
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteChecklist(checklist)
                        analytics.trackEvent("checklist_deleted", properties: ["checklist_id": checklist.id.uuidString])
                    } label: {
                        Label(L("common.delete"), systemImage: "trash")
                    }

                    Button {
                        viewModel.checklistToEdit = checklist
                    } label: {
                        Label(L("common.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .draggable(checklist) {
                    ChecklistRow(
                        checklist: checklist,
                        progress: viewModel.getProgress(for: checklist.id)
                    )
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .onMove(perform: viewModel.moveChecklist)
            .dropDestination(for: Checklist.self) { items, offset in
                guard let item = items.first,
                      let sourceIndex = viewModel.checklists.firstIndex(where: { $0.id == item.id }) else {
                    return
                }
                viewModel.moveChecklist(from: IndexSet(integer: sourceIndex), to: offset)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ChecklistsListView(journeyId: UUID())
    }
}
