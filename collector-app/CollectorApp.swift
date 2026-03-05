import SwiftUI
import SwiftData

@main
struct CollectorApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Folder.self)
    }
}
