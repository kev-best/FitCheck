import SwiftUI
import PhotosUI

// MARK: - App Entry

@main
struct FitNowApp: App {
    @StateObject private var theme = Theme()
    @StateObject private var appState = AppState()
    @StateObject private var router = Router()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(theme)
                .environmentObject(appState)
                .environmentObject(router)
        }
    }
}
