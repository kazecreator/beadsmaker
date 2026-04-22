import SwiftUI
import Observation

enum DrawingTool: String, CaseIterable {
    case pen    = "pencil"
    case eraser = "eraser"
}

@Observable
final class EditorViewModel {
    var selectedColorId: Int = 1
    var selectedColorGroup: ColorGroup = .red
    var currentTool: DrawingTool = .pen
    var isPanMode: Bool = true
    var recentColors: [Int] = []

    private var undoStack: [[Int]] = []
    private var redoStack: [[Int]] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    // MARK: - Drawing

    func beginStroke(on pattern: Pattern) {
        saveUndoState(for: pattern)
    }

    func paintCell(on pattern: Pattern, row: Int, col: Int) {
        switch currentTool {
        case .pen:
            pattern.setColor(selectedColorId, at: row, col: col)
            addRecentColor(selectedColorId)
        case .eraser:
            pattern.setColor(0, at: row, col: col)
        }
    }

    func eraseCell(on pattern: Pattern, row: Int, col: Int) {
        pattern.setColor(0, at: row, col: col)
    }

    // MARK: - Undo / Redo

    private func saveUndoState(for pattern: Pattern) {
        undoStack.append(pattern.gridData)
        if undoStack.count > 50 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func undo(on pattern: Pattern) {
        guard let state = undoStack.popLast() else { return }
        redoStack.append(pattern.gridData)
        pattern.gridData = state
        pattern.modifiedAt = Date()
    }

    func redo(on pattern: Pattern) {
        guard let state = redoStack.popLast() else { return }
        undoStack.append(pattern.gridData)
        pattern.gridData = state
        pattern.modifiedAt = Date()
    }

    // MARK: - Recent Colors

    private func addRecentColor(_ id: Int) {
        recentColors.removeAll { $0 == id }
        recentColors.insert(id, at: 0)
        if recentColors.count > 8 { recentColors = Array(recentColors.prefix(8)) }
    }

    // MARK: - Stats

    func colorStats(for pattern: Pattern) -> [(BeadColor, Int)] {
        var counts: [Int: Int] = [:]
        for id in pattern.gridData where id != 0 {
            counts[id, default: 0] += 1
        }
        return counts.compactMap { (id, count) in
            guard let color = BeadColorLibrary.color(id: id) else { return nil }
            return (color, count)
        }.sorted { $0.1 > $1.1 }
    }

    func totalBeads(for pattern: Pattern) -> Int {
        colorStats(for: pattern).reduce(0) { $0 + $1.1 }
    }

    // MARK: - Thumbnail

    func updateThumbnail(for pattern: Pattern) {
        let img = PatternRenderer.thumbnail(pattern: pattern)
        pattern.thumbnailData = img.pngData()
    }

    func resetForCanvasOpen() {
        isPanMode = true
    }
}
