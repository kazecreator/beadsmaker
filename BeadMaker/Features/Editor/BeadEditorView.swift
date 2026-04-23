import SwiftUI
import SwiftData

private struct EditorPatternSnapshot: Equatable {
    let name: String
    let width: Int
    let height: Int
    let gridData: [Int]

    var isEmpty: Bool {
        gridData.allSatisfy { $0 == 0 }
    }
}

struct BeadEditorView: View {
    let patternID: PersistentIdentifier

    @State private var viewModel: EditorViewModel
    @State private var colorPanelExpanded = false
    @State private var showStats = false
    @State private var showShare = false
    @State private var showRenameAlert = false
    @State private var showEmptyPatternAlert = false
    @State private var showIroningConfirmAlert = false
    @State private var pendingName = ""

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navigationModel: GalleryNavigationModel
    @AppStorage("gallery.selectedSegment") private var selectedGallerySegment = 0

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
                editorContent(pattern: pattern)
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
            ToolbarItem(placement: .topBarTrailing) {
                Button { showStats = true } label: {
                    Image(systemName: "chart.bar")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring()) {
                        colorPanelExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "paintpalette")
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
        .alert("请先绘制图案", isPresented: $showEmptyPatternAlert) {
            Button("知道了", role: .cancel) {}
        }
        .alert("确认熨烫", isPresented: $showIroningConfirmAlert) {
            Button("取消", role: .cancel) {}
            Button("开始熨烫") {
                if let pattern {
                    beginIroning(for: pattern)
                }
            }
        } message: {
            Text("确认后会生成成品，并进入成品详情。")
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
    }

    @ViewBuilder
    private func editorContent(pattern: Pattern) -> some View {
        VStack(spacing: 0) {
            ToolbarView(
                viewModel: viewModel,
                onUndo: { viewModel.undo(on: pattern) },
                onRedo: { viewModel.redo(on: pattern) },
                onComplete: { handleIroningRequest(for: pattern) }
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
    }

    private func handleIroningRequest(for pattern: Pattern) {
        let snapshot = EditorPatternSnapshot(
            name: pattern.name,
            width: pattern.width,
            height: pattern.height,
            gridData: pattern.gridData
        )

        guard !snapshot.isEmpty else {
            showEmptyPatternAlert = true
            return
        }

        showIroningConfirmAlert = true
    }

    private func beginIroning(for pattern: Pattern) {
        if colorPanelExpanded {
            colorPanelExpanded = false
        }

        let finishedPattern = FinishedPattern(
            name: pattern.name,
            width: pattern.width,
            height: pattern.height,
            gridData: pattern.gridData,
            sourcePatternID: String(describing: pattern.persistentModelID)
        )
        finishedPattern.modifiedAt = Date()

        let previewPattern = Pattern(name: pattern.name, width: pattern.width, height: pattern.height)
        previewPattern.gridData = pattern.gridData
        let thumbnailImage = PatternRenderer.ironedThumbnail(pattern: previewPattern)
        let thumbnailData = thumbnailImage.pngData()
        finishedPattern.thumbnailData = thumbnailData

        modelContext.insert(finishedPattern)
        viewModel.updateThumbnail(for: pattern)
        try? modelContext.save()

        selectedGallerySegment = 2
        navigationModel.replaceTopWithFinishedDetail(finishedPattern.persistentModelID, entryMode: .ironing)
    }
}
