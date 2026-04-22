import SwiftUI
import SwiftData

struct EditorView: View {
    let patternID: PersistentIdentifier

    var body: some View {
        BeadEditorView(patternID: patternID)
    }
}
