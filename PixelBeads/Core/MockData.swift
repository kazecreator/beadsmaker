import Foundation

struct PresetAvatarDefinition: Hashable {
    let id: String
    let title: String
    let pattern: Pattern
}

enum MockData {
    static let mardStandardPalette: [BeadColor] = [
        BeadColor(code: "A1", hex: "#FAF4C8"),
        BeadColor(code: "A2", hex: "#FFFFD5"),
        BeadColor(code: "A3", hex: "#FEFF8B"),
        BeadColor(code: "A4", hex: "#FBED56"),
        BeadColor(code: "A5", hex: "#F4D738"),
        BeadColor(code: "A6", hex: "#FEAC4C"),
        BeadColor(code: "A7", hex: "#FE8B4C"),
        BeadColor(code: "A8", hex: "#FFDA45"),
        BeadColor(code: "A9", hex: "#FF995B"),
        BeadColor(code: "A10", hex: "#F77C31"),
        BeadColor(code: "A11", hex: "#FFDD99"),
        BeadColor(code: "A12", hex: "#FE9F72"),
        BeadColor(code: "A13", hex: "#FFC365"),
        BeadColor(code: "A14", hex: "#FD543D"),
        BeadColor(code: "A15", hex: "#FFF365"),
        BeadColor(code: "A16", hex: "#FFFF9F"),
        BeadColor(code: "A17", hex: "#FFE36E"),
        BeadColor(code: "A18", hex: "#FEBE7D"),
        BeadColor(code: "A19", hex: "#FD7C72"),
        BeadColor(code: "A20", hex: "#FFD568"),
        BeadColor(code: "A21", hex: "#FFE395"),
        BeadColor(code: "A22", hex: "#F4F57D"),
        BeadColor(code: "A23", hex: "#E6C9B7"),
        BeadColor(code: "A24", hex: "#F7F8A2"),
        BeadColor(code: "A25", hex: "#FFD67D"),
        BeadColor(code: "A26", hex: "#FFC830"),
        BeadColor(code: "B1", hex: "#E6EE31"),
        BeadColor(code: "B2", hex: "#63F347"),
        BeadColor(code: "B3", hex: "#9EF780"),
        BeadColor(code: "B4", hex: "#5DE035"),
        BeadColor(code: "B5", hex: "#35E352"),
        BeadColor(code: "B6", hex: "#65E2A6"),
        BeadColor(code: "B7", hex: "#3DAF80"),
        BeadColor(code: "B8", hex: "#1C9C4F"),
        BeadColor(code: "B9", hex: "#27523A"),
        BeadColor(code: "B10", hex: "#95D3C2"),
        BeadColor(code: "B11", hex: "#5D722A"),
        BeadColor(code: "B12", hex: "#166F41"),
        BeadColor(code: "B13", hex: "#CAEB7B"),
        BeadColor(code: "B14", hex: "#ADE946"),
        BeadColor(code: "B15", hex: "#2E5132"),
        BeadColor(code: "B16", hex: "#C5ED9C"),
        BeadColor(code: "B17", hex: "#9BB13A"),
        BeadColor(code: "B18", hex: "#E6EE49"),
        BeadColor(code: "B19", hex: "#24B88C"),
        BeadColor(code: "B20", hex: "#C2F0CC"),
        BeadColor(code: "B21", hex: "#156A6B"),
        BeadColor(code: "B22", hex: "#0B3C43"),
        BeadColor(code: "B23", hex: "#303A21"),
        BeadColor(code: "B24", hex: "#EEFCA5"),
        BeadColor(code: "B25", hex: "#4E846D"),
        BeadColor(code: "B26", hex: "#8D7A35"),
        BeadColor(code: "B27", hex: "#CCE1AF"),
        BeadColor(code: "B28", hex: "#9EE5B9"),
        BeadColor(code: "B29", hex: "#C5E254"),
        BeadColor(code: "B30", hex: "#E2FCB1"),
        BeadColor(code: "B31", hex: "#B0E792"),
        BeadColor(code: "B32", hex: "#9CAB5A"),
        BeadColor(code: "C1", hex: "#E8FFE7"),
        BeadColor(code: "C2", hex: "#A9F9FC"),
        BeadColor(code: "C3", hex: "#A0E2FB"),
        BeadColor(code: "C4", hex: "#41CCFF"),
        BeadColor(code: "C5", hex: "#01ACEB"),
        BeadColor(code: "C6", hex: "#50AAF0"),
        BeadColor(code: "C7", hex: "#3677D2"),
        BeadColor(code: "C8", hex: "#0F54C0"),
        BeadColor(code: "C9", hex: "#324BCA"),
        BeadColor(code: "C10", hex: "#3EBCE2"),
        BeadColor(code: "C11", hex: "#28DDDE"),
        BeadColor(code: "C12", hex: "#1C334D"),
        BeadColor(code: "C13", hex: "#CDE8FF"),
        BeadColor(code: "C14", hex: "#D5FDFF"),
        BeadColor(code: "C15", hex: "#22C4C6"),
        BeadColor(code: "C16", hex: "#1557A8"),
        BeadColor(code: "C17", hex: "#04D1F6"),
        BeadColor(code: "C18", hex: "#1D3344"),
        BeadColor(code: "C19", hex: "#1887A2"),
        BeadColor(code: "C20", hex: "#176DAF"),
        BeadColor(code: "C21", hex: "#BEDDFF"),
        BeadColor(code: "C22", hex: "#67B4BE"),
        BeadColor(code: "C23", hex: "#C8E2FF"),
        BeadColor(code: "C24", hex: "#7CC4FF"),
        BeadColor(code: "C25", hex: "#A9E5E5"),
        BeadColor(code: "C26", hex: "#3CAED8"),
        BeadColor(code: "C27", hex: "#D3DFFA"),
        BeadColor(code: "C28", hex: "#BBCFED"),
        BeadColor(code: "C29", hex: "#34488E"),
        BeadColor(code: "D1", hex: "#AEB4F2"),
        BeadColor(code: "D2", hex: "#858EDD"),
        BeadColor(code: "D3", hex: "#2F54AF"),
        BeadColor(code: "D4", hex: "#182A84"),
        BeadColor(code: "D5", hex: "#B843C5"),
        BeadColor(code: "D6", hex: "#AC7BDE"),
        BeadColor(code: "D7", hex: "#8854B3"),
        BeadColor(code: "D8", hex: "#E2D3FF"),
        BeadColor(code: "D9", hex: "#D5B9F8"),
        BeadColor(code: "D10", hex: "#361851"),
        BeadColor(code: "D11", hex: "#B9BAE1"),
        BeadColor(code: "D12", hex: "#DE9AD4"),
        BeadColor(code: "D13", hex: "#B90095"),
        BeadColor(code: "D14", hex: "#8B279B"),
        BeadColor(code: "D15", hex: "#2F1F90"),
        BeadColor(code: "D16", hex: "#E3E1EE"),
        BeadColor(code: "D17", hex: "#C4D4F6"),
        BeadColor(code: "D18", hex: "#A45EC7"),
        BeadColor(code: "D19", hex: "#D8C3D7"),
        BeadColor(code: "D20", hex: "#9C32B2"),
        BeadColor(code: "D21", hex: "#9A009B"),
        BeadColor(code: "D22", hex: "#333A95"),
        BeadColor(code: "D23", hex: "#EBDAFC"),
        BeadColor(code: "D24", hex: "#7786E5"),
        BeadColor(code: "D25", hex: "#494FC7"),
        BeadColor(code: "D26", hex: "#DFC2F8"),
        BeadColor(code: "E1", hex: "#FDD3CC"),
        BeadColor(code: "E2", hex: "#FEC0DF"),
        BeadColor(code: "E3", hex: "#FFB7E7"),
        BeadColor(code: "E4", hex: "#E8649E"),
        BeadColor(code: "E5", hex: "#F551A2"),
        BeadColor(code: "E6", hex: "#F13D74"),
        BeadColor(code: "E7", hex: "#C63478"),
        BeadColor(code: "E8", hex: "#FFDBE9"),
        BeadColor(code: "E9", hex: "#E970CC"),
        BeadColor(code: "E10", hex: "#D33793"),
        BeadColor(code: "E11", hex: "#FCDDD2"),
        BeadColor(code: "E12", hex: "#F78FC3"),
        BeadColor(code: "E13", hex: "#B5006D"),
        BeadColor(code: "E14", hex: "#FFD1BA"),
        BeadColor(code: "E15", hex: "#F8C7C9"),
        BeadColor(code: "E16", hex: "#FFF3EB"),
        BeadColor(code: "E17", hex: "#FFE2EA"),
        BeadColor(code: "E18", hex: "#FFC7DB"),
        BeadColor(code: "E19", hex: "#FEBAD5"),
        BeadColor(code: "E20", hex: "#D8C7D1"),
        BeadColor(code: "E21", hex: "#BD9DA1"),
        BeadColor(code: "E22", hex: "#B785A1"),
        BeadColor(code: "E23", hex: "#937A8D"),
        BeadColor(code: "E24", hex: "#E1BCE8"),
        BeadColor(code: "F1", hex: "#FD957B"),
        BeadColor(code: "F2", hex: "#FC3D46"),
        BeadColor(code: "F3", hex: "#F74941"),
        BeadColor(code: "F4", hex: "#FC283C"),
        BeadColor(code: "F5", hex: "#E7002F"),
        BeadColor(code: "F6", hex: "#943630"),
        BeadColor(code: "F7", hex: "#971937"),
        BeadColor(code: "F8", hex: "#BC0028"),
        BeadColor(code: "F9", hex: "#E2677A"),
        BeadColor(code: "F10", hex: "#8A4526"),
        BeadColor(code: "F11", hex: "#5A2121"),
        BeadColor(code: "F12", hex: "#FD4E6A"),
        BeadColor(code: "F13", hex: "#F35744"),
        BeadColor(code: "F14", hex: "#FFA9AD"),
        BeadColor(code: "F15", hex: "#D30022"),
        BeadColor(code: "F16", hex: "#FEC2A6"),
        BeadColor(code: "F17", hex: "#E69C79"),
        BeadColor(code: "F18", hex: "#D37C46"),
        BeadColor(code: "F19", hex: "#C1444A"),
        BeadColor(code: "F20", hex: "#CD9391"),
        BeadColor(code: "F21", hex: "#F7B4C6"),
        BeadColor(code: "F22", hex: "#FDC0D0"),
        BeadColor(code: "F23", hex: "#F67E66"),
        BeadColor(code: "F24", hex: "#E698AA"),
        BeadColor(code: "F25", hex: "#E54B4F"),
        BeadColor(code: "G1", hex: "#FFE2CE"),
        BeadColor(code: "G2", hex: "#FFC4AA"),
        BeadColor(code: "G3", hex: "#F4C3A5"),
        BeadColor(code: "G4", hex: "#E1B383"),
        BeadColor(code: "G5", hex: "#EDB045"),
        BeadColor(code: "G6", hex: "#E99C17"),
        BeadColor(code: "G7", hex: "#9D5B3E"),
        BeadColor(code: "G8", hex: "#753832"),
        BeadColor(code: "G9", hex: "#E6B483"),
        BeadColor(code: "G10", hex: "#D98C39"),
        BeadColor(code: "G11", hex: "#E0C593"),
        BeadColor(code: "G12", hex: "#FFC890"),
        BeadColor(code: "G13", hex: "#B7714A"),
        BeadColor(code: "G14", hex: "#8D614C"),
        BeadColor(code: "G15", hex: "#FCF9E0"),
        BeadColor(code: "G16", hex: "#F2D9BA"),
        BeadColor(code: "G17", hex: "#78524B"),
        BeadColor(code: "G18", hex: "#FFE4CC"),
        BeadColor(code: "G19", hex: "#E07935"),
        BeadColor(code: "G20", hex: "#A94023"),
        BeadColor(code: "G21", hex: "#B88558"),
        BeadColor(code: "H1", hex: "#FDFBFF"),
        BeadColor(code: "H2", hex: "#FEFFFF"),
        BeadColor(code: "H3", hex: "#B6B1BA"),
        BeadColor(code: "H4", hex: "#89858C"),
        BeadColor(code: "H5", hex: "#48464E"),
        BeadColor(code: "H6", hex: "#2F2B2F"),
        BeadColor(code: "H7", hex: "#000000"),
        BeadColor(code: "H8", hex: "#E7D6DB"),
        BeadColor(code: "H9", hex: "#EDEDED"),
        BeadColor(code: "H10", hex: "#EEE9EA"),
        BeadColor(code: "H11", hex: "#CECDD5"),
        BeadColor(code: "H12", hex: "#FFF5ED"),
        BeadColor(code: "H13", hex: "#F5ECD2"),
        BeadColor(code: "H14", hex: "#CFD7D3"),
        BeadColor(code: "H15", hex: "#98A6A8"),
        BeadColor(code: "H16", hex: "#1D1414"),
        BeadColor(code: "H17", hex: "#F1EDED"),
        BeadColor(code: "H18", hex: "#FFFDF0"),
        BeadColor(code: "H19", hex: "#F6EFE2"),
        BeadColor(code: "H20", hex: "#949FA3"),
        BeadColor(code: "H21", hex: "#FFFBE1"),
        BeadColor(code: "H22", hex: "#CACAD4"),
        BeadColor(code: "H23", hex: "#9A9D94"),
        BeadColor(code: "M1", hex: "#BCC6B8"),
        BeadColor(code: "M2", hex: "#8AA386"),
        BeadColor(code: "M3", hex: "#697D80"),
        BeadColor(code: "M4", hex: "#E3D2BC"),
        BeadColor(code: "M5", hex: "#D0CCAA"),
        BeadColor(code: "M6", hex: "#B0A782"),
        BeadColor(code: "M7", hex: "#B4A497"),
        BeadColor(code: "M8", hex: "#B38281"),
        BeadColor(code: "M9", hex: "#A58767"),
        BeadColor(code: "M10", hex: "#C5B2BC"),
        BeadColor(code: "M11", hex: "#9F7594"),
        BeadColor(code: "M12", hex: "#644749"),
        BeadColor(code: "M13", hex: "#D19066"),
        BeadColor(code: "M14", hex: "#C77362"),
        BeadColor(code: "M15", hex: "#757D78"),
        BeadColor(code: "P1", hex: "#FCF7F8"),
        BeadColor(code: "P2", hex: "#B0A9AC"),
        BeadColor(code: "P3", hex: "#AFDCAB"),
        BeadColor(code: "P4", hex: "#FEA49F"),
        BeadColor(code: "P5", hex: "#EE8C3E"),
        BeadColor(code: "P6", hex: "#5FD0A7"),
        BeadColor(code: "P7", hex: "#EB9270"),
        BeadColor(code: "P8", hex: "#F0D958"),
        BeadColor(code: "P9", hex: "#D9D9D9"),
        BeadColor(code: "P10", hex: "#D9C7EA"),
        BeadColor(code: "P11", hex: "#F3ECC9"),
        BeadColor(code: "P12", hex: "#E6EEF2"),
        BeadColor(code: "P13", hex: "#AACBEF"),
        BeadColor(code: "P14", hex: "#337680"),
        BeadColor(code: "P15", hex: "#668575"),
        BeadColor(code: "P16", hex: "#FEBF45"),
        BeadColor(code: "P17", hex: "#FEA324"),
        BeadColor(code: "P18", hex: "#FEB89F"),
        BeadColor(code: "P19", hex: "#FFFEEC"),
        BeadColor(code: "P20", hex: "#FEBECF"),
        BeadColor(code: "P21", hex: "#ECBEBF"),
        BeadColor(code: "P22", hex: "#E4A89F"),
        BeadColor(code: "P23", hex: "#A56268"),
        BeadColor(code: "Q1", hex: "#F2A5E8"),
        BeadColor(code: "Q2", hex: "#E9EC91"),
        BeadColor(code: "Q3", hex: "#FFFF00"),
        BeadColor(code: "Q4", hex: "#FFEBFA"),
        BeadColor(code: "Q5", hex: "#76CEDE"),
        BeadColor(code: "R1", hex: "#D50D21"),
        BeadColor(code: "R2", hex: "#F92F83"),
        BeadColor(code: "R3", hex: "#FD8324"),
        BeadColor(code: "R4", hex: "#F8EC31"),
        BeadColor(code: "R5", hex: "#35C75B"),
        BeadColor(code: "R6", hex: "#238891"),
        BeadColor(code: "R7", hex: "#19779D"),
        BeadColor(code: "R8", hex: "#1A60C3"),
        BeadColor(code: "R9", hex: "#9A56B4"),
        BeadColor(code: "R10", hex: "#FFDB4C"),
        BeadColor(code: "R11", hex: "#FFEBFA"),
        BeadColor(code: "R12", hex: "#D8D5CE"),
        BeadColor(code: "R13", hex: "#55514C"),
        BeadColor(code: "R14", hex: "#9FE4DF"),
        BeadColor(code: "R15", hex: "#77CEE9"),
        BeadColor(code: "R16", hex: "#3ECFCA"),
        BeadColor(code: "R17", hex: "#4A867A"),
        BeadColor(code: "R18", hex: "#7FCD9D"),
        BeadColor(code: "R19", hex: "#CDE55D"),
        BeadColor(code: "R20", hex: "#E8C7B4"),
        BeadColor(code: "R21", hex: "#AD6F3C"),
        BeadColor(code: "R22", hex: "#6C372F"),
        BeadColor(code: "R23", hex: "#FEB872"),
        BeadColor(code: "R24", hex: "#F3C1C0"),
        BeadColor(code: "R25", hex: "#C9675E"),
        BeadColor(code: "R26", hex: "#D293BE"),
        BeadColor(code: "R27", hex: "#EA8CB1"),
        BeadColor(code: "R28", hex: "#9C87D6"),
        BeadColor(code: "T1", hex: "#FFFFFF"),
        BeadColor(code: "Y1", hex: "#FD6FB4"),
        BeadColor(code: "Y2", hex: "#FEB481"),
        BeadColor(code: "Y3", hex: "#D7FAA0"),
        BeadColor(code: "Y4", hex: "#8BDBFA"),
        BeadColor(code: "Y5", hex: "#E987EA"),
        BeadColor(code: "ZG1", hex: "#DAABB3"),
        BeadColor(code: "ZG2", hex: "#D6AA87"),
        BeadColor(code: "ZG3", hex: "#C1BD8D"),
        BeadColor(code: "ZG4", hex: "#96869F"),
        BeadColor(code: "ZG5", hex: "#8490A6"),
        BeadColor(code: "ZG6", hex: "#94BFE2"),
        BeadColor(code: "ZG7", hex: "#E2A9D2"),
        BeadColor(code: "ZG8", hex: "#AB91C0")
    ]

