import SwiftUI
import Observation

enum DrawingTool: String, CaseIterable {
    case pen    = "pencil"
    case eraser = "eraser"
}

@Observable
final class EditorViewModel {
    private struct PatternSnapshot {
        let width: Int
        let height: Int
        let gridData: [Int]
    }

    private struct CellChange {
        let index: Int
        let fromColorId: Int
        let toColorId: Int
    }

    private enum HistoryAction {
        case cellChanges([CellChange])
        case snapshot(PatternSnapshot)
    }

    var selectedColorId: Int = 1
    var selectedColorGroup: ColorGroup = .red
    var currentTool: DrawingTool = .pen
    var isPanMode: Bool = true
    var recentColors: [Int] = []

    private let maxHistorySteps = 50
    private var undoStack: [HistoryAction] = []
    private var redoStack: [HistoryAction] = []
    private var activeStrokeChanges: [Int: CellChange] = [:]

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    // MARK: - Drawing

    func beginStroke(on pattern: Pattern) {
        guard activeStrokeChanges.isEmpty else { return }
        activeStrokeChanges = [:]
    }

    func paintCell(on pattern: Pattern, row: Int, col: Int) {
        guard row >= 0, row < pattern.height, col >= 0, col < pattern.width else { return }

        let index = row * pattern.width + col
        let originalColorId = pattern.gridData[index]
        let newColorId: Int

        switch currentTool {
        case .pen:
            newColorId = selectedColorId
        case .eraser:
            newColorId = 0
        }

        guard originalColorId != newColorId else { return }

        let initialColorId = activeStrokeChanges[index]?.fromColorId ?? originalColorId
        pattern.setColor(newColorId, at: row, col: col)
        activeStrokeChanges[index] = CellChange(index: index, fromColorId: initialColorId, toColorId: newColorId)

        if currentTool == .pen {
            addRecentColor(selectedColorId)
        }
    }

    func eraseCell(on pattern: Pattern, row: Int, col: Int) {
        pattern.setColor(0, at: row, col: col)
    }

    func endStroke(on pattern: Pattern) {
        defer { activeStrokeChanges.removeAll() }
        guard !activeStrokeChanges.isEmpty else { return }

        let action = HistoryAction.cellChanges(activeStrokeChanges.values.sorted { $0.index < $1.index })
        pushUndoAction(action)
        redoStack.removeAll()
        pattern.modifiedAt = Date()
    }

    func applyImportedPattern(on pattern: Pattern, width: Int, height: Int, gridData: [Int]) {
        finishActiveStrokeIfNeeded(on: pattern)

        let previousSnapshot = snapshot(for: pattern)
        guard previousSnapshot.width != width || previousSnapshot.height != height || previousSnapshot.gridData != gridData else {
            return
        }

        pattern.width = width
        pattern.height = height
        pattern.gridData = gridData
        pattern.modifiedAt = Date()

        pushUndoAction(.snapshot(previousSnapshot))
        redoStack.removeAll()
    }

    // MARK: - Undo / Redo

    private func pushUndoAction(_ action: HistoryAction) {
        undoStack.append(action)
        if undoStack.count > maxHistorySteps {
            undoStack.removeFirst()
        }
    }

    func undo(on pattern: Pattern) {
        finishActiveStrokeIfNeeded(on: pattern)
        guard let action = undoStack.popLast() else { return }

        let redoAction = apply(action: action, on: pattern)
        redoStack.append(redoAction)
        if redoStack.count > maxHistorySteps {
            redoStack.removeFirst()
        }
    }

    func redo(on pattern: Pattern) {
        finishActiveStrokeIfNeeded(on: pattern)
        guard let action = redoStack.popLast() else { return }

        let undoAction = apply(action: action, on: pattern)
        pushUndoAction(undoAction)
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
        undoStack.removeAll()
        redoStack.removeAll()
        activeStrokeChanges.removeAll()
        isPanMode = true
    }

    private func finishActiveStrokeIfNeeded(on pattern: Pattern) {
        if !activeStrokeChanges.isEmpty {
            endStroke(on: pattern)
        }
    }

    @discardableResult
    private func apply(action: HistoryAction, on pattern: Pattern) -> HistoryAction {
        switch action {
        case .cellChanges(let changes):
            var inverseChanges: [CellChange] = []
            inverseChanges.reserveCapacity(changes.count)

            for change in changes {
                guard change.index >= 0 else { continue }
                let row = change.index / max(pattern.width, 1)
                let col = change.index % max(pattern.width, 1)
                let currentColorId = pattern.colorIndex(at: row, col: col)

                if currentColorId != change.toColorId {
                    pattern.setColor(change.toColorId, at: row, col: col)
                }

                inverseChanges.append(CellChange(index: change.index, fromColorId: change.toColorId, toColorId: currentColorId))
            }

            pattern.modifiedAt = Date()
            return .cellChanges(inverseChanges)

        case .snapshot(let targetSnapshot):
            let previousSnapshot = snapshot(for: pattern)
            pattern.width = targetSnapshot.width
            pattern.height = targetSnapshot.height
            pattern.gridData = targetSnapshot.gridData
            pattern.modifiedAt = Date()
            return .snapshot(previousSnapshot)
        }
    }

    private func snapshot(for pattern: Pattern) -> PatternSnapshot {
        PatternSnapshot(width: pattern.width, height: pattern.height, gridData: pattern.gridData)
    }
}
