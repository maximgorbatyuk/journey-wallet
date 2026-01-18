import SwiftUI

struct JourneyDetailView: View {

    @State private var viewModel = JourneyDetailViewModel()
    @State private var showAddJourneySheet = false
    @State private var showTransportList = false
    @State private var showHotelList = false
    @State private var showCarRentalList = false
    @State private var showDocumentList = false
    @State private var showNoteList = false
    @State private var showPlaceList = false
    @State private var showBudgetView = false
    @State private var showQuickAddSheet = false
    @ObservedObject private var analytics = AnalyticsService.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.allJourneys.isEmpty {
                        emptyStateView
                    } else {
                    // Journey selector at top
                    JourneySelectorView(
                        journeys: viewModel.allJourneys,
                        selectedJourneyId: viewModel.selectedJourneyId,
                        onSelect: { id in
                            viewModel.selectJourney(id: id)
                        },
                        onCreateNew: {
                            showAddJourneySheet = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Journey info header
                    if let journey = viewModel.selectedJourney {
                        journeyInfoHeader(journey: journey)
                    }

                    // Scrollable sections
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.transport"),
                                    iconName: "airplane",
                                    iconColor: .blue,
                                    itemCount: viewModel.sectionCounts.transports,
                                    onSeeAll: viewModel.selectedJourneyId != nil ? {
                                        showTransportList = true
                                    } : nil
                                ),
                                content: {
                                    if viewModel.upcomingTransports.isEmpty {
                                        Button {
                                            showTransportList = true
                                        } label: {
                                            EmptySectionView(
                                                message: L("journey.detail.transport.empty"),
                                                iconName: "airplane"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ForEach(viewModel.upcomingTransports) { transport in
                                            TransportPreviewRow(transport: transport)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showTransportList = true
                                                }
                                            if transport.id != viewModel.upcomingTransports.last?.id {
                                                Divider().padding(.leading, 56)
                                            }
                                        }
                                    }
                                }
                            )

                            // Hotels Section
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.hotels"),
                                    iconName: "building.2.fill",
                                    iconColor: .purple,
                                    itemCount: viewModel.sectionCounts.hotels,
                                    onSeeAll: viewModel.selectedJourneyId != nil ? {
                                        showHotelList = true
                                    } : nil
                                ),
                                content: {
                                    if viewModel.upcomingHotels.isEmpty {
                                        Button {
                                            showHotelList = true
                                        } label: {
                                            EmptySectionView(
                                                message: L("journey.detail.hotels.empty"),
                                                iconName: "building.2"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ForEach(viewModel.upcomingHotels) { hotel in
                                            HotelPreviewRow(hotel: hotel)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showHotelList = true
                                                }
                                            if hotel.id != viewModel.upcomingHotels.last?.id {
                                                Divider().padding(.leading, 56)
                                            }
                                        }
                                    }
                                }
                            )

                            // Car Rentals Section
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.car_rentals"),
                                    iconName: "car.fill",
                                    iconColor: .green,
                                    itemCount: viewModel.sectionCounts.carRentals,
                                    onSeeAll: viewModel.selectedJourneyId != nil ? {
                                        showCarRentalList = true
                                    } : nil
                                ),
                                content: {
                                    if viewModel.upcomingCarRentals.isEmpty {
                                        Button {
                                            showCarRentalList = true
                                        } label: {
                                            EmptySectionView(
                                                message: L("journey.detail.car_rentals.empty"),
                                                iconName: "car"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ForEach(viewModel.upcomingCarRentals) { carRental in
                                            CarRentalPreviewRow(carRental: carRental)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showCarRentalList = true
                                                }
                                            if carRental.id != viewModel.upcomingCarRentals.last?.id {
                                                Divider().padding(.leading, 56)
                                            }
                                        }
                                    }
                                }
                            )

