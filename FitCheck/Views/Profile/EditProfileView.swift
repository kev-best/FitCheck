//
//  EditProfileView.swift
//  FitCheck
//
//  Created by csuftitan on 9/17/25.
//


import SwiftUI

struct EditProfileView: View {
    var body: some View {
        Form {
            Section("Profile") {
                TextField("Display name", text: .constant("Alex Chen"))
                TextField("Username", text: .constant("alexc"))
            }
        }
        .navigationTitle("Edit Profile")
    }
}
