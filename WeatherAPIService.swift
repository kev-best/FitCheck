import Foundation
import CoreLocation

// MARK: - Weather API Service Protocol
protocol WeatherServicing {
    func fetchCurrentWeather(for location: CLLocation) async throws -> Weather
    func fetchWeeklyForecast(for location: CLLocation) async throws -> [Weather.DailyWeather]
    func getOutfitRecommendations(for weather: Weather, from wardrobe: [WardrobeItem]) -> [WardrobeItem]
}

// MARK: - OpenWeather API Service
class OpenWeatherService: WeatherServicing {
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let session = URLSession.shared
    
    init(apiKey: String = "YOUR_OPENWEATHER_API_KEY") {
        self.apiKey = apiKey
    }
    
    // MARK: - Fetch Current Weather
    func fetchCurrentWeather(for location: CLLocation) async throws -> Weather {
        let urlString = "\(baseURL)/weather"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        
        guard let url = components.url else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(CurrentWeatherResponse.self, from: data)
        
        // Fetch forecast for daily data
        let forecast = try await fetchWeeklyForecast(for: location)
        
        return Weather(
            temperature: response.main.temp,
            feelsLike: response.main.feelsLike,
            condition: response.weather.first?.main ?? "Unknown",
            description: response.weather.first?.description ?? "",
            humidity: response.main.humidity,
            windSpeed: response.wind.speed,
            precipitation: response.rain?.oneHour ?? 0,
            uvIndex: 0, // Would need separate API call for UV index
            visibility: Double(response.visibility ?? 10000) / 1000,
            pressure: response.main.pressure,
            sunrise: Date(timeIntervalSince1970: TimeInterval(response.sys.sunrise)),
            sunset: Date(timeIntervalSince1970: TimeInterval(response.sys.sunset)),
            dailyForecast: forecast
        )
    }
    
    // MARK: - Fetch Weekly Forecast
    func fetchWeeklyForecast(for location: CLLocation) async throws -> [Weather.DailyWeather] {
        let urlString = "\(baseURL)/forecast"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "cnt", value: "40") // 5 days of 3-hour forecasts
        ]
        
        guard let url = components.url else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(ForecastResponse.self, from: data)
        
        // Group forecasts by day and extract daily min/max
        var dailyForecasts: [Weather.DailyWeather] = []
        let calendar = Calendar.current
        var groupedByDay: [Date: [ForecastResponse.Forecast]] = [:]
        
        for forecast in response.list {
            let date = Date(timeIntervalSince1970: TimeInterval(forecast.dt))
            let startOfDay = calendar.startOfDay(for: date)
            groupedByDay[startOfDay, default: []].append(forecast)
        }
        
        for (date, forecasts) in groupedByDay.sorted(by: { $0.key < $1.key }) {
            let temps = forecasts.map { $0.main.temp }
            let minTemp = temps.min() ?? 0
            let maxTemp = temps.max() ?? 0
            let condition = forecasts.first?.weather.first?.main ?? "Unknown"
            let precipChance = forecasts.compactMap { $0.pop }.max() ?? 0
            
            dailyForecasts.append(Weather.DailyWeather(
                date: date,
                tempMin: minTemp,
                tempMax: maxTemp,
                condition: condition,
                precipitationChance: precipChance
            ))
        }
        
        return Array(dailyForecasts.prefix(7)) // Return up to 7 days
    }
    
    // MARK: - Outfit Recommendations
    func getOutfitRecommendations(for weather: Weather, from wardrobe: [WardrobeItem]) -> [WardrobeItem] {
        var recommendations: [WardrobeItem] = []
        
        // Temperature-based filtering
        let temp = weather.temperature
        let isRaining = weather.condition.lowercased().contains("rain")
        let isSnowing = weather.condition.lowercased().contains("snow")
        
        // Filter by season
        let currentSeason = getCurrentSeason()
        let seasonAppropriate = wardrobe.filter { item in
            item.seasons.contains(currentSeason) || item.seasons.contains(.allSeason)
        }
        
        // Select items based on weather conditions
        for item in seasonAppropriate {
            var score = 0
            
            // Temperature scoring
            switch (item.category, temp) {
            case (.outerwear, ..<10):
                score += 10
            case (.outerwear, 10..<20):
                score += 5
            case (.tops, 15..<25):
                score += 8
            case (.tops, ..<15) where item.name.lowercased().contains("sweater") || item.name.lowercased().contains("hoodie"):
                score += 9
            case (.bottoms, ..<15) where item.name.lowercased().contains("jeans") || item.name.lowercased().contains("pants"):
                score += 8
            case (.bottoms, 20...) where item.name.lowercased().contains("shorts"):
                score += 8
            case (.shoes, _) where isRaining && item.name.lowercased().contains("boot"):
                score += 10
            case (.accessories, ..<5) where item.name.lowercased().contains("scarf") || item.name.lowercased().contains("beanie"):
                score += 7
            default:
                score += 3
            }
            
            // Weather condition scoring
            if isRaining {
                if item.name.lowercased().contains("rain") || item.name.lowercased().contains("waterproof") {
                    score += 5
                }
            }
            
            if isSnowing {
                if item.name.lowercased().contains("winter") || item.name.lowercased().contains("warm") {
                    score += 5
                }
            }
            
            // Add items with score > 5
            if score > 5 {
                recommendations.append(item)
            }
        }
        
        // Sort by relevance and limit results
        recommendations.sort { first, second in
            // Prioritize by category order: outerwear > tops > bottoms > shoes > accessories
            let categoryOrder: [WardrobeItem.ItemCategory] = [.outerwear, .tops, .bottoms, .shoes, .accessories]
            let firstIndex = categoryOrder.firstIndex(of: first.category) ?? 99
            let secondIndex = categoryOrder.firstIndex(of: second.category) ?? 99
            return firstIndex < secondIndex
        }
        
        return Array(recommendations.prefix(10))
    }
    
    // MARK: - Helper Methods
    private func getCurrentSeason() -> WardrobeItem.Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .fall
        default: return .winter
        }
    }
}

