import Foundation
import SwiftUI

enum PlaceCategory: String, Codable, CaseIterable, Identifiable {
    case restaurant
    case attraction
    case museum
    case shopping
    case nature
    case entertainment
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .restaurant: return L("place.category.restaurant")
        case .attraction: return L("place.category.attraction")
        case .museum: return L("place.category.museum")
        case .shopping: return L("place.category.shopping")
        case .nature: return L("place.category.nature")
        case .entertainment: return L("place.category.entertainment")
        case .other: return L("place.category.other")
        }
    }

    var icon: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .attraction: return "star.fill"
        case .museum: return "building.columns.fill"
        case .shopping: return "bag.fill"
        case .nature: return "leaf.fill"
        case .entertainment: return "theatermasks.fill"
        case .other: return "mappin"
        }
    }

    var iconName: String { icon }

    var color: Color {
        switch self {
        case .restaurant: return .orange
        case .attraction: return .yellow
        case .museum: return .brown
        case .shopping: return .pink
        case .nature: return .green
        case .entertainment: return .purple
        case .other: return .gray
        }
    }
}

struct PlaceToVisit: Codable, Identifiable, Equatable {
    let id: UUID
    let journeyId: UUID
    var name: String
    var address: String?
    var category: PlaceCategory
    var isVisited: Bool
    var plannedDate: Date?
    var url: String?
    var notes: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        journeyId: UUID,
        name: String,
        address: String? = nil,
        category: PlaceCategory = .other,
        isVisited: Bool = false,
        plannedDate: Date? = nil,
        url: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.journeyId = journeyId
        self.name = name
        self.address = address
        self.category = category
        self.isVisited = isVisited
        self.plannedDate = plannedDate
        self.url = url
        self.notes = notes
        self.createdAt = createdAt
    }

    var isPastPlannedDate: Bool {
        guard let plannedDate = plannedDate else { return false }
        return plannedDate < Date() && !isVisited
    }
}
