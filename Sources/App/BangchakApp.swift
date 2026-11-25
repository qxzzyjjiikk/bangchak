import SwiftUI

@main
struct BangchakApp: App {
    @StateObject private var engine = StorageEngine()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .tint(Theme.accent)
        }
    }
}
