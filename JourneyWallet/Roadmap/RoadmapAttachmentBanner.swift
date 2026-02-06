import SwiftUI

struct RoadmapAttachmentBanner: View {

    let stopTitle: String
    let onDetach: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "map.fill")
                .font(.caption)
                .foregroundColor(.orange)

            Text(L("roadmap.attached_to"))
                .font(.caption)
                .foregroundColor(.secondary)

            Text(stopTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            Button {
                onDetach()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

#Preview {
    RoadmapAttachmentBanner(
        stopTitle: "Paris",
        onDetach: {}
    )
    .padding()
}
