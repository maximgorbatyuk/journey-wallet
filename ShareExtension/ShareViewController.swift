import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Entry point for the Share Extension.
/// Handles extracting shared files and presenting the SwiftUI interface.
class ShareViewController: UIViewController {

    private var fileURLs: [URL] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        extractSharedFiles()
    }

    private func extractSharedFiles() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            close(withError: "No items to share")
            return
        }

        let group = DispatchGroup()
        var extractedURLs: [URL] = []

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // Try to load as file data
                let supportedTypes = [
                    UTType.pdf.identifier,
                    UTType.image.identifier,
                    UTType.jpeg.identifier,
                    UTType.png.identifier,
                    UTType.heic.identifier,
                    UTType.data.identifier
                ]

                for typeIdentifier in supportedTypes {
                    if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                        group.enter()
                        provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { [weak self] url, error in
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

            if extractedURLs.isEmpty {
                self.close(withError: "No supported files found")
                return
            }

            self.fileURLs = extractedURLs
            self.presentShareUI()
        }
    }

    private func presentShareUI() {
        let viewModel = ShareViewModel(
            fileURLs: fileURLs,
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
        for url in fileURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
