import Foundation
import UIKit

enum BeadColorLibrary {
    static let colors: [BeadColor] = [
        // Red family (MARD F-series / adjacent rose tones)
        BeadColor(id: 1,  hex: "E7002F", chineseName: "红色",    englishName: "Red",           colorCode: "F5",  group: .red, standardCode: "F5"),
        BeadColor(id: 2,  hex: "FC3D46", chineseName: "亮红色",  englishName: "Bright Red",    colorCode: "F2",  group: .red, standardCode: "F2"),
        BeadColor(id: 3,  hex: "E2677A", chineseName: "玫瑰红",  englishName: "Rose",          colorCode: "F9",  group: .red, standardCode: "F9"),
        BeadColor(id: 4,  hex: "5A2121", chineseName: "深红色",  englishName: "Dark Red",      colorCode: "F11", group: .red, standardCode: "F11"),
        BeadColor(id: 5,  hex: "FFA9AD", chineseName: "浅红色",  englishName: "Light Red",     colorCode: "F14", group: .red, standardCode: "F14"),
        BeadColor(id: 6,  hex: "F35744", chineseName: "橙红色",  englishName: "Orange Red",    colorCode: "F13", group: .red, standardCode: "F13"),

        // Orange family (MARD A/G-series)
        BeadColor(id: 7,  hex: "F77C31", chineseName: "橙色",    englishName: "Orange",        colorCode: "A10", group: .orange, standardCode: "A10"),
        BeadColor(id: 8,  hex: "E99C17", chineseName: "深橙色",  englishName: "Dark Orange",   colorCode: "G6",  group: .orange, standardCode: "G6"),
        BeadColor(id: 9,  hex: "FEBE7D", chineseName: "浅橙色",  englishName: "Light Orange",  colorCode: "A18", group: .orange, standardCode: "A18"),
        BeadColor(id: 10, hex: "F4C3A5", chineseName: "桃色",    englishName: "Peach",         colorCode: "G3",  group: .orange, standardCode: "G3"),
        BeadColor(id: 11, hex: "FD543D", chineseName: "蕃茄红",  englishName: "Tomato",        colorCode: "A14", group: .orange, standardCode: "A14"),

        // Yellow family (MARD A/G-series)
        BeadColor(id: 12, hex: "F4D738", chineseName: "黄色",    englishName: "Yellow",        colorCode: "A5",  group: .yellow, standardCode: "A5"),
        BeadColor(id: 13, hex: "FFF365", chineseName: "亮黄色",  englishName: "Bright Yellow", colorCode: "A15", group: .yellow, standardCode: "A15"),
        BeadColor(id: 14, hex: "EDB045", chineseName: "金黄色",  englishName: "Goldenrod",     colorCode: "G5",  group: .yellow, standardCode: "G5"),
        BeadColor(id: 15, hex: "FFFFD5", chineseName: "柠檬奶油",englishName: "Lemon Cream",   colorCode: "A2",  group: .yellow, standardCode: "A2"),
        BeadColor(id: 16, hex: "F2D9BA", chineseName: "小麦色",  englishName: "Wheat",         colorCode: "G16", group: .yellow, standardCode: "G16"),

        // Green family (MARD B-series)
        BeadColor(id: 17, hex: "1C9C4F", chineseName: "绿色",    englishName: "Green",         colorCode: "B8",  group: .green, standardCode: "B8"),
        BeadColor(id: 18, hex: "2E5132", chineseName: "深绿色",  englishName: "Dark Green",    colorCode: "B15", group: .green, standardCode: "B15"),
        BeadColor(id: 19, hex: "9EE5B9", chineseName: "浅绿色",  englishName: "Light Green",   colorCode: "B28", group: .green, standardCode: "B28"),
        BeadColor(id: 20, hex: "63F347", chineseName: "草绿色",  englishName: "Lime Green",    colorCode: "B2",  group: .green, standardCode: "B2"),
        BeadColor(id: 21, hex: "166F41", chineseName: "森林绿",  englishName: "Forest Green",  colorCode: "B12", group: .green, standardCode: "B12"),
        BeadColor(id: 22, hex: "C5E254", chineseName: "黄绿色",  englishName: "Yellow Green",  colorCode: "B29", group: .green, standardCode: "B29"),
        BeadColor(id: 23, hex: "4E846D", chineseName: "海绿色",  englishName: "Sea Green",     colorCode: "B25", group: .green, standardCode: "B25"),
        BeadColor(id: 24, hex: "ADE946", chineseName: "黄绿",    englishName: "Chartreuse",    colorCode: "B14", group: .green, standardCode: "B14"),

        // Blue family (MARD C-series)
        BeadColor(id: 25, hex: "3677D2", chineseName: "蓝色",    englishName: "Blue",          colorCode: "C7",  group: .blue, standardCode: "C7"),
        BeadColor(id: 26, hex: "34488E", chineseName: "深蓝色",  englishName: "Navy Blue",     colorCode: "C29", group: .blue, standardCode: "C29"),
        BeadColor(id: 27, hex: "7CC4FF", chineseName: "浅蓝色",  englishName: "Light Blue",    colorCode: "C24", group: .blue, standardCode: "C24"),
        BeadColor(id: 28, hex: "176DAF", chineseName: "道奇蓝",  englishName: "Dodger Blue",   colorCode: "C20", group: .blue, standardCode: "C20"),
        BeadColor(id: 29, hex: "50AAF0", chineseName: "天蓝色",  englishName: "Sky Blue",      colorCode: "C6",  group: .blue, standardCode: "C6"),
        BeadColor(id: 30, hex: "324BCA", chineseName: "皇家蓝",  englishName: "Royal Blue",    colorCode: "C9",  group: .blue, standardCode: "C9"),
        BeadColor(id: 31, hex: "1887A2", chineseName: "蓝绿色",  englishName: "Teal",          colorCode: "C19", group: .blue, standardCode: "C19"),
        BeadColor(id: 32, hex: "22C4C6", chineseName: "深青色",  englishName: "Dark Turquoise",colorCode: "C15", group: .blue, standardCode: "C15"),
        BeadColor(id: 63, hex: "3EBCE2", chineseName: "MARD C10", englishName: "MARD C10",     colorCode: "C10", group: .blue, standardCode: "C10"),
        BeadColor(id: 64, hex: "28DDDE", chineseName: "MARD C11", englishName: "MARD C11",     colorCode: "C11", group: .blue, standardCode: "C11"),
        BeadColor(id: 65, hex: "CDE8FF", chineseName: "MARD C13", englishName: "MARD C13",     colorCode: "C13", group: .blue, standardCode: "C13"),
        BeadColor(id: 66, hex: "D5FDFF", chineseName: "MARD C14", englishName: "MARD C14",     colorCode: "C14", group: .blue, standardCode: "C14"),
        BeadColor(id: 67, hex: "1557A8", chineseName: "MARD C16", englishName: "MARD C16",     colorCode: "C16", group: .blue, standardCode: "C16"),
        BeadColor(id: 68, hex: "04D1F6", chineseName: "MARD C17", englishName: "MARD C17",     colorCode: "C17", group: .blue, standardCode: "C17"),
        BeadColor(id: 69, hex: "BEDDFF", chineseName: "MARD C21", englishName: "MARD C21",     colorCode: "C21", group: .blue, standardCode: "C21"),
        BeadColor(id: 70, hex: "C8E2FF", chineseName: "MARD C23", englishName: "MARD C23",     colorCode: "C23", group: .blue, standardCode: "C23"),
        BeadColor(id: 71, hex: "3CAED8", chineseName: "MARD C26", englishName: "MARD C26",     colorCode: "C26", group: .blue, standardCode: "C26"),

        // Purple family (MARD D-series)
        BeadColor(id: 33, hex: "9C32B2", chineseName: "紫色",    englishName: "Purple",        colorCode: "D20", group: .purple, standardCode: "D20"),
        BeadColor(id: 34, hex: "A45EC7", chineseName: "紫罗兰",  englishName: "Violet",        colorCode: "D18", group: .purple, standardCode: "D18"),
        BeadColor(id: 35, hex: "DE9AD4", chineseName: "兰花紫",  englishName: "Orchid",        colorCode: "D12", group: .purple, standardCode: "D12"),
        BeadColor(id: 36, hex: "858EDD", chineseName: "中紫色",  englishName: "Medium Purple", colorCode: "D2",  group: .purple, standardCode: "D2"),
        BeadColor(id: 37, hex: "2F1F90", chineseName: "靛蓝色",  englishName: "Indigo",        colorCode: "D15", group: .purple, standardCode: "D15"),
        BeadColor(id: 38, hex: "8854B3", chineseName: "梅红色",  englishName: "Plum",          colorCode: "D7",  group: .purple, standardCode: "D7"),

        // Pink family (MARD E-series)
        BeadColor(id: 39, hex: "F551A2", chineseName: "粉色",    englishName: "Hot Pink",      colorCode: "E5",  group: .pink, standardCode: "E5"),
        BeadColor(id: 40, hex: "FFE2EA", chineseName: "浅粉色",  englishName: "Light Pink",    colorCode: "E17", group: .pink, standardCode: "E17"),
        BeadColor(id: 41, hex: "F13D74", chineseName: "深粉色",  englishName: "Deep Pink",     colorCode: "E6",  group: .pink, standardCode: "E6"),
        BeadColor(id: 42, hex: "FEBAD5", chineseName: "粉红色",  englishName: "Pink",          colorCode: "E19", group: .pink, standardCode: "E19"),
        BeadColor(id: 43, hex: "C63478", chineseName: "玫红色",  englishName: "Rose Red",      colorCode: "E7",  group: .pink, standardCode: "E7"),
        BeadColor(id: 72, hex: "FEBCC9", chineseName: "MARD E1", englishName: "MARD E1",      colorCode: "E1",  group: .pink, standardCode: "E1"),
        BeadColor(id: 73, hex: "FFE0EE", chineseName: "MARD E4", englishName: "MARD E4",      colorCode: "E4",  group: .pink, standardCode: "E4"),
        BeadColor(id: 74, hex: "FFDBE9", chineseName: "MARD E8", englishName: "MARD E8",      colorCode: "E8",  group: .pink, standardCode: "E8"),
        BeadColor(id: 75, hex: "FFE5EF", chineseName: "MARD E10", englishName: "MARD E10",    colorCode: "E10", group: .pink, standardCode: "E10"),
        BeadColor(id: 76, hex: "FCBFC0", chineseName: "MARD E12", englishName: "MARD E12",    colorCode: "E12", group: .pink, standardCode: "E12"),
        BeadColor(id: 77, hex: "FEC0EA", chineseName: "MARD E18", englishName: "MARD E18",    colorCode: "E18", group: .pink, standardCode: "E18"),
        BeadColor(id: 78, hex: "FFCADE", chineseName: "MARD E24", englishName: "MARD E24",    colorCode: "E24", group: .pink, standardCode: "E24"),

        // Brown family (MARD G/F-series)
        BeadColor(id: 44, hex: "78524B", chineseName: "棕色",    englishName: "Brown",         colorCode: "G17", group: .brown, standardCode: "G17"),
        BeadColor(id: 45, hex: "B7714A", chineseName: "赭色",    englishName: "Sienna",        colorCode: "G13", group: .brown, standardCode: "G13"),
        BeadColor(id: 46, hex: "8A4526", chineseName: "巧克力色",englishName: "Chocolate",     colorCode: "F10", group: .brown, standardCode: "F10"),
        BeadColor(id: 47, hex: "E0C593", chineseName: "实木色",  englishName: "Burlywood",     colorCode: "G11", group: .brown, standardCode: "G11"),
        BeadColor(id: 48, hex: "D98C39", chineseName: "秘鲁棕",  englishName: "Peru",          colorCode: "G10", group: .brown, standardCode: "G10"),
        BeadColor(id: 49, hex: "753832", chineseName: "深棕色",  englishName: "Dark Brown",    colorCode: "G8",  group: .brown, standardCode: "G8"),
        BeadColor(id: 79, hex: "FFE2CE", chineseName: "MARD G1",  englishName: "MARD G1",      colorCode: "G1",  group: .brown, standardCode: "G1"),
        BeadColor(id: 80, hex: "FFC4AA", chineseName: "MARD G2",  englishName: "MARD G2",      colorCode: "G2",  group: .brown, standardCode: "G2"),
        BeadColor(id: 81, hex: "E1B383", chineseName: "MARD G4",  englishName: "MARD G4",      colorCode: "G4",  group: .brown, standardCode: "G4"),
        BeadColor(id: 82, hex: "FFC890", chineseName: "MARD G12", englishName: "MARD G12",     colorCode: "G12", group: .brown, standardCode: "G12"),
        BeadColor(id: 83, hex: "8D614C", chineseName: "MARD G14", englishName: "MARD G14",     colorCode: "G14", group: .brown, standardCode: "G14"),
        BeadColor(id: 84, hex: "FFE4CC", chineseName: "MARD G18", englishName: "MARD G18",     colorCode: "G18", group: .brown, standardCode: "G18"),
        BeadColor(id: 85, hex: "E07935", chineseName: "MARD G19", englishName: "MARD G19",     colorCode: "G19", group: .brown, standardCode: "G19"),
        BeadColor(id: 86, hex: "A94023", chineseName: "MARD G20", englishName: "MARD G20",     colorCode: "G20", group: .brown, standardCode: "G20"),
        BeadColor(id: 87, hex: "B88558", chineseName: "MARD G21", englishName: "MARD G21",     colorCode: "G21", group: .brown, standardCode: "G21"),

        // Neutral family (MARD H-series)
        BeadColor(id: 50, hex: "FEFFFF", chineseName: "白色",    englishName: "White",         colorCode: "H2",  group: .neutral, standardCode: "H2"),
        BeadColor(id: 51, hex: "F1EDED", chineseName: "烟白色",  englishName: "White Smoke",   colorCode: "H17", group: .neutral, standardCode: "H17"),
        BeadColor(id: 52, hex: "CACAD4", chineseName: "浅灰色",  englishName: "Light Gray",    colorCode: "H22", group: .neutral, standardCode: "H22"),
        BeadColor(id: 53, hex: "949FA3", chineseName: "灰色",    englishName: "Gray",          colorCode: "H20", group: .neutral, standardCode: "H20"),
        BeadColor(id: 54, hex: "89858C", chineseName: "暗灰色",  englishName: "Dim Gray",      colorCode: "H4",  group: .neutral, standardCode: "H4"),
        BeadColor(id: 55, hex: "48464E", chineseName: "炭灰色",  englishName: "Charcoal",      colorCode: "H5",  group: .neutral, standardCode: "H5"),
        BeadColor(id: 56, hex: "000000", chineseName: "黑色",    englishName: "Black",         colorCode: "H7",  group: .neutral, standardCode: "H7"),
        BeadColor(id: 88, hex: "FDFBFF", chineseName: "MARD H1",  englishName: "MARD H1",      colorCode: "H1",  group: .neutral, standardCode: "H1"),
        BeadColor(id: 89, hex: "2F2B2F", chineseName: "MARD H6",  englishName: "MARD H6",      colorCode: "H6",  group: .neutral, standardCode: "H6"),
        BeadColor(id: 90, hex: "E7D6DB", chineseName: "MARD H8",  englishName: "MARD H8",      colorCode: "H8",  group: .neutral, standardCode: "H8"),
        BeadColor(id: 91, hex: "EDEDED", chineseName: "MARD H9",  englishName: "MARD H9",      colorCode: "H9",  group: .neutral, standardCode: "H9"),
        BeadColor(id: 92, hex: "EEE9EA", chineseName: "MARD H10", englishName: "MARD H10",     colorCode: "H10", group: .neutral, standardCode: "H10"),
        BeadColor(id: 93, hex: "CECDD5", chineseName: "MARD H11", englishName: "MARD H11",     colorCode: "H11", group: .neutral, standardCode: "H11"),
        BeadColor(id: 94, hex: "FFF5ED", chineseName: "MARD H12", englishName: "MARD H12",     colorCode: "H12", group: .neutral, standardCode: "H12"),
        BeadColor(id: 95, hex: "F5ECD2", chineseName: "MARD H13", englishName: "MARD H13",     colorCode: "H13", group: .neutral, standardCode: "H13"),
        BeadColor(id: 96, hex: "CFD7D3", chineseName: "MARD H14", englishName: "MARD H14",     colorCode: "H14", group: .neutral, standardCode: "H14"),
        BeadColor(id: 97, hex: "98A6A8", chineseName: "MARD H15", englishName: "MARD H15",     colorCode: "H15", group: .neutral, standardCode: "H15"),
        BeadColor(id: 98, hex: "1D1414", chineseName: "MARD H16", englishName: "MARD H16",     colorCode: "H16", group: .neutral, standardCode: "H16"),
        BeadColor(id: 99, hex: "FFFDF0", chineseName: "MARD H18", englishName: "MARD H18",     colorCode: "H18", group: .neutral, standardCode: "H18"),
        BeadColor(id: 100, hex: "F6EFE2", chineseName: "MARD H19", englishName: "MARD H19",    colorCode: "H19", group: .neutral, standardCode: "H19"),
        BeadColor(id: 101, hex: "FFFBE1", chineseName: "MARD H21", englishName: "MARD H21",    colorCode: "H21", group: .neutral, standardCode: "H21"),
        BeadColor(id: 102, hex: "9A9D94", chineseName: "MARD H23", englishName: "MARD H23",    colorCode: "H23", group: .neutral, standardCode: "H23"),
        BeadColor(id: 58, hex: "B6B1BA", chineseName: "银色",    englishName: "Silver",        colorCode: "H3",  group: .neutral, standardCode: "H3"),

        // Supplemental red/orange tones from the MARD chart
        BeadColor(id: 103, hex: "FD957B", chineseName: "MARD F1",  englishName: "MARD F1",     colorCode: "F1",  group: .red, standardCode: "F1"),
        BeadColor(id: 104, hex: "F74941", chineseName: "MARD F3",  englishName: "MARD F3",     colorCode: "F3",  group: .red, standardCode: "F3"),
        BeadColor(id: 105, hex: "FD4E6A", chineseName: "MARD F12", englishName: "MARD F12",    colorCode: "F12", group: .red, standardCode: "F12"),
        BeadColor(id: 106, hex: "D30022", chineseName: "MARD F15", englishName: "MARD F15",    colorCode: "F15", group: .red, standardCode: "F15"),
        BeadColor(id: 107, hex: "F7B4C6", chineseName: "MARD F21", englishName: "MARD F21",    colorCode: "F21", group: .red, standardCode: "F21"),
        BeadColor(id: 108, hex: "FDC0D0", chineseName: "MARD F22", englishName: "MARD F22",    colorCode: "F22", group: .red, standardCode: "F22"),

        // Pearl / pastel series from the MARD chart
        BeadColor(id: 109, hex: "BCC6B8", chineseName: "MARD M1",  englishName: "MARD M1",     colorCode: "M1",  group: .pearl, standardCode: "M1"),
        BeadColor(id: 110, hex: "8AA386", chineseName: "MARD M2",  englishName: "MARD M2",     colorCode: "M2",  group: .pearl, standardCode: "M2"),
        BeadColor(id: 111, hex: "E3D2BC", chineseName: "MARD M4",  englishName: "MARD M4",     colorCode: "M4",  group: .pearl, standardCode: "M4"),
        BeadColor(id: 112, hex: "C5B2BC", chineseName: "MARD M10", englishName: "MARD M10",    colorCode: "M10", group: .pearl, standardCode: "M10"),
        BeadColor(id: 113, hex: "FCF7F8", chineseName: "MARD P1",  englishName: "MARD P1",     colorCode: "P1",  group: .pearl, standardCode: "P1"),
        BeadColor(id: 114, hex: "AFDCAB", chineseName: "MARD P3",  englishName: "MARD P3",     colorCode: "P3",  group: .pearl, standardCode: "P3"),
        BeadColor(id: 115, hex: "D9C7EA", chineseName: "MARD P10", englishName: "MARD P10",    colorCode: "P10", group: .pearl, standardCode: "P10"),
        BeadColor(id: 116, hex: "F3ECC9", chineseName: "MARD P11", englishName: "MARD P11",    colorCode: "P11", group: .pearl, standardCode: "P11"),
        BeadColor(id: 117, hex: "E6EEF2", chineseName: "MARD P12", englishName: "MARD P12",    colorCode: "P12", group: .pearl, standardCode: "P12"),
        BeadColor(id: 118, hex: "AACBEF", chineseName: "MARD P13", englishName: "MARD P13",    colorCode: "P13", group: .pearl, standardCode: "P13"),
        BeadColor(id: 119, hex: "FEBF45", chineseName: "MARD P16", englishName: "MARD P16",    colorCode: "P16", group: .pearl, standardCode: "P16"),
        BeadColor(id: 120, hex: "FEA324", chineseName: "MARD P17", englishName: "MARD P17",    colorCode: "P17", group: .pearl, standardCode: "P17"),
        BeadColor(id: 121, hex: "FEBECF", chineseName: "MARD P20", englishName: "MARD P20",    colorCode: "P20", group: .pearl, standardCode: "P20"),

        // Remaining MARD colors from the full chart
        BeadColor(id: 122, hex: "FAF4C8", chineseName: "MARD A1", englishName: "MARD A1", colorCode: "A1", group: .yellow, standardCode: "A1"),
        BeadColor(id: 123, hex: "FFDD99", chineseName: "MARD A11", englishName: "MARD A11", colorCode: "A11", group: .yellow, standardCode: "A11"),
        BeadColor(id: 124, hex: "FE9F72", chineseName: "MARD A12", englishName: "MARD A12", colorCode: "A12", group: .yellow, standardCode: "A12"),
        BeadColor(id: 125, hex: "FFC365", chineseName: "MARD A13", englishName: "MARD A13", colorCode: "A13", group: .yellow, standardCode: "A13"),
        BeadColor(id: 126, hex: "FFFF9F", chineseName: "MARD A16", englishName: "MARD A16", colorCode: "A16", group: .yellow, standardCode: "A16"),
        BeadColor(id: 127, hex: "FFE36E", chineseName: "MARD A17", englishName: "MARD A17", colorCode: "A17", group: .yellow, standardCode: "A17"),
        BeadColor(id: 128, hex: "FD7C72", chineseName: "MARD A19", englishName: "MARD A19", colorCode: "A19", group: .yellow, standardCode: "A19"),
        BeadColor(id: 129, hex: "FFD568", chineseName: "MARD A20", englishName: "MARD A20", colorCode: "A20", group: .yellow, standardCode: "A20"),
        BeadColor(id: 130, hex: "FFE395", chineseName: "MARD A21", englishName: "MARD A21", colorCode: "A21", group: .yellow, standardCode: "A21"),
        BeadColor(id: 131, hex: "F4F57D", chineseName: "MARD A22", englishName: "MARD A22", colorCode: "A22", group: .yellow, standardCode: "A22"),
        BeadColor(id: 132, hex: "E6C9B7", chineseName: "MARD A23", englishName: "MARD A23", colorCode: "A23", group: .yellow, standardCode: "A23"),
        BeadColor(id: 133, hex: "F7F8A2", chineseName: "MARD A24", englishName: "MARD A24", colorCode: "A24", group: .yellow, standardCode: "A24"),
        BeadColor(id: 134, hex: "FFD67D", chineseName: "MARD A25", englishName: "MARD A25", colorCode: "A25", group: .yellow, standardCode: "A25"),
        BeadColor(id: 135, hex: "FEFF8B", chineseName: "MARD A3", englishName: "MARD A3", colorCode: "A3", group: .yellow, standardCode: "A3"),
        BeadColor(id: 136, hex: "FBED56", chineseName: "MARD A4", englishName: "MARD A4", colorCode: "A4", group: .yellow, standardCode: "A4"),
        BeadColor(id: 137, hex: "FEAC4C", chineseName: "MARD A6", englishName: "MARD A6", colorCode: "A6", group: .yellow, standardCode: "A6"),
        BeadColor(id: 138, hex: "FE8B4C", chineseName: "MARD A7", englishName: "MARD A7", colorCode: "A7", group: .yellow, standardCode: "A7"),
        BeadColor(id: 139, hex: "FFDA45", chineseName: "MARD A8", englishName: "MARD A8", colorCode: "A8", group: .yellow, standardCode: "A8"),
        BeadColor(id: 140, hex: "FF995B", chineseName: "MARD A9", englishName: "MARD A9", colorCode: "A9", group: .yellow, standardCode: "A9"),
        BeadColor(id: 141, hex: "E6EE31", chineseName: "MARD B1", englishName: "MARD B1", colorCode: "B1", group: .green, standardCode: "B1"),
        BeadColor(id: 142, hex: "95D3C2", chineseName: "MARD B10", englishName: "MARD B10", colorCode: "B10", group: .green, standardCode: "B10"),
        BeadColor(id: 143, hex: "5D722A", chineseName: "MARD B11", englishName: "MARD B11", colorCode: "B11", group: .green, standardCode: "B11"),
        BeadColor(id: 144, hex: "CAEB7B", chineseName: "MARD B13", englishName: "MARD B13", colorCode: "B13", group: .green, standardCode: "B13"),
        BeadColor(id: 145, hex: "C5ED9C", chineseName: "MARD B16", englishName: "MARD B16", colorCode: "B16", group: .green, standardCode: "B16"),
        BeadColor(id: 146, hex: "9BB13A", chineseName: "MARD B17", englishName: "MARD B17", colorCode: "B17", group: .green, standardCode: "B17"),
        BeadColor(id: 147, hex: "E6EE49", chineseName: "MARD B18", englishName: "MARD B18", colorCode: "B18", group: .green, standardCode: "B18"),
        BeadColor(id: 148, hex: "C2F0CC", chineseName: "MARD B20", englishName: "MARD B20", colorCode: "B20", group: .green, standardCode: "B20"),
        BeadColor(id: 149, hex: "156A6B", chineseName: "MARD B21", englishName: "MARD B21", colorCode: "B21", group: .green, standardCode: "B21"),
        BeadColor(id: 150, hex: "0B3C43", chineseName: "MARD B22", englishName: "MARD B22", colorCode: "B22", group: .green, standardCode: "B22"),
        BeadColor(id: 151, hex: "303A21", chineseName: "MARD B23", englishName: "MARD B23", colorCode: "B23", group: .green, standardCode: "B23"),
        BeadColor(id: 152, hex: "EEFCA5", chineseName: "MARD B24", englishName: "MARD B24", colorCode: "B24", group: .green, standardCode: "B24"),
        BeadColor(id: 153, hex: "8D7A35", chineseName: "MARD B26", englishName: "MARD B26", colorCode: "B26", group: .green, standardCode: "B26"),
        BeadColor(id: 154, hex: "CCE1AF", chineseName: "MARD B27", englishName: "MARD B27", colorCode: "B27", group: .green, standardCode: "B27"),
        BeadColor(id: 155, hex: "9EF780", chineseName: "MARD B3", englishName: "MARD B3", colorCode: "B3", group: .green, standardCode: "B3"),
        BeadColor(id: 156, hex: "E2FCB1", chineseName: "MARD B30", englishName: "MARD B30", colorCode: "B30", group: .green, standardCode: "B30"),
        BeadColor(id: 157, hex: "B0E792", chineseName: "MARD B31", englishName: "MARD B31", colorCode: "B31", group: .green, standardCode: "B31"),
        BeadColor(id: 158, hex: "9CAB5A", chineseName: "MARD B32", englishName: "MARD B32", colorCode: "B32", group: .green, standardCode: "B32"),
        BeadColor(id: 159, hex: "5DE035", chineseName: "MARD B4", englishName: "MARD B4", colorCode: "B4", group: .green, standardCode: "B4"),
        BeadColor(id: 160, hex: "35E352", chineseName: "MARD B5", englishName: "MARD B5", colorCode: "B5", group: .green, standardCode: "B5"),
        BeadColor(id: 161, hex: "65E2A6", chineseName: "MARD B6", englishName: "MARD B6", colorCode: "B6", group: .green, standardCode: "B6"),
        BeadColor(id: 162, hex: "3DAF80", chineseName: "MARD B7", englishName: "MARD B7", colorCode: "B7", group: .green, standardCode: "B7"),
        BeadColor(id: 163, hex: "27523A", chineseName: "MARD B9", englishName: "MARD B9", colorCode: "B9", group: .green, standardCode: "B9"),
        BeadColor(id: 164, hex: "E8FFE7", chineseName: "MARD C1", englishName: "MARD C1", colorCode: "C1", group: .blue, standardCode: "C1"),
        BeadColor(id: 165, hex: "1C334D", chineseName: "MARD C12", englishName: "MARD C12", colorCode: "C12", group: .blue, standardCode: "C12"),
        BeadColor(id: 166, hex: "1D3344", chineseName: "MARD C18", englishName: "MARD C18", colorCode: "C18", group: .blue, standardCode: "C18"),
        BeadColor(id: 167, hex: "A9F9FC", chineseName: "MARD C2", englishName: "MARD C2", colorCode: "C2", group: .blue, standardCode: "C2"),
        BeadColor(id: 168, hex: "67B4BE", chineseName: "MARD C22", englishName: "MARD C22", colorCode: "C22", group: .blue, standardCode: "C22"),
        BeadColor(id: 169, hex: "A9E5E5", chineseName: "MARD C25", englishName: "MARD C25", colorCode: "C25", group: .blue, standardCode: "C25"),
        BeadColor(id: 170, hex: "D3DFFA", chineseName: "MARD C27", englishName: "MARD C27", colorCode: "C27", group: .blue, standardCode: "C27"),
        BeadColor(id: 171, hex: "BBCFED", chineseName: "MARD C28", englishName: "MARD C28", colorCode: "C28", group: .blue, standardCode: "C28"),
        BeadColor(id: 172, hex: "A0E2FB", chineseName: "MARD C3", englishName: "MARD C3", colorCode: "C3", group: .blue, standardCode: "C3"),
        BeadColor(id: 173, hex: "41CCFF", chineseName: "MARD C4", englishName: "MARD C4", colorCode: "C4", group: .blue, standardCode: "C4"),
        BeadColor(id: 174, hex: "01ACEB", chineseName: "MARD C5", englishName: "MARD C5", colorCode: "C5", group: .blue, standardCode: "C5"),
        BeadColor(id: 175, hex: "0F54C0", chineseName: "MARD C8", englishName: "MARD C8", colorCode: "C8", group: .blue, standardCode: "C8"),
        BeadColor(id: 176, hex: "AEB4F2", chineseName: "MARD D1", englishName: "MARD D1", colorCode: "D1", group: .purple, standardCode: "D1"),
        BeadColor(id: 177, hex: "361851", chineseName: "MARD D10", englishName: "MARD D10", colorCode: "D10", group: .purple, standardCode: "D10"),
        BeadColor(id: 178, hex: "B9BAE1", chineseName: "MARD D11", englishName: "MARD D11", colorCode: "D11", group: .purple, standardCode: "D11"),
        BeadColor(id: 179, hex: "8B279B", chineseName: "MARD D14", englishName: "MARD D14", colorCode: "D14", group: .purple, standardCode: "D14"),
        BeadColor(id: 180, hex: "E3E1EE", chineseName: "MARD D16", englishName: "MARD D16", colorCode: "D16", group: .purple, standardCode: "D16"),
        BeadColor(id: 181, hex: "C4D4F6", chineseName: "MARD D17", englishName: "MARD D17", colorCode: "D17", group: .purple, standardCode: "D17"),
        BeadColor(id: 182, hex: "D8C3D7", chineseName: "MARD D19", englishName: "MARD D19", colorCode: "D19", group: .purple, standardCode: "D19"),
        BeadColor(id: 183, hex: "9A009B", chineseName: "MARD D21", englishName: "MARD D21", colorCode: "D21", group: .purple, standardCode: "D21"),
        BeadColor(id: 184, hex: "333A95", chineseName: "MARD D22", englishName: "MARD D22", colorCode: "D22", group: .purple, standardCode: "D22"),
        BeadColor(id: 185, hex: "EBDAFC", chineseName: "MARD D23", englishName: "MARD D23", colorCode: "D23", group: .purple, standardCode: "D23"),
        BeadColor(id: 186, hex: "7786E5", chineseName: "MARD D24", englishName: "MARD D24", colorCode: "D24", group: .purple, standardCode: "D24"),
        BeadColor(id: 187, hex: "494FC7", chineseName: "MARD D25", englishName: "MARD D25", colorCode: "D25", group: .purple, standardCode: "D25"),
        BeadColor(id: 188, hex: "DFC2F8", chineseName: "MARD D26", englishName: "MARD D26", colorCode: "D26", group: .purple, standardCode: "D26"),
        BeadColor(id: 189, hex: "2F54AF", chineseName: "MARD D3", englishName: "MARD D3", colorCode: "D3", group: .purple, standardCode: "D3"),
        BeadColor(id: 190, hex: "182A84", chineseName: "MARD D4", englishName: "MARD D4", colorCode: "D4", group: .purple, standardCode: "D4"),
        BeadColor(id: 191, hex: "B843C5", chineseName: "MARD D5", englishName: "MARD D5", colorCode: "D5", group: .purple, standardCode: "D5"),
        BeadColor(id: 192, hex: "AC7BDE", chineseName: "MARD D6", englishName: "MARD D6", colorCode: "D6", group: .purple, standardCode: "D6"),
        BeadColor(id: 193, hex: "E2D3FF", chineseName: "MARD D8", englishName: "MARD D8", colorCode: "D8", group: .purple, standardCode: "D8"),
        BeadColor(id: 194, hex: "D5B9F8", chineseName: "MARD D9", englishName: "MARD D9", colorCode: "D9", group: .purple, standardCode: "D9"),
        BeadColor(id: 195, hex: "FCDDD2", chineseName: "MARD E11", englishName: "MARD E11", colorCode: "E11", group: .pink, standardCode: "E11"),
        BeadColor(id: 196, hex: "B5006D", chineseName: "MARD E13", englishName: "MARD E13", colorCode: "E13", group: .pink, standardCode: "E13"),
        BeadColor(id: 197, hex: "FFD1BA", chineseName: "MARD E14", englishName: "MARD E14", colorCode: "E14", group: .pink, standardCode: "E14"),
        BeadColor(id: 198, hex: "F8C7C9", chineseName: "MARD E15", englishName: "MARD E15", colorCode: "E15", group: .pink, standardCode: "E15"),
        BeadColor(id: 199, hex: "FFF3EB", chineseName: "MARD E16", englishName: "MARD E16", colorCode: "E16", group: .pink, standardCode: "E16"),
        BeadColor(id: 200, hex: "FEC0DF", chineseName: "MARD E2", englishName: "MARD E2", colorCode: "E2", group: .pink, standardCode: "E2"),
        BeadColor(id: 201, hex: "D8C7D1", chineseName: "MARD E20", englishName: "MARD E20", colorCode: "E20", group: .pink, standardCode: "E20"),
        BeadColor(id: 202, hex: "BD9DA1", chineseName: "MARD E21", englishName: "MARD E21", colorCode: "E21", group: .pink, standardCode: "E21"),
        BeadColor(id: 203, hex: "B785A1", chineseName: "MARD E22", englishName: "MARD E22", colorCode: "E22", group: .pink, standardCode: "E22"),
        BeadColor(id: 204, hex: "937A8D", chineseName: "MARD E23", englishName: "MARD E23", colorCode: "E23", group: .pink, standardCode: "E23"),
        BeadColor(id: 205, hex: "FFB7E7", chineseName: "MARD E3", englishName: "MARD E3", colorCode: "E3", group: .pink, standardCode: "E3"),
        BeadColor(id: 206, hex: "E970CC", chineseName: "MARD E9", englishName: "MARD E9", colorCode: "E9", group: .pink, standardCode: "E9"),
        BeadColor(id: 207, hex: "FEC2A6", chineseName: "MARD F16", englishName: "MARD F16", colorCode: "F16", group: .red, standardCode: "F16"),
        BeadColor(id: 208, hex: "E69C79", chineseName: "MARD F17", englishName: "MARD F17", colorCode: "F17", group: .red, standardCode: "F17"),
        BeadColor(id: 209, hex: "D37C46", chineseName: "MARD F18", englishName: "MARD F18", colorCode: "F18", group: .red, standardCode: "F18"),
        BeadColor(id: 210, hex: "C1444A", chineseName: "MARD F19", englishName: "MARD F19", colorCode: "F19", group: .red, standardCode: "F19"),
        BeadColor(id: 211, hex: "CD9391", chineseName: "MARD F20", englishName: "MARD F20", colorCode: "F20", group: .red, standardCode: "F20"),
        BeadColor(id: 212, hex: "F67E66", chineseName: "MARD F23", englishName: "MARD F23", colorCode: "F23", group: .red, standardCode: "F23"),
        BeadColor(id: 213, hex: "E698AA", chineseName: "MARD F24", englishName: "MARD F24", colorCode: "F24", group: .red, standardCode: "F24"),
        BeadColor(id: 214, hex: "E54B4F", chineseName: "MARD F25", englishName: "MARD F25", colorCode: "F25", group: .red, standardCode: "F25"),
        BeadColor(id: 215, hex: "FC283C", chineseName: "MARD F4", englishName: "MARD F4", colorCode: "F4", group: .red, standardCode: "F4"),
        BeadColor(id: 216, hex: "943630", chineseName: "MARD F6", englishName: "MARD F6", colorCode: "F6", group: .red, standardCode: "F6"),
        BeadColor(id: 217, hex: "971937", chineseName: "MARD F7", englishName: "MARD F7", colorCode: "F7", group: .red, standardCode: "F7"),
        BeadColor(id: 218, hex: "BC0028", chineseName: "MARD F8", englishName: "MARD F8", colorCode: "F8", group: .red, standardCode: "F8"),
        BeadColor(id: 219, hex: "FCF9E0", chineseName: "MARD G15", englishName: "MARD G15", colorCode: "G15", group: .brown, standardCode: "G15"),
        BeadColor(id: 220, hex: "9D5B3E", chineseName: "MARD G7", englishName: "MARD G7", colorCode: "G7", group: .brown, standardCode: "G7"),
        BeadColor(id: 221, hex: "E6B483", chineseName: "MARD G9", englishName: "MARD G9", colorCode: "G9", group: .brown, standardCode: "G9"),
        BeadColor(id: 222, hex: "9F7594", chineseName: "MARD M11", englishName: "MARD M11", colorCode: "M11", group: .pearl, standardCode: "M11"),
        BeadColor(id: 223, hex: "644749", chineseName: "MARD M12", englishName: "MARD M12", colorCode: "M12", group: .pearl, standardCode: "M12"),
        BeadColor(id: 224, hex: "D19066", chineseName: "MARD M13", englishName: "MARD M13", colorCode: "M13", group: .pearl, standardCode: "M13"),
        BeadColor(id: 225, hex: "C77362", chineseName: "MARD M14", englishName: "MARD M14", colorCode: "M14", group: .pearl, standardCode: "M14"),
        BeadColor(id: 226, hex: "757D78", chineseName: "MARD M15", englishName: "MARD M15", colorCode: "M15", group: .pearl, standardCode: "M15"),
        BeadColor(id: 227, hex: "697D80", chineseName: "MARD M3", englishName: "MARD M3", colorCode: "M3", group: .pearl, standardCode: "M3"),
        BeadColor(id: 228, hex: "D0CCAA", chineseName: "MARD M5", englishName: "MARD M5", colorCode: "M5", group: .pearl, standardCode: "M5"),
        BeadColor(id: 229, hex: "B0A782", chineseName: "MARD M6", englishName: "MARD M6", colorCode: "M6", group: .pearl, standardCode: "M6"),
        BeadColor(id: 230, hex: "B4A497", chineseName: "MARD M7", englishName: "MARD M7", colorCode: "M7", group: .pearl, standardCode: "M7"),
        BeadColor(id: 231, hex: "B38281", chineseName: "MARD M8", englishName: "MARD M8", colorCode: "M8", group: .pearl, standardCode: "M8"),
        BeadColor(id: 232, hex: "A58767", chineseName: "MARD M9", englishName: "MARD M9", colorCode: "M9", group: .pearl, standardCode: "M9"),
        BeadColor(id: 233, hex: "337680", chineseName: "MARD P14", englishName: "MARD P14", colorCode: "P14", group: .pearl, standardCode: "P14"),
        BeadColor(id: 234, hex: "668575", chineseName: "MARD P15", englishName: "MARD P15", colorCode: "P15", group: .pearl, standardCode: "P15"),
        BeadColor(id: 235, hex: "FEB89F", chineseName: "MARD P18", englishName: "MARD P18", colorCode: "P18", group: .pearl, standardCode: "P18"),
        BeadColor(id: 236, hex: "FFFEEC", chineseName: "MARD P19", englishName: "MARD P19", colorCode: "P19", group: .pearl, standardCode: "P19"),
        BeadColor(id: 237, hex: "B0A9AC", chineseName: "MARD P2", englishName: "MARD P2", colorCode: "P2", group: .pearl, standardCode: "P2"),
        BeadColor(id: 238, hex: "ECBEBF", chineseName: "MARD P21", englishName: "MARD P21", colorCode: "P21", group: .pearl, standardCode: "P21"),
        BeadColor(id: 239, hex: "E4A89F", chineseName: "MARD P22", englishName: "MARD P22", colorCode: "P22", group: .pearl, standardCode: "P22"),
        BeadColor(id: 240, hex: "A56268", chineseName: "MARD P23", englishName: "MARD P23", colorCode: "P23", group: .pearl, standardCode: "P23"),
        BeadColor(id: 241, hex: "FEA49F", chineseName: "MARD P4", englishName: "MARD P4", colorCode: "P4", group: .pearl, standardCode: "P4"),
        BeadColor(id: 242, hex: "EE8C3E", chineseName: "MARD P5", englishName: "MARD P5", colorCode: "P5", group: .pearl, standardCode: "P5"),
        BeadColor(id: 243, hex: "5FD0A7", chineseName: "MARD P6", englishName: "MARD P6", colorCode: "P6", group: .pearl, standardCode: "P6"),
        BeadColor(id: 244, hex: "EB9270", chineseName: "MARD P7", englishName: "MARD P7", colorCode: "P7", group: .pearl, standardCode: "P7"),
        BeadColor(id: 245, hex: "F0D958", chineseName: "MARD P8", englishName: "MARD P8", colorCode: "P8", group: .pearl, standardCode: "P8"),
        BeadColor(id: 246, hex: "D9D9D9", chineseName: "MARD P9", englishName: "MARD P9", colorCode: "P9", group: .pearl, standardCode: "P9"),
        BeadColor(id: 247, hex: "F2A5E8", chineseName: "MARD Q1", englishName: "MARD Q1", colorCode: "Q1", group: .special, standardCode: "Q1"),
        BeadColor(id: 248, hex: "E9EC91", chineseName: "MARD Q2", englishName: "MARD Q2", colorCode: "Q2", group: .special, standardCode: "Q2"),
        BeadColor(id: 249, hex: "FFFF00", chineseName: "MARD Q3", englishName: "MARD Q3", colorCode: "Q3", group: .special, standardCode: "Q3"),
        BeadColor(id: 250, hex: "FFEBFA", chineseName: "MARD Q4", englishName: "MARD Q4", colorCode: "Q4", group: .special, standardCode: "Q4"),
        BeadColor(id: 251, hex: "76CEDE", chineseName: "MARD Q5", englishName: "MARD Q5", colorCode: "Q5", group: .special, standardCode: "Q5"),
        BeadColor(id: 252, hex: "D50D21", chineseName: "MARD R1", englishName: "MARD R1", colorCode: "R1", group: .special, standardCode: "R1"),
        BeadColor(id: 253, hex: "FFDB4C", chineseName: "MARD R10", englishName: "MARD R10", colorCode: "R10", group: .special, standardCode: "R10"),
        BeadColor(id: 254, hex: "FFEBFA", chineseName: "MARD R11", englishName: "MARD R11", colorCode: "R11", group: .special, standardCode: "R11"),
        BeadColor(id: 255, hex: "D8D5CE", chineseName: "MARD R12", englishName: "MARD R12", colorCode: "R12", group: .special, standardCode: "R12"),
        BeadColor(id: 256, hex: "55514C", chineseName: "MARD R13", englishName: "MARD R13", colorCode: "R13", group: .special, standardCode: "R13"),
        BeadColor(id: 257, hex: "9FE4DF", chineseName: "MARD R14", englishName: "MARD R14", colorCode: "R14", group: .special, standardCode: "R14"),
        BeadColor(id: 258, hex: "77CEE9", chineseName: "MARD R15", englishName: "MARD R15", colorCode: "R15", group: .special, standardCode: "R15"),
        BeadColor(id: 259, hex: "3ECFCA", chineseName: "MARD R16", englishName: "MARD R16", colorCode: "R16", group: .special, standardCode: "R16"),
        BeadColor(id: 260, hex: "4A867A", chineseName: "MARD R17", englishName: "MARD R17", colorCode: "R17", group: .special, standardCode: "R17"),
        BeadColor(id: 261, hex: "7FCD9D", chineseName: "MARD R18", englishName: "MARD R18", colorCode: "R18", group: .special, standardCode: "R18"),
        BeadColor(id: 262, hex: "CDE55D", chineseName: "MARD R19", englishName: "MARD R19", colorCode: "R19", group: .special, standardCode: "R19"),
        BeadColor(id: 263, hex: "F92F83", chineseName: "MARD R2", englishName: "MARD R2", colorCode: "R2", group: .special, standardCode: "R2"),
        BeadColor(id: 264, hex: "E8C7B4", chineseName: "MARD R20", englishName: "MARD R20", colorCode: "R20", group: .special, standardCode: "R20"),
        BeadColor(id: 265, hex: "AD6F3C", chineseName: "MARD R21", englishName: "MARD R21", colorCode: "R21", group: .special, standardCode: "R21"),
        BeadColor(id: 266, hex: "6C372F", chineseName: "MARD R22", englishName: "MARD R22", colorCode: "R22", group: .special, standardCode: "R22"),
        BeadColor(id: 267, hex: "FEB872", chineseName: "MARD R23", englishName: "MARD R23", colorCode: "R23", group: .special, standardCode: "R23"),
        BeadColor(id: 268, hex: "F3C1C0", chineseName: "MARD R24", englishName: "MARD R24", colorCode: "R24", group: .special, standardCode: "R24"),
        BeadColor(id: 269, hex: "C9675E", chineseName: "MARD R25", englishName: "MARD R25", colorCode: "R25", group: .special, standardCode: "R25"),
        BeadColor(id: 270, hex: "D293BE", chineseName: "MARD R26", englishName: "MARD R26", colorCode: "R26", group: .special, standardCode: "R26"),
        BeadColor(id: 271, hex: "EA8CB1", chineseName: "MARD R27", englishName: "MARD R27", colorCode: "R27", group: .special, standardCode: "R27"),
        BeadColor(id: 272, hex: "9C87D6", chineseName: "MARD R28", englishName: "MARD R28", colorCode: "R28", group: .special, standardCode: "R28"),
        BeadColor(id: 273, hex: "FD8324", chineseName: "MARD R3", englishName: "MARD R3", colorCode: "R3", group: .special, standardCode: "R3"),
        BeadColor(id: 274, hex: "F8EC31", chineseName: "MARD R4", englishName: "MARD R4", colorCode: "R4", group: .special, standardCode: "R4"),
        BeadColor(id: 275, hex: "35C75B", chineseName: "MARD R5", englishName: "MARD R5", colorCode: "R5", group: .special, standardCode: "R5"),
        BeadColor(id: 276, hex: "238891", chineseName: "MARD R6", englishName: "MARD R6", colorCode: "R6", group: .special, standardCode: "R6"),
        BeadColor(id: 277, hex: "19779D", chineseName: "MARD R7", englishName: "MARD R7", colorCode: "R7", group: .special, standardCode: "R7"),
        BeadColor(id: 278, hex: "1A60C3", chineseName: "MARD R8", englishName: "MARD R8", colorCode: "R8", group: .special, standardCode: "R8"),
        BeadColor(id: 279, hex: "9A56B4", chineseName: "MARD R9", englishName: "MARD R9", colorCode: "R9", group: .special, standardCode: "R9"),
        BeadColor(id: 280, hex: "FFFFFF", chineseName: "MARD T1", englishName: "MARD T1", colorCode: "T1", group: .special, standardCode: "T1"),
        BeadColor(id: 281, hex: "FD6FB4", chineseName: "MARD Y1", englishName: "MARD Y1", colorCode: "Y1", group: .special, standardCode: "Y1"),
        BeadColor(id: 282, hex: "FEB481", chineseName: "MARD Y2", englishName: "MARD Y2", colorCode: "Y2", group: .special, standardCode: "Y2"),
        BeadColor(id: 283, hex: "D7FAA0", chineseName: "MARD Y3", englishName: "MARD Y3", colorCode: "Y3", group: .special, standardCode: "Y3"),
        BeadColor(id: 284, hex: "8BDBFA", chineseName: "MARD Y4", englishName: "MARD Y4", colorCode: "Y4", group: .special, standardCode: "Y4"),
        BeadColor(id: 285, hex: "E987EA", chineseName: "MARD Y5", englishName: "MARD Y5", colorCode: "Y5", group: .special, standardCode: "Y5"),

        // ZG series (MARD chart)
        BeadColor(id: 286, hex: "DAABB3", chineseName: "MARD ZG1", englishName: "MARD ZG1", colorCode: "ZG1", group: .special, standardCode: "ZG1"),
        BeadColor(id: 287, hex: "D6AA87", chineseName: "MARD ZG2", englishName: "MARD ZG2", colorCode: "ZG2", group: .special, standardCode: "ZG2"),
        BeadColor(id: 288, hex: "C1BD8D", chineseName: "MARD ZG3", englishName: "MARD ZG3", colorCode: "ZG3", group: .special, standardCode: "ZG3"),
        BeadColor(id: 289, hex: "96869F", chineseName: "MARD ZG4", englishName: "MARD ZG4", colorCode: "ZG4", group: .special, standardCode: "ZG4"),
        BeadColor(id: 290, hex: "8490A6", chineseName: "MARD ZG5", englishName: "MARD ZG5", colorCode: "ZG5", group: .special, standardCode: "ZG5"),
        BeadColor(id: 291, hex: "94BFE2", chineseName: "MARD ZG6", englishName: "MARD ZG6", colorCode: "ZG6", group: .special, standardCode: "ZG6"),
        BeadColor(id: 292, hex: "E2A9D2", chineseName: "MARD ZG7", englishName: "MARD ZG7", colorCode: "ZG7", group: .special, standardCode: "ZG7"),
        BeadColor(id: 293, hex: "AB91C0", chineseName: "MARD ZG8", englishName: "MARD ZG8", colorCode: "ZG8", group: .special, standardCode: "ZG8"),

        // Special family (picked directly from MARD chart)
        BeadColor(id: 57, hex: "FFC830", chineseName: "金色",    englishName: "Gold",          colorCode: "A26", group: .special, standardCode: "A26"),
        BeadColor(id: 59, hex: "B90095", chineseName: "品红色",  englishName: "Magenta",       colorCode: "D13", group: .special, standardCode: "D13"),
        BeadColor(id: 61, hex: "24B88C", chineseName: "亮海绿",  englishName: "Light Sea Green",colorCode: "B19", group: .special, standardCode: "B19"),
    ]

