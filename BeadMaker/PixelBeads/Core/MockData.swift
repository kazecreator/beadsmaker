import Foundation

enum MockData {
    static let defaultPalette = [
        "#111111", "#FFFFFF", "#F5F5F5", "#FF5A36", "#3B82F6", "#F4C542", "#5DBB63"
    ]

    static let presetAvatarIDs = ["coral-cat", "mono-heart", "mini-star", "pixel-smile"]

    static let guestUser = User(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
        displayName: "Guest Maker",
        publicHandle: nil,
        avatar: Avatar(type: .preset, presetId: presetAvatarIDs[0], patternId: nil, renderStyle: .bead),
        isGuest: true,
        isClaimed: false
    )

    static let creatorNames = ["Mia", "Alex", "Jun", "Nora"]

    static let explorePatterns: [Pattern] = [
        makePattern(
            title: "Coral Flower",
            authorName: "Mia",
            size: 16,
            difficulty: .easy,
            tags: ["Floral", "Mini"],
            filled: [
                (7, 2, "#FF5A36"), (8, 2, "#FF5A36"),
                (6, 3, "#FF5A36"), (7, 3, "#FF5A36"), (8, 3, "#FF5A36"), (9, 3, "#FF5A36"),
                (5, 4, "#F4C542"), (6, 4, "#FF5A36"), (7, 4, "#FF5A36"), (8, 4, "#FF5A36"), (9, 4, "#FF5A36"), (10, 4, "#F4C542"),
                (6, 5, "#FF5A36"), (7, 5, "#FF5A36"), (8, 5, "#FF5A36"), (9, 5, "#FF5A36"),
                (7, 6, "#F4C542"), (8, 6, "#F4C542"),
                (7, 7, "#5DBB63"), (8, 7, "#5DBB63"),
                (7, 8, "#5DBB63"), (8, 8, "#5DBB63"),
                (6, 9, "#5DBB63"), (7, 9, "#5DBB63"), (8, 9, "#5DBB63"),
                (8, 10, "#5DBB63")
            ]
        ),
        makePattern(
            title: "Lucky Star",
            authorName: "Alex",
            size: 16,
            difficulty: .medium,
            tags: ["Icon", "Gift"],
            filled: [
                (8, 1, "#F4C542"),
                (7, 3, "#F4C542"), (8, 3, "#F4C542"), (9, 3, "#F4C542"),
                (4, 4, "#F4C542"), (8, 4, "#F4C542"), (12, 4, "#F4C542"),
                (5, 6, "#F4C542"), (8, 6, "#F4C542"), (11, 6, "#F4C542"),
                (6, 8, "#F4C542"), (7, 8, "#F4C542"), (8, 8, "#F4C542"), (9, 8, "#F4C542"), (10, 8, "#F4C542"),
                (7, 10, "#F4C542"), (8, 10, "#F4C542"), (9, 10, "#F4C542"),
                (8, 12, "#F4C542")
            ]
        ),
        makePattern(
            title: "Ocean Charm",
            authorName: "Jun",
            size: 16,
            difficulty: .hard,
            tags: ["Sea", "Character"],
            filled: [
                (5, 3, "#3B82F6"), (6, 3, "#3B82F6"), (7, 3, "#3B82F6"), (8, 3, "#3B82F6"), (9, 3, "#3B82F6"), (10, 3, "#3B82F6"),
                (4, 4, "#3B82F6"), (5, 4, "#3B82F6"), (6, 4, "#FFFFFF"), (7, 4, "#111111"), (8, 4, "#111111"), (9, 4, "#FFFFFF"), (10, 4, "#3B82F6"), (11, 4, "#3B82F6"),
                (4, 5, "#3B82F6"), (5, 5, "#FFFFFF"), (6, 5, "#FFFFFF"), (7, 5, "#111111"), (8, 5, "#111111"), (9, 5, "#FFFFFF"), (10, 5, "#FFFFFF"), (11, 5, "#3B82F6"),
                (5, 6, "#3B82F6"), (6, 6, "#FFFFFF"), (7, 6, "#FFFFFF"), (8, 6, "#FFFFFF"), (9, 6, "#FFFFFF"), (10, 6, "#FFFFFF"),
                (6, 7, "#3B82F6"), (7, 7, "#3B82F6"), (8, 7, "#3B82F6"), (9, 7, "#3B82F6"),
                (7, 8, "#3B82F6"), (8, 8, "#3B82F6")
            ]
        )
    ]

    static func makePattern(
        title: String,
        authorName: String,
        size: Int,
        difficulty: DifficultyLevel,
        tags: [String],
        filled: [(Int, Int, String)]
    ) -> Pattern {
        let pixels = filled.map { PatternPixel(x: $0.0, y: $0.1, colorHex: $0.2) }
        return Pattern(
            id: UUID(),
            title: title,
            authorName: authorName,
            width: size,
            height: size,
            pixels: pixels,
            palette: defaultPalette,
            status: .final,
            visibility: .public,
            difficulty: difficulty,
            tags: tags,
            likeCount: Int.random(in: 32...420),
            saveCount: Int.random(in: 10...120),
            isRemixable: true,
            createdAt: .now.addingTimeInterval(Double.random(in: -200000 ... -1000))
        )
    }

    static func blankPattern(title: String = "Untitled Draft", size: Int = 16, authorName: String = "Guest Maker") -> Pattern {
        Pattern(
            id: UUID(),
            title: title,
            authorName: authorName,
            width: size,
            height: size,
            pixels: [],
            palette: defaultPalette,
            status: .draft,
            visibility: .private,
            difficulty: .easy,
            tags: ["New"],
            likeCount: 0,
            saveCount: 0,
            isRemixable: true,
            createdAt: .now
        )
    }
}
