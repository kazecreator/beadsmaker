import SwiftUI
import AVFoundation
import PhotosUI

struct ImportPatternView: View {
    let hasExistingDrafts: Bool
    let onImport: (Pattern) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var detectedPayload: PatternQRPayload?
    @State private var parseError: String?
    @State private var cameraPermission: CameraPermission = .notDetermined
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingImportConfirmation = false

    enum CameraPermission {
        case notDetermined
        case authorized
        case denied
    }

    var body: some View {
        NavigationStack {
            Group {
                if let payload = detectedPayload {
                    previewView(payload)
                } else if cameraPermission == .authorized || cameraPermission == .notDetermined {
                    scannerView
                } else {
                    permissionDeniedView
                }
            }
            .navigationTitle(L10n.tr("Import Pattern"))
            .navigationBarTitleDisplayMode(.inline)
            .background(PixelBeadsTheme.surface)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("Cancel")) { dismiss() }
                }
            }
        }
        .onAppear { checkCameraPermission() }
    }

    // MARK: - Scanner

    private var scannerView: some View {
        VStack(spacing: 0) {
            ZStack {
                QRScannerView(
                    onDetect: handleDetection,
                    onSetupError: { cameraPermission = .denied }
                )
                .ignoresSafeArea(edges: .top)

                scannerOverlay
            }
            .aspectRatio(1, contentMode: .fit)

            VStack(spacing: 10) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(PixelBeadsTheme.ink.opacity(0.25))

                Text(L10n.tr("Scan a PixelBeads QR code"))
                    .font(.headline)
                Text(L10n.tr("Point your camera at a QR code shared from another PixelBeads user."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .frame(maxWidth: .infinity)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(L10n.tr("Pick from Photos"), systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            if let error = parseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task { await detectQRInPhoto(item) }
        }
    }

    private var scannerOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: 230, height: 230)
                .blendMode(.destinationOut)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 2)
                .frame(width: 230, height: 230)
        }
        .compositingGroup()
    }

    // MARK: - Permission denied

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(PixelBeadsTheme.ink.opacity(0.2))

            VStack(spacing: 8) {
                Text(L10n.tr("Camera Access Needed"))
                    .font(.headline)
                Text(L10n.tr("Open Settings to grant camera access for scanning QR codes."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text(L10n.tr("Open Settings"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(L10n.tr("Pick from Photos"), systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task { await detectQRInPhoto(item) }
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Preview

    private func previewView(_ payload: PatternQRPayload) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Image(uiImage: PatternImageRenderer.finishedImage(
                    for: PatternQRCode.toPattern(payload, authorName: ""),
                    cellSize: 22, scale: 3
                ))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 16, y: 8)

                VStack(spacing: 4) {
                    Text(payload.t.isEmpty ? L10n.tr("Untitled") : payload.t)
                        .font(.title3.bold())
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 4) {
                        Text("\(payload.w) × \(payload.h)")
                        Text("·")
                        Text("\(payload.p.count) \(L10n.tr("beads"))")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    if hasExistingDrafts {
                        isShowingImportConfirmation = true
                    } else {
                        importPattern(payload)
                    }
                } label: {
                    Label(L10n.tr("Import as Draft"), systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .confirmationDialog(
                    L10n.tr("Importing will replace your current draft."),
                    isPresented: $isShowingImportConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(L10n.tr("Import Anyway"), role: .destructive) {
                        importPattern(payload)
                    }
                    Button(L10n.tr("Cancel"), role: .cancel) {}
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        detectedPayload = nil
                        parseError = nil
                        selectedPhotoItem = nil
                        checkCameraPermission()
                    }
                } label: {
                    Label(L10n.tr("Scan Again"), systemImage: "qrcode.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(24)
        }
        .background(PixelBeadsTheme.surface)
    }

    private func importPattern(_ payload: PatternQRPayload) {
        let pattern = PatternQRCode.toPattern(payload, authorName: L10n.tr("Imported"))
        onImport(pattern)
        dismiss()
    }

    // MARK: - Detection

    private func handleDetection(_ code: String) {
        guard let payload = PatternQRCode.decode(code) else {
            withAnimation { parseError = L10n.tr("Could not parse this QR code. Make sure it is a valid PixelBeads pattern.") }
            return
        }
        parseError = nil
        withAnimation(.easeInOut(duration: 0.25)) { detectedPayload = payload }
    }

    private func detectQRInPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let ciImage = CIImage(image: image)
        else {
            await MainActor.run {
                withAnimation { parseError = L10n.tr("Could not read image.") }
            }
            return
        }

        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil)
        let features = detector?.features(in: ciImage) as? [CIQRCodeFeature]

        guard let code = features?.first?.messageString else {
            await MainActor.run {
                withAnimation { parseError = L10n.tr("No QR code found in image.") }
            }
            return
        }

        await MainActor.run { handleDetection(code) }
    }

    // MARK: - Permissions

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraPermission = .authorized
        case .denied, .restricted:
            cameraPermission = .denied
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        @unknown default:
            cameraPermission = .denied
        }
    }
}
