import SwiftUI

struct RoadmapConnectionView: View {

    let stopId: UUID
    let currentTransportId: UUID?
    let viewModel: RoadmapTimelineViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedTransportId: UUID?

    var body: some View {
        NavigationStack {
            List {
                // None option
                Button {
                    selectedTransportId = nil
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                            .frame(width: 24)

                        Text(L("roadmap.no_transport"))
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedTransportId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                }

                // Available transports
                let transports = viewModel.journeyTransports()
                ForEach(transports) { transport in
                    Button {
                        selectedTransportId = transport.id
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: transport.type.iconName)
                                .foregroundColor(transport.type.color)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(transport.departureLocation) → \(transport.arrivalLocation)")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Text(formatDate(transport.departureDate))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if selectedTransportId == transport.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("roadmap.set_transport"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        viewModel.setOutgoingTransport(stopId: stopId, transportId: selectedTransportId)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedTransportId = currentTransportId
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }
}
