import SwiftUI
import SwiftData

struct ShareView: View {
    let pattern: Pattern
    @Query private var profiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss
    @State private var patternImage: UIImage?
    @State private var showSavedAlert = false
    @State private var savedMessage = ""
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // QR Code Section
                    VStack(spacing: 12) {
                        Text("分享二维码").font(.headline)
                        QRGeneratorView(pattern: pattern)
                        HStack(spacing: 12) {
                            shareButton(icon: "square.and.arrow.down", label: "保存到相册") {
                                saveQRToAlbum()
                            }
                            shareButton(icon: "square.and.arrow.up", label: "分享") {
                                shareQR()
                            }
                        }
                        Text("分享的图片包含署名").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Pattern Image Section
                    VStack(spacing: 12) {
                        Text("导出图片").font(.headline)
                        if let img = patternImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 4)
                        } else {
                            ProgressView().frame(height: 200)
                        }
                        HStack(spacing: 12) {
                            shareButton(icon: "square.and.arrow.down", label: "保存图片") {
                                savePatternToAlbum()
                            }
                            shareButton(icon: "square.and.arrow.up", label: "分享图片") {
                                sharePattern()
                            }
                        }
                        Text("导出带网格线和署名的图纸图片")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("分享图纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .task {
                let base = PatternRenderer.render(pattern: pattern, cellSize: 12, showGrid: true)
                patternImage = PatternRenderer.attachSignature(to: base, profile: profile)
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(items: shareItems)
            }
            .alert(savedMessage, isPresented: $showSavedAlert) {
                Button("好的", role: .cancel) {}
            }
        }
    }

    // MARK: - Buttons

    @ViewBuilder
    private func shareButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .foregroundStyle(.primary)
    }

    // MARK: - QR

    private func signedQR() -> UIImage? {
        guard let string = try? PatternCodec.encodeQRCodeString(pattern: pattern) else { return nil }
        let data = Data(string.utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        guard let output = filter?.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        let raw = UIImage(cgImage: cgImage)
        return PatternRenderer.attachSignature(to: raw, profile: profile)
    }

    private func saveQRToAlbum() {
        guard let img = signedQR() else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        savedMessage = "二维码已保存到相册"
        showSavedAlert = true
    }

    private func shareQR() {
        guard let img = signedQR() else { return }
        shareItems = [img]
        showShareSheet = true
    }

    private func savePatternToAlbum() {
        guard let img = patternImage else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        savedMessage = "图纸图片已保存到相册"
        showSavedAlert = true
    }

    private func sharePattern() {
        guard let img = patternImage else { return }
        shareItems = [img]
        showShareSheet = true
    }
}

// MARK: - Activity Sheet

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
