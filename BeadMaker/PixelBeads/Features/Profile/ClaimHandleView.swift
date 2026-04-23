import SwiftUI

struct ClaimHandleView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var sessionStore: AppSessionStore

    @State private var displayName: String = ""
    @State private var publicHandle: String = ""
    @State private var didMockSignIn = false

    private var availabilityState: HandleAvailabilityState {
        let normalized = publicHandle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return .idle }
        guard normalized.count >= 3 else { return .tooShort }
        return sessionStore.isHandleAvailable(normalized) ? .available : .taken
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PBSectionHeader(
                        title: sessionStore.currentUser.isClaimed ? "Edit Profile" : "Claim Your Handle",
                        subtitle: "Display names stay flexible. Public handles are unique and only required for publishing."
                    )

                    signInCard
                    identityCard
                    availabilityCard
                    actionsCard
                }
                .padding(16)
            }
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                displayName = sessionStore.currentUser.displayName
                publicHandle = sessionStore.currentUser.publicHandle ?? ""
            }
            .pbScreen()
        }
    }

    private var signInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sign in with Apple")
                .font(.headline)

            Text("Mock demo flow for identity upgrades without leaving guest-first creation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                didMockSignIn = true
                if displayName == sessionStore.currentUser.displayName, sessionStore.currentUser.isGuest {
                    displayName = "Pixel Maker"
                }
            } label: {
                Label(didMockSignIn ? "Apple Sign-In Linked" : "Continue with Apple", systemImage: "apple.logo")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .pbCard()
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identity")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.caption.weight(.semibold))
                TextField("Pixel Maker", text: $displayName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Public Handle")
                    .font(.caption.weight(.semibold))
                TextField("pixelmaker", text: $publicHandle)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }
        }
        .pbCard()
    }

    private var availabilityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Availability")
                .font(.headline)

            Label(availabilityState.message, systemImage: availabilityState.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(availabilityState.color)

            if let error = sessionStore.claimError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(PixelBeadsTheme.coral)
            }
        }
        .pbCard()
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button {
                sessionStore.updateDisplayName(displayName)
                sessionStore.claimHandle(publicHandle)
                if sessionStore.claimError == nil {
                    dismiss()
                }
            } label: {
                Label(sessionStore.currentUser.isClaimed ? "Save Profile" : "Claim Handle", systemImage: "at")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(availabilityState != .available)

            if sessionStore.currentUser.isGuest {
                Button("Skip for Now") {
                    sessionStore.updateDisplayName(displayName)
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .pbCard()
    }
}

private enum HandleAvailabilityState: Equatable {
    case idle
    case tooShort
    case available
    case taken

    var message: String {
        switch self {
        case .idle: return "Enter a handle to check local mock availability."
        case .tooShort: return "Handle must be at least 3 characters."
        case .available: return "That handle looks available."
        case .taken: return "That handle is already taken in mock data."
        }
    }

    var symbol: String {
        switch self {
        case .idle: return "info.circle"
        case .tooShort: return "exclamationmark.circle"
        case .available: return "checkmark.circle.fill"
        case .taken: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .available: return .green
        case .taken, .tooShort: return PixelBeadsTheme.coral
        case .idle: return .secondary
        }
    }
}
