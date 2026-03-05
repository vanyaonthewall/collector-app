import SwiftUI
import SwiftData

@main
struct collector_appApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: Folder.self)
    }
}
