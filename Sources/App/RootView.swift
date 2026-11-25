import SwiftUI

struct RootView: View {
    @AppStorage(PreferenceKey.appearance) private var appearanceRaw = AppearanceMode.dark.rawValue
    @State private var tab: Tab = .dashboard

    enum Tab: Hashable {
        case dashboard
        case browse
        case settings
    }

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .dark
    }

    var body: some View {
        TabView(selection: $tab) {
            DashboardView()
                .tabItem { Label("Storage", systemImage: "internaldrive") }
                .tag(Tab.dashboard)

            BrowseView()
                .tabItem { Label("Files", systemImage: "folder") }
                .tag(Tab.browse)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
        .preferredColorScheme(appearance.scheme)
    }
}
