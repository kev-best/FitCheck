//
//  AuthServicing.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation

// MARK: - Protocol
protocol AuthServicing {
    func signInWithApple() async throws -> User
    func signOut() async throws
    var currentUser: User? { get }
}

// MARK: - Mock
final class MockAuthService: AuthServicing {
    private(set) var user: User? = MockData.user
    var currentUser: User? { user }

    func signInWithApple() async throws -> User {
        // TODO: integrate ASAuthorizationAppleID if desired
        return MockData.user
    }
    func signOut() async throws {
        user = nil
    }
}
