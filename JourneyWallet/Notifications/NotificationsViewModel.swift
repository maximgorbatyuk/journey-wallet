import Foundation

@Observable
@MainActor
class NotificationsViewModel {

    var reminders: [Reminder] = []
    var isLoading = false
    var showAddReminderSheet = false
    var reminderToEdit: Reminder?
    var selectedFilter: ReminderFilter = .all

    private let remindersRepository: RemindersRepository?
    private let journeysRepository: JourneysRepository?

    // Cache for journey names
    private var journeyNamesCache: [UUID: String] = [:]

    init() {
        self.remindersRepository = DatabaseManager.shared.remindersRepository
        self.journeysRepository = DatabaseManager.shared.journeysRepository
    }

    // MARK: - Computed Properties

    var filteredReminders: [Reminder] {
        switch selectedFilter {
        case .all:
            return reminders.filter { !$0.isCompleted }
        case .today:
            return reminders.filter { $0.isDueToday }
        case .upcoming:
            return reminders.filter { $0.isUpcoming && !$0.isDueToday }
        case .overdue:
            return reminders.filter { $0.isOverdue }
        case .completed:
            return reminders.filter { $0.isCompleted }
        }
    }

    var groupedReminders: [ReminderGroup] {
        let filtered = filteredReminders

        if selectedFilter == .completed {
            return [ReminderGroup(title: L("reminder.group.completed"), reminders: filtered)]
        }

        var groups: [ReminderGroup] = []

        // Overdue
        let overdue = filtered.filter { $0.isOverdue }
        if !overdue.isEmpty {
            groups.append(ReminderGroup(title: L("reminder.group.overdue"), reminders: overdue))
        }

        // Today
        let today = filtered.filter { $0.isDueToday }
        if !today.isEmpty {
            groups.append(ReminderGroup(title: L("reminder.group.today"), reminders: today))
        }

        // Tomorrow
        let tomorrow = filtered.filter { $0.isDueTomorrow }
        if !tomorrow.isEmpty {
            groups.append(ReminderGroup(title: L("reminder.group.tomorrow"), reminders: tomorrow))
        }

        // This Week (excluding today and tomorrow)
        let thisWeek = filtered.filter { reminder in
            reminder.isDueThisWeek && !reminder.isDueToday && !reminder.isDueTomorrow
        }
        if !thisWeek.isEmpty {
            groups.append(ReminderGroup(title: L("reminder.group.this_week"), reminders: thisWeek))
        }

        // Later
        let later = filtered.filter { reminder in
            reminder.isUpcoming && !reminder.isDueToday && !reminder.isDueTomorrow && !reminder.isDueThisWeek
        }
        if !later.isEmpty {
            groups.append(ReminderGroup(title: L("reminder.group.later"), reminders: later))
        }

        return groups
    }

    var totalCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }

    var overdueCount: Int {
        reminders.filter { $0.isOverdue }.count
    }

    var todayCount: Int {
        reminders.filter { $0.isDueToday }.count
    }

    // MARK: - Data Operations

    func loadData() {
        isLoading = true
        reminders = remindersRepository?.fetchAll() ?? []
        loadJourneyNames()
        isLoading = false
    }

    private func loadJourneyNames() {
        let journeyIds = Set(reminders.map { $0.journeyId })
        for journeyId in journeyIds {
            if journeyNamesCache[journeyId] == nil {
                if let journey = journeysRepository?.fetchById(id: journeyId) {
                    journeyNamesCache[journeyId] = journey.name
                }
            }
        }
    }

    func getJourneyName(for journeyId: UUID) -> String {
        return journeyNamesCache[journeyId] ?? L("reminder.unknown_journey")
    }

    func toggleCompleted(_ reminder: Reminder) {
        if reminder.isCompleted {
            _ = remindersRepository?.markIncomplete(id: reminder.id)
            // Reschedule notification if date is in the future
            if reminder.reminderDate > Date() {
                rescheduleNotification(for: reminder)
            }
        } else {
            _ = remindersRepository?.markCompleted(id: reminder.id)
            // Cancel notification
            if let notificationId = reminder.notificationId {
                NotificationManager.shared.cancelNotification(notificationId)
            }
        }
        loadData()
    }

    func deleteReminder(_ reminder: Reminder) {
        // Cancel notification first
        if let notificationId = reminder.notificationId {
            NotificationManager.shared.cancelNotification(notificationId)
        }
        _ = remindersRepository?.delete(id: reminder.id)
        loadData()
    }

    func addReminder(_ reminder: Reminder) {
        // Schedule notification first
        let notificationId = NotificationManager.shared.scheduleNotification(
            title: L("reminder.notification.title"),
            body: reminder.title,
            on: reminder.reminderDate
        )

        // Create reminder with notification ID
        var reminderWithNotificationId = reminder
        reminderWithNotificationId.notificationId = notificationId

        _ = remindersRepository?.insert(reminderWithNotificationId)
        loadData()
    }

    func updateReminder(_ reminder: Reminder) {
        // Cancel old notification
        if let oldReminder = remindersRepository?.fetchById(id: reminder.id),
           let oldNotificationId = oldReminder.notificationId {
            NotificationManager.shared.cancelNotification(oldNotificationId)
        }

        // Schedule new notification if not completed and in the future
        var updatedReminder = reminder
        if !reminder.isCompleted && reminder.reminderDate > Date() {
            let notificationId = NotificationManager.shared.scheduleNotification(
                title: L("reminder.notification.title"),
                body: reminder.title,
                on: reminder.reminderDate
            )
            updatedReminder.notificationId = notificationId
        } else {
            updatedReminder.notificationId = nil
        }

        _ = remindersRepository?.update(updatedReminder)
        loadData()
    }

    private func rescheduleNotification(for reminder: Reminder) {
        guard reminder.reminderDate > Date() else { return }

        let notificationId = NotificationManager.shared.scheduleNotification(
            title: L("reminder.notification.title"),
            body: reminder.title,
            on: reminder.reminderDate
        )

        var updatedReminder = reminder
        updatedReminder.notificationId = notificationId
        _ = remindersRepository?.update(updatedReminder)
    }
}

// MARK: - Supporting Types

enum ReminderFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case upcoming
    case overdue
    case completed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return L("reminder.filter.all")
        case .today: return L("reminder.filter.today")
        case .upcoming: return L("reminder.filter.upcoming")
        case .overdue: return L("reminder.filter.overdue")
        case .completed: return L("reminder.filter.completed")
        }
    }
}

struct ReminderGroup: Identifiable {
    let id = UUID()
    let title: String
    let reminders: [Reminder]
}
