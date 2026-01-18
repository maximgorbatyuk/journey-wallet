import SwiftUI

// MARK: - Error State View

struct ErrorStateView: View {
    let title: String
    let message: String
    var retryTitle: String? = nil
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryTitle = retryTitle, let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(retryTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Error Type

enum ErrorType {
    case network
    case database
    case permission
    case notFound
    case generic

    var icon: String {
        switch self {
        case .network: return "wifi.exclamationmark"
        case .database: return "externaldrive.badge.exclamationmark"
        case .permission: return "lock.shield"
        case .notFound: return "questionmark.folder"
        case .generic: return "exclamationmark.triangle.fill"
        }
    }

    var title: String {
        switch self {
        case .network: return L("error.network.title")
        case .database: return L("error.database.title")
        case .permission: return L("error.permission.title")
        case .notFound: return L("error.not_found.title")
        case .generic: return L("error.generic.title")
        }
    }

    var message: String {
        switch self {
        case .network: return L("error.network.message")
        case .database: return L("error.database.message")
        case .permission: return L("error.permission.message")
        case .notFound: return L("error.not_found.message")
        case .generic: return L("error.generic.message")
        }
    }
}

// MARK: - Typed Error State View

struct TypedErrorStateView: View {
    let type: ErrorType
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: type.icon)
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text(type.title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(type.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text(L("Retry"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Inline Error View

struct InlineErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: String?
    var retryAction: (() -> Void)?

    var body: some View {
        content
            .alert(L("Error"), isPresented: .constant(error != nil)) {
                Button(L("OK")) {
                    error = nil
                }
                if let retryAction = retryAction {
                    Button(L("Retry")) {
                        error = nil
                        retryAction()
                    }
                }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        EmptyView()
    }
}

extension View {
    func errorAlert(_ error: Binding<String?>, retryAction: (() -> Void)? = nil) -> some View {
        self.alert(L("Error"), isPresented: .constant(error.wrappedValue != nil)) {
            Button(L("OK")) {
                error.wrappedValue = nil
            }
            if let retryAction = retryAction {
                Button(L("Retry")) {
                    error.wrappedValue = nil
                    retryAction()
                }
            }
        } message: {
            if let errorMessage = error.wrappedValue {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Toast Error View

struct ToastErrorView: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()

            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Error State") {
    ErrorStateView(
        title: "Something went wrong",
        message: "We couldn't load your journeys. Please try again.",
        retryTitle: "Try Again",
        retryAction: {}
    )
}

#Preview("Typed Error - Network") {
    TypedErrorStateView(type: .network, retryAction: {})
}

#Preview("Typed Error - Database") {
    TypedErrorStateView(type: .database, retryAction: {})
}

#Preview("Inline Error") {
    InlineErrorView(
        message: "Failed to save changes",
        retryAction: {}
    )
    .padding()
}

#Preview("Toast Error") {
    VStack {
        Spacer()
        ToastErrorView(
            message: "Network connection lost",
            onDismiss: {}
        )
    }
}
