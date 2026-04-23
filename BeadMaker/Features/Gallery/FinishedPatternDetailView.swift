import SwiftUI
import UIKit

struct FinishedPatternDetailView: View {
    enum EntryMode {
        case direct
        case ironing
    }

    let pattern: FinishedPattern
    let entryMode: EntryMode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationModel: GalleryNavigationModel
    @State private var rotation = 180.0
    @State private var showsFinishedSide = true
    @State private var showsCelebration = false
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            FinishedPresentationBackground()

            if entryMode == .ironing {
                ironingContent
            } else {
                FinishedPresentationCard(
                    width: pattern.width,
                    height: pattern.height,
                    gridData: pattern.gridData
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }

            if showsCelebration {
                SparkleCelebrationView()
                    .transition(.opacity)
            }
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navigationModel.openPatternViewer(
                        title: pattern.name,
                        width: pattern.width,
                        height: pattern.height,
                        gridData: pattern.gridData
                    )
                } label: {
                    Image(systemName: "eye")
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear(perform: configureEntry)
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
    }

    private var ironingContent: some View {
        ZStack {
            // 内容层（带翻转动画）
            Group {
                if showsFinishedSide {
                    IronedPatternView(
                        width: pattern.width,
                        height: pattern.height,
                        gridData: pattern.gridData,
                        showsPlate: false
                    )
                } else {
                    PixelPatternPreview(
                        width: pattern.width,
                        height: pattern.height,
                        gridData: pattern.gridData
                    )
                }
            }
            .padding(28)
            .rotation3DEffect(.degrees(showsFinishedSide ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: 520)
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 20)
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.72)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func configureEntry() {
        animationTask?.cancel()

        switch entryMode {
        case .direct:
            rotation = 180
            showsFinishedSide = true
            showsCelebration = false
        case .ironing:
            rotation = 0
            showsFinishedSide = false
            showsCelebration = false
            runIroningSequence()
        }
    }

    private func runIroningSequence() {
        animationTask = Task { @MainActor in
            // Phase 1: 开始翻转 (0° → 90°)
            withAnimation(.easeIn(duration: 0.35)) {
                rotation = 90
            }

            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            // Phase 2: 切换面并继续翻转 (90° → 180°)
            showsFinishedSide = true

            withAnimation(.easeOut(duration: 0.45)) {
                rotation = 180
            }

            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            // Phase 3: 翻转完成，触发震动反馈
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()

            // Phase 4: 粒子庆祝动画
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showsCelebration = true
            }

            // Phase 5: 自动隐藏庆祝动画
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.5)) {
                showsCelebration = false
            }
        }
    }

}

struct PatternViewerScreen: View {
    let title: String
    let width: Int
    let height: Int
    let gridData: [Int]

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = EditorViewModel()
    private let previewPattern: Pattern

    init(title: String, width: Int, height: Int, gridData: [Int]) {
        self.title = title
        self.width = width
        self.height = height
        self.gridData = gridData
        let previewPattern = Pattern(name: title, width: width, height: height)
        previewPattern.gridData = gridData
        previewPattern.thumbnailData = PatternRenderer.thumbnail(pattern: previewPattern).pngData()
        self.previewPattern = previewPattern
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            CanvasView(pattern: previewPattern, viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            viewModel.resetForCanvasOpen()
            viewModel.isPanMode = true
        }
    }
}

struct FinishedPresentationBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.84),
                Color(red: 0.12, green: 0.13, blue: 0.18),
                Color.black.opacity(0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct FinishedPresentationCard: View {
    let width: Int
    let height: Int
    let gridData: [Int]

    var body: some View {
        IronedPatternView(
            width: width,
            height: height,
            gridData: gridData,
            showsPlate: false
        )
        .frame(maxWidth: 520)
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 20)
    }
}

struct CircularToolbarButton: View {
    enum Style {
        case lightOnDark
        case lightOnLight
    }

    let icon: String
    let action: () -> Void
    var style: Style = .lightOnDark

    private var foregroundColor: Color {
        switch style {
        case .lightOnDark:
            return .white
        case .lightOnLight:
            return Color.black.opacity(0.82)
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}



private struct PixelPatternPreview: View {
    let width: Int
    let height: Int
    let gridData: [Int]

    var body: some View {
        GeometryReader { proxy in
            let layout = PatternSheetLayout(containerSize: proxy.size, columns: width, rows: height)

            Canvas { context, _ in
                let bounds = CGRect(origin: .zero, size: layout.contentSize)
                let boardPath = Path(roundedRect: bounds, cornerRadius: max(layout.cellSize * 0.16, 10))

                context.fill(boardPath, with: .color(Color(.secondarySystemBackground)))

                for row in 0..<height {
                    for col in 0..<width {
                        let index = row * width + col
                        guard gridData.indices.contains(index) else { continue }

                        let cellRect = layout.cellRect(row: row, col: col)
                        let cellPath = Path(cellRect)
                        let fillColor = PatternSheetPalette.pixelColor(
                            for: gridData[index],
                            row: row,
                            col: col
                        )
                        context.fill(cellPath, with: .color(fillColor))
                    }
                }

                var gridPath = Path()
                for row in 0...height {
                    let y = CGFloat(row) * layout.cellSize
                    gridPath.move(to: CGPoint(x: 0, y: y))
                    gridPath.addLine(to: CGPoint(x: layout.contentSize.width, y: y))
                }

                for col in 0...width {
                    let x = CGFloat(col) * layout.cellSize
                    gridPath.move(to: CGPoint(x: x, y: 0))
                    gridPath.addLine(to: CGPoint(x: x, y: layout.contentSize.height))
                }

                context.stroke(
                    gridPath,
                    with: .color(Color.black.opacity(0.18)),
                    lineWidth: max(layout.cellSize * 0.06, 0.65)
                )
            }
            .frame(width: layout.contentSize.width, height: layout.contentSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct SparkleCelebrationView: View {
    @State private var animate = false

    private let sparkles: [SparkleParticle] = [
        .init(x: 0.22, y: 0.28, size: 18, dx: -18, dy: -34),
        .init(x: 0.34, y: 0.2, size: 14, dx: -10, dy: -28),
        .init(x: 0.48, y: 0.16, size: 22, dx: 0, dy: -36),
        .init(x: 0.63, y: 0.2, size: 16, dx: 16, dy: -26),
        .init(x: 0.76, y: 0.28, size: 18, dx: 22, dy: -30),
        .init(x: 0.29, y: 0.66, size: 14, dx: -18, dy: 30),
        .init(x: 0.44, y: 0.74, size: 20, dx: -8, dy: 34),
        .init(x: 0.56, y: 0.74, size: 20, dx: 8, dy: 34),
        .init(x: 0.71, y: 0.66, size: 14, dx: 18, dy: 30)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(Array(sparkles.enumerated()), id: \.offset) { index, sparkle in
                    Image(systemName: "sparkle")
                        .font(.system(size: sparkle.size, weight: .semibold))
                        .foregroundStyle(.white, Color.white.opacity(0.45))
                        .position(
                            x: proxy.size.width * sparkle.x + (animate ? sparkle.dx : 0),
                            y: proxy.size.height * sparkle.y + (animate ? sparkle.dy : 0)
                        )
                        .scaleEffect(animate ? 1 : 0.3)
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: 0.82).delay(Double(index) * 0.03),
                            value: animate
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }
}

private struct SparkleParticle {
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let dx: CGFloat
    let dy: CGFloat
}
