import Foundation

enum AppTab: Hashable {
    case explore
    case create
    case library
    case profile
}

enum AvatarType: String, Codable, CaseIterable {
    case preset
    case generated
    case pattern
}

enum AvatarRenderStyle: String, Codable, CaseIterable, Identifiable {
    case bead
    case pixel

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum PatternStatus: String, Codable, CaseIterable {
    case draft
    case final
}

enum PatternVisibility: String, Codable, CaseIterable {
    case `private`
    case `public`
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum EditorTool: String, CaseIterable, Identifiable {
    case brush
    case eraser
    case eyedropper

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .brush: return "paintbrush"
        case .eraser: return "eraser"
        case .eyedropper: return "eyedropper"
        }
    }
}

enum PreviewMode: String, CaseIterable, Identifiable {
    case pixel
    case bead
    case comparison

    var id: String { rawValue }
    var title: String {
        switch self {
        case .pixel: return "Pixel"
        case .bead: return "Bead"
        case .comparison: return "Compare"
        }
    }
}

enum LibrarySegment: String, CaseIterable, Identifiable {
    case drafts
    case saved
    case published

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum ExportOption: String, CaseIterable, Identifiable {
    case pixelPNG
    case beadPNG
    case comparisonPNG

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pixelPNG: return "Pixel PNG"
        case .beadPNG: return "Bead PNG"
        case .comparisonPNG: return "Comparison PNG"
        }
    }

    var mode: PreviewMode {
        switch self {
        case .pixelPNG: return .pixel
        case .beadPNG: return .bead
        case .comparisonPNG: return .comparison
        }
    }

    var fileName: String {
        switch self {
        case .pixelPNG: return "pixelbeads-pixel.png"
        case .beadPNG: return "pixelbeads-bead.png"
        case .comparisonPNG: return "pixelbeads-comparison.png"
        }
    }
}

struct Avatar: Codable, Hashable {
    var type: AvatarType
    var presetId: String?
    var patternId: UUID?
    var renderStyle: AvatarRenderStyle
}

struct User: Identifiable, Codable, Hashable {
    var id: UUID
    var displayName: String
    var publicHandle: String?
    var avatar: Avatar
    var isGuest: Bool
    var isClaimed: Bool
}

struct PatternPixel: Codable, Hashable {
    var x: Int
    var y: Int
    var colorHex: String?
}

struct Pattern: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var authorName: String
    var width: Int
    var height: Int
    var pixels: [PatternPixel]
    var palette: [String]
    var status: PatternStatus
    var visibility: PatternVisibility
    var difficulty: DifficultyLevel
    var tags: [String]
    var likeCount: Int
    var saveCount: Int
    var isRemixable: Bool
    var createdAt: Date

    var isSquare: Bool { width == height }
}

struct LibraryContent {
    var drafts: [Pattern]
    var saved: [Pattern]
    var published: [Pattern]
}

struct ExportArtifact: Identifiable {
    let id = UUID()
    let option: ExportOption
    let imageData: Data
    let previewPattern: Pattern
}
