import SwiftUI

struct DraftReferenceView: View {
    let pattern: Pattern
    @ObservedObject var createStore: CreateStore
    @Binding var selectedTab: AppTab

    /// Optional trailing toolbar button. Pass `nil` for view-only mode.
    var actionTitle: String? = nil
    var onAction: (() -> Void)? = nil

    @State private var canvasScale: Double = 1.0
    @State private var canvasOffset: CGSize = .zero
    @State private var viewportSize: CGSize = .zero
    @State private var hasInitialized = false
    @State private var isLegendExpanded = true

    private let minScale: Double = 0.4
    private let maxScale: Double = 5.0

    private var cellSize: CGFloat {
        let d = max(pattern.width, pattern.height)
        if d <= 20 { return 18 }
        if d <= 29 { return 14 }
        if d <= 32 { return 12 }
        return 10
    }

    private var gutter: CGFloat { min(max(cellSize * CGFloat(canvasScale) * 1.35, 20), 32) }

    private var boardSize: CGSize {
        CGSize(
            width: CGFloat(pattern.width) * cellSize * canvasScale,
            height: CGFloat(pattern.height) * cellSize * canvasScale
        )
    }

    private var canvasSize: CGSize {
        CGSize(width: boardSize.width + gutter * 2, height: boardSize.height + gutter * 2)
    }

    private func centeredOffset(for viewport: CGSize) -> CGSize {
        CGSize(
            width: (viewport.width - canvasSize.width) / 2,
            height: (viewport.height - canvasSize.height) / 2
        )
    }

    private func clampedOffset(_ offset: CGSize, viewport: CGSize) -> CGSize {
        guard viewport.width > 0 else { return offset }
        let minVisible: CGFloat = 0.25
        func clamp(value: CGFloat, canvasDim: CGFloat, viewportDim: CGFloat) -> CGFloat {
            if canvasDim > viewportDim {
                return min(max(value, viewportDim * minVisible - canvasDim), viewportDim * (1 - minVisible))
            } else {
                let center = (viewportDim - canvasDim) / 2
                return center
            }
        }
        return CGSize(
            width: clamp(value: offset.width, canvasDim: canvasSize.width, viewportDim: viewport.width),
            height: clamp(value: offset.height, canvasDim: canvasSize.height, viewportDim: viewport.height)
        )
    }

    // MARK: - Color stats
    private var colorStats: [(beadColor: BeadColor?, hex: String, count: Int)] {
        var counts: [String: Int] = [:]
        for pixel in pattern.pixels where pixel.colorHex != nil {
            counts[pixel.colorHex!, default: 0] += 1
        }
        return counts
            .map { (MockData.beadColor(for: $0.key), $0.key, $0.value) }
            .sorted { $0.2 > $1.2 }
    }

