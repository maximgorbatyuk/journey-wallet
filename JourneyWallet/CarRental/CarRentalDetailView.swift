import SwiftUI

struct CarRentalDetailView: View {

    let carRental: CarRental
    let journeyId: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showReminderSheet: Bool = false
    @State private var copiedBookingRef: Bool = false

    private let carRentalsRepository = DatabaseManager.shared.carRentalsRepository
    private let remindersRepository = DatabaseManager.shared.remindersRepository

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with status
                headerSection

                // Main info card
                mainInfoCard

                // Dates card
                datesCard

                // Booking info card
                if carRental.bookingReference != nil || carRental.carType != nil {
                    bookingInfoCard
                }

                // Cost card
                if carRental.cost != nil {
                    costCard
                }

                // Notes card
                if let notes = carRental.notes, !notes.isEmpty {
                    notesCard(notes: notes)
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle(L("car_rental.detail.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label(L("Edit"), systemImage: "pencil")
                    }

                    Button {
                        showReminderSheet = true
                    } label: {
                        Label(L("car_rental.detail.add_reminder"), systemImage: "bell.badge.fill")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(L("Delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("car_rental_detail_screen")
        }
        .sheet(isPresented: $showEditSheet) {
            CarRentalFormView(
                journeyId: journeyId,
                mode: .edit(carRental),
                onSave: { _ in
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showReminderSheet) {
            CarRentalReminderSheet(carRental: carRental, journeyId: journeyId)
        }
        .alert(L("car_rental.detail.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Delete"), role: .destructive) {
                deleteCarRental()
            }
        } message: {
            Text(L("car_rental.detail.delete_confirm.message"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Car icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "car.fill")
                    .font(.system(size: 36))
                    .foregroundColor(statusColor)
            }

            // Company name
            Text(carRental.company)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Car type
            if let carType = carRental.carType, !carType.isEmpty {
                Text(carType)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Status badge
            Text(statusText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(statusColor)
                .cornerRadius(16)

            // Countdown
            if carRental.isUpcoming {
                Text(countdownText)
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 20)
    }

    private var statusText: String {
        if carRental.isActive {
            return L("car_rental.status.active")
        } else if carRental.isUpcoming {
            return L("car_rental.status.upcoming")
        } else {
            return L("car_rental.status.past")
        }
    }

    private var statusColor: Color {
        if carRental.isActive {
            return .green
        } else if carRental.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    private var countdownText: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: carRental.pickupDate)

        if let days = components.day, days > 0 {
            return "\(L("car_rental.detail.pickup_in")) \(days) \(L("journey.days"))"
        } else if let hours = components.hour, hours > 0 {
            return "\(L("car_rental.detail.pickup_in")) \(hours)h"
        }
        return L("car_rental.detail.pickup_soon")
    }

    // MARK: - Main Info Card

    private var mainInfoCard: some View {
        VStack(spacing: 16) {
            // Pickup location
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("car_rental.detail.pickup_location"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(carRental.pickupLocation)
                        .font(.body)
                }

                Spacer()

                // Open in Maps button
                Button {
                    openInMaps(location: carRental.pickupLocation)
                } label: {
                    Image(systemName: "map.fill")
                        .foregroundColor(.orange)
                }
            }

            Divider()

            // Dropoff location
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("car_rental.detail.dropoff_location"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(carRental.dropoffLocation)
                        .font(.body)
                }

                Spacer()

                // Open in Maps button
                if !carRental.isSameLocation {
                    Button {
                        openInMaps(location: carRental.dropoffLocation)
                    } label: {
                        Image(systemName: "map.fill")
                            .foregroundColor(.orange)
                    }
                }
            }

            // Same location indicator
            if carRental.isSameLocation {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(L("car_rental.detail.same_location"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Dates Card

    private var datesCard: some View {
        VStack(spacing: 16) {
            // Pickup date/time
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("car_rental.detail.pickup"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDateTime(carRental.pickupDate))
                        .font(.headline)
                }

                Spacer()
            }

            Divider()

            // Dropoff date/time
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.red)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("car_rental.detail.dropoff"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDateTime(carRental.dropoffDate))
                        .font(.headline)
                }

                Spacer()
            }

            Divider()

            // Duration
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("car_rental.detail.duration"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(carRental.durationDays) \(L("car_rental.days"))")
                        .font(.headline)
                        .foregroundColor(.orange)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Booking Info Card

    private var bookingInfoCard: some View {
        VStack(spacing: 16) {
            // Booking reference
            if let ref = carRental.bookingReference, !ref.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("car_rental.detail.booking_reference"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(ref)
                            .font(.headline)
                            .fontDesign(.monospaced)
                    }

                    Spacer()

                    // Copy button
                    Button {
                        UIPasteboard.general.string = ref
                        copiedBookingRef = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedBookingRef = false
                        }
                    } label: {
                        Image(systemName: copiedBookingRef ? "checkmark.circle.fill" : "doc.on.doc")
                            .foregroundColor(copiedBookingRef ? .green : .orange)
                    }
                }
            }

            // Car type
            if let carType = carRental.carType, !carType.isEmpty {
                if carRental.bookingReference != nil {
                    Divider()
                }

                HStack(spacing: 12) {
                    Image(systemName: "car.side.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("car_rental.detail.car_type"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(carType)
                            .font(.headline)
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Cost Card

    private var costCard: some View {
        VStack(spacing: 16) {
            // Total cost
            if let cost = carRental.cost, let currency = carRental.currency {
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("car_rental.detail.total_cost"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currency.rawValue)\(cost.formatted())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    Spacer()
                }

                // Cost per day
                if let perDay = carRental.costPerDay {
                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("car_rental.detail.per_day"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(currency.rawValue)\(perDay.formatted())")
                                .font(.headline)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                Text(L("car_rental.detail.notes"))
                    .font(.headline)
            }

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Open pickup location in Maps
            Button(action: {
                openInMaps(location: carRental.pickupLocation)
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text(L("car_rental.detail.action.map_pickup"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Add reminder button
            Button(action: {
                showReminderSheet = true
            }) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text(L("car_rental.detail.action.reminder"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Methods

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func openInMaps(location: String) {
        let query = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            openURL(url)
        }
    }

    private func deleteCarRental() {
        // Delete associated reminders
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == carRental.id {
            _ = remindersRepository?.delete(id: reminder.id)
        }

        // Delete car rental
        _ = carRentalsRepository?.delete(id: carRental.id)
        dismiss()
    }
}

// MARK: - Car Rental Reminder Sheet

struct CarRentalReminderSheet: View {

    let carRental: CarRental
    let journeyId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var selectedOption: CarRentalReminderOption = .dayBefore
    @State private var customDate: Date = Date()

    private let remindersRepository = DatabaseManager.shared.remindersRepository

    enum CarRentalReminderOption: CaseIterable {
        case dayBefore
        case twoDaysBefore
        case weekBefore
        case custom

        var displayName: String {
            switch self {
            case .dayBefore: return L("car_rental.reminder.day_before")
            case .twoDaysBefore: return L("car_rental.reminder.two_days_before")
            case .weekBefore: return L("car_rental.reminder.week_before")
            case .custom: return L("car_rental.reminder.custom")
            }
        }

        func reminderDate(for pickupDate: Date) -> Date {
            switch self {
            case .dayBefore:
                return Calendar.current.date(byAdding: .day, value: -1, to: pickupDate) ?? pickupDate
            case .twoDaysBefore:
                return Calendar.current.date(byAdding: .day, value: -2, to: pickupDate) ?? pickupDate
            case .weekBefore:
                return Calendar.current.date(byAdding: .day, value: -7, to: pickupDate) ?? pickupDate
            case .custom:
                return pickupDate
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L("car_rental.reminder.when"))) {
                    ForEach(CarRentalReminderOption.allCases, id: \.self) { option in
                        HStack {
                            Text(option.displayName)

                            Spacer()

                            if option != .custom {
                                Text(formatDate(option.reminderDate(for: carRental.pickupDate)))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if selectedOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedOption = option
                        }
                    }
                }

                if selectedOption == .custom {
                    Section {
                        DatePicker(
                            L("car_rental.reminder.date"),
                            selection: $customDate,
                            in: ...carRental.pickupDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section {
                    Button(action: saveReminder) {
                        HStack {
                            Spacer()
                            Text(L("car_rental.reminder.save"))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle(L("car_rental.reminder.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func saveReminder() {
        let reminderDate = selectedOption == .custom ? customDate : selectedOption.reminderDate(for: carRental.pickupDate)
        let title = "\(L("car_rental.reminder.notification.title")): \(carRental.company)"

        // Schedule local notification first to get the notificationId
        let notificationId = NotificationManager.shared.scheduleNotification(
            title: L("car_rental.reminder.notification.title"),
            body: title,
            on: reminderDate
        )

        // Create Reminder entity with the notificationId
        let reminder = Reminder(
            journeyId: journeyId,
            title: title,
            reminderDate: reminderDate,
            relatedEntityId: carRental.id,
            notificationId: notificationId
        )

        _ = remindersRepository?.insert(reminder)

        dismiss()
    }
}
