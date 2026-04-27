import Foundation

enum AppTab: Hashable {
    case explore
    case create
    case library
    case profile
}

enum AvatarType: String, Codable, CaseIterable, Identifiable {
    case preset
    case generated
    case pattern

    var id: String { rawValue }
}

enum AvatarRenderStyle: String, Codable, CaseIterable, Identifiable {
    case bead
    case pixel

    var id: String { rawValue }
    var title: String {
        switch self {
        case .bead: return L10n.tr("Bead")
        case .pixel: return L10n.tr("Pixel")
        }
    }
}

enum PatternStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case final

    var id: String { rawValue }
    var title: String {
        switch self {
        case .draft: return L10n.tr("Draft")
        case .final: return L10n.tr("Final")
        }
    }
}

enum PatternVisibility: String, Codable, CaseIterable, Identifiable {
    case `private`
    case `public`

    var id: String { rawValue }
    var title: String {
        switch self {
        case .private: return L10n.tr("Private")
        case .public: return L10n.tr("Public")
        }
    }
}

enum PatternTheme: String, Codable, CaseIterable, Identifiable {
    case animals
    case food
    case nature
    case games
    case anime
    case holiday
    case geometric
    case emoji
    case fantasy
    case other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .animals:   return L10n.tr("Animals")
        case .food:      return L10n.tr("Food")
        case .nature:    return L10n.tr("Nature")
        case .games:     return L10n.tr("Games")
        case .anime:     return L10n.tr("Anime")
        case .holiday:   return L10n.tr("Holiday")
        case .geometric: return L10n.tr("Geometric")
        case .emoji:     return L10n.tr("Emoji")
        case .fantasy:   return L10n.tr("Fantasy")
        case .other:     return L10n.tr("Other")
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }
    var title: String {
        switch self {
        case .easy: return L10n.tr("Easy")
        case .medium: return L10n.tr("Medium")
        case .hard: return L10n.tr("Hard")
        }
    }
}

enum PatternSizeTier: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }
    var title: String {
        switch self {
        case .small: return L10n.tr("Small")
        case .medium: return L10n.tr("Medium")
        case .large: return L10n.tr("Large")
        }
    }
}

enum ExploreSortMode: String, Codable, CaseIterable, Identifiable {
    case weekly
    case allTime

    var id: String { rawValue }
    var title: String {
        switch self {
        case .weekly: return L10n.tr("Week")
        case .allTime: return L10n.tr("All Time")
        }
    }
}

enum ExploreFeedSource: Equatable {
    case remote
    case cache
    case localFallback
}

struct ExploreFilters: Codable, Equatable {
    var theme: PatternTheme?
    var difficulty: DifficultyLevel?
    var sizeTier: PatternSizeTier?

    static let `default` = ExploreFilters()

    var isDefault: Bool {
        theme == nil && difficulty == nil && sizeTier == nil
    }
}

struct ExploreFeedSnapshot: Equatable {
    let patterns: [Pattern]
    let source: ExploreFeedSource
    var hasMore: Bool = false
}

enum EditorTool: String, CaseIterable, Identifiable {
    case brush
    case eraser
    case eyedropper

    var id: String { rawValue }
    var title: String {
        switch self {
        case .brush: return L10n.tr("Brush")
        case .eraser: return L10n.tr("Eraser")
        case .eyedropper: return L10n.tr("Eyedropper")
        }
    }
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
        case .pixel: return L10n.tr("Finished")
        case .bead: return L10n.tr("Bead")
        case .comparison: return L10n.tr("Compare")
        }
    }
}

enum LibrarySegment: String, CaseIterable, Identifiable {
    case drafts
    case saved
    case published

    var id: String { rawValue }

    static var allCases: [LibrarySegment] {
        AppFeatureFlags.communityEnabled ? [.drafts, .saved, .published] : [.drafts]
    }

    var title: String {
        switch self {
        case .drafts: return L10n.tr("Drafts")
        case .saved: return L10n.tr("Saved")
        case .published: return L10n.tr("Published")
        }
    }
}

enum ExportOption: String, CaseIterable, Identifiable {
    case pixelPNG
    case beadPNG
    case comparisonPNG

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pixelPNG: return L10n.tr("Finished PNG")
        case .beadPNG: return L10n.tr("Bead PNG")
        case .comparisonPNG: return L10n.tr("Comparison PNG")
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

enum PhotoSaveStatus: Equatable {
    case saved
    case failed(String)

    var title: String {
        switch self {
        case .saved:
            return L10n.tr("Saved to Photos")
        case .failed:
            return L10n.tr("Could Not Save")
        }
    }

    var message: String {
        switch self {
        case .saved:
            return L10n.tr("Finished PNG has been saved to your photo library.")
        case .failed(let message):
            return message
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
    /// True after a ¥6 one-time Pro purchase. Unlocks publishing, iCloud sync, and unlimited drafts.
    var isPro: Bool
    /// The Apple user ID linked after Apple Sign In (Phase 2). Nil for guest users.
    var appleUserID: String?

    init(
        id: UUID,
        displayName: String,
        publicHandle: String? = nil,
        avatar: Avatar,
        isGuest: Bool,
        isClaimed: Bool,
        isPro: Bool = false,
        appleUserID: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.publicHandle = publicHandle
        self.avatar = avatar
        self.isGuest = isGuest
        self.isClaimed = isClaimed
        self.isPro = isPro
        self.appleUserID = appleUserID
    }
}

struct PatternPixel: Codable, Hashable {
    var x: Int
    var y: Int
    var colorHex: String?

    var coordinateKey: String {
        "\(x)-\(y)"
    }
}

extension Sequence where Element == PatternPixel {
    func colorMap() -> [String: String?] {
        reduce(into: [:]) { result, pixel in
            result[pixel.coordinateKey] = pixel.colorHex
        }
    }
}

struct BeadColor: Hashable, Identifiable {
    var code: String
    var hex: String

    var id: String { code }

    var family: String {
        String(code.prefix { $0.isLetter })
    }
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
    var theme: PatternTheme
    var tags: [String]
    var likeCount: Int
    var saveCount: Int
    var weekSaveCount: Int?
    var isRemixable: Bool
    var createdAt: Date
    var thumbnailURL: URL?

    var isSquare: Bool { width == height }
    var hasPlacedBeads: Bool { pixels.contains { $0.colorHex != nil } }
    var isAvatarEligibleWork: Bool { isSquare && hasPlacedBeads }
    var sizeTier: PatternSizeTier {
        let shortestSide = min(width, height)
        switch shortestSide {
        case ...16:
            return .small
        case ...32:
            return .medium
        default:
            return .large
        }
    }

    init(
        id: UUID,
        title: String,
        authorName: String,
        width: Int,
        height: Int,
        pixels: [PatternPixel],
        palette: [String],
        status: PatternStatus,
        visibility: PatternVisibility,
        difficulty: DifficultyLevel,
        tags: [String],
        likeCount: Int,
        saveCount: Int,
        weekSaveCount: Int? = nil,
        isRemixable: Bool,
        createdAt: Date,
        theme: PatternTheme = .other,
        thumbnailURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.authorName = authorName
        self.width = width
        self.height = height
        self.pixels = pixels
        self.palette = palette
        self.status = status
        self.visibility = visibility
        self.difficulty = difficulty
        self.theme = theme
        self.tags = tags
        self.likeCount = likeCount
        self.saveCount = saveCount
        self.weekSaveCount = weekSaveCount
        self.isRemixable = isRemixable
        self.createdAt = createdAt
        self.thumbnailURL = thumbnailURL
    }
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
