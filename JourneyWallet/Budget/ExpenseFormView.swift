import SwiftUI

enum ExpenseFormMode {
    case add
    case edit(Expense)

    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }

    var existingExpense: Expense? {
        if case .edit(let expense) = self { return expense }
        return nil
    }
}

struct ExpenseFormView: View {

    let journeyId: UUID
    let mode: ExpenseFormMode
    let defaultCurrency: Currency
    let onSave: (Expense) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    // Form fields
    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var currency: Currency
    @State private var category: ExpenseCategory = .other
    @State private var date: Date = Date()
    @State private var notes: String = ""

    // Validation
    @State private var showValidationError: Bool = false
    @State private var validationMessage: String = ""

    init(journeyId: UUID, mode: ExpenseFormMode, defaultCurrency: Currency, onSave: @escaping (Expense) -> Void) {
        self.journeyId = journeyId
        self.mode = mode
        self.defaultCurrency = defaultCurrency
        self.onSave = onSave

        // Initialize currency from existing expense if editing, otherwise use default
        if case .edit(let expense) = mode {
            _currency = State(initialValue: expense.currency)
        } else {
            _currency = State(initialValue: defaultCurrency)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                expenseInfoSection
                amountSection
                categorySection
                dateSection
                notesSection
            }
            .navigationTitle(mode.isEditing ? L("expense.form.edit_title") : L("expense.form.add_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                analytics.trackScreen("expense_form_screen")
                loadExistingData()
            }
            .alert(L("expense.form.validation.error"), isPresented: $showValidationError) {
                Button(L("OK"), role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }

    // MARK: - Form Sections

    private var expenseInfoSection: some View {
        Section {
            TextField(L("expense.form.title"), text: $title)
        } header: {
            Text(L("expense.form.section.info"))
        }
    }

    private var amountSection: some View {
        Section {
            HStack {
                TextField(L("expense.form.amount"), text: $amountString)
                    .keyboardType(.decimalPad)

                Picker("", selection: $currency) {
                    ForEach(Currency.allCases, id: \.self) { curr in
                        Text(curr.rawValue).tag(curr)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 80)
            }
        } header: {
            Text(L("expense.form.section.amount"))
        }
    }

    private var categorySection: some View {
        Section {
            Picker(L("expense.form.category"), selection: $category) {
                ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                    Label(cat.displayName, systemImage: cat.icon)
                        .tag(cat)
                }
            }
        } header: {
            Text(L("expense.form.section.category"))
        }
    }

    private var dateSection: some View {
        Section {
            DatePicker(
                L("expense.form.date"),
                selection: $date,
                displayedComponents: [.date]
            )
        } header: {
            Text(L("expense.form.section.date"))
        }
    }

    private var notesSection: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 60)
        } header: {
            Text(L("expense.form.section.notes"))
        }
    }

    // MARK: - Private Methods

    private func loadExistingData() {
        if let expense = mode.existingExpense {
            title = expense.title
            amountString = "\(expense.amount)"
            category = expense.category
            date = expense.date
            notes = expense.notes ?? ""
        }
    }

    private func saveExpense() {
        // Validate title
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            validationMessage = L("expense.form.validation.title_required")
            showValidationError = true
            return
        }

        // Validate amount
        let cleanedAmount = amountString.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: cleanedAmount), amount > 0 else {
            validationMessage = L("expense.form.validation.amount_required")
            showValidationError = true
            return
        }

        let expense: Expense

        if let existingExpense = mode.existingExpense {
            // Update existing expense
            expense = Expense(
                id: existingExpense.id,
                journeyId: journeyId,
                title: trimmedTitle,
                amount: amount,
                currency: currency,
                category: category,
                date: date,
                notes: notes.isEmpty ? nil : notes,
                createdAt: existingExpense.createdAt
            )
            analytics.trackEvent("expense_updated", properties: ["expense_id": existingExpense.id.uuidString])
        } else {
            // Create new expense
            expense = Expense(
                journeyId: journeyId,
                title: trimmedTitle,
                amount: amount,
                currency: currency,
                category: category,
                date: date,
                notes: notes.isEmpty ? nil : notes
            )
            analytics.trackEvent("expense_created", properties: [
                "journey_id": journeyId.uuidString,
                "category": category.rawValue,
                "currency": currency.rawValue
            ])
        }

        onSave(expense)
        dismiss()
    }
}

#Preview {
    ExpenseFormView(
        journeyId: UUID(),
        mode: .add,
        defaultCurrency: .usd,
        onSave: { _ in }
    )
}
