import SwiftUI

/// Flat, dark-first palette. No video layer, no gradient wallpaper, nothing that moves
/// behind the content unless the user scrolls it.
enum Theme {
    static let background = Color(red: 0.043, green: 0.051, blue: 0.067)
    static let surface = Color(red: 0.082, green: 0.094, blue: 0.118)
    static let surfaceRaised = Color(red: 0.110, green: 0.125, blue: 0.153)
    static let stroke = Color.white.opacity(0.07)

    static let accent = Color(red: 0.34, green: 0.87, blue: 0.62)
    static let accentSoft = Color(red: 0.24, green: 0.66, blue: 0.86)
    static let warn = Color(red: 1.00, green: 0.70, blue: 0.30)
    static let danger = Color(red: 1.00, green: 0.38, blue: 0.42)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    static let ringGradient = AngularGradient(
        gradient: Gradient(colors: [accent, accentSoft, warn]),
        center: .center,
        startAngle: .degrees(0),
        endAngle: .degrees(360)
    )
}

extension View {
    func cardSurface(cornerRadius: CGFloat = 22, padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}
