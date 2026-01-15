import Foundation
import SwiftUI

struct OnboardingPageViewModelItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}
