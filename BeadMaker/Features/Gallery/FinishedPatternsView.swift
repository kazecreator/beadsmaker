import SwiftUI
import SwiftData

struct FinishedPatternsView: View {
    let patterns: [FinishedPattern]
    let onSelect: (FinishedPattern) -> Void
    let onCreateCopy: (Pattern) -> Void

    @Environment(\.modelContext) private var modelContext

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(patterns) { pattern in
                    Button {
                        onSelect(pattern)
                    } label: {
                        PatternCardView(
                            name: pattern.name,
                            width: pattern.width,
                            height: pattern.height,
                            thumbnailData: pattern.thumbnailData,
                            isCollected: false,
                            subtitle: "已熨烫",
                            badgeText: "成品"
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            let copy = duplicate(pattern)
                            onCreateCopy(copy)
                        } label: {
                            Label("生成副本", systemImage: "doc.on.doc")
                        }

                        Button(role: .destructive) {
                            modelContext.delete(pattern)
                            try? modelContext.save()
                        } label: {
                            Label("删除成品", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func duplicate(_ pattern: FinishedPattern) -> Pattern {
        let copy = Pattern(name: "\(pattern.name) 副本", width: pattern.width, height: pattern.height)
        copy.gridData = pattern.gridData
        copy.thumbnailData = PatternRenderer.thumbnail(pattern: copy).pngData()
        modelContext.insert(copy)
        try? modelContext.save()
        return copy
    }
}
