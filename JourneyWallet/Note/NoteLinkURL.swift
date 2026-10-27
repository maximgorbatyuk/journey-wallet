import Foundation

enum NoteLinkURL {
    static func normalized(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let hasScheme = trimmed.range(of: #"^[A-Za-z][A-Za-z0-9+.-]*:"#, options: .regularExpression) != nil
        let address = hasScheme ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: address),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host,
              !host.isEmpty,
              host.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
        else {
            return nil
        }
        return components.url
    }
}
