import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var engine: StorageEngine
    @AppStorage(PreferenceKey.confirmBeforeClean) private var confirmBeforeClean = true

    @State private var selection: Set<ScanTarget> = Set(ScanTarget.purgeableTargets)
    @State private var pendingTargets: [ScanTarget] = []
    @State private var showConfirm = false
    @State private var report: CleanReport?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ringCard
                    breakdownCard
                    cleanCard
                    if let report {
                        resultCard(report)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Storage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await engine.refresh() }
                    } label: {
                        Image(systemName: engine.isScanning ? "hourglass" : "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .disabled(engine.isScanning || engine.isCleaning)
                }
            }
            .refreshable { await engine.refresh() }
            .task {
                if engine.snapshots.isEmpty { await engine.refresh() }
            }
            .confirmationDialog(
                "Clean selected locations?",
                isPresented: $showConfirm,
                titleVisibility: .visible
            ) {
                Button("Clean now", role: .destructive) {
                    runClean(pendingTargets)
                }
                Button("Cancel", role: .cancel) { pendingTargets = [] }
            } message: {
                Text("Only app caches and temporary files are removed. Your documents stay untouched.")
            }
        }
    }

    // MARK: - Cards

    private var ringCard: some View {
        Card {
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Device storage")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(SizeFormat.human(engine.volume.free)) free of \(SizeFormat.human(engine.volume.total))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(SizeFormat.percent(engine.volume.usedFraction))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.warn)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.warn.opacity(0.14)))
                }

                StorageRing(
                    fraction: engine.volume.usedFraction,
                    title: SizeFormat.human(engine.containerBytes),
                    caption: "in this app"
                )
                .padding(.vertical, 2)

                HStack(spacing: 8) {
                    StatPill(label: "Container", value: SizeFormat.human(engine.containerBytes))
                    StatPill(
                        label: "Cleanable",
                        value: SizeFormat.human(engine.purgeableBytes),
                        tint: Theme.accent
                    )
                    StatPill(
                        label: "Biggest",
                        value: engine.largestSnapshot.map { SizeFormat.human($0.bytes) } ?? "—",
                        tint: Theme.textSecondary
                    )
                }

                if engine.isScanning {
                    VStack(spacing: 7) {
                        ProgressStrip(progress: engine.scanProgress)
                        Text("Scanning…")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                } else {
                    Text(engine.status)
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                }
            }
        }
    }

    private var breakdownCard: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Container breakdown")

                if engine.snapshots.isEmpty {
                    Text(engine.isScanning ? "Reading folders…" : "Pull to refresh to scan.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.vertical, 12)
                } else {
                    VStack(spacing: 4) {
                        ForEach(engine.snapshots) { snapshot in
                            TargetRow(
                                snapshot: snapshot,
                                isSelected: selection.contains(snapshot.target),
                                isEnabled: snapshot.target.purgeable,
                                onToggle: {
                                    if selection.contains(snapshot.target) {
                                        selection.remove(snapshot.target)
                                    } else {
                                        selection.insert(snapshot.target)
                                    }
                                }
                            )
                        }
                    }
                }

                Text("Application Support and Documents are shown for reference but are never removed by the bulk cleaner.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private var cleanCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clean selected")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(selection.count) location(s) · \(SizeFormat.human(selectedBytes))")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button("All") {
                        selection = Set(ScanTarget.purgeableTargets)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .disabled(selection.count == ScanTarget.purgeableTargets.count)
                }

                Button {
                    let targets = ScanTarget.purgeableTargets.filter { selection.contains($0) }
                    guard !targets.isEmpty else { return }
                    if confirmBeforeClean {
                        pendingTargets = targets
                        showConfirm = true
                    } else {
                        runClean(targets)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if engine.isCleaning {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.black)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .bold))
                        }
                        Text(engine.isCleaning ? "Cleaning…" : "Clean \(SizeFormat.human(selectedBytes))")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(Theme.accent)
                    )
                    .opacity(selection.isEmpty || engine.isCleaning ? 0.45 : 1)
                }
                .buttonStyle(.plain)
                .disabled(selection.isEmpty || engine.isCleaning || engine.isScanning)
            }
        }
    }

    private func resultCard(_ report: CleanReport) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: report.isClean ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(report.isClean ? Theme.accent : Theme.warn)
                    Text(report.isClean ? "Cleanup finished" : "Cleanup finished with notes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Button {
                        self.report = nil
                        engine.resetReport()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Text("Freed \(SizeFormat.human(report.freedBytes)) · \(SizeFormat.items(report.removedItems))")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)

                if !report.skipped.isEmpty {
                    Text("Skipped: \(report.skipped.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                }

                ForEach(report.failures.prefix(3), id: \.self) { failure in
                    Text(failure)
                        .font(.caption2)
                        .foregroundStyle(Theme.danger)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - Actions

    private var selectedBytes: Int64 {
        engine.snapshots
            .filter { selection.contains($0.target) }
            .reduce(0) { $0 + $1.bytes }
    }

    private func runClean(_ targets: [ScanTarget]) {
        Task {
            let result = await engine.clean(targets)
            report = result
            pendingTargets = []
        }
    }
}
