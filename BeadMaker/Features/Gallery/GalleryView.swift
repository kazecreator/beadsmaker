import SwiftUI
import SwiftData

struct GalleryView: View {
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Query(sort: \FinishedPattern.modifiedAt, order: .reverse) private var finishedPatterns: [FinishedPattern]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationModel: GalleryNavigationModel
    var onSelectPattern: (Pattern) -> Void

    @AppStorage("gallery.selectedSegment") private var selectedSegment = 0
    @AppStorage("gallery.pendingFinishedSourcePatternID") private var pendingFinishedSourcePatternID = ""
    @State private var searchText = ""
    @State private var showNewSheet = false
    @State private var patternToDelete: Pattern?
    @State private var showDeletePatternAlert = false
    @State private var showScannerSheet = false
    @State private var toastMessage: String?
    @State private var showToast = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    private var ironedSourceIDs: Set<String> {
        Set(finishedPatterns.compactMap(\.sourcePatternID))
    }

    private var visibleEditablePatterns: [Pattern] {
        patterns.filter { !ironedSourceIDs.contains(String(describing: $0.persistentModelID)) }
    }

    private var filteredEditablePatterns: [Pattern] {
        searchText.isEmpty ? visibleEditablePatterns : visibleEditablePatterns.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredFinishedPatterns: [FinishedPattern] {
        searchText.isEmpty ? finishedPatterns : finishedPatterns.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedSegment) {
                Text("我的图纸").tag(0)
                Text("收藏").tag(1)
                Text("成品").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Group {
                if selectedSegment == 0 {
                    myPatternsContent
                } else if selectedSegment == 1 {
                    FavoritesView(
                        searchText: searchText,
                        onSelectFavorite: {
                            navigationModel.openFavoriteDetail($0.persistentModelID)
                        },
                        onCreateCopy: handleFavoriteCopy
                    )
                } else {
                    finishedPatternsContent
                }
            }
        }
        .searchable(text: $searchText, prompt: searchPrompt)
        .navigationTitle("图纸")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                galleryMenu
            }
        }
        .sheet(isPresented: $showNewSheet) {
            NewPatternSheet { name, width, height in
                let pattern = Pattern(name: name, width: width, height: height)
                modelContext.insert(pattern)
                try? modelContext.save()
                showNewSheet = false
                onSelectPattern(pattern)
            }
        }
        .sheet(isPresented: $showScannerSheet) {
            NavigationStack {
                ScannerView(onSavedToGallery: {
                    showScannerSheet = false
                }, onFavoriteSaved: { message in
                    showScannerSheet = false
                    selectedSegment = 1
                    presentToast(message)
                })
            }
        }
        .alert("删除图纸", isPresented: $showDeletePatternAlert, presenting: patternToDelete) { pattern in
            Button("删除", role: .destructive) {
                modelContext.delete(pattern)
                try? modelContext.save()
            }
            Button("取消", role: .cancel) {}
        } message: { pattern in
            Text("确定要删除「\(pattern.name)」吗？此操作无法撤销。")
        }
        .overlay(alignment: .bottom) {
            if showToast, let toastMessage {
                Text(toastMessage)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear(perform: openPendingFinishedIfNeeded)
        .onChange(of: finishedPatterns.map(\.persistentModelID)) { _, _ in
            openPendingFinishedIfNeeded()
        }
    }

    private var myPatternsContent: some View {
        Group {
            if visibleEditablePatterns.isEmpty {
                ContentUnavailableView {
                    Label("没有图纸", systemImage: "square.grid.2x2")
                } description: {
                    Text("点击右上角 + 新建第一张图纸")
                } actions: {
                    Button("新建图纸") { showNewSheet = true }
                        .buttonStyle(.borderedProminent)
                }
            } else if filteredEditablePatterns.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView {
                    editableSection(patterns: filteredEditablePatterns)
                        .padding(16)
                }
            }
        }
    }

    private var finishedPatternsContent: some View {
        Group {
            if finishedPatterns.isEmpty {
                ContentUnavailableView {
                    Label("还没有成品", systemImage: "sparkles.square.filled.on.square")
                } description: {
                    Text("在编辑页点击“熨烫”，就会在这里看到成品")
                }
            } else if filteredFinishedPatterns.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                FinishedPatternsView(
                    patterns: filteredFinishedPatterns,
                    onSelect: {
                        navigationModel.openFinishedDetail($0.persistentModelID, entryMode: .direct)
                    },
                    onCreateCopy: handleFinishedCopy
                )
            }
        }
    }

    private var galleryMenu: some View {
        Menu {
            Button {
                showNewSheet = true
            } label: {
                Label("新建图纸", systemImage: "square.and.pencil")
            }

            Button {
                showScannerSheet = true
            } label: {
                Label("扫码加入收藏", systemImage: "qrcode.viewfinder")
            }
        } label: {
            Image(systemName: "plus")
        }
    }

    private func editableSection(patterns: [Pattern]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(patterns) { pattern in
                    PatternCardView(
                        name: pattern.name,
                        width: pattern.width,
                        height: pattern.height,
                        thumbnailData: pattern.thumbnailData,
                        isCollected: false
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onSelectPattern(pattern) }
                    .contextMenu {
                        Button {
                            let copy = duplicate(pattern)
                            onSelectPattern(copy)
                        } label: {
                            Label("复制", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) {
                            patternToDelete = pattern
                            showDeletePatternAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    private func duplicate(_ pattern: Pattern) -> Pattern {
        let copy = Pattern(name: "\(pattern.name) 副本", width: pattern.width, height: pattern.height)
        copy.gridData = pattern.gridData
        copy.thumbnailData = pattern.thumbnailData
        modelContext.insert(copy)
        try? modelContext.save()
        return copy
    }

    private func handleFavoriteCopy(_ pattern: Pattern) {
        selectedSegment = 0

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            onSelectPattern(pattern)
        }
    }

    private func handleFinishedCopy(_ pattern: Pattern) {
        selectedSegment = 0
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            onSelectPattern(pattern)
        }
    }

    private func presentToast(_ message: String) {
        toastMessage = message

        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.6))
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showToast = false
                }
            }
        }
    }

    private var searchPrompt: String {
        switch selectedSegment {
        case 1:
            return "搜索收藏"
        case 2:
            return "搜索成品"
        default:
            return "搜索我的图纸"
        }
    }

    private func openPendingFinishedIfNeeded() {
        guard selectedSegment == 2, !pendingFinishedSourcePatternID.isEmpty else { return }
        guard let target = finishedPatterns.first(where: { $0.sourcePatternID == pendingFinishedSourcePatternID }) else { return }

        pendingFinishedSourcePatternID = ""
        navigationModel.openFinishedDetail(target.persistentModelID, entryMode: .ironing)
    }
}

