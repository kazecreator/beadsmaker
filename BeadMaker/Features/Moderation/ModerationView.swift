import SwiftData
import SwiftUI
import UIKit

struct ModerationView: View {
    @Query private var profiles: [UserProfile]
    @StateObject private var viewModel = ModerationViewModel()
    @State private var patInput: String = ""
    @AppStorage(AppConstants.githubPATKey) private var githubPAT = ""

    private var profile: UserProfile? { profiles.first }
    private var isAdmin: Bool { profile?.isAdmin == true }

    private var storedPat: String? {
        let trimmed = githubPAT.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var body: some View {
        Group {
            if isAdmin {
                if storedPat != nil {
                    moderationContentView
                } else {
                    patSetupView
                }
            } else {
                ContentUnavailableView(
                    "Moderation Unavailable",
                    systemImage: "checkmark.shield",
                    description: Text("Only the admin account can access moderation.")
                )
            }
        }
        .navigationTitle("Moderation")
        .alert("操作结果", isPresented: alertBinding) {
            Button("好", role: .cancel) {
                viewModel.alertMessage = nil
            }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }

    @ViewBuilder
    private var patSetupView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("设置 GitHub Personal Access Token")
                    .font(.headline)
                Text("用于访问 GitHub 仓库并审核投稿。请输入您的 GitHub PAT。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub PAT")
                    .font(.subheadline.weight(.medium))
                SecureField("ghp_xxxxxxxxxxxx", text: $patInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)

            Button {
                let trimmed = patInput.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                githubPAT = trimmed
            } label: {
                Text("保存并继续")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(patInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Spacer()
        }
    }

    @ViewBuilder
    private var moderationContentView: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView("加载待审核投稿…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .failed(let message):
                ContentUnavailableView {
                    Label("加载失败", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try Again") {
                        if let token = storedPat {
                            Task {
                                await viewModel.reload(token: token)
                            }
                        }
                    }
                }

            case .empty:
                Text("暂无待审核投稿")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded:
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.submissions) { submission in
                            ModerationSubmissionCard(
                                submission: submission,
                                isProcessing: viewModel.processingIssueNumbers.contains(submission.id),
                                onApprove: {
                                    if let token = storedPat {
                                        Task {
                                            await viewModel.approveSubmission(submission, token: token)
                                        }
                                    }
                                },
                                onReject: {
                                    if let token = storedPat {
                                        Task {
                                            await viewModel.rejectSubmission(submission, token: token)
                                        }
                                    }
                                }
                            )
                        }

                        if viewModel.canLoadMore {
                            Button {
                                if let token = storedPat {
                                    Task {
                                        await viewModel.loadMore(token: token)
                                    }
                                }
                            } label: {
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Text("Load More")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isLoadingMore)
                        }
                    }
                    .padding()
                }
                .refreshable {
                    if let token = storedPat {
                        await viewModel.reload(token: token)
                    }
                }
            }
        }
        .onChange(of: storedPat) { _, newToken in
            if let token = newToken {
                Task {
                    await viewModel.loadIfNeeded(token: token)
                }
            }
        }
        .onAppear {
            if let token = storedPat {
                Task {
                    await viewModel.loadIfNeeded(token: token)
                }
            }
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.alertMessage = nil
                }
            }
        )
    }
}

private struct ModerationSubmissionCard: View {
    let submission: ModerationSubmission
    let isProcessing: Bool
    let onApprove: () -> Void
    let onReject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(submission.title)
                    .font(.headline)

                Text("@\(submission.author) · \(submission.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !submission.description.isEmpty {
                    Text(submission.description)
                        .font(.subheadline)
                }
            }

            if let previewImage = submission.previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 280)
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let parseError = submission.parseError {
                Text(parseError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 12) {
                Button("Approve", action: onApprove)
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing || !submission.isApprovable)

                Button("Reject", action: onReject)
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(isProcessing)

                Spacer()

                Link(destination: submission.htmlURL) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.body)
                }
                .foregroundStyle(.secondary)
            }

            if isProcessing {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
    }
}

