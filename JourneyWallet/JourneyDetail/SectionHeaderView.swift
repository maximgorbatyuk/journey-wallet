import SwiftUI

/// Reusable section header component for journey detail sections
struct SectionHeaderView: View {
    let title: String
    let iconName: String
    let iconColor: Color
    let itemCount: Int
    let badgeText: String?
    let onSeeAll: (() -> Void)?

    init(
        title: String,
        iconName: String,
        iconColor: Color = .orange,
        itemCount: Int = 0,
        badgeText: String? = nil,
        onSeeAll: (() -> Void)? = nil
    ) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.itemCount = itemCount
        self.badgeText = badgeText
        self.onSeeAll = onSeeAll
    }

    var body: some View {
        HStack {
            // Icon and title
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                // Item count badge or custom badge text
                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(iconColor)
                        .clipShape(Capsule())
                } else if itemCount > 0 {
                    Text("\(itemCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(iconColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            // See all button
            if let onSeeAll = onSeeAll, (itemCount > 0 || badgeText != nil) {
                Button(action: onSeeAll) {
                    HStack(spacing: 4) {
                        Text(L("journey.detail.see_all"))
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    VStack(spacing: 0) {
        SectionHeaderView(
            title: "Transport",
            iconName: "airplane",
            iconColor: .blue,
            itemCount: 5,
            onSeeAll: {}
        )

        Divider()

        SectionHeaderView(
            title: "Hotels",
            iconName: "building.2",
            iconColor: .purple,
            itemCount: 2,
            onSeeAll: {}
        )

        Divider()

        SectionHeaderView(
            title: "Documents",
            iconName: "doc.fill",
            iconColor: .orange,
            itemCount: 0,
            onSeeAll: nil
        )
    }
    .background(Color(.systemBackground))
}
