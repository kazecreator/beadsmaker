import SwiftUI

struct CreateView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore

    @State private var draftTitle: String = ""
    @State private var showClaimHint = false
    @State private var isShowingExportSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PBSectionHeader(title: "Create", subtitle: "Paint pixel bead patterns, preview them live, then export or publish.")

                    patternTitleCard
                    editorToolbar
                    editorCanvas
                    paletteStrip
                    quickActions
                }
                .padding(16)
            }
            .navigationTitle("Create")
            .background(PixelBeadsTheme.surface)
        }
        .onAppear {
            draftTitle = createStore.currentPattern.title
        }
        .onChange(of: createStore.currentPattern.title) { _, newValue in
            draftTitle = newValue
        }
        .sheet(isPresented: $isShowingExportSheet) {
            ExportSheet(pattern: createStore.currentPattern)
        }
        .alert("Claim a handle to publish", isPresented: $showClaimHint) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Guest mode still supports creating, saving drafts, and exporting. Publishing unlocks after claiming a unique handle.")
        }
        .pbScreen()
    }

    private var patternTitleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern Title")
                .font(.headline)

            TextField("Untitled Draft", text: $draftTitle)
                .textFieldStyle(.roundedBorder)
                .onChange(of: draftTitle) { _, newValue in
                    createStore.updateTitle(newValue)
                }

            HStack(spacing: 8) {
                PBChip(title: createStore.currentPattern.status.title, accent: createStore.currentPattern.status == .final)
                PBChip(title: "\(createStore.currentPattern.width)×\(createStore.currentPattern.height)")
                PBChip(title: createStore.previewMode == .bead ? "Bead Preview" : "Pixel Preview")
            }
        }
        .pbCard()
    }

    private var editorToolbar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Editor")
                    .font(.headline)
                Spacer()
                Picker("Preview", selection: $createStore.previewMode) {
                    Text("Pixel").tag(PreviewMode.pixel)
                    Text("Bead").tag(PreviewMode.bead)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }

            HStack(spacing: 10) {
                ForEach(EditorTool.allCases) { tool in
                    Button {
                        createStore.selectedTool = tool
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tool.systemImage)
                                .font(.headline)
                            Text(tool.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(createStore.selectedTool == tool ? Color.white : PixelBeadsTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(createStore.selectedTool == tool ? PixelBeadsTheme.ink : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                                .stroke(createStore.selectedTool == tool ? PixelBeadsTheme.ink : PixelBeadsTheme.outline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                editorIconButton(title: "Undo", systemImage: "arrow.uturn.backward", enabled: createStore.canUndo, action: createStore.undo)
                editorIconButton(title: "Redo", systemImage: "arrow.uturn.forward", enabled: createStore.canRedo, action: createStore.redo)
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: createStore.selectedColorHex))
                        .frame(width: 18, height: 18)
                    Text(createStore.selectedColorHex)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .pbCard()
    }

    private var editorCanvas: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(createStore.selectedTool == .eyedropper ? "Tap a cell to pick its color." : "Drag across the grid to draw.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            PixelEditorCanvas(pattern: createStore.currentPattern, previewMode: createStore.previewMode) { phase in
                switch phase {
                case .began:
                    createStore.beginStroke()
                case .changed(let x, let y):
                    createStore.dragCell(x: x, y: y)
                case .ended:
                    createStore.endStroke()
                }
            }
            .frame(height: 360)

            PatternThumbnail(pattern: createStore.currentPattern, mode: createStore.previewMode, height: 180)
        }
        .pbCard()
    }

    private var paletteStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Palette")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(createStore.currentPattern.palette, id: \.self) { hex in
                        Button {
                            createStore.selectedColorHex = hex
                            createStore.selectedTool = .brush
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 38, height: 38)
                                if createStore.selectedColorHex == hex {
                                    Circle()
                                        .stroke(PixelBeadsTheme.ink, lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .pbCard()
    }

    private var quickActions: some View {
        VStack(spacing: 12) {
            Button {
                createStore.saveDraft(user: sessionStore.currentUser)
                libraryStore.load(for: sessionStore.currentUser)
            } label: {
                Label("Save Draft", systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                isShowingExportSheet = true
            } label: {
                Label("Export PNG", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(SecondaryButtonStyle())

            NavigationLink {
                PreviewView(sessionStore: sessionStore, createStore: createStore, libraryStore: libraryStore)
            } label: {
                Label("Open Preview", systemImage: "sparkles.rectangle.stack")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button {
                let didPublish = createStore.publishAndFinalize(user: sessionStore.currentUser)
                libraryStore.load(for: sessionStore.currentUser)
                showClaimHint = !didPublish
            } label: {
                Label("Publish Pattern", systemImage: "paperplane")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func editorIconButton(title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(!enabled)
        .frame(maxWidth: 120)
    }
}

private enum PixelEditorGesturePhase {
    case began
    case changed(Int, Int)
    case ended
}

private struct PixelEditorCanvas: View {
    let pattern: Pattern
    let previewMode: PreviewMode
    let onGesturePhase: (PixelEditorGesturePhase) -> Void

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            Canvas { context, size in
                let cellWidth = size.width / CGFloat(pattern.width)
                let cellHeight = size.height / CGFloat(pattern.height)
                let colorMap = Dictionary(uniqueKeysWithValues: pattern.pixels.map { ("\($0.x)-\($0.y)", $0.colorHex) })

                for row in 0..<pattern.height {
                    for column in 0..<pattern.width {
                        let rect = CGRect(x: CGFloat(column) * cellWidth, y: CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
                        let hex = colorMap["\(column)-\(row)"] ?? nil
                        let fillColor = hex.flatMap(Color.init(hex:)) ?? PixelBeadsTheme.surface

                        switch previewMode {
                        case .pixel, .comparison:
                            context.fill(Path(rect), with: .color(fillColor))
                        case .bead:
                            context.fill(Path(rect), with: .color(Color.white))
                            context.fill(Path(ellipseIn: rect.insetBy(dx: cellWidth * 0.12, dy: cellHeight * 0.12)), with: .color(fillColor))
                            context.fill(
                                Path(ellipseIn: CGRect(x: rect.minX + cellWidth * 0.28, y: rect.minY + cellHeight * 0.2, width: cellWidth * 0.2, height: cellHeight * 0.2)),
                                with: .color(Color.white.opacity(0.45))
                            )
                        }

                        context.stroke(Path(rect), with: .color(Color.black.opacity(0.08)), lineWidth: 0.6)
                    }
                }
            }
            .frame(width: side, height: side)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous)
                    .stroke(PixelBeadsTheme.outline, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            onGesturePhase(.began)
                        }
                        if let cell = cell(at: value.location, side: side) {
                            onGesturePhase(.changed(cell.x, cell.y))
                        }
                    }
                    .onEnded { _ in
                        guard isDragging else { return }
                        isDragging = false
                        onGesturePhase(.ended)
                    }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private func cell(at location: CGPoint, side: CGFloat) -> (x: Int, y: Int)? {
        guard side > 0 else { return nil }
        let cellWidth = side / CGFloat(pattern.width)
        let cellHeight = side / CGFloat(pattern.height)
        let x = min(max(Int(location.x / cellWidth), 0), pattern.width - 1)
        let y = min(max(Int(location.y / cellHeight), 0), pattern.height - 1)
        return (x, y)
    }
}
