import Foundation

final class AppState: ObservableObject {
    @Published var currentUser: User = MockData.user
    @Published var feed: [Post] = MockData.sampleFeed
    @Published var wardrobe: [WardrobeItem] = MockData.sampleWardrobe
    @Published var hasPostedToday: Bool = false
    @Published var dailyWindowActive: Bool = true // Toggle for demo
}

