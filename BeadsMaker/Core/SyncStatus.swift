import Foundation

enum SyncStatus: Equatable {
    case unavailable
    case notPro
    case syncing(downloaded: Int, total: Int)
    case upToDate(lastSync: Date)
    case error(String)
}
