import SwiftUI

struct WardrobeItem: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let color: Color
    let brand: String?
}

