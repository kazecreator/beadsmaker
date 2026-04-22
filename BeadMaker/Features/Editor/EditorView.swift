import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct EditorView: View {
    let patternID: PersistentIdentifier
    @State private var viewModel: EditorViewModel
    @State private var colorPanelExpanded = false
    @State private var showStats = false
    @State private var showShare = false
    @State private var showRenameAlert = false
    @State private var pendingName = ""
    @State private var selectedImportPhoto: PhotosPickerItem?
    @State private var importErrorMessage = ""
    @State private var showImportError = false
    @State private var isImportingPhoto = false
    @Environment(\.modelContext) private var modelContext

    init(patternID: PersistentIdentifier) {
        self.patternID = patternID
        self._viewModel = State(wrappedValue: EditorViewModel())
    }

    private var pattern: Pattern? {
        modelContext.model(for: patternID) as? Pattern
    }

    var body: some View {
        Group {
            if let pattern {
                VStack(spacing: 0) {
                    ToolbarView(
                        viewModel: viewModel,
                        onUndo: { viewModel.undo(on: pattern) },
                        onRedo: { viewModel.redo(on: pattern) }
                    )
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

                    ZStack(alignment: .bottom) {
                        CanvasView(pattern: pattern, viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if colorPanelExpanded {
                            ColorPanelView(
                                viewModel: viewModel,
                                isExpanded: $colorPanelExpanded,
                                onColorSelected: {
                                    withAnimation(.spring()) {
                                        colorPanelExpanded = false
                                    }
                                }
                            )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
            } else {
                ContentUnavailableView("图纸不可用", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(pattern?.name ?? "图纸")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    pendingName = pattern?.name ?? ""
                    showRenameAlert = true
                } label: {
                    Image(systemName: "pencil.line")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                PhotosPicker(selection: $selectedImportPhoto, matching: .images) {
                    Image(systemName: "photo")
                }
                .disabled(isImportingPhoto)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showStats = true } label: {
                    Image(systemName: "chart.bar.fill")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring()) {
                        colorPanelExpanded.toggle()
                    }
                } label: {
                    Image(systemName: colorPanelExpanded ? "paintpalette.fill" : "paintpalette")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showShare = true } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showStats) {
            if let pattern {
                BeadStatsView(pattern: pattern)
            }
        }
        .sheet(isPresented: $showShare, onDismiss: {
            if let pattern {
                viewModel.updateThumbnail(for: pattern)
            }
            try? modelContext.save()
        }) {
            if let pattern {
                ShareView(pattern: pattern)
            }
        }
        .alert("重命名图纸", isPresented: $showRenameAlert) {
            TextField("图纸名称", text: $pendingName)
            Button("确定") {
                if let pattern,
                   !pendingName.trimmingCharacters(in: .whitespaces).isEmpty {
                    pattern.name = pendingName
                    try? modelContext.save()
                }
            }
            Button("取消", role: .cancel) {}
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
                    ProgressView("正在生成拼豆图纸…")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .onDisappear {
            if let pattern {
                viewModel.updateThumbnail(for: pattern)
            }
            try? modelContext.save()
        }
        .onAppear {
            viewModel.resetForCanvasOpen()
        }
        .onChange(of: patternID) { _, _ in
            viewModel.resetForCanvasOpen()
        }
        .onChange(of: selectedImportPhoto) { _, item in
            guard let item else { return }
            Task {
                await importPhoto(item)
            }
        }
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem) async {
        guard let pattern else { return }

        isImportingPhoto = true
        defer {
            isImportingPhoto = false
            selectedImportPhoto = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ImageImporterError.invalidImage
            }

            let gridData = try ImageImporter.makePattern(
                from: image,
                targetWidth: pattern.width,
                targetHeight: pattern.height
            )

            viewModel.applyImportedPattern(on: pattern, width: pattern.width, height: pattern.height, gridData: gridData)
            viewModel.updateThumbnail(for: pattern)
            try? modelContext.save()
        } catch {
            importErrorMessage = error.localizedDescription
            showImportError = true
        }
    }
}
