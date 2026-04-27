import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

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
                            .foregroundStyle(PixelBeadsTheme.ink)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Privacy Policy"))
            .navigationBarTitleDisplayMode(.inline)
            .background(PixelBeadsTheme.surface)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("Done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
