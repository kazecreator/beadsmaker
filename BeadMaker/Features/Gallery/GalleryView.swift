import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct GalleryView: View {
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Query(sort: \CollectedPattern.modifiedAt, order: .reverse) private var collectedPatterns: [CollectedPattern]
    @Environment(\.modelContext) private var modelContext
    var onSelectPattern: (Pattern) -> Void

    @State private var searchText = ""
    @State private var showNewSheet = false
    @State private var patternToDelete: Pattern?
    @State private var collectedPatternToDelete: CollectedPattern?
    @State private var showDeletePatternAlert = false
    @State private var showDeleteCollectedAlert = false
    @State private var showImportSheet = false
    @State private var showScannerSheet = false
    @State private var importErrorMessage = ""
    @State private var showImportError = false
    @State private var isImportingPhoto = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    private var filteredPatterns: [Pattern] {
        searchText.isEmpty ? patterns : patterns.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredCollectedPatterns: [CollectedPattern] {
        searchText.isEmpty ? collectedPatterns : collectedPatterns.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var hasAnyContent: Bool {
        !patterns.isEmpty || !collectedPatterns.isEmpty
    }

    var body: some View {
        Group {
            if !hasAnyContent {
                ContentUnavailableView {
                    Label("没有图纸", systemImage: "square.grid.2x2")
                } description: {
                    Text("点击右上角 + 新建第一张图纸")
                } actions: {
                    Button("新建图纸") { showNewSheet = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if !filteredCollectedPatterns.isEmpty {
                            collectedSection
                        }

                        if !filteredPatterns.isEmpty {
                            editableSection
                        }
                    }
                    .padding(16)
                }
                .searchable(text: $searchText, prompt: "搜索图纸")
            }
        }
        .navigationTitle("My Patterns")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showNewSheet = true
                    } label: {
                        Label("New Pattern", systemImage: "square.and.pencil")
                    }

                    Button {
                        showImportSheet = true
                    } label: {
                        Label("Import from Photos", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        showScannerSheet = true
                    } label: {
                        Label("Import from QR Code", systemImage: "qrcode.viewfinder")
                    }
                } label: {
                    Image(systemName: "plus")
                }
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
        .sheet(isPresented: $showImportSheet) {
            ImportPatternSheet { name, width, height, item in
                Task {
                    await importPhoto(item, name: name, width: width, height: height)
                }
            }
        }
        .sheet(isPresented: $showScannerSheet) {
            NavigationStack {
                ScannerView {
                    showScannerSheet = false
                }
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
        .alert("移出收藏", isPresented: $showDeleteCollectedAlert, presenting: collectedPatternToDelete) { pattern in
            Button("移出", role: .destructive) {
                modelContext.delete(pattern)
                try? modelContext.save()
            }
            Button("取消", role: .cancel) {}
        } message: { pattern in
            Text("确定要将「\(pattern.name)」移出外部图纸吗？")
        }
        .alert("导入失败", isPresented: $showImportError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .overlay {
            if isImportingPhoto {
                ZStack {
                    Color.black.opacity(0.18)
                        .ignoresSafeArea()
                    ProgressView("正在导入照片…")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private var collectedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("外部图纸")
                .font(.headline)
                .padding(.horizontal, 2)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredCollectedPatterns) { pattern in
                    PatternCardView(
                        name: pattern.name,
                        width: pattern.width,
                        height: pattern.height,
                        thumbnailData: pattern.thumbnailData,
                        isCollected: true
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let copy = duplicate(collected: pattern)
                        onSelectPattern(copy)
                    }
                    .contextMenu {
                        Button {
                            let copy = duplicate(collected: pattern)
                            onSelectPattern(copy)
                        } label: {
                            Label("创建副本", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) {
                            collectedPatternToDelete = pattern
                            showDeleteCollectedAlert = true
                        } label: {
                            Label("移出外部图纸", systemImage: "bookmark.slash")
                        }
                    }
                }
            }
        }
    }

    private var editableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的图纸")
                .font(.headline)
                .padding(.horizontal, 2)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filteredPatterns) { pattern in
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
                        Button {
                            addToCollection(pattern)
                        } label: {
                            Label("存为外部图纸", systemImage: "bookmark")
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

    @discardableResult
    private func duplicate(collected pattern: CollectedPattern) -> Pattern {
        let copy = Pattern(name: "\(pattern.name) 副本", width: pattern.width, height: pattern.height)
        copy.gridData = pattern.gridData
        copy.thumbnailData = pattern.thumbnailData
        modelContext.insert(copy)
        try? modelContext.save()
        return copy
    }

    private func addToCollection(_ pattern: Pattern) {
        guard let signature = try? PatternCodec.collectionSignature(
            width: pattern.width,
            height: pattern.height,
            gridData: pattern.gridData
        ) else { return }

        guard !collectedPatterns.contains(where: { $0.signature == signature }) else { return }

        let collected = CollectedPattern(
            name: pattern.name,
            width: pattern.width,
            height: pattern.height,
            gridData: pattern.gridData,
            thumbnailData: pattern.thumbnailData ?? PatternRenderer.thumbnail(pattern: pattern).pngData(),
            signature: signature
        )
        modelContext.insert(collected)
        try? modelContext.save()
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem, name: String, width: Int, height: Int) async {
        isImportingPhoto = true
        defer { isImportingPhoto = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ImageImporterError.invalidImage
            }

            let gridData = try ImageImporter.makePattern(
                from: image,
                targetWidth: width,
                targetHeight: height
            )

            let pattern = Pattern(name: name, width: width, height: height)
            pattern.gridData = gridData
            pattern.thumbnailData = PatternRenderer.thumbnail(pattern: pattern).pngData()

            modelContext.insert(pattern)
            try? modelContext.save()
            onSelectPattern(pattern)
        } catch {
            importErrorMessage = error.localizedDescription
            showImportError = true
        }
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

private struct ImportPatternSheet: View {
    var onImport: (String, Int, Int, PhotosPickerItem) -> Void

    @State private var name = "照片导入"
    @State private var selectedPreset = 1
    @State private var customWidth = 20
    @State private var customHeight = 20
    @State private var selectedPhoto: PhotosPickerItem?
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
                        ForEach(0..<presets.count, id: \.self) { index in
                            Text(presets[index].0).tag(index)
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

                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("选择照片", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Import from Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            onImport(name.isEmpty ? "照片导入" : name, width, height, item)
            dismiss()
        }
    }
}
