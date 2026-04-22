import SwiftUI
import UIKit

struct CanvasView: View {
    var pattern: Pattern
    var viewModel: EditorViewModel

    private let cellSize: CGFloat = 20
    private let emptyCellBase = UIColor(red: 0.86, green: 0.87, blue: 0.89, alpha: 1)
    private let emptyCellAlt = UIColor(red: 0.79, green: 0.81, blue: 0.84, alpha: 1)
    private let emptyCellGrid = UIColor(red: 0.56, green: 0.59, blue: 0.64, alpha: 1)
    private let canvasBackground = UIColor.systemGroupedBackground

    var body: some View {
        NativeCanvasScrollView(
            pattern: pattern,
            viewModel: viewModel,
            cellSize: cellSize,
            emptyCellBase: emptyCellBase,
            emptyCellAlt: emptyCellAlt,
            emptyCellGrid: emptyCellGrid,
            canvasBackground: canvasBackground
        )
        .background(Color(.systemGroupedBackground))
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct NativeCanvasScrollView: UIViewRepresentable {
    var pattern: Pattern
    var viewModel: EditorViewModel
    let cellSize: CGFloat
    let emptyCellBase: UIColor
    let emptyCellAlt: UIColor
    let emptyCellGrid: UIColor
    let canvasBackground: UIColor

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.isOpaque = true
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.decelerationRate = .normal
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .systemGroupedBackground

        let containerView = UIView()
        containerView.isOpaque = true
        containerView.backgroundColor = canvasBackground

        let canvasView = PixelCanvasUIView()
        canvasView.isOpaque = true
        canvasView.backgroundColor = canvasBackground
        canvasView.isMultipleTouchEnabled = true
        canvasView.contentMode = .redraw

        containerView.addSubview(canvasView)
        scrollView.addSubview(containerView)
        
        // Add pan gesture to canvas for drawing when not in pan mode
        let canvasPanGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleCanvasPan(_:)))
        canvasPanGesture.maximumNumberOfTouches = 1
        canvasView.addGestureRecognizer(canvasPanGesture)
        context.coordinator.canvasPanGesture = canvasPanGesture
        context.coordinator.scrollView = scrollView
        context.coordinator.containerView = containerView
        context.coordinator.canvasView = canvasView

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let containerView = context.coordinator.containerView,
              let canvasView = context.coordinator.canvasView else { return }

        let canvasSize = PixelCanvasUIView.contentSize(
            width: pattern.width,
            height: pattern.height,
            cellSize: cellSize
        )

        canvasView.configure(
            gridData: pattern.gridData,
            width: pattern.width,
            height: pattern.height,
            cellSize: cellSize,
            showGrid: true,
            currentTool: viewModel.currentTool,
            selectedColorId: viewModel.selectedColorId,
            emptyCellBase: emptyCellBase,
            emptyCellAlt: emptyCellAlt,
            emptyCellGrid: emptyCellGrid,
            canvasBackground: canvasBackground,
            isPanMode: viewModel.isPanMode
        )

        canvasView.onBeginStroke = {
            viewModel.beginStroke(on: pattern)
        }
        canvasView.onPaintCell = { row, col in
            viewModel.paintCell(on: pattern, row: row, col: col)
        }

        if context.coordinator.canvasSize != canvasSize {
            containerView.frame = CGRect(origin: .zero, size: canvasSize)
            canvasView.frame = containerView.bounds
            scrollView.contentSize = canvasSize
            context.coordinator.canvasSize = canvasSize
            context.coordinator.didSetInitialZoom = false
        }

        scrollView.isScrollEnabled = viewModel.isPanMode
        scrollView.panGestureRecognizer.isEnabled = viewModel.isPanMode
        scrollView.pinchGestureRecognizer?.isEnabled = true
        canvasView.isUserInteractionEnabled = true
        
        // Canvas pan gesture should only be active when NOT in pan mode
        if let canvasPanGesture = context.coordinator.canvasPanGesture {
            canvasPanGesture.isEnabled = !viewModel.isPanMode
        }

