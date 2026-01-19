import SwiftUI

// MARK: - Extended Stats Section

struct ExtendedStatsSection: View {
    let statistics: OverviewStatistics
    let transportStats: TransportStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Transport Breakdown
            if transportStats.totalTransports > 0 {
                transportBreakdownCard
            }
        }
    }

    private var transportBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("stats.transport_breakdown"), systemImage: "airplane")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(transportStats.breakdown, id: \.type) { item in
                    TransportStatItem(
                        type: item.type,
                        count: item.count
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

}

// MARK: - Mini Stat Item

struct MiniStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Transport Stat Item

struct TransportStatItem: View {
    let type: TransportType
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.color)

                Text("\(count)")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Text(type.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(type.color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Journey Stats Card

struct JourneyStatsCard: View {
    let stats: JourneyDetailStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("stats.journey_summary"))
                .font(.headline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                JourneyStatItem(
                    value: "\(stats.transportsCount)",
                    label: L("stats.transports"),
                    icon: "airplane",
                    color: .blue
                )

                JourneyStatItem(
                    value: "\(stats.hotelsCount)",
                    label: L("stats.hotels"),
                    icon: "bed.double.fill",
                    color: .purple
                )

                JourneyStatItem(
                    value: "\(stats.carRentalsCount)",
                    label: L("stats.car_rentals"),
                    icon: "car.fill",
                    color: .green
                )

                JourneyStatItem(
                    value: "\(stats.placesVisited)/\(stats.placesCount)",
                    label: L("stats.places_visited"),
                    icon: "mappin.circle.fill",
                    color: .orange
                )

                JourneyStatItem(
                    value: "\(stats.remindersCompleted)/\(stats.remindersCount)",
                    label: L("stats.reminders"),
                    icon: "bell.fill",
                    color: .red
                )

                JourneyStatItem(
                    value: "\(stats.expensesCount)",
                    label: L("stats.expenses"),
                    icon: "creditcard.fill",
                    color: .teal
                )
            }

        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Journey Stat Item

struct JourneyStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Quick Insights Card

struct QuickInsightsCard: View {
    let totalTravelDays: Int
    let longestJourney: Journey?
    let mostVisitedDestination: (destination: String, count: Int)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("stats.quick_insights"), systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                // Total travel days
                InsightRow(
                    icon: "calendar.badge.clock",
                    color: .blue,
                    title: L("stats.total_travel_days"),
                    value: "\(totalTravelDays) \(L("stats.days"))"
                )

                // Longest journey
                if let journey = longestJourney {
                    InsightRow(
                        icon: "trophy.fill",
                        color: .orange,
                        title: L("stats.longest_journey"),
                        value: "\(journey.name) (\(journey.durationDays) \(L("stats.days")))"
                    )
                }

                // Most visited destination
                if let destination = mostVisitedDestination {
                    InsightRow(
                        icon: "star.fill",
                        color: .yellow,
                        title: L("stats.most_visited"),
                        value: "\(destination.destination) (\(destination.count)x)"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ExtendedStatsSection(
                statistics: OverviewStatistics(
                    totalJourneys: 12,
                    activeJourneys: 1,
                    upcomingJourneys: 3,
                    pastJourneys: 8,
                    uniqueDestinations: 7
                ),
                transportStats: TransportStatistics(
                    totalTransports: 25,
                    flights: 15,
                    trains: 6,
                    buses: 2,
                    ferries: 1,
                    transfers: 1,
                    other: 0
                )
            )

            QuickInsightsCard(
                totalTravelDays: 85,
                longestJourney: nil,
                mostVisitedDestination: ("Paris", 3)
            )
        }
        .padding()
    }
}