    private static let colorMap: [Int: BeadColor] = {
        Dictionary(uniqueKeysWithValues: colors.map { ($0.id, $0) })
    }()

    private static let standardCodeMap: [String: BeadColor] = {
        Dictionary(uniqueKeysWithValues: colors.map { (($0.standardCode ?? $0.colorCode).uppercased(), $0) })
    }()

    static func color(id: Int) -> BeadColor? {
        colorMap[id]
    }

    static func color(standardCode: String) -> BeadColor? {
        standardCodeMap[standardCode.uppercased()]
    }

    static func colors(in group: ColorGroup) -> [BeadColor] {
        colors
            .filter { $0.group == group }
            .sorted(by: sortForDisplay)
    }

    static func nearestColorId(red: UInt8, green: UInt8, blue: UInt8) -> Int {
        var bestColorId = colors.first?.id ?? 0
        var smallestDistance = Double.greatestFiniteMagnitude

        for bead in colors {
            let rgb = rgbComponents(for: bead.uiColor)
            let redDelta = Double(Int(red) - Int(rgb.red))
            let greenDelta = Double(Int(green) - Int(rgb.green))
            let blueDelta = Double(Int(blue) - Int(rgb.blue))
            let distance = (redDelta * redDelta * 0.30) + (greenDelta * greenDelta * 0.59) + (blueDelta * blueDelta * 0.11)

            if distance < smallestDistance {
                smallestDistance = distance
                bestColorId = bead.id
            }
        }

        return bestColorId
    }

    private static func sortForDisplay(_ lhs: BeadColor, _ rhs: BeadColor) -> Bool {
        let left = splitCode(lhs.standardCode ?? lhs.colorCode)
        let right = splitCode(rhs.standardCode ?? rhs.colorCode)
        if left.prefix != right.prefix {
            return left.prefix < right.prefix
        }
        if left.number != right.number {
            return left.number < right.number
        }
        return lhs.id < rhs.id
    }

    private static func splitCode(_ code: String) -> (prefix: String, number: Int) {
        let prefix = String(code.prefix { $0.isLetter })
        let number = Int(code.drop { $0.isLetter }) ?? 0
        return (prefix, number)
    }

    private static func rgbComponents(for color: UIColor) -> (red: UInt8, green: UInt8, blue: UInt8) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (
                red: UInt8((red * 255).rounded()),
                green: UInt8((green * 255).rounded()),
                blue: UInt8((blue * 255).rounded())
            )
        }

        var white: CGFloat = 0
        if color.getWhite(&white, alpha: &alpha) {
            let value = UInt8((white * 255).rounded())
            return (red: value, green: value, blue: value)
        }

        return (red: 0, green: 0, blue: 0)
    }
}
