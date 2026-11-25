import Foundation

/// The four disjoint locations inside the app's own container that we ever touch.
/// Nothing outside the sandbox is reachable, and nothing here is shared with another app.
enum ScanTarget: String, CaseIterable, Identifiable, Sendable {
    case caches
    case temporary
    case support
    case documents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .caches: return "Caches"
        case .temporary: return "Temporary files"
        case .support: return "Application Support"
        case .documents: return "Documents"
        }
    }

    var subtitle: String {
        switch self {
        case .caches: return "Library/Caches · regenerated on demand"
        case .temporary: return "NSTemporaryDirectory() · safe to drop"
        case .support: return "Library/Application Support · may hold app data"
        case .documents: return "Your files · never cleaned automatically"
        }
    }

    var symbol: String {
        switch self {
        case .caches: return "shippingbox"
        case .temporary: return "clock.arrow.circlepath"
        case .support: return "internaldrive"
        case .documents: return "folder"
        }
    }

    /// Only locations the system rebuilds on its own are offered to the bulk cleaner.
    var purgeable: Bool {
        switch self {
        case .caches, .temporary: return true
        case .support, .documents: return false
        }
    }

    var url: URL? {
        let fm = FileManager.default
        switch self {
        case .caches:
            return fm.urls(for: .cachesDirectory, in: .userDomainMask).first
        case .temporary:
            return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        case .support:
            return fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        case .documents:
            return fm.urls(for: .documentDirectory, in: .userDomainMask).first
        }
    }

    /// Names the cleaner will refuse to delete even inside a purgeable folder.
    static let protectedNames: Set<String> = [
        ".DS_Store",
        "com.apple.metadata.SKStore"
    ]

    static var purgeableTargets: [ScanTarget] {
        allCases.filter(\.purgeable)
    }
}
