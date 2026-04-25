import Foundation
import AuthenticationServices
import Supabase

// MARK: - Result type

struct AppleSignInResult {
    let appleUserID: String
    let displayName: String?
    let email: String?
}

// MARK: - Errors

enum AppleSignInError: LocalizedError {
    case cancelled
    case credentialInvalid
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .credentialInvalid:
            return L10n.tr("Apple Sign In credential was invalid.")
        case .unknown(let msg):
            return msg
        }
    }
}

// MARK: - AppleSignInManager

@MainActor
final class AppleSignInManager: NSObject, ObservableObject {
    @Published private(set) var isSigningIn = false
    @Published var errorMessage: String?

    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    private var supabaseClient: SupabaseClient?
    /// Retained to keep the ASAuthorizationController alive until its delegate fires.
    private var authController: ASAuthorizationController?

    func configure(config: SupabaseClientConfig) {
        supabaseClient = SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
    }

    // MARK: - Sign In

    /// Presents the Apple Sign In sheet and authenticates with Supabase.
    /// Throws `AppleSignInError.cancelled` if the user dismisses the sheet.
    func signIn() async throws -> AppleSignInResult {
        isSigningIn = true
        errorMessage = nil
        defer { isSigningIn = false }

        return try await withCheckedThrowingContinuation { [weak self] cont in
            guard let self else {
                cont.resume(throwing: AppleSignInError.unknown(L10n.tr("Sign in is unavailable.")))
                return
            }
            self.continuation = cont

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.authController = controller
            controller.performRequests()
        }
    }

    // MARK: - Profile upsert

    /// Upserts the authenticated user's display name into the Supabase `users` table.
    /// Requires `signIn()` to have been called first in this session so the
    /// Supabase client carries a valid JWT.
    func upsertProfile(appleUserID: String, displayName: String) async throws {
        guard let client = supabaseClient else { return }
        try await client
            .from("users")
            .upsert([
                "apple_id": appleUserID,
                "display_name": displayName
            ], onConflict: "apple_id")
            .execute()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                continuation?.resume(throwing: AppleSignInError.credentialInvalid)
                continuation = nil
                return
            }

            // Authenticate with Supabase so subsequent requests are JWT-signed.
            if let client = supabaseClient {
                do {
                    try await client.auth.signInWithIdToken(credentials: .init(
                        provider: .apple,
                        idToken: identityToken
                    ))
                } catch {
                    // Supabase auth failure is non-fatal: the user is still Pro on-device.
                }
            }

            // Reconstruct display name from given + family name (only sent on first sign-in).
            let parts = [
                credential.fullName?.givenName,
                credential.fullName?.familyName
            ]
            let displayName = parts
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)

            let result = AppleSignInResult(
                appleUserID: credential.user,
                displayName: displayName.isEmpty ? nil : displayName,
                email: credential.email
            )
            continuation?.resume(returning: result)
            continuation = nil
            authController = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("[AppleSignInManager] didCompleteWithError: \(error)")
        Task { @MainActor in
            let authError = error as? ASAuthorizationError
            if authError?.code == .canceled {
                continuation?.resume(throwing: AppleSignInError.cancelled)
            } else {
                continuation?.resume(throwing: AppleSignInError.unknown(error.localizedDescription))
            }
            continuation = nil
            authController = nil
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .compactMap { $0.keyWindow }
            .first
            ?? UIWindow()
    }
}
