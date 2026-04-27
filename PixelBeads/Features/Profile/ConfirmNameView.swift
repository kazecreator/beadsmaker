import SwiftUI

/// Shown immediately after Apple Sign In completes.
/// Lets the user confirm or edit the display name for account-backed features.
struct ConfirmNameView: View {
    @ObservedObject var sessionStore: AppSessionStore
    let appleSignInResult: AppleSignInResult
    let onComplete: () -> Void

    @EnvironmentObject private var appleSignInManager: AppleSignInManager
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    nameCard
                    if let error = saveError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(PixelBeadsTheme.coral)
                            .padding(.horizontal, 4)
                    }
                    saveCard
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Your Creator Name"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.tr("Skip")) {
                        finalize()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .pbScreen()
        }
        .onAppear {
            // Pre-fill from Apple; fall back to current display name.
            displayName = appleSignInResult.displayName ?? sessionStore.currentUser.displayName
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 40))
                .foregroundStyle(PixelBeadsTheme.coral)
                .padding(.top, 4)
            Text(L10n.tr("Welcome, Pro Creator!"))
                .font(.title2.bold())
                .foregroundStyle(PixelBeadsTheme.ink)
            Text(L10n.tr("This name will appear on patterns you publish to the community."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .pbCard()
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("Display Name"))
                .font(.headline)
                .foregroundStyle(PixelBeadsTheme.ink)
            TextField(L10n.tr("Your name"), text: $displayName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.body)
                .padding(12)
                .background(PixelBeadsTheme.canvas)
                .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.button, style: .continuous)
                        .stroke(PixelBeadsTheme.outline, lineWidth: 1)
                )
        }
        .pbCard()
    }

    private var saveCard: some View {
        Button {
            Task { await save() }
        } label: {
            if isSaving {
                ProgressView().frame(maxWidth: .infinity)
            } else {
                Label(L10n.tr("Save and Continue"), systemImage: "checkmark")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .pbCard()
    }

    // MARK: - Actions

    private func save() async {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        saveError = nil
        defer { isSaving = false }

        if AppFeatureFlags.backendEnabled {
            do {
                try await appleSignInManager.upsertProfile(
                    appleUserID: appleSignInResult.appleUserID,
                    displayName: trimmed
                )
            } catch {
                // Non-fatal: local state still reflects the Pro purchase.
                saveError = error.localizedDescription
            }
        }

        // Update local session regardless of Supabase outcome.
        sessionStore.linkAppleAccount(
            appleUserID: appleSignInResult.appleUserID,
            displayName: trimmed
        )
        finalize()
    }

    private func finalize() {
        onComplete()
    }
}
