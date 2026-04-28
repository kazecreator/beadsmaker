import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    private var privacyURL: URL {
        let lang = Locale.preferredLanguages.first ?? ""
        let path = lang.starts(with: "zh") ? "privacy-zh" : "privacy"
        return URL(string: "https://kazecreator.github.io/pixelbeads/\(path).html")!
    }

    var body: some View {
        NavigationStack {
            WebView(url: privacyURL)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(L10n.tr("Privacy Policy"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.tr("Done")) { dismiss() }
                    }
                }
        }
        .presentationDetents([.large])
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}
