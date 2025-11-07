import SwiftUI
import PhotosUI

struct PostCreationView: View {
    @EnvironmentObject var app: AppState
    @EnvironmentObject var theme: Theme
    @Environment(\.dismiss) private var dismiss
    
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var caption = ""
    @State private var selectedBrands: [Brand] = []
    @State private var selectedWardrobeItems: [WardrobeItem] = []
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var shareLocation = false
    @State private var showingBrandPicker = false
    @State private var showingWardrobePicker = false
    @State private var showingPhotosPicker = false
    @State private var isPosting = false
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherService = WeatherViewModel()
    
    var canPost: Bool {
        frontImage != nil || backImage != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo Selection
                    PhotoSectionView(
                        frontImage: $frontImage,
                        backImage: $backImage,
                        onSelectPhotos: {
                            showingPhotosPicker = true
                        }
                    )
                    
                    // Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.headline)
                        
                        TextField("What's your fit today?", text: $caption, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Brand Tags
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Brand Tags")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingBrandPicker = true
                            } label: {
                                Label("Add Brand", systemImage: "plus.circle")
                                    .font(.caption)
                            }
                        }
                        
                        if !selectedBrands.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedBrands) { brand in
                                        BrandTag(brand: brand) {
                                            selectedBrands.removeAll { $0.id == brand.id }
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("No brands selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Wardrobe Items
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Wardrobe Items")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingWardrobePicker = true
                            } label: {
                                Label("Add Items", systemImage: "plus.circle")
                                    .font(.caption)
                            }
                        }
                        
                        if !selectedWardrobeItems.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedWardrobeItems) { item in
                                        WardrobeItemTag(item: item) {
                                            selectedWardrobeItems.removeAll { $0.id == item.id }
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("No items selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Custom Tags
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline)
                        
                        HStack {
                            TextField("Add tag", text: $newTag)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    addTag()
                                }
                            
                            Button {
                                addTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newTag.isEmpty)
                        }
                        
                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    TagChip(text: tag) {
                                        tags.removeAll { $0 == tag }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Location & Weather
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional Info")
                            .font(.headline)
                        
                        Toggle(isOn: $shareLocation) {
                            HStack {
                                Image(systemName: "location")
                                Text("Share Location")
                            }
                        }
                        .toggleStyle(.automatic)
                        
                        if let weather = weatherService.currentWeather {
                            HStack {
                                Image(systemName: "cloud.sun")
                                Text("Current: \(weather.temperatureString) • \(weather.condition)")
                                    .font(.caption)
                                Spacer()
                                Text("Will be saved with post")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await postOutfit()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!canPost || isPosting)
                }
            }
            .sheet(isPresented: $showingBrandPicker) {
                BrandPickerView(selectedBrands: $selectedBrands)
            }
            .sheet(isPresented: $showingWardrobePicker) {
                WardrobePickerView(
                    wardrobeItems: app.wardrobe,
                    selectedItems: $selectedWardrobeItems
                )
            }
            .sheet(isPresented: $showingPhotosPicker) {
                PhotosPicker(
                    selection: .constant([]),
                    matching: .images
                )
            }
            .overlay {
                if isPosting {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Posting your fit...")
                            .font(.headline)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .task {
            if let location = locationManager.location {
                await weatherService.fetchWeather(for: location)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func addTag() {
        guard !newTag.isEmpty else { return }
        tags.append(newTag.lowercased())
        newTag = ""
    }
    
    private func postOutfit() async {
        isPosting = true
        
        // Create post data
        var locationInfo: Post.LocationInfo?
        if shareLocation, let location = locationManager.location {
            locationInfo = Post.LocationInfo(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                cityName: nil // Would use reverse geocoding
            )
        }
        
        var weatherInfo: Post.WeatherInfo?
        if let weather = weatherService.currentWeather {
            weatherInfo = Post.WeatherInfo(
                temperature: weather.temperature,
                condition: weather.condition,
                humidity: weather.humidity,
                windSpeed: weather.windSpeed
            )
        }
        
        let post = Post(
            id: UUID().uuidString,
            user: app.currentUser,
            createdAt: Date(),
            isLate: false,
            frontImageName: "front_temp",
            backImageName: "back_temp",
            tags: tags,
            brandTags: selectedBrands,
            itemTags: selectedWardrobeItems.map { $0.id },
            palette: extractColors(),
            reactions: [],
            comments: [],
            location: locationInfo,
            weather: weatherInfo
        )
        
        // Add to feed
        app.feed.insert(post, at: 0)
        
        // Update wardrobe item wear counts
        for item in selectedWardrobeItems {
            if let index = app.wardrobe.firstIndex(where: { $0.id == item.id }) {
                app.wardrobe[index].wearCount += 1
                app.wardrobe[index].lastWorn = Date()
            }
        }
        
        isPosting = false
        dismiss()
    }
    
    private func extractColors() -> [Color] {
        var colors: [Color] = []
        
        // Extract from selected wardrobe items
        for item in selectedWardrobeItems {
            colors.append(item.color)
            colors.append(contentsOf: item.secondaryColors)
        }
        
        // Limit to 5 unique colors
        return Array(Set(colors).prefix(5))
    }
}

// MARK: - Photo Section View
struct PhotoSectionView: View {
    @Binding var frontImage: UIImage?
    @Binding var backImage: UIImage?
    let onSelectPhotos: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Photos")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                PhotoSlot(
                    title: "Front",
                    image: frontImage,
                    onTap: onSelectPhotos
                )
                
                PhotoSlot(
                    title: "Back",
                    image: backImage,
                    onTap: onSelectPhotos
                )
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Photo Slot
struct PhotoSlot: View {
    let title: String
    let image: UIImage?
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "camera")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text(title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Brand Tag
struct BrandTag: View {
    let brand: Brand
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(brand.name)
                .font(.caption.bold())
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Wardrobe Item Tag
struct WardrobeItemTag: View {
    let item: WardrobeItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(item.color)
                .frame(width: 16, height: 16)
            
            Text(item.name)
                .font(.caption)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(text)")
                .font(.caption)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Brand Picker View
struct BrandPickerView: View {
    @Binding var selectedBrands: [Brand]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    let allBrands = MockData.sampleBrands
    
    var filteredBrands: [Brand] {
        if searchText.isEmpty {
            return allBrands
        }
        return allBrands.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search brands", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                
                // Brand Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Brand.BrandCategory.allCases, id: \.self) { category in
                            Button {
                                searchText = category.rawValue
                            } label: {
                                Text(category.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Brand List
                List {
                    ForEach(filteredBrands) { brand in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(brand.name)
                                    .font(.headline)
                                Text(brand.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedBrands.contains(where: { $0.id == brand.id }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let index = selectedBrands.firstIndex(where: { $0.id == brand.id }) {
                                selectedBrands.remove(at: index)
                            } else {
                                selectedBrands.append(brand)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Brands")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Wardrobe Picker View
struct WardrobePickerView: View {
    let wardrobeItems: [WardrobeItem]
    @Binding var selectedItems: [WardrobeItem]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: WardrobeItem.ItemCategory?
    
    var filteredItems: [WardrobeItem] {
        var items = wardrobeItems
        
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            items = items.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.brand?.name ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search items", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button {
                            selectedCategory = nil
                        } label: {
                            Text("All")
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundStyle(selectedCategory == nil ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        
                        ForEach(WardrobeItem.ItemCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Items Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(filteredItems) { item in
                            WardrobeItemGridCell(
                                item: item,
                                isSelected: selectedItems.contains { $0.id == item.id }
                            ) {
                                if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
                                    selectedItems.remove(at: index)
                                } else {
                                    selectedItems.append(item)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done (\(selectedItems.count))") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Wardrobe Item Grid Cell
struct WardrobeItemGridCell: View {
    let item: WardrobeItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.color.opacity(0.3))
                    .frame(height: 100)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .blue)
                }
            }
            
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
            
            if let brand = item.brand {
                Text(brand.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: ProposedViewSize(result.sizes[index]))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                sizes.append(size)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}
