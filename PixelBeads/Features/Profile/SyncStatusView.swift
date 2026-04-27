import SwiftUI

struct SyncStatusView: View {
    @EnvironmentObject var syncManager: iCloudSyncManager
    @EnvironmentObject var proStatusManager: ProStatusManager

    var body: some View {
        NavigationStack {
            List {
                statusSection
                if !proStatusManager.isPro {
                    upgradeSection
                }
            }
            .navigationTitle(L10n.tr("iCloud Sync"))
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        Section {
            HStack {
                icon
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            switch syncManager.syncStatus {
            case .syncing(let downloaded, let total):
                if total > 0 {
                    ProgressView(value: Double(downloaded), total: Double(total)) {
                        Text(L10n.tr("Syncing files..."))
                    }
                } else {
                    HStack {
                        ProgressView()
                        Text(L10n.tr("Preparing sync..."))
                            .foregroundStyle(.secondary)
                    }
                }
            case .error(let message):
                Button(role: .destructive) {
                    syncManager.startSync()
                } label: {
                    Label(message, systemImage: "exclamationmark.triangle")
                }
            default:
                EmptyView()
            }
        }
    }

    // MARK: - Upgrade

    @ViewBuilder
    private var upgradeSection: some View {
        Section {
            VStack(spacing: 12) {
                Text(L10n.tr("iCloud sync is a Pro feature."))
                    .font(.subheadline)
                Text(L10n.tr("Upgrade to PixelBeads Pro to sync your drafts, finished patterns, and preferences across all your devices."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private var icon: some View {
        Group {
            switch syncManager.syncStatus {
            case .unavailable:
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.secondary)
            case .notPro:
                Image(systemName: "lock.icloud")
                    .foregroundStyle(.secondary)
            case .syncing:
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundStyle(.blue)
            case .upToDate:
                Image(systemName: "checkmark.icloud")
                    .foregroundStyle(.green)
            case .error:
                Image(systemName: "xmark.icloud")
                    .foregroundStyle(.red)
            }
        }
    }

    private var title: String {
        switch syncManager.syncStatus {
        case .unavailable:
            L10n.tr("iCloud Not Available")
        case .notPro:
            L10n.tr("Sync Locked")
        case .syncing:
            L10n.tr("Syncing...")
        case .upToDate:
            L10n.tr("Up to Date")
        case .error:
            L10n.tr("Sync Error")
        }
    }

    private var subtitle: String {
        switch syncManager.syncStatus {
        case .unavailable:
            L10n.tr("Sign in to iCloud in Settings to enable sync.")
        case .notPro:
            L10n.tr("Upgrade to Pro to enable iCloud sync.")
        case .syncing(let downloaded, let total):
            if total > 0 {
                L10n.tr("Downloaded %d of %d files", downloaded, total)
            } else {
                L10n.tr("Preparing your data...")
            }
        case .upToDate(let lastSync):
            L10n.tr("Last synced: %@", lastSync.formatted(.relative(presentation: .named)))
        case .error(let message):
            message
        }
    }
}
