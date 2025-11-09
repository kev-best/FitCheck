//
//  UserLoginView.swift
//  FitCheck
//
//  Created by Ellie Winter on 11/9/25.
//

import SwiftUI

struct UserLoginView: View {
    @State private var username = ""
    @AppStorage("currentUser") private var currentUser: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome To FitCheck!")
            
            TextField("Enter username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            Button("Login") {
                UserService.shared.login(username: username)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    UserLoginView()
}

