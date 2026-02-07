import SwiftUI

struct RoadmapStopDetailView: View {

    let stop: RoadmapStop
    let attachments: [RoadmapStopAttachment]
    let outgoingTransport: Transport?
    let viewModel: RoadmapTimelineViewModel
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var analytics = AnalyticsService.shared

    @State private var showEditSheet: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showAttachmentPicker: Bool = false
    @State private var showConnectionPicker: Bool = false
    @State private var attachmentToDetach: RoadmapStopAttachment?

    private var isPast: Bool {
        if let departureDate = stop.departureDate {
            return departureDate < Date()
        }
        if let arrivalDate = stop.arrivalDate {
            return arrivalDate < Date()
        }
        return false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection

                    if stop.arrivalDate != nil || stop.departureDate != nil {
                        datesCard
                    }

                    if !attachments.isEmpty {
                        attachmentsCard
                    }

                    transportCard

                    if let notes = stop.notes, !notes.isEmpty {
                        notesCard(notes: notes)
                    }

                    actionsSection
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationTitle(L("roadmap.detail.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Close")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label(L("roadmap.edit_stop"), systemImage: "pencil")
                        }

                        Button {
                            showAttachmentPicker = true
                        } label: {
                            Label(L("roadmap.attach_items"), systemImage: "paperclip")
                        }

                        Button {
                            showConnectionPicker = true
                        } label: {
                            Label(L("roadmap.set_transport"), systemImage: "arrow.right")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(L("Delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                analytics.trackScreen("roadmap_stop_detail_screen")
            }
            .sheet(isPresented: $showEditSheet) {
                RoadmapStopFormView(
                    journeyId: stop.journeyId,
                    mode: .edit(stop),
                    nextSortOrder: stop.sortOrder
                ) { updatedStop in
                    viewModel.updateStop(updatedStop)
                }
            }
            .sheet(isPresented: $showAttachmentPicker) {
                RoadmapAttachmentPicker(stopId: stop.id, viewModel: viewModel)
            }
            .sheet(isPresented: $showConnectionPicker) {
                RoadmapConnectionView(
                    stopId: stop.id,
                    currentTransportId: stop.outgoingTransportId,
                    viewModel: viewModel
                )
            }
            .alert(L("roadmap.stop.delete_confirm.title"), isPresented: $showDeleteConfirmation) {
                Button(L("Cancel"), role: .cancel) {}
                Button(L("Delete"), role: .destructive) {
                    viewModel.deleteStop(id: stop.id)
                    onDelete()
                    dismiss()
                }
            } message: {
                Text(L("roadmap.stop.delete_confirm.message"))
            }
            .alert(
                L("roadmap.detach.confirm.title"),
                isPresented: Binding(
                    get: { attachmentToDetach != nil },
                    set: { if !$0 { attachmentToDetach = nil } }
                )
            ) {
                Button(L("Cancel"), role: .cancel) {
                    attachmentToDetach = nil
                }
                Button(L("roadmap.detach"), role: .destructive) {
                    if let attachment = attachmentToDetach {
                        viewModel.removeAttachment(id: attachment.id)
                    }
                    attachmentToDetach = nil
                }
            } message: {
                Text(L("roadmap.detach.confirm.message"))
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isPast ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(isPast ? .orange : .blue)
            }

            Text(stop.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if let subtitle = stop.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if stop.arrivalDate != nil || stop.departureDate != nil {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.orange)

                    if let arrival = stop.arrivalDate {
                        Text(formatDateTime(arrival))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if stop.arrivalDate != nil && stop.departureDate != nil {
                        Text("–")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let departure = stop.departureDate {
                        Text(formatDateTime(departure))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }

    // MARK: - Dates Card

    private var datesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.orange)
                Text(L("roadmap.detail.dates"))
                    .font(.headline)
            }

            if let arrival = stop.arrivalDate {
                HStack {
                    Text(L("roadmap.detail.arrival"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDateTime(arrival))
                        .font(.subheadline)
                }
            }

            if let departure = stop.departureDate {
                HStack {
                    Text(L("roadmap.detail.departure"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDateTime(departure))
                        .font(.subheadline)
                }
            }

            if let arrival = stop.arrivalDate, let departure = stop.departureDate {
                HStack {
                    Spacer()
                    Text(formatDuration(from: arrival, to: departure))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Attachments Card

    private var attachmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paperclip")
                    .foregroundColor(.orange)
                Text(L("roadmap.detail.attachments"))
                    .font(.headline)
            }

            ForEach(attachments) { attachment in
                HStack(spacing: 8) {
                    Image(systemName: viewModel.entityIcon(for: attachment.entityType))
                        .font(.subheadline)
                        .foregroundColor(viewModel.entityColor(for: attachment.entityType))
                        .frame(width: 24)

                    Text(viewModel.entityDisplayName(for: attachment))
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        attachmentToDetach = attachment
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Transport Card

    private var transportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.orange)
                Text(L("roadmap.detail.transport_to_next"))
                    .font(.headline)
            }

            if let transport = outgoingTransport {
                HStack(spacing: 8) {
                    Image(systemName: transport.type.iconName)
                        .foregroundColor(transport.type.color)
                        .frame(width: 24)

                    Text("\(transport.departureLocation) → \(transport.arrivalLocation)")
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text(L("roadmap.no_transport"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                Text(L("roadmap.stop.notes"))
                    .font(.headline)
            }

            Text(notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.bottom, 12)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        CompactActionBar {
            CompactActionButton(
                icon: "pencil",
                label: L("Edit"),
                color: .blue
            ) {
                showEditSheet = true
            }

            CompactActionButton(
                icon: "paperclip",
                label: L("roadmap.attach_items"),
                color: .orange
            ) {
                showAttachmentPicker = true
            }

            CompactActionButton(
                icon: "arrow.right",
                label: L("roadmap.set_transport"),
                color: .green
            ) {
                showConnectionPicker = true
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func formatDateTime(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let days = hours / 24
        let remainingHours = hours % 24

        if days > 0 && remainingHours > 0 {
            return "\(days)d \(remainingHours)h"
        } else if days > 0 {
            return "\(days)d"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(interval) / 60
            return "\(max(minutes, 1))m"
        }
    }
}
