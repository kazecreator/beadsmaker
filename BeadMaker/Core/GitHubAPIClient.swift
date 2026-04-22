import Foundation

enum AppConstants {
    // Replace with kazecreator's Apple ID userIdentifier from Apple Developer console
    static let adminAppleID: String = "REPLACE_WITH_YOUR_APPLE_ID"
    static let githubPATKey: String = "beadmaker_admin_github_pat"
    static let appleUserIDKey: String = "beadmaker_apple_user_id"
}

struct GitHubAPIClient {
    private let baseURL = URL(string: "https://api.github.com")!

    func fetchAuthenticatedUser(token: String) async throws -> GitHubAuthenticatedUser {
        let (data, _) = try await request(path: "/user", token: token)
        return try decoder.decode(GitHubAuthenticatedUser.self, from: data)
    }

    func fetchOpenSubmissionIssues(token: String, page: Int, perPage: Int) async throws -> [GitHubIssue] {
        let (data, _) = try await request(
            path: "/repos/kazecreator/bead-maker/issues",
            token: token,
            queryItems: [
                URLQueryItem(name: "labels", value: "marketplace-submission"),
                URLQueryItem(name: "state", value: "open"),
                URLQueryItem(name: "per_page", value: String(perPage)),
                URLQueryItem(name: "page", value: String(page))
            ]
        )
        return try decoder.decode([GitHubIssue].self, from: data)
    }

    func fetchRepositoryContent(path: String, token: String) async throws -> GitHubRepositoryContent {
        let encodedPath = path.split(separator: "/").map(String.init).joined(separator: "/")
        let (data, _) = try await request(path: "/repos/kazecreator/bead-maker/contents/\(encodedPath)", token: token)
        return try decoder.decode(GitHubRepositoryContent.self, from: data)
    }

    func updateRepositoryContent(path: String, token: String, message: String, sha: String, content: Data) async throws {
        let encodedPath = path.split(separator: "/").map(String.init).joined(separator: "/")
        let body = try JSONEncoder().encode(
            GitHubRepositoryContentUpdateRequest(
                message: message,
                sha: sha,
                content: content.base64EncodedString()
            )
        )
        _ = try await request(
            path: "/repos/kazecreator/bead-maker/contents/\(encodedPath)",
            token: token,
            method: "PUT",
            body: body
        )
    }

    func addIssueComment(token: String, issueNumber: Int, body: String) async throws {
        let requestBody = try JSONEncoder().encode(GitHubIssueCommentRequest(body: body))
        _ = try await request(
            path: "/repos/kazecreator/bead-maker/issues/\(issueNumber)/comments",
            token: token,
            method: "POST",
            body: requestBody
        )
    }

    func closeIssue(token: String, issueNumber: Int, labels: [String]) async throws {
        let requestBody = try JSONEncoder().encode(
            GitHubIssueUpdateRequest(
                state: "closed",
                labels: labels
            )
        )
        _ = try await request(
            path: "/repos/kazecreator/bead-maker/issues/\(issueNumber)",
            token: token,
            method: "PATCH",
            body: requestBody
        )
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { value in
            let container = try value.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = GitHubDateFormatter.fractional.date(from: string) ?? GitHubDateFormatter.standard.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid GitHub date: \(string)")
        }
        return decoder
    }

    @discardableResult
    private func request(
        path: String,
        token: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(url: baseURL.appendingPathComponent(normalizedPath), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let url = components?.url else {
            throw GitHubAPIError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("BeadMaker", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let githubError = try? JSONDecoder().decode(GitHubErrorResponse.self, from: data),
               let message = githubError.combinedMessage {
                throw GitHubAPIError.server(message)
            }
            throw GitHubAPIError.server("GitHub 返回了状态码 \(httpResponse.statusCode)。")
        }

        return (data, httpResponse)
    }
}

struct GitHubAuthenticatedUser: Decodable {
    let login: String
}

struct GitHubIssue: Decodable, Identifiable {
    let number: Int
    let title: String
    let body: String?
    let htmlURL: URL
    let createdAt: Date
    let user: GitHubIssueUser

    var id: Int { number }

    private enum CodingKeys: String, CodingKey {
        case number
        case title
        case body
        case htmlURL = "html_url"
        case createdAt = "created_at"
        case user
    }
}

struct GitHubIssueUser: Decodable {
    let login: String
}

struct GitHubRepositoryContent: Decodable {
    let sha: String
    let content: String
    let encoding: String
}

private struct GitHubRepositoryContentUpdateRequest: Encodable {
    let message: String
    let sha: String
    let content: String
}

private struct GitHubIssueCommentRequest: Encodable {
    let body: String
}

private struct GitHubIssueUpdateRequest: Encodable {
    let state: String
    let labels: [String]
}

private struct GitHubErrorResponse: Decodable {
    let message: String
    let errors: [GitHubErrorDetail]?

    var combinedMessage: String? {
        let details = errors?.compactMap(\.message).joined(separator: "\n")
        if let details, !details.isEmpty {
            return "\(message)\n\(details)"
        }
        return message
    }
}

private struct GitHubErrorDetail: Decodable {
    let message: String?
}

enum GitHubAPIError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case invalidRepositoryContent
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "GitHub 请求无效。"
        case .invalidResponse:
            return "未收到有效的 GitHub 响应。"
        case .invalidRepositoryContent:
            return "无法解析 GitHub 仓库文件内容。"
        case .server(let message):
            return message
        }
    }
}

enum GitHubDateFormatter {
    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
