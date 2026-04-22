import SwiftUI
import UIKit

struct IroningAnimationView: View {
    let patternName: String
    let width: Int
    let height: Int
    let gridData: [Int]
    let namespace: Namespace.ID

    @Binding var isPresented: Bool

    let onFinished: () -> Void

    @State private var rotation = 0.0
    @State private var showsFinishedSide = false
    @State private var showsCelebration = false
    @State private var showsFinishedBadge = false
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
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

            VStack(spacing: 24) {
                Spacer(minLength: 40)

                VStack(spacing: 10) {
                    Text(patternName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(showsFinishedSide ? "熨烫完成" : "正在翻面熨烫")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.28), radius: 30, y: 18)

                    Group {
                        if showsFinishedSide {
                            IronedPatternView(width: width, height: height, gridData: gridData)
                                .matchedGeometryEffect(id: "pattern-sheet", in: namespace)
                        } else {
                            PixelPatternPreview(width: width, height: height, gridData: gridData)
                                .matchedGeometryEffect(id: "pattern-sheet", in: namespace)
                        }
                    }
                    .padding(28)
                    .rotation3DEffect(.degrees(showsFinishedSide ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                }
                .frame(maxWidth: 520)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 20)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.72)

                if showsFinishedBadge {
                    Label("完成", systemImage: "checkmark.circle.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.9))
                        .clipShape(Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: 40)
            }

            if showsCelebration {
                SparkleCelebrationView()
                    .transition(.opacity)
            }
        }
        .statusBarHidden()
        .onAppear(perform: runAnimationSequence)
        .onDisappear {
            animationTask?.cancel()
            animationTask = nil
        }
        .onTapGesture {
            if showsFinishedSide {
                dismissAnimation()
            }
        }
    }

    private func runAnimationSequence() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.4)) {
                rotation = 90
            }

            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled, isPresented else { return }

            showsFinishedSide = true

            withAnimation(.easeInOut(duration: 0.4)) {
                rotation = 180
            }

            try? await Task.sleep(nanoseconds: 420_000_000)
            guard !Task.isCancelled, isPresented else { return }

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()

            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                showsCelebration = true
                showsFinishedBadge = true
            }

            try? await Task.sleep(nanoseconds: 1_030_000_000)
            guard !Task.isCancelled, isPresented else { return }
            dismissAnimation()
        }
    }

    private func dismissAnimation() {
        guard isPresented else { return }
        animationTask?.cancel()
        animationTask = nil

        withAnimation(.easeOut(duration: 0.25)) {
            isPresented = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onFinished()
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
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "star.fill")
                        .font(.system(size: sparkle.size, weight: .semibold))
                        .foregroundStyle(.white, Color.yellow.opacity(0.85))
                        .shadow(color: .white.opacity(0.35), radius: 8)
                        .scaleEffect(animate ? 1.28 : 0.25)
                        .opacity(animate ? 0 : 0.96)
                        .position(
                            x: proxy.size.width * sparkle.x + (animate ? sparkle.dx : 0),
                            y: proxy.size.height * sparkle.y + (animate ? sparkle.dy : 0)
                        )
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
