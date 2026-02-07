import SwiftUI

struct RoadmapStopRow: View {

    let stop: RoadmapStop
    let isFirst: Bool
    let isLast: Bool
    let attachments: [RoadmapStopAttachment]
    let outgoingTransport: Transport?
    let hasDateInconsistency: Bool
    let viewModel: RoadmapTimelineViewModel

    @State private var showDetailView: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Stop content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(stop.title)
                    .font(.headline)

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

                // Date inconsistency warning
                if hasDateInconsistency {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(L("roadmap.date_inconsistency"))
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                // Attached entities as small labels
                if !attachments.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(attachments) { attachment in
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.entityIcon(for: attachment.entityType))
                                    .font(.system(size: 10))
                                Text(viewModel.entityDisplayName(for: attachment))
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundColor(viewModel.entityColor(for: attachment.entityType))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(viewModel.entityColor(for: attachment.entityType).opacity(0.12))
                            .cornerRadius(6)
                        }
                    }
                }

                // Details button
                Button {
                    showDetailView = true
                } label: {
                    Text(L("open.details"))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .accessibilityLabel(L("open.details"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(10)

            Color.clear.frame(height: 36)
        }
        .background(timelineLine)
        .sheet(isPresented: $showDetailView) {
            RoadmapStopDetailView(
                stop: stop,
                attachments: attachments,
                outgoingTransport: outgoingTransport,
                viewModel: viewModel
            )
        }
    }

    // MARK: - Timeline Line

    private var timelineLine: some View {
        GeometryReader { geo in
            let midY = geo.size.height / 2
            let centerX = geo.size.width / 2

            Path { path in
                if isFirst {
                    path.move(to: CGPoint(x: centerX, y: midY))
                    path.addLine(to: CGPoint(x: centerX, y: geo.size.height))
                } else if isLast {
                    path.move(to: CGPoint(x: centerX, y: 0))
                    path.addLine(to: CGPoint(x: centerX, y: midY))
                } else {
                    path.move(to: CGPoint(x: centerX, y: 0))
                    path.addLine(to: CGPoint(x: centerX, y: geo.size.height))
                }
            }
            .stroke(
                Color.orange.opacity(0.3),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
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

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        totalHeight = y + rowHeight

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