                            // Documents Section
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.documents"),
                                    iconName: "doc.fill",
                                    iconColor: .orange,
                                    itemCount: viewModel.sectionCounts.documents,
                                    onSeeAll: viewModel.selectedJourneyId != nil ? {
                                        showDocumentList = true
                                    } : nil
                                ),
                                content: {
                                    if viewModel.sectionCounts.documents == 0 {
                                        Button {
                                            showDocumentList = true
                                        } label: {
                                            EmptySectionView(
                                                message: L("journey.detail.documents.empty"),
                                                iconName: "doc"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            showDocumentList = true
                                        } label: {
                                            HStack {
                                                Text("\(viewModel.sectionCounts.documents) \(L("journey.detail.documents.count"))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding()
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            )

                            // Notes Section
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.notes"),
                                    iconName: "note.text",
                                    iconColor: .yellow,
                                    itemCount: viewModel.sectionCounts.notes,
                                    onSeeAll: viewModel.selectedJourneyId != nil ? {
                                        showNoteList = true
                                    } : nil
                                ),
                                content: {
                                    if viewModel.recentNotes.isEmpty {
                                        Button {
                                            showNoteList = true
                                        } label: {
                                            EmptySectionView(
                                                message: L("journey.detail.notes.empty"),
                                                iconName: "note.text"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ForEach(viewModel.recentNotes) { note in
                                            NotePreviewRow(note: note)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showNoteList = true
                                                }
                                            if note.id != viewModel.recentNotes.last?.id {
                                                Divider().padding(.leading, 56)
                                            }
                                        }
                                    }
                                }
                            )

                            // Places to Visit Section
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.places"),
                                    iconName: "mappin.circle.fill",
                                    iconColor: .red,
                                    itemCount: viewModel.sectionCounts.places,
                                    onSeeAll: viewModel.selectedJourneyId != nil ? {
                                        showPlaceList = true
                                    } : nil
                                ),
                                content: {
                                    if viewModel.upcomingPlaces.isEmpty {
                                        Button {
                                            showPlaceList = true
                                        } label: {
                                            EmptySectionView(
                                                message: L("journey.detail.places.empty"),
                                                iconName: "mappin"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        ForEach(viewModel.upcomingPlaces) { place in
                                            PlacePreviewRow(place: place)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showPlaceList = true
                                                }
                                            if place.id != viewModel.upcomingPlaces.last?.id {
                                                Divider().padding(.leading, 56)
                                            }
                                        }
                                    }
                                }
                            )

                            // Reminders Section
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.reminders"),
                                    iconName: "bell.fill",
                                    iconColor: .red,
                                    itemCount: viewModel.sectionCounts.reminders,
                                    onSeeAll: viewModel.sectionCounts.reminders > 0 ? {
                                        // TODO: Navigate to full reminders list
                                    } : nil
                                ),
                                content: {
                                    if viewModel.upcomingReminders.isEmpty {
                                        EmptySectionView(
                                            message: L("journey.detail.reminders.empty"),
                                            iconName: "bell"
                                        )
                                    } else {
                                        ForEach(viewModel.upcomingReminders) { reminder in
                                            ReminderPreviewRow(reminder: reminder)
                                            if reminder.id != viewModel.upcomingReminders.last?.id {
                                                Divider().padding(.leading, 56)
                                            }
                                        }
                                    }
                                }
                            )

                            // Budget Section
                            sectionContainer(
                                header: SectionHeaderView(
                                    title: L("journey.detail.section.budget"),
                                    iconName: "dollarsign.circle.fill",
                                    iconColor: .green,
                                    itemCount: viewModel.sectionCounts.expenses,
                                    onSeeAll: viewModel.selectedJourneyId != nil ? {
                                        showBudgetView = true
                                    } : nil
                                ),
                                content: {
                                    if viewModel.sectionCounts.expenses == 0 {
                                        Button {
                                            showBudgetView = true
                                        } label: {
                                            EmptySectionView(
                                                message: L("journey.detail.budget.empty"),
                                                iconName: "dollarsign.circle"
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    } else {
                                        Button {
                                            showBudgetView = true
                                        } label: {
                                            BudgetSummaryView(
                                                totalExpenses: viewModel.sectionCounts.totalExpenses,
                                                expenseCount: viewModel.sectionCounts.expenses,
                                                currency: viewModel.sectionCounts.expensesCurrency
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            )

                            // Bottom padding for FAB
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                }
                }
                .background(Color(.systemGray6))

                // Floating Action Button
                if viewModel.selectedJourneyId != nil {
                    floatingAddButton
                }
            }
            .navigationTitle(L("journey.detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                analytics.trackScreen("journey_detail_screen")
                viewModel.loadInitialData()
            }
            .refreshable {
                viewModel.refreshData()
            }
            .sheet(isPresented: $showAddJourneySheet) {
                JourneyFormView(
                    mode: .add,
                    onSave: { journey in
                        // Add journey and select it
                        if DatabaseManager.shared.journeysRepository?.insert(journey) == true {
                            viewModel.refreshData()
                            viewModel.selectJourney(id: journey.id)
                        }
                    }
                )
            }
            .sheet(isPresented: $showQuickAddSheet) {
                if let journeyId = viewModel.selectedJourneyId {
                    QuickAddSheet(journeyId: journeyId) {
                        viewModel.refreshData()
                    }
                }
            }
            .navigationDestination(isPresented: $showTransportList) {
                TransportListView(journeyId: viewModel.selectedJourneyId ?? UUID())
            }
            .navigationDestination(isPresented: $showHotelList) {
                HotelListView(journeyId: viewModel.selectedJourneyId ?? UUID())
            }
            .navigationDestination(isPresented: $showCarRentalList) {
                CarRentalListView(journeyId: viewModel.selectedJourneyId ?? UUID())
            }
            .navigationDestination(isPresented: $showDocumentList) {
                DocumentListView(journeyId: viewModel.selectedJourneyId ?? UUID())
            }
            .navigationDestination(isPresented: $showNoteList) {
                NoteListView(journeyId: viewModel.selectedJourneyId ?? UUID())
            }
            .navigationDestination(isPresented: $showPlaceList) {
                PlaceListView(journeyId: viewModel.selectedJourneyId ?? UUID())
            }
            .navigationDestination(isPresented: $showBudgetView) {
                BudgetView(journeyId: viewModel.selectedJourneyId ?? UUID())
            }
        }
    }

    // MARK: - Floating Action Button

    private var floatingAddButton: some View {
        Button {
            showQuickAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.orange)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "suitcase")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(L("journey.detail.empty.title"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)

            Text(L("journey.detail.empty.subtitle"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                showAddJourneySheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text(L("journey.detail.empty.add_button"))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Journey Info Header

    private func journeyInfoHeader(journey: Journey) -> some View {
        HStack(spacing: 16) {
            // Status badge
            Text(journeyStatusText(journey))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(journeyStatusColor(journey))
                .cornerRadius(12)

            // Duration
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("\(journey.durationDays) \(L("journey.days"))")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            Spacer()

            // Days until/since
            Text(daysUntilText(journey))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func journeyStatusText(_ journey: Journey) -> String {
        if journey.isActive {
            return L("journey.status.active")
        } else if journey.isUpcoming {
            return L("journey.status.upcoming")
        } else {
            return L("journey.status.past")
        }
    }

    private func journeyStatusColor(_ journey: Journey) -> Color {
        if journey.isActive {
            return .green
        } else if journey.isUpcoming {
            return .blue
        } else {
            return .gray
        }
    }

    private func daysUntilText(_ journey: Journey) -> String {
        let now = Date()
        let calendar = Calendar.current

        if journey.isActive {
            let daysLeft = calendar.dateComponents([.day], from: now, to: journey.endDate).day ?? 0
            return "\(daysLeft) \(L("journey.detail.days_left"))"
        } else if journey.isUpcoming {
            let daysUntil = calendar.dateComponents([.day], from: now, to: journey.startDate).day ?? 0
            return "\(L("journey.detail.starts_in")) \(daysUntil) \(L("journey.days"))"
        } else {
            let daysSince = calendar.dateComponents([.day], from: journey.endDate, to: now).day ?? 0
            return "\(daysSince) \(L("journey.detail.days_ago"))"
        }
    }

    // MARK: - Section Container

    @ViewBuilder
    private func sectionContainer<Content: View>(
        header: SectionHeaderView,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            header
            Divider()
            content()
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

#Preview {
    JourneyDetailView()
}