        context.coordinator.updateZoomScalesIfNeeded()
        context.coordinator.centerContentIfNeeded()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        weak var containerView: UIView?
        weak var canvasView: PixelCanvasUIView?
        weak var canvasPanGesture: UIPanGestureRecognizer?
        var didSetInitialZoom = false
        var canvasSize: CGSize = .zero

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            containerView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContentIfNeeded()
        }

        func updateZoomScalesIfNeeded() {
            guard let scrollView, let containerView else { return }
            let rawBoundsSize = scrollView.bounds.size
            guard rawBoundsSize.width > 0, rawBoundsSize.height > 0,
                  containerView.bounds.width > 0, containerView.bounds.height > 0 else { return }

            let paddedBoundsSize = CGSize(
                width: max(rawBoundsSize.width - 32, 1),
                height: max(rawBoundsSize.height - 32, 1)
            )

            let widthScale = paddedBoundsSize.width / containerView.bounds.width
            let heightScale = paddedBoundsSize.height / containerView.bounds.height
            let fitScale = min(widthScale, heightScale)
            let initialScale = preferredInitialScale(for: fitScale)
            let minScale = max(min(initialScale * 0.45, fitScale), 0.08)
            let maxScale = max(initialScale * 10, 8)

            scrollView.minimumZoomScale = minScale
            scrollView.maximumZoomScale = maxScale

            if !didSetInitialZoom {
                scrollView.setZoomScale(initialScale, animated: false)
                didSetInitialZoom = true
            } else if scrollView.zoomScale < minScale {
                scrollView.setZoomScale(minScale, animated: false)
            }
        }

        private func preferredInitialScale(for fitScale: CGFloat) -> CGFloat {
            let paddedFitScale = fitScale * 0.92

            if fitScale >= 3.2 {
                return 2.4
            }

            if fitScale >= 2.2 {
                return 2.0
            }

            if fitScale >= 1.2 {
                return min(paddedFitScale, 1.6)
            }

            return max(paddedFitScale, 0.12)
        }

        func centerContentIfNeeded() {
            guard let scrollView, let containerView else { return }
            let boundsSize = scrollView.bounds.size
            let contentSize = scrollView.contentSize

            let offsetX = max((boundsSize.width - contentSize.width) * 0.5, 0)
            let offsetY = max((boundsSize.height - contentSize.height) * 0.5, 0)
            containerView.center = CGPoint(
                x: contentSize.width * 0.5 + offsetX,
                y: contentSize.height * 0.5 + offsetY
            )
        }

        @objc func handleCanvasPan(_ gesture: UIPanGestureRecognizer) {
            guard let canvasView = gesture.view as? PixelCanvasUIView else { return }
            
            // If there are 2+ touches, let the pinch gesture handle it
            if gesture.numberOfTouches > 1 {
                if gesture.state == .began || gesture.state == .changed {
                    canvasView.handlePanEnded()
                }
                return
            }
            
            let point = gesture.location(in: canvasView)
            
            switch gesture.state {
            case .began:
                canvasView.handlePanBegan(at: point)
            case .changed:
                canvasView.handlePanChanged(at: point)
            case .ended, .cancelled:
                canvasView.handlePanEnded()
            default:
                break
            }
        }
    }
}

private final class PixelCanvasUIView: UIView {
    private static let rulerThickness: CGFloat = 28

    var onBeginStroke: (() -> Void)?
    var onPaintCell: ((Int, Int) -> Void)?

    private var gridData: [Int] = []
    private var widthCount = 0
    private var heightCount = 0
    private var cellSize: CGFloat = 20
    private var showGrid = true
    private var currentTool: DrawingTool = .pen
    private var selectedColorId = 1
    private var emptyCellBase = UIColor.lightGray
    private var emptyCellAlt = UIColor.gray
    private var emptyCellGrid = UIColor.darkGray
    private var canvasBackground = UIColor.systemGroupedBackground
    private var lastTouchedCell: CGPoint?
    private var didBeginStroke = false
    private var isPanMode = false

