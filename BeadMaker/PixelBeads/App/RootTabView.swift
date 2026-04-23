import SwiftUI

struct RootTabView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var exploreStore: ExploreStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore
    @ObservedObject var profileStore: ProfileStore

    @State private var selection: AppTab = .explore

    var body: some View {
        TabView(selection: $selection) {
            ExploreView(
                sessionStore: sessionStore,
                exploreStore: exploreStore,
                createStore: createStore,
                libraryStore: libraryStore,
                selectedTab: $selection
            )
            .tabItem { Label("Explore", systemImage: "safari") }
            .tag(AppTab.explore)

            CreateView(
                sessionStore: sessionStore,
                createStore: createStore,
                libraryStore: libraryStore
            )
            .tabItem { Label("Create", systemImage: "square.grid.3x3.fill") }
            .tag(AppTab.create)

            LibraryView(libraryStore: libraryStore)
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag(AppTab.library)

            ProfileView(sessionStore: sessionStore, profileStore: profileStore)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .task {
            reloadStores()
        }
        .onChange(of: sessionStore.currentUser) { _, _ in
            reloadStores()
        }
        .onChange(of: selection) { _, newValue in
            if newValue == .library || newValue == .profile || newValue == .explore {
                reloadStores()
            }
        }
    }

    private func reloadStores() {
        let user = sessionStore.currentUser
        exploreStore.load(for: user)
        libraryStore.load(for: user)
        profileStore.load(for: user)
    }
}
