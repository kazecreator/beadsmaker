import Foundation
import Compression

// MARK: - Payloads

struct PatternQRPayloadV1: Codable {
    let v: Int
    let w: Int
    let h: Int
    let t: String
    let p: [PixelEntry]
}

struct PatternQRPayloadV2: Codable {
    let v: Int
    let w: Int
    let h: Int
    let t: String
    /// Unique color hex strings (no # prefix)
    let pal: [String]
    /// URL-safe base64 of zlib-compressed grid bytes.
    /// Each byte is a palette index (0-based), or 254 for empty.
    let g: String
}

struct PixelEntry: Codable {
    let x: Int
    let y: Int
    let c: String
}

/// Union type for decoded payloads — callers should inspect `version` to decide how to handle.
struct DecodedQRPayload {
    let version: Int
    let width: Int
    let height: Int
    let title: String
    /// Non-empty for v1 payloads.
    let pixelEntries: [PixelEntry]
    /// Non-empty for v2 payloads.
    let palette: [String]
    /// Non-empty for v2 payloads. Row-major grid, each byte = palette index or 254 (empty).
    let gridBytes: Data

    var beadCount: Int {
        if version == 2 {
            return gridBytes.filter { $0 != 254 }.count
        }
        return pixelEntries.count
    }
}

// MARK: - PatternQRCode

enum PatternQRCode {
    static let prefix = "pb:"

    /// Checks whether a scanned string looks like a valid pattern QR payload.
    static func canImport(_ string: String) -> Bool {
        string.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix)
    }

    // MARK: - Encode

    /// Encodes a Pattern into a compact QR-code-friendly string using the v2 palette+grid format.
    static func encode(_ pattern: Pattern) -> String? {
        // Build palette from unique colors (stable order by first occurrence).
        var palette: [String] = []
        var colorIndex: [String: Int] = [:]
        for pixel in pattern.pixels {
            guard let hex = pixel.colorHex, colorIndex[hex] == nil else { continue }
            colorIndex[hex] = palette.count
            palette.append(hex)
        }

        // Build grid bytes in row-major order.
        var grid = Data(capacity: pattern.width * pattern.height)
        let pixelColor = Dictionary(
            uniqueKeysWithValues: pattern.pixels
                .filter { $0.colorHex != nil }
                .map { ("\($0.x),\($0.y)", $0.colorHex!) }
        )
        for y in 0..<pattern.height {
            for x in 0..<pattern.width {
                if let hex = pixelColor["\(x),\(y)"], let idx = colorIndex[hex] {
                    grid.append(UInt8(idx))
                } else {
                    grid.append(254) // empty sentinel
                }
            }
        }

        // Compress grid bytes, then base64-url encode.
        guard let compressedGrid = compress(grid) else { return nil }
        let gridB64 = base64URLEncode(compressedGrid)

        let payload = PatternQRPayloadV2(
            v: 2,
            w: pattern.width,
            h: pattern.height,
            t: pattern.title,
            pal: palette,
            g: gridB64
        )

        guard let jsonData = try? JSONEncoder().encode(payload),
              let compressed = compress(jsonData)
        else { return nil }

        return prefix + base64URLEncode(compressed)
    }

    // MARK: - Decode

    /// Decodes a QR code string into a payload union that supports both v1 and v2 formats.
    static func decode(_ string: String) -> DecodedQRPayload? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { return nil }
        let b64 = String(trimmed.dropFirst(prefix.count))

        guard let compressed = base64URLDecode(b64),
              let jsonData = decompress(compressed)
        else { return nil }

        // Try v2 first (palette+grid), fall back to v1 (per-pixel entries).
        if let p = try? JSONDecoder().decode(PatternQRPayloadV2.self, from: jsonData), p.v == 2 {
            guard let grid = base64URLDecode(p.g),
                  let decompressedGrid = decompress(grid)
            else { return nil }
            return DecodedQRPayload(
                version: 2,
                width: p.w,
                height: p.h,
                title: p.t,
                pixelEntries: [],
                palette: p.pal,
                gridBytes: decompressedGrid
            )
        }

        if let p = try? JSONDecoder().decode(PatternQRPayloadV1.self, from: jsonData), p.v == 1 {
            return DecodedQRPayload(
                version: 1,
                width: p.w,
                height: p.h,
                title: p.t,
                pixelEntries: p.p,
                palette: [],
                gridBytes: Data()
            )
        }

        return nil
    }

    // MARK: - To Pattern

    static func toPattern(_ payload: DecodedQRPayload, authorName: String) -> Pattern {
        let pixels: [PatternPixel]
        var usedColors: [String] = []

        if payload.version == 2 {
            pixels = (0..<payload.height).flatMap { y in
                (0..<payload.width).map { x in
                    let idx = payload.gridBytes.count > y * payload.width + x
                        ? Int(payload.gridBytes[y * payload.width + x]) : 254
                    let hex = (idx < payload.palette.count) ? payload.palette[idx] : nil
                    return PatternPixel(x: x, y: y, colorHex: hex)
                }
            }
            usedColors = payload.palette
        } else {
            let pixelMap = Dictionary(
                uniqueKeysWithValues: payload.pixelEntries.map { ("\($0.x),\($0.y)", $0.c) }
            )
            pixels = (0..<payload.height).flatMap { y in
                (0..<payload.width).map { x in
                    PatternPixel(x: x, y: y, colorHex: pixelMap["\(x),\(y)"])
                }
            }
            usedColors = payload.pixelEntries.map(\.c)
        }

        return Pattern(
            id: UUID(),
            title: payload.title,
            authorName: authorName,
            width: payload.width,
            height: payload.height,
            pixels: pixels,
            palette: usedColors,
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
        let dstSize = max(data.count + 64, data.count * 2)
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

    // MARK: - Base64URL helpers

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        let s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = s.count % 4
        let padded = pad == 0 ? s : s + String(repeating: "=", count: 4 - pad)
        return Data(base64Encoded: padded)
    }
}
