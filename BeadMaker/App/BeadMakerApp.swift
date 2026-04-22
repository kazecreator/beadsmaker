import SwiftUI
import SwiftData

@main
struct BeadMakerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Pattern.self, CollectedPattern.self, UserProfile.self])
    }
}
