import SwiftUI

enum BeadsMakerTheme {
    static let ink = Color(hex: "#111111")
    static let canvas = Color.white
    static let surface = Color(hex: "#F5F5F5")
    static let coral = Color(hex: "#FF5A36")
    static let muted = Color.black.opacity(0.08)
    static let outline = Color.black.opacity(0.12)
    static let shadow = Color.black.opacity(0.06)

    enum Radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 14
        static let chip: CGFloat = 12
        static let small: CGFloat = 8
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

struct PBCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(BeadsMakerTheme.canvas)
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous)
                    .stroke(BeadsMakerTheme.outline, lineWidth: 1)
            )
            .shadow(color: BeadsMakerTheme.shadow, radius: 16, y: 8)
    }
}

extension View {
    func pbCard() -> some View {
        modifier(PBCardModifier())
    }

    func pbScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(BeadsMakerTheme.surface.ignoresSafeArea())
            .preferredColorScheme(.light)
            .toolbarBackground(BeadsMakerTheme.surface, for: .navigationBar)
            .toolbarBackground(BeadsMakerTheme.surface, for: .tabBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.visible, for: .tabBar)
            .tint(BeadsMakerTheme.ink)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(BeadsMakerTheme.ink.opacity(configuration.isPressed ? 0.86 : 1))
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.button, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(BeadsMakerTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(BeadsMakerTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.button, style: .continuous)
                    .stroke(BeadsMakerTheme.outline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct PBChip: View {
    let title: String
    var accent: Bool = false

    var body: some View {
        Text(L10n.tr(title))
            .font(.caption.weight(.semibold))
            .foregroundStyle(BeadsMakerTheme.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accent ? BeadsMakerTheme.muted : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.chip, style: .continuous)
                    .stroke(accent ? BeadsMakerTheme.outline : BeadsMakerTheme.outline, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.chip, style: .continuous))
    }
}

struct PBSectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tr(title))
                .font(.title3.weight(.bold))
                .foregroundStyle(BeadsMakerTheme.ink)
            if let subtitle {
                Text(L10n.tr(subtitle))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PBAvatarView: View {
    let image: Image
    var size: CGFloat = 56

    var body: some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous)
                    .stroke(BeadsMakerTheme.outline, lineWidth: 1)
            )
    }
}
