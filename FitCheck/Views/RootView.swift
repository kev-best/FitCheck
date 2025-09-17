import SwiftUI

struct RootView: View {
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var router: Router

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView()

                TabView(selection: $router.selectedTab) {

                    // FEED
                    NavigationStack(path: router.bindingForPath(of: .feed)) {
                        FeedView()
                            .navigationDestination(for: Screen.self) { screen in
                                destinationView(for: screen)
                            }
                    }
                    .tabItem { Label("Feed", systemImage: "sparkles") }
                    .tag(Tab.feed)

                    // FITCHECK (Camera)
                    NavigationStack(path: router.bindingForPath(of: .fitCheck)) {
                        FitCheckView()
                            .navigationDestination(for: Screen.self) { screen in
                                destinationView(for: screen)
                            }
                    }
                    .tabItem { Label("FitCheck", systemImage: "camera.aperture") }
                    .tag(Tab.fitCheck)

                    // WARDROBE
                    NavigationStack(path: router.bindingForPath(of: .wardrobe)) {
                        WardrobeView()
                            .navigationDestination(for: Screen.self) { screen in
                                destinationView(for: screen)
                            }
                    }
                    .tabItem { Label("Wardrobe", systemImage: "hanger") }
                    .tag(Tab.wardrobe)

                    // PROFILE
                    NavigationStack(path: router.bindingForPath(of: .profile)) {
                        ProfileView()
                            .navigationDestination(for: Screen.self) { screen in
                                destinationView(for: screen)
                            }
                    }
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    .tag(Tab.profile)
                }
            }
        }
        // Global sheets (e.g., Post Review)
        .sheet(item: $router.sheet) { sheet in
            switch sheet {
            case .postReview(let result):
                PostReviewSheet(result: result)

            case .genericInfo(let title, let message):
                VStack(spacing: 16) {
                    Text(title).font(.title2.bold())
                    Text(message).foregroundStyle(.secondary)
                    Button("Close") { router.sheet = nil }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .presentationDetents([.medium, .large])
            }
        }
    }

    // Centralized factory for navigation destinations
    @ViewBuilder
    private func destinationView(for screen: Screen) -> some View {
        switch screen {
        case .postDetail(let id):
            PostDetailView(postId: id)
        case .cameraSettings:
            CameraSettingsView()
        case .wardrobeItem(let id):
            WardrobeItemDetailView(itemId: id)
        case .editProfile:
            EditProfileView()
        }
    }
}



struct HeaderView: View {
    @EnvironmentObject var theme: Theme
    
    var body: some View {
        HStack {
            Text("FitCheck")
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "flame.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.orange, .red)
                .font(.title2)
                .accessibilityLabel("Streaks")
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