    override class var layerClass: AnyClass {
        CATiledLayer.self
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        contentScaleFactor = 1
        if let tiledLayer = layer as? CATiledLayer {
            tiledLayer.levelsOfDetail = 4
            tiledLayer.levelsOfDetailBias = 4
            tiledLayer.tileSize = CGSize(width: 512, height: 512)
        }
    }

    static func contentSize(width: Int, height: Int, cellSize: CGFloat) -> CGSize {
        CGSize(
            width: CGFloat(width) * cellSize + rulerThickness * 2,
            height: CGFloat(height) * cellSize + rulerThickness * 2
        )
    }

    private var gridOrigin: CGPoint {
        CGPoint(x: Self.rulerThickness, y: Self.rulerThickness)
    }

    private var gridRect: CGRect {
        CGRect(
            x: gridOrigin.x,
            y: gridOrigin.y,
            width: CGFloat(widthCount) * cellSize,
            height: CGFloat(heightCount) * cellSize
        )
    }

    func configure(
        gridData: [Int],
        width: Int,
        height: Int,
        cellSize: CGFloat,
        showGrid: Bool,
        currentTool: DrawingTool,
        selectedColorId: Int,
        emptyCellBase: UIColor,
        emptyCellAlt: UIColor,
        emptyCellGrid: UIColor,
        canvasBackground: UIColor,
        isPanMode: Bool
    ) {
        let needsDisplay =
            self.gridData != gridData ||
            self.widthCount != width ||
            self.heightCount != height ||
            self.showGrid != showGrid ||
            self.cellSize != cellSize

        self.gridData = gridData
        self.widthCount = width
        self.heightCount = height
        self.cellSize = cellSize
        self.showGrid = showGrid
        self.currentTool = currentTool
        self.selectedColorId = selectedColorId
        self.emptyCellBase = emptyCellBase
        self.emptyCellAlt = emptyCellAlt
        self.emptyCellGrid = emptyCellGrid
        self.canvasBackground = canvasBackground
        self.isPanMode = isPanMode

        if needsDisplay {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let gridRect = gridRect

        context.setFillColor(canvasBackground.cgColor)
        context.fill(rect)

        drawRulers(in: context, rect: rect, gridRect: gridRect)

        let visibleGridRect = rect.intersection(gridRect)
        guard !visibleGridRect.isNull else {
            drawGridBorder(in: context, gridRect: gridRect)
            return
        }

        let startCol = max(Int(floor((visibleGridRect.minX - gridRect.minX) / cellSize)), 0)
        let endCol = min(Int(ceil((visibleGridRect.maxX - gridRect.minX) / cellSize)), widthCount)
        let startRow = max(Int(floor((visibleGridRect.minY - gridRect.minY) / cellSize)), 0)
        let endRow = min(Int(ceil((visibleGridRect.maxY - gridRect.minY) / cellSize)), heightCount)

        for row in startRow..<endRow {
            for col in startCol..<endCol {
                let idx = row * widthCount + col
                guard idx < gridData.count else { continue }

                let cellRect = CGRect(
                    x: gridRect.minX + CGFloat(col) * cellSize,
                    y: gridRect.minY + CGFloat(row) * cellSize,
                    width: cellSize,
                    height: cellSize
                )

                let colorId = gridData[idx]
                if colorId != 0, let bead = BeadColorLibrary.color(id: colorId) {
                    context.setFillColor(bead.uiColor.cgColor)
                    context.fill(cellRect)
                } else {
                    let baseColor = (row + col).isMultiple(of: 2) ? emptyCellBase : emptyCellAlt
                    drawMosaicCell(in: context, cellRect: cellRect, color: baseColor)
                }

                if showGrid {
                    context.setStrokeColor(emptyCellGrid.withAlphaComponent(0.55).cgColor)
                    context.setLineWidth(0.5)
                    context.stroke(cellRect)
                }
            }
        }

        drawGridBorder(in: context, gridRect: gridRect)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        // In pan mode, ignore touches (let scroll view handle pan/zoom)
        guard !isPanMode else { return }
        // Only handle single touch for drawing
        guard touches.count == 1 else { return }
        handleTouchSequence(touches, isContinuous: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        // In pan mode, ignore touches (let scroll view handle pan/zoom)
        guard !isPanMode else { return }
        // Only handle single touch for drawing
        guard touches.count == 1 else { return }
        handleTouchSequence(touches, isContinuous: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        resetTouchState()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        resetTouchState()
    }

    private func handleTouchSequence(_ touches: Set<UITouch>, isContinuous: Bool) {
        guard let touch = touches.first else { return }
        
        let point = touch.location(in: self)
        guard let cell = cell(at: point) else { return }

        if CGPoint(x: cell.col, y: cell.row) == lastTouchedCell {
            return
        }

        if !didBeginStroke {
            onBeginStroke?()
            didBeginStroke = true
        }

        onPaintCell?(cell.row, cell.col)
        lastTouchedCell = CGPoint(x: cell.col, y: cell.row)

        if !isContinuous {
            resetTouchState()
        }
    }

    private func cell(at point: CGPoint) -> (row: Int, col: Int)? {
        let localX = point.x - gridOrigin.x
        let localY = point.y - gridOrigin.y
        guard localX >= 0, localY >= 0 else { return nil }
        let col = Int(localX / cellSize)
        let row = Int(localY / cellSize)
        guard row >= 0, row < heightCount, col >= 0, col < widthCount else { return nil }
        return (row, col)
    }

    // MARK: - Pan Gesture Handling for Drawing

    func handlePanBegan(at point: CGPoint) {
        guard let cell = cell(at: point) else { return }
        onBeginStroke?()
        onPaintCell?(cell.row, cell.col)
        lastTouchedCell = CGPoint(x: cell.col, y: cell.row)
        didBeginStroke = true
    }

    func handlePanChanged(at point: CGPoint) {
        guard let cell = cell(at: point) else { return }
        guard CGPoint(x: cell.col, y: cell.row) != lastTouchedCell else { return }
        onPaintCell?(cell.row, cell.col)
        lastTouchedCell = CGPoint(x: cell.col, y: cell.row)
    }

    func handlePanEnded() {
        resetTouchState()
    }

    private func drawRulers(in context: CGContext, rect: CGRect, gridRect: CGRect) {
        let rulerColor = UIColor.secondarySystemBackground
        let labelColor = UIColor.secondaryLabel

        let topRect = CGRect(x: gridRect.minX, y: 0, width: gridRect.width, height: Self.rulerThickness)
        let bottomRect = CGRect(
            x: gridRect.minX,
            y: gridRect.maxY,
            width: gridRect.width,
            height: Self.rulerThickness
        )
        let leftRect = CGRect(x: 0, y: gridRect.minY, width: Self.rulerThickness, height: gridRect.height)
        let rightRect = CGRect(
            x: gridRect.maxX,
            y: gridRect.minY,
            width: Self.rulerThickness,
            height: gridRect.height
        )

        context.setFillColor(rulerColor.cgColor)
        for band in [topRect, bottomRect, leftRect, rightRect] where band.intersects(rect) {
            context.fill(band)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: labelColor
        ]

        drawCornerBlocks(in: context, rect: rect, color: rulerColor, gridRect: gridRect)

        for col in 0..<widthCount {
            drawColumnMarker(col, gridRect: gridRect, visibleRect: rect, attributes: attributes)
        }

        for row in 0..<heightCount {
            drawRowMarker(row, gridRect: gridRect, visibleRect: rect, attributes: attributes)
        }
    }

    private func drawCornerBlocks(in context: CGContext, rect: CGRect, color: UIColor, gridRect: CGRect) {
        let corners = [
            CGRect(x: 0, y: 0, width: Self.rulerThickness, height: Self.rulerThickness),
            CGRect(x: gridRect.maxX, y: 0, width: Self.rulerThickness, height: Self.rulerThickness),
            CGRect(x: 0, y: gridRect.maxY, width: Self.rulerThickness, height: Self.rulerThickness),
            CGRect(
                x: gridRect.maxX,
                y: gridRect.maxY,
                width: Self.rulerThickness,
                height: Self.rulerThickness
            )
        ]

        context.setFillColor(color.cgColor)
        for corner in corners where corner.intersects(rect) {
            context.fill(corner)
        }
    }

    private func drawColumnMarker(
        _ col: Int,
        gridRect: CGRect,
        visibleRect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let label = "\(col + 1)" as NSString
        let labelSize = label.size(withAttributes: attributes)
        let centerX = gridRect.minX + CGFloat(col) * cellSize + cellSize * 0.5
        let topRect = CGRect(
            x: centerX - labelSize.width * 0.5,
            y: (Self.rulerThickness - labelSize.height) * 0.5,
            width: labelSize.width,
            height: labelSize.height
        )
        let bottomRect = CGRect(
            x: centerX - labelSize.width * 0.5,
            y: gridRect.maxY + (Self.rulerThickness - labelSize.height) * 0.5,
            width: labelSize.width,
            height: labelSize.height
        )

        if topRect.intersects(visibleRect) {
            label.draw(in: topRect.integral, withAttributes: attributes)
        }
        if bottomRect.intersects(visibleRect) {
            label.draw(in: bottomRect.integral, withAttributes: attributes)
        }
    }

    private func drawRowMarker(
        _ row: Int,
        gridRect: CGRect,
        visibleRect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let label = "\(row + 1)" as NSString
        let labelSize = label.size(withAttributes: attributes)
        let centerY = gridRect.minY + CGFloat(row) * cellSize + cellSize * 0.5
        let leftRect = CGRect(
            x: (Self.rulerThickness - labelSize.width) * 0.5,
            y: centerY - labelSize.height * 0.5,
            width: labelSize.width,
            height: labelSize.height
        )
        let rightRect = CGRect(
            x: gridRect.maxX + (Self.rulerThickness - labelSize.width) * 0.5,
            y: centerY - labelSize.height * 0.5,
            width: labelSize.width,
            height: labelSize.height
        )

        if leftRect.intersects(visibleRect) {
            label.draw(in: leftRect.integral, withAttributes: attributes)
        }
        if rightRect.intersects(visibleRect) {
            label.draw(in: rightRect.integral, withAttributes: attributes)
        }
    }

    private func drawGridBorder(in context: CGContext, gridRect: CGRect) {
        context.setStrokeColor(emptyCellGrid.withAlphaComponent(0.85).cgColor)
        context.setLineWidth(1)
        context.stroke(gridRect.insetBy(dx: 0.5, dy: 0.5))
    }

    private func drawMosaicCell(in context: CGContext, cellRect: CGRect, color: UIColor) {
        let rows = 4
        let cols = 4
        let tileWidth = cellRect.width / CGFloat(cols)
        let tileHeight = cellRect.height / CGFloat(rows)
        let offsets: [[CGFloat]] = [
            [0.030, -0.018, 0.030, -0.018],
            [-0.018, 0.030, -0.018, 0.030],
            [0.030, -0.018, 0.030, -0.018],
            [-0.018, 0.030, -0.018, 0.030]
        ]

        for row in 0..<rows {
            for col in 0..<cols {
                let originX = cellRect.minX + CGFloat(col) * tileWidth
                let originY = cellRect.minY + CGFloat(row) * tileHeight
                let tileRect = CGRect(
                    x: originX,
                    y: originY,
                    width: col == cols - 1 ? cellRect.maxX - originX : tileWidth,
                    height: row == rows - 1 ? cellRect.maxY - originY : tileHeight
                )

                context.setFillColor(color.mosaicAdjusted(by: offsets[row][col]).cgColor)
                context.fill(tileRect.integral)
            }
        }
    }

    private func resetTouchState() {
        lastTouchedCell = nil
        didBeginStroke = false
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
