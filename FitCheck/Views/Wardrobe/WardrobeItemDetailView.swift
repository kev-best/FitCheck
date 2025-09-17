//
//  WardrobeItemDetailView.swift
//  FitCheck
//
//  Created by csuftitan on 9/17/25.
//


import SwiftUI

struct WardrobeItemDetailView: View {
    let itemId: String
    var body: some View {
        VStack(spacing: 12) {
            Text("Wardrobe Item \(itemId)").font(.title2.bold())
            Text("TODO: item photos, tags, wear stats.")
        }
        .padding()
        .navigationTitle("Item")
        .navigationBarTitleDisplayMode(.inline)
    }
}
