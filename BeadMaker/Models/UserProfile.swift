import SwiftData
import UIKit

@Model
final class UserProfile {
    var nickname: String
    var avatarType: String      // "preset" | "pattern"
    var presetAvatarIndex: Int
    var customAvatarData: Data? // PNG of selected avatar (from pattern thumbnail)

    init() {
        self.nickname = "拼豆玩家"
        self.avatarType = "preset"
        self.presetAvatarIndex = 0
    }

    var isPreset: Bool { avatarType == "preset" }

    var avatarImage: UIImage? {
        if avatarType == "pattern", let data = customAvatarData {
            return UIImage(data: data)
        }
        let idx = min(presetAvatarIndex, PixelAvatarLibrary.avatars.count - 1)
        return PixelAvatarLibrary.avatars[max(0, idx)].render(pixelSize: 8)
    }
}
