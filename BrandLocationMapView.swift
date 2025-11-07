import SwiftUI
import MapKit
import CoreLocation

struct BrandLocationMapView: View {
    let brand: Brand
    @StateObject private var viewModel = BrandLocationViewModel()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedStore: StoreLocation?
    @State private var showingDirections = false
    @State private var mapType: MKMapType = .standard
    
    var body: some View {
        ZStack {
            // Map View
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: viewModel.stores) { store in
                MapAnnotation(coordinate: store.coordinate) {
                    StoreAnnotationView(store: store, isSelected: selectedStore?.id == store.id) {
                        selectedStore = store
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            
            // Top Controls
            VStack {
                HStack {
                    // Map Type Selector
                    Picker("Map Type", selection: $mapType) {
                        Text("Standard").tag(MKMapType.standard)
                        Text("Satellite").tag(MKMapType.satellite)
                        Text("Hybrid").tag(MKMapType.hybrid)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Refresh Button
                    Button {
                        Task {
                            await viewModel.loadStores(for: brand)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Store List
                if !viewModel.stores.isEmpty {
                    StoreListView(
                        stores: viewModel.stores,
                        selectedStore: $selectedStore,
                        onDirections: { store in
                            selectedStore = store
                            showingDirections = true
                        }
                    )
                }
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Finding \(brand.name) stores...")
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .navigationTitle("\(brand.name) Locations")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDirections) {
            if let store = selectedStore {
                DirectionsView(store: store)
            }
        }
        .task {
            await viewModel.loadStores(for: brand)
            if let firstStore = viewModel.stores.first {
                region.center = firstStore.coordinate
            }
        }
    }
}

// MARK: - Store Annotation View
struct StoreAnnotationView: View {
    let store: StoreLocation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isSelected {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.caption.bold())
                    Text(store.address)
                        .font(.caption2)
                    if let distance = store.distance {
                        Text("\(String(format: "%.1f", distance/1000)) km away")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.scale.combined(with: .opacity))
            }
            
            Image(systemName: pinIcon)
                .font(.title)
                .foregroundStyle(.white, pinColor)
                .symbolEffect(.bounce, value: isSelected)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                onTap()
            }
        }
    }
    
    private var pinIcon: String {
        switch store.storeType {
        case .flagship: return "star.circle.fill"
        case .outlet: return "tag.circle.fill"
        case .department: return "building.2.crop.circle.fill"
        case .boutique: return "bag.circle.fill"
        case .online: return "network.circle.fill"
        }
    }
    
    private var pinColor: Color {
        switch store.storeType {
        case .flagship: return .blue
        case .outlet: return .green
        case .department: return .purple
        case .boutique: return .orange
        case .online: return .gray
        }
    }
}

// MARK: - Store List View
struct StoreListView: View {
    let stores: [StoreLocation]
    @Binding var selectedStore: StoreLocation?
    let onDirections: (StoreLocation) -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle to expand/collapse
            HStack {
                Capsule()
                    .fill(.secondary)
                    .frame(width: 40, height: 4)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(stores) { store in
                        StoreCard(
                            store: store,
                            isSelected: selectedStore?.id == store.id,
                            onSelect: {
                                selectedStore = store
                            },
                            onDirections: {
                                onDirections(store)
                            }
                        )
                    }
                }
                .padding()
            }
            .frame(height: isExpanded ? 300 : 150)
            .background(.regularMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Store Card
struct StoreCard: View {
    let store: StoreLocation
    let isSelected: Bool
    let onSelect: () -> Void
    let onDirections: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(store.name)
                        .font(.subheadline.bold())
                    
                    Badge(text: store.storeType.rawValue, color: colorForType(store.storeType))
                }
                
                Text(store.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let hours = store.hours?.components(separatedBy: "\n").first {
                    Text(hours)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    if let distance = store.distance {
                        Label("\(String(format: "%.1f", distance/1000)) km", systemImage: "location")
                            .font(.caption)
                    }
                    
                    if let phone = store.phoneNumber {
                        Label(phone, systemImage: "phone")
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            Button {
                onDirections()
            } label: {
                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.title2)
                    .foregroundStyle(.white, .blue)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            onSelect()
        }
    }
    
    private func colorForType(_ type: StoreLocation.StoreType) -> Color {
        switch type {
        case .flagship: return .blue
        case .outlet: return .green
        case .department: return .purple
        case .boutique: return .orange
        case .online: return .gray
        }
    }
}

// MARK: - Badge View
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Directions View
struct DirectionsView: View {
    let store: StoreLocation
    @StateObject private var viewModel = DirectionsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Map(coordinateRegion: $viewModel.region,
                    showsUserLocation: true,
                    annotationItems: [store]) { store in
                    MapMarker(coordinate: store.coordinate, tint: .red)
                }
                
                VStack {
                    Spacer()
                    
                    if let route = viewModel.route {
                        RouteInfoCard(route: route, store: store)
                    }
                }
            }
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.openInMaps(store: store)
                    } label: {
                        Label("Open in Maps", systemImage: "map")
                    }
                }
            }
            .task {
                await viewModel.calculateRoute(to: store)
            }
        }
    }
}

// MARK: - Route Info Card
struct RouteInfoCard: View {
    let route: MKRoute
    let store: StoreLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.name)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(String(format: "%.1f", route.distance/1000)) km")
                        .font(.title3.bold())
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatTime(route.expectedTravelTime))
                        .font(.title3.bold())
                }
                
                Spacer()
            }
            
            Text(store.address)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let phone = store.phoneNumber {
                Button {
                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label(phone, systemImage: "phone.fill")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

// MARK: - Brand Location View Model
@MainActor
class BrandLocationViewModel: ObservableObject {
    @Published var stores: [StoreLocation] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let locationService: LocationServicing
    private let locationManager = CLLocationManager()
    
    init(locationService: LocationServicing = MockLocationService()) {
        self.locationService = locationService
        locationManager.requestWhenInUseAuthorization()
    }
    
    func loadStores(for brand: Brand) async {
        isLoading = true
        error = nil
        
        // Get user location
        let userLocation = locationManager.location ?? CLLocation(
            latitude: 40.7128,
            longitude: -74.0060
        )
        
        do {
            stores = try await locationService.findNearbyStores(
                for: brand,
                near: userLocation
            ).sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}

// MARK: - Directions View Model
@MainActor
class DirectionsViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var route: MKRoute?
    @Published var isCalculating = false
    
    private let locationService: LocationServicing
    private let locationManager = CLLocationManager()
    
    init(locationService: LocationServicing = MockLocationService()) {
        self.locationService = locationService
    }
    
    func calculateRoute(to store: StoreLocation) async {
        isCalculating = true
        
        let userLocation = locationManager.location ?? CLLocation(
            latitude: 40.7128,
            longitude: -74.0060
        )
        
        do {
            let response = try await locationService.getDirections(
                to: store,
                from: userLocation
            )
            
            if let route = response.routes.first {
                self.route = route
                
                // Adjust region to show the route
                let rect = route.polyline.boundingMapRect
                region = MKCoordinateRegion(rect)
            }
        } catch {
            print("Failed to calculate route: \(error)")
        }
        
        isCalculating = false
    }
    
    func openInMaps(store: StoreLocation) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: store.coordinate))
        mapItem.name = store.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
