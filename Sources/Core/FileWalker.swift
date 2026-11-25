import Foundation

/// Blocking file-system primitives. Every call is meant to run off the main actor.
enum FileWalker {

    struct Measurement: Sendable, Equatable {
        var bytes: Int64
        var items: Int

        static let empty = Measurement(bytes: 0, items: 0)
    }

    struct PurgeResult: Sendable, Equatable {
        var freedBytes: Int64 = 0
        var removedItems: Int = 0
        var failures: [String] = []
    }

    private static let sizeKeys: Set<URLResourceKey> = [
        .isRegularFileKey,
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .totalFileAllocatedSizeKey,
        .fileAllocatedSizeKey,
        .fileSizeKey
    ]

    private static let listKeys: [URLResourceKey] = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .totalFileAllocatedSizeKey,
        .fileSizeKey
    ]

    /// Allocated bytes of a single file, falling back through the size keys iOS may omit.
    static func allocatedBytes(of url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: sizeKeys)
        if let total = values?.totalFileAllocatedSize { return Int64(total) }
        if let allocated = values?.fileAllocatedSize { return Int64(allocated) }
        if let logical = values?.fileSize { return Int64(logical) }
        return 0
    }

    /// Recursive usage of a file or directory. Symlinks are counted as links, never followed.
    static func measure(_ url: URL) -> Measurement {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return .empty
        }

        if !isDirectory.boolValue {
            return Measurement(bytes: allocatedBytes(of: url), items: 1)
        }

        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(sizeKeys),
            options: [],
            errorHandler: { _, _ in true }
        ) else {
            return .empty
        }

        var bytes: Int64 = 0
        var items: Int = 0

        for case let child as URL in enumerator {
            guard let values = try? child.resourceValues(forKeys: sizeKeys) else { continue }
            if values.isSymbolicLink == true { continue }
            guard values.isRegularFile == true else { continue }
            bytes += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0)
            items += 1
        }

        return Measurement(bytes: bytes, items: items)
    }

    /// Shallow listing for the file browser. Directory sizes are left at zero on purpose:
    /// recursive measuring of every row would stall the list.
    static func entries(in directory: URL) -> [FileEntry] {
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: listKeys,
            options: []
        ) else {
            return []
        }

        var rows: [FileEntry] = []
        rows.reserveCapacity(children.count)

        for child in children {
            let values = try? child.resourceValues(forKeys: Set(listKeys))
            let isDirectory = values?.isDirectory ?? false
            let isLink = values?.isSymbolicLink ?? false
            let bytes = isDirectory || isLink
                ? 0
                : Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
            rows.append(
                FileEntry(
                    url: child,
                    name: child.lastPathComponent,
                    isDirectory: isDirectory,
                    bytes: bytes
                )
            )
        }

        return rows.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    /// Empties a directory's children, never the directory itself.
    static func purgeContents(of root: URL, keeping protectedNames: Set<String>) -> PurgeResult {
        let fm = FileManager.default
        var result = PurgeResult()

        guard let children = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: nil,
            options: []
        ) else {
            result.failures.append("\(root.lastPathComponent) is not readable")
            return result
        }

        for child in children {
            if protectedNames.contains(child.lastPathComponent) { continue }
            let before = measure(child)
            do {
                try fm.removeItem(at: child)
                result.freedBytes += before.bytes
                result.removedItems += max(1, before.items)
            } catch {
                result.failures.append("\(child.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return result
    }

    /// True when `candidate` lives at or below `root`. Used as the last line of defence
    /// before any destructive call leaves the container.
    static func isInside(_ candidate: URL, root: URL) -> Bool {
        let child = candidate.standardizedFileURL.path
        let parent = root.standardizedFileURL.path
        if child == parent { return true }
        return child.hasPrefix(parent.hasSuffix("/") ? parent : parent + "/")
    }

    /// The one directory tree this app is ever allowed to modify.
    static var containerRoot: URL {
        URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }
}
