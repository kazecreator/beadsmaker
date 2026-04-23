import SwiftUI

struct LibraryView: View {
    @ObservedObject var libraryStore: LibraryStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PBSectionHeader(title: "Library", subtitle: "Keep drafts local, save inspiration, and revisit published pieces.")

                    Picker("Library", selection: $libraryStore.selectedSegment) {
                        ForEach(LibrarySegment.allCases) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)

                    if libraryStore.displayedPatterns.isEmpty {
                        emptyState
                    } else {
                        ForEach(libraryStore.displayedPatterns) { pattern in
                            VStack(alignment: .leading, spacing: 14) {
                                PatternThumbnail(pattern: pattern, mode: pattern.status == .final ? .bead : .pixel, height: 170)
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(pattern.title)
                                            .font(.headline)
                                        Text(pattern.status == .draft ? "Local draft" : "Ready for export")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    PBChip(title: pattern.status.rawValue.capitalized, accent: pattern.status == .final)
                                }
                            }
                            .pbCard()
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Library")
            .background(PixelBeadsTheme.surface)
        }
        .pbScreen()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nothing here yet")
                .font(.headline)
            Text("Saved patterns, drafts, and published work appear here automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .pbCard()
    }
}
