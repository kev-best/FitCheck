//
//  NewPostPayload.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation
import UIKit

struct NewPostPayload {
    let frontImage: Data
    let backImage: Data
    let tags: [String]
    let createdAt: Date
    let isLate: Bool
}

// MARK: - Protocol
protocol PostServicing {
    func uploadPost(_ payload: NewPostPayload, for user: User) async throws -> Post
    func fetchFeed(for userId: String) async throws -> [Post]
    func react(to postId: String, emoji: String) async throws
    func comment(on postId: String, text: String) async throws
}

// MARK: - Mock
final class MockPostService: PostServicing {
    func uploadPost(_ payload: NewPostPayload, for user: User) async throws -> Post {
        // Returns a local mock post; replace with Firebase/CloudKit later
        return Post(
            id: UUID().uuidString,
            user: user,
            createdAt: payload.createdAt,
            isLate: payload.isLate,
            frontImageName: "front1",
            backImageName: "back1",
            tags: payload.tags,
            palette: [.black, .white, .gray],
            reactions: [],
            comments: []
        )
    }

    func fetchFeed(for userId: String) async throws -> [Post] {
        return MockData.sampleFeed
    }

    func react(to postId: String, emoji: String) async throws { /* no-op */ }
    func comment(on postId: String, text: String) async throws { /* no-op */ }
}
