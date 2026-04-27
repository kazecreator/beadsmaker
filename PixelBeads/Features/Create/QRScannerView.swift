import SwiftUI
import AVFoundation

// MARK: - Scanner UIViewController

final class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onDetect: ((String) -> Void)?
    var onSetupError: (() -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isRunning = false
    private var isSessionConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCaptureSessionIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }

    // MARK: - Setup

    private func setupCaptureSessionIfNeeded() {
        guard !isSessionConfigured else {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.startIfReady()
            }
            return
        }
        isSessionConfigured = true

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            onSetupError?()
            return
        }

        session.beginConfiguration()
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.startIfReady()
        }
    }

    func startIfReady() {
        guard !isRunning else { return }
        isRunning = true
        session.startRunning()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        session.stopRunning()
    }

    // MARK: - Detection

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue,
              code.hasPrefix(PatternQRCode.prefix)
        else { return }
        stop()
        onDetect?(code)
    }
}

// MARK: - SwiftUI wrapper

struct QRScannerView: UIViewControllerRepresentable {
    let onDetect: (String) -> Void
    let onSetupError: (() -> Void)?

    init(onDetect: @escaping (String) -> Void, onSetupError: (() -> Void)? = nil) {
        self.onDetect = onDetect
        self.onSetupError = onSetupError
    }

    func makeUIViewController(context: Context) -> QRScannerController {
        let vc = QRScannerController()
        vc.onDetect = onDetect
        vc.onSetupError = onSetupError
        return vc
    }

    func updateUIViewController(_ vc: QRScannerController, context: Context) {}
}
