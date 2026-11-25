import Foundation
import Combine

@MainActor
final class StorageEngine: ObservableObject {

    @Published private(set) var volume: VolumeInfo = VolumeInfo.current()
    @Published private(set) var snapshots: [TargetSnapshot] = []
    @Published private(set) var isScanning = false
    @Published private(set) var isCleaning = false
    @Published private(set) var scanProgress: Double = 0
    @Published private(set) var lastScanAt: Date?
    @Published private(set) var lastReport: CleanReport?
    @Published private(set) var status: String = "Nothing scanned yet."

    // MARK: - Derived values

    var containerBytes: Int64 {
        snapshots.reduce(0) { $0 + $1.bytes }
    }

    var purgeableBytes: Int64 {
        snapshots.filter { $0.target.purgeable }.reduce(0) { $0 + $1.bytes }
    }

    func snapshot(for target: ScanTarget) -> TargetSnapshot? {
        snapshots.first { $0.target == target }
    }

    var largestSnapshot: TargetSnapshot? {
        snapshots.max { $0.bytes < $1.bytes }
    }

    // MARK: - Scanning

    func refresh() async {
        guard !isScanning, !isCleaning else { return }

        isScanning = true
        scanProgress = 0
        status = "Scanning the container…"

        let targets = ScanTarget.allCases
        var collected: [TargetSnapshot] = []
        collected.reserveCapacity(targets.count)

        for (index, target) in targets.enumerated() {
            guard let url = target.url else {
                scanProgress = Double(index + 1) / Double(targets.count)
                continue
            }
            let measurement = await Task.detached(priority: .userInitiated) {
                FileWalker.measure(url)
            }.value

            collected.append(
                TargetSnapshot(
                    target: target,
                    url: url,
                    bytes: measurement.bytes,
                    itemCount: measurement.items
                )
            )
            scanProgress = Double(index + 1) / Double(targets.count)
        }

        volume = VolumeInfo.current()
        snapshots = collected
        lastScanAt = Date()
        scanProgress = 1
        isScanning = false
        status = "\(SizeFormat.human(containerBytes)) in this container across \(SizeFormat.items(collected.reduce(0) { $0 + $1.itemCount }))."
    }

    // MARK: - Cleaning

    @discardableResult
    func clean(_ targets: [ScanTarget]) async -> CleanReport {
        guard !isCleaning, !isScanning else { return CleanReport() }

        let jobs: [(ScanTarget, URL)] = targets.compactMap { target in
            guard let url = target.url, FileWalker.isInside(url, root: FileWalker.containerRoot) else {
                return nil
            }
            return (target, url)
        }

        guard !jobs.isEmpty else {
            status = "Those locations are outside this app's container."
            return CleanReport()
        }

        isCleaning = true
        status = "Cleaning…"

        var report = CleanReport()

        for (target, url) in jobs {
            guard target.purgeable else {
                report.skipped.append(target.title)
                continue
            }
            let result = await Task.detached(priority: .userInitiated) {
                FileWalker.purgeContents(of: url, keeping: ScanTarget.protectedNames)
            }.value

            report.freedBytes += result.freedBytes
            report.removedItems += result.removedItems
            report.failures.append(contentsOf: result.failures)
        }

        lastReport = report
        isCleaning = false

        await refresh()
        status = report.summary
        return report
    }

    /// Deletes one row chosen in the file browser, with the same container guard.
    @discardableResult
    func delete(_ entry: FileEntry) async -> Bool {
        guard FileWalker.isInside(entry.url, root: FileWalker.containerRoot),
              entry.url.standardizedFileURL != FileWalker.containerRoot.standardizedFileURL else {
            status = "Refused: that path is outside the container."
            return false
        }

        let freed = await Task.detached(priority: .userInitiated) { () -> Int64 in
            let size = FileWalker.measure(entry.url).bytes
            do {
                try FileManager.default.removeItem(at: entry.url)
                return size
            } catch {
                return -1
            }
        }.value

        guard freed >= 0 else {
            status = "Could not delete \(entry.name)."
            return false
        }

        status = "Deleted \(entry.name) · \(SizeFormat.human(freed))"
        await refresh()
        return true
    }

    func resetReport() {
        lastReport = nil
    }
}
