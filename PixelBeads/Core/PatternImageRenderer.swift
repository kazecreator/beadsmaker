import SwiftUI
import UIKit

enum PatternImageRenderer {
    private static func key(x: Int, y: Int) -> String {
        "\(x)-\(y)"
    }

    static func image(for pattern: Pattern, mode: PreviewMode, scale: CGFloat = 1) -> UIImage {
        switch mode {
        case .pixel:
            return finishedImage(for: pattern, cellSize: 22, scale: scale)
        case .bead:
            return beadImage(for: pattern, cellSize: 24, scale: scale)
        case .comparison:
            let pixel = finishedImage(for: pattern, cellSize: 18, scale: scale)
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

    static func finishedImage(for pattern: Pattern, cellSize: CGFloat, scale: CGFloat = 1) -> UIImage {
        let coloredPixels = pattern.pixels.filter { $0.colorHex != nil }
        let colorMap = coloredPixels.colorMap()

        let minX = coloredPixels.map(\.x).min() ?? 0
        let maxX = coloredPixels.map(\.x).max() ?? 0
        let minY = coloredPixels.map(\.y).min() ?? 0
        let maxY = coloredPixels.map(\.y).max() ?? 0

        let border = cellSize * 0.22
        let margin = border + cellSize * 0.6
        let canvasW = CGFloat(maxX - minX + 1) * cellSize + margin * 2
        let canvasH = CGFloat(maxY - minY + 1) * cellSize + margin * 2
        let canvas = CGSize(width: canvasW, height: canvasH)

        let ox = margin - CGFloat(minX) * cellSize
        let oy = margin - CGFloat(minY) * cellSize

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: canvas, format: format).image { ctx in
            let cgCtx = ctx.cgContext

            // Transparent background — sticker PNG with no background
            cgCtx.clear(CGRect(origin: .zero, size: canvas))

            // White sticker border — union of outward-expanded pixel rects
            let stickerPath = UIBezierPath()
            let stickerCorner = cellSize * 0.34
            for pixel in coloredPixels {
                let r = CGRect(x: ox + CGFloat(pixel.x) * cellSize,
                               y: oy + CGFloat(pixel.y) * cellSize,
                               width: cellSize, height: cellSize)
                    .insetBy(dx: -border, dy: -border)
                stickerPath.append(UIBezierPath(roundedRect: r, cornerRadius: stickerCorner))
            }
            UIColor.white.setFill()
            stickerPath.fill()

            // Fused beads — no inset, flush to each other
            let beadCorner = cellSize * 0.14
            for pixel in coloredPixels {
                guard let hex = colorMap[pixel.coordinateKey] ?? nil else { continue }
                let color = UIColor(hex: hex)
                let rect = CGRect(x: ox + CGFloat(pixel.x) * cellSize,
                                  y: oy + CGFloat(pixel.y) * cellSize,
                                  width: cellSize, height: cellSize)

                // Base color with subtle top-to-bottom gradient via two fills
                let beadPath = UIBezierPath(roundedRect: rect, cornerRadius: beadCorner)
                color.setFill()
                beadPath.fill()

                // Darker bottom tint
                cgCtx.saveGState()
                beadPath.addClip()
                let gradColors = [UIColor.black.withAlphaComponent(0).cgColor,
                                  UIColor.black.withAlphaComponent(0.10).cgColor]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: gradColors as CFArray,
                                         locations: [0, 1])!
                cgCtx.drawLinearGradient(gradient,
                                         start: CGPoint(x: rect.midX, y: rect.minY),
                                         end: CGPoint(x: rect.midX, y: rect.maxY),
                                         options: [])
                cgCtx.restoreGState()

                // Seam
                UIColor.black.withAlphaComponent(0.07).setStroke()
                beadPath.lineWidth = 0.55
                beadPath.stroke()

                // Top-left highlight
                let hlRect = CGRect(x: rect.minX + cellSize * 0.08,
                                    y: rect.minY + cellSize * 0.07,
                                    width: cellSize * 0.30,
                                    height: cellSize * 0.14)
                UIColor.white.withAlphaComponent(0.28).setFill()
                UIBezierPath(ovalIn: hlRect).fill()
            }
        }
    }

    static func beadImage(for pattern: Pattern, cellSize: CGFloat, scale: CGFloat = 1) -> UIImage {
        let canvas = CGSize(width: CGFloat(pattern.width) * cellSize, height: CGFloat(pattern.height) * cellSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: canvas, format: format)

        let colorMap = pattern.pixels.colorMap()
        return renderer.image { context in
            UIColor(red: 0.96, green: 0.93, blue: 0.86, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: canvas))

            for row in 0..<pattern.height {
                for column in 0..<pattern.width {
                    let rect = CGRect(x: CGFloat(column) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)

                    let pegRect = rect.insetBy(dx: cellSize * 0.34, dy: cellSize * 0.34)
                    UIColor.black.withAlphaComponent(0.10).setFill()
                    context.cgContext.fillEllipse(in: pegRect.offsetBy(dx: 0, dy: cellSize * 0.035))
                    UIColor.white.withAlphaComponent(0.74).setFill()
                    context.cgContext.fillEllipse(in: pegRect)

                    guard let hex = colorMap[key(x: column, y: row)] ?? nil else { continue }
                    let color = UIColor(hex: hex)
                    let beadRect = rect.insetBy(dx: cellSize * 0.10, dy: cellSize * 0.10)
                    UIColor.black.withAlphaComponent(0.18).setFill()
                    context.cgContext.fillEllipse(in: beadRect.offsetBy(dx: 0, dy: cellSize * 0.08))
                    color.setFill()
                    context.cgContext.fillEllipse(in: beadRect)

                    UIColor.white.withAlphaComponent(0.78).setFill()
                    context.cgContext.fillEllipse(in: rect.insetBy(dx: cellSize * 0.36, dy: cellSize * 0.36))
                    UIColor.white.withAlphaComponent(0.42).setFill()
                    context.cgContext.fillEllipse(in: CGRect(x: rect.minX + cellSize * 0.24, y: rect.minY + cellSize * 0.18, width: cellSize * 0.18, height: cellSize * 0.13))
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
