import SwiftUI
import SwiftData
import UIKit

struct ShareView: View {
    let pattern: Pattern
    @Query private var profiles: [UserProfile]
    @Environment(\.dismiss) private var dismiss
    @State private var patternImage: UIImage?
    @State private var showSavedAlert = false
    @State private var savedMessage = ""
    @State private var showShareSheet = false
    @State private var showMarketplaceSheet = false
    @State private var shareItems: [Any] = []

    private var profile: UserProfile? { profiles.first }
    private var thumbnailPreview: UIImage {
        if let data = pattern.thumbnailData, let image = UIImage(data: data) {
            return image
        }
        return PatternRenderer.thumbnail(pattern: pattern)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // QR Code Section
                    VStack(spacing: 12) {
                        Text("分享二维码").font(.headline)
                        QRGeneratorView(pattern: pattern)
                        HStack(spacing: 12) {
                            shareButton(icon: "square.and.arrow.down", label: "保存到相册") {
                                saveQRToAlbum()
                            }
                            shareButton(icon: "square.and.arrow.up", label: "分享") {
                                shareQR()
                            }
                        }
                        Text("分享的图片包含署名").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Pattern Image Section
                    VStack(spacing: 12) {
                        Text("导出图片").font(.headline)
                        if let img = patternImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 4)
                        } else {
                            ProgressView().frame(height: 200)
                        }
                        HStack(spacing: 12) {
                            shareButton(icon: "square.and.arrow.down", label: "保存图片") {
                                savePatternToAlbum()
                            }
                            shareButton(icon: "square.and.arrow.up", label: "分享图片") {
                                sharePattern()
                            }
                        }
                        Text("导出带网格线和署名的图纸图片")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(spacing: 12) {
                        Text("提交到 Marketplace").font(.headline)
                        Image(uiImage: thumbnailPreview)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button {
                            showMarketplaceSheet = true
                        } label: {
                            Label("Submit to Marketplace", systemImage: "paperplane.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Text("通过 GitHub Issue 提交图纸，等待 Marketplace 审核。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("分享图纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .task {
                let base = PatternRenderer.render(pattern: pattern, cellSize: 12, showGrid: true)
                patternImage = PatternRenderer.attachSignature(to: base, profile: profile)
            }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(items: shareItems)
            }
            .sheet(isPresented: $showMarketplaceSheet) {
                MarketplaceSubmissionSheet(
                    pattern: pattern,
                    profile: profile,
                    previewImage: thumbnailPreview
                )
            }
            .alert(savedMessage, isPresented: $showSavedAlert) {
                Button("好的", role: .cancel) {}
            }
        }
    }

    // MARK: - Buttons

    @ViewBuilder
    private func shareButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .foregroundStyle(.primary)
    }

    // MARK: - QR

    private func signedQR() -> UIImage? {
        guard let string = try? PatternCodec.encodeQRCodeString(pattern: pattern) else { return nil }
        let data = Data(string.utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        guard let output = filter?.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        let raw = UIImage(cgImage: cgImage)
        return PatternRenderer.attachSignature(to: raw, profile: profile)
    }

    private func saveQRToAlbum() {
        guard let img = signedQR() else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        savedMessage = "二维码已保存到相册"
        showSavedAlert = true
    }

    private func shareQR() {
        guard let img = signedQR() else { return }
        shareItems = [img]
        showShareSheet = true
    }

    private func savePatternToAlbum() {
        guard let img = patternImage else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        savedMessage = "图纸图片已保存到相册"
        showSavedAlert = true
    }

    private func sharePattern() {
        guard let img = patternImage else { return }
        shareItems = [img]
        showShareSheet = true
    }
}

// MARK: - Activity Sheet

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

private struct MarketplaceSubmissionSheet: View {
    let pattern: Pattern
    let profile: UserProfile?
    let previewImage: UIImage

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppConstants.githubPATKey) private var githubPAT = ""

    @State private var patternName: String
    @State private var authorName: String
    @State private var description: String
    @State private var isSubmitting = false
    @State private var showResultAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var dismissAfterAlert = false

    init(pattern: Pattern, profile: UserProfile?, previewImage: UIImage) {
        self.pattern = pattern
        self.profile = profile
        self.previewImage = previewImage
        _patternName = State(initialValue: pattern.name)
        _authorName = State(initialValue: profile?.nickname ?? "")
        _description = State(initialValue: "")
    }

