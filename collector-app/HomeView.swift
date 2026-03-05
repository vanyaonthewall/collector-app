import SwiftUI
import SwiftData

struct DotPattern: View {
    var body: some View {
        Canvas { context, size in
            let dotRadius: CGFloat = 1
            let spacing: CGFloat = 10
            let color = Color(red: 225/255, green: 225/255, blue: 225/255)
            var x: CGFloat = spacing / 2
            while x < size.width {
                var y: CGFloat = spacing / 2
                while y < size.height {
                    let rect = CGRect(
                        x: x - dotRadius, y: y - dotRadius,
                        width: dotRadius * 2, height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                    y += spacing
                }
                x += spacing
            }
        }
    }
}

struct HomeView: View {
    @Query(sort: \Folder.createdAt) var folders: [Folder]
    @Environment(\.modelContext) private var modelContext

    @State private var isCreatingFolder = false
    @State private var newFolderName = ""
    @State private var scrollOffset: CGFloat = 0

    private var isScrolled: Bool { scrollOffset > 20 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()
                .overlay(DotPattern().ignoresSafeArea())

            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("Collections")
                        .font(isScrolled
                            ? .system(size: 17, weight: .regular, design: .monospaced)
                            : .system(size: 32, weight: .regular, design: .monospaced))
                        .kerning(-2)
                        .foregroundStyle(.black)
                        .animation(.easeInOut(duration: 0.2), value: isScrolled)
                    Spacer()
                    SecondaryButton(action: { isCreatingFolder = true })
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)

                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 24
                    ) {
                        ForEach(folders) { folder in
                            FolderView(name: folder.name)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geo in
                    geo.contentOffset.y
                } action: { _, offset in
                    scrollOffset = max(0, offset)
                }
            }

            MainButton(action: {})
                .padding(.bottom, 50)
        }
        .ignoresSafeArea(.keyboard)
        .alert("New Collection", isPresented: $isCreatingFolder) {
            TextField("Name", text: $newFolderName)
            Button("Create") {
                let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                modelContext.insert(Folder(name: trimmed))
                newFolderName = ""
            }
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Folder.self, inMemory: true)
}
