import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct GalleryView: View {
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Environment(\.modelContext) private var modelContext
    var onSelectPattern: (Pattern) -> Void

    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var showNewSheet = false
    @State private var patternToDelete: Pattern?
    @State private var showDeletePatternAlert = false
    @State private var showImportSheet = false
    @State private var showScannerSheet = false
    @State private var importErrorMessage = ""
    @State private var showImportError = false
    @State private var isImportingPhoto = false
    @State private var toastMessage: String?
    @State private var showToast = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    private var filteredPatterns: [Pattern] {
        searchText.isEmpty ? patterns : patterns.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("View", selection: $selectedSegment) {
                Text("我的图纸").tag(0)
                Text("收藏").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Group {
                if selectedSegment == 0 {
                    myPatternsContent
                } else {
                    FavoritesView(searchText: searchText, onCreateCopy: onSelectPattern)
                }
            }
        }
        .searchable(text: $searchText, prompt: selectedSegment == 0 ? "搜索我的图纸" : "搜索收藏")
        .navigationTitle("图纸")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showScannerSheet = true
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                }

                Menu {
                    Button {
                        showNewSheet = true
                    } label: {
                        Label("新建图纸", systemImage: "square.and.pencil")
                    }

                    Button {
                        showImportSheet = true
                    } label: {
                        Label("从相册导入", systemImage: "photo.on.rectangle")
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
                ScannerView(onSavedToGallery: {
                    showScannerSheet = false
                }, onFavoriteSaved: { message in
                    showScannerSheet = false
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
    }

    private var myPatternsContent: some View {
        Group {
            if patterns.isEmpty {
                ContentUnavailableView {
                    Label("没有图纸", systemImage: "square.grid.2x2")
                } description: {
                    Text("点击右上角 + 新建第一张图纸")
                } actions: {
                    Button("新建图纸") { showNewSheet = true }
                        .buttonStyle(.borderedProminent)
                }
            } else if filteredPatterns.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView {
                    editableSection
                        .padding(16)
                }
            }
        }
    }

    private var editableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
