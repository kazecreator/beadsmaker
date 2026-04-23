import SwiftUI

struct PatternCardView: View {
    let name: String
    let width: Int
    let height: Int
    let thumbnailData: Data?
    let isCollected: Bool
    var subtitle: String? = nil
    var badgeText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color(.systemFill)
                if let data = thumbnailData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if let badgeText {
                        Text(badgeText)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.14))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text("\(width) × \(height)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
