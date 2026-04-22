import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Environment(\.modelContext) private var modelContext

    @State private var showAvatarPicker = false
    @State private var showNicknameAlert = false
    @State private var pendingNickname = ""
    @State private var tokenValidationState: GitHubTokenValidationState = .idle
    @State private var tokenValidationTask: Task<Void, Never>?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if let profile {
                profileContent(profile: profile)
            } else {
                ProgressView().onAppear { createProfile() }
            }
        }
        .navigationTitle("我的")
        .onDisappear {
            tokenValidationTask?.cancel()
        }
    }

    @ViewBuilder
    private func profileContent(profile: UserProfile) -> some View {
        List {
            // Avatar + nickname card
            Section {
                VStack(spacing: 16) {
                    Button { showAvatarPicker = true } label: {
                        ZStack(alignment: .bottomTrailing) {
                            avatarView(profile: profile)
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .background(Circle().fill(Color(.systemBackground)).padding(1))
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        pendingNickname = profile.nickname
                        showNicknameAlert = true
                    } label: {
                        VStack(spacing: 4) {
                            Text(profile.nickname)
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            Label("点击修改昵称", systemImage: "pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("我的作品") {
                LabeledContent("图纸数量") { Text("\(patterns.count) 张").monospacedDigit() }
                LabeledContent("拼豆总数") { Text("\(totalBeads) 颗").monospacedDigit() }
            }

            Section("头像") {
                HStack {
                    Text(profile.isPreset ? "预设像素头像" : "我的拼豆图纸")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("更换") { showAvatarPicker = true }
                }
            }

            Section("Marketplace") {
                TextField("GitHub Token", text: githubTokenBinding(for: profile), axis: .vertical)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .privacySensitive()

                tokenValidationStatusView(for: profile)

                Text("用于提交图纸到 Marketplace 审核。请填写 GitHub Personal Access Token。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView(profile: profile)
        }
        .alert("修改昵称", isPresented: $showNicknameAlert) {
            TextField("昵称", text: $pendingNickname)
            Button("确定") {
                let name = pendingNickname.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { profile.nickname = name }
                try? modelContext.save()
            }
            Button("取消", role: .cancel) {}
        }
        .task {
            syncTokenValidationState(for: profile)
            if profile.trimmedGitHubToken != nil, profile.githubUsername == nil {
                scheduleTokenValidation(for: profile)
            }
        }
    }

    @ViewBuilder
    private func avatarView(profile: UserProfile) -> some View {
        Group {
            if let img = profile.avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemFill), lineWidth: 2))
        .shadow(radius: 4)
    }

    private var totalBeads: Int {
        patterns.reduce(0) { total, p in total + p.gridData.filter { $0 != 0 }.count }
    }

    private func githubTokenBinding(for profile: UserProfile) -> Binding<String> {
        Binding(
            get: { profile.githubToken ?? "" },
            set: { newValue in
                profile.githubToken = newValue.isEmpty ? nil : newValue
                try? modelContext.save()
                scheduleTokenValidation(for: profile)
            }
        )
    }

    @ViewBuilder
    private func tokenValidationStatusView(for profile: UserProfile) -> some View {
        switch tokenValidationState {
        case .idle:
            if let username = profile.githubUsername, !username.isEmpty {
                usernameStatusView(username: username, isAdmin: profile.isAdmin)
            }
        case .validating:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("正在验证 GitHub Token…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .valid(let username):
            usernameStatusView(username: username, isAdmin: profile.isAdmin)
        case .invalid:
            Text("Invalid token")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func usernameStatusView(username: String, isAdmin: Bool) -> some View {
        HStack(spacing: 6) {
            Text(username)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if isAdmin {
                Label("Admin", systemImage: "checkmark.shield.fill")
                    .font(.caption2.weight(.bold))
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
    }

    private func syncTokenValidationState(for profile: UserProfile) {
        if let username = profile.githubUsername, !username.isEmpty {
            tokenValidationState = .valid(username)
        } else if profile.trimmedGitHubToken == nil {
            tokenValidationState = .idle
        }
    }

    private func scheduleTokenValidation(for profile: UserProfile) {
        tokenValidationTask?.cancel()

        guard let token = profile.trimmedGitHubToken else {
            profile.githubUsername = nil
            tokenValidationState = .idle
            try? modelContext.save()
            return
        }

        tokenValidationState = .validating
        tokenValidationTask = Task {
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }

            do {
                let user = try await GitHubAPIClient().fetchAuthenticatedUser(token: token)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard profile.trimmedGitHubToken == token else { return }
                    profile.githubUsername = user.login
                    tokenValidationState = .valid(user.login)
                    try? modelContext.save()
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard profile.trimmedGitHubToken == token else { return }
                    profile.githubUsername = nil
                    tokenValidationState = .invalid
                    try? modelContext.save()
                }
            }
        }
    }

    private func createProfile() {
        let p = UserProfile()
        modelContext.insert(p)
        try? modelContext.save()
    }
}

private enum GitHubTokenValidationState: Equatable {
    case idle
    case validating
    case valid(String)
    case invalid
}
