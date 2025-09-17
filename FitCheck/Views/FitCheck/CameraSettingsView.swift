//
//  CameraSettingsView.swift
//  FitCheck
//
//  Created by csuftitan on 9/17/25.
//


import SwiftUI

struct CameraSettingsView: View {
    var body: some View {
        Form {
            Section("Capture") {
                Toggle("Mirror front camera", isOn: .constant(true))
                Toggle("Show grid", isOn: .constant(false))
                Toggle("Face blur (pre-upload)", isOn: .constant(false))
            }
        }
        .navigationTitle("Camera Settings")
    }
}
