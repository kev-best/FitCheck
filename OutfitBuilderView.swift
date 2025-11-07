import SwiftUI
import CoreLocation

struct OutfitBuilderView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherService = WeatherViewModel()
    
    @State private var selectedItems: [WardrobeItem] = []
    @State private var outfitName = ""
    @State private var outfitNotes = ""
    @State private var selectedOccasions: Set<WardrobeItem.Occasion> = []
    @State private var selectedSeasons: Set<WardrobeItem.Season> = []
    @State private var showingSaveSheet = false
    @State private var showingWeatherRecommendations = false
    @State private var weatherRecommendations: [WardrobeItem] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Weather Widget
                    if let weather = weatherService.currentWeather {
                        WeatherWidget(weather: weather) {
                            Task {
                                await loadWeatherRecommendations()
                                showingWeatherRecommendations = true
                            }
                        }
                    } else {
                        WeatherLoadingWidget()
                    }
                    
                    // Current Outfit Display
                    if !selectedItems.isEmpty {
                        CurrentOutfitCard(items: selectedItems) { item in
                            selectedItems.removeAll { $0.id == item.id }
                        }
                    }
                    
                    // Category Sections
                    ForEach(WardrobeItem.ItemCategory.allCases, id: \.self) { category in
                        let categoryItems = app.wardrobe.filter { $0.category == category }
                        if !categoryItems.isEmpty {
                            CategorySection(
                                category: category,
                                items: categoryItems,
                                selectedItems: selectedItems
                            ) { item in
                                toggleItemSelection(item)
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Outfit Builder")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selectedItems.removeAll()
                    }
                    .disabled(selectedItems.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        showingSaveSheet = true
                    }
                    .disabled(selectedItems.count < 2)
                }
            }
        }
        .sheet(isPresented: $showingSaveSheet) {
            SaveOutfitSheet(
                items: selectedItems,
                outfitName: $outfitName,
                notes: $outfitNotes,
                occasions: $selectedOccasions,
                seasons: $selectedSeasons
            ) {
                saveOutfit()
            }
        }
        .sheet(isPresented: $showingWeatherRecommendations) {
            WeatherRecommendationsSheet(
                recommendations: weatherRecommendations,
                weather: weatherService.currentWeather
            ) { items in
                selectedItems.append(contentsOf: items)
                showingWeatherRecommendations = false
            }
        }
        .task {
            await loadWeather()
        }
    }
    
    // MARK: - Helper Methods
    private func toggleItemSelection(_ item: WardrobeItem) {
        if selectedItems.contains(where: { $0.id == item.id }) {
            selectedItems.removeAll { $0.id == item.id }
        } else {
            // Only allow one item per category (except accessories)
            if item.category != .accessories {
                selectedItems.removeAll { $0.category == item.category }
            }
            selectedItems.append(item)
        }
    }
    
    private func loadWeather() async {
        guard let location = locationManager.location else { return }
        await weatherService.fetchWeather(for: location)
    }
    
    private func loadWeatherRecommendations() async {
        guard let weather = weatherService.currentWeather else { return }
        weatherRecommendations = weatherService.getRecommendations(
            for: weather,
            from: app.wardrobe
        )
    }
    
    private func saveOutfit() {
        let outfit = Outfit(
            id: UUID().uuidString,
            name: outfitName.isEmpty ? "Outfit \(Date().formatted())" : outfitName,
            items: selectedItems.map { $0.id },
            occasions: Array(selectedOccasions),
            seasons: Array(selectedSeasons),
            createdAt: Date(),
            lastWorn: nil,
            wearCount: 0,
            notes: outfitNotes.isEmpty ? nil : outfitNotes,
            weatherSuitability: nil
        )
        
        app.currentUser.savedOutfits.append(outfit)
        
        // Reset state
        selectedItems.removeAll()
        outfitName = ""
        outfitNotes = ""
        selectedOccasions.removeAll()
        selectedSeasons.removeAll()
        showingSaveSheet = false
    }
}

// MARK: - Weather Widget
struct WeatherWidget: View {
    let weather: Weather
    let onRecommendationTap: () -> Void
    @EnvironmentObject var theme: Theme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(weather.temperatureString)
                        .font(.largeTitle.bold())
                    
                    HStack {
                        Image(systemName: weatherIcon)
                            .font(.title2)
                        Text(weather.condition)
                            .font(.headline)
                    }
                    
