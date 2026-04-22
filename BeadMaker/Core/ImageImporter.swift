import AVFoundation
import CoreGraphics
import UIKit

enum ImageImporterError: LocalizedError {
    case invalidImage
    case unsupportedTargetSize

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取所选图片"
        case .unsupportedTargetSize:
            return "当前图纸尺寸无效，无法导入图片"
        }
    }
}

enum ImageImporter {
    static func makePattern(from image: UIImage, targetWidth: Int, targetHeight: Int) throws -> [Int] {
        guard targetWidth > 0, targetHeight > 0 else {
            throw ImageImporterError.unsupportedTargetSize
        }

        guard let scaledImage = scaledPixelData(from: image, width: targetWidth, height: targetHeight) else {
            throw ImageImporterError.invalidImage
        }

        var gridData: [Int] = []
        gridData.reserveCapacity(targetWidth * targetHeight)

        for pixel in scaledImage {
            if pixel.alpha < 12 {
                gridData.append(0)
                continue
            }

            let colorId = BeadColorLibrary.nearestColorId(
                red: pixel.red,
                green: pixel.green,
                blue: pixel.blue
            )
            gridData.append(colorId)
        }

        return gridData
    }

    private static func scaledPixelData(from image: UIImage, width: Int, height: Int) -> [RGBA8]? {
        guard let cgImage = image.cgImage else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        var rawData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let fittedRect = AVMakeRect(aspectRatio: CGSize(width: cgImage.width, height: cgImage.height),
                                    insideRect: CGRect(x: 0, y: 0, width: width, height: height))
        context.draw(cgImage, in: fittedRect)

        return stride(from: 0, to: rawData.count, by: bytesPerPixel).map { offset in
            RGBA8(
                red: rawData[offset],
                green: rawData[offset + 1],
                blue: rawData[offset + 2],
                alpha: rawData[offset + 3]
            )
        }
    }
}

private struct RGBA8 {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}
