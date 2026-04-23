import SwiftUI

@main
struct PixelBeadsApp: App {
    @StateObject private var sessionStore: AppSessionStore
    @StateObject private var exploreStore: ExploreStore
    @StateObject private var createStore: CreateStore
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var profileStore: ProfileStore

    init() {
        let userService = MockUserService()
        let patternService = MockPatternService()
        let communityService = MockCommunityService(patternService: patternService)
        let avatarService = MockAvatarService()
        let exportService = MockExportService()
        let initialUser = userService.bootstrapGuestUser()

        _sessionStore = StateObject(wrappedValue: AppSessionStore(userService: userService))
        _exploreStore = StateObject(wrappedValue: ExploreStore(patternService: patternService, communityService: communityService))
        _createStore = StateObject(wrappedValue: CreateStore(patternService: patternService, exportService: exportService, user: initialUser))
        _libraryStore = StateObject(wrappedValue: LibraryStore(patternService: patternService))
        _profileStore = StateObject(wrappedValue: ProfileStore(avatarService: avatarService, patternService: patternService))
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
        }
    }
}
