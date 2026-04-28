import SwiftUI

@main
struct BeadsMakerApp: App {
    @StateObject private var sessionStore: AppSessionStore
    @StateObject private var createStore: CreateStore
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var profileStore: ProfileStore
    @StateObject private var proStatusManager: ProStatusManager
    @StateObject private var appleSignInManager = AppleSignInManager()
    @StateObject private var syncManager: iCloudSyncManager

    /// Retained to enable runtime migration after Pro purchase.
    private let patternService: LocalPatternService

    init() {
        let proStatus = ProStatusManager()
        _proStatusManager = StateObject(wrappedValue: proStatus)

        let syncMgr = iCloudSyncManager()
        _syncManager = StateObject(wrappedValue: syncMgr)

        // --- Choose storage backend ---
        let storage: PatternStorage
        let icloudPrefs: iCloudPreferencesStore?

        if proStatus.isPro, syncMgr.isAvailable, let iCloudStorage = iCloudPatternStorage() {
            storage = iCloudStorage
            icloudPrefs = iCloudPreferencesStore()
            syncMgr.startSync()
        } else {
            storage = LocalPatternStorage()
            icloudPrefs = nil
        }

        // --- Services ---
        let userService = MockUserService(icloud: icloudPrefs)
        let patternSvc = LocalPatternService(storage: storage)
        patternService = patternSvc
        let avatarService = MockAvatarService()
        let exportService = MockExportService()
        let initialUser = userService.bootstrapGuestUser()

        _sessionStore = StateObject(wrappedValue: AppSessionStore(userService: userService))
        _createStore = StateObject(wrappedValue: CreateStore(
            patternService: patternSvc, exportService: exportService, user: initialUser
        ))
        _libraryStore = StateObject(wrappedValue: LibraryStore(patternService: patternSvc))
        _profileStore = StateObject(wrappedValue: ProfileStore(
            avatarService: avatarService, patternService: patternSvc
        ))

        #if DEBUG
        debugPrint("BeadsMaker is running local-only.")
        if patternSvc.isUsingiCloud {
            debugPrint("iCloud sync enabled for Pro user.")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                sessionStore: sessionStore,
                createStore: createStore,
                libraryStore: libraryStore,
                profileStore: profileStore
            )
            .environmentObject(proStatusManager)
            .environmentObject(appleSignInManager)
            .environmentObject(syncManager)
            .task {
                if !proStatusManager.isPro {
                    await proStatusManager.checkEntitlements()
                }
                if proStatusManager.isPro {
                    sessionStore.upgradeToPro()
                }
            }
            .onChange(of: proStatusManager.isPro) { _, isPro in
                guard isPro, !patternService.isUsingiCloud else { return }
                Task {
                    await migrateToiCloud()
                }
            }
        }
    }

    // MARK: - Migration

    private func migrateToiCloud() async {
        guard let iCloudStorage = iCloudPatternStorage() else {
            syncManager.syncStatus = .unavailable
            return
        }
        syncManager.syncStatus = .syncing(downloaded: 0, total: 0)
        await patternService.migrateToiCloud(storage: iCloudStorage)
        syncManager.startSync()
    }
}
