import SwiftUI

struct BeadStatsView: View {
    var pattern: Pattern

    private var stats: [(BeadColor, Int)] {
        var counts: [Int: Int] = [:]
        for id in pattern.gridData where id != 0 {
            counts[id, default: 0] += 1
        }
        return counts.compactMap { (id, count) -> (BeadColor, Int)? in
            guard let color = BeadColorLibrary.color(id: id) else { return nil }
            return (color, count)
        }.sorted { $0.1 > $1.1 }
    }

    private var totalBeads: Int { stats.reduce(0) { $0 + $1.1 } }

    var body: some View {
        NavigationStack {
            Group {
                if stats.isEmpty {
                    ContentUnavailableView("还没有画任何拼豆", systemImage: "square.dashed")
                } else {
                    List {
                        Section {
                            HStack {
                                Label("总计", systemImage: "sum")
                                Spacer()
                                Text("\(totalBeads) 颗")
                                    .bold()
                                    .monospacedDigit()
                            }
                        }

                        Section("颜色明细") {
                            ForEach(stats, id: \.0.id) { bead, count in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(bead.color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bead.chineseName)
                                            .font(.subheadline)
                                        Text("\(bead.colorCode) · \(bead.englishName)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(count)")
                                            .font(.subheadline.bold())
                                            .monospacedDigit()
                                        Text("颗")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("用色统计")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
