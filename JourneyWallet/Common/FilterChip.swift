import SwiftUI

/// A reusable filter chip component for filtering lists
struct FilterChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack(spacing: 8) {
        FilterChip(title: "All", isSelected: true) {}
        FilterChip(title: "Active", isSelected: false) {}
        FilterChip(title: "Upcoming", isSelected: false) {}
    }
    .padding()
}
