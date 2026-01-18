import SwiftUI

enum QuickAddEntityType: String, CaseIterable, Identifiable {
    case transport
    case hotel
    case carRental
    case document
    case note
    case place
    case reminder
    case expense

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transport: return L("quick_add.transport")
        case .hotel: return L("quick_add.hotel")
        case .carRental: return L("quick_add.car_rental")
        case .document: return L("quick_add.document")
        case .note: return L("quick_add.note")
        case .place: return L("quick_add.place")
        case .reminder: return L("quick_add.reminder")
        case .expense: return L("quick_add.expense")
        }
    }

    var iconName: String {
        switch self {
        case .transport: return "airplane"
        case .hotel: return "building.2.fill"
        case .carRental: return "car.fill"
        case .document: return "doc.fill"
        case .note: return "note.text"
        case .place: return "mappin.circle.fill"
        case .reminder: return "bell.fill"
        case .expense: return "dollarsign.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .transport: return .blue
        case .hotel: return .purple
        case .carRental: return .green
        case .document: return .orange
        case .note: return .yellow
        case .place: return .red
        case .reminder: return .red
        case .expense: return .green
        }
    }
}