    private var totalBeads: Int { colorStats.reduce(0) { $0 + $1.count } }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ReferenceCanvas(
                    pattern: pattern,
                    scale: canvasScale,
                    offset: canvasOffset
                )
                .background(Color(red: 0.96, green: 0.93, blue: 0.86))
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = min(max(canvasScale * value, minScale), maxScale)
                            canvasScale = newScale
                            canvasOffset = clampedOffset(canvasOffset, viewport: geo.size)
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            canvasOffset = clampedOffset(
                                CGSize(width: canvasOffset.width + value.translation.width,
                                       height: canvasOffset.height + value.translation.height),
                                viewport: geo.size
                            )
                        }
                )
                .onAppear {
                    guard !hasInitialized else { return }
                    viewportSize = geo.size
                    canvasOffset = centeredOffset(for: geo.size)
                    hasInitialized = true
                }
                .onChange(of: geo.size) { _, size in
                    viewportSize = size
                    canvasOffset = clampedOffset(canvasOffset, viewport: size)
                }
            }
            .frame(maxHeight: .infinity)

            colorLegendPanel
        }
        .navigationTitle(pattern.title.isEmpty ? L10n.tr("Draft") : pattern.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            canvasScale = 1.0
                            canvasOffset = centeredOffset(for: viewportSize)
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.subheadline.weight(.semibold))
                    }

                    if let title = actionTitle, let action = onAction {
                        Button(action: action) {
                            Text(L10n.tr(title))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PixelBeadsTheme.coral)
                        }
                    }
                }
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .background(Color(red: 0.96, green: 0.93, blue: 0.86).ignoresSafeArea())
        .pbScreen()
    }

    // MARK: - Color legend

    private var colorLegendPanel: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    isLegendExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "swatchpalette.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PixelBeadsTheme.coral)
                    Text(L10n.tr("%d colors · %d beads", colorStats.count, totalBeads))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PixelBeadsTheme.ink)
                    Spacer()
                    Image(systemName: isLegendExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isLegendExpanded {
                Divider()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(colorStats, id: \.hex) { stat in
                            colorChip(stat: stat)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(PixelBeadsTheme.canvas)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func colorChip(stat: (beadColor: BeadColor?, hex: String, count: Int)) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: stat.hex))
                    .frame(width: 32, height: 32)
                    .shadow(color: Color.black.opacity(0.12), radius: 3, y: 1)
                Circle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 10, height: 10)
                    .offset(x: -6, y: -6)
            }
            if let code = stat.beadColor?.code {
                Text(code)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(PixelBeadsTheme.ink)
            } else {
                Text(String(stat.hex.dropFirst()).prefix(4).uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Text("×\(stat.count)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 40)
    }
}

// MARK: - Canvas

private struct ReferenceCanvas: View {
    let pattern: Pattern
    let scale: Double
    let offset: CGSize

    private var cellSize: CGFloat {
        let d = max(pattern.width, pattern.height)
        if d <= 20 { return 18 }
        if d <= 29 { return 14 }
        if d <= 32 { return 12 }
        return 10
    }

    private var scaledCell: CGFloat { cellSize * CGFloat(scale) }
    private var gutter: CGFloat { min(max(scaledCell * 1.35, 20), 32) }
    private var boardSize: CGSize {
        CGSize(width: CGFloat(pattern.width) * scaledCell, height: CGFloat(pattern.height) * scaledCell)
    }
    private var canvasSize: CGSize {
        CGSize(width: boardSize.width + gutter * 2, height: boardSize.height + gutter * 2)
    }

    var body: some View {
        Canvas { context, size in
            let visualRect = CGRect(origin: CGPoint(x: offset.width, y: offset.height), size: canvasSize)
            let boardRect = CGRect(
                x: visualRect.minX + gutter, y: visualRect.minY + gutter,
                width: boardSize.width, height: boardSize.height
            )
            let cw = boardSize.width / CGFloat(pattern.width)
            let ch = boardSize.height / CGFloat(pattern.height)
            let colorMap = pattern.pixels.colorMap()

            // Board background
            context.fill(
                Path(roundedRect: boardRect, cornerRadius: cw * 0.7),
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.92), Color(red: 0.93, green: 0.91, blue: 0.84).opacity(0.72)]),
                    startPoint: boardRect.origin,
                    endPoint: CGPoint(x: boardRect.maxX, y: boardRect.maxY)
                )
            )

            // Cells
            for row in 0..<pattern.height {
                for col in 0..<pattern.width {
                    let rect = CGRect(
                        x: boardRect.minX + CGFloat(col) * cw,
                        y: boardRect.minY + CGFloat(row) * ch,
                        width: cw, height: ch
                    )
                    let hex = colorMap["\(col)-\(row)"] ?? nil
                    drawCell(in: &context, rect: rect, hex: hex, cw: cw, ch: ch)
                    context.stroke(Path(rect), with: .color(Color.black.opacity(0.04)), lineWidth: 0.45)
                }
            }

            drawCoordinates(in: &context, visualRect: visualRect, boardRect: boardRect, cw: cw, ch: ch)
        }
        .contentShape(Rectangle())
    }

    private func drawCell(in context: inout GraphicsContext, rect: CGRect, hex: String?, cw: CGFloat, ch: CGFloat) {
        let pegRect = rect.insetBy(dx: cw * 0.34, dy: ch * 0.34)
        context.fill(Path(ellipseIn: pegRect.offsetBy(dx: 0, dy: ch * 0.035)), with: .color(Color.black.opacity(0.08)))
        context.fill(Path(ellipseIn: pegRect), with: .color(Color.white.opacity(0.72)))

        guard let color = hex.flatMap(Color.init(hex:)) else { return }

        let beadRect = rect.insetBy(dx: cw * 0.06, dy: ch * 0.06)
        context.fill(Path(ellipseIn: beadRect.offsetBy(dx: 0, dy: ch * 0.07)), with: .color(Color.black.opacity(0.15)))
        context.fill(Path(roundedRect: beadRect, cornerRadius: cw * 0.12), with: .color(color))
        context.stroke(Path(roundedRect: beadRect, cornerRadius: cw * 0.12), with: .color(Color.black.opacity(0.10)), lineWidth: 0.6)

        let hl = CGRect(x: rect.minX + cw * 0.18, y: rect.minY + cw * 0.14, width: cw * 0.22, height: ch * 0.12)
        context.fill(Path(ellipseIn: hl), with: .color(Color.white.opacity(0.38)))
    }

    private func drawCoordinates(in context: inout GraphicsContext, visualRect: CGRect, boardRect: CGRect, cw: CGFloat, ch: CGFloat) {
        let step = cw >= 12 ? 1 : cw >= 8 ? 2 : cw >= 5 ? 4 : 6
        let fontSize = min(max(min(cw, ch) * 0.46, 7), 11)
        let labelColor = Color.black.opacity(0.45)

        for col in 0..<pattern.width where col == 0 || col == pattern.width - 1 || col % step == 0 {
            let t = Text("\(col + 1)").font(.system(size: fontSize, weight: .bold, design: .rounded)).foregroundStyle(labelColor)
            let x = boardRect.minX + (CGFloat(col) + 0.5) * cw
            context.draw(t, at: CGPoint(x: x, y: visualRect.minY + gutter * 0.46), anchor: .center)
            context.draw(t, at: CGPoint(x: x, y: boardRect.maxY + gutter * 0.54), anchor: .center)
        }
        for row in 0..<pattern.height where row == 0 || row == pattern.height - 1 || row % step == 0 {
            let t = Text("\(row + 1)").font(.system(size: fontSize, weight: .bold, design: .rounded)).foregroundStyle(labelColor)
            let y = boardRect.minY + (CGFloat(row) + 0.5) * ch
            context.draw(t, at: CGPoint(x: visualRect.minX + gutter * 0.46, y: y), anchor: .center)
            context.draw(t, at: CGPoint(x: boardRect.maxX + gutter * 0.54, y: y), anchor: .center)
        }
    }
}
