import SwiftUI

@main
struct PixelBeadsApp: App {
    @StateObject private var sessionStore: AppSessionStore
    @StateObject private var exploreStore: ExploreStore
    @StateObject private var createStore: CreateStore
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var profileStore: ProfileStore
    @StateObject private var proStatusManager = ProStatusManager()
    @StateObject private var appleSignInManager = AppleSignInManager()

    init() {
        let userService = MockUserService()
        let patternService = LocalPatternService()
        let exploreService: ExploreService = MockExploreService()
        let communityService: CommunityService = MockCommunityService()
        let avatarService = MockAvatarService()
        let exportService = MockExportService()
        let initialUser = userService.bootstrapGuestUser()

        _sessionStore = StateObject(wrappedValue: AppSessionStore(userService: userService))
        _exploreStore = StateObject(wrappedValue: ExploreStore(
            exploreService: exploreService,
            patternService: patternService,
            communityService: communityService
        ))
        _createStore = StateObject(wrappedValue: CreateStore(patternService: patternService, exportService: exportService, user: initialUser))
        _libraryStore = StateObject(wrappedValue: LibraryStore(patternService: patternService))
        _profileStore = StateObject(wrappedValue: ProfileStore(avatarService: avatarService, patternService: patternService))

        #if DEBUG
        debugPrint("Community and backend calls are disabled. PixelBeads is running local-only.")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                sessionStore: sessionStore,
                exploreStore: exploreStore,
                createStore: createStore,
                libraryStore: libraryStore,
                profileStore: profileStore
            )
            .environmentObject(proStatusManager)
            .environmentObject(appleSignInManager)
            .task {
                // Sync Pro status on cold start.
                // If Keychain already has Pro, apply it immediately.
                // Otherwise check StoreKit entitlements (e.g. purchases made on another device).
                if !proStatusManager.isPro {
                    await proStatusManager.checkEntitlements()
                }
                if proStatusManager.isPro {
                    sessionStore.upgradeToPro()
                }
            }
        }
    }
}
