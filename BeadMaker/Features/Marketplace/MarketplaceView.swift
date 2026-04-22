import SwiftUI
import SwiftData

struct MarketplaceView: View {
    @StateObject private var viewModel = MarketplaceViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .empty:
                ContentUnavailableView {
                    Label("No Featured Patterns", systemImage: "sparkles")
                } description: {
                    Text("Check back later for new marketplace picks.")
                }
            case .failed(let message):
                ContentUnavailableView {
                    Label("Unable to Load Marketplace", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        Task { await viewModel.reload() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .loaded(let patterns):
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(patterns) { pattern in
                            NavigationLink {
                                MarketplaceDetailView(pattern: pattern)
                            } label: {
                                MarketplacePatternRow(pattern: pattern)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    await viewModel.reload()
                }
            }
        }
        .navigationTitle("Marketplace")
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Loading featured patterns…")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MarketplacePatternRow: View {
    let pattern: MarketplacePattern

    var body: some View {
        HStack(spacing: 14) {
            MarketplaceThumbnailView(pattern: pattern)
                .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 6) {
                Text(pattern.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("by \(pattern.author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(pattern.width) × \(pattern.height)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(pattern.downloadCount.formatted(), systemImage: "arrow.down.circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct MarketplaceDetailView: View {
    let pattern: MarketplacePattern

    @Environment(\.modelContext) private var modelContext
    @State private var didDownload = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MarketplaceThumbnailView(pattern: pattern)
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)

                VStack(alignment: .leading, spacing: 10) {
                    Text(pattern.name)
                        .font(.title2.weight(.bold))

                    Text("by \(pattern.author)")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Label("\(pattern.width) × \(pattern.height)", systemImage: "ruler")
                        Label(pattern.downloadCount.formatted(), systemImage: "arrow.down.circle")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let description = pattern.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                    }
                }

                Button(didDownload ? "Saved to My Patterns" : "Download") {
                    downloadPattern()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(didDownload)
            }
            .padding(16)
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func downloadPattern() {
        let localPattern = Pattern(name: pattern.name, width: pattern.width, height: pattern.height)
        localPattern.gridData = pattern.gridData
        localPattern.thumbnailData = PatternRenderer.thumbnail(pattern: localPattern).pngData()

        modelContext.insert(localPattern)
        try? modelContext.save()
        didDownload = true
    }
}

private struct MarketplaceThumbnailView: View {
    let pattern: MarketplacePattern

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemFill))

            if let url = pattern.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var placeholder: some View {
        MarketplacePatternArtworkView(pattern: pattern)
            .padding(10)
    }
}

private struct MarketplacePatternArtworkView: View {
    let pattern: MarketplacePattern

    var body: some View {
        GeometryReader { proxy in
            let layout = PatternSheetLayout(
                containerSize: proxy.size,
                columns: pattern.width,
                rows: pattern.height,
                padding: 8
            )

            Canvas { context, _ in
                let bounds = CGRect(origin: .zero, size: layout.contentSize)
                let boardPath = Path(
                    roundedRect: bounds,
                    cornerRadius: max(layout.cellSize * 0.18, 6)
                )

                context.fill(boardPath, with: .color(Color(.secondarySystemBackground)))

                for row in 0..<pattern.height {
                    for col in 0..<pattern.width {
                        let index = row * pattern.width + col
                        guard pattern.gridData.indices.contains(index) else { continue }

                        let cellRect = layout.cellRect(row: row, col: col)
                        let cellPath = Path(cellRect)
                        let fillColor = PatternSheetPalette.pixelColor(
                            for: pattern.gridData[index],
                            row: row,
                            col: col
                        )

                        context.fill(cellPath, with: .color(fillColor))
                    }
                }

                var gridPath = Path()
                for row in 0...pattern.height {
                    let y = CGFloat(row) * layout.cellSize
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: layout.contentSize.width, y: y))
                }

                for col in 0...pattern.width {
                    let x = CGFloat(col) * layout.cellSize
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: layout.contentSize.height))
                }

                context.stroke(
                    gridPath,
                    with: .color(Color.black.opacity(0.12)),
                    lineWidth: max(layout.cellSize * 0.04, 0.5)
                )
            }
            .frame(width: layout.contentSize.width, height: layout.contentSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MarketplacePattern: Identifiable, Hashable {
    let id: String
    let name: String
    let author: String
    let description: String?
    let thumbnailURL: URL?
    let downloadCount: Int
    let width: Int
    let height: Int
    let gridData: [Int]

    init?(dictionary: [String: Any]) {
        guard let name = dictionary.string(for: ["name", "title"]),
              let width = dictionary.int(for: ["width", "columns", "cols"]),
              let height = dictionary.int(for: ["height", "rows"]),
              let gridData = dictionary.intArray(for: ["gridData", "grid_data", "grid", "cells"]),
              gridData.count == width * height else {
            return nil
        }

        self.id = dictionary.string(for: ["id", "slug"]) ?? "\(name)-\(width)x\(height)-\(gridData.hashValue)"
        self.name = name
        self.author = dictionary.string(for: ["author", "creator", "username"]) ?? "Unknown Creator"
        self.description = dictionary.string(for: ["description", "summary", "details"])
        self.thumbnailURL = dictionary.url(for: ["thumbnailURL", "thumbnailUrl", "thumbnail", "imageURL", "imageUrl", "image"])
        self.downloadCount = dictionary.int(for: ["downloadCount", "download_count", "downloads"]) ?? 0
        self.width = width
        self.height = height
        self.gridData = gridData
    }
}

@MainActor
private final class MarketplaceViewModel: ObservableObject {
    @Published private(set) var state: MarketplaceState = .idle

    private let client = MarketplaceClient()

    func loadIfNeeded() async {
        guard case .idle = state else { return }
        await reload()
    }

    func reload() async {
        state = .loading

        do {
            let patterns = try await client.fetchPatterns()
            state = patterns.isEmpty ? .empty : .loaded(patterns)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

private enum MarketplaceState {
    case idle
    case loading
    case loaded([MarketplacePattern])
    case empty
    case failed(String)
}

private struct MarketplaceClient {
    private let url = URL(string: "https://raw.githubusercontent.com/kazecreator/bead-maker/main/patterns.json")!

    func fetchPatterns() async throws -> [MarketplacePattern] {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw MarketplaceError.invalidResponse
        }

        return try MarketplaceParser.parsePatterns(from: data)
    }
}

private enum MarketplaceParser {
    static func parsePatterns(from data: Data) throws -> [MarketplacePattern] {
        let rootObject = try JSONSerialization.jsonObject(with: data)

        let rawPatterns: [[String: Any]]
        if let array = rootObject as? [[String: Any]] {
            rawPatterns = array
        } else if let dictionary = rootObject as? [String: Any] {
            rawPatterns = dictionary.dictionaryArray(for: ["patterns", "items", "featured", "data"]) ?? []
        } else {
            rawPatterns = []
        }

        return rawPatterns.compactMap(MarketplacePattern.init(dictionary:))
    }
}

private enum MarketplaceError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The marketplace returned an invalid response."
        }
    }
}

private extension Dictionary where Key == String, Value == Any {
    func string(for keys: [String]) -> String? {
        for key in keys {
            if let value = self[key] as? String, !value.isEmpty {
                return value
            }
        }
        return nil
    }

    func int(for keys: [String]) -> Int? {
        for key in keys {
            if let value = self[key] as? Int {
                return value
            }

            if let value = self[key] as? NSNumber {
                return value.intValue
            }

            if let value = self[key] as? String,
               let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    func intArray(for keys: [String]) -> [Int]? {
        for key in keys {
            if let values = self[key] as? [Int] {
                return values
            }

            if let values = self[key] as? [NSNumber] {
                return values.map(\.intValue)
            }
        }
        return nil
    }

    func url(for keys: [String]) -> URL? {
        guard let value = string(for: keys) else { return nil }
        return URL(string: value)
    }

    func dictionaryArray(for keys: [String]) -> [[String: Any]]? {
        for key in keys {
            if let value = self[key] as? [[String: Any]] {
                return value
            }

            if let value = self[key] as? [Any] {
                return value.compactMap { $0 as? [String: Any] }
            }
        }
        return nil
    }
}
