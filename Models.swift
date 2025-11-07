import Foundation
import SwiftUI
import CoreLocation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: String
    var username: String
    var displayName: String
    var profileImageURL: String?
    var bio: String?
    var friends: [String]
    var followers: [String]
    var following: [String]
    var streakCount: Int
    var joinedDate: Date
    var wardrobeItems: [String] // IDs of wardrobe items
    var savedOutfits: [Outfit]
    
    init(id: String = UUID().uuidString, 
         username: String,
         displayName: String,
         profileImageURL: String? = nil,
         bio: String? = nil,
         friends: [String] = [],
         followers: [String] = [],
         following: [String] = [],
         streakCount: Int = 0,
         joinedDate: Date = Date(),
         wardrobeItems: [String] = [],
         savedOutfits: [Outfit] = []) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.friends = friends
        self.followers = followers
        self.following = following
        self.streakCount = streakCount
        self.joinedDate = joinedDate
        self.wardrobeItems = wardrobeItems
        self.savedOutfits = savedOutfits
    }
}

// MARK: - Brand Model
struct Brand: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logo: String?
    let website: String?
    let category: BrandCategory
    
    enum BrandCategory: String, Codable, CaseIterable {
        case luxury = "Luxury"
        case streetwear = "Streetwear"
        case fastFashion = "Fast Fashion"
        case athletic = "Athletic"
        case designer = "Designer"
        case vintage = "Vintage"
        case sustainable = "Sustainable"
        case other = "Other"
    }
}

// MARK: - Post Model
struct Post: Identifiable, Codable {
    let id: String
    let user: User
    let createdAt: Date
    let isLate: Bool
    var frontImageURL: String?
    var backImageURL: String?
    let frontImageName: String // For demo
    let backImageName: String // For demo
    var tags: [String]
    var brandTags: [Brand]
    var itemTags: [String] // Wardrobe item IDs
    var palette: [Color]
    var reactions: [Reaction]
    var comments: [Comment]
    var location: LocationInfo?
    var weather: WeatherInfo?
    
    struct LocationInfo: Codable {
        let latitude: Double
        let longitude: Double
        let cityName: String?
    }
    
    struct WeatherInfo: Codable {
        let temperature: Double
        let condition: String
        let humidity: Double?
        let windSpeed: Double?
    }
}

// MARK: - Reaction Model
struct Reaction: Identifiable, Codable {
    let id: String
    let userId: String
    let emoji: String
    let createdAt: Date
}

// MARK: - Comment Model
struct Comment: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let text: String
    let createdAt: Date
    var likes: [String] // User IDs who liked the comment
}

// MARK: - Wardrobe Item Model
struct WardrobeItem: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var category: ItemCategory
    var brand: Brand?
    var purchaseDate: Date?
    var price: Double?
    var color: Color
    var secondaryColors: [Color]
    var size: String?
    var tags: [String]
    var imageURL: String?
    var wearCount: Int
    var lastWorn: Date?
    var seasons: [Season]
    var occasions: [Occasion]
    
    enum ItemCategory: String, Codable, CaseIterable {
        case tops = "Tops"
        case bottoms = "Bottoms"
        case outerwear = "Outerwear"
        case shoes = "Shoes"
        case accessories = "Accessories"
        case bags = "Bags"
        case jewelry = "Jewelry"
        case hats = "Hats"
        case underwear = "Underwear"
        case other = "Other"
    }
    
    enum Season: String, Codable, CaseIterable {
        case spring = "Spring"
        case summer = "Summer"
        case fall = "Fall"
        case winter = "Winter"
        case allSeason = "All Season"
    }
    
    enum Occasion: String, Codable, CaseIterable {
        case casual = "Casual"
        case formal = "Formal"
        case business = "Business"
        case party = "Party"
        case athletic = "Athletic"
        case date = "Date"
        case travel = "Travel"
    }
}

// MARK: - Outfit Model
struct Outfit: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var items: [String] // Wardrobe item IDs
    var occasions: [WardrobeItem.Occasion]
    var seasons: [WardrobeItem.Season]
    var createdAt: Date
    var lastWorn: Date?
    var wearCount: Int
    var notes: String?
    var weatherSuitability: WeatherSuitability?
    
    struct WeatherSuitability: Codable, Hashable {
        let minTemp: Double
        let maxTemp: Double
        let rainSuitable: Bool
        let snowSuitable: Bool
    }
}

// MARK: - Store Location Model
struct StoreLocation: Identifiable {
    let id: String
    let brand: Brand
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: Double? // in meters
    let phoneNumber: String?
    let hours: String?
    let storeType: StoreType
    
    enum StoreType: String, CaseIterable {
        case flagship = "Flagship"
        case outlet = "Outlet"
        case department = "Department Store"
        case boutique = "Boutique"
        case online = "Online Only"
    }
}

