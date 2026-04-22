import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRGeneratorView: View {
    let pattern: Pattern
    @State private var qrImage: UIImage?
    @State private var encodedData: Data?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            if let img = qrImage {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.12), radius: 8)
            } else if let err = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text(err).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .frame(width: 220, height: 220)
            } else {
                ProgressView("生成中…")
                    .frame(width: 220, height: 220)
            }
        }
        .task { await generate() }
    }

    @MainActor
    private func generate() async {
        do {
            let string = try PatternCodec.encodeQRCodeString(pattern: pattern)
            encodedData = Data(string.utf8)

            let context = CIContext()
            let filter = CIFilter.qrCodeGenerator()
            filter.message = Data(string.utf8)
            filter.correctionLevel = "Q"

            guard let output = filter.outputImage else { return }
            let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
            guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return }
            qrImage = UIImage(cgImage: cgImage)
        } catch {
            errorMessage = "编码失败：\(error.localizedDescription)"
        }
    }

    func generatedImage() -> UIImage? { qrImage }
    func generatedData() -> Data? { encodedData }
}
