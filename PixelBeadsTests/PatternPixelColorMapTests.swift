import XCTest
@testable import PixelBeads

final class PatternPixelColorMapTests: XCTestCase {
    func testColorMapAllowsDuplicateCoordinatesWithLastValueWinning() {
        let pixels = [
            PatternPixel(x: 8, y: 2, colorHex: "#111111"),
            PatternPixel(x: 1, y: 1, colorHex: "#222222"),
            PatternPixel(x: 8, y: 2, colorHex: "#333333")
        ]

        let map = pixels.colorMap()

        XCTAssertEqual(map["8-2"] ?? nil, "#333333")
        XCTAssertEqual(map["1-1"] ?? nil, "#222222")
    }
}
