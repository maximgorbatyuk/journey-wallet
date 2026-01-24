import SwiftUI

// MARK: - Transport Preview Row

struct TransportPreviewRow: View {
    let transport: Transport

    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: transport.type.iconName)
                .font(.title3)
                .foregroundColor(transport.type.color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                // Carrier and number
                HStack {
                    if let carrier = transport.carrier {
                        Text(carrier)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    if let number = transport.transportNumber {
                        Text(number)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // Route
                HStack(spacing: 4) {
                    Text(transport.departureLocation)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(transport.arrivalLocation)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // For Whom label (only shown if not empty)
                if let forWhom = transport.forWhom, !forWhom.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.caption2)
                        Text(forWhom)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                }
            }

            Spacer()

            // Departure time
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDate(transport.departureDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formatTime(transport.departureDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Hotel Preview Row

struct HotelPreviewRow: View {
    let hotel: Hotel

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundColor(.purple)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(hotel.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(hotel.address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Check-in date and nights
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDate(hotel.checkInDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(hotel.nightsCount) \(L("journey.detail.nights"))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Car Rental Preview Row

struct CarRentalPreviewRow: View {
    let carRental: CarRental

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "car.fill")
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(carRental.carType)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let company = carRental.company {
                    Text(company)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Pickup date and duration
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatDate(carRental.pickupDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(carRental.durationDays) \(L("journey.days"))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Note Preview Row

struct NotePreviewRow: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "note.text")
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(note.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Place Preview Row

struct PlacePreviewRow: View {
    let place: PlaceToVisit

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: place.category.iconName)
                .font(.title3)
                .foregroundColor(place.category.color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(place.category.displayName)
                        .font(.caption)

                    if let plannedDate = place.plannedDate {
                        Text("•")
                        Text(formatDate(plannedDate))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Visited status
            Image(systemName: place.isVisited ? "checkmark.circle.fill" : "circle")
                .foregroundColor(place.isVisited ? .green : .gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Reminder Preview Row

struct ReminderPreviewRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "bell.fill")
                .font(.title3)
                .foregroundColor(reminder.isCompleted ? .green : .red)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(reminder.isCompleted)

                Text(formatDateTime(reminder.reminderDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Expense Preview Row

struct ExpensePreviewRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: expense.category.icon)
                .font(.title3)
                .foregroundColor(expense.category.color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Category badge
                    Text(expense.category.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    // Date
                    Text(formatDate(expense.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Amount
            Text("\(expense.currency.rawValue)\(expense.amount.formatted())")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Checklist Preview Row

struct ChecklistPreviewRow: View {
    let checklist: Checklist
    let progress: (checked: Int, total: Int)

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "checklist")
                .font(.title3)
                .foregroundColor(.teal)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(checklist.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                // Progress
                HStack(spacing: 8) {
                    ProgressView(value: progressPercentage)
                        .tint(progressColor)
                        .frame(width: 60)

                    Text("\(progress.checked)/\(progress.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Percentage
            Text("\(Int(progressPercentage * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(progressColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var progressPercentage: Double {
        guard progress.total > 0 else { return 0 }
        return Double(progress.checked) / Double(progress.total)
    }

    private var progressColor: Color {
        if progress.total == 0 {
            return .gray
        } else if progress.checked == progress.total {
            return .green
        } else if progressPercentage > 0.5 {
            return .blue
        } else {
            return .orange
        }
    }
}

// MARK: - Empty Section View

struct EmptySectionView: View {
    let message: String
    let iconName: String

    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Transport Row") {
    TransportPreviewRow(
        transport: Transport(
            journeyId: UUID(),
            type: .flight,
            carrier: "Emirates",
            transportNumber: "EK123",
            departureLocation: "Dubai",
            arrivalLocation: "Paris",
            departureDate: Date(),
            arrivalDate: Date().addingTimeInterval(6 * 60 * 60)
        )
    )
}

#Preview("Hotel Row") {
    HotelPreviewRow(
        hotel: Hotel(
            journeyId: UUID(),
            name: "Grand Hotel Paris",
            address: "123 Champs-Elysees, Paris",
            checkInDate: Date(),
            checkOutDate: Date().addingTimeInterval(3 * 24 * 60 * 60)
        )
    )
}
