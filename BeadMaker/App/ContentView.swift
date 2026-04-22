import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @State private var activePatternID: PersistentIdentifier?
    @State private var selectedTab = 1

    private var activePattern: Pattern? {
        guard let activePatternID else { return nil }
        return patterns.first { $0.persistentModelID == activePatternID }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Editor tab
            NavigationStack {
                if let activePatternID {
                    EditorView(patternID: activePatternID)
                        .id(activePatternID)
                } else {
                    ContentUnavailableView {
                        Label("没有打开的图纸", systemImage: "pencil.and.ruler")
                    } description: {
                        Text("从「我的图纸」中选择或新建一张图纸")
                    } actions: {
                        Button("新建图纸") {
                            createDefault()
                            selectedTab = 0
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .tag(0)
            .tabItem { Label("编辑器", systemImage: "pencil.and.ruler") }

            // Gallery tab
            NavigationStack {
                GalleryView { pattern in
                    activePatternID = pattern.persistentModelID
                    selectedTab = 0
                }
            }
            .tag(1)
            .tabItem { Label("我的图纸", systemImage: "square.grid.2x2.fill") }

            // Scanner tab
            NavigationStack {
                ScannerView {
                    selectedTab = 1
                }
            }
            .tag(2)
            .tabItem { Label("扫码导入", systemImage: "qrcode.viewfinder") }

            // Profile tab
            NavigationStack {
                ProfileView()
            }
            .tag(3)
            .tabItem { Label("我的", systemImage: "person.circle.fill") }
        }
        .onAppear {
            syncActivePatternSelection()
            repairStoredData()
        }
        .onChange(of: patterns.map(\.persistentModelID)) { _, _ in
            syncActivePatternSelection()
            repairStoredData()
        }
    }

    private func createDefault() {
        let p = Pattern(name: "新图纸", width: 15, height: 15)
        modelContext.insert(p)
        try? modelContext.save()
        activePatternID = p.persistentModelID
    }

    private func syncActivePatternSelection() {
        if let activePatternID, patterns.contains(where: { $0.persistentModelID == activePatternID }) {
            return
        }
        activePatternID = patterns.first?.persistentModelID
    }

    private func repairStoredData() {
        var didChange = false

        if profiles.isEmpty {
            let profile = UserProfile()
            modelContext.insert(profile)
            didChange = true
        }

        for pattern in patterns {
            if pattern.thumbnailData == nil {
                pattern.thumbnailData = PatternRenderer.thumbnail(pattern: pattern).pngData()
                didChange = true
            }
        }

        if didChange {
            try? modelContext.save()
        }
    }
}