private struct NewPatternSheet: View {
    var onCreate: (String, Int, Int) -> Void

    @State private var name = "新图纸"
    @State private var selectedPreset = 0
    @State private var customWidth = 20
    @State private var customHeight = 20
    @Environment(\.dismiss) private var dismiss

    private let presets: [(String, Int, Int)] = [
        ("小方板 15×15", 15, 15),
        ("大方板 29×29", 29, 29),
        ("自定义", 0, 0),
    ]

    private var width: Int { selectedPreset == 2 ? customWidth : presets[selectedPreset].1 }
    private var height: Int { selectedPreset == 2 ? customHeight : presets[selectedPreset].2 }

    var body: some View {
        NavigationStack {
            Form {
                Section("图纸名称") {
                    TextField("名称", text: $name)
                }

                Section("尺寸") {
                    Picker("板型", selection: $selectedPreset) {
                        ForEach(0..<presets.count, id: \.self) { i in
                            Text(presets[i].0).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedPreset == 2 {
                        Stepper("宽度：\(customWidth)", value: $customWidth, in: 5...100)
                        Stepper("高度：\(customHeight)", value: $customHeight, in: 5...100)
                    }
                }

                Section {
                    Text("画布大小：\(width) × \(height) = \(width * height) 颗")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("新建图纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("创建") {
                        onCreate(name.isEmpty ? "新图纸" : name, width, height)
                    }
                    .bold()
                }
            }
        }
    }
}