    static let defaultPalette = mardStandardPalette.map(\.hex)

    static var mardColorFamilies: [String] {
        Array(Set(mardStandardPalette.map(\.family))).sorted { left, right in
            if left.count == right.count { return left < right }
            return left.count < right.count
        }
    }

    static func beadColor(for hex: String?) -> BeadColor? {
        guard let hex else { return nil }
        return mardStandardPalette.first { $0.hex.caseInsensitiveCompare(hex) == .orderedSame }
    }

    static func closestBeadColor(for hex: String?) -> BeadColor? {
        guard let hex else { return nil }
        if let exact = beadColor(for: hex) { return exact }
        guard let (r1, g1, b1) = parseRGB(hex) else { return nil }
        return mardStandardPalette.min {
            guard let (ra, ga, ba) = parseRGB($0.hex),
                  let (rb, gb, bb) = parseRGB($1.hex) else { return true }
            let da = (r1 - ra) * (r1 - ra) + (g1 - ga) * (g1 - ga) + (b1 - ba) * (b1 - ba)
            let db = (r1 - rb) * (r1 - rb) + (g1 - gb) * (g1 - gb) + (b1 - bb) * (b1 - bb)
            return da < db
        }
    }

    private static func parseRGB(_ hex: String) -> (Int, Int, Int)? {
        let value = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard value.count == 6, let number = UInt32(value, radix: 16) else { return nil }
        return (
            Int((number >> 16) & 0xFF),
            Int((number >> 8) & 0xFF),
            Int(number & 0xFF)
        )
    }

