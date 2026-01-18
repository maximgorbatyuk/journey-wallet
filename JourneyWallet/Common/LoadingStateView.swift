import SwiftUI

// MARK: - Loading State View

struct LoadingStateView: View {
    var message: String = L("Loading")

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Shimmer Effect Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Views

struct SkeletonBox: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Skeleton Card View

struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonCircle(size: 40)

                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBox(width: 150, height: 16)
                    SkeletonBox(width: 100, height: 12)
                }

                Spacer()
            }

            SkeletonBox(height: 14)
            SkeletonBox(width: 200, height: 14)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Skeleton List View

struct SkeletonListView: View {
    var itemCount: Int = 3

    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonCardView()
            }
        }
        .padding()
    }
}

// MARK: - Skeleton Journey Card

struct SkeletonJourneyCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    SkeletonBox(width: 180, height: 20)
                    HStack(spacing: 8) {
                        SkeletonCircle(size: 16)
                        SkeletonBox(width: 100, height: 14)
                    }
                }

                Spacer()

                SkeletonBox(width: 70, height: 24, cornerRadius: 8)
            }

            HStack {
                SkeletonCircle(size: 14)
                SkeletonBox(width: 200, height: 12)
                Spacer()
                SkeletonBox(width: 50, height: 12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Skeleton Transport Card

struct SkeletonTransportCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonCircle(size: 36)

                VStack(alignment: .leading, spacing: 6) {
                    SkeletonBox(width: 120, height: 16)
                    SkeletonBox(width: 80, height: 12)
                }

                Spacer()

                SkeletonBox(width: 60, height: 14)
            }

            HStack(spacing: 8) {
                SkeletonBox(width: 100, height: 14)
                SkeletonCircle(size: 20)
                SkeletonBox(width: 100, height: 14)
            }

            SkeletonBox(width: 150, height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Skeleton Stats Card

struct SkeletonStatsCardView: View {
    var body: some View {
        VStack(spacing: 8) {
            SkeletonCircle(size: 30)
            SkeletonBox(width: 40, height: 24)
            SkeletonBox(width: 60, height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Skeleton Main View

struct SkeletonMainView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Search bar skeleton
            SkeletonBox(height: 44, cornerRadius: 10)

            // Stats section skeleton
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBox(width: 100, height: 16)

                HStack(spacing: 12) {
                    SkeletonStatsCardView()
                    SkeletonStatsCardView()
                    SkeletonStatsCardView()
                }
            }

            // Journey cards skeleton
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBox(width: 150, height: 16)

                SkeletonJourneyCardView()
                SkeletonJourneyCardView()
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Loading State") {
    LoadingStateView()
}

#Preview("Skeleton Card") {
    SkeletonCardView()
        .padding()
}

#Preview("Skeleton List") {
    SkeletonListView(itemCount: 3)
}

#Preview("Skeleton Main View") {
    SkeletonMainView()
}

#Preview("Skeleton Journey Card") {
    SkeletonJourneyCardView()
        .padding()
}

#Preview("Skeleton Transport Card") {
    SkeletonTransportCardView()
        .padding()
}
