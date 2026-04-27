import Foundation

struct SupabaseClientConfig: Equatable {
    let url: URL
    let anonKey: String
}

enum AppEnvironmentError: LocalizedError {
    case missingValue(String)
    case invalidURL(String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let key):
            return "Missing required app configuration value: \(key)"
        case .invalidURL(let value):
            return "Invalid Supabase URL: \(value)"
        }
    }
}

enum AppEnvironment {
    static func supabaseConfig(bundle: Bundle = .main) throws -> SupabaseClientConfig {
        let urlValue = try requiredValue(for: "PB_SUPABASE_URL", bundle: bundle)
        let anonKey = try requiredValue(for: "PB_SUPABASE_ANON_KEY", bundle: bundle)

        guard let url = URL(string: urlValue), url.scheme != nil, url.host != nil else {
            throw AppEnvironmentError.invalidURL(urlValue)
        }

        return SupabaseClientConfig(url: url, anonKey: anonKey)
    }

    static func optionalSupabaseConfig(bundle: Bundle = .main) -> SupabaseClientConfig? {
        try? supabaseConfig(bundle: bundle)
    }

    private static func requiredValue(for key: String, bundle: Bundle) throws -> String {
        guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String else {
            throw AppEnvironmentError.missingValue(key)
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("your-project-ref"), !trimmed.contains("your-anon-key") else {
            throw AppEnvironmentError.missingValue(key)
        }

        return trimmed
    }
}

enum AppFeatureFlags {
    static let communityEnabled = false
    static let backendEnabled = false
}
