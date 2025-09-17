//
//  PostReviewSheet.swift
//  FitCheck
//
//  Created by csuftitan on 9/17/25.
//


import SwiftUI

struct PostReviewSheet: View {
    let result: CameraCaptureResult

    var body: some View {
        VStack(spacing: 16) {
            Text("Review your Fit").font(.title2.bold())

            HStack(spacing: 12) {
                if let back = result.back {
                    Image(uiImage: back).resizable().scaledToFill()
                        .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(Text("Back").font(.caption).padding(6).background(.ultraThinMaterial, in: Capsule()).padding(6), alignment: .bottomTrailing)
                }
                if let front = result.front {
                    Image(uiImage: front).resizable().scaledToFill()
                        .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(Text("Front").font(.caption).padding(6).background(.ultraThinMaterial, in: Capsule()).padding(6), alignment: .bottomTrailing)
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                Button("Retake") {
                    // Dismiss handled by parent setting router.sheet = nil
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Post") {
                    // TODO: Call PostService.uploadPost, then dismiss.
                    // For now, just dismiss:
                    // You'll dismiss this from the presenting context by setting router.sheet = nil.
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
