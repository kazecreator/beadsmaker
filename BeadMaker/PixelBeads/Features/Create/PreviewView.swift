import SwiftUI

struct PreviewView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore

    @State private var isShowingExportSheet = false
    @State private var showClaimHint = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PBSectionHeader(title: "Preview", subtitle: "Inspection only — switch render style and export in one tap.")

                Picker("Mode", selection: $createStore.previewMode) {
                    ForEach(PreviewMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                PatternThumbnail(pattern: createStore.currentPattern, mode: createStore.previewMode, height: 280)

                exportSection
                publishSection
            }
            .padding(16)
        }
        .navigationTitle("Preview")
        .background(PixelBeadsTheme.surface)
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

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.headline)

            Button {
                isShowingExportSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Export Sheet")
                            .font(.headline)
                            .foregroundStyle(PixelBeadsTheme.ink)
                        Text("Share pixel, bead, or comparison PNG renders.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(PixelBeadsTheme.coral)
                }
                .padding(14)
                .background(Color.white)
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

    private var publishSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next")
                .font(.headline)

            Button {
                createStore.saveDraft(user: sessionStore.currentUser)
                libraryStore.load(for: sessionStore.currentUser)
            } label: {
                Label("Save to Library", systemImage: "books.vertical")
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
        .pbCard()
    }
}
