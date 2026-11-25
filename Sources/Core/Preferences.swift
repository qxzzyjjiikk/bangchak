import Foundation
import SwiftUI

enum PreferenceKey {
    static let appearance = "ck.appearance"
    static let confirmBeforeClean = "ck.confirmBeforeClean"
    static let showHiddenFiles = "ck.showHiddenFiles"
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var scheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum BuildInfo {
    static let name = "Bangchak"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let bundleID = Bundle.main.bundleIdentifier ?? "xyz.rlzx.bangchak"

    /// Everything this app deliberately does not contain.
    static let absentFeatures: [AbsentFeature] = [
        AbsentFeature(title: "license key", detail: "No activation screen, no key field, no expiry."),
        AbsentFeature(title: "account", detail: "Nothing to sign in to and no profile to sync."),
        AbsentFeature(title: "network", detail: "The app never uploads or downloads anything."),
        AbsentFeature(title: "background video", detail: "No AVPlayer, no looping movie behind the UI."),
        AbsentFeature(title: "music", detail: "No AVAudioPlayer and no bundled track.")
    ]
}

struct AbsentFeature: Identifiable, Hashable, Sendable {
    var id: String { title }
    var title: String
    var detail: String
}
