import SwiftUI
import UIKit

enum ColorGroup: String, CaseIterable, Codable {
    case red = "红色系"
    case orange = "橙色系"
    case yellow = "黄色系"
    case green = "绿色系"
    case blue = "蓝色系"
    case purple = "紫色系"
    case pink = "粉色系"
    case brown = "棕色系"
    case neutral = "黑白灰"
    case pearl = "珠光/粉彩"
    case special = "特殊色"
}

struct BeadColor: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let hex: String
    let chineseName: String
    let englishName: String
    let colorCode: String
    let group: ColorGroup
    
    // MARD palette code shown in the UI/export views.
    let standardCode: String?

    var color: Color { Color(hex: hex) }
    var uiColor: UIColor { UIColor(hex: hex) }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
