import SwiftUI

enum CarRentalFormMode: Identifiable {
    case add
    case edit(CarRental)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let carRental): return carRental.id.uuidString
        }
    }
}

struct CarRentalFormView: View {

    let journeyId: UUID
    let mode: CarRentalFormMode
    let onSave: (CarRental) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    // Form state
    @State private var company: String = ""
    @State private var pickupLocation: String = ""
    @State private var dropoffLocation: String = ""
    @State private var sameLocation: Bool = true
    @State private var pickupDate: Date = Date()
    @State private var dropoffDate: Date = Date().addingTimeInterval(24 * 60 * 60)
    @State private var bookingReference: String = ""
    @State private var carType: String = ""
    @State private var cost: String = ""
    @State private var currency: Currency = .usd
    @State private var notes: String = ""

    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var navigationTitle: String {
        isEditing ? L("car_rental.form.edit_title") : L("car_rental.form.add_title")
    }

    init(journeyId: UUID, mode: CarRentalFormMode, onSave: @escaping (CarRental) -> Void) {
        self.journeyId = journeyId
        self.mode = mode
        self.onSave = onSave

        // Initialize state from existing car rental if editing
        if case .edit(let carRental) = mode {
            _company = State(initialValue: carRental.company)
            _pickupLocation = State(initialValue: carRental.pickupLocation)
            _dropoffLocation = State(initialValue: carRental.dropoffLocation)
            _sameLocation = State(initialValue: carRental.isSameLocation)
            _pickupDate = State(initialValue: carRental.pickupDate)
            _dropoffDate = State(initialValue: carRental.dropoffDate)
            _bookingReference = State(initialValue: carRental.bookingReference ?? "")
            _carType = State(initialValue: carRental.carType ?? "")
            _cost = State(initialValue: carRental.cost?.description ?? "")
            _currency = State(initialValue: carRental.currency ?? .usd)
            _notes = State(initialValue: carRental.notes ?? "")
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
                // Company Section
                Section(header: Text(L("car_rental.form.section.company"))) {
                    TextField(L("car_rental.form.company"), text: $company)
                        .textContentType(.organizationName)

                    TextField(L("car_rental.form.car_type"), text: $carType)
                }

                // Location Section
                Section(header: Text(L("car_rental.form.section.locations"))) {
                    TextField(L("car_rental.form.pickup_location"), text: $pickupLocation)
                        .textContentType(.fullStreetAddress)

                    Toggle(L("car_rental.form.same_location"), isOn: $sameLocation)
                        .tint(.orange)

                    if !sameLocation {
                        TextField(L("car_rental.form.dropoff_location"), text: $dropoffLocation)
                            .textContentType(.fullStreetAddress)
                    }
                }

                // Dates Section
                Section(header: Text(L("car_rental.form.section.dates"))) {
                    DatePicker(
                        L("car_rental.form.pickup_date"),
                        selection: $pickupDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    DatePicker(
                        L("car_rental.form.dropoff_date"),
                        selection: $dropoffDate,
                        in: pickupDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    // Duration display
                    HStack {
                        Text(L("car_rental.form.duration"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(calculateDays()) \(L("car_rental.days"))")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }

                // Booking Details Section
                Section(header: Text(L("car_rental.form.section.booking"))) {
                    TextField(L("car_rental.form.booking_reference"), text: $bookingReference)
                        .textInputAutocapitalization(.characters)
                }

                // Cost Section
                Section(header: Text(L("car_rental.form.section.cost"))) {
                    HStack {
                        Picker(L("car_rental.form.currency"), selection: $currency) {
                            ForEach(Currency.allCases, id: \.self) { curr in
                                Text("\(curr.rawValue)").tag(curr)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)

                        TextField(L("car_rental.form.total_cost"), text: $cost)
                            .keyboardType(.decimalPad)
                    }

                    // Per day calculation
                    if let costValue = Decimal(string: cost), costValue > 0, calculateDays() > 0 {
                        HStack {
                            Text(L("car_rental.form.per_day"))
                                .foregroundColor(.secondary)
                            Spacer()
                            let perDay = costValue / Decimal(calculateDays())
                            Text("\(currency.rawValue)\(perDay.formatted())")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }

                // Notes Section
                Section(header: Text(L("car_rental.form.section.notes"))) {
                    TextField(L("car_rental.form.notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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
                        saveCarRental()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                analytics.trackScreen(isEditing ? "car_rental_edit_screen" : "car_rental_add_screen")
            }
            .alert(L("car_rental.form.validation.error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateDays() -> Int {
        let components = Calendar.current.dateComponents([.day], from: pickupDate, to: dropoffDate)
        return max(1, components.day ?? 1)
    }

    private func validateForm() -> Bool {
        if company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("car_rental.form.validation.company_required")
            showValidationError = true
            return false
        }

        if pickupLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("car_rental.form.validation.pickup_required")
            showValidationError = true
            return false
        }

        if !sameLocation && dropoffLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("car_rental.form.validation.dropoff_required")
            showValidationError = true
            return false
        }

        if dropoffDate <= pickupDate {
            validationMessage = L("car_rental.form.validation.date_order")
            showValidationError = true
            return false
        }

        return true
    }

    private func saveCarRental() {
        guard validateForm() else { return }

        var costDecimal: Decimal? = nil
        if let parsed = Decimal(string: cost) {
            costDecimal = parsed
        }

        let finalDropoffLocation = sameLocation ? pickupLocation : dropoffLocation

        let carRental: CarRental
        if case .edit(let existingCarRental) = mode {
            carRental = CarRental(
                id: existingCarRental.id,
                journeyId: journeyId,
                company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                pickupLocation: pickupLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                dropoffLocation: finalDropoffLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                pickupDate: pickupDate,
                dropoffDate: dropoffDate,
                bookingReference: bookingReference.isEmpty ? nil : bookingReference,
                carType: carType.isEmpty ? nil : carType,
                cost: costDecimal,
                currency: costDecimal != nil ? currency : nil,
                notes: notes.isEmpty ? nil : notes,
                createdAt: existingCarRental.createdAt,
                updatedAt: Date()
            )
        } else {
            carRental = CarRental(
                journeyId: journeyId,
                company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                pickupLocation: pickupLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                dropoffLocation: finalDropoffLocation.trimmingCharacters(in: .whitespacesAndNewlines),
                pickupDate: pickupDate,
                dropoffDate: dropoffDate,
                bookingReference: bookingReference.isEmpty ? nil : bookingReference,
                carType: carType.isEmpty ? nil : carType,
                cost: costDecimal,
                currency: costDecimal != nil ? currency : nil,
                notes: notes.isEmpty ? nil : notes
            )
        }

        analytics.trackEvent(isEditing ? "car_rental_edited" : "car_rental_added", properties: [
            "days": calculateDays(),
            "has_cost": costDecimal != nil,
            "same_location": sameLocation
        ])

        onSave(carRental)
        dismiss()
    }
}
