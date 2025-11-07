import Foundation
import CoreLocation
import MapKit

// MARK: - Google Maps API Service
protocol LocationServicing {
    func findNearbyStores(for brand: Brand, near location: CLLocation) async throws -> [StoreLocation]
    func getDirections(to store: StoreLocation, from location: CLLocation) async throws -> MKDirections.Response
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D
}

class GoogleMapsService: LocationServicing {
    private let apiKey: String
    private let session = URLSession.shared
    
    // Base URLs for Google APIs
    private let placesBaseURL = "https://maps.googleapis.com/maps/api/place"
    private let geocodingBaseURL = "https://maps.googleapis.com/maps/api/geocoding"
    private let directionsBaseURL = "https://maps.googleapis.com/maps/api/directions"
    
    init(apiKey: String = "YOUR_GOOGLE_MAPS_API_KEY") {
        self.apiKey = apiKey
    }
    
    // MARK: - Find Nearby Stores
    func findNearbyStores(for brand: Brand, near location: CLLocation) async throws -> [StoreLocation] {
        let searchQuery = "\(brand.name) store"
        let radius = 10000 // 10km radius
        
        let urlString = "\(placesBaseURL)/nearbysearch/json"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
            URLQueryItem(name: "radius", value: String(radius)),
            URLQueryItem(name: "keyword", value: searchQuery),
            URLQueryItem(name: "type", value: "clothing_store"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw LocationError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
        
        return response.results.map { place in
            StoreLocation(
                id: place.placeId,
                brand: brand,
                name: place.name,
                address: place.vicinity ?? "Address not available",
                coordinate: CLLocationCoordinate2D(
                    latitude: place.geometry.location.lat,
                    longitude: place.geometry.location.lng
                ),
                distance: location.distance(from: CLLocation(
                    latitude: place.geometry.location.lat,
                    longitude: place.geometry.location.lng
                )),
                phoneNumber: nil,
                hours: place.openingHours?.weekdayText?.joined(separator: "\n"),
                storeType: determineStoreType(from: place.types)
            )
        }
    }
    
    // MARK: - Get Directions
    func getDirections(to store: StoreLocation, from location: CLLocation) async throws -> MKDirections.Response {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        return try await directions.calculate()
    }
    
    // MARK: - Geocode Address
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let urlString = "\(geocodingBaseURL)/json"
        var components = URLComponents(string: urlString)!
        components.queryItems = [
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            throw LocationError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        
        guard let result = response.results.first else {
            throw LocationError.noResults
        }
        
        return CLLocationCoordinate2D(
            latitude: result.geometry.location.lat,
            longitude: result.geometry.location.lng
        )
    }
    
    // MARK: - Helper Methods
    private func determineStoreType(from types: [String]?) -> StoreLocation.StoreType {
        guard let types = types else { return .boutique }
        
        if types.contains("department_store") {
            return .department
        } else if types.contains("shopping_mall") {
            return .department
        } else {
            return .boutique
        }
    }
}

// MARK: - Response Models
private struct PlacesResponse: Decodable {
    let results: [Place]
    let status: String
    let nextPageToken: String?
    
    struct Place: Decodable {
        let placeId: String
        let name: String
        let vicinity: String?
        let geometry: Geometry
        let types: [String]?
        let openingHours: OpeningHours?
        
        private enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case name
            case vicinity
            case geometry
            case types
            case openingHours = "opening_hours"
        }
    }
    
    struct Geometry: Decodable {
        let location: Location
    }
    
    struct Location: Decodable {
        let lat: Double
        let lng: Double
    }
    
    struct OpeningHours: Decodable {
        let openNow: Bool?
        let weekdayText: [String]?
        
        private enum CodingKeys: String, CodingKey {
            case openNow = "open_now"
            case weekdayText = "weekday_text"
        }
    }
}

private struct GeocodingResponse: Decodable {
    let results: [GeocodingResult]
    let status: String
    
    struct GeocodingResult: Decodable {
        let geometry: Geometry
    }
    
    struct Geometry: Decodable {
        let location: Location
    }
    
    struct Location: Decodable {
        let lat: Double
        let lng: Double
    }
}

// MARK: - Location Error
enum LocationError: LocalizedError {
    case invalidURL
    case noResults
    case apiKeyMissing
    case quotaExceeded
    case invalidRequest
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for API request"
        case .noResults:
            return "No results found for your search"
        case .apiKeyMissing:
            return "Google Maps API key is missing"
        case .quotaExceeded:
            return "API quota exceeded. Please try again later"
        case .invalidRequest:
            return "Invalid request to Google Maps API"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Mock Location Service
class MockLocationService: LocationServicing {
    func findNearbyStores(for brand: Brand, near location: CLLocation) async throws -> [StoreLocation] {
        // Return mock store locations for testing
        return [
            StoreLocation(
                id: "store1",
                brand: brand,
                name: "\(brand.name) - Downtown",
                address: "123 Main St, New York, NY 10001",
                coordinate: CLLocationCoordinate2D(latitude: 40.7484, longitude: -73.9857),
                distance: 1200,
                phoneNumber: "+1 212-555-0100",
                hours: "Mon-Sat: 10AM-9PM\nSun: 11AM-7PM",
                storeType: .flagship
            ),
            StoreLocation(
                id: "store2",
                brand: brand,
                name: "\(brand.name) - Mall Location",
                address: "456 Shopping Plaza, New York, NY 10002",
                coordinate: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
                distance: 2500,
                phoneNumber: "+1 212-555-0200",
                hours: "Daily: 10AM-10PM",
                storeType: .department
            ),
            StoreLocation(
                id: "store3",
                brand: brand,
                name: "\(brand.name) Outlet",
                address: "789 Outlet Way, Brooklyn, NY 11201",
                coordinate: CLLocationCoordinate2D(latitude: 40.6782, longitude: -73.9442),
                distance: 5800,
                phoneNumber: "+1 718-555-0300",
                hours: "Mon-Fri: 9AM-9PM\nSat-Sun: 9AM-10PM",
                storeType: .outlet
            )
        ]
    }
    
    func getDirections(to store: StoreLocation, from location: CLLocation) async throws -> MKDirections.Response {
        // For mock, we'll need to use actual MapKit directions
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinate))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        return try await directions.calculate()
    }
    
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        // Return a mock coordinate for testing
        return CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    }
}
