import SwiftUI

struct HotelDetailView: View {

    let hotel: Hotel
    let journeyId: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showReminderSheet: Bool = false
    @State private var copiedBookingRef: Bool = false

    private let hotelsRepository = DatabaseManager.shared.hotelsRepository
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
                if hotel.bookingReference != nil || hotel.roomType != nil {
                    bookingInfoCard
                }

                // Cost card
                if hotel.cost != nil {
                    costCard
                }

                // Notes card
                if let notes = hotel.notes, !notes.isEmpty {
                    notesCard(notes: notes)
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle(L("hotel.detail.title"))
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
                        Label(L("hotel.detail.add_reminder"), systemImage: "bell.badge.fill")
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
            analytics.trackScreen("hotel_detail_screen")
        }
        .sheet(isPresented: $showEditSheet) {
            HotelFormView(
                journeyId: journeyId,
                mode: .edit(hotel),
                onSave: { _ in
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showReminderSheet) {
            HotelReminderSheet(hotel: hotel, journeyId: journeyId)
        }
        .alert(L("hotel.detail.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Delete"), role: .destructive) {
                deleteHotel()
            }
        } message: {
            Text(L("hotel.detail.delete_confirm.message"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Hotel icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "building.2.fill")
                    .font(.system(size: 36))
                    .foregroundColor(statusColor)
            }

            // Hotel name
            Text(hotel.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

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
            if hotel.isUpcoming {
                Text(countdownText)
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 20)
    }

    private var statusText: String {
        if hotel.isActive {
            return L("hotel.status.active")
        } else if hotel.isUpcoming {
            return L("hotel.status.upcoming")
        } else {
            return L("hotel.status.past")
        }
    }

    private var statusColor: Color {
        if hotel.isActive {
            return .green
        } else if hotel.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    private var countdownText: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour], from: now, to: hotel.checkInDate)

        if let days = components.day, days > 0 {
            return "\(L("hotel.detail.check_in_in")) \(days) \(L("journey.days"))"
        } else if let hours = components.hour, hours > 0 {
            return "\(L("hotel.detail.check_in_in")) \(hours)h"
        }
        return L("hotel.detail.checking_in_soon")
    }

    // MARK: - Main Info Card

    private var mainInfoCard: some View {
        VStack(spacing: 16) {
            // Address
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("hotel.detail.address"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(hotel.address)
                        .font(.body)
                }

                Spacer()

                // Open in Maps button
                Button {
                    openInMaps()
                } label: {
                    Image(systemName: "map.fill")
                        .foregroundColor(.orange)
                }
            }

            // Contact phone
            if let phone = hotel.contactPhone, !phone.isEmpty {
                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("hotel.detail.phone"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(phone)
                            .font(.body)
                    }

                    Spacer()

                    // Call button
                    Button {
                        callHotel(phone)
                    } label: {
                        Image(systemName: "phone.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
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
            // Check-in
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("hotel.detail.check_in"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDate(hotel.checkInDate))
                        .font(.headline)
                }

                Spacer()
            }

            Divider()

            // Check-out
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.circle.fill")
                    .foregroundColor(.red)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("hotel.detail.check_out"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDate(hotel.checkOutDate))
                        .font(.headline)
                }

                Spacer()
            }

            Divider()

