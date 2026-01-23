import SwiftUI

struct JourneyStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: JourneyStatsViewModel

    init(journey: Journey) {
        _viewModel = State(initialValue: JourneyStatsViewModel(journey: journey))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Journey header
                    journeyHeader

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        // Stats grid
                        statsGrid
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L("journey.stats.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Close")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.loadStats()
            }
        }
    }

    // MARK: - Journey Header

    private var journeyHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.journey.name)
                .font(.title2)
                .fontWeight(.bold)

            if !viewModel.journey.destination.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.subheadline)
                    Text(viewModel.journey.destination)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }

            Text(formatDateRange(viewModel.journey))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatBlock(
                icon: "airplane",
                iconColor: .blue,
                count: viewModel.flightsCount,
                label: L("journey.stats.flights")
            )

            StatBlock(
                icon: "tram.fill",
                iconColor: .green,
                count: viewModel.trainsCount,
                label: L("journey.stats.trains")
            )

            StatBlock(
                icon: "bus.fill",
                iconColor: .orange,
                count: viewModel.otherTransportsCount,
                label: L("journey.stats.other_transport")
            )

            StatBlock(
                icon: "building.2.fill",
                iconColor: .purple,
                count: viewModel.hotelsCount,
                label: L("journey.stats.hotels")
            )

            StatBlock(
                icon: "car.fill",
                iconColor: .teal,
                count: viewModel.carRentalsCount,
                label: L("journey.stats.car_rentals")
            )

            StatBlock(
                icon: "doc.fill",
                iconColor: .red,
                count: viewModel.documentsCount,
                label: L("journey.stats.documents")
            )

            StatBlock(
                icon: "mappin.circle.fill",
                iconColor: .pink,
                count: viewModel.placesCount,
                label: L("journey.stats.places")
            )

            StatBlock(
                icon: "note.text",
                iconColor: .yellow,
                count: viewModel.notesCount,
                label: L("journey.stats.notes")
            )
        }
    }

    // MARK: - Helpers

    private func formatDateRange(_ journey: Journey) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: journey.startDate)) - \(formatter.string(from: journey.endDate))"
    }
}

// MARK: - Stat Block

struct StatBlock: View {
    let icon: String
    let iconColor: Color
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    JourneyStatsView(journey: Journey(
        name: "Summer Vacation",
        destination: "Paris, France",
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 7)
    ))
}