// MARK: - Weather Model
struct Weather: Codable {
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let description: String
    let humidity: Double
    let windSpeed: Double
    let precipitation: Double
    let uvIndex: Int
    let visibility: Double
    let pressure: Double
    let sunrise: Date
    let sunset: Date
    let dailyForecast: [DailyWeather]
    
    struct DailyWeather: Codable {
        let date: Date
        let tempMin: Double
        let tempMax: Double
        let condition: String
        let precipitationChance: Double
    }
    
    var temperatureF: Double {
        return temperature * 9/5 + 32
    }
    
    var temperatureString: String {
        return "\(Int(temperature))°C / \(Int(temperatureF))°F"
    }
    
    func outfitRecommendation() -> String {
        switch temperature {
        case ..<0:
            return "Heavy winter coat, layers, boots"
        case 0..<10:
            return "Jacket, long pants, closed shoes"
        case 10..<20:
            return "Light jacket or sweater, comfortable layers"
        case 20..<25:
            return "T-shirt/light top, comfortable bottoms"
        case 25...:
            return "Light, breathable clothing"
        default:
            return "Dress comfortably"
        }
    }
}

// MARK: - Notification Model
struct AppNotification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let fromUserId: String?
    let fromUserName: String?
    let postId: String?
    let message: String
    let createdAt: Date
    var isRead: Bool
    
    enum NotificationType: String, Codable {
        case dailyFitCall = "Daily Fit Call"
        case reaction = "Reaction"
        case comment = "Comment"
        case follow = "Follow"
        case friendRequest = "Friend Request"
        case mention = "Mention"
        case systemUpdate = "System Update"
    }
}

// MARK: - Feed Filter Options
struct FeedFilter {
    var timeRange: TimeRange = .today
    var showFriends: Bool = true
    var showFollowing: Bool = true
    var brands: [Brand] = []
    var categories: [WardrobeItem.ItemCategory] = []
    
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
    }
}

// MARK: - Mock Data
struct MockData {
    static let sampleBrands = [
        Brand(id: "1", name: "Nike", logo: "nike-logo", website: "nike.com", category: .athletic),
        Brand(id: "2", name: "Adidas", logo: "adidas-logo", website: "adidas.com", category: .athletic),
        Brand(id: "3", name: "Zara", logo: "zara-logo", website: "zara.com", category: .fastFashion),
        Brand(id: "4", name: "Supreme", logo: "supreme-logo", website: "supremenewyork.com", category: .streetwear),
        Brand(id: "5", name: "Gucci", logo: "gucci-logo", website: "gucci.com", category: .luxury),
        Brand(id: "6", name: "Uniqlo", logo: "uniqlo-logo", website: "uniqlo.com", category: .fastFashion),
        Brand(id: "7", name: "Patagonia", logo: "patagonia-logo", website: "patagonia.com", category: .sustainable)
    ]
    
    static let sampleUser = User(
        username: "alexc",
        displayName: "Alex Chen",
        bio: "Fashion enthusiast | Sneakerhead | 📍 NYC",
        friends: ["user2", "user3"],
        followers: ["user2", "user3", "user4"],
        following: ["user2", "user5"],
        streakCount: 7
    )
    
    static let sampleWardrobe: [WardrobeItem] = [
        WardrobeItem(
            id: "w1",
            name: "Black Hoodie",
            category: .tops,
            brand: sampleBrands[3],
            price: 168,
            color: .black,
            secondaryColors: [.red],
            size: "M",
            tags: ["streetwear", "casual"],
            wearCount: 12,
            seasons: [.fall, .winter, .spring],
            occasions: [.casual]
        ),
        WardrobeItem(
            id: "w2",
            name: "Blue Jeans",
            category: .bottoms,
            brand: sampleBrands[2],
            price: 89,
            color: .blue,
            secondaryColors: [],
            size: "32",
            tags: ["denim", "casual"],
            wearCount: 25,
            seasons: [.allSeason],
            occasions: [.casual, .date]
        ),
        WardrobeItem(
            id: "w3",
            name: "Air Max 90",
            category: .shoes,
            brand: sampleBrands[0],
            price: 130,
            color: .white,
            secondaryColors: [.black, .gray],
            size: "10",
            tags: ["sneakers", "athletic"],
            wearCount: 30,
            seasons: [.allSeason],
            occasions: [.casual, .athletic]
        )
    ]
    
    static let sampleFeed: [Post] = [
        Post(
            id: "p1",
            user: sampleUser,
            createdAt: Date(),
            isLate: false,
            frontImageName: "front1",
            backImageName: "back1",
            tags: ["streetwear", "casual"],
            brandTags: [sampleBrands[3], sampleBrands[0]],
            itemTags: ["w1", "w2", "w3"],
            palette: [.black, .blue, .white],
            reactions: [],
            comments: [],
            weather: Post.WeatherInfo(temperature: 22, condition: "Sunny", humidity: 45, windSpeed: 10)
        )
    ]
}
