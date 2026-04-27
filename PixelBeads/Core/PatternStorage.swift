import Foundation

// MARK: - Protocol

protocol PatternStorage {
    func baseURL() -> URL
    func loadPatterns(from directory: URL) -> [Pattern]
    func writePattern(_ pattern: Pattern, to directory: URL)
    func deletePattern(id: UUID, from directory: URL)
    func fileExists(id: UUID, in directory: URL) -> Bool
    func patternCount(in directory: URL) -> Int
}

// MARK: - File URL helper (shared)

private func fileURL(id: UUID, in directory: URL) -> URL {
    directory.appendingPathComponent("\(id.uuidString).json")
}

// MARK: - JSON helpers (shared)

private let sharedEncoder: JSONEncoder = {
    let e = JSONEncoder()
    e.dateEncodingStrategy = .iso8601
    return e
}()

private let sharedDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return d
}()

// MARK: - LocalPatternStorage

final class LocalPatternStorage: PatternStorage {
    private let root: URL

    init(root: URL? = nil) {
        self.root = root ??
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PixelBeads", isDirectory: true)
    }

    func baseURL() -> URL { root }

    func loadPatterns(from directory: URL) -> [Pattern] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> Pattern? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? sharedDecoder.decode(Pattern.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func writePattern(_ pattern: Pattern, to directory: URL) {
        guard let data = try? sharedEncoder.encode(pattern) else { return }
        let url = fileURL(id: pattern.id, in: directory)
        try? data.write(to: url, options: .atomic)
    }

    func deletePattern(id: UUID, from directory: URL) {
        try? FileManager.default.removeItem(at: fileURL(id: id, in: directory))
    }

    func fileExists(id: UUID, in directory: URL) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(id: id, in: directory).path)
    }

    func patternCount(in directory: URL) -> Int {
        loadPatterns(from: directory).count
    }
}

// MARK: - iCloudPatternStorage

final class iCloudPatternStorage: PatternStorage {
    private let root: URL
    private let coordinator = NSFileCoordinator(filePresenter: nil)

    init?(containerID: String = "iCloud.com.kevinzhang.pixelbeads") {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: containerID) else {
            return nil
        }
        self.root = container.appendingPathComponent("PixelBeads", isDirectory: true)

        let fm = FileManager.default
        for subdir in ["drafts", "saved", "published"] {
            let dir = root.appendingPathComponent(subdir, isDirectory: true)
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    func baseURL() -> URL { root }

    func loadPatterns(from directory: URL) -> [Pattern] {
        var results: [Pattern] = []
        var coordError: NSError?

        coordinator.coordinate(readingItemAt: directory, options: [], error: &coordError) { readURL in
            let fm = FileManager.default
            guard let files = try? fm.contentsOfDirectory(
                at: readURL,
                includingPropertiesForKeys: [URLResourceKey.ubiquitousItemDownloadingStatusKey],
                options: .skipsHiddenFiles
            ) else { return }

            results = files
                .filter { $0.pathExtension == "json" }
                .compactMap { url -> Pattern? in
                    // Trigger download for evicted files
                    if let status = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
                        .ubiquitousItemDownloadingStatus,
                       status == .notDownloaded {
                        try? fm.startDownloadingUbiquitousItem(at: url)
                        return nil
                    }

                    var pattern: Pattern?
                    coordinator.coordinate(readingItemAt: url, options: [], error: nil) { fileURL in
                        guard let data = try? Data(contentsOf: fileURL) else { return }
                        pattern = try? sharedDecoder.decode(Pattern.self, from: data)
                    }
                    return pattern
                }
                .sorted { $0.createdAt > $1.createdAt }
        }

        return results
    }

    func writePattern(_ pattern: Pattern, to directory: URL) {
        guard let data = try? sharedEncoder.encode(pattern) else { return }
        let url = fileURL(id: pattern.id, in: directory)
        var coordError: NSError?

        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordError) { writeURL in
            try? NSFileVersion.removeOtherVersionsOfItem(at: writeURL)
            try? data.write(to: writeURL, options: .atomic)
        }
    }

    func deletePattern(id: UUID, from directory: URL) {
        let url = fileURL(id: id, in: directory)
        var coordError: NSError?
        coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &coordError) { deleteURL in
            try? FileManager.default.removeItem(at: deleteURL)
        }
    }

    func fileExists(id: UUID, in directory: URL) -> Bool {
        let url = fileURL(id: id, in: directory)
        return FileManager.default.fileExists(atPath: url.path)
    }

    func patternCount(in directory: URL) -> Int {
        loadPatterns(from: directory).count
    }
}
