import Foundation

/// Formats byte counts for display without pulling in UIKit.
enum SizeFormat {

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        formatter.zeroPadsFractionDigits = false
        return formatter
    }()

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// "0 KB" for zero so the UI never shows an empty string.
    static func human(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 KB" }
        return byteFormatter.string(fromByteCount: bytes)
    }

    static func items(_ count: Int) -> String {
        let value = countFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
        return count == 1 ? "\(value) item" : "\(value) items"
    }

    static func percent(_ fraction: Double) -> String {
        let clamped = min(max(fraction, 0), 1)
        return String(format: "%.0f%%", clamped * 100)
    }

    /// Compact signed delta, e.g. "−124.3 MB" style without the minus glyph.
    static func freed(_ bytes: Int64) -> String {
        bytes > 0 ? human(bytes) : "nothing"
    }
}
