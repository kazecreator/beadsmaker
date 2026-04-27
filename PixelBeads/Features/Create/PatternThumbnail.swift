import SwiftUI

struct PatternThumbnail: View {
    let pattern: Pattern
    let mode: PreviewMode
    var height: CGFloat

    var body: some View {
        Group {
            if let thumbnailURL = pattern.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    default:
                        fallbackThumbnail
                    }
                }
            } else {
                fallbackThumbnail
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous)
                .stroke(PixelBeadsTheme.outline, lineWidth: 1)
        )
    }

    private var fallbackThumbnail: some View {
        let image = PatternImageRenderer.image(for: pattern, mode: mode)
        return Image(uiImage: image)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}
