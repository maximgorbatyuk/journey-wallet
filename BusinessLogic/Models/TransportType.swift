import Foundation

enum TransportType: String, Codable, CaseIterable, Identifiable {
    case flight
    case train
    case bus
    case ferry
    case transfer
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flight: return L("transport.type.flight")
        case .train: return L("transport.type.train")
        case .bus: return L("transport.type.bus")
        case .ferry: return L("transport.type.ferry")
        case .transfer: return L("transport.type.transfer")
        case .other: return L("transport.type.other")
        }
    }

    var icon: String {
        switch self {
        case .flight: return "airplane"
        case .train: return "tram.fill"
        case .bus: return "bus.fill"
        case .ferry: return "ferry.fill"
        case .transfer: return "car.fill"
        case .other: return "arrow.triangle.swap"
        }
    }

    var carrierLabel: String {
        switch self {
        case .flight: return L("transport.label.airline")
        case .train: return L("transport.label.train_company")
        case .bus: return L("transport.label.bus_company")
        case .ferry: return L("transport.label.ferry_company")
        case .transfer: return L("transport.label.provider")
        case .other: return L("transport.label.carrier")
        }
    }

    var numberLabel: String {
        switch self {
        case .flight: return L("transport.label.flight_number")
        case .train: return L("transport.label.train_number")
        case .bus: return L("transport.label.route_number")
        case .ferry: return L("transport.label.ferry_number")
        case .transfer: return L("transport.label.vehicle")
        case .other: return L("transport.label.reference")
        }
    }

    var platformLabel: String {
        switch self {
        case .flight: return L("transport.label.terminal")
        case .train: return L("transport.label.platform")
        case .bus: return L("transport.label.platform")
        case .ferry: return L("transport.label.pier")
        case .transfer: return L("transport.label.pickup_point")
        case .other: return L("transport.label.location")
        }
    }

    var departureLabel: String {
        switch self {
        case .flight: return L("transport.label.departure_airport")
        case .train: return L("transport.label.departure_station")
        case .bus: return L("transport.label.departure_station")
        case .ferry: return L("transport.label.departure_port")
        case .transfer: return L("transport.label.pickup_location")
        case .other: return L("transport.label.from")
        }
    }

    var arrivalLabel: String {
        switch self {
        case .flight: return L("transport.label.arrival_airport")
        case .train: return L("transport.label.arrival_station")
        case .bus: return L("transport.label.arrival_station")
        case .ferry: return L("transport.label.arrival_port")
        case .transfer: return L("transport.label.dropoff_location")
        case .other: return L("transport.label.to")
        }
    }
}
