import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Entry point for the Share Extension.
/// Handles extracting shared content (files, text, URLs) and presenting the SwiftUI interface.
class ShareViewController: UIViewController {

    private var extractedContent: SharedContentType?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        extractSharedContent()
    }

    private func extractSharedContent() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            close(withError: "No items to share")
            return
        }

        let group = DispatchGroup()

        var extractedURLs: [URL] = []      // File URLs
        var extractedText: String?          // Plain text
        var extractedWebURL: URL?           // Web URL
        var extractedWebTitle: String?      // Web page title

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            // Try to get attributed content text (for URL sharing with title)
            if let attributedText = item.attributedContentText {
                extractedWebTitle = attributedText.string
            }

            for provider in attachments {

                // 1. Try to extract URL first
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, error in
                        defer { group.leave() }
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                extractedWebURL = url
                            }
                        }
                    }
                }

                // 2. Try to extract plain text
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    group.enter()
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                        defer { group.leave() }
                        if let text = item as? String {
                            DispatchQueue.main.async {
                                extractedText = text
                            }
                        }
                    }
                }

                // 3. Try to extract files (PDFs, images)
                let fileTypes = [
                    UTType.pdf.identifier,
                    UTType.image.identifier,
                    UTType.jpeg.identifier,
                    UTType.png.identifier,
                    UTType.heic.identifier
                ]

                for typeIdentifier in fileTypes {
                    if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                        group.enter()
                        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                            defer { group.leave() }

                            guard let url = url else { return }

                            // Copy to temp location (provider's URL is temporary)
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)

                            do {
                                try FileManager.default.copyItem(at: url, to: tempURL)
                                DispatchQueue.main.async {
                                    extractedURLs.append(tempURL)
                                }
                            } catch {
                                print("Failed to copy file: \(error)")
                            }
                        }
                        break // Found a matching type, move to next attachment
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // Determine content type based on what was extracted
            let contentType: SharedContentType

            if !extractedURLs.isEmpty {
                // Files take priority
                contentType = .files(extractedURLs)
            } else if let webURL = extractedWebURL {
                // Web URL
                if let text = extractedText, !text.isEmpty, text != webURL.absoluteString {
                    contentType = .urlWithText(webURL, text)
                } else {
                    contentType = .url(webURL, title: extractedWebTitle)
                }
            } else if let text = extractedText, !text.isEmpty {
                // Plain text
                contentType = .text(text)
            } else {
                self.close(withError: "No supported content found")
                return
            }

            self.extractedContent = contentType
            self.presentShareUI(with: contentType)
        }
    }

    private func presentShareUI(with contentType: SharedContentType) {
        let viewModel = ShareViewModel(
            contentType: contentType,
            onComplete: { [weak self] success in
                if success {
                    self?.extensionContext?.completeRequest(returningItems: nil)
                } else {
                    self?.close(withError: "Failed to save")
                }
            },
            onCancel: { [weak self] in
                self?.cleanupTempFiles()
                self?.extensionContext?.cancelRequest(withError: NSError(
                    domain: "ShareExtension",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
                ))
            }
        )

        let shareView = ShareView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: shareView)

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    private func close(withError message: String) {
        cleanupTempFiles()
        extensionContext?.cancelRequest(withError: NSError(
            domain: "ShareExtension",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        ))
    }

    private func cleanupTempFiles() {
        if case .files(let urls) = extractedContent {
            for url in urls {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
