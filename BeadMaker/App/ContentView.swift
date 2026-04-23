import SwiftUI
import SwiftData

enum FinishedDetailEntryMode: String, Hashable {
    case direct
    case ironing
}

struct PatternViewerPayload: Hashable {
    let title: String
    let width: Int
    let height: Int
    let gridData: [Int]
}

enum GalleryRoute: Hashable {
    case editor(PersistentIdentifier)
    case favoriteDetail(PersistentIdentifier)
    case finishedDetail(PersistentIdentifier, FinishedDetailEntryMode)
    case patternViewer(PatternViewerPayload)
}

final class GalleryNavigationModel: ObservableObject {
    @Published var selectedTab = 0
    @Published var path: [GalleryRoute] = []

    func openEditor(_ patternID: PersistentIdentifier) {
        selectedTab = 0
        path.append(.editor(patternID))
    }

    func openFavoriteDetail(_ favoriteID: PersistentIdentifier) {
        selectedTab = 0
        path.append(.favoriteDetail(favoriteID))
    }

    func openFinishedDetail(_ finishedPatternID: PersistentIdentifier, entryMode: FinishedDetailEntryMode = .direct) {
        selectedTab = 0
        path.append(.finishedDetail(finishedPatternID, entryMode))
    }

    func replaceTopWithFinishedDetail(_ finishedPatternID: PersistentIdentifier, entryMode: FinishedDetailEntryMode) {
        selectedTab = 0

        if !path.isEmpty {
            path.removeLast()
        }

        path.append(.finishedDetail(finishedPatternID, entryMode))
    }

    func openPatternViewer(title: String, width: Int, height: Int, gridData: [Int]) {
        path.append(.patternViewer(.init(title: title, width: width, height: height, gridData: gridData)))
    }
}

struct ContentView: View {
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Query(sort: \FinishedPattern.modifiedAt, order: .reverse) private var finishedPatterns: [FinishedPattern]
    @Query(sort: \CollectedPattern.modifiedAt, order: .reverse) private var collectedPatterns: [CollectedPattern]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppConstants.appleUserIDKey) private var appleUserID = ""
    @StateObject private var navigationModel = GalleryNavigationModel()

    private var isAdmin: Bool {
        !appleUserID.isEmpty && appleUserID == AppConstants.adminAppleID
    }

    var body: some View {
        TabView(selection: $navigationModel.selectedTab) {
            NavigationStack(path: $navigationModel.path) {
                GalleryView { pattern in
                    navigationModel.openEditor(pattern.persistentModelID)
                }
                .navigationDestination(for: GalleryRoute.self) { route in
                    routeDestination(for: route)
                }
            }
            .environmentObject(navigationModel)
            .tag(0)
            .tabItem { Label("图纸", systemImage: "square.grid.2x2.fill") }

            NavigationStack {
                MarketplaceView()
            }
            .tag(1)
            .tabItem { Label("市集", systemImage: "bag.fill") }

            NavigationStack {
                ProfileView()
            }
            .tag(2)
            .tabItem { Label("我的", systemImage: "person.crop.circle") }

            if isAdmin {
                NavigationStack {
                    ModerationView()
                }
                .tag(3)
                .tabItem { Label("审核", systemImage: "checkmark.shield") }
            }
        }
        .onAppear {
            repairStoredData()
        }
        .onChange(of: patterns.map(\.persistentModelID)) { _, _ in
            repairStoredData()
        }
    }

    private func repairStoredData() {
        var didChange = false

        if profiles.isEmpty {
            let profile = UserProfile()
            modelContext.insert(profile)
            didChange = true
        }

        for pattern in patterns {
            let renderedThumbnail = PatternRenderer.thumbnail(pattern: pattern).pngData()
            if pattern.thumbnailData != renderedThumbnail {
                pattern.thumbnailData = renderedThumbnail
                didChange = true
            }
        }

        for finished in finishedPatterns {
            let preview = Pattern(name: finished.name, width: finished.width, height: finished.height)
            preview.gridData = finished.gridData
            let renderedThumbnail = PatternRenderer.ironedThumbnail(pattern: preview).pngData()
            if finished.thumbnailData != renderedThumbnail {
                finished.thumbnailData = renderedThumbnail
                didChange = true
            }
        }

        for favorite in collectedPatterns {
            let preview = Pattern(name: favorite.name, width: favorite.width, height: favorite.height)
            preview.gridData = favorite.gridData
            let renderedThumbnail = PatternRenderer.ironedThumbnail(pattern: preview).pngData()
            if favorite.thumbnailData != renderedThumbnail {
                favorite.thumbnailData = renderedThumbnail
                didChange = true
            }

            if favorite.author.isEmpty {
                favorite.author = "未知作者"
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }

    @ViewBuilder
    private func routeDestination(for route: GalleryRoute) -> some View {
        switch route {
        case .editor(let patternID):
            EditorView(patternID: patternID)
                .toolbar(.hidden, for: .tabBar)
        case .favoriteDetail(let favoriteID):
            FavoriteDetailDestinationView(favoriteID: favoriteID)
        case .finishedDetail(let patternID, let entryMode):
            FinishedDetailDestinationView(patternID: patternID, entryMode: entryMode)
        case .patternViewer(let payload):
            PatternViewerScreen(
                title: payload.title,
                width: payload.width,
                height: payload.height,
                gridData: payload.gridData
            )
        }
    }
}

private struct FavoriteDetailDestinationView: View {
    let favoriteID: PersistentIdentifier

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let favorite = modelContext.model(for: favoriteID) as? CollectedPattern {
            FavoriteDetailView(favorite: favorite)
        } else {
            ContentUnavailableView("收藏不可用", systemImage: "heart.slash")
        }
    }
}

private struct FinishedDetailDestinationView: View {
    let patternID: PersistentIdentifier
    let entryMode: FinishedDetailEntryMode

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if let pattern = modelContext.model(for: patternID) as? FinishedPattern {
            FinishedPatternDetailView(
                pattern: pattern,
                entryMode: entryMode == .ironing ? .ironing : .direct
            )
        } else {
            ContentUnavailableView("成品不可用", systemImage: "sparkles.square.filled.on.square")
        }
    }
}
