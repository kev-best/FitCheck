//
//  Screen.swift
//  FitCheck
//
//  Created by csuftitan on 9/15/25.
//


import Foundation
import SwiftUI

/// App-wide type-safe destinations you can push on a NavigationStack.
enum Screen: Hashable {
    // Feed
    case postDetail(id: String)

    // FitCheck (camera) subpages
    case cameraSettings

    // Wardrobe
    case wardrobeItem(id: String)

    // Profile
    case editProfile
}



/// Central router for tabs, navigation paths, and global sheets.
@MainActor
final class Router: ObservableObject {
    // Currently selected tab
    @Published var selectedTab: Tab = .feed

    // Per-tab navigation paths
    @Published var feedPath = NavigationPath()
    @Published var fitCheckPath = NavigationPath()
    @Published var wardrobePath = NavigationPath()
    @Published var profilePath = NavigationPath()

    // Global sheet presentation
    @Published var sheet: Sheet?

        enum Sheet: Identifiable {
            case postReview(CameraCaptureResult)
            case genericInfo(title: String, message: String)

            var id: String {
                switch self {
                case .postReview: return "postReview"
                case .genericInfo(let t, let m): return "generic:\(t)#\(m)"
                }
            }
        }

    // MARK: - Tab selection
    func select(_ tab: Tab) {
        selectedTab = tab
    }

    // MARK: - Push / Pop
    func push(_ screen: Screen, in tab: Tab? = nil) {
        let target = tab ?? selectedTab
        switch target {
        case .feed:     feedPath.append(screen)
        case .fitCheck: fitCheckPath.append(screen)
        case .wardrobe: wardrobePath.append(screen)
        case .profile:  profilePath.append(screen)
        }
    }

    func pop(in tab: Tab? = nil) {
        let target = tab ?? selectedTab
        switch target {
        case .feed:     if !feedPath.isEmpty { feedPath.removeLast() }
        case .fitCheck: if !fitCheckPath.isEmpty { fitCheckPath.removeLast() }
        case .wardrobe: if !wardrobePath.isEmpty { wardrobePath.removeLast() }
        case .profile:  if !profilePath.isEmpty { profilePath.removeLast() }
        }
    }

    func popToRoot(in tab: Tab? = nil) {
        let target = tab ?? selectedTab
        switch target {
        case .feed:     feedPath = NavigationPath()
        case .fitCheck: fitCheckPath = NavigationPath()
        case .wardrobe: wardrobePath = NavigationPath()
        case .profile:  profilePath = NavigationPath()
        }
    }

    // MARK: - Bindings for NavigationStack
    func bindingForPath(of tab: Tab) -> Binding<NavigationPath> {
        Binding(
            get: {
                switch tab {
                case .feed:     return self.feedPath
                case .fitCheck: return self.fitCheckPath
                case .wardrobe: return self.wardrobePath
                case .profile:  return self.profilePath
                }
            },
            set: { newValue in
                switch tab {
                case .feed:     self.feedPath = newValue
                case .fitCheck: self.fitCheckPath = newValue
                case .wardrobe: self.wardrobePath = newValue
                case .profile:  self.profilePath = newValue
                }
            }
        )
    }
}

