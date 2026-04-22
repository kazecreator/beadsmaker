import SwiftUI
import PhotosUI
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectedPattern.modifiedAt, order: .reverse) private var collectedPatterns: [CollectedPattern]
    var onSavedToGallery: (() -> Void)?
    @State private var scannedPayload: (name: String, width: Int, height: Int, gridData: [Int])?
    @State private var showPreview = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var cameraPermissionDenied = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            if cameraPermissionDenied {
                ContentUnavailableView {
                    Label("需要相机权限", systemImage: "camera.fill")
                } description: {
                    Text("请在「设置」中允许拼豆图纸使用相机")
                } actions: {
                    Button("打开设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                QRScannerRepresentable(
                    onScan: handleScanResult,
                    onPermissionDenied: { cameraPermissionDenied = true }
                )
                .ignoresSafeArea()
            }

            VStack {
                Spacer()
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("从相册选取", systemImage: "photo.on.rectangle")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("扫码导入")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, item in
            Task { await loadPhoto(item) }
        }
        .sheet(isPresented: $showPreview) {
            if let payload = scannedPayload {
                ScannedPatternPreview(payload: payload) { save in
                    if save {
                        saveCollectedPattern(payload)
                        onSavedToGallery?()
                    }
                    scannedPayload = nil
                    showPreview = false
                }
            }
        }
        .alert("扫码失败", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "无法识别该二维码")
        }
    }

    private func handleScanResult(_ string: String) {
        do {
            let result = try PatternCodec.decodeQRCodeString(string)
            scannedPayload = result
            showPreview = true
        } catch {
            showScanError(error.localizedDescription)
        }
    }

    private func showScanError(_ msg: String) {
        errorMessage = msg
        showError = true
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let ciImage = CIImage(image: uiImage) else { return }

        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]

        if let message = features?.first?.messageString {
            await MainActor.run { handleScanResult(message) }
        } else {
            await MainActor.run { showScanError("图片中未找到有效的二维码") }
        }
    }

    private func saveCollectedPattern(_ payload: (name: String, width: Int, height: Int, gridData: [Int])) {
        guard let signature = try? PatternCodec.collectionSignature(
            width: payload.width,
            height: payload.height,
            gridData: payload.gridData
        ) else { return }

        if collectedPatterns.contains(where: { $0.signature == signature }) {
            return
        }

        let draft = Pattern(name: payload.name, width: payload.width, height: payload.height)
        draft.gridData = payload.gridData
        let collected = CollectedPattern(
            name: payload.name,
            width: payload.width,
            height: payload.height,
            gridData: payload.gridData,
            thumbnailData: PatternRenderer.thumbnail(pattern: draft).pngData(),
            signature: signature
        )
        modelContext.insert(collected)
        try? modelContext.save()
    }
}

// MARK: - Scanner Representable

private struct QRScannerRepresentable: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    var onPermissionDenied: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> QRScannerController {
        let vc = QRScannerController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {}

    final class Coordinator: NSObject, QRScannerDelegate {
        let parent: QRScannerRepresentable
        init(_ parent: QRScannerRepresentable) { self.parent = parent }

        func scanner(_ scanner: QRScannerController, didFind string: String) {
            parent.onScan(string)
        }
        func scannerDidFailPermission(_ scanner: QRScannerController) {
            parent.onPermissionDenied()
        }
    }
}

// MARK: - Preview Sheet

private struct ScannedPatternPreview: View {
    let payload: (name: String, width: Int, height: Int, gridData: [Int])
    let onAction: (Bool) -> Void

    private var previewImage: UIImage {
        let p = Pattern(name: payload.name, width: payload.width, height: payload.height)
        p.gridData = payload.gridData
        return PatternRenderer.render(pattern: p, cellSize: 6)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 6)
                    .padding()

                VStack(spacing: 6) {
                    Text(payload.name).font(.title2.bold())
                    Text("\(payload.width) × \(payload.height)").foregroundStyle(.secondary)
                }

                Spacer()
            }
            .navigationTitle("预览图纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { onAction(false) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("导入图纸") { onAction(true) }
                        .bold()
                }
            }
        }
    }
}
