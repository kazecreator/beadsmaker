import CryptoKit
import Foundation

private struct PatternPayloadV1: Codable {
    let v: Int
    let w: Int
    let h: Int
    let n: String
    let p: [Int]
    let d: String
}

private struct PatternPayloadV2: Codable {
    let v: Int
    let w: Int
    let h: Int
    let n: String
    let p: [String]
    let d: String
}

enum PatternCodecError: Error, LocalizedError {
    case unsupportedVersion
    case invalidData

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: return "不支持的版本格式"
        case .invalidData: return "二维码数据损坏"
        }
    }
}

enum PatternCodec {
    private static let qrPrefix = "BM1:"

    static func encode(pattern: Pattern) throws -> Data {
        let payload = try payloadV2(name: pattern.name, width: pattern.width, height: pattern.height, gridData: pattern.gridData)
        return try JSONEncoder().encode(payload)
    }

    static func encodeQRCodeString(pattern: Pattern) throws -> String {
        let data = try encode(pattern: pattern)
        let compressed = try compress(data)
        return qrPrefix + base64URLEncodedString(for: compressed)
    }

    static func decode(data: Data) throws -> (name: String, width: Int, height: Int, gridData: [Int]) {
        if let payload = try? JSONDecoder().decode(PatternPayloadV2.self, from: data) {
            return try decodeV2(payload)
        }
        if let payload = try? JSONDecoder().decode(PatternPayloadV1.self, from: data) {
            return try decodeV1(payload)
        }
        throw PatternCodecError.invalidData
    }

    private static func decodeV1(_ payload: PatternPayloadV1) throws -> (name: String, width: Int, height: Int, gridData: [Int]) {
        guard payload.v == 1 else { throw PatternCodecError.unsupportedVersion }

        var gridData: [Int] = []
        for chunk in payload.d.split(separator: ",") {
            let parts = chunk.split(separator: ":")
            guard parts.count == 2,
                  let count = Int(parts[0]),
                  let paletteIndex = Int(parts[1]),
                  paletteIndex < payload.p.count else {
                throw PatternCodecError.invalidData
            }
            let colorId = payload.p[paletteIndex]
            gridData.append(contentsOf: Array(repeating: colorId, count: count))
        }

        guard gridData.count == payload.w * payload.h else {
            throw PatternCodecError.invalidData
        }

        return (payload.n, payload.w, payload.h, gridData)
    }

    private static func decodeV2(_ payload: PatternPayloadV2) throws -> (name: String, width: Int, height: Int, gridData: [Int]) {
        guard payload.v == 2 else { throw PatternCodecError.unsupportedVersion }

        var gridData: [Int] = []
        for chunk in payload.d.split(separator: ",") {
            let parts = chunk.split(separator: ":")
            guard parts.count == 2,
                  let count = Int(parts[0]),
                  let paletteIndex = Int(parts[1]),
                  paletteIndex < payload.p.count else {
                throw PatternCodecError.invalidData
            }

            let token = payload.p[paletteIndex]
            let colorId: Int
            if token.isEmpty {
                colorId = 0
            } else if let bead = BeadColorLibrary.color(standardCode: token) {
                colorId = bead.id
            } else {
                throw PatternCodecError.invalidData
            }

            gridData.append(contentsOf: Array(repeating: colorId, count: count))
        }

        guard gridData.count == payload.w * payload.h else {
            throw PatternCodecError.invalidData
        }

        return (payload.n, payload.w, payload.h, gridData)
    }

    static func decodeQRCodeString(_ string: String) throws -> (name: String, width: Int, height: Int, gridData: [Int]) {
        if string.hasPrefix(qrPrefix) {
            let encoded = String(string.dropFirst(qrPrefix.count))
            guard let compressed = dataFromBase64URLString(encoded) else {
                throw PatternCodecError.invalidData
            }
            let data = try decompress(compressed)
            return try decode(data: data)
        }

        guard let data = string.data(using: .utf8) else {
            throw PatternCodecError.invalidData
        }
        return try decode(data: data)
    }

    static func collectionSignature(width: Int, height: Int, gridData: [Int]) throws -> String {
        let payload = try payloadV2(name: "", width: width, height: height, gridData: gridData)
        let data = try JSONEncoder().encode(payload)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func compress(_ data: Data) throws -> Data {
        try (data as NSData).compressed(using: .zlib) as Data
    }

    private static func decompress(_ data: Data) throws -> Data {
        try (data as NSData).decompressed(using: .zlib) as Data
    }

    private static func base64URLEncodedString(for data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func dataFromBase64URLString(_ string: String) -> Data? {
        let padding = (4 - string.count % 4) % 4
        let padded = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/") + String(repeating: "=", count: padding)
        return Data(base64Encoded: padded)
    }

    private static func paletteToken(for colorId: Int) -> String? {
        guard let bead = BeadColorLibrary.color(id: colorId) else { return nil }
        return bead.standardCode ?? bead.colorCode
    }

    private static func payloadV2(name: String, width: Int, height: Int, gridData: [Int]) throws -> PatternPayloadV2 {
        var tokens = Set<String>()
        for id in gridData where id != 0 {
            guard let token = paletteToken(for: id) else {
                throw PatternCodecError.invalidData
            }
            tokens.insert(token)
        }
        let palette = [""] + tokens.sorted(by: paletteTokenSort)
        let indexMap = Dictionary(uniqueKeysWithValues: palette.enumerated().map { ($1, $0) })

        var rle = ""
        var i = 0
        while i < gridData.count {
            let colorId = gridData[i]
            let paletteIndex: Int
            if colorId == 0 {
                paletteIndex = 0
            } else if let token = paletteToken(for: colorId), let index = indexMap[token] {
                paletteIndex = index
            } else {
                throw PatternCodecError.invalidData
            }

            var count = 1
            while i + count < gridData.count && gridData[i + count] == colorId && count < 255 {
                count += 1
            }
            if !rle.isEmpty { rle += "," }
            rle += "\(count):\(paletteIndex)"
            i += count
        }

        return PatternPayloadV2(v: 2, w: width, h: height, n: name, p: palette, d: rle)
    }

    private static func paletteTokenSort(_ lhs: String, _ rhs: String) -> Bool {
        let left = splitCode(lhs)
        let right = splitCode(rhs)
        if left.prefix != right.prefix {
            return left.prefix < right.prefix
        }
        if left.number != right.number {
            return left.number < right.number
        }
        return lhs < rhs
    }

    private static func splitCode(_ code: String) -> (prefix: String, number: Int) {
        let prefix = String(code.prefix { $0.isLetter })
        let number = Int(code.drop { $0.isLetter }) ?? 0
        return (prefix, number)
    }
}
