//
//  PostDetailView.swift
//  FitCheck
//
//  Created by csuftitan on 9/17/25.
//


import SwiftUI

struct PostDetailView: View {
    let postId: String
    var body: some View {
        VStack(spacing: 12) {
            Text("Post \(postId)").font(.title2.bold())
            Text("TODO: load post details and comments.")
        }
        .padding()
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }
}
