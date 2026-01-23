import Foundation

/// Entity types that can be created from shared content.
enum ShareEntityType: String, CaseIterable, Identifiable {
    case transport
    case hotel
    case carRental
    case note
    case place

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .transport: return "airplane"
        case .hotel: return "bed.double.fill"
        case .carRental: return "car.fill"
        case .note: return "note.text"
        case .place: return "mappin.circle.fill"
        }
    }

    var title: String {
        switch self {
        case .transport: return L("share.entity_type.transport")
        case .hotel: return L("share.entity_type.hotel")
        case .carRental: return L("share.entity_type.car_rental")
        case .note: return L("share.entity_type.note")
        case .place: return L("share.entity_type.place")
        }
    }
}

/// Analyzes shared content to suggest entity type and extract data.
struct ContentAnalyzer {
    /// Suggests the most likely entity type based on shared content.
    static func suggestEntityType(for text: String) -> ShareEntityType {
        let lowercased = text.lowercased()

        // Flight/transport keywords
        let transportKeywords = [
            "flight", "airline", "boarding", "departure", "arrival",
            "train", "bus", "ferry", "terminal", "gate",
            "рейс", "вылет", "прилет", "посадочный", "терминал",
            "uçuş", "kalkış", "varış", "flug", "abflug", "ankunft"
        ]
        if transportKeywords.contains(where: { lowercased.contains($0) }) {
            return .transport
        }

        // Hotel keywords
        let hotelKeywords = [
            "hotel", "check-in", "check-out", "reservation", "room",
            "booking.com", "airbnb", "hostel", "accommodation",
            "отель", "гостиница", "заселение", "выселение", "бронь",
            "otel", "konaklama", "hotel", "zimmer", "unterkunft"
        ]
        if hotelKeywords.contains(where: { lowercased.contains($0) }) {
            return .hotel
        }

        // Car rental keywords
        let carKeywords = [
            "car rental", "vehicle", "pickup", "drop-off", "rental",
            "hertz", "avis", "enterprise", "sixt", "europcar",
            "аренда авто", "прокат", "получение авто",
            "araç kiralama", "mietwagen", "autovermietung"
        ]
        if carKeywords.contains(where: { lowercased.contains($0) }) {
            return .carRental
        }

        // Place keywords (often URLs)
        let placeKeywords = [
            "restaurant", "museum", "attraction", "place", "visit",
            "tripadvisor", "yelp", "google.com/maps", "maps.apple",
            "ресторан", "музей", "достопримечательность",
            "restoran", "müze", "sehenswürdigkeit"
        ]
        if placeKeywords.contains(where: { lowercased.contains($0) }) {
            return .place
        }

        // If it's a URL without specific keywords, suggest place
        if text.hasPrefix("http://") || text.hasPrefix("https://") {
            return .place
        }

        // Default to note
        return .note
    }

    /// Attempts to extract a booking reference from text.
    static func extractBookingReference(from text: String) -> String? {
        // Common patterns: ABC123, 123456, XX-1234-YY
        let patterns = [
            "[A-Z]{2,3}[0-9]{3,6}",           // ABC123, AB1234
            "[A-Z0-9]{6,10}",                  // ABCD123456
            "[A-Z]{2}-[0-9]{4,6}",             // AB-123456
            "[0-9]{6,12}"                       // 123456789
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                return String(text[range])
            }
        }

        return nil
    }

    /// Extracts the first line of text (useful for titles).
    static func extractFirstLine(from text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) ?? ""
        // Limit to reasonable length for a title
        if firstLine.count > 100 {
            return String(firstLine.prefix(100)) + "..."
        }
        return firstLine
    }
}
