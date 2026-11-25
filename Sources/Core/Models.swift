import Foundation

struct VolumeInfo: Sendable, Equatable {
    var total: Int64
    var free: Int64

    var used: Int64 { max(0, total - free) }

    var usedFraction: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }

    static func current() -> VolumeInfo {
        let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        let total = (attributes?[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free = (attributes?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        return VolumeInfo(total: total, free: free)
    }
}

struct TargetSnapshot: Identifiable, Sendable, Equatable {
    var id: String { target.rawValue }
    var target: ScanTarget
    var url: URL
    var bytes: Int64
    var itemCount: Int
}

struct CleanReport: Sendable, Equatable {
    var freedBytes: Int64 = 0
    var removedItems: Int = 0
    var failures: [String] = []
    var skipped: [String] = []

    var isClean: Bool { failures.isEmpty }

    var summary: String {
        if freedBytes == 0 && removedItems == 0 {
            return failures.isEmpty ? "Nothing to clean." : "Could not clean \(failures.count) item(s)."
        }
        var parts = ["Freed \(SizeFormat.human(freedBytes))", SizeFormat.items(removedItems)]
        if !failures.isEmpty {
            parts.append("\(failures.count) skipped")
        }
        return parts.joined(separator: " · ")
    }
}

struct FileEntry: Identifiable, Hashable, Sendable {
    var id: String { url.path }
    var url: URL
    var name: String
    var isDirectory: Bool
    var bytes: Int64

    var displaySize: String {
        isDirectory ? "folder" : SizeFormat.human(bytes)
    }
}
