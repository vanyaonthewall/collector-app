import SwiftUI
import SwiftData

@main
struct collector_appApp: App {
    let modelContainer: ModelContainer

    init() {
        let container = try! ModelContainer(for: Folder.self, CollectionItem.self)
        self.modelContainer = container
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }
}
