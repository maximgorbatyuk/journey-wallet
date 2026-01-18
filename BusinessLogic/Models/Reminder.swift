import Foundation

enum ReminderEntityType: String, Codable, CaseIterable, Identifiable {
    case transport
    case hotel
    case carRental
    case place
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transport: return L("reminder.entity.transport")
        case .hotel: return L("reminder.entity.hotel")
        case .carRental: return L("reminder.entity.car_rental")
        case .place: return L("reminder.entity.place")
        case .custom: return L("reminder.entity.custom")
        }
    }

    var icon: String {
        switch self {
        case .transport: return "airplane"
        case .hotel: return "bed.double.fill"
        case .carRental: return "car.fill"
        case .place: return "mappin"
        case .custom: return "bell.fill"
        }
    }
}

struct Reminder: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var title: String
    var reminderDate: Date
    var isCompleted: Bool
    var relatedEntityType: ReminderEntityType?
    var relatedEntityId: UUID?
    var notificationId: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        title: String,
        reminderDate: Date,
        isCompleted: Bool = false,
        relatedEntityType: ReminderEntityType? = nil,
        relatedEntityId: UUID? = nil,
        notificationId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.title = title
        self.reminderDate = reminderDate
        self.isCompleted = isCompleted
        self.relatedEntityType = relatedEntityType
        self.relatedEntityId = relatedEntityId
        self.notificationId = notificationId
        self.createdAt = createdAt
    }

    var isOverdue: Bool {
        !isCompleted && reminderDate < Date()
    }

    var isUpcoming: Bool {
        !isCompleted && reminderDate > Date()
    }

    var isDueToday: Bool {
        guard !isCompleted else { return false }
        return Calendar.current.isDateInToday(reminderDate)
    }

    var isDueTomorrow: Bool {
        guard !isCompleted else { return false }
        return Calendar.current.isDateInTomorrow(reminderDate)
    }

    var isDueThisWeek: Bool {
        guard !isCompleted else { return false }
        let now = Date()
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return reminderDate > now && reminderDate <= weekFromNow
    }
}
