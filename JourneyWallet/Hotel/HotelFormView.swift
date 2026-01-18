import SwiftUI

enum HotelFormMode: Identifiable {
    case add
    case edit(Hotel)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let hotel): return hotel.id.uuidString
        }
    }
}

struct HotelFormView: View {

    let journeyId: UUID
    let mode: HotelFormMode
    let onSave: (Hotel) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    // Form state
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var checkInDate: Date = Date()
    @State private var checkOutDate: Date = Date().addingTimeInterval(24 * 60 * 60)
    @State private var bookingReference: String = ""
    @State private var roomType: String = ""
    @State private var contactPhone: String = ""
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
        isEditing ? L("hotel.form.edit_title") : L("hotel.form.add_title")
    }

    init(journeyId: UUID, mode: HotelFormMode, onSave: @escaping (Hotel) -> Void) {
        self.journeyId = journeyId
        self.mode = mode
        self.onSave = onSave

        // Initialize state from existing hotel if editing
        if case .edit(let hotel) = mode {
            _name = State(initialValue: hotel.name)
            _address = State(initialValue: hotel.address)
            _checkInDate = State(initialValue: hotel.checkInDate)
            _checkOutDate = State(initialValue: hotel.checkOutDate)
            _bookingReference = State(initialValue: hotel.bookingReference ?? "")
            _roomType = State(initialValue: hotel.roomType ?? "")
            _contactPhone = State(initialValue: hotel.contactPhone ?? "")
            _cost = State(initialValue: hotel.cost?.description ?? "")
            _currency = State(initialValue: hotel.currency ?? .usd)
            _notes = State(initialValue: hotel.notes ?? "")
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
                // Hotel Info Section
                Section(header: Text(L("hotel.form.section.hotel"))) {
                    TextField(L("hotel.form.name"), text: $name)
                        .textContentType(.organizationName)

                    TextField(L("hotel.form.address"), text: $address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                }

                // Dates Section
                Section(header: Text(L("hotel.form.section.dates"))) {
                    DatePicker(
                        L("hotel.form.check_in"),
                        selection: $checkInDate,
                        displayedComponents: [.date]
                    )

                    DatePicker(
                        L("hotel.form.check_out"),
                        selection: $checkOutDate,
                        in: checkInDate.addingTimeInterval(24 * 60 * 60)...,
                        displayedComponents: [.date]
                    )

                    // Duration display
                    HStack {
                        Text(L("hotel.form.nights"))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(calculateNights()) \(L("hotel.nights"))")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }

                // Booking Details Section
                Section(header: Text(L("hotel.form.section.booking"))) {
                    TextField(L("hotel.form.booking_reference"), text: $bookingReference)
                        .textInputAutocapitalization(.characters)

                    TextField(L("hotel.form.room_type"), text: $roomType)
                }

                // Contact Section
                Section(header: Text(L("hotel.form.section.contact"))) {
                    TextField(L("hotel.form.phone"), text: $contactPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                // Cost Section
                Section(header: Text(L("hotel.form.section.cost"))) {
                    HStack {
                        Picker(L("hotel.form.currency"), selection: $currency) {
                            ForEach(Currency.allCases, id: \.self) { curr in
                                Text("\(curr.symbol) \(curr.rawValue)").tag(curr)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)

                        TextField(L("hotel.form.total_cost"), text: $cost)
                            .keyboardType(.decimalPad)
                    }

                    // Per night calculation
                    if let costValue = Decimal(string: cost), costValue > 0, calculateNights() > 0 {
                        HStack {
                            Text(L("hotel.form.per_night"))
                                .foregroundColor(.secondary)
                            Spacer()
                            let perNight = costValue / Decimal(calculateNights())
                            Text("\(currency.symbol)\(perNight.formatted())")
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }

                // Notes Section
                Section(header: Text(L("hotel.form.section.notes"))) {
                    TextField(L("hotel.form.notes"), text: $notes, axis: .vertical)
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
                        saveHotel()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                analytics.trackScreen(isEditing ? "hotel_edit_screen" : "hotel_add_screen")
            }
            .alert(L("hotel.form.validation.error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Helper Methods

    private func calculateNights() -> Int {
        let components = Calendar.current.dateComponents([.day], from: checkInDate, to: checkOutDate)
        return components.day ?? 0
    }

    private func validateForm() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("hotel.form.validation.name_required")
            showValidationError = true
            return false
        }

        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = L("hotel.form.validation.address_required")
            showValidationError = true
            return false
        }

        if checkOutDate <= checkInDate {
            validationMessage = L("hotel.form.validation.date_order")
            showValidationError = true
            return false
        }

        return true
    }

    private func saveHotel() {
        guard validateForm() else { return }

        var costDecimal: Decimal? = nil
        if let parsed = Decimal(string: cost) {
            costDecimal = parsed
        }

        let hotel: Hotel
        if case .edit(let existingHotel) = mode {
            hotel = Hotel(
                id: existingHotel.id,
                journeyId: journeyId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                checkInDate: checkInDate,
                checkOutDate: checkOutDate,
                bookingReference: bookingReference.isEmpty ? nil : bookingReference,
                roomType: roomType.isEmpty ? nil : roomType,
                cost: costDecimal,
                currency: costDecimal != nil ? currency : nil,
                contactPhone: contactPhone.isEmpty ? nil : contactPhone,
                notes: notes.isEmpty ? nil : notes,
                createdAt: existingHotel.createdAt,
                updatedAt: Date()
            )
        } else {
            hotel = Hotel(
                journeyId: journeyId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                checkInDate: checkInDate,
                checkOutDate: checkOutDate,
                bookingReference: bookingReference.isEmpty ? nil : bookingReference,
                roomType: roomType.isEmpty ? nil : roomType,
                cost: costDecimal,
                currency: costDecimal != nil ? currency : nil,
                contactPhone: contactPhone.isEmpty ? nil : contactPhone,
                notes: notes.isEmpty ? nil : notes
            )
        }

        analytics.trackEvent(isEditing ? "hotel_edited" : "hotel_added", properties: [
            "nights": calculateNights(),
            "has_cost": costDecimal != nil
        ])

        onSave(hotel)
        dismiss()
    }
}