                    Text(weather.outfitRecommendation())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Image(systemName: "humidity")
                        Text("\(Int(weather.humidity))%")
                    }
                    .font(.caption)
                    
                    HStack {
                        Image(systemName: "wind")
                        Text("\(Int(weather.windSpeed)) km/h")
                    }
                    .font(.caption)
                    
                    Button {
                        onRecommendationTap()
                    } label: {
                        Label("Get Suggestions", systemImage: "sparkles")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // 3-Day Forecast
            HStack(spacing: 16) {
                ForEach(weather.dailyForecast.prefix(3), id: \.date) { day in
                    VStack(spacing: 4) {
                        Text(day.date, format: .dateTime.weekday(.abbreviated))
                            .font(.caption2)
                        Image(systemName: weatherIcon(for: day.condition))
                            .font(.footnote)
                        Text("\(Int(day.tempMax))°")
                            .font(.caption.bold())
                        Text("\(Int(day.tempMin))°")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            LinearGradient(
                colors: gradientColors(for: weather.condition),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var weatherIcon: String {
        switch weather.condition.lowercased() {
        case let condition where condition.contains("rain"):
            return "cloud.rain"
        case let condition where condition.contains("cloud"):
            return "cloud"
        case let condition where condition.contains("sun") || condition.contains("clear"):
            return "sun.max"
        case let condition where condition.contains("snow"):
            return "cloud.snow"
        default:
            return "cloud.sun"
        }
    }
    
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case let c where c.contains("rain"):
            return "cloud.rain"
        case let c where c.contains("cloud"):
            return "cloud"
        case let c where c.contains("sun") || c.contains("clear"):
            return "sun.max"
        case let c where c.contains("snow"):
            return "cloud.snow"
        default:
            return "cloud.sun"
        }
    }
    
    private func gradientColors(for condition: String) -> [Color] {
        switch condition.lowercased() {
        case let c where c.contains("rain"):
            return [.blue, .gray]
        case let c where c.contains("sun") || c.contains("clear"):
            return [.orange, .yellow]
        case let c where c.contains("cloud"):
            return [.gray, .white]
        case let c where c.contains("snow"):
            return [.white, .blue.opacity(0.3)]
        default:
            return [.blue.opacity(0.3), .white]
        }
    }
}

// MARK: - Weather Loading Widget
struct WeatherLoadingWidget: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Loading Weather...")
                    .font(.headline)
                Text("Fetching current conditions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ProgressView()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Current Outfit Card
struct CurrentOutfitCard: View {
    let items: [WardrobeItem]
    let onRemove: (WardrobeItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Outfit")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        OutfitItemCard(item: item) {
                            onRemove(item)
                        }
                    }
                }
            }
            
            // Color Palette
            HStack(spacing: 8) {
                Text("Colors:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach(Array(Set(items.flatMap { [$0.color] + $0.secondaryColors })), id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(.white, lineWidth: 1))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Outfit Item Card
struct OutfitItemCard: View {
    let item: WardrobeItem
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.color.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        VStack {
                            Image(systemName: iconForCategory(item.category))
                                .font(.title2)
                            Text(item.name)
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    )
                
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.white, .red)
                }
                .offset(x: 8, y: -8)
            }
            
            if let brand = item.brand {
                Text(brand.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func iconForCategory(_ category: WardrobeItem.ItemCategory) -> String {
        switch category {
        case .tops: return "tshirt"
        case .bottoms: return "figure.stand"
        case .outerwear: return "cloud.rain"
        case .shoes: return "shoe"
        case .accessories: return "star"
        case .bags: return "bag"
        case .jewelry: return "sparkles"
        case .hats: return "graduationcap"
        default: return "hanger"
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    let category: WardrobeItem.ItemCategory
    let items: [WardrobeItem]
    let selectedItems: [WardrobeItem]
    let onSelect: (WardrobeItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.rawValue)
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        WardrobeItemSelectable(
                            item: item,
                            isSelected: selectedItems.contains { $0.id == item.id }
                        ) {
                            onSelect(item)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Wardrobe Item Selectable
struct WardrobeItemSelectable: View {
    let item: WardrobeItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(item.color.opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay(
                    VStack {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .green)
                        }
                        Text(item.name)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                )
            
            if let brand = item.brand {
                Text(brand.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Save Outfit Sheet
struct SaveOutfitSheet: View {
    let items: [WardrobeItem]
    @Binding var outfitName: String
    @Binding var notes: String
    @Binding var occasions: Set<WardrobeItem.Occasion>
    @Binding var seasons: Set<WardrobeItem.Season>
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Outfit Details") {
                    TextField("Outfit Name", text: $outfitName)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Occasions") {
                    ForEach(WardrobeItem.Occasion.allCases, id: \.self) { occasion in
                        HStack {
                            Text(occasion.rawValue)
                            Spacer()
                            if occasions.contains(occasion) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if occasions.contains(occasion) {
                                occasions.remove(occasion)
                            } else {
                                occasions.insert(occasion)
                            }
                        }
                    }
                }
                
                Section("Seasons") {
                    ForEach(WardrobeItem.Season.allCases, id: \.self) { season in
                        HStack {
                            Text(season.rawValue)
                            Spacer()
                            if seasons.contains(season) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if seasons.contains(season) {
                                seasons.remove(season)
                            } else {
                                seasons.insert(season)
                            }
                        }
                    }
                }
                
                Section("Items") {
                    ForEach(items) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 20, height: 20)
                            Text(item.name)
                            Spacer()
                            Text(item.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Save Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Weather Recommendations Sheet
struct WeatherRecommendationsSheet: View {
    let recommendations: [WardrobeItem]
    let weather: Weather?
    let onSelect: ([WardrobeItem]) -> Void
    @State private var selectedItems: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let weather = weather {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Based on current weather:")
                            .font(.headline)
                        Text("\(weather.temperatureString) • \(weather.condition)")
                            .font(.subheadline)
                        Text(weather.outfitRecommendation())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                }
                
                List(recommendations) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 30, height: 30)
                        
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            HStack {
                                Text(item.category.rawValue)
                                if let brand = item.brand {
                                    Text("• \(brand.name)")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedItems.contains(item.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Weather Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Selected") {
                        let selected = recommendations.filter { selectedItems.contains($0.id) }
                        onSelect(selected)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedItems.isEmpty)
                }
            }
        }
    }
}

// MARK: - Weather View Model
@MainActor
class WeatherViewModel: ObservableObject {
    @Published var currentWeather: Weather?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let weatherService: WeatherServicing
    
    init(weatherService: WeatherServicing = MockWeatherService()) {
        self.weatherService = weatherService
    }
    
    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        error = nil
        
        do {
            currentWeather = try await weatherService.fetchCurrentWeather(for: location)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func getRecommendations(for weather: Weather, from wardrobe: [WardrobeItem]) -> [WardrobeItem] {
        return weatherService.getOutfitRecommendations(for: weather, from: wardrobe)
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}
