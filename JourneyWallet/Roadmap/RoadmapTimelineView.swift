import SwiftUI

struct RoadmapTimelineView: View {

    @State private var viewModel = RoadmapTimelineViewModel()
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var localStops: [RoadmapStop] = []
    @State private var showAddStopSheet: Bool = false
    @State private var showCreateJourneySheet: Bool = false
    @State private var showResetConfirmation: Bool = false
    @State private var editMode: EditMode = .active

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Journey selector
                JourneySelectorView(
                    journeys: viewModel.allJourneys,
                    selectedJourneyId: viewModel.selectedJourneyId,
                    onSelect: { journeyId in
                        viewModel.selectJourney(id: journeyId)
                    },
                    onCreateNew: {
                        showCreateJourneySheet = true
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)

                if viewModel.stops.isEmpty {
                    emptyState
                } else {
                    timelineContent
                }
            }
            .background(Color(.systemGray6))
            .navigationTitle(L("roadmap.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.hasTimeline {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) {
                                showResetConfirmation = true
                            } label: {
                                Label(L("roadmap.reset_timeline"), systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel(L("roadmap.more_options"))
                    }
                }
            }
            .alert(L("roadmap.reset_timeline.title"), isPresented: $showResetConfirmation) {
                Button(L("cancel"), role: .cancel) {}
                Button(L("roadmap.reset_timeline"), role: .destructive) {
                    viewModel.resetTimeline()
                }
            } message: {
                Text(L("roadmap.reset_timeline.message"))
            }
            .onAppear {
                viewModel.loadInitialData()
                localStops = viewModel.stops
                analytics.trackScreen("roadmap_timeline_screen")
            }
            .onChange(of: viewModel.stops) { _, newStops in
                localStops = newStops
            }
            .refreshable {
                viewModel.refreshData()
            }
            .sheet(isPresented: $showAddStopSheet) {
                RoadmapStopFormView(
                    journeyId: viewModel.selectedJourneyId ?? UUID(),
                    mode: .add,
                    nextSortOrder: viewModel.nextSortOrder()
                ) { newStop in
                    viewModel.addStop(newStop)
                }
            }
            .sheet(isPresented: $showCreateJourneySheet) {
                JourneyFormView(
                    mode: .add,
                    onSave: { _ in
                        viewModel.refreshData()
                    }
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(L("roadmap.empty.title"))
                .font(.title2)
                .fontWeight(.bold)

            Text(L("roadmap.empty.message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showAddStopSheet = true
            } label: {
                Label(L("roadmap.add_stop"), systemImage: "plus")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(25)
            }
            .disabled(viewModel.selectedJourneyId == nil)
            .accessibilityLabel(L("roadmap.add_stop"))

            Spacer()
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb")
                        .font(.caption2)
                    Text(L("roadmap.hint.tap_to_expand"))
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                ForEach(localStops) { stop in
                    let index = localStops.firstIndex(where: { $0.id == stop.id }) ?? 0
                    let dateInconsistent = hasDateInconsistency(
                        stop: stop,
                        nextStop: index + 1 < localStops.count ? localStops[index + 1] : nil
                    )
                    RoadmapStopRow(
                        stop: stop,
                        isFirst: index == 0,
                        isLast: index == localStops.count - 1,
                        attachments: viewModel.attachmentsByStopId[stop.id] ?? [],
                        outgoingTransport: viewModel.transportsByStopId[stop.id],
                        hasDateInconsistency: dateInconsistent,
                        viewModel: viewModel
                    )
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
                .onMove { source, destination in
                    localStops.move(fromOffsets: source, toOffset: destination)
                    viewModel.persistStopReorder(localStops)
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, $editMode)
            }

            // FAB
            Button {
                showAddStopSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel(L("roadmap.add_stop"))
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
    // MARK: - Helpers

    private func hasDateInconsistency(stop: RoadmapStop, nextStop: RoadmapStop?) -> Bool {
        guard let nextStop else { return false }

        let currentLatest = stop.departureDate ?? stop.arrivalDate
        let nextEarliest = nextStop.arrivalDate ?? nextStop.departureDate

        guard let currentDate = currentLatest, let nextDate = nextEarliest else {
            return false
        }

        return currentDate > nextDate
    }
}

#Preview {
    RoadmapTimelineView()
}
