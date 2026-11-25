import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content.cardSurface(padding: padding)
    }
}

struct StorageRing: View {
    var fraction: Double
    var title: String
    var caption: String

    private var clamped: Double {
        min(max(fraction, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.stroke, lineWidth: 16)

            Circle()
                .trim(from: 0, to: max(0.015, clamped))
                .stroke(
                    Theme.ringGradient,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.55), value: clamped)

            VStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 22)
        }
        .frame(width: 192, height: 192)
    }
}

struct StatPill: View {
    var label: String
    var value: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surfaceRaised)
        )
    }
}

struct TargetRow: View {
    var snapshot: TargetSnapshot
    var isSelected: Bool
    var isEnabled: Bool
    var onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(isSelected ? Theme.accent.opacity(0.18) : Theme.surfaceRaised)
                        .frame(width: 38, height: 38)
                    Image(systemName: snapshot.target.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.target.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(snapshot.target.subtitle)
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(SizeFormat.human(snapshot.bytes))
                        .font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                    if snapshot.itemCount > 0 {
                        Text(SizeFormat.items(snapshot.itemCount))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textTertiary.opacity(0.7))
            }
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct ProgressStrip: View {
    var progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceRaised)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(4, proxy.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: 5)
        .animation(.easeOut(duration: 0.25), value: progress)
    }
}

struct SectionLabel: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
