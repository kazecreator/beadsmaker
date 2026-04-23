import Foundation
import SwiftData

struct FavoritePatternPayload {
    let name: String
    let author: String
    let width: Int
    let height: Int
    let gridData: [Int]
    let sourceURL: String?
}

enum FavoriteImportError: LocalizedError {
    case invalidPayload
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidPayload:
            return "无法识别该二维码中的图纸数据"
        case .invalidResponse:
            return "图纸链接返回了无效内容"
        }
    }
}

enum FavoriteImportService {
    static func importFromQRCode(_ string: String) async throws -> FavoritePatternPayload {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = remoteURL(from: trimmed) {
            return try await fetchPattern(from: url)
        }

        if let payload = try decodeEmbeddedPattern(from: trimmed) {
            return payload
        }

        throw FavoriteImportError.invalidPayload
    }

    static func refresh(_ favorite: CollectedPattern) async throws -> FavoritePatternPayload? {
        guard let sourceURL = favorite.sourceURL,
              let url = remoteURL(from: sourceURL) else {
            return nil
        }

        return try await fetchPattern(from: url)
    }

    @discardableResult
    static func saveFavorite(
        _ payload: FavoritePatternPayload,
        in modelContext: ModelContext,
        existingFavorites: [CollectedPattern]
    ) throws -> CollectedPattern {
        let signature = try PatternCodec.collectionSignature(
            width: payload.width,
            height: payload.height,
            gridData: payload.gridData
        )

        let thumbnailData = thumbnailData(for: payload)

        if let existing = existingFavorites.first(where: {
            if let sourceURL = payload.sourceURL, let existingSourceURL = $0.sourceURL {
                return existingSourceURL == sourceURL
            }

            return $0.signature == signature
        }) {
            existing.name = payload.name
            existing.author = payload.author
            existing.width = payload.width
            existing.height = payload.height
            existing.gridData = payload.gridData
            existing.thumbnailData = thumbnailData
            existing.signature = signature
            existing.sourceURL = payload.sourceURL ?? existing.sourceURL
            existing.modifiedAt = Date()
            try modelContext.save()
            return existing
        }

        let favorite = CollectedPattern(
            name: payload.name,
            author: payload.author,
            width: payload.width,
            height: payload.height,
            gridData: payload.gridData,
            thumbnailData: thumbnailData,
            signature: signature,
            sourceURL: payload.sourceURL
        )
        modelContext.insert(favorite)
        try modelContext.save()
        return favorite
    }

    static func refreshAll(
        favorites: [CollectedPattern],
        in modelContext: ModelContext
    ) async {
        for favorite in favorites {
            guard let payload = try? await refresh(favorite) else { continue }
            let signature = try? PatternCodec.collectionSignature(
                width: payload.width,
                height: payload.height,
                gridData: payload.gridData
            )
            favorite.name = payload.name
            favorite.author = payload.author
            favorite.width = payload.width
            favorite.height = payload.height
            favorite.gridData = payload.gridData
            favorite.thumbnailData = thumbnailData(for: payload)
            if let signature {
                favorite.signature = signature
            }
            favorite.sourceURL = payload.sourceURL ?? favorite.sourceURL
            favorite.modifiedAt = Date()
        }

        try? modelContext.save()
    }

    private static func fetchPattern(from url: URL) async throws -> FavoritePatternPayload {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw FavoriteImportError.invalidResponse
        }

