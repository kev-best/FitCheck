import SwiftUI
import Combine

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var currentUser: User
    @Published var feed: [Post] = []
    @Published var wardrobe: [WardrobeItem] = []
    @Published var savedOutfits: [Outfit] = []
    @Published var notifications: [AppNotification] = []
    @Published var isAuthenticated = true
    @Published var dailyWindowActive = false
    
    init() {
        self.currentUser = MockData.sampleUser
        self.feed = MockData.sampleFeed
        self.wardrobe = MockData.sampleWardrobe
        loadMockData()
    }
    
    private func loadMockData() {
        // Add more sample posts
        for i in 1...5 {
            let post = Post(
                id: "post_\(i)",
                user: User(
                    username: "user\(i)",
                    displayName: "User \(i)",
                    streakCount: Int.random(in: 1...30)
                ),
                createdAt: Date().addingTimeInterval(TimeInterval(-3600 * i)),
                isLate: Bool.random(),
                frontImageName: "front\(i % 3 + 1)",
                backImageName: "back\(i % 3 + 1)",
                tags: ["ootd", "streetwear", "fashion"].shuffled().prefix(2).map { $0 },
                brandTags: Array(MockData.sampleBrands.shuffled().prefix(2)),
                itemTags: [],
                palette: [.blue, .black, .white, .gray, .red].shuffled().prefix(3).map { $0 },
                reactions: [],
                comments: [],
                location: nil,
                weather: Post.WeatherInfo(
                    temperature: Double.random(in: 15...25),
                    condition: ["Sunny", "Cloudy", "Partly Cloudy"].randomElement()!,
                    humidity: Double.random(in: 40...70),
                    windSpeed: Double.random(in: 5...20)
                )
            )
            feed.append(post)
        }
        
        // Add more wardrobe items
        let additionalItems = [
            WardrobeItem(
                id: "w4",
                name: "White T-Shirt",
                category: .tops,
                brand: MockData.sampleBrands[5],
                price: 29,
                color: .white,
                secondaryColors: [],
                size: "M",
                tags: ["basic", "essential"],
                wearCount: 40,
                seasons: [.summer, .spring],
                occasions: [.casual]
            ),
            WardrobeItem(
                id: "w5",
                name: "Leather Jacket",
                category: .outerwear,
                brand: MockData.sampleBrands[4],
                price: 450,
                color: .black,
                secondaryColors: [],
                size: "M",
                tags: ["luxury", "statement"],
                wearCount: 5,
                seasons: [.fall, .winter],
                occasions: [.party, .date]
            ),
            WardrobeItem(
                id: "w6",
                name: "Running Shorts",
                category: .bottoms,
                brand: MockData.sampleBrands[1],
                price: 55,
                color: .gray,
                secondaryColors: [.white],
                size: "M",
                tags: ["athletic", "comfort"],
                wearCount: 20,
                seasons: [.summer],
                occasions: [.athletic, .casual]
            )
        ]
        wardrobe.append(contentsOf: additionalItems)
    }
    
    func likePost(_ postId: String, emoji: String) {
        if let index = feed.firstIndex(where: { $0.id == postId }) {
            let reaction = Reaction(
                id: UUID().uuidString,
                userId: currentUser.id,
                emoji: emoji,
                createdAt: Date()
            )
            feed[index].reactions.append(reaction)
        }
    }
    
    func commentOnPost(_ postId: String, text: String) {
        if let index = feed.firstIndex(where: { $0.id == postId }) {
            let comment = Comment(
                id: UUID().uuidString,
                userId: currentUser.id,
                userName: currentUser.displayName,
                text: text,
                createdAt: Date(),
                likes: []
            )
            feed[index].comments.append(comment)
        }
    }
    
    func followUser(_ userId: String) {
        if !currentUser.following.contains(userId) {
            currentUser.following.append(userId)
        }
    }
    
    func unfollowUser(_ userId: String) {
        currentUser.following.removeAll { $0 == userId }
    }
}

// MARK: - Router
enum AppTab: Hashable {
    case feed
    case fitCheck
    case wardrobe
    case profile
}

enum NavigationRoute: Hashable {
    case postDetail(id: String)
    case userProfile(id: String)
    case brandLocations(brand: Brand)
    case outfitBuilder
    case savedOutfits
    case wardrobeItemDetail(id: String)
    case editProfile
    case cameraSettings
    case notifications
    case settings
}

enum SheetRoute: Identifiable {
    case postReview(CameraCaptureResult)
    case postCreation
    case brandPicker
    case weatherInfo
    
    var id: String {
        switch self {
        case .postReview: return "postReview"
        case .postCreation: return "postCreation"
        case .brandPicker: return "brandPicker"
        case .weatherInfo: return "weatherInfo"
        }
    }
}

