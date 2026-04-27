import SwiftUI

struct RootTabView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var exploreStore: ExploreStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore
    @ObservedObject var profileStore: ProfileStore

    @State private var selection: AppTab = .create
    private let deviceID = DeviceIdentity.deviceID

    var body: some View {
        TabView(selection: $selection) {
            if AppFeatureFlags.communityEnabled {
                ExploreView(
                    sessionStore: sessionStore,
                    exploreStore: exploreStore,
                    createStore: createStore,
                    libraryStore: libraryStore,
                    selectedTab: $selection
                )
                .tabItem { Label("Explore", systemImage: "safari") }
                .tag(AppTab.explore)
            }

            CreateView(
                sessionStore: sessionStore,
                createStore: createStore,
                libraryStore: libraryStore,
                selectedTab: $selection
            )
            .tabItem { Label("Create", systemImage: "square.grid.3x3.fill") }
            .tag(AppTab.create)

            LibraryView(libraryStore: libraryStore, createStore: createStore, sessionStore: sessionStore, selectedTab: $selection)
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag(AppTab.library)

            ProfileView(sessionStore: sessionStore, profileStore: profileStore)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .task {
            await reloadStores()
        }
        .onChange(of: sessionStore.currentUser) { _, _ in
            Task {
                await reloadStores()
            }
        }
        .onChange(of: selection) { _, newValue in
            if newValue == .library || newValue == .profile || newValue == .explore {
                Task {
                    await reloadStores()
                }
            }
        }
    }

    private func reloadStores() async {
        let user = sessionStore.currentUser
        if AppFeatureFlags.communityEnabled {
            await exploreStore.load(for: user, deviceID: deviceID)
        }
        libraryStore.load(for: user)
        profileStore.load(for: user)
    }
}