        return try parsePattern(from: data, fallbackSourceURL: url.absoluteString)
    }

    private static func decodeEmbeddedPattern(from string: String) throws -> FavoritePatternPayload? {
        if let codecPayload = try? PatternCodec.decodeQRCodeString(string) {
            return FavoritePatternPayload(
                name: codecPayload.name,
                author: "未知作者",
                width: codecPayload.width,
                height: codecPayload.height,
                gridData: codecPayload.gridData,
                sourceURL: nil
            )
        }

        guard let data = string.data(using: .utf8) else {
            return nil
        }

        return try parsePattern(from: data, fallbackSourceURL: nil)
    }

    private static func parsePattern(from data: Data, fallbackSourceURL: String?) throws -> FavoritePatternPayload {
        if let codecPayload = try? PatternCodec.decode(data: data) {
            return FavoritePatternPayload(
                name: codecPayload.name,
                author: "未知作者",
                width: codecPayload.width,
                height: codecPayload.height,
                gridData: codecPayload.gridData,
                sourceURL: fallbackSourceURL
            )
        }

        let rootObject = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = normalizedPatternDictionary(from: rootObject),
              let payload = FavoritePatternPayload(
                dictionary: dictionary,
                fallbackSourceURL: fallbackSourceURL
              ) else {
            throw FavoriteImportError.invalidPayload
        }

        return payload
    }

    private static func normalizedPatternDictionary(from object: Any) -> [String: Any]? {
        if let dictionary = object as? [String: Any] {
            if looksLikePattern(dictionary) {
                return dictionary
            }

            for key in ["pattern", "item", "data", "favorite"] {
                if let nested = dictionary[key] as? [String: Any], looksLikePattern(nested) {
                    return nested.merging(dictionary) { current, _ in current }
                }
            }
        }

        if let array = object as? [[String: Any]] {
            return array.first(where: looksLikePattern)
        }

        return nil
    }

    private static func looksLikePattern(_ dictionary: [String: Any]) -> Bool {
        let hasName = dictionary.string(for: ["name", "title"]) != nil
        let hasWidth = dictionary.int(for: ["width", "columns", "cols"]) != nil
        let hasHeight = dictionary.int(for: ["height", "rows"]) != nil
        let hasGrid = dictionary.intArray(for: ["gridData", "grid_data", "grid", "cells"]) != nil
        return hasName && hasWidth && hasHeight && hasGrid
    }

    private static func remoteURL(from string: String) -> URL? {
        guard let url = URL(string: string),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            return nil
        }

        return url
    }

    private static func thumbnailData(for payload: FavoritePatternPayload) -> Data? {
        let preview = Pattern(name: payload.name, width: payload.width, height: payload.height)
        preview.gridData = payload.gridData
        return PatternRenderer.ironedThumbnail(pattern: preview).pngData()
    }
}

private extension FavoritePatternPayload {
    init?(dictionary: [String: Any], fallbackSourceURL: String?) {
        guard let name = dictionary.string(for: ["name", "title"]),
              let width = dictionary.int(for: ["width", "columns", "cols"]),
              let height = dictionary.int(for: ["height", "rows"]),
              let gridData = dictionary.intArray(for: ["gridData", "grid_data", "grid", "cells"]),
              gridData.count == width * height else {
            return nil
        }

        self.name = name
        self.author = dictionary.string(for: ["author", "creator", "username"]) ?? "未知作者"
        self.width = width
        self.height = height
        self.gridData = gridData
        self.sourceURL = dictionary.string(for: ["sourceURL", "sourceUrl", "url", "link"]) ?? fallbackSourceURL
    }
}

private extension Dictionary where Key == String, Value == Any {
    func string(for keys: [String]) -> String? {
        for key in keys {
            if let value = self[key] as? String,
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }

        return nil
    }

    func int(for keys: [String]) -> Int? {
        for key in keys {
            if let value = self[key] as? Int {
                return value
            }

            if let value = self[key] as? NSNumber {
                return value.intValue
            }

            if let value = self[key] as? String,
               let intValue = Int(value) {
                return intValue
            }
        }

        return nil
    }

    func intArray(for keys: [String]) -> [Int]? {
        for key in keys {
            if let values = self[key] as? [Int] {
                return values
            }

            if let values = self[key] as? [NSNumber] {
                return values.map(\.intValue)
            }
        }

        return nil
    }
}
