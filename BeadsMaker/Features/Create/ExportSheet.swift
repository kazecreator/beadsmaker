import SwiftUI
import UIKit

struct ExportSheet: View {
    let pattern: Pattern

    @Environment(\.dismiss) private var dismiss
    @State private var saveStatus: PhotoSaveStatus?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Image(uiImage: PatternImageRenderer.finishedImage(for: pattern, cellSize: 18, scale: 1))
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous)
                            .stroke(BeadsMakerTheme.outline, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.tr("Finished PNG"))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(BeadsMakerTheme.ink)
                    Text(L10n.tr("Save the finished piece as a PNG directly to Photos."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    PhotoLibrarySaver.saveFinishedPNG(pattern: pattern) { status in
                        saveStatus = status
                    }
                } label: {
                    Label(L10n.tr("Save Finished PNG"), systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer(minLength: 0)
            }
            .padding(16)
            .navigationTitle(L10n.tr("Export PNG"))
            .navigationBarTitleDisplayMode(.inline)
            .pbScreen()
        }
        .alert(saveStatus?.title ?? "", isPresented: Binding(
            get: { saveStatus != nil },
            set: { if !$0 { saveStatus = nil } }
        )) {
            Button(L10n.tr("OK"), role: .cancel) {
                if saveStatus == .saved {
                    dismiss()
                }
                saveStatus = nil
            }
        } message: {
            Text(saveStatus?.message ?? "")
        }
    }
}

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
