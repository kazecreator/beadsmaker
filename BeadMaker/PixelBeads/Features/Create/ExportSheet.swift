import SwiftUI
import UIKit

struct ExportSheet: View {
    let pattern: Pattern

    @State private var selectedShareItem: ShareItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PBSectionHeader(
                        title: "Export",
                        subtitle: "Share crisp PNG renders for digital posting or real-world beading."
                    )

                    ForEach(ExportOption.allCases) { option in
                        Button {
                            let image = PatternImageRenderer.image(for: pattern, mode: option.mode, scale: 2)
                            selectedShareItem = ShareItem(
                                title: option.title,
                                image: image,
                                data: image.pngData() ?? Data()
                            )
                        } label: {
                            HStack(spacing: 14) {
                                Image(uiImage: PatternImageRenderer.image(for: pattern, mode: option.mode, scale: 1))
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .frame(width: 88, height: 88)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(option.title)
                                        .font(.headline)
                                        .foregroundStyle(PixelBeadsTheme.ink)
                                    Text(description(for: option))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(PixelBeadsTheme.coral)
                            }
                            .padding(14)
                            .background(PixelBeadsTheme.canvas)
                            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                                    .stroke(PixelBeadsTheme.outline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Export PNG")
            .navigationBarTitleDisplayMode(.inline)
            .pbScreen()
        }
        .sheet(item: $selectedShareItem) { item in
            ShareActivityView(activityItems: [item.data])
        }
    }

    private func description(for option: ExportOption) -> String {
        switch option {
        case .pixelPNG:
            return "Sharp block-by-block render for posting the source design."
        case .beadPNG:
            return "Round bead render that matches the crafting look."
        case .comparisonPNG:
            return "Side-by-side render showing both pixel and bead styles."
        }
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let title: String
    let image: UIImage
    let data: Data
}

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