    private static func presetAvatarPattern(
        id: String,
        title: String,
        rows: [String],
        colors: [Character: String]
    ) -> Pattern {
        let pixels = rows.enumerated().flatMap { y, row in
            row.enumerated().compactMap { x, character -> PatternPixel? in
                guard let color = colors[character] else { return nil }
                return PatternPixel(x: x, y: y, colorHex: color)
            }
        }

        return Pattern(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            authorName: "PixelBeads",
            width: rows.first?.count ?? 0,
            height: rows.count,
            pixels: pixels,
            palette: Array(Set(pixels.compactMap(\.colorHex))).sorted(),
            status: .final,
            visibility: .private,
            difficulty: .easy,
            tags: [],
            likeCount: 0,
            saveCount: 0,
            isRemixable: false,
            createdAt: .now,
            theme: .other
        )
    }

    static let presetAvatars = [
        PresetAvatarDefinition(
            id: "mono-heart",
            title: L10n.tr("Mono Heart"),
            pattern: presetAvatarPattern(
                id: "00000000-0000-0000-0000-000000000102",
                title: L10n.tr("Mono Heart"),
                rows: [
                    ".RR...RR.",
                    "RRRR.RRRR",
                    "RRRRRRRRR",
                    "RRRRRRRRR",
                    ".RRRRRRR.",
                    "..RRRRR..",
                    "...RRR...",
                    "....R....",
                    "........."
                ],
                colors: ["R": "#FF5A36"]
            )
        ),
        PresetAvatarDefinition(
            id: "mini-star",
            title: L10n.tr("Mini Star"),
            pattern: presetAvatarPattern(
                id: "00000000-0000-0000-0000-000000000103",
                title: L10n.tr("Mini Star"),
                rows: [
                    "....Y....",
                    "...YYY...",
                    "...YYY...",
                    "YYYYYYYYY",
                    ".YYYYYYY.",
                    "..YYYYY..",
                    "..YY.YY..",
                    ".Y.....Y.",
                    "........."
                ],
                colors: ["Y": "#F4C542"]
            )
        ),
        PresetAvatarDefinition(
            id: "pixel-smile",
            title: L10n.tr("Pixel Smile"),
            pattern: presetAvatarPattern(
                id: "00000000-0000-0000-0000-000000000104",
                title: L10n.tr("Pixel Smile"),
                rows: [
                    "..YYYYY..",
                    ".YYYYYYY.",
                    "YYDYYYDYY",
                    "YYYYYYYYY",
                    "YYYYYYYYY",
                    "YYDDDDDYY",
                    ".YYYYYYY.",
                    "..YYYYY..",
                    "........."
                ],
                colors: ["Y": "#F4C542", "D": "#111111"]
            )
        )
    ]

