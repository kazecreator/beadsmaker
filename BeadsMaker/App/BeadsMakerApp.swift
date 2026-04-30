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

        let syncWasEnabled = UserDefaults.standard.bool(forKey: "sync.enabled")
        let syncNeverSet = UserDefaults.standard.object(forKey: "sync.enabled") == nil
        let shouldUseiCloud = proStatus.isPro && syncMgr.isAvailable && (syncWasEnabled || syncNeverSet)

        if shouldUseiCloud, let iCloudStorage = iCloudPatternStorage() {
            storage = iCloudStorage
            icloudPrefs = iCloudPreferencesStore()
            UserDefaults.standard.set(true, forKey: "sync.enabled")
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
        if patternSvc.isUsingiCloud {
            print("[AppInit] iCloud storage selected — sync enabled")
        } else {
            let reason = proStatus.isPro
                ? (syncMgr.isAvailable ? "iCloudPatternStorage init failed" : "iCloud not available")
                : "user is not Pro"
            print("[AppInit] local storage selected — \(reason)")
        }
        #endif

        syncMgr.onToggleSync = { wantsOn in
            if wantsOn {
                guard let iCloudStorage = iCloudPatternStorage() else {
                    syncMgr.syncStatus = .unavailable
                    return
                }
                syncMgr.syncStatus = .syncing(downloaded: 0, total: 0)
                if iCloudStorage.isEmpty {
                    await patternSvc.migrateToiCloud(storage: iCloudStorage)
                } else {
                    await patternSvc.switchToiCloud(storage: iCloudStorage)
                }
                UserDefaults.standard.set(true, forKey: "sync.enabled")
                syncMgr.startSync()
            } else {
                syncMgr.stopSync()
            }
        }
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
                sessionStore.setProStatus(proStatusManager.isPro)
            }
            .onChange(of: proStatusManager.isPro) { _, isPro in
                sessionStore.setProStatus(isPro)
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
        let iCloudEmpty = iCloudStorage.isEmpty
        if iCloudEmpty {
            await patternService.migrateToiCloud(storage: iCloudStorage)
        } else {
            await patternService.switchToiCloud(storage: iCloudStorage)
        }
        UserDefaults.standard.set(true, forKey: "sync.enabled")
        syncManager.startSync()
    }
}