    private var trimmedPatternName: String {
        patternName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedAuthorName: String {
        authorName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !trimmedPatternName.isEmpty && !trimmedAuthorName.isEmpty && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Submission") {
                    TextField("Pattern name", text: $patternName)
                    TextField("Author name", text: $authorName)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .onChange(of: description) { _, newValue in
                            if newValue.count > 200 {
                                description = String(newValue.prefix(200))
                            }
                        }

                    HStack {
                        Spacer()
                        Text("\(description.count)/200")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Preview") {
                    HStack {
                        Spacer()
                        Image(uiImage: previewImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(maxWidth: 220, maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .padding(.trailing, 6)
                            }
                            Text(isSubmitting ? "Submitting…" : "Submit")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Submit to Marketplace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(alertTitle, isPresented: $showResultAlert) {
                Button(dismissAfterAlert ? "好的" : "关闭", role: .cancel) {
                    if dismissAfterAlert {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    @MainActor
    private func submit() async {
        let token = githubPAT.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            presentAlert(
                title: "Marketplace 不可用",
                message: "Marketplace 投稿功能仅对管理员开放。",
                dismissAfterAlert: false
            )
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let submissionPattern = Pattern(name: trimmedPatternName, width: pattern.width, height: pattern.height)
            submissionPattern.gridData = pattern.gridData
            submissionPattern.thumbnailData = pattern.thumbnailData

            let data = try PatternCodec.encode(pattern: submissionPattern)
            guard let patternJSON = String(data: data, encoding: .utf8) else {
                throw MarketplaceSubmissionError.invalidPatternJSON
            }

            try await MarketplaceSubmissionClient().submit(
                token: token,
                patternName: trimmedPatternName,
                author: trimmedAuthorName,
                description: trimmedDescription,
                patternJSON: patternJSON
            )

            presentAlert(
                title: "提交成功",
                message: "图纸已提交到 Marketplace 审核队列。",
                dismissAfterAlert: true
            )
        } catch {
            presentAlert(
                title: "提交失败",
                message: error.localizedDescription,
                dismissAfterAlert: false
            )
        }
    }

    private func presentAlert(title: String, message: String, dismissAfterAlert: Bool) {
        alertTitle = title
        alertMessage = message
        self.dismissAfterAlert = dismissAfterAlert
        showResultAlert = true
    }
}

private struct MarketplaceSubmissionClient {
    func submit(token: String, patternName: String, author: String, description: String, patternJSON: String) async throws {
        let endpoint = URL(string: "https://api.github.com/repos/kazecreator/bead-maker/issues")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("BeadMaker", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONEncoder().encode(
            GitHubIssueRequest(
                title: "[Marketplace Submission] \(patternName) by \(author)",
                body: issueBody(description: description, patternJSON: patternJSON),
                labels: ["marketplace-submission"]
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MarketplaceSubmissionError.invalidResponse
        }

        guard httpResponse.statusCode == 201 else {
            if let githubError = try? JSONDecoder().decode(GitHubIssueErrorResponse.self, from: data),
               let message = githubError.combinedMessage {
                throw MarketplaceSubmissionError.server(message)
            }
            throw MarketplaceSubmissionError.server("GitHub 返回了状态码 \(httpResponse.statusCode)。")
        }
    }

    private func issueBody(description: String, patternJSON: String) -> String {
        let descriptionText = description.isEmpty ? "No description provided." : description
        return """
        Description:
        \(descriptionText)

        Pattern JSON:
        ```json
        \(patternJSON)
        ```
        """
    }
}

private struct GitHubIssueRequest: Encodable {
    let title: String
    let body: String
    let labels: [String]
}

private struct GitHubIssueErrorResponse: Decodable {
    let message: String
    let errors: [GitHubIssueErrorDetail]?

    var combinedMessage: String? {
        let details = errors?.compactMap(\.message).joined(separator: "\n")
        if let details, !details.isEmpty {
            return "\(message)\n\(details)"
        }
        return message
    }
}

private struct GitHubIssueErrorDetail: Decodable {
    let message: String?
}

private enum MarketplaceSubmissionError: LocalizedError {
    case invalidPatternJSON
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidPatternJSON:
            return "图纸 JSON 编码失败，请稍后再试。"
        case .invalidResponse:
            return "未收到有效的 GitHub 响应。"
        case .server(let message):
            return message
        }
    }
}
