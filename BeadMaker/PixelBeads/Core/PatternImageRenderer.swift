import SwiftUI
import UIKit

enum PatternImageRenderer {
    private static func key(x: Int, y: Int) -> String {
        "\(x)-\(y)"
    }

    static func image(for pattern: Pattern, mode: PreviewMode, scale: CGFloat = 1) -> UIImage {
        switch mode {
        case .pixel:
            return pixelImage(for: pattern, cellSize: 22, scale: scale)
        case .bead:
            return beadImage(for: pattern, cellSize: 24, scale: scale)
        case .comparison:
            let pixel = pixelImage(for: pattern, cellSize: 18, scale: scale)
            let bead = beadImage(for: pattern, cellSize: 18, scale: scale)
            let spacing: CGFloat = 16
            let size = CGSize(width: pixel.size.width + bead.size.width + spacing + 32, height: max(pixel.size.height, bead.size.height) + 32)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))

                let leftY = (size.height - pixel.size.height) / 2
                let rightY = (size.height - bead.size.height) / 2
                pixel.draw(at: CGPoint(x: 12, y: leftY))
                bead.draw(at: CGPoint(x: pixel.size.width + spacing + 20, y: rightY))
            }
        }
    }

    static func pixelImage(for pattern: Pattern, cellSize: CGFloat, scale: CGFloat = 1) -> UIImage {
        let canvas = CGSize(width: CGFloat(pattern.width) * cellSize, height: CGFloat(pattern.height) * cellSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)

        let colorMap = Dictionary(uniqueKeysWithValues: pattern.pixels.map { (key(x: $0.x, y: $0.y), UIColor(hex: $0.colorHex ?? "#FFFFFF")) })
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvas))

            for row in 0..<pattern.height {
                for column in 0..<pattern.width {
                    let rect = CGRect(x: CGFloat(column) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
                    let color = colorMap[key(x: column, y: row)] ?? UIColor(hex: "#F5F5F5")
                    color.setFill()
                    context.fill(rect)

                    let cgRect = rect.insetBy(dx: 0.2, dy: 0.2)
                    context.cgContext.setStrokeColor(UIColor.black.withAlphaComponent(0.08).cgColor)
                    context.cgContext.setLineWidth(0.5)
                    context.cgContext.stroke(cgRect)
                }
            }
        }
    }

    static func beadImage(for pattern: Pattern, cellSize: CGFloat, scale: CGFloat = 1) -> UIImage {
        let canvas = CGSize(width: CGFloat(pattern.width) * cellSize, height: CGFloat(pattern.height) * cellSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)

        let colorMap = Dictionary(uniqueKeysWithValues: pattern.pixels.map { (key(x: $0.x, y: $0.y), UIColor(hex: $0.colorHex ?? "#FFFFFF")) })
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvas))

            for row in 0..<pattern.height {
                for column in 0..<pattern.width {
                    let rect = CGRect(x: CGFloat(column) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
                    let color = colorMap[key(x: column, y: row)] ?? UIColor(hex: "#F5F5F5")

                    UIColor.black.withAlphaComponent(0.04).setFill()
                    context.fill(rect.insetBy(dx: 1, dy: 1))

                    color.setFill()
                    context.cgContext.fillEllipse(in: rect.insetBy(dx: 2, dy: 2))

                    UIColor.white.withAlphaComponent(0.45).setFill()
                    context.cgContext.fillEllipse(in: CGRect(x: rect.minX + 5, y: rect.minY + 4, width: cellSize * 0.22, height: cellSize * 0.22))
                }
            }
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
