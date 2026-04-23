import SwiftUI
import SwiftData

struct FavoriteDetailView: View {
    let favorite: CollectedPattern

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationModel: GalleryNavigationModel

    var body: some View {
        ZStack {
            FinishedPresentationBackground()

            VStack(spacing: 0) {
                FinishedPresentationCard(
                    width: favorite.width,
                    height: favorite.height,
                    gridData: favorite.gridData
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

        }
        .navigationTitle(favorite.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    navigationModel.openPatternViewer(
                        title: favorite.name,
                        width: favorite.width,
                        height: favorite.height,
                        gridData: favorite.gridData
                    )
                } label: {
                    Image(systemName: "eye")
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }
}
