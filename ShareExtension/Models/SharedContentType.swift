import Foundation

/// Represents the type of content shared to the extension.
enum SharedContentType {
    /// One or more files (PDFs, images, etc.)
    case files([URL])

    /// Plain text content
    case text(String)

    /// A URL with optional title
    case url(URL, title: String?)

    /// A URL along with additional text
    case urlWithText(URL, String)

    var isTextBased: Bool {
        switch self {
        case .files:
            return false
        case .text, .url, .urlWithText:
            return true
        }
    }

    var displayText: String {
        switch self {
        case .files(let urls):
            return urls.map { $0.lastPathComponent }.joined(separator: ", ")
        case .text(let text):
            return text
        case .url(let url, _):
            return url.absoluteString
        case .urlWithText(let url, let text):
            return "\(text)\n\(url.absoluteString)"
        }
    }

    /// Extracts the URL if present
    var extractedURL: URL? {
        switch self {
        case .url(let url, _), .urlWithText(let url, _):
            return url
        case .text(let text):
            // Try to find URL in text
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
               let match = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                return URL(string: String(text[range]))
            }
            return nil
        case .files:
            return nil
        }
    }

    /// Extracts the text content
    var extractedText: String? {
        switch self {
        case .text(let text):
            return text
        case .urlWithText(_, let text):
            return text
        case .url(_, let title):
            return title
        case .files:
            return nil
        }
    }
}
