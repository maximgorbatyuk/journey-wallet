import SwiftUI

struct TransportDetailView: View {

    @State private var viewModel: TransportDetailViewModel

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showReminderSheet: Bool = false
    @State private var copiedBookingRef: Bool = false

    init(transport: Transport, journeyId: UUID) {
        _viewModel = State(initialValue: TransportDetailViewModel(transport: transport, journeyId: journeyId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with type icon and status
                headerSection

                // Main info card
                mainInfoCard

                // Details card
                detailsCard

                // Booking info card
                if hasBookingInfo {
                    bookingInfoCard
                }

                // Cost card
                if viewModel.transport.cost != nil {
                    costCard
                }

                // Notes card
                if let notes = viewModel.transport.notes, !notes.isEmpty {
                    notesCard(notes: notes)
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .navigationTitle(viewModel.transport.type.displayName)
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
                        Label(L("transport.detail.add_reminder"), systemImage: "bell.badge.fill")
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
            analytics.trackScreen("transport_detail_screen")
        }
        .sheet(isPresented: $showEditSheet) {
            TransportFormView(
                journeyId: viewModel.journeyId,
                mode: .edit(viewModel.transport),
                onSave: { updatedTransport in
                    viewModel.updateTransport(updatedTransport)
                }
            )
        }
        .sheet(isPresented: $showReminderSheet) {
            TransportReminderSheet(viewModel: viewModel)
        }
        .alert(L("transport.detail.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
            Button(L("Cancel"), role: .cancel) {}
            Button(L("Delete"), role: .destructive) {
                if viewModel.deleteTransport() {
                    dismiss()
                }
            }
        } message: {
            Text(L("transport.detail.delete_confirm.message"))
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Type icon
            ZStack {
                Circle()
                    .fill(viewModel.transport.type.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: viewModel.transport.type.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.transport.type.color)
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
            if viewModel.transport.isUpcoming {
                Text(countdownText)
                    .font(.headline)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 20)
    }

    private var statusText: String {
        if viewModel.transport.isInProgress {
            return L("transport.status.in_progress")
        } else if viewModel.transport.isUpcoming {
            return L("transport.status.upcoming")
        } else {
            return L("transport.status.completed")
        }
    }

    private var statusColor: Color {
        if viewModel.transport.isInProgress {
            return .green
        } else if viewModel.transport.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    private var countdownText: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: now, to: viewModel.transport.departureDate)

        if let days = components.day, days > 0 {
            return "\(L("transport.detail.departs_in")) \(days) \(L("journey.days"))"
        } else if let hours = components.hour, hours > 0 {
            return "\(L("transport.detail.departs_in")) \(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(L("transport.detail.departs_in")) \(minutes)m"
        }
        return L("transport.detail.departing_soon")
    }

    // MARK: - Main Info Card

    private var mainInfoCard: some View {
        VStack(spacing: 16) {
            // Carrier and number
            if viewModel.transport.carrier != nil || viewModel.transport.transportNumber != nil {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.transport.type.carrierLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.transport.carrier ?? "-")
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.transport.type.numberLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.transport.transportNumber ?? "-")
                            .font(.headline)
                    }
                }
            }

            Divider()

            // Route visualization
            HStack(alignment: .center, spacing: 16) {
                // Departure
                VStack(spacing: 4) {
                    Text(formatTime(viewModel.transport.departureDate))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(formatDate(viewModel.transport.departureDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.transport.departureLocation)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)

                // Arrow with duration
                VStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Text(viewModel.transport.durationFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Arrival
                VStack(spacing: 4) {
                    Text(formatTime(viewModel.transport.arrivalDate))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(formatDate(viewModel.transport.arrivalDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.transport.arrivalLocation)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Details Card

    private var detailsCard: some View {
        VStack(spacing: 0) {
            if let platform = viewModel.transport.platform {
                DetailRow(
                    label: viewModel.transport.type.platformLabel,
                    value: platform,
                    iconName: "signpost.right.fill"
                )
                Divider().padding(.leading, 44)
            }

            if let seat = viewModel.transport.seatNumber {
                DetailRow(
                    label: L("transport.detail.seat"),
                    value: seat,
                    iconName: "chair.fill"
                )
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.top, 12)
    }

    private var hasBookingInfo: Bool {
        viewModel.transport.bookingReference != nil
    }

    // MARK: - Booking Info Card

    private var bookingInfoCard: some View {
        VStack(spacing: 0) {
            if let bookingRef = viewModel.transport.bookingReference {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("transport.detail.booking_reference"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(bookingRef)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = bookingRef
                        copiedBookingRef = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedBookingRef = false
                        }
                    } label: {
                        Image(systemName: copiedBookingRef ? "checkmark" : "doc.on.doc")
                            .foregroundColor(copiedBookingRef ? .green : .orange)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.top, 12)
    }

    // MARK: - Cost Card

    private var costCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("transport.detail.cost"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.transport.formattedCost ?? "-")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.top, 12)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                Text(L("transport.detail.notes"))
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
        .padding(.top, 12)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Add reminder button
            Button {
                showReminderSheet = true
            } label: {
                HStack {
                    Image(systemName: "bell.badge.fill")
                    Text(L("transport.detail.add_reminder"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Helper Methods

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    let iconName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundColor(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Transport Reminder Sheet

struct TransportReminderSheet: View {

    let viewModel: TransportDetailViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedOption: ReminderOption = .oneHourBefore
    @State private var customDate: Date = Date()

    enum ReminderOption: String, CaseIterable {
        case twentyFourHoursBefore
        case threeHoursBefore
        case oneHourBefore
        case custom

        var displayName: String {
            switch self {
            case .twentyFourHoursBefore: return L("transport.reminder.24h_before")
            case .threeHoursBefore: return L("transport.reminder.3h_before")
            case .oneHourBefore: return L("transport.reminder.1h_before")
            case .custom: return L("transport.reminder.custom")
            }
        }

        func reminderDate(for departureDate: Date) -> Date {
            switch self {
            case .twentyFourHoursBefore:
                return departureDate.addingTimeInterval(-24 * 60 * 60)
            case .threeHoursBefore:
                return departureDate.addingTimeInterval(-3 * 60 * 60)
            case .oneHourBefore:
                return departureDate.addingTimeInterval(-1 * 60 * 60)
            case .custom:
                return departureDate
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(L("transport.reminder.when"))) {
                    ForEach(ReminderOption.allCases, id: \.self) { option in
                        Button {
                            selectedOption = option
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }

                if selectedOption == .custom {
                    Section {
                        DatePicker(
                            L("transport.reminder.date"),
                            selection: $customDate,
                            in: Date()...viewModel.transport.departureDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }

                Section {
                    HStack {
                        Text(L("transport.reminder.preview"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatReminderDate())
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle(L("transport.detail.add_reminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveReminder()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func formatReminderDate() -> String {
        let date = selectedOption == .custom ? customDate : selectedOption.reminderDate(for: viewModel.transport.departureDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }

    private func saveReminder() {
        let reminderDate = selectedOption == .custom ? customDate : selectedOption.reminderDate(for: viewModel.transport.departureDate)
        let title = "\(viewModel.transport.type.displayName): \(viewModel.transport.departureLocation) → \(viewModel.transport.arrivalLocation)"

        viewModel.saveReminder(date: reminderDate, title: title)
        dismiss()
    }
}

#Preview {
    NavigationView {
        TransportDetailView(
            transport: Transport(
                journeyId: UUID(),
                type: .flight,
                carrier: "Emirates",
                transportNumber: "EK123",
                departureLocation: "Dubai International",
                arrivalLocation: "Paris CDG",
                departureDate: Date().addingTimeInterval(24 * 60 * 60),
                arrivalDate: Date().addingTimeInterval(30 * 60 * 60),
                bookingReference: "ABC123XYZ",
                seatNumber: "12A",
                platform: "Terminal 3",
                cost: Decimal(450),
                currency: .usd
            ),
            journeyId: UUID()
        )
    }
}
