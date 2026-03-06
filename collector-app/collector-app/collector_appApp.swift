import SwiftUI
import SwiftData

private struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            GIFView(name: "glass")
                .frame(width: 150, height: 150)
        }
    }
}

@main
struct collector_appApp: App {
    let modelContainer: ModelContainer
    @State private var showSplash = true

    init() {
        let container = try! ModelContainer(for: Folder.self, CollectionItem.self)
        self.modelContainer = container
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .preferredColorScheme(.light)
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                let gifDuration = GIFView.loadGIF(named: "glass")?.duration ?? 2.0
                try? await Task.sleep(nanoseconds: UInt64(gifDuration * 1_000_000_000))
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
