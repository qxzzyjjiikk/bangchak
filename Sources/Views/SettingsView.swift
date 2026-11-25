import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var engine: StorageEngine
    @AppStorage(PreferenceKey.appearance) private var appearanceRaw = AppearanceMode.dark.rawValue
    @AppStorage(PreferenceKey.confirmBeforeClean) private var confirmBeforeClean = true
    @AppStorage(PreferenceKey.showHiddenFiles) private var showHidden = false

    @State private var copied = false

    private var appearance: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceRaw) ?? .dark },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    appearanceCard
                    behaviourCard
                    absenceCard
                    aboutCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }

    private var appearanceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Appearance")
                Picker("Theme", selection: appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("There is no wallpaper layer and no background movie, so the theme only changes colours and contrast.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private var behaviourCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "Cleaning behaviour")

                Toggle(isOn: $confirmBeforeClean) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ask before cleaning")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Show a confirmation before deleting anything.")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .tint(Theme.accent)

                Divider().overlay(Theme.stroke)

                Toggle(isOn: $showHidden) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show hidden files")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Reveals dot-files in the browser.")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .tint(Theme.accent)
            }
        }
    }

    private var absenceCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "What this app does not have")

                ForEach(BuildInfo.absentFeatures) { feature in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "nosign")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.danger.opacity(0.85))
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(feature.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(feature.detail)
                                .font(.caption2)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }
            }
        }
    }

    private var aboutCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "About")

                HStack {
                    Text(BuildInfo.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("v\(BuildInfo.version) (\(BuildInfo.build))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }

                Text(BuildInfo.bundleID)
                    .font(.caption2.monospaced())
                    .foregroundStyle(Theme.textTertiary)

                Divider().overlay(Theme.stroke)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Container")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                    Text(FileWalker.containerRoot.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(3)
                        .truncationMode(.middle)
                }

                Button {
                    UIPasteboard.general.string = FileWalker.containerRoot.path
                    copied = true
                } label: {
                    Text(copied ? "Path copied" : "Copy container path")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)

                if let scannedAt = engine.lastScanAt {
                    Text("Last scan: \(scannedAt.formatted(date: .omitted, time: .standard))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.textTertiary)
                }

                Text("This app only reads and writes its own container. Another app's data is not reachable without an entitlement signed by Apple.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}