// MARK: - Response Models
private struct CurrentWeatherResponse: Decodable {
    let main: Main
    let weather: [Weather]
    let wind: Wind
    let rain: Rain?
    let visibility: Int?
    let sys: Sys
    
    struct Main: Decodable {
        let temp: Double
        let feelsLike: Double
        let humidity: Double
        let pressure: Double
        
        private enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
            case pressure
        }
    }
    
    struct Weather: Decodable {
        let main: String
        let description: String
    }
    
    struct Wind: Decodable {
        let speed: Double
    }
    
    struct Rain: Decodable {
        let oneHour: Double?
        
        private enum CodingKeys: String, CodingKey {
            case oneHour = "1h"
        }
    }
    
    struct Sys: Decodable {
        let sunrise: Int
        let sunset: Int
    }
}

private struct ForecastResponse: Decodable {
    let list: [Forecast]
    
    struct Forecast: Decodable {
        let dt: Int
        let main: Main
        let weather: [Weather]
        let pop: Double? // Probability of precipitation
        
        struct Main: Decodable {
            let temp: Double
            let tempMin: Double
            let tempMax: Double
            
            private enum CodingKeys: String, CodingKey {
                case temp
                case tempMin = "temp_min"
                case tempMax = "temp_max"
            }
        }
        
        struct Weather: Decodable {
            let main: String
            let description: String
        }
    }
}

// MARK: - Weather Error
enum WeatherError: LocalizedError {
    case invalidURL
    case apiKeyMissing
    case noData
    case decodingError
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for weather API"
        case .apiKeyMissing:
            return "Weather API key is missing"
        case .noData:
            return "No weather data available"
        case .decodingError:
            return "Failed to decode weather data"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Mock Weather Service
class MockWeatherService: WeatherServicing {
    func fetchCurrentWeather(for location: CLLocation) async throws -> Weather {
        return Weather(
            temperature: 22.5,
            feelsLike: 21.0,
            condition: "Partly Cloudy",
            description: "scattered clouds",
            humidity: 65,
            windSpeed: 12,
            precipitation: 0,
            uvIndex: 5,
            visibility: 10,
            pressure: 1013,
            sunrise: Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!,
            sunset: Calendar.current.date(bySettingHour: 19, minute: 45, second: 0, of: Date())!,
            dailyForecast: try await fetchWeeklyForecast(for: location)
        )
    }
    
    func fetchWeeklyForecast(for location: CLLocation) async throws -> [Weather.DailyWeather] {
        let calendar = Calendar.current
        var forecasts: [Weather.DailyWeather] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: Date())!
            let conditions = ["Sunny", "Cloudy", "Partly Cloudy", "Light Rain", "Clear"]
            
            forecasts.append(Weather.DailyWeather(
                date: date,
                tempMin: Double.random(in: 15...20),
                tempMax: Double.random(in: 22...28),
                condition: conditions.randomElement()!,
                precipitationChance: Double.random(in: 0...0.3)
            ))
        }
        
        return forecasts
    }
    
    func getOutfitRecommendations(for weather: Weather, from wardrobe: [WardrobeItem]) -> [WardrobeItem] {
        // Return a subset of wardrobe items as recommendations
        let suitable = wardrobe.filter { item in
            if weather.temperature < 15 {
                return item.seasons.contains(.winter) || item.seasons.contains(.fall)
            } else if weather.temperature > 25 {
                return item.seasons.contains(.summer)
            } else {
                return item.seasons.contains(.spring) || item.seasons.contains(.allSeason)
            }
        }
        
        return Array(suitable.prefix(5))
    }
}
