import SwiftUI
import UIKit

struct PatternSheetLayout {
    let cellSize: CGFloat
    let contentSize: CGSize
    let beadInset: CGFloat
    let beadCornerRadius: CGFloat
    let sheetCornerRadius: CGFloat

    init(containerSize: CGSize, columns: Int, rows: Int, padding: CGFloat = 24) {
        let safeColumns = max(columns, 1)
        let safeRows = max(rows, 1)
        let availableWidth = max(containerSize.width - padding * 2, 1)
        let availableHeight = max(containerSize.height - padding * 2, 1)
        let resolvedCellSize = min(availableWidth / CGFloat(safeColumns), availableHeight / CGFloat(safeRows))

        cellSize = resolvedCellSize
        contentSize = CGSize(width: resolvedCellSize * CGFloat(safeColumns), height: resolvedCellSize * CGFloat(safeRows))
        beadInset = max(resolvedCellSize * 0.09, 0.8)
        beadCornerRadius = max(resolvedCellSize * 0.28, 2)
        sheetCornerRadius = max(resolvedCellSize * 0.55, 18)
    }

    func cellRect(row: Int, col: Int) -> CGRect {
        CGRect(
            x: CGFloat(col) * cellSize,
            y: CGFloat(row) * cellSize,
            width: cellSize,
            height: cellSize
        )
    }
}

enum PatternSheetPalette {
    static func pixelColor(for colorID: Int, row: Int, col: Int) -> Color {
        guard colorID != 0 else {
            let light = UIColor(red: 0.86, green: 0.87, blue: 0.89, alpha: 1)
            let dark = UIColor(red: 0.79, green: 0.81, blue: 0.84, alpha: 1)
            return Color(uiColor: (row + col).isMultiple(of: 2) ? light : dark)
        }

        let uiColor = BeadColorLibrary.color(id: colorID)?.uiColor ?? UIColor.systemGray3
        return Color(uiColor: uiColor)
    }

    static func ironedColor(for colorID: Int, row: Int, col: Int) -> UIColor {
        guard colorID != 0 else {
            let base = (row + col).isMultiple(of: 2)
                ? UIColor(red: 0.91, green: 0.92, blue: 0.94, alpha: 1)
                : UIColor(red: 0.87, green: 0.89, blue: 0.92, alpha: 1)
            return base.adjusted(saturation: 0.86, brightness: 1.01)
        }

        let base = BeadColorLibrary.color(id: colorID)?.uiColor ?? UIColor.systemGray3
        return base.adjusted(saturation: 1.14, brightness: 1.03)
    }
}

struct IronedPatternView: View {
    let width: Int
    let height: Int
    let gridData: [Int]

    var body: some View {
        GeometryReader { proxy in
            let layout = PatternSheetLayout(containerSize: proxy.size, columns: width, rows: height)

            ZStack {
                RoundedRectangle(cornerRadius: layout.sheetCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.08),
                                Color.black.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: layout.sheetCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .frame(
                        width: layout.contentSize.width + layout.beadInset * 3,
                        height: layout.contentSize.height + layout.beadInset * 3
                    )

                Canvas { context, _ in
                    for row in 0..<height {
                        for col in 0..<width {
                            let index = row * width + col
                            guard gridData.indices.contains(index) else { continue }

                            let cellRect = layout.cellRect(row: row, col: col)
                            let beadRect = cellRect.insetBy(dx: layout.beadInset, dy: layout.beadInset)
                            let beadPath = Path(roundedRect: beadRect, cornerRadius: layout.beadCornerRadius)
                            let beadColor = PatternSheetPalette.ironedColor(
                                for: gridData[index],
                                row: row,
                                col: col
                            )
                            let colorOpacity = gridData[index] == 0 ? 0.45 : 1.0

                            context.drawLayer { layer in
                                layer.addFilter(
                                    .shadow(
                                        color: .black.opacity(gridData[index] == 0 ? 0.05 : 0.14),
                                        radius: layout.cellSize * 0.08,
                                        x: layout.cellSize * 0.05,
                                        y: layout.cellSize * 0.08
                                    )
                                )
                                layer.fill(beadPath, with: .color(Color(uiColor: beadColor).opacity(colorOpacity)))
                            }

                            context.drawLayer { layer in
                                layer.clip(to: beadPath)

                                let highlightRect = beadRect
                                    .insetBy(dx: beadRect.width * 0.18, dy: beadRect.height * 0.18)
                                    .offsetBy(dx: -beadRect.width * 0.08, dy: -beadRect.height * 0.1)
                                let highlightPath = Path(ellipseIn: highlightRect)
                                layer.fill(
                                    highlightPath,
                                    with: .radialGradient(
                                        Gradient(colors: [
                                            .white.opacity(gridData[index] == 0 ? 0.12 : 0.36),
                                            .white.opacity(0.06),
                                            .clear
                                        ]),
                                        center: CGPoint(x: highlightRect.midX, y: highlightRect.midY),
                                        startRadius: 0,
                                        endRadius: max(highlightRect.width, highlightRect.height)
                                    )
                                )

                                let glossRect = CGRect(
                                    x: beadRect.minX,
                                    y: beadRect.minY,
                                    width: beadRect.width * 0.84,
                                    height: beadRect.height * 0.52
                                )
                                let glossPath = Path(roundedRect: glossRect, cornerRadius: layout.beadCornerRadius * 0.7)
                                layer.fill(
                                    glossPath,
                                    with: .linearGradient(
                                        Gradient(colors: [
                                            .white.opacity(gridData[index] == 0 ? 0.08 : 0.24),
                                            .white.opacity(0.02)
                                        ]),
                                        startPoint: CGPoint(x: glossRect.minX, y: glossRect.minY),
                                        endPoint: CGPoint(x: glossRect.maxX, y: glossRect.maxY)
                                    )
                                )

                                let shadowRect = beadRect.offsetBy(dx: beadRect.width * 0.08, dy: beadRect.height * 0.1)
                                let shadowPath = Path(ellipseIn: shadowRect)
                                layer.fill(
                                    shadowPath,
                                    with: .linearGradient(
                                        Gradient(colors: [
                                            .clear,
                                            .black.opacity(gridData[index] == 0 ? 0.03 : 0.12)
                                        ]),
                                        startPoint: CGPoint(x: shadowRect.minX, y: shadowRect.minY),
                                        endPoint: CGPoint(x: shadowRect.maxX, y: shadowRect.maxY)
                                    )
                                )
                            }
                        }
                    }
                }
                .frame(width: layout.contentSize.width, height: layout.contentSize.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension UIColor {
    func adjusted(saturation: CGFloat, brightness: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var currentSaturation: CGFloat = 0
        var currentBrightness: CGFloat = 0
        var alpha: CGFloat = 0

        if getHue(&hue, saturation: &currentSaturation, brightness: &currentBrightness, alpha: &alpha) {
            return UIColor(
                hue: hue,
                saturation: min(max(currentSaturation * saturation, 0), 1),
                brightness: min(max(currentBrightness * brightness, 0), 1),
                alpha: alpha
            )
        }

        var white: CGFloat = 0
        if getWhite(&white, alpha: &alpha) {
            return UIColor(
                white: min(max(white * brightness, 0), 1),
                alpha: alpha
            )
        }

        return self
    }
}
