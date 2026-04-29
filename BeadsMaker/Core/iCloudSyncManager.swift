import Foundation

@MainActor
final class iCloudSyncManager: ObservableObject {
    @Published var syncStatus: SyncStatus = .notPro {
        didSet {
            #if DEBUG
            print("[iCloudSync] status → \(syncStatus)")
            #endif
        }
    }

    private let containerID = "iCloud.com.kevinzhang.beadsmaker"
    private var metadataQuery: NSMetadataQuery?

    var isAvailable: Bool {
        let available = FileManager.default.ubiquityIdentityToken != nil
        #if DEBUG
        if !available {
            print("[iCloudSync] iCloud not available — no ubiquity identity token")
        }
        #endif
        return available
    }

    var containerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: containerID)
    }

    // MARK: - Sync preference (persisted)

    var isSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "sync.enabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "sync.enabled")
            #if DEBUG
            print("[iCloudSync] isSyncEnabled = \(newValue)")
            #endif
        }
    }

    var onToggleSync: ((Bool) async -> Void)?

    // MARK: - Init

    init() {
        #if DEBUG
        print("[iCloudSync] init — isAvailable: \(FileManager.default.ubiquityIdentityToken != nil)")
        #endif
        observeIdentityChanges()
    }

    // MARK: - Start / Stop

    func startSync() {
        isSyncEnabled = true
        guard isAvailable else {
            syncStatus = .unavailable
            return
        }
        #if DEBUG
        print("[iCloudSync] startSync — starting metadata query")
        #endif
        startMetadataQuery()
    }

    func stopSync() {
        #if DEBUG
        print("[iCloudSync] stopSync — stopping metadata query")
        #endif
        isSyncEnabled = false
        metadataQuery?.stop()
        metadataQuery = nil
        syncStatus = .notPro
    }

    // MARK: - Private

    private func observeIdentityChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(identityDidChange),
            name: NSNotification.Name.NSUbiquityIdentityDidChange,
            object: nil
        )
    }

    @objc private func identityDidChange() {
        #if DEBUG
        print("[iCloudSync] identityDidChange — isAvailable: \(FileManager.default.ubiquityIdentityToken != nil)")
        #endif
        if isAvailable {
            startMetadataQuery()
        } else {
            syncStatus = .unavailable
            metadataQuery?.stop()
            metadataQuery = nil
        }
    }

    private func startMetadataQuery() {
        guard isAvailable else {
            syncStatus = .unavailable
            return
        }

        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K ENDSWITH '.json'", NSMetadataItemFSNameKey)

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(metadataQueryDidUpdate),
                           name: .NSMetadataQueryDidUpdate, object: query)
        center.addObserver(self, selector: #selector(metadataQueryDidFinish),
                           name: .NSMetadataQueryDidFinishGathering, object: query)

        self.metadataQuery = query
        syncStatus = .syncing(downloaded: 0, total: 0)
        query.start()
    }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }
        updateProgress(from: query)
    }

    @objc private func metadataQueryDidFinish(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }
        updateProgress(from: query)
        syncStatus = .upToDate(lastSync: .now)
    }

    private func updateProgress(from query: NSMetadataQuery) {
        let total = query.resultCount
        var downloaded = 0

        for i in 0..<total {
            guard let item = query.result(at: i) as? NSMetadataItem,
                  let status = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
            else { continue }
            if status == NSMetadataUbiquitousItemDownloadingStatusCurrent {
                downloaded += 1
            }
        }

        #if DEBUG
        print("[iCloudSync] metadata progress — \(downloaded)/\(total) files current")
        #endif

        if total > 0 {
            syncStatus = .syncing(downloaded: downloaded, total: total)
        }
    }
}
