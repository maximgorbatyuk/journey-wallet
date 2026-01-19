import SwiftUI

enum TransportFormMode: Identifiable {
    case add
    case edit(Transport)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let transport): return transport.id.uuidString
        }
    }
}

struct TransportFormView: View {

    let journeyId: UUID
    let mode: TransportFormMode
    let onSave: (Transport) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    // Form state
    @State private var transportType: TransportType = .flight
    @State private var bookingReference: String = ""
    @State private var transportNumber: String = ""
    @State private var departureLocation: String = ""
    @State private var arrivalLocation: String = ""
    @State private var departureDate: Date = Date()
    @State private var arrivalDate: Date = Date().addingTimeInterval(2 * 60 * 60)
    @State private var cost: String = ""
    @State private var currency: Currency = .usd
    @State private var seatNumber: String = ""
    @State private var platform: String = ""
    @State private var carrier: String = ""
    @State private var forWhom: String = ""
    @State private var notes: String = ""

    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? L("transport.form.edit_title") : L("transport.form.add_title")
    }

    init(journeyId: UUID, mode: TransportFormMode, onSave: @escaping (Transport) -> Void) {
        self.journeyId = journeyId
        self.mode = mode
        self.onSave = onSave

        // Initialize state from existing transport if editing
        if case .edit(let transport) = mode {
            _transportType = State(initialValue: transport.type)
            _bookingReference = State(initialValue: transport.bookingReference ?? "")
            _transportNumber = State(initialValue: transport.transportNumber ?? "")
            _departureLocation = State(initialValue: transport.departureLocation)
            _arrivalLocation = State(initialValue: transport.arrivalLocation)
            _departureDate = State(initialValue: transport.departureDate)
            _arrivalDate = State(initialValue: transport.arrivalDate)
            _cost = State(initialValue: transport.cost?.description ?? "")
            _currency = State(initialValue: transport.currency ?? .usd)
            _seatNumber = State(initialValue: transport.seatNumber ?? "")
            _platform = State(initialValue: transport.platform ?? "")
            _carrier = State(initialValue: transport.carrier ?? "")
            _forWhom = State(initialValue: transport.forWhom ?? "")
            _notes = State(initialValue: transport.notes ?? "")
        } else {
            // Set default currency from user settings
            if let userCurrency = DatabaseManager.shared.userSettingsRepository?.fetchCurrency() {
                _currency = State(initialValue: userCurrency)
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // Type Section (required)
                Section(header: Text(L("transport.form.section.type"))) {
                    Picker(L("transport.form.type"), selection: $transportType) {
                        ForEach(TransportType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.iconName)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // Booking Reference Section (required)
                Section(header: Text(L("transport.form.section.booking"))) {
                    TextField(L("transport.form.booking_reference"), text: $bookingReference)
                        .autocapitalization(.allCharacters)
                }

                // Flight/Transport Number Section (optional)
                Section(header: Text(L("transport.form.section.number"))) {
                    TextField(transportType.numberLabel, text: $transportNumber)
                        .autocapitalization(.allCharacters)
                }

                // Route Section (optional)
                Section(header: Text(L("transport.form.section.route"))) {
                    TextField(transportType.departureLabel, text: $departureLocation)
                        .textContentType(.addressCity)

                    TextField(transportType.arrivalLabel, text: $arrivalLocation)
                        .textContentType(.addressCity)
                }

                // Date/Time Section (optional)
                Section(header: Text(L("transport.form.section.schedule"))) {
                    DatePicker(
                        L("transport.form.departure"),
                        selection: $departureDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    DatePicker(
                        L("transport.form.arrival"),
                        selection: $arrivalDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    // Duration display (only if arrival is after departure)
                    if arrivalDate > departureDate {
                        HStack {
                            Text(L("transport.form.duration"))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(calculateDuration())
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }

                // Cost Section (optional)
                Section(header: Text(L("transport.form.section.cost"))) {
                    HStack {
                        TextField(L("transport.form.cost"), text: $cost)
                            .keyboardType(.decimalPad)

                        Picker("", selection: $currency) {
                            ForEach(Currency.allCases, id: \.self) { curr in
                                Text(curr.shortName).tag(curr)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                }

                // Additional Details Section (optional)
                Section(header: Text(L("transport.form.section.details"))) {
                    TextField(L("transport.form.seats"), text: $seatNumber)

                    TextField(transportType.platformLabel, text: $platform)

                    TextField(transportType.carrierLabel, text: $carrier)
                }

                // For Whom Section (optional)
                Section(header: Text(L("transport.form.section.for_whom"))) {
                    TextField(L("transport.form.for_whom"), text: $forWhom)
                        .textContentType(.name)
                }

                // Notes Section (optional)
                Section(header: Text(L("transport.form.section.notes"))) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveTransport()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert(L("Error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .onAppear {
                let screenName = isEditing ? "transport_edit_screen" : "transport_add_screen"
                analytics.trackScreen(screenName)
            }
        }
    }

    // MARK: - Validation

    private func validateForm() -> Bool {
        // Only booking reference is required
        if bookingReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("transport.form.error.booking_required")
            showValidationError = true
            return false
        }

        // Validate cost if entered
        if !cost.isEmpty {
            if Decimal(string: cost) == nil {
                validationMessage = L("transport.form.error.invalid_cost")
                showValidationError = true
                return false
            }
        }

        return true
    }

    // MARK: - Save

    private func saveTransport() {
        guard validateForm() else { return }

        let parsedCost = cost.isEmpty ? nil : Decimal(string: cost)

        // Use default values for required model fields if not provided
        let finalDepartureLocation = departureLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalArrivalLocation = arrivalLocation.trimmingCharacters(in: .whitespacesAndNewlines)

        let transport: Transport

        if case .edit(let existingTransport) = mode {
            transport = Transport(
                id: existingTransport.id,
                journeyId: journeyId,
                type: transportType,
                carrier: carrier.isEmpty ? nil : carrier,
                transportNumber: transportNumber.isEmpty ? nil : transportNumber,
                departureLocation: finalDepartureLocation.isEmpty ? "-" : finalDepartureLocation,
                arrivalLocation: finalArrivalLocation.isEmpty ? "-" : finalArrivalLocation,
                departureDate: departureDate,
                arrivalDate: arrivalDate,
                bookingReference: bookingReference.trimmingCharacters(in: .whitespacesAndNewlines),
                seatNumber: seatNumber.isEmpty ? nil : seatNumber,
                platform: platform.isEmpty ? nil : platform,
                cost: parsedCost,
                currency: parsedCost != nil ? currency : nil,
                notes: notes.isEmpty ? nil : notes,
                forWhom: forWhom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : forWhom.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: existingTransport.createdAt,
                updatedAt: Date()
            )
        } else {
            transport = Transport(
                journeyId: journeyId,
                type: transportType,
                carrier: carrier.isEmpty ? nil : carrier,
                transportNumber: transportNumber.isEmpty ? nil : transportNumber,
                departureLocation: finalDepartureLocation.isEmpty ? "-" : finalDepartureLocation,
                arrivalLocation: finalArrivalLocation.isEmpty ? "-" : finalArrivalLocation,
                departureDate: departureDate,
                arrivalDate: arrivalDate,
                bookingReference: bookingReference.trimmingCharacters(in: .whitespacesAndNewlines),
                seatNumber: seatNumber.isEmpty ? nil : seatNumber,
                platform: platform.isEmpty ? nil : platform,
                cost: parsedCost,
                currency: parsedCost != nil ? currency : nil,
                notes: notes.isEmpty ? nil : notes,
                forWhom: forWhom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : forWhom.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        onSave(transport)
        dismiss()
    }

    // MARK: - Helpers

    private func calculateDuration() -> String {
        let duration = arrivalDate.timeIntervalSince(departureDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

#Preview("Add Transport") {
    TransportFormView(
        journeyId: UUID(),
        mode: .add
    ) { _ in }
}

#Preview("Edit Transport") {
    TransportFormView(
        journeyId: UUID(),
        mode: .edit(Transport(
            journeyId: UUID(),
            type: .flight,
            carrier: "Emirates",
            transportNumber: "EK123",
            departureLocation: "Dubai",
            arrivalLocation: "Paris",
            departureDate: Date(),
            arrivalDate: Date().addingTimeInterval(6 * 60 * 60),
            bookingReference: "ABC123"
        ))
    ) { _ in }
}
