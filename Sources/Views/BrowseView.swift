import SwiftUI
import UniformTypeIdentifiers

struct BrowseView: View {
    @EnvironmentObject private var engine: StorageEngine
    @AppStorage(PreferenceKey.showHiddenFiles) private var showHidden = false

    @State private var stack: [URL] = [FileWalker.containerRoot]
    @State private var entries: [FileEntry] = []
    @State private var isLoading = false
    @State private var footer = ""
    @State private var pendingDelete: FileEntry?
    @State private var showImporter = false
    @State private var banner: String?

    private var current: URL {
        stack.last ?? FileWalker.containerRoot
    }

    private var visibleEntries: [FileEntry] {
        showHidden ? entries : entries.filter { !$0.name.hasPrefix(".") }
    }

    private var breadcrumb: String {
        let rootPath = FileWalker.containerRoot.path
        let path = current.path
        guard path.hasPrefix(rootPath) else { return current.lastPathComponent }
        let tail = path.dropFirst(rootPath.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return tail.isEmpty ? "Container" : tail
    }

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack(spacing: 10) {
                        ProgressView().controlSize(.small)
                        Text("Reading folder…")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .listRowBackground(Theme.surface)
                } else if visibleEntries.isEmpty {
                    Text("This folder is empty. Use the import button to bring a file in.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.surface)
                } else {
                    ForEach(visibleEntries) { entry in
                        row(entry)
                            .listRowBackground(Theme.surface)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard entry.isDirectory else { return }
                                banner = nil
                                stack.append(entry.url)
                            }
                            .contextMenu {
                                if entry.isDirectory {
                                    Button {
                                        banner = nil
                                        stack.append(entry.url)
                                    } label: {
                                        Label("Open", systemImage: "folder")
                                    }
                                }
                                ShareLink(item: entry.url) {
                                    Label("Export", systemImage: "square.and.arrow.up")
                                }
                                Button(role: .destructive) {
                                    pendingDelete = entry
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingDelete = entry
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if stack.count > 1 {
                        Button {
                            banner = nil
                            stack.removeLast()
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button {
                            showImporter = true
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        Button {
                            showHidden.toggle()
                        } label: {
                            Image(systemName: showHidden ? "eye" : "eye.slash")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(breadcrumb)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                    Text(footer)
                        .font(.caption2)
                        .foregroundStyle(Theme.textTertiary)
                    if let banner {
                        Text(banner)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.accent)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Theme.background)
            }
            .task(id: current) { await load() }
            .refreshable { await load() }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    importFiles(urls)
                case .failure(let error):
                    banner = "Import failed: \(error.localizedDescription)"
                }
            }
            .confirmationDialog(
                "Delete \(pendingDelete?.name ?? "item")?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { confirmDelete() }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This removes the item from the app container permanently.")
            }
        }
    }

    private func row(_ entry: FileEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(entry.isDirectory ? Theme.accent : Theme.textTertiary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(entry.isDirectory ? "folder" : SizeFormat.human(entry.bytes))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer(minLength: 6)

            if entry.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.vertical, 3)
    }

    // MARK: - Loading

    private func load() async {
        isLoading = true
        let directory = current
        let rows = await Task.detached(priority: .userInitiated) {
            FileWalker.entries(in: directory)
        }.value

        guard directory == current else { return }
        entries = rows
        footer = summary(for: rows)
        isLoading = false
    }

    private func summary(for rows: [FileEntry]) -> String {
        let folders = rows.filter(\.isDirectory).count
        let files = rows.count - folders
        return "\(folders) folders · \(files) files"
    }

    // MARK: - Import

    private func importFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let directory = current

        Task {
            var copied = 0
            var failed: [String] = []

            for source in urls {
                let scoped = source.startAccessingSecurityScopedResource()
                defer { if scoped { source.stopAccessingSecurityScopedResource() } }

                let destination = uniqueDestination(for: source.lastPathComponent, in: directory)
                guard FileWalker.isInside(destination, root: FileWalker.containerRoot) else { continue }

                do {
                    try FileManager.default.copyItem(at: source, to: destination)
                    copied += 1
                } catch {
                    failed.append(source.lastPathComponent)
                }
            }

            if !failed.isEmpty {
                banner = "Skipped \(failed.count): \(failed.prefix(2).joined(separator: ", "))"
            } else if copied > 0 {
                banner = "Imported \(copied) file(s) into \(directory.lastPathComponent)"
            }

            await load()
        }
    }

    private func uniqueDestination(for name: String, in directory: URL) -> URL {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = directory.appendingPathComponent(name)
        var counter = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            let suffix = counter == 1 ? "-1" : "-\(counter)"
            let candidateName = ext.isEmpty ? "\(base)\(suffix)" : "\(base)\(suffix).\(ext)"
            candidate = directory.appendingPathComponent(candidateName)
            counter += 1
        }

        return candidate
    }

    // MARK: - Delete

    private func confirmDelete() {
        guard let entry = pendingDelete else { return }
        pendingDelete = nil

        let directory = current
        guard FileWalker.isInside(entry.url, root: directory) else { return }

        Task {
            _ = await engine.delete(entry)
            let rows = await Task.detached(priority: .userInitiated) {
                FileWalker.entries(in: directory)
            }.value
            guard directory == current else { return }
            entries = rows
            footer = summary(for: rows)
        }
    }
}
