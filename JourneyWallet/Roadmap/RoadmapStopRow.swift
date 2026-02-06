import SwiftUI

struct RoadmapStopRow: View {

    let stop: RoadmapStop
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
        HStack(alignment: .top, spacing: 12) {
            // Timeline visual
            timelineDot

            // Content
            VStack(alignment: .leading, spacing: 8) {
                stopHeader

                if isExpanded {
                    expandedContent
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
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

    // MARK: - Timeline Dot

    private var timelineDot: some View {
        VStack(spacing: 0) {
            // Dot
            Circle()
                .fill(isPast ? dotColor : Color.clear)
                .overlay(
                    Circle()
                        .stroke(dotColor, lineWidth: 2)
                )
                .frame(width: 16, height: 16)
                .padding(.top, 4)

            // Line to next stop
            if !isLast {
                Rectangle()
                    .fill(outgoingTransport != nil ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: outgoingTransport != nil ? 2 : 1)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 16)
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

                    if let arrival = stop.arrivalDate {
                        Text(formatDate(arrival))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if stop.arrivalDate != nil && stop.departureDate != nil {
                        Text("-")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let departure = stop.departureDate {
                        Text(formatDate(departure))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                Label(L("Open"), systemImage: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}
