import SwiftUI

struct AppImageBackground: SwiftUI.View {
    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUI.View {
        Image(colorScheme == .dark ? "logo-pattern-white" : "logo-pattern-black" )
            .resizable()
            .scaledToFill()
            .opacity(0.05)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}
