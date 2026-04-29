import SwiftUI

struct PreviewView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var proStatusManager: ProStatusManager
    @EnvironmentObject private var appleSignInManager: AppleSignInManager

    @Environment(\.dismiss) private var dismiss
    @State private var animationID = UUID()
    @State private var isShowingShareSheet = false
    @State private var finishedPattern: Pattern?
    @State private var isDuplicateAlertShown = false
    @State private var isShowingProInfo = false

    private var isPublished: Bool {
        createStore.currentPattern.visibility == .public
    }

    var body: some View {
        VStack(spacing: 20) {
            AnimatedFinishedPreview(pattern: createStore.currentPattern, animationID: animationID)
                .padding(.top, 8)

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Button {
                        animationID = UUID()
                    } label: {
                        Label(L10n.tr("Replay Finished Animation"), systemImage: "play.circle")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        let result = createStore.finalizeLocally(user: sessionStore.currentUser)
                        libraryStore.load(for: sessionStore.currentUser)
                        if result.isDuplicate {
                            isDuplicateAlertShown = true
                        } else {
                            finishedPattern = result.pattern
                            isShowingShareSheet = true
                            createStore.resetToBlank(user: sessionStore.currentUser)
                        }
                    } label: {
                        Label(L10n.tr("Finish"), systemImage: "checkmark.seal")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                if AppFeatureFlags.communityEnabled, isPublished {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(L10n.tr("Published"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                } else if AppFeatureFlags.communityEnabled {
                    Button {
                        let success = createStore.publishAndFinalize(user: sessionStore.currentUser)
                        if success {
                            libraryStore.load(for: sessionStore.currentUser)
                        } else {
                        isShowingProInfo = true
                        }
                    } label: {
                        Label(L10n.tr("Publish Pattern"), systemImage: "globe")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(L10n.tr("Finished"))
        .background(BeadsMakerTheme.surface)
        .onAppear {
            createStore.previewMode = .pixel
            animationID = UUID()
        }
        .alert(L10n.tr("Already Saved"), isPresented: $isDuplicateAlertShown) {
            Button(L10n.tr("OK"), role: .cancel) { }
        } message: {
            Text(L10n.tr("This pattern has already been saved as a finished work."))
        }
        .sheet(isPresented: $isShowingShareSheet, onDismiss: {
            libraryStore.selectedSegment = .finished
            selectedTab = .library
            dismiss()
        }) {
            if let pattern = finishedPattern {
                PublishShareSheet(
                    pattern: pattern,
                    displayName: sessionStore.currentUser.displayName,
                    avatarPattern: avatarPatternForShare()
                )
            }
        }
        .sheet(isPresented: $isShowingProInfo) {
            ProInfoView(sessionStore: sessionStore)
                .environmentObject(proStatusManager)
                .environmentObject(appleSignInManager)
        }
        .pbScreen()
    }

    private func avatarPatternForShare() -> Pattern? {
        let avatar = sessionStore.currentUser.avatar
        if let presetID = avatar.presetId,
           let preset = MockData.presetAvatars.first(where: { $0.id == presetID }) {
            return preset.pattern
        }
        if let patternID = avatar.patternId,
           let pattern = libraryStore.content.published.first(where: { $0.id == patternID }) {
            return pattern
        }
        return nil
    }
}

private struct AnimatedFinishedPreview: View {
    let pattern: Pattern
    let animationID: UUID

    @State private var startDate = Date()
    @State private var liftProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // Sticker lifts as one cohesive piece via SwiftUI spring animation.
            TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                GeometryReader { proxy in
                    let size = proxy.size
                    let layout = previewLayout(in: size)
                    let scene = sceneState(at: timeline.date)

                    Canvas { context, _ in
                        let elapsed = scene.elapsed
                        let (stickerPath, glowPath) = makeStickerPaths(layout: layout, elapsed: elapsed)

                        context.clip(to: stickerPath)

                        drawAmbientLight(in: &context, size: size, layout: layout, scene: scene)
                        drawStickerBorder(in: &context, layout: layout, lift: liftProgress,
                                         stickerPath: stickerPath, glowPath: glowPath)
                        drawFinishedPiece(in: &context, layout: layout, elapsed: elapsed)
                        drawHighlightSweep(in: &context, layout: layout, scene: scene, lift: liftProgress)
                    }
                }
            }
            .scaleEffect(1 + liftProgress * 0.10, anchor: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 364)
        .padding(12)
        .onAppear(perform: restart)
        .onChange(of: animationID) { _, _ in restart() }
    }

    private func restart() {
        startDate = Date()
        liftProgress = 0
        withAnimation(.spring(response: 0.46, dampingFraction: 0.68).delay(0.08)) {
            liftProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                liftProgress = 0
            }
        }
    }

    private func sceneState(at date: Date) -> FinishedSceneState {
        let elapsed = date.timeIntervalSince(startDate)
        return FinishedSceneState(
            elapsed: elapsed,
            glow: easedProgress(elapsed, start: 0.12, end: 1.92),
            sweepDown: easedProgress(elapsed, start: 0.36, end: 1.10),
            sweepUp: easedProgress(elapsed, start: 1.46, end: 2.14)
        )
    }

    private func previewLayout(in size: CGSize) -> PreviewLayout {
        let coloredPixels = pattern.pixels.filter { $0.colorHex != nil }
        let occupiedMinX = coloredPixels.map(\.x).min() ?? 0
        let occupiedMaxX = coloredPixels.map(\.x).max() ?? max(pattern.width - 1, 0)
        let occupiedMinY = coloredPixels.map(\.y).min() ?? 0
        let occupiedMaxY = coloredPixels.map(\.y).max() ?? max(pattern.height - 1, 0)

        let occupiedWidth = CGFloat(max(occupiedMaxX - occupiedMinX + 1, 1))
        let occupiedHeight = CGFloat(max(occupiedMaxY - occupiedMinY + 1, 1))
        let availableWidth = max(size.width - 84, 120)
        let availableHeight = max(size.height - 108, 120)
        let cellSize = min(availableWidth / occupiedWidth, availableHeight / occupiedHeight)

        let occupiedCenterX = CGFloat(occupiedMinX) + occupiedWidth / 2
        let occupiedCenterY = CGFloat(occupiedMinY) + occupiedHeight / 2
        let pieceOrigin = CGPoint(
            x: size.width / 2 - occupiedCenterX * cellSize,
            y: size.height / 2 - occupiedCenterY * cellSize + 10
        )

        return PreviewLayout(
            pieceOrigin: pieceOrigin,
            cellSize: cellSize,
            occupiedBounds: CGRect(
                x: CGFloat(occupiedMinX),
                y: CGFloat(occupiedMinY),
                width: occupiedWidth,
                height: occupiedHeight
            )
        )
    }

    private func drawAmbientLight(
        in context: inout GraphicsContext,
        size: CGSize,
        layout: PreviewLayout,
        scene: FinishedSceneState
    ) {
        let pieceRect = occupiedPieceRect(layout: layout)
        let glowRect = pieceRect.insetBy(dx: -pieceRect.width * 0.28, dy: -pieceRect.height * 0.32)
        context.fill(
            Path(ellipseIn: glowRect),
            with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(0.58 * scene.glow),
                    Color.white.opacity(0.18 * scene.glow),
                    Color.clear
                ]),
                center: CGPoint(x: glowRect.midX, y: glowRect.midY),
                startRadius: 6,
                endRadius: glowRect.width * 0.48
            )
        )

        let edgeFade = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context.fill(
            Path(edgeFade),
            with: .radialGradient(
                Gradient(colors: [
                    Color.clear,
                    Color.black.opacity(0.015 * scene.glow)
                ]),
                center: CGPoint(x: edgeFade.midX, y: edgeFade.midY),
                startRadius: min(size.width, size.height) * 0.28,
                endRadius: min(size.width, size.height) * 0.68
            )
        )
    }

    private func makeStickerPaths(layout: PreviewLayout, elapsed: Double) -> (sticker: Path, glow: Path) {
        let orderedPixels = orderedColoredPixels()
        guard !orderedPixels.isEmpty else { return (Path(), Path()) }

        let borderInset = layout.cellSize * -0.18
        let cornerRadius = layout.cellSize * 0.34

        var stickerPath = Path()
        var glowPath = Path()

        for pixel in orderedPixels {
            let rect = cellRect(for: pixel, layout: layout, elapsed: elapsed)
            let stickerRect = rect.insetBy(dx: borderInset, dy: borderInset)
            let glowRect = stickerRect.insetBy(dx: layout.cellSize * -0.05, dy: layout.cellSize * -0.05)
            stickerPath.addPath(Path(roundedRect: stickerRect, cornerRadius: cornerRadius))
            glowPath.addPath(Path(roundedRect: glowRect, cornerRadius: cornerRadius + layout.cellSize * 0.08))
        }

        return (stickerPath, glowPath)
    }

    private func drawStickerShadow(in context: inout GraphicsContext, layout: PreviewLayout, lift: CGFloat) {
        let pieceRect = occupiedPieceRect(layout: layout)
        let shadowSpread = 1 + lift * 0.22
        let stickerShadowOpacity = 0.06 + lift * 0.12
        // Shadow falls further down as sticker lifts higher
        let stickerShadowYOffset = layout.cellSize * (0.80 + lift * 0.40)

        let shadowRect = pieceRect
            .insetBy(dx: -layout.cellSize * 1.05 * shadowSpread, dy: -layout.cellSize * 0.55 * shadowSpread)
            .offsetBy(dx: 0, dy: stickerShadowYOffset)

        context.fill(
            Path(roundedRect: shadowRect, cornerRadius: max(layout.cellSize * 1.1, 18)),
            with: .radialGradient(
                Gradient(colors: [
                    Color.black.opacity(stickerShadowOpacity),
                    Color.black.opacity(stickerShadowOpacity * 0.35),
                    Color.clear
                ]),
                center: CGPoint(x: shadowRect.midX, y: shadowRect.midY),
                startRadius: 8,
                endRadius: max(shadowRect.width, shadowRect.height) * 0.62
            )
        )
    }

    private func drawStickerBorder(in context: inout GraphicsContext, layout: PreviewLayout, lift: CGFloat, stickerPath: Path, glowPath: Path) {
        let borderWidth = max(layout.cellSize * 0.10, 2.2)
        let borderOpacity = 0.986 + lift * 0.012
        let outerGlowOpacity = 0.11 + lift * 0.22

        context.fill(glowPath, with: .color(Color.white.opacity(outerGlowOpacity)))
        context.fill(stickerPath, with: .color(Color.white.opacity(borderOpacity)))
        context.stroke(stickerPath, with: .color(Color.black.opacity(0.025)), lineWidth: borderWidth)
    }

    private func drawFinishedPiece(in context: inout GraphicsContext, layout: PreviewLayout, elapsed: Double) {
        let orderedPixels = orderedColoredPixels()
        let cornerRadius = layout.cellSize * 0.14

        for pixel in orderedPixels {
            guard let hex = pixel.colorHex else { continue }

            let rect = cellRect(for: pixel, layout: layout, elapsed: elapsed)
            let beadColor = Color(hex: hex)

            context.fill(
                Path(roundedRect: rect, cornerRadius: cornerRadius),
                with: .linearGradient(
                    Gradient(colors: [beadColor.opacity(0.99), beadColor.opacity(0.85)]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            )
            context.stroke(
                Path(roundedRect: rect, cornerRadius: cornerRadius),
                with: .color(Color.black.opacity(0.07)),
                lineWidth: 0.55
            )
            context.fill(
                Path(ellipseIn: CGRect(
                    x: rect.minX + layout.cellSize * 0.08,
                    y: rect.minY + layout.cellSize * 0.07,
                    width: layout.cellSize * 0.30,
                    height: layout.cellSize * 0.14
                )),
                with: .color(Color.white.opacity(0.28))
            )
        }
    }

    private func cellRect(for pixel: PatternPixel, layout: PreviewLayout, elapsed: Double = 0) -> CGRect {
        let yOffset = cellYOffset(for: pixel, layout: layout, elapsed: elapsed)
        return CGRect(
            x: layout.pieceOrigin.x + CGFloat(pixel.x) * layout.cellSize,
            y: layout.pieceOrigin.y + CGFloat(pixel.y) * layout.cellSize - yOffset,
            width: layout.cellSize,
            height: layout.cellSize
        )
    }

    // Lift: top rows first (liftDelay=0 at top, 0.28s at bottom).
    // Drop: bottom rows first (dropDelay=0 at bottom, 0.28s at top).
    private func cellYOffset(for pixel: PatternPixel, layout: PreviewLayout, elapsed: Double) -> CGFloat {
        let occupiedMinY = Int(layout.occupiedBounds.minY.rounded())
        let rowIndex = max(pixel.y - occupiedMinY, 0)
        let rowCount = max(Int(layout.occupiedBounds.height.rounded()), 1)
        let t = rowCount > 1 ? Double(rowIndex) / Double(rowCount - 1) : 0

        let liftDelay = t * 0.28
        let dropDelay = (1 - t) * 0.28

        let lift = easedProgress(elapsed, start: 0.08 + liftDelay, end: 0.52 + liftDelay)
        let drop = easedProgress(elapsed, start: 1.50 + dropDelay, end: 1.94 + dropDelay)
        return max(0, lift - drop) * layout.cellSize * 0.46
    }

    private func drawHighlightSweep(in context: inout GraphicsContext, layout: PreviewLayout, scene: FinishedSceneState, lift: CGFloat) {
        if scene.sweepDown > 0.01 {
            drawSweepBand(in: &context, layout: layout, progress: scene.sweepDown, direction: 1, lift: lift)
        }
        if scene.sweepUp > 0.01 {
            drawSweepBand(in: &context, layout: layout, progress: scene.sweepUp, direction: -1, lift: lift)
        }
    }

    private func drawSweepBand(
        in context: inout GraphicsContext,
        layout: PreviewLayout,
        progress: CGFloat,
        direction: CGFloat,
        lift: CGFloat
    ) {
        let pieceRect = occupiedPieceRect(layout: layout)
        // Full-width band so the sweep is clearly visible across the whole sticker.
        let sweepWidth = pieceRect.width * 1.12
        let sweepHeight = max(pieceRect.height * 0.38, layout.cellSize * 4.2)
        let travel = pieceRect.height + sweepHeight * 1.6

        let sweepY: CGFloat
        if direction > 0 {
            sweepY = pieceRect.minY - sweepHeight * 0.9 + travel * progress
        } else {
            sweepY = pieceRect.maxY + sweepHeight * 0.9 - travel * progress
        }

        let sweepRect = CGRect(
            x: pieceRect.minX - pieceRect.width * 0.06,
            y: sweepY,
            width: sweepWidth,
            height: sweepHeight
        )
        context.fill(
            Path(roundedRect: sweepRect, cornerRadius: sweepHeight * 0.5),
            with: .linearGradient(
                Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.18 + lift * 0.14),
                    Color.white.opacity(0.32 + lift * 0.16),
                    Color.white.opacity(0.18 + lift * 0.14),
                    Color.clear
                ]),
                startPoint: CGPoint(x: sweepRect.midX, y: direction > 0 ? sweepRect.minY : sweepRect.maxY),
                endPoint: CGPoint(x: sweepRect.midX, y: direction > 0 ? sweepRect.maxY : sweepRect.minY)
            )
        )

        let trailingShadowRect = CGRect(
            x: pieceRect.minX - pieceRect.width * 0.04,
            y: direction > 0 ? sweepRect.midY - sweepHeight * 0.22 : sweepRect.midY - sweepHeight * 0.30,
            width: pieceRect.width * 1.08,
            height: sweepHeight * 0.52
        )
        context.fill(
            Path(roundedRect: trailingShadowRect, cornerRadius: trailingShadowRect.height * 0.5),
            with: .linearGradient(
                Gradient(colors: [Color.black.opacity(0.04 * lift), Color.clear]),
                startPoint: CGPoint(x: trailingShadowRect.midX,
                                    y: direction > 0 ? trailingShadowRect.minY : trailingShadowRect.maxY),
                endPoint: CGPoint(x: trailingShadowRect.midX,
                                  y: direction > 0 ? trailingShadowRect.maxY : trailingShadowRect.minY)
            )
        )
    }

    private func occupiedPieceRect(layout: PreviewLayout) -> CGRect {
        CGRect(
            x: layout.pieceOrigin.x + layout.occupiedBounds.minX * layout.cellSize,
            y: layout.pieceOrigin.y + layout.occupiedBounds.minY * layout.cellSize,
            width: layout.occupiedBounds.width * layout.cellSize,
            height: layout.occupiedBounds.height * layout.cellSize
        )
    }

    private func orderedColoredPixels() -> [PatternPixel] {
        pattern.pixels
            .filter { $0.colorHex != nil }
            .sorted {
                if $0.y == $1.y { return $0.x < $1.x }
                return $0.y < $1.y
            }
    }

    private func easedProgress(_ elapsed: Double, start: Double, end: Double) -> CGFloat {
        guard end > start else { return 1 }
        let raw = min(max((elapsed - start) / (end - start), 0), 1)
        let eased = raw * raw * (3 - 2 * raw)
        return CGFloat(eased)
    }
}

private struct FinishedSceneState {
    let elapsed: Double
    let glow: CGFloat
    let sweepDown: CGFloat
    let sweepUp: CGFloat
}

private struct PreviewLayout {
    let pieceOrigin: CGPoint
    let cellSize: CGFloat
    let occupiedBounds: CGRect
}
