import UIKit

enum PatternRenderer {
    private static let emptyCellBase = UIColor(red: 0.86, green: 0.87, blue: 0.89, alpha: 1)
    private static let emptyCellAlt = UIColor(red: 0.79, green: 0.81, blue: 0.84, alpha: 1)
    private static let emptyCellGrid = UIColor(red: 0.56, green: 0.59, blue: 0.64, alpha: 0.55)

    // MARK: - Core Render

    static func render(pattern: Pattern, cellSize: CGFloat = 10, showGrid: Bool = true) -> UIImage {
        let w = CGFloat(pattern.width) * cellSize
        let h = CGFloat(pattern.height) * cellSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            for row in 0..<pattern.height {
                for col in 0..<pattern.width {
                    let colorId = pattern.colorIndex(at: row, col: col)
                    let rect = CGRect(x: CGFloat(col) * cellSize, y: CGFloat(row) * cellSize,
                                     width: cellSize, height: cellSize)
                    if colorId != 0, let bead = BeadColorLibrary.color(id: colorId) {
                        cg.setFillColor(bead.uiColor.cgColor)
                        cg.fill(rect)
                    } else {
                        drawMosaicCell(in: cg, rect: rect, color: emptyFill(forRow: row, col: col))
                    }
                    if showGrid {
                        cg.setStrokeColor(emptyCellGrid.cgColor)
                        cg.setLineWidth(0.5)
                        cg.stroke(rect)
                    }
                }
            }
            cg.setStrokeColor(emptyCellGrid.withAlphaComponent(0.9).cgColor)
            cg.setLineWidth(1)
            cg.stroke(CGRect(x: 0, y: 0, width: w, height: h))
        }
    }

    static func thumbnail(pattern: Pattern, size: CGSize = CGSize(width: 120, height: 120)) -> UIImage {
        let cs = min(size.width / CGFloat(pattern.width), size.height / CGFloat(pattern.height))
        return render(pattern: pattern, cellSize: cs, showGrid: false)
    }

    // MARK: - Signature

    /// Appends a pixel-style signature bar with avatar + nickname to the bottom of `image`.
    static func attachSignature(to image: UIImage, profile: UserProfile?) -> UIImage {
        guard let profile else { return image }

        let signH: CGFloat = 48
        let totalSize = CGSize(width: image.size.width, height: image.size.height + signH)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: totalSize, format: format)

        return renderer.image { ctx in
            let cg = ctx.cgContext

            // 1. Original image
            image.draw(at: .zero)

            // 2. Dark bar
            UIColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 0.93).setFill()
            cg.fill(CGRect(x: 0, y: image.size.height, width: totalSize.width, height: signH))

            // 3. Subtle checkerboard texture (pixel feel)
            UIColor.white.withAlphaComponent(0.04).setFill()
            let gs: CGFloat = 3
            var gy = image.size.height
            while gy < totalSize.height {
                var gx: CGFloat = 0
                while gx < totalSize.width {
                    if (Int(gx / gs) + Int(gy / gs)) % 2 == 0 {
                        cg.fill(CGRect(x: gx, y: gy, width: gs, height: gs))
                    }
                    gx += gs
                }
                gy += gs
            }

            // 4. Avatar circle
            let avSize: CGFloat = 34
            let avPad: CGFloat = 7
            let avRect = CGRect(x: avPad,
                                y: image.size.height + (signH - avSize) / 2,
                                width: avSize, height: avSize)
            if let avatarImg = profile.avatarImage {
                cg.saveGState()
                cg.addEllipse(in: avRect)
                cg.clip()
                avatarImg.draw(in: avRect)
                cg.restoreGState()
            }
            // White ring
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.55).cgColor)
            cg.setLineWidth(1.5)
            cg.strokeEllipse(in: avRect.insetBy(dx: 0.75, dy: 0.75))

            // 5. "Made by" + nickname
            let textX = avRect.maxX + 8
            let byAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.55),
            ]
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor.white,
            ]
            let byStr = "Made by"
            let byH = (byStr as NSString).size(withAttributes: byAttrs).height
            let nameH = (profile.nickname as NSString).size(withAttributes: nameAttrs).height
            let totalTextH = byH + 2 + nameH
            let textStartY = image.size.height + (signH - totalTextH) / 2
            byStr.draw(at: CGPoint(x: textX, y: textStartY), withAttributes: byAttrs)
            profile.nickname.draw(at: CGPoint(x: textX, y: textStartY + byH + 2), withAttributes: nameAttrs)

            // 6. App label at right
            let appName = "拼豆图纸"
            let appAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.35),
            ]
            let appSize = (appName as NSString).size(withAttributes: appAttrs)
            appName.draw(at: CGPoint(x: totalSize.width - appSize.width - 8,
                                     y: image.size.height + (signH - appSize.height) / 2),
                         withAttributes: appAttrs)
        }
    }

    private static func emptyFill(forRow row: Int, col: Int) -> UIColor {
        (row + col).isMultiple(of: 2) ? emptyCellBase : emptyCellAlt
    }

    private static func drawMosaicCell(in context: CGContext, rect: CGRect, color: UIColor) {
        let rows = 4
        let cols = 4
        let tileWidth = rect.width / CGFloat(cols)
        let tileHeight = rect.height / CGFloat(rows)
        let offsets: [[CGFloat]] = [
            [0.030, -0.018, 0.030, -0.018],
            [-0.018, 0.030, -0.018, 0.030],
            [0.030, -0.018, 0.030, -0.018],
            [-0.018, 0.030, -0.018, 0.030]
        ]

        for row in 0..<rows {
            for col in 0..<cols {
                let originX = rect.minX + CGFloat(col) * tileWidth
                let originY = rect.minY + CGFloat(row) * tileHeight
                let tileRect = CGRect(
                    x: originX,
                    y: originY,
                    width: col == cols - 1 ? rect.maxX - originX : tileWidth,
                    height: row == rows - 1 ? rect.maxY - originY : tileHeight
                )

                context.setFillColor(color.mosaicAdjusted(by: offsets[row][col]).cgColor)
                context.fill(tileRect.integral)
            }
        }
    }
}

private extension UIColor {
    func mosaicAdjusted(by amount: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            var white: CGFloat = 0
            if getWhite(&white, alpha: &alpha) {
                let adjusted = min(max(white + amount, 0), 1)
                return UIColor(white: adjusted, alpha: alpha)
            }
            return self
        }

        return UIColor(
            red: min(max(red + amount, 0), 1),
            green: min(max(green + amount, 0), 1),
            blue: min(max(blue + amount, 0), 1),
            alpha: alpha
        )
    }
}
