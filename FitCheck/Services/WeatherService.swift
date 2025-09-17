//
//  WeatherBrief.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation

// MARK: - Protocol
struct WeatherBrief {
    let temperatureC: Double
    let condition: String
}

protocol WeatherServicing {
    func fetchBrief(latitude: Double, longitude: Double) async throws -> WeatherBrief
}

// MARK: - Mock
final class MockWeatherService: WeatherServicing {
    func fetchBrief(latitude: Double, longitude: Double) async throws -> WeatherBrief {
        return WeatherBrief(temperatureC: 18.0, condition: "Cloudy")
    }
}
