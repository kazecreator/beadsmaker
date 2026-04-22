import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Query(sort: \CollectedPattern.modifiedAt, order: .reverse) private var collectedPatterns: [CollectedPattern]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppConstants.appleUserIDKey) private var appleUserID = ""
    @State private var editorRoute: EditorRoute?
    @State private var selectedTab = 0

    private var isAdmin: Bool {
        !appleUserID.isEmpty && appleUserID == AppConstants.adminAppleID
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GalleryView { pattern in
                    editorRoute = EditorRoute(id: pattern.persistentModelID)
                }
                .navigationDestination(item: $editorRoute) { route in
                    EditorView(patternID: route.id)
                        .toolbar(.hidden, for: .tabBar)
                }
            }
            .tag(0)
            .tabItem { Label("My Patterns", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                MarketplaceView()
            }
            .tag(1)
            .tabItem { Label("Marketplace", systemImage: "bag.fill") }

            NavigationStack {
                ProfileView()
            }
            .tag(2)
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }

            if isAdmin {
                NavigationStack {
                    ModerationView()
                }
                .tag(3)
                .tabItem { Label("Moderation", systemImage: "checkmark.shield") }
            }
        }
        .onAppear {
            repairStoredData()
        }
        .onChange(of: patterns.map(\.persistentModelID)) { _, _ in
            repairStoredData()
        }
    }

    private func repairStoredData() {
        var didChange = false

        if profiles.isEmpty {
            let profile = UserProfile()
            modelContext.insert(profile)
            didChange = true
        }

        for pattern in patterns {
            if pattern.thumbnailData == nil {
                pattern.thumbnailData = PatternRenderer.thumbnail(pattern: pattern).pngData()
                didChange = true
            }
        }

        for favorite in collectedPatterns {
            if favorite.thumbnailData == nil {
                let preview = Pattern(name: favorite.name, width: favorite.width, height: favorite.height)
                preview.gridData = favorite.gridData
                favorite.thumbnailData = PatternRenderer.thumbnail(pattern: preview).pngData()
                didChange = true
            }

            if favorite.author.isEmpty {
                favorite.author = "未知作者"
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }
}

private struct EditorRoute: Hashable, Identifiable {
    let id: PersistentIdentifier
}
