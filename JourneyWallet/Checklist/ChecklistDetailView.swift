import SwiftUI

struct ChecklistDetailView: View {
    let journeyId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChecklistDetailViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    init(checklist: Checklist, journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: ChecklistDetailViewModel(checklist: checklist, journeyId: journeyId))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter section
            filterSection
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Progress bar
            if !viewModel.items.isEmpty {
                progressSection
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            // Content
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.items.isEmpty {
                emptyStateView
            } else if viewModel.filteredItems.isEmpty {
                noMatchingItemsView
            } else {
                itemsList
            }
        }
        .navigationTitle(viewModel.checklist.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        viewModel.showAddItemSheet = true
                    }) {
                        Label(L("checklist.items.add"), systemImage: "plus")
                    }

                    Divider()

                    Button(action: {
                        viewModel.showMoveCheckedConfirmation = true
                    }) {
                        Label(L("checklist.items.move_completed"), systemImage: "arrow.down.to.line")
                    }
                    .disabled(!viewModel.hasCheckedItems)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("checklist_detail_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddItemSheet) {
            ChecklistItemFormView { name in
                viewModel.addItem(name: name)
                analytics.trackEvent("checklist_item_added", properties: ["checklist_id": viewModel.checklist.id.uuidString])
            }
        }
        .sheet(item: $viewModel.itemToEdit) { item in
            ChecklistItemFormView(existingItem: item) { name in
                var updated = item
                updated.name = name
                viewModel.updateItem(updated)
                analytics.trackEvent("checklist_item_edited", properties: ["item_id": item.id.uuidString])
            }
        }
        .alert(
            L("checklist.items.move_completed.title"),
            isPresented: $viewModel.showMoveCheckedConfirmation
        ) {
            Button(L("checklist.items.move_completed.cancel"), role: .cancel) {}
            Button(L("checklist.items.move_completed.confirm"), role: .destructive) {
                viewModel.moveCheckedItemsToEnd()
                analytics.trackEvent("checklist_items_moved_to_end", properties: ["checklist_id": viewModel.checklist.id.uuidString])
            }
        } message: {
            Text(L("checklist.items.move_completed.message"))
        }
    }

    // MARK: - Subviews

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChecklistItemFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                        viewModel.applyFilters()
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: 4) {
            ProgressView(value: viewModel.progressPercentage)
                .tint(progressColor)

            HStack {
                Text(String(format: L("checklist.items.progress"), viewModel.progress.checked, viewModel.progress.total))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(viewModel.progressPercentage * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var progressColor: Color {
        if viewModel.progress.total == 0 {
            return .gray
        } else if viewModel.progress.checked == viewModel.progress.total {
            return .green
        } else if viewModel.progressPercentage > 0.5 {
            return .blue
        } else {
            return .orange
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(L("checklist.items.empty"), systemImage: "checklist")
        } description: {
            Text(L("checklist.items.empty.description"))
        } actions: {
            Button(action: {
                viewModel.showAddItemSheet = true
            }) {
                Text(L("checklist.items.add"))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var noMatchingItemsView: some View {
        ContentUnavailableView {
            Label(L("checklist.items.empty"), systemImage: "magnifyingglass")
        } description: {
            Text(L("checklist.items.empty.description"))
        }
    }

    private var itemsList: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
                ChecklistItemRow(item: item) {
                    viewModel.toggleItem(item)
                    analytics.trackEvent("checklist_item_toggled", properties: [
                        "item_id": item.id.uuidString,
                        "is_checked": String(!item.isChecked)
                    ])
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteItem(item)
                        analytics.trackEvent("checklist_item_deleted", properties: ["item_id": item.id.uuidString])
                    } label: {
                        Label(L("common.delete"), systemImage: "trash")
                    }

                    Button {
                        viewModel.itemToEdit = item
                    } label: {
                        Label(L("common.edit"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .draggable(item) {
                    ChecklistItemRow(item: item, onToggle: {})
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .onMove(perform: viewModel.moveItem)
            .dropDestination(for: ChecklistItem.self) { items, offset in
                guard let item = items.first,
                      let sourceIndex = viewModel.items.firstIndex(where: { $0.id == item.id }) else {
                    return
                }
                viewModel.moveItem(from: IndexSet(integer: sourceIndex), to: offset)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ChecklistDetailView(
            checklist: Checklist(journeyId: UUID(), name: "Packing"),
            journeyId: UUID()
        )
    }
}
