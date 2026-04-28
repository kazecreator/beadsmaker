import SwiftUI
import Photos
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - PublishShareSheet

struct PublishShareSheet: View {
    let pattern: Pattern
    let displayName: String
    let avatarImage: UIImage?
    var onDone: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var saveStatus: PhotoSaveStatus?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    ShareCardView(
                        pattern: pattern,
                        displayName: displayName,
                        avatarImage: avatarImage
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.14), radius: 24, y: 10)
                    .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        Button {
                            let img = renderCard()
                            PhotoLibrarySaver.saveImage(img) { status in
                                saveStatus = status
                            }
                        } label: {
                            Label(L10n.tr("Save Image"), systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle(L10n.tr("Share Your Creation"))
            .navigationBarTitleDisplayMode(.inline)
            .background(BeadsMakerTheme.surface)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("Done")) {
                        onDone?()
                        dismiss()
                    }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .alert(saveStatus?.title ?? "", isPresented: Binding(
            get: { saveStatus != nil },
            set: { if !$0 { saveStatus = nil } }
        )) {
            Button(L10n.tr("OK"), role: .cancel) { saveStatus = nil }
        } message: {
            Text(saveStatus?.message ?? "")
        }
    }

    private var cardWidth: CGFloat { 320 }
    private var cardHeight: CGFloat { 440 }

    @MainActor
    private func renderCard() -> UIImage {
        let renderer = ImageRenderer(
            content: ShareCardView(
                pattern: pattern,
                displayName: displayName,
                avatarImage: avatarImage
            )
            .frame(width: cardWidth, height: cardHeight)
        )
        renderer.scale = 3
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: - Share Card

private struct ShareCardView: View {
    let pattern: Pattern
    let displayName: String
    let avatarImage: UIImage?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#FFF8F2")

            VStack(spacing: 0) {
                Image(uiImage: PatternImageRenderer.finishedImage(for: pattern, cellSize: 22, scale: 2))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 10) {
                        avatarView
                            .frame(width: 40, height: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayName)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(BeadsMakerTheme.ink)
                                .lineLimit(1)
                            Text("BeadsMaker")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(BeadsMakerTheme.ink.opacity(0.35))
                        }
                    }

                    Spacer()

                    QROverlayView(dataString: PatternQRCode.encode(pattern) ?? "")
                        .frame(width: 58, height: 58)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color.white)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let img = avatarImage {
            Image(uiImage: img)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "#F0EDE8"))
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundStyle(Color(hex: "#C0BBB4"))
                )
        }
    }
}

// MARK: - QR Overlay

private struct QROverlayView: View {
    let dataString: String

    private var qrImage: UIImage? { Self.makeQRCode(from: dataString) }
    private var appIcon: UIImage? {
        if let img = UIImage(named: "AppIcon") { return img }
        guard
            let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let name = files.last
        else { return nil }
        return UIImage(named: name)
    }

    var body: some View {
        ZStack {
            if let qr = qrImage {
                Image(uiImage: qr)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            }
            if let icon = appIcon {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                            .fill(Color.white)
                    )
            }
        }
    }

    private static func makeQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "H"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
