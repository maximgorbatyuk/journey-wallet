import SwiftUI

/// A compact action button with a large icon and small caption below.
/// Designed for use in horizontal action bars.
struct CompactActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

/// A horizontal container for compact action buttons with a card-style background.
struct CompactActionBar<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        CompactActionBar {
            CompactActionButton(
                icon: "checkmark.circle.fill",
                label: "Done",
                color: .green
            ) {}

            CompactActionButton(
                icon: "link",
                label: "Open",
                color: .blue
            ) {}

            CompactActionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                color: .orange
            ) {}
        }
        .padding()
    }
    .background(Color(.systemGray6))
}
