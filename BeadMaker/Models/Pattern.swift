 import SwiftData
import Foundation

@Model
final class Pattern {
    var name: String
    var width: Int
    var height: Int
    var gridData: [Int]
    var thumbnailData: Data?
    var createdAt: Date
    var modifiedAt: Date

    init(name: String, width: Int, height: Int) {
        self.name = name
        self.width = width
        self.height = height
        self.gridData = Array(repeating: 0, count: width * height)
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    func colorIndex(at row: Int, col: Int) -> Int {
        guard row >= 0, row < height, col >= 0, col < width else { return 0 }
        return gridData[row * width + col]
    }

    func setColor(_ index: Int, at row: Int, col: Int) {
        guard row >= 0, row < height, col >= 0, col < width else { return }
        gridData[row * width + col] = index
        modifiedAt = Date()
    }
}

@Model
final class CollectedPattern {
    var name: String
    var width: Int
    var height: Int
    var gridData: [Int]
    var thumbnailData: Data?
    var signature: String
    var createdAt: Date
    var modifiedAt: Date

    init(name: String, width: Int, height: Int, gridData: [Int], thumbnailData: Data?, signature: String) {
        self.name = name
        self.width = width
        self.height = height
        self.gridData = gridData
        self.thumbnailData = thumbnailData
        self.signature = signature
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
