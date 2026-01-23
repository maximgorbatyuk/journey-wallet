import SwiftUI
import UIKit

/// A reusable button that copies text to the clipboard with visual feedback.
/// When tapped, the button shows an accent background for 1 second before returning to default state.
public struct CopyButton: View {
    let text: String
    var iconSize: CGFloat = 16
    var padding: CGFloat = 6
    var cornerRadius: CGFloat = 6

    @State private var isCopied = false

    public init(
        text: String,
        iconSize: CGFloat = 16,
        padding: CGFloat = 6,
        cornerRadius: CGFloat = 6
    ) {
        self.text = text
        self.iconSize = iconSize
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Button(action: copyToClipboard) {
            Image(systemName: "doc.on.doc")
                .font(.system(size: iconSize))
                .foregroundColor(isCopied ? .white : .secondary)
                .padding(padding)
                .background(isCopied ? Color.accentColor : Color.clear)
                .cornerRadius(cornerRadius)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isCopied)
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = text
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isCopied = false
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        CopyButton(text: "Hello World")
        CopyButton(text: "Custom Size", iconSize: 20, padding: 8)
    }
    .padding()
}
