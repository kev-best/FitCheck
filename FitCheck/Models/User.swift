import Foundation

struct User: Identifiable, Hashable {
    let id: String
    var displayName: String
    var username: String
    var avatarURL: URL?
    var streakCount: Int
    var friends: [String]
}

