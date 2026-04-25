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
    private let supabaseConfig: SupabaseClientConfig?

    init() {
        self.supabaseConfig = AppEnvironment.optionalSupabaseConfig()
        let userService = MockUserService()
        let patternService = LocalPatternService()
        let exploreService: ExploreService
        let communityService: CommunityService
        if let supabaseConfig {
            exploreService = SupabaseExploreService(config: supabaseConfig)
            communityService = SupabaseCommunityService(config: supabaseConfig)
        } else {
            exploreService = MockExploreService()
            communityService = MockCommunityService()
        }
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
        if let supabaseConfig {
            debugPrint("Supabase config loaded for host:", supabaseConfig.url.host ?? "unknown")
        } else {
            debugPrint("Supabase configuration not found. Phase 0 local-only mode remains available.")
        }
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
                // Configure Apple Sign In manager with Supabase if available.
                if let config = supabaseConfig {
                    appleSignInManager.configure(config: config)
                }
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
