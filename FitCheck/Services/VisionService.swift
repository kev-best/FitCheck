//
//  VisionServicing.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation
import UIKit

// MARK: - Protocol
protocol VisionServicing {
    func blurFaces(in image: UIImage) async throws -> UIImage
    func blurBackground(in image: UIImage) async throws -> UIImage
    func extractPalette(from image: UIImage, maxColors: Int) async throws -> [UIColor]
}

// MARK: - Mock
final class MockVisionService: VisionServicing {
    func blurFaces(in image: UIImage) async throws -> UIImage { image }
    func blurBackground(in image: UIImage) async throws -> UIImage { image }
    func extractPalette(from image: UIImage, maxColors: Int) async throws -> [UIColor] { [.black, .white] }
}
