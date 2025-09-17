//
//  WardrobeServicing.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation
import SwiftUI

// MARK: - Protocol
protocol WardrobeServicing {
    func listItems() async throws -> [WardrobeItem]
    func addItem(_ item: WardrobeItem) async throws
    func deleteItem(id: String) async throws
}

// MARK: - Mock
final class MockWardrobeService: WardrobeServicing {
    private var items = MockData.sampleWardrobe

    func listItems() async throws -> [WardrobeItem] { items }

    func addItem(_ item: WardrobeItem) async throws { items.append(item) }

    func deleteItem(id: String) async throws { items.removeAll { $0.id == id } }
}
