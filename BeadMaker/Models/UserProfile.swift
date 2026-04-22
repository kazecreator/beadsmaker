import SwiftData
import UIKit

@Model
final class UserProfile {
    var nickname: String
    var avatarType: String      // "preset" | "pattern"
    var presetAvatarIndex: Int
    var customAvatarData: Data? // PNG of selected avatar (from pattern thumbnail)
    var githubToken: String?

    init() {
        self.nickname = "拼豆玩家"
        self.avatarType = "preset"
        self.presetAvatarIndex = 0
        self.githubToken = nil
    }

    var isPreset: Bool { avatarType == "preset" }

    var trimmedGitHubToken: String? {
        guard let token = githubToken?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
            return nil
        }
        return token
    }

    var avatarImage: UIImage? {
        if avatarType == "pattern", let data = customAvatarData {
            return UIImage(data: data)
        }
        let idx = min(presetAvatarIndex, PixelAvatarLibrary.avatars.count - 1)
        return PixelAvatarLibrary.avatars[max(0, idx)].render(pixelSize: 8)
    }
}
