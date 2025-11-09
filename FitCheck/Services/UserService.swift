//
//  UserService.swift
//  FitCheck
//
//  Created by Ellie Winter on 11/9/25.
//

import Foundation

final class UserService {
    static let shared = UserService()
    private init() {}

    private let usersKey = "users"
    private let currentUserKey = "currentUser"

    // MARK: - Load & Save Users
    private func loadUsers() -> [String: User] {
        guard
            let data = UserDefaults.standard.data(forKey: usersKey),
            let decoded = try? JSONDecoder().decode([String: User].self, from: data)
        else { return [:] }
        return decoded
    }

    private func saveUsers(_ dict: [String: User]) {
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
    }

    // MARK: - Public Properties
    var users: [String: User] {
        get { loadUsers() }
        set { saveUsers(newValue) }
    }

    var currentUser: User? {
        get {
            guard let username = UserDefaults.standard.string(forKey: currentUserKey) else { return nil }
            return loadUsers()[username.lowercased()]
        }
        set {
            if let user = newValue {
                UserDefaults.standard.set(user.username.lowercased(), forKey: currentUserKey)
            } else {
                UserDefaults.standard.removeObject(forKey: currentUserKey)
            }
        }
    }

    // MARK: - Auth Methods
    func login(username: String) {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = trimmed.lowercased()
        var all = loadUsers()

        if all[key] == nil {
            let newUser = User(
                id: UUID().uuidString,
                displayName: trimmed,
                username: trimmed,
                avatarURL: nil,
                streakCount: 0,
                friends: []
            )
            all[key] = newUser
            saveUsers(all)
        }

        currentUser = all[key]
    }

    func logout() {
        currentUser = nil
    }

    // MARK: - Example User Actions
    func incrementStreak() {
        guard var user = currentUser else { return }
        user.streakCount += 1

        var all = loadUsers()
        all[user.username.lowercased()] = user
        saveUsers(all)
        currentUser = user
    }

    func addFriend(_ friendUsername: String) {
        guard var user = currentUser else { return }
        if !user.friends.contains(friendUsername) {
            user.friends.append(friendUsername)
        }

        var all = loadUsers()
        all[user.username.lowercased()] = user
        saveUsers(all)
        currentUser = user
    }
}

