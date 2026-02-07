import SwiftUI

struct RoadmapStopRow: View {

    let stop: RoadmapStop
    let isFirst: Bool
    let isLast: Bool
    let attachments: [RoadmapStopAttachment]
    let outgoingTransport: Transport?
    let viewModel: RoadmapTimelineViewModel

    @State private var isExpanded: Bool = false
    @State private var showDetailView: Bool = false

    private var isPast: Bool {
        if let departureDate = stop.departureDate {
            return departureDate < Date()
        }
        if let arrivalDate = stop.arrivalDate {
            return arrivalDate < Date()
        }
        return false
    }

    private var dotColor: Color {
        isPast ? .orange : .blue
    }

    var body: some View {
        VStack(spacing: 0) {
            // Incoming section: line + optional transport label
            if !isFirst {
                incomingSection
            }

            // Stop content
            VStack(alignment: .leading, spacing: 8) {
                stopHeader

                if isExpanded {
                    expandedContent
                }
            }
            .padding(.bottom, 4)
        }
        .sheet(isPresented: $showDetailView) {
            RoadmapStopDetailView(
                stop: stop,
                attachments: attachments,
                outgoingTransport: outgoingTransport,
                viewModel: viewModel,
                onDelete: {}
            )
        }
    }

    // MARK: - Incoming Section

    private var incomingSection: some View {
        VStack(spacing: 0) {
            if let transport = outgoingTransport {
                Spacer().frame(height: 20)

                HStack(spacing: 4) {
                    Image(systemName: transport.type.iconName)
                        .font(.caption2)
                        .foregroundColor(transport.type.color)
                    Text("\(transport.departureLocation) → \(transport.arrivalLocation)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer().frame(height: 6)
            } else {
                Spacer().frame(height: 8)
            }
        }
    }

    // MARK: - Stop Header

    private var stopHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stop.title)
                    .font(.headline)

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let subtitle = stop.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Date range
            if stop.arrivalDate != nil || stop.departureDate != nil {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text(formatDateRange(arrival: stop.arrivalDate, departure: stop.departureDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Attachment count badge
            if !attachments.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(attachments.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Notes
            if let notes = stop.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
            }

            // Attached entities
            if !attachments.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(attachments) { attachment in
                        HStack(spacing: 8) {
                            Image(systemName: viewModel.entityIcon(for: attachment.entityType))
                                .font(.caption)
                                .foregroundColor(viewModel.entityColor(for: attachment.entityType))
                                .frame(width: 20)

                            Text(viewModel.entityDisplayName(for: attachment))
                                .font(.caption)
                                .lineLimit(1)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                    }
                }
                .background(Color(.systemBackground).opacity(0.5))
                .cornerRadius(8)
            }

            // Outgoing transport card
            if let transport = outgoingTransport {
                HStack(spacing: 8) {
                    Image(systemName: transport.type.iconName)
                        .font(.caption)
                        .foregroundColor(transport.type.color)

                    Text("\(transport.departureLocation) → \(transport.arrivalLocation)")
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Open detail button
            Button {
                showDetailView = true
            } label: {
                Label(L("open.details"), systemImage: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers

    private func formatDateRange(arrival: Date?, departure: Date?) -> String {
        if let arrival, let departure,
           Calendar.current.isDate(arrival, inSameDayAs: departure) {
            let day = arrival.formatted(.dateTime.day().month(.abbreviated))
            let startTime = arrival.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
            let endTime = departure.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute())
            return "\(day), \(startTime) - \(endTime)"
        }

        if let arrival, let departure {
            return "\(formatDate(arrival)) - \(formatDate(departure))"
        }

        if let arrival {
            return formatDate(arrival)
        }

        if let departure {
            return formatDate(departure)
        }

        return ""
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}
