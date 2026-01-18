import SwiftUI

struct BudgetView: View {

    let journeyId: UUID

    @State private var viewModel: BudgetViewModel
    @ObservedObject private var analytics = AnalyticsService.shared

    private let userSettingsRepository: UserSettingsRepository?

    init(journeyId: UUID) {
        self.journeyId = journeyId
        self._viewModel = State(initialValue: BudgetViewModel(journeyId: journeyId))
        self.userSettingsRepository = DatabaseManager.shared.userSettingsRepository
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary section
            if !viewModel.expenses.isEmpty {
                totalSummaryCard
                    .padding(.horizontal)
                    .padding(.top, 8)

                categoryBreakdownSection
                    .padding(.horizontal)
                    .padding(.top, 12)
            }

            // Filter section
            filterSection
                .padding(.horizontal)
                .padding(.vertical, 8)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredExpenses.isEmpty {
                emptyStateView
            } else {
                expenseList
            }
        }
        .navigationTitle(L("budget.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    analytics.trackEvent("add_expense_button_clicked", properties: [
                        "screen": "budget_screen"
                    ])
                    viewModel.showAddExpenseSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            analytics.trackScreen("budget_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showAddExpenseSheet) {
            ExpenseFormView(
                journeyId: journeyId,
                mode: .add,
                defaultCurrency: userSettingsRepository?.fetchCurrency() ?? .usd,
                onSave: { expense in
                    viewModel.addExpense(expense)
                }
            )
        }
        .sheet(item: $viewModel.expenseToEdit) { expense in
            ExpenseFormView(
                journeyId: journeyId,
                mode: .edit(expense),
                defaultCurrency: expense.currency,
                onSave: { updatedExpense in
                    viewModel.updateExpense(updatedExpense)
                }
            )
        }
    }

    // MARK: - Total Summary Card

    private var totalSummaryCard: some View {
        VStack(spacing: 8) {
            Text(L("budget.total_spent"))
                .font(.caption)
                .foregroundColor(.secondary)

            Text(viewModel.formattedTotal)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.orange)

            Text("\(viewModel.expenses.count) \(L("budget.expenses"))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Category Breakdown Section

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("budget.by_category"))
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.categoryBreakdown, id: \.category) { item in
                        CategoryChip(
                            category: item.category,
                            amount: item.amount,
                            currency: item.currency
                        )
                    }
                }
            }
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExpenseFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                        viewModel.applyFilters()
                    }
                }
            }
        }
    }

    // MARK: - Expense List

    private var expenseList: some View {
        List {
            ForEach(viewModel.filteredExpenses) { expense in
                ExpenseListRow(expense: expense)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.expenseToEdit = expense
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteExpense(expense)
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }

                        Button {
                            viewModel.expenseToEdit = expense
                        } label: {
                            Label(L("Edit"), systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "dollarsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(L("budget.empty.title"))
                .font(.headline)
                .foregroundColor(.secondary)

            Text(L("budget.empty.message"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                viewModel.showAddExpenseSheet = true
            }) {
                Label(L("budget.add_first"), systemImage: "plus")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {

    let category: ExpenseCategory
    let amount: Decimal
    let currency: Currency

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(categoryColor)
                .cornerRadius(8)

            Text(category.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text("\(currency.rawValue)\(formatAmount(amount))")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(width: 70)
    }

    private var categoryColor: Color {
        switch category {
        case .transport: return .blue
        case .accommodation: return .purple
        case .food: return .orange
        case .activities: return .green
        case .shopping: return .pink
        case .other: return .gray
        }
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

// MARK: - Expense List Row

struct ExpenseListRow: View {

    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: expense.category.icon)
                    .foregroundColor(categoryColor)
                    .font(.system(size: 18))
            }

            // Expense info
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(expense.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formatDate(expense.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Amount
            Text("\(expense.currency.rawValue)\(formatAmount(expense.amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch expense.category {
        case .transport: return .blue
        case .accommodation: return .purple
        case .food: return .orange
        case .activities: return .green
        case .shopping: return .pink
        case .other: return .gray
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}

#Preview {
    NavigationStack {
        BudgetView(journeyId: UUID())
    }
}
