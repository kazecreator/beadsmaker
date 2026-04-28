import Foundation
import Compression

// MARK: - Payload

struct PatternQRPayload: Codable {
    /// Format version
    let v: Int
    /// Grid width
    let w: Int
    /// Grid height
    let h: Int
    /// Title
    let t: String
    /// Non-empty pixels with color hex values
    let p: [PixelEntry]
}

struct PixelEntry: Codable {
    let x: Int
    let y: Int
    let c: String
}

// MARK: - PatternQRCode

enum PatternQRCode {
    static let prefix = "pb:"
    private static let currentVersion = 1

    /// Checks whether a scanned string looks like a valid pattern QR payload.
    static func canImport(_ string: String) -> Bool {
        string.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix)
    }

    // MARK: - Encode

    /// Encodes a Pattern into a compact QR-code-friendly string.
    static func encode(_ pattern: Pattern) -> String? {
        let payload = PatternQRPayload(
            v: currentVersion,
            w: pattern.width,
            h: pattern.height,
            t: pattern.title,
            p: pattern.pixels
                .filter { $0.colorHex != nil }
                .map { PixelEntry(x: $0.x, y: $0.y, c: $0.colorHex!) }
        )

        guard let jsonData = try? JSONEncoder().encode(payload),
              let compressed = compress(jsonData)
        else { return nil }

        let b64 = compressed.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return prefix + b64
    }

    // MARK: - Decode

    /// Decodes a QR code string back into pattern metadata.
    static func decode(_ string: String) -> PatternQRPayload? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { return nil }
        let b64 = String(trimmed.dropFirst(prefix.count))
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Restore padding
        let pad = b64.count % 4
        let padded = pad == 0 ? b64 : b64 + String(repeating: "=", count: 4 - pad)

        guard let compressed = Data(base64Encoded: padded),
              let jsonData = decompress(compressed),
              let payload = try? JSONDecoder().decode(PatternQRPayload.self, from: jsonData)
        else { return nil }
        return payload
    }

    // MARK: - To Pattern

    static func toPattern(_ payload: PatternQRPayload, authorName: String) -> Pattern {
        let pixelMap = Dictionary(
            uniqueKeysWithValues: payload.p.map { ("\($0.x),\($0.y)", $0.c) }
        )
        let pixels = (0..<payload.h).flatMap { y in
            (0..<payload.w).map { x in
                PatternPixel(x: x, y: y, colorHex: pixelMap["\(x),\(y)"])
            }
        }
        return Pattern(
            id: UUID(),
            title: payload.t,
            authorName: authorName,
            width: payload.w,
            height: payload.h,
            pixels: pixels,
            palette: payload.p.map(\.c),
            status: .draft,
            visibility: .private,
            difficulty: .easy,
            tags: [],
            likeCount: 0,
            saveCount: 0,
            isRemixable: true,
            createdAt: .now
        )
    }

    // MARK: - Compression

    private static func compress(_ data: Data) -> Data? {
        let dstSize = data.count + 64
        var result = Data(count: dstSize)
        let written = result.withUnsafeMutableBytes { dst in
            data.withUnsafeBytes { src in
                compression_encode_buffer(
                    dst.baseAddress!, dst.count,
                    src.baseAddress!, src.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard written > 0 else { return nil }
        return result.prefix(written)
    }

    private static func decompress(_ data: Data) -> Data? {
        var result = Data(count: data.count * 8)
        let written = result.withUnsafeMutableBytes { dst in
            data.withUnsafeBytes { src in
                compression_decode_buffer(
                    dst.baseAddress!, dst.count,
                    src.baseAddress!, src.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard written > 0 else { return nil }
        return result.prefix(written)
    }
}