    static let presetAvatarIDs = presetAvatars.map(\.id)

    static let guestUser = User(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
        displayName: L10n.tr("Guest Maker"),
        publicHandle: nil,
        avatar: Avatar(type: .preset, presetId: presetAvatarIDs[0], patternId: nil, renderStyle: .bead),
        isGuest: true,
        isClaimed: false,
        isPro: false
    )

    static let creatorNames = ["Mia", "Alex", "Jun", "Nora"]

    static let explorePatterns: [Pattern] = [
        makePattern(
            title: L10n.tr("Coral Flower"),
            authorName: L10n.tr("Mia"),
            size: 16,
            difficulty: .easy,
            tags: [L10n.tr("Floral"), L10n.tr("Mini")],
            filled: [
                (7, 2, "#FD543D"), (8, 2, "#FD543D"),
                (6, 3, "#FD543D"), (7, 3, "#FD543D"), (8, 3, "#FD543D"), (9, 3, "#FD543D"),
                (5, 4, "#FFDA45"), (6, 4, "#FD543D"), (7, 4, "#FD543D"), (8, 4, "#FD543D"), (9, 4, "#FD543D"), (10, 4, "#FFDA45"),
                (6, 5, "#FD543D"), (7, 5, "#FD543D"), (8, 5, "#FD543D"), (9, 5, "#FD543D"),
                (7, 6, "#FFDA45"), (8, 6, "#FFDA45"),
                (7, 7, "#1C9C4F"), (8, 7, "#1C9C4F"),
                (7, 8, "#1C9C4F"), (8, 8, "#1C9C4F"),
                (6, 9, "#1C9C4F"), (7, 9, "#1C9C4F"), (8, 9, "#1C9C4F"),
                (8, 10, "#1C9C4F")
            ]
        ),
        makePattern(
            title: L10n.tr("Lucky Star"),
            authorName: L10n.tr("Alex"),
            size: 16,
            difficulty: .medium,
            tags: [L10n.tr("Icon"), L10n.tr("Gift")],
            filled: [
                (8, 1, "#FFDA45"),
                (7, 3, "#FFDA45"), (8, 3, "#FFDA45"), (9, 3, "#FFDA45"),
                (4, 4, "#FFDA45"), (8, 4, "#FFDA45"), (12, 4, "#FFDA45"),
                (5, 6, "#FFDA45"), (8, 6, "#FFDA45"), (11, 6, "#FFDA45"),
                (6, 8, "#FFDA45"), (7, 8, "#FFDA45"), (8, 8, "#FFDA45"), (9, 8, "#FFDA45"), (10, 8, "#FFDA45"),
                (7, 10, "#FFDA45"), (8, 10, "#FFDA45"), (9, 10, "#FFDA45"),
                (8, 12, "#FFDA45")
            ]
        ),
        makePattern(
            title: L10n.tr("Ocean Charm"),
            authorName: L10n.tr("Jun"),
            size: 16,
            difficulty: .hard,
            tags: [L10n.tr("Sea"), L10n.tr("Character")],
            filled: [
                (5, 3, "#3677D2"), (6, 3, "#3677D2"), (7, 3, "#3677D2"), (8, 3, "#3677D2"), (9, 3, "#3677D2"), (10, 3, "#3677D2"),
                (4, 4, "#3677D2"), (5, 4, "#3677D2"), (6, 4, "#FFFFFF"), (7, 4, "#1C334D"), (8, 4, "#1C334D"), (9, 4, "#FFFFFF"), (10, 4, "#3677D2"), (11, 4, "#3677D2"),
                (4, 5, "#3677D2"), (5, 5, "#FFFFFF"), (6, 5, "#FFFFFF"), (7, 5, "#1C334D"), (8, 5, "#1C334D"), (9, 5, "#FFFFFF"), (10, 5, "#FFFFFF"), (11, 5, "#3677D2"),
                (5, 6, "#3677D2"), (6, 6, "#FFFFFF"), (7, 6, "#FFFFFF"), (8, 6, "#FFFFFF"), (9, 6, "#FFFFFF"), (10, 6, "#FFFFFF"),
                (6, 7, "#3677D2"), (7, 7, "#3677D2"), (8, 7, "#3677D2"), (9, 7, "#3677D2"),
                (7, 8, "#3677D2"), (8, 8, "#3677D2")
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

    static func blankPattern(title: String = L10n.tr("Untitled Draft"), size: Int = 16, authorName: String = L10n.tr("Guest Maker")) -> Pattern {
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
            tags: [L10n.tr("New")],
            likeCount: 0,
            saveCount: 0,
            isRemixable: true,
            createdAt: .now
        )
    }
}
