import SwiftUI
import SwiftData
import AuthenticationServices

struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Environment(\.modelContext) private var modelContext

    @State private var showAvatarPicker = false
    @State private var showNicknameAlert = false
    @State private var pendingNickname = ""

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

            Section("账户") {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    handleSignInWithApple(result: result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 44)

                if profile.isAdmin {
                    Label("Admin", systemImage: "checkmark.shield.fill")
                        .font(.caption.weight(.bold))
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
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

    private func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userIdentifier = appleIDCredential.user
                UserDefaults.standard.set(userIdentifier, forKey: AppConstants.appleUserIDKey)
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    private func createProfile() {
        let p = UserProfile()
        modelContext.insert(p)
        try? modelContext.save()
    }
}
