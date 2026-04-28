import SwiftUI

/// A simple sheet for editing the user's display name.
struct EditNameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var sessionStore: AppSessionStore

    @State private var displayName: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.tr("Display Name"))
                            .font(.headline)

                        TextField(L10n.tr("Pixel Maker"), text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()

                        Text(L10n.tr("Displays on published patterns"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .pbCard()

                    Button {
                        sessionStore.updateDisplayName(displayName)
                        dismiss()
                    } label: {
                        Label(L10n.tr("Save"), systemImage: "checkmark")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 0)
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Edit Name"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("Cancel")) { dismiss() }
                }
            }
            .onAppear {
                displayName = sessionStore.currentUser.displayName
            }
            .pbScreen()
        }
        .presentationDetents([.medium])
    }
}
