import SwiftUI

@main
struct FitCheckApp: App {
    @StateObject private var app = AppState()
    @StateObject private var theme = Theme()
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(app)
                .environmentObject(theme)
                .environmentObject(router)
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var router: Router
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.feedPath) {
                FeedView()
                    .navigationDestination(for: NavigationRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Feed", systemImage: "rectangle.stack")
            }
            .tag(AppTab.feed)
            
            NavigationStack(path: $router.fitCheckPath) {
                FitCheckView()
                    .navigationDestination(for: NavigationRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("FitCheck", systemImage: "camera")
            }
            .tag(AppTab.fitCheck)
            
            NavigationStack(path: $router.wardrobePath) {
                WardrobeTabView()
                    .navigationDestination(for: NavigationRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Wardrobe", systemImage: "tshirt")
            }
            .tag(AppTab.wardrobe)
            
            NavigationStack(path: $router.profilePath) {
                ProfileView()
                    .navigationDestination(for: NavigationRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }
            .tag(AppTab.profile)
        }
        .sheet(item: $router.sheet) { sheet in
            sheetView(for: sheet)
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: NavigationRoute) -> some View {
        switch route {
        case .postDetail(let id):
            EnhancedPostDetailView(postId: id)
        case .userProfile(let id):
            UserProfileView(userId: id)
        case .brandLocations(let brand):
            BrandLocationMapView(brand: brand)
        case .outfitBuilder:
            OutfitBuilderView()
        case .savedOutfits:
            SavedOutfitsView()
        case .wardrobeItemDetail(let id):
            WardrobeItemDetailView(itemId: id)
        case .editProfile:
            EditProfileView()
        case .cameraSettings:
            CameraSettingsView()
        case .notifications:
            NotificationsView()
        case .settings:
            SettingsView()
        }
    }
    
    @ViewBuilder
    private func sheetView(for sheet: SheetRoute) -> some View {
        switch sheet {
        case .postReview(let result):
            PostReviewSheet(result: result)
        case .postCreation:
            PostCreationView()
        case .brandPicker:
            BrandPickerView(selectedBrands: .constant([]))
        case .weatherInfo:
            WeatherDetailView()
        }
    }
}

// MARK: - Wardrobe Tab View
struct WardrobeTabView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var router: Router
    @State private var selectedSegment = 0
    
    var body: some View {
        VStack {
            // Segmented Control
            Picker("View", selection: $selectedSegment) {
                Text("Items").tag(0)
                Text("Outfits").tag(1)
                Text("Builder").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            switch selectedSegment {
            case 0:
                WardrobeView()
            case 1:
                SavedOutfitsView()
            case 2:
                OutfitBuilderView()
            default:
                WardrobeView()
            }
        }
        .navigationTitle("Wardrobe")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Add new item
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Enhanced Post Detail View
struct EnhancedPostDetailView: View {
    let postId: String
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var router: Router
    @State private var commentText = ""
    @State private var showingBrandMap = false
    @State private var selectedBrand: Brand?
    
    var post: Post? {
        app.feed.first { $0.id == postId }
    }
    
    var body: some View {
        ScrollView {
            if let post = post {
                VStack(spacing: 20) {
                    // User Info
                    HStack {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(Text(String(post.user.displayName.prefix(1))).font(.title3.bold()))
                        
                        VStack(alignment: .leading) {
                            Text(post.user.displayName)
                                .font(.headline)
                            Text("@\(post.user.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Follow") {
                            app.followUser(post.user.id)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                    
                    // Images
                    TabView {
                        DemoImage(name: post.frontImageName)
                            .tag(0)
                        DemoImage(name: post.backImageName)
                            .tag(1)
                    }
                    .tabViewStyle(.page)
                    .frame(height: 400)
                    
                    // Weather & Location Info
                    if let weather = post.weather {
                        HStack {
                            Image(systemName: "thermometer")
                            Text("\(Int(weather.temperature))°C")
                            Spacer()
                            Image(systemName: "cloud.sun")
                            Text(weather.condition)
                        }
                        .font(.caption)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Brand Tags with Map Feature
                    if !post.brandTags.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Brands")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(post.brandTags) { brand in
                                        Button {
                                            selectedBrand = brand
                                            showingBrandMap = true
                                        } label: {
                                            HStack {
                                                Text(brand.name)
                                                Image(systemName: "map")
                                            }
                                            .font(.caption.bold())
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(theme.gradient)
                                            .foregroundStyle(.white)
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Tags
                    if !post.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(post.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.black.opacity(0.06))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Reactions
                    HStack {
                        ForEach(["👔", "🔥", "💯", "😍", "👏"], id: \.self) { emoji in
                            Button {
                                app.likePost(postId, emoji: emoji)
                            } label: {
                                Text(emoji)
                                    .font(.title2)
                            }
                        }
                        Spacer()
                        Text("\(post.reactions.count) reactions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comments (\(post.comments.count))")
                            .font(.headline)
                        
                        ForEach(post.comments) { comment in
                            CommentRow(comment: comment)
                        }
                        
                        // Add Comment
                        HStack {
                            TextField("Add a comment...", text: $commentText)
                                .textFieldStyle(.roundedBorder)
                            
                            Button {
                                if !commentText.isEmpty {
                                    app.commentOnPost(postId, text: commentText)
                                    commentText = ""
                                }
                            } label: {
                                Image(systemName: "paperplane.fill")
                            }
                            .disabled(commentText.isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            } else {
                Text("Post not found")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBrandMap) {
            if let brand = selectedBrand {
                NavigationView {
                    BrandLocationMapView(brand: brand)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingBrandMap = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(.gray.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(Text(String(comment.userName.prefix(1))).font(.caption.bold()))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(comment.userName)
                    .font(.subheadline.bold())
                Text(comment.text)
                    .font(.subheadline)
                Text(comment.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: "heart")
                    .font(.caption)
                Text("\(comment.likes.count)")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Additional Views
struct UserProfileView: View {
    let userId: String
    
    var body: some View {
        Text("User Profile: \(userId)")
            .navigationTitle("Profile")
    }
}

struct SavedOutfitsView: View {
    @EnvironmentObject var app: AppState
    
    var body: some View {
        ScrollView {
            if app.currentUser.savedOutfits.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("No saved outfits yet")
                        .font(.headline)
                    Text("Create your first outfit in the Builder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(50)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(app.currentUser.savedOutfits) { outfit in
                        SavedOutfitCard(outfit: outfit)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Saved Outfits")
    }
}

struct SavedOutfitCard: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 150)
                .overlay(
                    VStack {
                        Image(systemName: "tshirt")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("\(outfit.items.count) items")
                            .font(.caption)
                    }
                )
            
            Text(outfit.name)
                .font(.subheadline.bold())
                .lineLimit(1)
            
            Text("Worn \(outfit.wearCount) times")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
}

struct NotificationsView: View {
    var body: some View {
        List {
            ForEach(0..<5) { _ in
                HStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading) {
                        Text("New follower")
                            .font(.subheadline.bold())
                        Text("user123 started following you")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("2h")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Notifications")
    }
}

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Account") {
                NavigationLink("Edit Profile", destination: EditProfileView())
                NavigationLink("Privacy", destination: Text("Privacy Settings"))
                NavigationLink("Notifications", destination: Text("Notification Settings"))
            }
            
            Section("App") {
                NavigationLink("Camera Settings", destination: CameraSettingsView())
                NavigationLink("Theme", destination: Text("Theme Settings"))
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

struct WeatherDetailView: View {
    @StateObject private var weatherService = WeatherViewModel()
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            if let weather = weatherService.currentWeather {
                ScrollView {
                    VStack(spacing: 20) {
                        // Current Weather
                        VStack(spacing: 16) {
                            Text(weather.temperatureString)
                                .font(.system(size: 60, weight: .thin))
                            
                            Text(weather.condition)
                                .font(.title2)
                            
                            Text("Feels like \(Int(weather.feelsLike))°C")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        
                        // Details Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            WeatherDetailCard(icon: "humidity", title: "Humidity", value: "\(Int(weather.humidity))%")
                            WeatherDetailCard(icon: "wind", title: "Wind", value: "\(Int(weather.windSpeed)) km/h")
                            WeatherDetailCard(icon: "eye", title: "Visibility", value: "\(Int(weather.visibility)) km")
                            WeatherDetailCard(icon: "gauge", title: "Pressure", value: "\(Int(weather.pressure)) mb")
                        }
                        .padding()
                        
                        // Outfit Recommendation
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Outfit Recommendation")
                                .font(.headline)
                            Text(weather.outfitRecommendation())
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // 7-Day Forecast
                        VStack(alignment: .leading, spacing: 12) {
                            Text("7-Day Forecast")
                                .font(.headline)
                            
                            ForEach(weather.dailyForecast, id: \.date) { day in
                                HStack {
                                    Text(day.date, format: .dateTime.weekday(.wide))
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Spacer()
                                    
                                    Text(day.condition)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Text("\(Int(day.tempMax))°")
                                            .fontWeight(.medium)
                                        Text("\(Int(day.tempMin))°")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                
                                if day.date != weather.dailyForecast.last?.date {
                                    Divider()
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Loading weather data...")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Weather")
        .task {
            if let location = locationManager.location {
                await weatherService.fetchWeather(for: location)
            }
        }
    }
}

struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
