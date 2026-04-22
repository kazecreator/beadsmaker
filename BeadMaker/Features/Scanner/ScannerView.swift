import SwiftUI
import PhotosUI
import SwiftData

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectedPattern.modifiedAt, order: .reverse) private var collectedPatterns: [CollectedPattern]
    var onSavedToGallery: (() -> Void)?
    var onFavoriteSaved: ((String) -> Void)?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var cameraPermissionDenied = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isImporting = false

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
        .alert("扫码失败", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "无法识别该二维码")
        }
        .overlay {
            if isImporting {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()

                    ProgressView("正在加入收藏…")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func handleScanResult(_ string: String) {
        guard !isImporting else { return }

        Task {
            await importFavorite(from: string)
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
            await importFavorite(from: message)
        } else {
            await MainActor.run { showScanError("图片中未找到有效的二维码") }
        }
    }

    @MainActor
    private func importFavorite(from string: String) async {
        guard !isImporting else { return }
        isImporting = true
        defer { isImporting = false }

        do {
            let payload = try await FavoriteImportService.importFromQRCode(string)
            try FavoriteImportService.saveFavorite(payload, in: modelContext, existingFavorites: collectedPatterns)
            onSavedToGallery?()
            onFavoriteSaved?("已加入收藏")
        } catch {
            showScanError(error.localizedDescription)
        }
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
