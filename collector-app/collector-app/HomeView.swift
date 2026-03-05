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

private struct FolderFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct HomeView: View {
    @Query(sort: \Folder.createdAt) var folders: [Folder]
    @Environment(\.modelContext) private var modelContext

    @State private var isCreatingFolder = false
    @State private var newFolderName = ""
    @State private var scrollOffset: CGFloat = 0

    @State private var newlyAddedFolderName: String? = nil
    @State private var newFolderIsAnimating = false

    @State private var selectedFolder: Folder? = nil
    @State private var showDetail = false
    @State private var detailScale: CGFloat = 0.0
    @State private var detailOpacity: Double = 0.0
    @State private var detailBlur: CGFloat = 20
    @State private var tappedAnchor: UnitPoint = .center
    @State private var folderFrames: [Int: CGRect] = [:]

    private var isScrolled: Bool { scrollOffset > 20 }

    private func gridColumns(for width: CGFloat) -> [GridItem] {
        let itemWidth: CGFloat = 160
        let paddingHorizontal: CGFloat = 24
        let spacing: CGFloat = 24
        let availableWidth = width - paddingHorizontal * 2
        let columns = max(Int((availableWidth + spacing) / (itemWidth + spacing)), 1)
        return Array(repeating: GridItem(.flexible()), count: columns)
    }

    private func folderRotation(_ name: String) -> Double {
        let sum = name.utf8.reduce(0) { Int($0) &+ Int($1) }
        return Double(sum % 21) - 10.0
    }

    private func openFolder(_ folder: Folder) {
        let screen = UIScreen.main.bounds
        if let frame = folderFrames[folder.name.hashValue] {
            tappedAnchor = UnitPoint(
                x: frame.midX / screen.width,
                y: frame.midY / screen.height
            )
        } else {
            tappedAnchor = .center
        }
        detailBlur = 20
        selectedFolder = folder
        showDetail = true

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            detailScale = 1.0
            detailOpacity = 1.0
            detailBlur = 0
        }
    }

    private func closeFolder() {
        withAnimation(.easeIn(duration: 0.15)) { detailBlur = 20 }
        withAnimation(.easeIn(duration: 0.25)) {
            detailScale = 0.0
            detailOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showDetail = false
            selectedFolder = nil
            detailScale = 0.0
            detailOpacity = 0.0
            detailBlur = 20
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()
                    .overlay(DotPattern().ignoresSafeArea())

                ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(
                        columns: gridColumns(for: geo.size.width),
                        spacing: 24
                    ) {
                    ForEach(folders) { folder in
                        let isNew = folder.name == newlyAddedFolderName && newFolderIsAnimating
                        Button { openFolder(folder) } label: {
                            FolderView(name: folder.name)
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(isNew ? 1.2 : 1.0)
                        .rotationEffect(.degrees(folderRotation(folder.name) + (isNew ? 10 : 0)))
                        .animation(.spring(response: 0.5, dampingFraction: 0.65), value: isNew)
                        .onAppear {
                            guard folder.name == newlyAddedFolderName, newFolderIsAnimating else { return }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                                    newFolderIsAnimating = false
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                newlyAddedFolderName = nil
                            }
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: FolderFrameKey.self,
                                    value: [folder.name.hashValue: geo.frame(in: .global)]
                                )
                            }
                        )
                        .id(folder.id)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, offset in
                scrollOffset = max(0, offset)
            }
            .onChange(of: folders.count) { oldCount, newCount in
                guard newCount > oldCount, let last = folders.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .top) }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
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
                .background {
                    ZStack {
                        VariableBlurView(intensity: 0.08)
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(1.0), location: 0),
                                .init(color: .white.opacity(0.365), location: 0.601),
                                .init(color: .white.opacity(0), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .opacity(isScrolled ? 1 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.2), value: isScrolled)
                }
            }

            } // ScrollViewReader

                MainButton(action: {})
                    .padding(.bottom, 30)
                    .zIndex(2)
                    .offset(y: showDetail ? 150 : 0)
                    .opacity(showDetail ? 0 : 1)
                    .disabled(showDetail)
                    .animation(.easeIn(duration: 0.2), value: showDetail)
            }
            .onPreferenceChange(FolderFrameKey.self) { frames in
                folderFrames = frames
            }
            .ignoresSafeArea(.keyboard)
            .alert("New Collection", isPresented: $isCreatingFolder) {
            TextField("Name", text: $newFolderName)
            Button("Create") {
                let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                newlyAddedFolderName = trimmed
                newFolderIsAnimating = true
                modelContext.insert(Folder(name: trimmed))
                newFolderName = ""
            }
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if showDetail, let folder = selectedFolder {
                FolderDetailView(folder: folder, onDismiss: closeFolder)
                    .frame(
                        width: UIScreen.main.bounds.width,
                        height: UIScreen.main.bounds.height
                    )
                    .ignoresSafeArea()
                    .scaleEffect(detailScale, anchor: tappedAnchor)
                    .opacity(detailOpacity)
                    .blur(radius: detailBlur)
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Folder.self, inMemory: true)
}
