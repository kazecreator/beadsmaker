import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private var privacyURL: URL {
        let lang = Locale.preferredLanguages.first ?? ""
        let path = lang.starts(with: "zh") ? "privacy-zh" : "privacy"
        return URL(string: "https://kazecreator.github.io/pixelbeads/\(path).html")!
    }

    private var paragraphs: [String] {
        L10n.tr("Privacy Policy Body")
            .components(separatedBy: "\n\n")
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(.body)
                            .foregroundStyle(BeadsMakerTheme.ink)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(16)

                Link(destination: privacyURL) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                            .font(.subheadline)
                        Text("View Online")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(BeadsMakerTheme.ink)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(BeadsMakerTheme.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.button, style: .continuous))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle(L10n.tr("Privacy Policy"))
            .navigationBarTitleDisplayMode(.inline)
            .background(BeadsMakerTheme.surface)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("Done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.large, .medium])
    }
}
