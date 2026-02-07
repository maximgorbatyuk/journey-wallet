import SwiftUI

struct RoadmapAttachmentPicker: View {

    let stopId: UUID
    let viewModel: RoadmapTimelineViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedHotelIds: Set<UUID> = []
    @State private var selectedTransportIds: Set<UUID> = []
    @State private var selectedCarRentalIds: Set<UUID> = []
    @State private var selectedPlaceIds: Set<UUID> = []
    @State private var selectedIdeaIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                // Hotels section
                let hotels = viewModel.availableHotels()
                if !hotels.isEmpty {
                    Section(header: Text(L("tab.current_journey"))) {
                        ForEach(hotels) { hotel in
                            attachmentRow(
                                icon: "building.2.fill",
                                color: .blue,
                                title: hotel.name,
                                isSelected: selectedHotelIds.contains(hotel.id)
                            ) {
                                toggleSelection(id: hotel.id, in: &selectedHotelIds)
                            }
                        }
                    }
                }

                // Transports section
                let transports = viewModel.availableTransports()
                if !transports.isEmpty {
                    Section(header: Text(L("transport.entity_name"))) {
                        ForEach(transports) { transport in
                            attachmentRow(
                                icon: transport.type.iconName,
                                color: transport.type.color,
                                title: "\(transport.departureLocation) → \(transport.arrivalLocation)",
                                isSelected: selectedTransportIds.contains(transport.id)
                            ) {
                                toggleSelection(id: transport.id, in: &selectedTransportIds)
                            }
                        }
                    }
                }

                // Car Rentals section
                let carRentals = viewModel.availableCarRentals()
                if !carRentals.isEmpty {
                    Section(header: Text(L("car_rental.entity_name"))) {
                        ForEach(carRentals) { carRental in
                            attachmentRow(
                                icon: "car.fill",
                                color: .green,
                                title: carRental.displayName,
                                isSelected: selectedCarRentalIds.contains(carRental.id)
                            ) {
                                toggleSelection(id: carRental.id, in: &selectedCarRentalIds)
                            }
                        }
                    }
                }

                // Places section
                let places = viewModel.availablePlaces()
                if !places.isEmpty {
                    Section(header: Text(L("place.entity_name"))) {
                        ForEach(places) { place in
                            attachmentRow(
                                icon: "mappin.circle.fill",
                                color: .purple,
                                title: place.name,
                                isSelected: selectedPlaceIds.contains(place.id)
                            ) {
                                toggleSelection(id: place.id, in: &selectedPlaceIds)
                            }
                        }
                    }
                }

                // Ideas section
                let ideas = viewModel.availableIdeas()
                if !ideas.isEmpty {
                    Section(header: Text(L("idea.detail.title"))) {
                        ForEach(ideas) { idea in
                            attachmentRow(
                                icon: "lightbulb.fill",
                                color: .yellow,
                                title: idea.title,
                                isSelected: selectedIdeaIds.contains(idea.id)
                            ) {
                                toggleSelection(id: idea.id, in: &selectedIdeaIds)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L("roadmap.attach_items"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        saveAttachments()
                    }
                    .fontWeight(.semibold)
                    .disabled(totalSelected == 0)
                }
            }
        }
    }

    private var totalSelected: Int {
        selectedHotelIds.count + selectedTransportIds.count +
            selectedCarRentalIds.count + selectedPlaceIds.count + selectedIdeaIds.count
    }

    private func attachmentRow(
        icon: String,
        color: Color,
        title: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func toggleSelection(id: UUID, in set: inout Set<UUID>) {
        if set.contains(id) {
            set.remove(id)
        } else {
            set.insert(id)
        }
    }

    private func saveAttachments() {
        var attachments: [RoadmapStopAttachment] = []

        for id in selectedHotelIds {
            attachments.append(RoadmapStopAttachment(
                roadmapStopId: stopId,
                entityType: RoadmapEntityType.hotel.rawValue,
                entityId: id
            ))
        }

        for id in selectedTransportIds {
            attachments.append(RoadmapStopAttachment(
                roadmapStopId: stopId,
                entityType: RoadmapEntityType.transport.rawValue,
                entityId: id
            ))
        }

        for id in selectedCarRentalIds {
            attachments.append(RoadmapStopAttachment(
                roadmapStopId: stopId,
                entityType: RoadmapEntityType.carRental.rawValue,
                entityId: id
            ))
        }

        for id in selectedPlaceIds {
            attachments.append(RoadmapStopAttachment(
                roadmapStopId: stopId,
                entityType: RoadmapEntityType.placeToVisit.rawValue,
                entityId: id
            ))
        }

        for id in selectedIdeaIds {
            attachments.append(RoadmapStopAttachment(
                roadmapStopId: stopId,
                entityType: RoadmapEntityType.idea.rawValue,
                entityId: id
            ))
        }

        viewModel.addAttachments(attachments)
        dismiss()
    }
}