@MainActor
class Router: ObservableObject {
    @Published var selectedTab: AppTab = .feed
    @Published var feedPath: [NavigationRoute] = []
    @Published var fitCheckPath: [NavigationRoute] = []
    @Published var wardrobePath: [NavigationRoute] = []
    @Published var profilePath: [NavigationRoute] = []
    @Published var sheet: SheetRoute?
    
    func select(_ tab: AppTab) {
        selectedTab = tab
    }
    
    func push(_ route: NavigationRoute, in tab: AppTab) {
        switch tab {
        case .feed: feedPath.append(route)
        case .fitCheck: fitCheckPath.append(route)
        case .wardrobe: wardrobePath.append(route)
        case .profile: profilePath.append(route)
        }
    }
    
    func popToRoot(in tab: AppTab) {
        switch tab {
        case .feed: feedPath.removeAll()
        case .fitCheck: fitCheckPath.removeAll()
        case .wardrobe: wardrobePath.removeAll()
        case .profile: profilePath.removeAll()
        }
    }
}

// MARK: - Theme
@MainActor
class Theme: ObservableObject {
    @Published var bg = LinearGradient(colors: [.white, Color(.systemGray6)], startPoint: .top, endPoint: .bottom)
    @Published var gradient = LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    @Published var shadow = Color.black.opacity(0.1)
    @Published var cornerRadius: CGFloat = 20
    @Published var textPrimary = Color.primary
    @Published var textSecondary = Color.secondary
    @Published var accent = Color.blue
}

// MARK: - Camera Manager (Enhanced from template)
import AVFoundation

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isDualSupported = false
    @Published var isDualEnabled = false
    @Published var primaryPreviewLayer: AVCaptureVideoPreviewLayer?
    @Published var secondaryPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private var session: AVCaptureSession?
    private var currentInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var position: AVCaptureDevice.Position = .back
    
    override init() {
        super.init()
        checkDualCameraSupport()
    }
    
    private func checkDualCameraSupport() {
        #if !targetEnvironment(simulator)
        isDualSupported = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil
        #endif
    }
    
    func start(isDualPreferred: Bool) async {
        #if targetEnvironment(simulator)
        // Simulator doesn't support camera
        return
        #else
        await setupSession(isDual: isDualPreferred && isDualSupported)
        session?.startRunning()
        #endif
    }
    
    func stop() {
        session?.stopRunning()
    }
    
    func flipCamera() async {
        position = position == .back ? .front : .back
        await reconfigureSession()
    }
    
    func setDualMode(_ enabled: Bool) async {
        isDualEnabled = enabled && isDualSupported
        await reconfigureSession()
    }
    
    func capturePhoto() async throws -> CameraCaptureResult {
        guard let photoOutput = photoOutput else {
            throw CameraError.notConfigured
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            let delegate = PhotoCaptureDelegate { result in
                continuation.resume(returning: result)
            }
            
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    private func setupSession(isDual: Bool) async {
        let newSession = AVCaptureSession()
        newSession.beginConfiguration()
        
        // Configure for photo capture
        if newSession.canSetSessionPreset(.photo) {
            newSession.sessionPreset = .photo
        }
        
        // Add input
        guard let device = getCamera(isDual: isDual),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if newSession.canAddInput(input) {
            newSession.addInput(input)
            currentInput = input
        }
        
        // Add photo output
        let output = AVCapturePhotoOutput()
        if newSession.canAddOutput(output) {
            newSession.addOutput(output)
            photoOutput = output
        }
        
        newSession.commitConfiguration()
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: newSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        await MainActor.run {
            self.session = newSession
            self.primaryPreviewLayer = previewLayer
        }
    }
    
    private func reconfigureSession() async {
        guard let session = session else { return }
        
        session.beginConfiguration()
        
        // Remove current input
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        // Add new input
        guard let device = getCamera(isDual: isDualEnabled),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        
        session.commitConfiguration()
    }
    
    private func getCamera(isDual: Bool) -> AVCaptureDevice? {
        if isDual && position == .back {
            return AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
        } else {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
        }
    }
}

// MARK: - Camera Support Types
struct CameraCaptureResult {
    let front: UIImage?
    let back: UIImage?
}

enum CameraError: Error {
    case notConfigured
    case captureFailure
}

private class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (CameraCaptureResult) -> Void
    
    init(completion: @escaping (CameraCaptureResult) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(CameraCaptureResult(front: nil, back: nil))
            return
        }
        
        // For now, return the same image for both front and back
        // In a real app, you'd capture two separate photos
        completion(CameraCaptureResult(front: image, back: image))
    }
}

// MARK: - View Extensions
extension View {
    func softCard(cornerRadius: CGFloat, shadow: Color) -> some View {
        self
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadow, radius: 8, x: 0, y: 4)
    }
    
    func pill(_ theme: Theme) -> some View {
        self
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.gradient)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}
