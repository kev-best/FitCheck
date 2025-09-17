import SwiftUI

struct Post: Identifiable, Hashable {
    let id: String
    let user: User
    let createdAt: Date
    let isLate: Bool
    let frontImageName: String
    let backImageName: String
    let tags: [String]
    let palette: [Color]
    let reactions: [Reaction]
    let comments: [Comment]

    struct Reaction: Identifiable, Hashable {
        let id: String
        let user: User
        let emoji: String
    }

    struct Comment: Identifiable, Hashable {
        let id: String
        let user: User
        let text: String
        let createdAt: Date
    }
}

