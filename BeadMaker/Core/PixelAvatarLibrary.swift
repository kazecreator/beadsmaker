import UIKit

struct PixelAvatar: Identifiable {
    let id: Int
    let name: String
    let grid: [Int]  // 8×8 = 64 elements, BeadColor IDs (0 = empty/white)

    func render(pixelSize: CGFloat = 8) -> UIImage {
        let side = 8.0 * pixelSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            UIColor.white.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: side, height: side))
            for row in 0..<8 {
                for col in 0..<8 {
                    let idx = row * 8 + col
                    guard idx < grid.count, grid[idx] != 0 else { continue }
                    guard let bead = BeadColorLibrary.color(id: grid[idx]) else { continue }
                    let rect = CGRect(x: CGFloat(col) * pixelSize, y: CGFloat(row) * pixelSize,
                                     width: pixelSize, height: pixelSize)
                    bead.uiColor.setFill()
                    cg.fill(rect)
                }
            }
        }
    }
}

enum PixelAvatarLibrary {
    static let avatars: [PixelAvatar] = [smile, heart, star, flower, mushroom, cat, diamond, robot]

    // Color IDs from BeadColorLibrary:
    // 0=empty  1=red  8=orange  12=yellow  25=blue  27=lightBlue
    // 41=pink  49=burlywood  53=white  55=lightGray  56=gray  59=black  60=gold

    static let smile = PixelAvatar(id: 0, name: "笑脸", grid: [
         0,12,12,12,12,12,12, 0,
        12,12,12,12,12,12,12,12,
        12,12,59,12,12,59,12,12,
        12,12,12,12,12,12,12,12,
        12,59,12,12,12,12,59,12,
        12,12,59,59,59,59,12,12,
        12,12,12,12,12,12,12,12,
         0,12,12,12,12,12,12, 0,
    ])

    static let heart = PixelAvatar(id: 1, name: "爱心", grid: [
         0, 1, 1, 0, 0, 1, 1, 0,
         1, 1, 1, 1, 1, 1, 1, 1,
         1, 1, 1, 1, 1, 1, 1, 1,
         1, 1, 1, 1, 1, 1, 1, 1,
         0, 1, 1, 1, 1, 1, 1, 0,
         0, 0, 1, 1, 1, 1, 0, 0,
         0, 0, 0, 1, 1, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 0,
    ])

    static let star = PixelAvatar(id: 2, name: "星星", grid: [
         0, 0, 0,12, 0, 0, 0, 0,
         0, 0, 0,12, 0, 0, 0, 0,
        12,12,12,12,12,12,12, 0,
         0, 0,12,12,12, 0, 0, 0,
         0, 0,12, 0,12, 0, 0, 0,
         0,12, 0, 0, 0,12, 0, 0,
        12, 0, 0, 0, 0, 0,12, 0,
         0, 0, 0, 0, 0, 0, 0, 0,
    ])

    static let flower = PixelAvatar(id: 3, name: "花朵", grid: [
         0, 0,41, 0,41, 0, 0, 0,
         0,41,41,41,41,41, 0, 0,
        41,41,12,12,12,41,41, 0,
         0,41,12,12,12,41, 0, 0,
        41,41,12,12,12,41,41, 0,
         0,41,41,41,41,41, 0, 0,
         0, 0,41, 0,41, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 0,
    ])

    static let mushroom = PixelAvatar(id: 4, name: "蘑菇", grid: [
         0, 0, 1, 1, 1, 1, 0, 0,
         0, 1, 1,53, 1, 1, 1, 0,
         1, 1, 1, 1, 1,53, 1, 1,
         1, 1, 1, 1, 1, 1, 1, 1,
         0, 0,49,49,49,49, 0, 0,
         0, 0,49,49,49,49, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 0,
    ])

    static let cat = PixelAvatar(id: 5, name: "小猫", grid: [
         8, 0, 0, 0, 0, 0, 0, 8,
         8, 8, 0, 0, 0, 0, 8, 8,
         0, 8, 8, 8, 8, 8, 8, 0,
         0, 8,59, 8, 8,59, 8, 0,
         0, 8, 8, 8, 8, 8, 8, 0,
         0, 8, 8,41, 8, 8, 8, 0,
         0, 8, 8, 8, 8, 8, 8, 0,
         0, 0, 8, 8, 8, 8, 0, 0,
    ])

    static let diamond = PixelAvatar(id: 6, name: "钻石", grid: [
         0, 0, 0,25, 0, 0, 0, 0,
         0, 0,25,27,25, 0, 0, 0,
         0,25,27,25,27,25, 0, 0,
        25,27,25,27,25,27,25, 0,
         0,25,27,25,27,25, 0, 0,
         0, 0,25,27,25, 0, 0, 0,
         0, 0, 0,25, 0, 0, 0, 0,
         0, 0, 0, 0, 0, 0, 0, 0,
    ])

    static let robot = PixelAvatar(id: 7, name: "机器人", grid: [
         0, 0,60, 0, 0,60, 0, 0,
         0, 0,55,55,55,55, 0, 0,
        56,56,56,56,56,56,56, 0,
        56,55,25,55,55,25,55, 0,
        56,55,55,55,55,55,55, 0,
        56,55,59,59,59,59,55, 0,
        56,56,56,56,56,56,56, 0,
         0, 0, 0, 0, 0, 0, 0, 0,
    ])
}
