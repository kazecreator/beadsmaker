import UIKit
import AVFoundation

protocol QRScannerDelegate: AnyObject {
    func scanner(_ scanner: QRScannerController, didFind string: String)
    func scannerDidFailPermission(_ scanner: QRScannerController)
}

final class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionAndSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted { self?.setupSession() }
                    else { self?.delegate?.scannerDidFailPermission(self!) }
                }
            }
        default:
            delegate?.scannerDidFailPermission(self)
        }
    }

    private func setupSession() {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview

        addOverlay()

        self.captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func addOverlay() {
        let overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.backgroundColor = .clear

        let size: CGFloat = 220
        let cx = view.bounds.midX
        let cy = view.bounds.midY
        let scanRect = CGRect(x: cx - size / 2, y: cy - size / 2, width: size, height: size)

        let path = UIBezierPath(rect: view.bounds)
        path.append(UIBezierPath(roundedRect: scanRect, cornerRadius: 12))
        path.usesEvenOddFillRule = true

        let mask = CAShapeLayer()
        mask.path = path.cgPath
        mask.fillRule = .evenOdd
        mask.fillColor = UIColor.black.withAlphaComponent(0.55).cgColor
        overlay.layer.addSublayer(mask)

        let border = CAShapeLayer()
        border.path = UIBezierPath(roundedRect: scanRect, cornerRadius: 12).cgPath
        border.strokeColor = UIColor.white.cgColor
        border.fillColor = UIColor.clear.cgColor
        border.lineWidth = 2
        overlay.layer.addSublayer(border)

        let tip = UILabel()
        tip.text = "将二维码置于框内"
        tip.textColor = .white
        tip.font = .systemFont(ofSize: 14)
        tip.sizeToFit()
        tip.center = CGPoint(x: cx, y: scanRect.maxY + 24)
        overlay.addSubview(tip)

        view.addSubview(overlay)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              let string = obj.stringValue else { return }
        captureSession?.stopRunning()
        delegate?.scanner(self, didFind: string)
    }
}