            // Duration
            HStack(spacing: 12) {
                Image(systemName: "moon.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("hotel.detail.duration"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(hotel.nightsCount) \(L("hotel.nights"))")
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
            if let ref = hotel.bookingReference, !ref.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "number")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("hotel.detail.booking_reference"))
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

            // Room type
            if let roomType = hotel.roomType, !roomType.isEmpty {
                if hotel.bookingReference != nil {
                    Divider()
                }

                HStack(spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("hotel.detail.room_type"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(roomType)
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
            if let cost = hotel.cost, let currency = hotel.currency {
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("hotel.detail.total_cost"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currency.symbol)\(cost.formatted())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    Spacer()
                }

                // Cost per night
                if let perNight = hotel.costPerNight {
                    Divider()

                    HStack(spacing: 12) {
                        Image(systemName: "moon.stars")
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("hotel.detail.per_night"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(currency.symbol)\(perNight.formatted())")
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
                Text(L("hotel.detail.notes"))
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
            // Call hotel button
            if let phone = hotel.contactPhone, !phone.isEmpty {
                Button(action: {
                    callHotel(phone)
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text(L("hotel.detail.action.call"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

            // Open in Maps button
            Button(action: {
                openInMaps()
            }) {
                HStack {
                    Image(systemName: "map.fill")
                    Text(L("hotel.detail.action.map"))
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
                    Text(L("hotel.detail.action.reminder"))
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func callHotel(_ phone: String) {
        let cleaned = phone.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        if let url = URL(string: "tel://\(cleaned)") {
            openURL(url)
        }
    }

    private func openInMaps() {
        let query = hotel.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            openURL(url)
        }
    }

    private func deleteHotel() {
        // Delete associated reminders
        let reminders = remindersRepository?.fetchByJourneyId(journeyId: journeyId) ?? []
        for reminder in reminders where reminder.relatedEntityId == hotel.id {
            _ = remindersRepository?.delete(id: reminder.id)
        }

        // Delete hotel
        _ = hotelsRepository?.delete(id: hotel.id)
        dismiss()
    }
}

// MARK: - Hotel Reminder Sheet

struct HotelReminderSheet: View {

    let hotel: Hotel
    let journeyId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var selectedOption: HotelReminderOption = .dayBefore
    @State private var customDate: Date = Date()

    private let remindersRepository = DatabaseManager.shared.remindersRepository

    enum HotelReminderOption: CaseIterable {
        case dayBefore
        case twoDaysBefore
        case weekBefore
        case custom

        var displayName: String {
            switch self {
            case .dayBefore: return L("hotel.reminder.day_before")
            case .twoDaysBefore: return L("hotel.reminder.two_days_before")
            case .weekBefore: return L("hotel.reminder.week_before")
            case .custom: return L("hotel.reminder.custom")
            }
        }

        func reminderDate(for checkInDate: Date) -> Date {
            switch self {
            case .dayBefore:
                return Calendar.current.date(byAdding: .day, value: -1, to: checkInDate) ?? checkInDate
            case .twoDaysBefore:
                return Calendar.current.date(byAdding: .day, value: -2, to: checkInDate) ?? checkInDate
            case .weekBefore:
                return Calendar.current.date(byAdding: .day, value: -7, to: checkInDate) ?? checkInDate
            case .custom:
                return checkInDate
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L("hotel.reminder.when"))) {
                    ForEach(HotelReminderOption.allCases, id: \.self) { option in
                        HStack {
                            Text(option.displayName)

                            Spacer()

                            if option != .custom {
                                Text(formatDate(option.reminderDate(for: hotel.checkInDate)))
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
                            L("hotel.reminder.date"),
                            selection: $customDate,
                            in: ...hotel.checkInDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section {
                    Button(action: saveReminder) {
                        HStack {
                            Spacer()
                            Text(L("hotel.reminder.save"))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle(L("hotel.reminder.title"))
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
        let reminderDate = selectedOption == .custom ? customDate : selectedOption.reminderDate(for: hotel.checkInDate)
        let title = "\(L("hotel.reminder.notification.title")): \(hotel.name)"

        let reminder = Reminder(
            journeyId: journeyId,
            title: title,
            reminderDate: reminderDate,
            type: .accommodation,
            relatedEntityId: hotel.id
        )

        _ = remindersRepository?.insert(reminder)

        // Schedule local notification
        _ = NotificationManager.shared.scheduleNotification(
            title: L("hotel.reminder.notification.title"),
            body: title,
            on: reminderDate
        )

        dismiss()
    }
}
