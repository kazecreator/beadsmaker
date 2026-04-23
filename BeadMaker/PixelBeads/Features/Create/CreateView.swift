import SwiftUI

struct CreateView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore

    @State private var draftTitle: String = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 16)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PBSectionHeader(title: "Create", subtitle: "Edit a pixel pattern, preview it as beads, then export as PNG.")

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
        .pbScreen()
    }

    private var patternTitleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern title")
                .font(.headline)
            TextField("Untitled Draft", text: $draftTitle)
                .textFieldStyle(.roundedBorder)
                .onChange(of: draftTitle) { _, newValue in
                    createStore.updateTitle(newValue)
                }

            HStack(spacing: 8) {
                PBChip(title: createStore.currentPattern.status.rawValue.capitalized, accent: createStore.currentPattern.status == .final)
                PBChip(title: "\(createStore.currentPattern.width)×\(createStore.currentPattern.height)")
                PBChip(title: createStore.previewMode.title)
            }
        }
        .pbCard()
    }

    private var editorToolbar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tools")
                .font(.headline)

            HStack(spacing: 10) {
                ForEach(EditorTool.allCases) { tool in
                    Button {
                        createStore.selectedTool = tool
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: tool.systemImage)
                            Text(tool.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(createStore.selectedTool == tool ? Color.white : PixelBeadsTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(createStore.selectedTool == tool ? PixelBeadsTheme.ink : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                Button("Undo", action: createStore.undo)
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!createStore.canUndo)
                Button("Redo", action: createStore.redo)
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(!createStore.canRedo)
            }
        }
        .pbCard()
    }

    private var editorCanvas: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Canvas")
                    .font(.headline)
                Spacer()
                Picker("Preview Mode", selection: $createStore.previewMode) {
                    ForEach(PreviewMode.allCases.filter { $0 != .comparison }) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(0..<createStore.currentPattern.height, id: \.self) { row in
                    ForEach(0..<createStore.currentPattern.width, id: \.self) { column in
                        let color = colorForCell(x: column, y: row)
                        Rectangle()
                            .fill(color)
                            .frame(height: 18)
                            .overlay(Rectangle().stroke(Color.black.opacity(0.06), lineWidth: 0.5))
                            .onTapGesture {
                                createStore.tapCell(x: column, y: row)
                            }
                    }
                }
            }
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous))

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
                                    .frame(width: 34, height: 34)
                                if createStore.selectedColorHex == hex {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 40, height: 40)
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

            NavigationLink {
                PreviewView(sessionStore: sessionStore, createStore: createStore, libraryStore: libraryStore)
            } label: {
                Label("Open Preview", systemImage: "sparkles.rectangle.stack")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }

    private func colorForCell(x: Int, y: Int) -> Color {
        if let hex = createStore.currentPattern.pixels.first(where: { $0.x == x && $0.y == y })?.colorHex {
            return Color(hex: hex)
        }
        return PixelBeadsTheme.surface
    }
}
