import SwiftUI

struct NotificationsView: View {

    @State private var viewModel = NotificationsViewModel()
    @ObservedObject private var analytics = AnalyticsService.shared

    private let journeysRepository: JourneysRepository?

    init() {
        self.journeysRepository = DatabaseManager.shared.journeysRepository
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                filterChipsSection
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                // Summary bar
                if !viewModel.reminders.isEmpty {
                    summaryBar
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.groupedReminders.isEmpty {
                    emptyStateView
                } else {
                    reminderList
                }
            }
            .navigationTitle(L("reminder.list.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        analytics.trackEvent("add_reminder_button_clicked", properties: [
                            "screen": "notifications_screen"
                        ])
                        viewModel.showAddReminderSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                analytics.trackScreen("notifications_screen")
                viewModel.loadData()
            }
            .refreshable {
                viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showAddReminderSheet) {
                ReminderFormView(
                    mode: .add,
                    onSave: { reminder in
                        viewModel.addReminder(reminder)
                    }
                )
            }
            .sheet(item: $viewModel.reminderToEdit) { reminder in
                ReminderFormView(
                    mode: .edit(reminder),
                    onSave: { updatedReminder in
                        viewModel.updateReminder(updatedReminder)
                    }
                )
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChipsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReminderFilter.allCases) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 16) {
            Label("\(viewModel.totalCount) \(L("reminder.summary.pending"))", systemImage: "bell.fill")
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.overdueCount > 0 {
                Label("\(viewModel.overdueCount) \(L("reminder.summary.overdue"))", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if viewModel.todayCount > 0 {
                Label("\(viewModel.todayCount) \(L("reminder.summary.today"))", systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Reminder List

    private var reminderList: some View {
        List {
            ForEach(viewModel.groupedReminders) { group in
                Section(header: Text(group.title)) {
                    ForEach(group.reminders) { reminder in
                        ReminderListRow(
                            reminder: reminder,
                            journeyName: viewModel.getJourneyName(for: reminder.journeyId),
                            onToggleCompleted: {
                                viewModel.toggleCompleted(reminder)
                            }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.reminderToEdit = reminder
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deleteReminder(reminder)
                            } label: {
                                Label(L("Delete"), systemImage: "trash")
                            }

                            Button {
                                viewModel.reminderToEdit = reminder
                            } label: {
                                Label(L("Edit"), systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                viewModel.toggleCompleted(reminder)
                            } label: {
                                if reminder.isCompleted {
                                    Label(L("reminder.action.mark_incomplete"), systemImage: "arrow.uturn.backward.circle")
                                } else {
                                    Label(L("reminder.action.mark_complete"), systemImage: "checkmark.circle")
                                }
                            }
                            .tint(reminder.isCompleted ? .orange : .green)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(emptyStateTitle)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if viewModel.selectedFilter == .all {
                Button(action: {
                    viewModel.showAddReminderSheet = true
                }) {
                    Label(L("reminder.list.add_first"), systemImage: "plus")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var emptyStateIcon: String {
        switch viewModel.selectedFilter {
        case .all: return "bell.slash"
        case .today: return "calendar"
        case .upcoming: return "calendar.badge.clock"
        case .overdue: return "checkmark.circle"
        case .completed: return "tray"
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .all: return L("reminder.list.empty.title")
        case .today: return L("reminder.list.empty.today.title")
        case .upcoming: return L("reminder.list.empty.upcoming.title")
        case .overdue: return L("reminder.list.empty.overdue.title")
        case .completed: return L("reminder.list.empty.completed.title")
        }
    }

    private var emptyStateMessage: String {
        switch viewModel.selectedFilter {
        case .all: return L("reminder.list.empty.message")
        case .today: return L("reminder.list.empty.today.message")
        case .upcoming: return L("reminder.list.empty.upcoming.message")
        case .overdue: return L("reminder.list.empty.overdue.message")
        case .completed: return L("reminder.list.empty.completed.message")
        }
    }
}

// MARK: - Reminder List Row

struct ReminderListRow: View {

    let reminder: Reminder
    let journeyName: String
    let onToggleCompleted: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button(action: onToggleCompleted) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(reminder.isCompleted ? .green : (reminder.isOverdue ? .red : .gray))
            }
            .buttonStyle(.plain)

            // Reminder info
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // Journey name
                    Label(journeyName, systemImage: "suitcase.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Entity type if present
                    if let entityType = reminder.relatedEntityType {
                        Label(entityType.displayName, systemImage: entityType.icon)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }

                // Date and time
                HStack(spacing: 4) {
                    Image(systemName: reminder.isOverdue ? "exclamationmark.circle.fill" : "clock")
                        .font(.caption)
                        .foregroundColor(dateColor)

                    Text(formatDate(reminder.reminderDate))
                        .font(.caption)
                        .foregroundColor(dateColor)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var dateColor: Color {
        if reminder.isCompleted {
            return .secondary
        } else if reminder.isOverdue {
            return .red
        } else if reminder.isDueToday {
            return .orange
        } else {
            return .secondary
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()

        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "\(L("reminder.date.today")), \(formatter.string(from: date))"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "\(L("reminder.date.tomorrow")), \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NotificationsView()
}
