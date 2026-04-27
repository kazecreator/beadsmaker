import Combine
import SwiftUI

struct CreateView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var proStatusManager: ProStatusManager
    @EnvironmentObject private var appleSignInManager: AppleSignInManager

    @State private var draftTitle: String = ""
    @State private var isShowingColorPicker = false
    @State private var isShowingSizePicker = false
    @State private var isToolbarExpanded = true
    @State private var isTrackPointActive = false
    @State private var isShowingResetConfirmation = false
    @State private var isShowingResizeConfirmation = false
    @State private var isShowingDraftLimitAlert = false
    @State private var isShowingEmptyPreviewAlert = false
    @State private var isShowingEmptyDraftAlert = false
    @State private var isShowingPaywall = false
    @State private var isShowingImport = false
    @State private var canvasOffset: CGSize = .zero
    @State private var canvasScale: Double = 1.0
    @State private var canvasViewportSize: CGSize = .zero
    @State private var hasInitializedCanvasPosition = false

    private let canvasSizes = [16, 20, 24, 29, 32, 48]
    private let minScale: Double = 0.5
    private let maxScale: Double = 3.0
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private func baseCellSize(width: Int, height: Int) -> CGFloat {
        let maxDimension = max(width, height)
        if maxDimension <= 20 { return 18 }
        if maxDimension <= 29 { return 14 }
        if maxDimension <= 32 { return 12 }
        return 10
    }

    private func coordinateGutter(for cellSize: CGFloat) -> CGFloat {
        min(max(cellSize * 1.35, 20), 30)
    }

    private var currentBoardSize: CGSize {
        let cellSize = baseCellSize(width: createStore.currentPattern.width, height: createStore.currentPattern.height)
        return CGSize(
            width: CGFloat(createStore.currentPattern.width) * cellSize * CGFloat(canvasScale),
            height: CGFloat(createStore.currentPattern.height) * cellSize * CGFloat(canvasScale)
        )
    }

    private var currentCanvasSize: CGSize {
        let boardSize = currentBoardSize
        let cellSize = boardSize.width / CGFloat(createStore.currentPattern.width)
        let gutter = coordinateGutter(for: cellSize)

        return CGSize(
            width: boardSize.width + gutter * 2,
            height: boardSize.height + gutter * 2
        )
    }

    private var joystickPanStep: CGFloat {
        guard canvasViewportSize.width > 0, canvasViewportSize.height > 0 else { return 2.4 }

        let canvasSize = currentCanvasSize
        let overflow = max(
            canvasSize.width - canvasViewportSize.width,
            canvasSize.height - canvasViewportSize.height,
            0
        )
        let viewportBase = max(canvasViewportSize.width, canvasViewportSize.height, 1)
        let overflowRatio = overflow / viewportBase
        let scaleProgress = CGFloat((canvasScale - minScale) / (maxScale - minScale))
        let step = 2.4 + (overflowRatio * 2.2) + (scaleProgress * 1.2)

        return min(max(step, 2.4), 8.5)
    }

    private func clampedOffset(_ offset: CGSize, viewSize: CGSize) -> CGSize {
        guard viewSize.width > 0, viewSize.height > 0 else { return offset }

        let canvasSize = currentCanvasSize
        let minVisible: CGFloat = 0.3

        let minX: CGFloat
        let maxX: CGFloat
        if canvasSize.width > viewSize.width {
            minX = viewSize.width * minVisible - canvasSize.width
            maxX = viewSize.width * (1 - minVisible)
        } else {
            minX = (viewSize.width - canvasSize.width) / 2
            maxX = minX
        }

        let minY: CGFloat
        let maxY: CGFloat
        if canvasSize.height > viewSize.height {
            minY = viewSize.height * minVisible - canvasSize.height
            maxY = viewSize.height * (1 - minVisible)
        } else {
            minY = (viewSize.height - canvasSize.height) / 2
            maxY = minY
        }

        return CGSize(
            width: min(max(offset.width, minX), maxX),
            height: min(max(offset.height, minY), maxY)
        )
    }

    private func centeredCanvasOffset(viewSize: CGSize) -> CGSize {
        let canvasSize = currentCanvasSize
        return clampedOffset(
            CGSize(
                width: (viewSize.width - canvasSize.width) / 2,
                height: (viewSize.height - canvasSize.height) / 2
            ),
            viewSize: viewSize
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    editorCard
                    editorCanvas
                    quickActions
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Create"))
            .background(PixelBeadsTheme.surface)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingImport = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .accessibilityLabel(L10n.tr("Import from QR"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let succeeded = createStore.startNewDraft(
                            user: sessionStore.currentUser,
                            library: libraryStore.content
                        )
                        if succeeded {
                            libraryStore.load(for: sessionStore.currentUser)
                        } else {
                            isShowingDraftLimitAlert = true
                        }
                    } label: {
                        Label(L10n.tr("New Draft"), systemImage: "square.and.pencil")
                    }
                }
            }
            .alert(L10n.tr("Draft Limit Reached"), isPresented: $isShowingDraftLimitAlert) {
                Button(L10n.tr("Upgrade to Pro")) {
                    isShowingPaywall = true
                }
                Button(L10n.tr("Not Now"), role: .cancel) { }
            } message: {
                Text(L10n.tr("You've reached the 20-draft limit. Delete a draft to make room, or upgrade to Pro for unlimited drafts."))
            }
            .alert(L10n.tr("Add beads before previewing"), isPresented: $isShowingEmptyPreviewAlert) {
                Button(L10n.tr("OK"), role: .cancel) { }
            } message: {
                Text(L10n.tr("Place at least one bead on the pegboard before opening Preview."))
            }
            .alert(L10n.tr("Add beads before saving"), isPresented: $isShowingEmptyDraftAlert) {
                Button(L10n.tr("OK"), role: .cancel) { }
            } message: {
                Text(L10n.tr("Place at least one bead on the pegboard before saving a draft."))
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(sessionStore: sessionStore)
                    .environmentObject(proStatusManager)
                    .environmentObject(appleSignInManager)
            }
        }
        .onAppear {
            draftTitle = createStore.currentPattern.title
        }
        .onChange(of: createStore.currentPattern.title) { _, newValue in
            draftTitle = newValue
        }
        .sheet(isPresented: $isShowingColorPicker) {
            ColorPickerSheet(selectedColorHex: $createStore.selectedColorHex) {
                createStore.selectedTool = .brush
            }
        }
        .sheet(isPresented: $isShowingSizePicker) {
            SizePickerSheet(
                currentSize: max(createStore.currentPattern.width, createStore.currentPattern.height),
                sizes: canvasSizes
            ) { newSize in
                createStore.resizeCanvas(width: newSize, height: newSize)
            }
        }
        .sheet(isPresented: $isShowingImport) {
            ImportPatternView(hasExistingDrafts: !libraryStore.content.drafts.isEmpty) { pattern in
                let remixed = createStore.remixImported(pattern)
                libraryStore.load(for: sessionStore.currentUser)
            }
        }
        .confirmationDialog(
            L10n.tr("Clear Canvas?"),
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.tr("Clear Canvas"), role: .destructive) {
                createStore.clearCanvas()
                haptic.impactOccurred()
            }
            Button(L10n.tr("Cancel"), role: .cancel) { }
        } message: {
            Text(L10n.tr("This will remove every bead from the current draft."))
        }
        .confirmationDialog(
            L10n.tr("Change Canvas Size?"),
            isPresented: $isShowingResizeConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.tr("Change Size"), role: .destructive) {
                isShowingSizePicker = true
            }
            Button(L10n.tr("Cancel"), role: .cancel) { }
        } message: {
            Text(L10n.tr("Changing size will remove beads outside the new area."))
        }
        .onChange(of: createStore.currentPattern.id) { _ in
            canvasOffset = .zero
            canvasScale = 1.0
            hasInitializedCanvasPosition = false
        }
        .pbScreen()
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                TextField(L10n.tr("Untitled Draft"), text: $draftTitle)
                    .font(.body.weight(.semibold))
                    .textFieldStyle(.plain)
                    .onChange(of: draftTitle) { _, newValue in
                        createStore.updateTitle(newValue)
                    }

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        isToolbarExpanded.toggle()
                    }
                    haptic.impactOccurred()
                } label: {
                    Image(systemName: isToolbarExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PixelBeadsTheme.ink)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.tr(isToolbarExpanded ? "Hide tools" : "Show tools"))
            }

            if isToolbarExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            lockControlButton

                            toolSelectionButton(.brush)

                            ForEach(EditorTool.allCases.filter { $0 != .brush }) { tool in
                                toolSelectionButton(tool)
                            }

                            editorControlButton(
                                title: "Undo",
                                systemImage: "arrow.uturn.backward",
                                enabled: createStore.canUndo
                            ) {
                                createStore.undo()
                                haptic.impactOccurred()
                            }

                            editorControlButton(
                                title: "Clear",
                                systemImage: "trash.circle",
                                enabled: !createStore.currentPattern.pixels.isEmpty
                            ) {
                                isShowingResetConfirmation = true
                            }

                            editorControlButton(
                                title: "Size",
                                systemImage: "squareshape.split.3x3",
                                enabled: true
                            ) {
                                if createStore.currentPattern.hasPlacedBeads {
                                    isShowingResizeConfirmation = true
                                } else {
                                    isShowingSizePicker = true
                                }
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .background(PixelBeadsTheme.outline)

            Button {
                isShowingColorPicker = true
            } label: {
                HStack(spacing: 12) {
                    BeadSwatch(color: Color(hex: createStore.selectedColorHex), isSelected: true)
                    Text(selectedBeadColor?.code ?? L10n.tr("Custom"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PixelBeadsTheme.ink)
                    Spacer()
                    Label(L10n.tr("Palette"), systemImage: "swatchpalette")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PixelBeadsTheme.ink)
                }
                .padding(12)
                .background(PixelBeadsTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                        .stroke(PixelBeadsTheme.outline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .pbCard()
    }

    private var editorCanvas: some View {
        VStack(alignment: .leading, spacing: 8) {
            canvasViewport
                .frame(height: 400)

            canvasControls
                .padding(.top, 4)
        }
        .pbCard()
    }

    private var canvasViewport: some View {
        GeometryReader { geometry in
            let viewSize = geometry.size
            PixelEditorCanvas(
                pattern: createStore.currentPattern,
                scale: canvasScale,
                offset: canvasOffset,
                isEditable: !createStore.isCanvasLocked
            ) { phase in
                switch phase {
                case .began:
                    createStore.beginStroke()
                case .changed(let x, let y):
                    createStore.dragCell(x: x, y: y)
                case .ended:
                    createStore.endStroke()
                }
            }
            .frame(width: viewSize.width, height: viewSize.height)
            .clipped()
            .background(
                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous)
                    .fill(Color(red: 0.96, green: 0.93, blue: 0.86))
            )
            .overlay(alignment: .topTrailing) {
                if createStore.isCanvasLocked {
                    Label(L10n.tr("Locked"), systemImage: "lock.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(PixelBeadsTheme.ink.opacity(0.86))
                        .clipShape(Capsule())
                        .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous)
                    .stroke(PixelBeadsTheme.outline, lineWidth: 1)
            )
            .onAppear {
                updateCanvasViewportSize(viewSize)
            }
            .onChange(of: viewSize) { _, newSize in
                updateCanvasViewportSize(newSize)
            }
            .onChange(of: canvasScale) { _, _ in
                centerCanvasIfPossible()
            }
            .onChange(of: createStore.currentPattern.width) { _, _ in
                centerCanvasIfPossible()
            }
            .onChange(of: createStore.currentPattern.height) { _, _ in
                centerCanvasIfPossible()
            }
        }
    }

    private func isToolButtonSelected(_ tool: EditorTool) -> Bool {
        !createStore.isCanvasLocked && createStore.selectedTool == tool
    }

    private var lockControlButton: some View {
        Button {
            createStore.toggleCanvasLock()
            haptic.impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: createStore.isCanvasLocked ? "lock.fill" : "lock.open")
                    .font(.subheadline.weight(.semibold))
                Text(L10n.tr("Lock"))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(createStore.isCanvasLocked ? Color.white : PixelBeadsTheme.ink)
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(createStore.isCanvasLocked ? PixelBeadsTheme.ink : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                    .stroke(createStore.isCanvasLocked ? PixelBeadsTheme.ink : PixelBeadsTheme.outline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.tr("Lock"))
    }

    private func toolSelectionButton(_ tool: EditorTool) -> some View {
        Button {
            createStore.selectTool(tool)
            haptic.impactOccurred()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: tool.systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(tool.title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isToolButtonSelected(tool) ? Color.white : PixelBeadsTheme.ink)
            .frame(height: 44)
            .padding(.horizontal, 12)
            .background(isToolButtonSelected(tool) ? PixelBeadsTheme.ink : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                    .stroke(isToolButtonSelected(tool) ? PixelBeadsTheme.ink : PixelBeadsTheme.outline, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tool.title)
    }

    private var canvasControls: some View {
        ZStack {
            HStack(spacing: 12) {
                if !isTrackPointActive {
                    zoomControl
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }

                Spacer(minLength: 0)

                TrackPointButton(isActive: $isTrackPointActive, maxPanStep: joystickPanStep) { delta in
                    let newOffset = CGSize(
                        width: canvasOffset.width + delta.width,
                        height: canvasOffset.height + delta.height
                    )
                    canvasOffset = clampedOffset(newOffset, viewSize: canvasViewportSize)
                }
                .accessibilityLabel(L10n.tr(isTrackPointActive ? "Pan canvas active" : "Activate pan canvas"))

                if isTrackPointActive {
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(height: 68)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: isTrackPointActive)
    }

    private var zoomControl: some View {
        HStack(spacing: 8) {
            Image(systemName: "minus.magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $canvasScale, in: minScale...maxScale, step: 0.1)
                .accessibilityLabel(L10n.tr("Zoom"))

            Image(systemName: "plus.magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(PixelBeadsTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                .stroke(PixelBeadsTheme.outline, lineWidth: 1)
        )
    }

    private func updateCanvasViewportSize(_ size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        canvasViewportSize = size

        if hasInitializedCanvasPosition {
            canvasOffset = clampedOffset(canvasOffset, viewSize: size)
        } else {
            canvasOffset = centeredCanvasOffset(viewSize: size)
            hasInitializedCanvasPosition = true
        }
    }

    private func centerCanvasIfPossible() {
        guard canvasViewportSize.width > 0, canvasViewportSize.height > 0 else { return }
        canvasOffset = centeredCanvasOffset(viewSize: canvasViewportSize)
    }

    private var selectedBeadColor: BeadColor? {
        MockData.beadColor(for: createStore.selectedColorHex)
    }

    private struct BeadSwatch: View {
        let color: Color
        let isSelected: Bool

        var body: some View {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: 38, height: 38)
                    .offset(y: 2)
                Circle()
                    .fill(color)
                    .frame(width: 38, height: 38)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.55), lineWidth: 4)
                            .padding(6)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.32))
                            .frame(width: 8, height: 8)
                            .offset(x: -8, y: -8)
                    )
                Circle()
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))

                if isSelected {
                    Circle()
                        .stroke(PixelBeadsTheme.ink, lineWidth: 3)
                        .frame(width: 46, height: 46)
                }
            }
            .frame(width: 48, height: 48)
        }
    }

    private struct SizePickerSheet: View {
        let currentSize: Int
        let sizes: [Int]
        let onSelect: (Int) -> Void

        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                List {
                    Section {
                        ForEach(sizes, id: \.self) { size in
                            Button {
                                onSelect(size)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("\(size) × \(size)")
                                        .font(.body)
                                    Spacer()
                                    if size == currentSize {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(PixelBeadsTheme.ink)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .foregroundStyle(PixelBeadsTheme.ink)
                        }
                    } footer: {
                        Text(L10n.tr("Changing size keeps beads within the new area. Beads outside will be removed."))
                            .font(.caption)
                    }
                }
                .navigationTitle(L10n.tr("Canvas Size"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.tr("Done")) {
                            dismiss()
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private struct ColorPickerSheet: View {
        @Binding var selectedColorHex: String
        let onSelect: () -> Void

        @Environment(\.dismiss) private var dismiss

        private let columns = [
            GridItem(.adaptive(minimum: 76), spacing: 12)
        ]

        var body: some View {
            NavigationStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 22, pinnedViews: [.sectionHeaders]) {
                        ForEach(MockData.mardColorFamilies, id: \.self) { family in
                            let colors = MockData.mardStandardPalette.filter { $0.family == family }
                            Section {
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(colors) { beadColor in
                                        Button {
                                            selectedColorHex = beadColor.hex
                                            onSelect()
                                            dismiss()
                                        } label: {
                                            VStack(spacing: 8) {
                                                BeadSwatch(color: Color(hex: beadColor.hex), isSelected: selectedColorHex == beadColor.hex)
                                                VStack(spacing: 2) {
                                                    Text(beadColor.code)
                                                        .font(.caption.weight(.black))
                                                        .foregroundStyle(PixelBeadsTheme.ink)
                                                    Text(beadColor.hex)
                                                        .font(.caption2.monospacedDigit())
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                                                    .stroke(selectedColorHex == beadColor.hex ? PixelBeadsTheme.ink : PixelBeadsTheme.outline, lineWidth: selectedColorHex == beadColor.hex ? 2 : 1)
                                            )
                                        }
                                        .accessibilityLabel(L10n.tr("MARD color %@ %@", beadColor.code, beadColor.hex))
                                        .buttonStyle(.plain)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(L10n.tr("Color Family %@", family))
                                        .font(.headline)
                                    Spacer()
                                    Text(L10n.tr("%d colors", colors.count))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(PixelBeadsTheme.surface)
                                .zIndex(1)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .navigationTitle(L10n.tr("MARD Color Chart"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(PixelBeadsTheme.surface, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.tr("Done")) {
                            dismiss()
                        }
                    }
                }
                .background(PixelBeadsTheme.surface)
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var quickActions: some View {
        VStack(spacing: 12) {
            Button {
                guard createStore.saveDraft(user: sessionStore.currentUser) else {
                    isShowingEmptyDraftAlert = true
                    return
                }
                libraryStore.load(for: sessionStore.currentUser)
                libraryStore.selectedSegment = .drafts
                selectedTab = .library
            } label: {
                Label(L10n.tr("Save Draft"), systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(SecondaryButtonStyle())

            if createStore.currentPattern.pixels.contains(where: { $0.colorHex != nil }) {
                NavigationLink {
                    PreviewView(sessionStore: sessionStore, createStore: createStore, libraryStore: libraryStore, selectedTab: $selectedTab)
                } label: {
                    Label(L10n.tr("Open Preview"), systemImage: "sparkles.rectangle.stack")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button {
                    isShowingEmptyPreviewAlert = true
                } label: {
                    Label(L10n.tr("Open Preview"), systemImage: "sparkles.rectangle.stack")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func editorControlButton(title: String, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                Text(L10n.tr(title))
                    .font(.caption.weight(.semibold))
            } icon: {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(height: 44)
            .padding(.horizontal, 12)
            .foregroundStyle(PixelBeadsTheme.ink)
            .background(PixelBeadsTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                    .stroke(PixelBeadsTheme.outline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.42)
        .accessibilityLabel(L10n.tr(title))
    }
}

private enum PixelEditorGesturePhase {
    case began
    case changed(Int, Int)
    case ended
}

private struct PixelEditorCanvas: View {
    let pattern: Pattern
    let scale: Double
    let offset: CGSize
    let isEditable: Bool
    let onGesturePhase: (PixelEditorGesturePhase) -> Void

    @State private var isDragging = false

    private var cellSize: CGFloat {
        let maxDimension = max(pattern.width, pattern.height)
        if maxDimension <= 20 { return 18 }
        if maxDimension <= 29 { return 14 }
        if maxDimension <= 32 { return 12 }
        return 10
    }

    private var boardSize: CGSize {
        CGSize(
            width: CGFloat(pattern.width) * cellSize * CGFloat(scale),
            height: CGFloat(pattern.height) * cellSize * CGFloat(scale)
        )
    }

    private var coordinateGutter: CGFloat {
        let scaledCellSize = cellSize * CGFloat(scale)
        return min(max(scaledCellSize * 1.35, 20), 30)
    }

    private var canvasSize: CGSize {
        let boardSize = boardSize
        return CGSize(
            width: boardSize.width + coordinateGutter * 2,
            height: boardSize.height + coordinateGutter * 2
        )
    }

    var body: some View {
        let canvas = Canvas { context, size in
            let canvasSize = canvasSize
            let visualRect = CGRect(origin: CGPoint(x: offset.width, y: offset.height), size: canvasSize)
            let boardSize = boardSize
            let boardRect = CGRect(
                x: visualRect.minX + coordinateGutter,
                y: visualRect.minY + coordinateGutter,
                width: boardSize.width,
                height: boardSize.height
            )
            let cellWidth = boardSize.width / CGFloat(pattern.width)
            let cellHeight = boardSize.height / CGFloat(pattern.height)
            let colorMap = pattern.pixels.colorMap()

            context.fill(
                Path(roundedRect: visualRect, cornerRadius: max(cellWidth * 0.9, 14)),
                with: .color(Color.white.opacity(0.30))
            )

            context.fill(
                Path(roundedRect: boardRect, cornerRadius: cellWidth * 0.7),
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.92), Color(red: 0.93, green: 0.91, blue: 0.84).opacity(0.72)]),
                    startPoint: boardRect.origin,
                    endPoint: CGPoint(x: boardRect.maxX, y: boardRect.maxY)
                )
            )

            for row in 0..<pattern.height {
                for column in 0..<pattern.width {
                    let rect = CGRect(
                        x: boardRect.minX + CGFloat(column) * cellWidth,
                        y: boardRect.minY + CGFloat(row) * cellHeight,
                        width: cellWidth,
                        height: cellHeight
                    )
                    let hex = colorMap["\(column)-\(row)"] ?? nil

                    drawPegboardCell(in: &context, rect: rect, hex: hex, cellWidth: cellWidth, cellHeight: cellHeight)

                    context.stroke(Path(rect), with: .color(Color.black.opacity(0.035)), lineWidth: 0.45)
                }
            }

            drawCoordinateLabels(
                in: &context,
                visualRect: visualRect,
                boardRect: boardRect,
                cellWidth: cellWidth,
                cellHeight: cellHeight
            )
        }
        .contentShape(Rectangle())

        return Group {
            if isEditable {
                canvas.gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                onGesturePhase(.began)
                            }
                            if let cell = cell(at: value.location, canvasSize: canvasSize) {
                                onGesturePhase(.changed(cell.x, cell.y))
                            }
                        }
                        .onEnded { _ in
                            guard isDragging else { return }
                            isDragging = false
                            onGesturePhase(.ended)
                        }
                )
            } else {
                canvas
            }
        }
    }

    private func drawPegboardCell(
        in context: inout GraphicsContext,
        rect: CGRect,
        hex: String?,
        cellWidth: CGFloat,
        cellHeight: CGFloat
    ) {
        let pegRect = rect.insetBy(dx: cellWidth * 0.34, dy: cellHeight * 0.34)
        context.fill(Path(ellipseIn: pegRect.offsetBy(dx: 0, dy: cellHeight * 0.035)), with: .color(Color.black.opacity(0.10)))
        context.fill(Path(ellipseIn: pegRect), with: .color(Color.white.opacity(0.74)))
        context.stroke(Path(ellipseIn: pegRect), with: .color(Color.black.opacity(0.08)), lineWidth: 0.55)

        guard let color = hex.flatMap(Color.init(hex:)) else { return }
        let beadRect = rect.insetBy(dx: cellWidth * 0.10, dy: cellHeight * 0.10)
        context.fill(Path(ellipseIn: beadRect.offsetBy(dx: 0, dy: cellHeight * 0.08)), with: .color(Color.black.opacity(0.18)))
        context.fill(Path(ellipseIn: beadRect), with: .color(color))
        context.stroke(Path(ellipseIn: beadRect), with: .color(Color.black.opacity(0.16)), lineWidth: 0.75)

        let holeRect = rect.insetBy(dx: cellWidth * 0.36, dy: cellHeight * 0.36)
        context.fill(Path(ellipseIn: holeRect), with: .color(Color.white.opacity(0.78)))
        context.stroke(Path(ellipseIn: holeRect), with: .color(Color.black.opacity(0.10)), lineWidth: 0.55)

        let highlight = CGRect(x: rect.minX + cellWidth * 0.24, y: rect.minY + cellHeight * 0.18, width: cellWidth * 0.18, height: cellHeight * 0.13)
        context.fill(Path(ellipseIn: highlight), with: .color(Color.white.opacity(0.42)))
    }

    private func drawCoordinateLabels(
        in context: inout GraphicsContext,
        visualRect: CGRect,
        boardRect: CGRect,
        cellWidth: CGFloat,
        cellHeight: CGFloat
    ) {
        let step = coordinateStep(cellSize: min(cellWidth, cellHeight))
        let fontSize = min(max(min(cellWidth, cellHeight) * 0.46, 7), 11)
        let labelStyle = Color.black.opacity(0.46)
        let columnTextYTop = visualRect.minY + coordinateGutter * 0.48
        let columnTextYBottom = boardRect.maxY + coordinateGutter * 0.52
        let rowTextXLeft = visualRect.minX + coordinateGutter * 0.48
        let rowTextXRight = boardRect.maxX + coordinateGutter * 0.52

        for column in 0..<pattern.width where shouldShowCoordinate(index: column, count: pattern.width, step: step) {
            let text = Text("\(column + 1)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(labelStyle)
            let x = boardRect.minX + (CGFloat(column) + 0.5) * cellWidth

            context.draw(text, at: CGPoint(x: x, y: columnTextYTop), anchor: .center)
            context.draw(text, at: CGPoint(x: x, y: columnTextYBottom), anchor: .center)
        }

        for row in 0..<pattern.height where shouldShowCoordinate(index: row, count: pattern.height, step: step) {
            let text = Text("\(row + 1)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(labelStyle)
            let y = boardRect.minY + (CGFloat(row) + 0.5) * cellHeight

            context.draw(text, at: CGPoint(x: rowTextXLeft, y: y), anchor: .center)
            context.draw(text, at: CGPoint(x: rowTextXRight, y: y), anchor: .center)
        }
    }

    private func coordinateStep(cellSize: CGFloat) -> Int {
        if cellSize >= 12 { return 1 }
        if cellSize >= 8 { return 2 }
        if cellSize >= 5 { return 4 }
        return 6
    }

    private func shouldShowCoordinate(index: Int, count: Int, step: Int) -> Bool {
        index == 0 || index == count - 1 || index % step == 0
    }

    private func cell(at location: CGPoint, canvasSize: CGSize) -> (x: Int, y: Int)? {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return nil }

        let boardSize = boardSize
        let boardRect = CGRect(
            x: offset.width + coordinateGutter,
            y: offset.height + coordinateGutter,
            width: boardSize.width,
            height: boardSize.height
        )
        guard boardRect.contains(location) else { return nil }

        let localX = location.x - boardRect.minX
        let localY = location.y - boardRect.minY
        let cellWidth = boardSize.width / CGFloat(pattern.width)
        let cellHeight = boardSize.height / CGFloat(pattern.height)
        let x = min(max(Int(localX / cellWidth), 0), pattern.width - 1)
        let y = min(max(Int(localY / cellHeight), 0), pattern.height - 1)
        return (x, y)
    }
}

struct TrackPointButton: View {
    @Binding var isActive: Bool
    let maxPanStep: CGFloat
    let onPan: (CGSize) -> Void

    @State private var isDragging = false
    @State private var knobOffset: CGSize = .zero
    @State private var dragDistance: CGFloat = 0
    @State private var hapticDistance: CGFloat = 0
    @State private var wasActiveAtDragStart = false

    private let dragLimit: CGFloat = 22
    private let panTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(isActive ? 0.22 : 0.08))
                .frame(width: isActive ? 62 : 44, height: isActive ? 62 : 44)

            Circle()
                .stroke(Color.red.opacity(isActive ? 0.30 : 0.10), lineWidth: 1)
                .frame(width: dragLimit * 2, height: dragLimit * 2)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.red.opacity(isActive ? 0.98 : 0.50),
                                Color.red.opacity(isActive ? 0.78 : 0.36),
                                Color.red.opacity(isActive ? 0.58 : 0.24)
                            ]),
                            center: .center,
                            startRadius: 2,
                            endRadius: 14
                        )
                    )
                    .frame(width: isActive ? 34 : 28, height: isActive ? 34 : 28)

                Circle()
                    .fill(Color.white.opacity(isActive ? 0.32 : 0.18))
                    .frame(width: 12, height: 12)
                    .offset(y: -4)
            }
            .offset(knobOffset)
        }
        .frame(width: 76, height: 76)
        .scaleEffect(isDragging ? 1.05 : 1)
        .shadow(color: .red.opacity(isActive ? 0.38 : 0.14), radius: isActive ? 10 : 5, x: 0, y: 2)
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .opacity(isActive ? 1 : 0.72)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isActive)
        .animation(.spring(response: 0.20, dampingFraction: 0.74), value: isDragging)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        dragDistance = 0
                        hapticDistance = 0
                        wasActiveAtDragStart = isActive
                        activateIfNeeded()
                    }
                    let limitedOffset = limitedKnobOffset(for: value.translation)
                    dragDistance = max(dragDistance, hypot(limitedOffset.width, limitedOffset.height))
                    knobOffset = limitedOffset
                }
                .onEnded { _ in
                    isDragging = false
                    knobOffset = .zero
                    if wasActiveAtDragStart, dragDistance < 2 {
                        isActive = false
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
        )
        .onReceive(panTimer) { _ in
            guard isDragging, isActive else { return }
            let normalized = CGSize(
                width: knobOffset.width / dragLimit,
                height: knobOffset.height / dragLimit
            )
            let delta = CGSize(
                width: normalized.width * maxPanStep,
                height: normalized.height * maxPanStep
            )
            let movement = hypot(delta.width, delta.height)

            guard movement > 0.05 else { return }
            onPan(delta)
            triggerMovementHapticIfNeeded(movement: movement)
        }
    }

    private func activateIfNeeded() {
        guard !isActive else { return }
        isActive = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func limitedKnobOffset(for translation: CGSize) -> CGSize {
        let distance = hypot(translation.width, translation.height)
        guard distance > dragLimit else { return translation }

        let scale = dragLimit / distance
        return CGSize(
            width: translation.width * scale,
            height: translation.height * scale
        )
    }

    private func triggerMovementHapticIfNeeded(movement: CGFloat) {
        hapticDistance += movement
        guard hapticDistance >= 18 else { return }
        hapticDistance = 0
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