@MainActor
private final class ModerationViewModel: ObservableObject {
    @Published private(set) var state: ModerationState = .idle
    @Published private(set) var submissions: [ModerationSubmission] = []
    @Published private(set) var canLoadMore = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var processingIssueNumbers: Set<Int> = []
    @Published var alertMessage: String?

    private let client = GitHubAPIClient()
    private let pageSize = 10
    private var currentPage = 1

    func loadIfNeeded(token: String) async {
        guard case .idle = state else { return }
        await reload(token: token)
    }

    func reload(token: String) async {
        state = .loading
        currentPage = 1
        canLoadMore = false

        do {
            let submissions = try await fetchSubmissions(page: 1, token: token)
            self.submissions = submissions
            canLoadMore = submissions.count == pageSize
            state = submissions.isEmpty ? .empty : .loaded
        } catch {
            submissions = []
            state = .failed(error.localizedDescription)
        }
    }

    func loadMore(token: String) async {
        guard !isLoadingMore, canLoadMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1

        do {
            let moreSubmissions = try await fetchSubmissions(page: nextPage, token: token)
            currentPage = nextPage
            submissions.append(contentsOf: moreSubmissions)
            canLoadMore = moreSubmissions.count == pageSize
            state = submissions.isEmpty ? .empty : .loaded
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func approveSubmission(_ submission: ModerationSubmission, token: String) async {
        guard !processingIssueNumbers.contains(submission.id), let pattern = submission.pattern else { return }

        processingIssueNumbers.insert(submission.id)
        defer { processingIssueNumbers.remove(submission.id) }

        do {
            let repositoryContent = try await client.fetchRepositoryContent(path: "patterns.json", token: token)
            guard repositoryContent.encoding == "base64",
                  let contentData = Data(base64Encoded: repositoryContent.content, options: .ignoreUnknownCharacters) else {
                throw GitHubAPIError.invalidRepositoryContent
            }

            let rootObject = try JSONSerialization.jsonObject(with: contentData)
            var rootDictionary = rootObject as? [String: Any] ?? [:]
            var patterns = rootDictionary["patterns"] as? [Any] ?? []
            let now = GitHubDateFormatter.standard.string(from: Date())

            patterns.append(submission.marketplaceEntry(from: pattern, approvedAt: now))
            rootDictionary["version"] = rootDictionary["version"] ?? 1
            rootDictionary["updatedAt"] = now
            rootDictionary["patterns"] = patterns

            let updatedContent = try JSONSerialization.data(withJSONObject: rootDictionary, options: [.prettyPrinted, .sortedKeys])

            try await client.updateRepositoryContent(
                path: "patterns.json",
                token: token,
                message: "feat: add \"\(pattern.name)\" to marketplace",
                sha: repositoryContent.sha,
                content: updatedContent
            )
            try await client.closeIssue(token: token, issueNumber: submission.issueNumber, labels: ["marketplace-submission", "approved"])

            submissions.removeAll { $0.id == submission.id }
            state = submissions.isEmpty ? .empty : .loaded
            alertMessage = "投稿已通过审核并加入 Marketplace。"
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func rejectSubmission(_ submission: ModerationSubmission, token: String) async {
        guard !processingIssueNumbers.contains(submission.id) else { return }

        processingIssueNumbers.insert(submission.id)
        defer { processingIssueNumbers.remove(submission.id) }

        do {
            try await client.addIssueComment(
                token: token,
                issueNumber: submission.issueNumber,
                body: "谢谢投稿！这次未能入选精选市场，欢迎继续提交其他作品。"
            )
            try await client.closeIssue(token: token, issueNumber: submission.issueNumber, labels: ["marketplace-submission", "rejected"])

            submissions.removeAll { $0.id == submission.id }
            state = submissions.isEmpty ? .empty : .loaded
            alertMessage = "投稿已拒绝并关闭。"
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func fetchSubmissions(page: Int, token: String) async throws -> [ModerationSubmission] {
        let issues = try await client.fetchOpenSubmissionIssues(token: token, page: page, perPage: pageSize)
        return issues.map(ModerationSubmissionParser.parse)
    }
}

private enum ModerationState {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}

private struct ModerationSubmission: Identifiable {
    let issueNumber: Int
    let title: String
    let author: String
    let description: String
    let createdAt: Date
    let htmlURL: URL
    let pattern: ModerationPattern?
    let previewImage: UIImage?
    let parseError: String?

    var id: Int { issueNumber }
    var isApprovable: Bool { pattern != nil }

    func marketplaceEntry(from pattern: ModerationPattern, approvedAt: String) -> [String: Any] {
        var entry: [String: Any] = [
            "id": UUID().uuidString.lowercased(),
            "name": pattern.name,
            "author": author,
            "description": pattern.description,
            "width": pattern.width,
            "height": pattern.height,
            "gridData": pattern.gridData,
            "downloads": 0,
            "submittedAt": GitHubDateFormatter.standard.string(from: createdAt),
            "approvedAt": approvedAt
        ]

        if let colorPalette = pattern.colorPalette, !colorPalette.isEmpty {
            entry["colorPalette"] = colorPalette
        }

        return entry
    }
}

private struct ModerationPattern {
    let name: String
    let description: String
    let width: Int
    let height: Int
    let gridData: [Int]
    let colorPalette: [String]?
}

private enum ModerationSubmissionParser {
    private static let jsonPattern = /```json\s*([\s\S]*?)\s*```/
    private static let rawCodePattern = /```\s*([\s\S]*?)\s*```/
    private static let descriptionPattern = /Description:\s*([\s\S]*?)\s*Pattern JSON:/

    static func parse(issue: GitHubIssue) -> ModerationSubmission {
        let body = issue.body ?? ""
        let fallbackDescription = extractDescription(from: body)
        let fallbackName = patternName(from: issue.title)

        guard let jsonString = extractPatternJSONString(from: body) else {
            return ModerationSubmission(
                issueNumber: issue.number,
                title: issue.title,
                author: issue.user.login,
                description: fallbackDescription,
                createdAt: issue.createdAt,
                htmlURL: issue.htmlURL,
                pattern: nil,
                previewImage: nil,
                parseError: "无法从 issue body 中解析图纸 JSON。"
            )
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return ModerationSubmission(
                issueNumber: issue.number,
                title: issue.title,
                author: issue.user.login,
                description: fallbackDescription,
                createdAt: issue.createdAt,
                htmlURL: issue.htmlURL,
                pattern: nil,
                previewImage: nil,
                parseError: "图纸 JSON 编码无效。"
            )
        }

        if let object = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let pattern = directPattern(from: object, fallbackName: fallbackName, fallbackDescription: fallbackDescription) {
            return ModerationSubmission(
                issueNumber: issue.number,
                title: issue.title,
                author: issue.user.login,
                description: pattern.description,
                createdAt: issue.createdAt,
                htmlURL: issue.htmlURL,
                pattern: pattern,
                previewImage: ModerationPreviewRenderer.render(pattern: pattern),
                parseError: nil
            )
        }

        do {
            let decoded = try PatternCodec.decode(data: jsonData)
            let pattern = ModerationPattern(
                name: decoded.name.isEmpty ? fallbackName : decoded.name,
                description: fallbackDescription,
                width: decoded.width,
                height: decoded.height,
                gridData: decoded.gridData,
                colorPalette: nil
            )

            return ModerationSubmission(
                issueNumber: issue.number,
                title: issue.title,
                author: issue.user.login,
                description: pattern.description,
                createdAt: issue.createdAt,
                htmlURL: issue.htmlURL,
                pattern: pattern,
                previewImage: ModerationPreviewRenderer.render(pattern: pattern),
                parseError: nil
            )
        } catch {
            return ModerationSubmission(
                issueNumber: issue.number,
                title: issue.title,
                author: issue.user.login,
                description: fallbackDescription,
                createdAt: issue.createdAt,
                htmlURL: issue.htmlURL,
                pattern: nil,
                previewImage: nil,
                parseError: "图纸 JSON 无法解析，请在 GitHub 中检查投稿内容。"
            )
        }
    }

    private static func extractPatternJSONString(from body: String) -> String? {
        if let match = body.firstMatch(of: jsonPattern) {
            return String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let match = body.firstMatch(of: rawCodePattern) {
            return String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func extractDescription(from body: String) -> String {
        if let match = body.firstMatch(of: descriptionPattern) {
            return String(match.1).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private static func directPattern(from object: [String: Any], fallbackName: String, fallbackDescription: String) -> ModerationPattern? {
        let nestedPattern = (object["pattern"] as? [String: Any]) ?? object

        guard let width = intValue(for: ["width", "w"], in: nestedPattern),
              let height = intValue(for: ["height", "h"], in: nestedPattern),
              let gridData = intArrayValue(for: ["gridData", "grid", "cells"], in: nestedPattern) else {
            return nil
        }

        let name = stringValue(for: ["name", "title"], in: nestedPattern) ?? stringValue(for: ["name", "title"], in: object) ?? fallbackName
        let description = stringValue(for: ["description"], in: nestedPattern) ?? stringValue(for: ["description"], in: object) ?? fallbackDescription
        let colorPalette = stringArrayValue(for: ["colorPalette", "palette"], in: nestedPattern) ?? stringArrayValue(for: ["colorPalette", "palette"], in: object)

        guard width > 0, height > 0, gridData.count >= width * height else {
            return nil
        }

        return ModerationPattern(
            name: name,
            description: description,
            width: width,
            height: height,
            gridData: Array(gridData.prefix(width * height)),
            colorPalette: colorPalette
        )
    }

    private static func patternName(from title: String) -> String {
        title
            .replacingOccurrences(of: "[Marketplace Submission] ", with: "")
            .components(separatedBy: " by ")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? title
    }

    private static func stringValue(for keys: [String], in dictionary: [String: Any]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    private static func intValue(for keys: [String], in dictionary: [String: Any]) -> Int? {
        for key in keys {
            if let value = dictionary[key] as? Int {
                return value
            }
            if let value = dictionary[key] as? NSNumber {
                return value.intValue
            }
            if let value = dictionary[key] as? String, let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    private static func intArrayValue(for keys: [String], in dictionary: [String: Any]) -> [Int]? {
        for key in keys {
            if let values = dictionary[key] as? [Int] {
                return values
            }
            if let values = dictionary[key] as? [NSNumber] {
                return values.map(\.intValue)
            }
        }
        return nil
    }

    private static func stringArrayValue(for keys: [String], in dictionary: [String: Any]) -> [String]? {
        for key in keys {
            if let values = dictionary[key] as? [String] {
                return values
            }
        }
        return nil
    }
}

private enum ModerationPreviewRenderer {
    private static let htmlColors: [UIColor] = [
        "#ffffff", "#000000", "#ff0000", "#00ff00", "#0000ff", "#ffff00", "#ff00ff", "#00ffff",
        "#c0c0c0", "#808080", "#800000", "#808000", "#008000", "#800080", "#008080", "#000080",
        "#ffc0cb", "#f0e68c", "#d2691e", "#696969", "#ffa500", "#800020", "#00ced1", "#4b0082",
        "#ee82ee", "#6a5acd", "#cd853f", "#2f4f4f", "#ff6347", "#4682b4", "#9acd32", "#ba55d3"
    ].compactMap(UIColor.init(hex:))

    static func render(pattern: ModerationPattern, cellSize: CGFloat = 8) -> UIImage? {
        guard pattern.width > 0, pattern.height > 0, pattern.gridData.count >= pattern.width * pattern.height else {
            return nil
        }

        let size = CGSize(width: CGFloat(pattern.width) * cellSize, height: CGFloat(pattern.height) * cellSize)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for row in 0..<pattern.height {
                for col in 0..<pattern.width {
                    let index = row * pattern.width + col
                    color(for: pattern.gridData[index]).setFill()
                    context.fill(
                        CGRect(
                            x: CGFloat(col) * cellSize,
                            y: CGFloat(row) * cellSize,
                            width: cellSize,
                            height: cellSize
                        )
                    )
                }
            }
        }
    }

    private static func color(for index: Int) -> UIColor {
        if index >= 0, index < htmlColors.count {
            return htmlColors[index]
        }

        if let bead = BeadColorLibrary.color(id: index) {
            return UIColor(hex: bead.hex)
        }

        return .white
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
