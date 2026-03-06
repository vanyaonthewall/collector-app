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

private struct FolderCell: View {
    let folder: Folder
    var animateTrigger: Bool = false

    @State private var previewImages: [UIImage] = []
    @State private var newItemScale: CGFloat = 1.0
    @State private var hasPendingAnimation = false
    @State private var pendingAnimationRequested = false

    private func playAnimation() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            newItemScale = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            hasPendingAnimation = false
        }
    }

    var body: some View {
        FolderView(
            name: folder.name,
            previewImages: previewImages,
            lastImageScale: hasPendingAnimation ? newItemScale : 1.0
        )
        .task(id: folder.items.count) {
            let items = Array(folder.items.suffix(3))
            let images = await Task.detached(priority: .userInitiated) {
                items.compactMap { ImageStorage.load(id: $0.id) }
            }.value
            // Анимируем только если был явный внешний запрос
            let shouldAnimate = images.count > previewImages.count && pendingAnimationRequested
            pendingAnimationRequested = false
            if shouldAnimate {
                newItemScale = 0
                hasPendingAnimation = true
            }
            previewImages = images
            if shouldAnimate {
                try? await Task.sleep(nanoseconds: 16_000_000)
                playAnimation()
            }
        }
        .onChange(of: animateTrigger) { _, triggered in
            guard triggered else { return }
            pendingAnimationRequested = true
        }
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

    @State private var showCameraFlow = false
    @State private var bouncingFolderName: String? = nil
    @State private var navigationPath = NavigationPath()
    @State private var tappingFolderID: PersistentIdentifier? = nil

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
        let sum: Int = name.utf8.reduce(0) { $0 &+ Int($1) }
        return Double(sum % 21) - 10.0
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                        let isBouncing = bouncingFolderName == folder.name
                        let isTapping = tappingFolderID == folder.persistentModelID
                        Button {
                            guard tappingFolderID == nil else { return }
                            tappingFolderID = folder.persistentModelID
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                navigationPath.append(folder.persistentModelID)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    tappingFolderID = nil
                                }
                            }
                        } label: {
                            FolderCell(folder: folder, animateTrigger: isBouncing)
                                .scaleEffect(isNew ? 1.2 : (isBouncing ? 1.15 : (isTapping ? 1.2 : 1.0)))
                                .rotationEffect(.degrees(folderRotation(folder.name) + (isNew ? 10 : 0) + (isBouncing ? 6 : 0) + (isTapping ? 10 : 0)))
                                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: isNew)
                                .animation(.spring(response: 0.35, dampingFraction: 0.45), value: isBouncing)
                                .animation(.spring(response: 0.28, dampingFraction: 0.6), value: isTapping)
                        }
                        .buttonStyle(.plain)
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
                        .id(folder.persistentModelID)
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
                        VariableBlurView(intensity: isScrolled ? 0.032 : 0)
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(1.0), location: 0),
                                .init(color: .white.opacity(0.365), location: 0.601),
                                .init(color: .white.opacity(0), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .opacity(isScrolled ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isScrolled)
                    }
                    .ignoresSafeArea()
                }
            }

            } // ScrollViewReader

                MainButton(action: { showCameraFlow = true })
                    .padding(.bottom, 30)
                    .zIndex(2)
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
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: PersistentIdentifier.self) { id in
            if let folder = folders.first(where: { $0.persistentModelID == id }) {
                FolderDetailView(folder: folder)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        } // NavigationStack
        .fullScreenCover(isPresented: $showCameraFlow) {
            CameraFlowView(
                onDismiss: { showCameraFlow = false },
                onItemSaved: { _, folder in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    bouncingFolderName = folder.name
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                        bouncingFolderName = nil
                    }
                }
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Folder.self, inMemory: true)
}
