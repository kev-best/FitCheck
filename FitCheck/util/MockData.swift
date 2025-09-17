import SwiftUI

enum MockData {
    static let user = User(
        id: "me",
        displayName: "Alex Chen",
        username: "alexc",
        avatarURL: nil,
        streakCount: 3,
        friends: ["u1", "u2", "u3"]
    )

    static let sampleFeed: [Post] = {
        let u1 = User(id: "u1", displayName: "Maya Singh", username: "mayas", avatarURL: nil, streakCount: 12, friends: [])
        let u2 = User(id: "u2", displayName: "Diego Ramos", username: "diego", avatarURL: nil, streakCount: 7, friends: [])
        let u3 = User(id: "u3", displayName: "Jules Park", username: "jules", avatarURL: nil, streakCount: 21, friends: [])

        return [
            Post(
                id: "p1",
                user: u1,
                createdAt: .now.addingTimeInterval(-3600),
                isLate: false,
                frontImageName: "front1",
                backImageName: "back1",
                tags: ["Jacket", "Sneakers", "Monochrome"],
                palette: [.black, .gray, .white],
                reactions: [
                    .init(id: "r1", user: u2, emoji: "🔥"),
                    .init(id: "r2", user: u3, emoji: "🖤")
                ],
                comments: [
                    .init(id: "c1", user: u2, text: "Clean lines!", createdAt: .now.addingTimeInterval(-2000))
                ]
            ),
            Post(
                id: "p2",
                user: u2,
                createdAt: .now.addingTimeInterval(-7200),
                isLate: true,
                frontImageName: "front2",
                backImageName: "back2",
                tags: ["Denim", "Boots"],
                palette: [.blue, .brown, .white],
                reactions: [
                    .init(id: "r3", user: u1, emoji: "🤝")
                ],
                comments: []
            )
        ]
    }()

    static let sampleWardrobe: [WardrobeItem] = [
        .init(id: "w1", name: "Oversized Blazer", category: "Jackets", color: .black, brand: "COS"),
        .init(id: "w2", name: "Raw Denim", category: "Pants", color: .blue, brand: "A.P.C."),
        .init(id: "w3", name: "White Tee", category: "Tops", color: .white, brand: "Uniqlo"),
        .init(id: "w4", name: "Chelsea Boots", category: "Shoes", color: .brown, brand: "Common Projects")
    ]
}
