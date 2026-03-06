import SwiftUI
import SwiftData

// MARK: - Preference keys

private struct FolderCenterKey: PreferenceKey {
    static var defaultValue: [PersistentIdentifier: CGPoint] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

private struct ImageBoundsKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - FolderPreviewCell

private struct FolderPreviewCell: View {
    let folder: Folder
    let isSelected: Bool

    @State private var previewImages: [UIImage] = []

    var body: some View {
        FolderView(name: folder.name,
                   fillOpacity: isSelected ? 0.5 : 0.1,
                   previewImages: previewImages)
            .task(id: folder.items.count) {
                let ids = Array(folder.items.suffix(3).map { $0.id })
                let images = await withCheckedContinuation { (cont: CheckedContinuation<[UIImage], Never>) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        cont.resume(returning: ids.compactMap { ImageStorage.load(id: $0) })
                    }
                }
                previewImages = images
            }
    }
}

// MARK: - PhotoReviewView

struct PhotoReviewView: View {
    let originalImage: UIImage
    let onDismiss: () -> Void
    var onItemSaved: ((UIImage, Folder) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.createdAt) var folders: [Folder]
    @Query var allItems: [CollectionItem]

    @State private var processedImage: UIImage? = nil
    @State private var isProcessing = true
    @State private var selectedFolder: Folder? = nil
    @State private var tappedFolder: PersistentIdentifier? = nil
    @State private var processingError: String? = nil
    @State private var isSaving = false

    @State private var isCreatingFolder = false
    @State private var newFolderName = ""
    @State private var newlyAddedFolderName: String? = nil
    @State private var newFolderIsAnimating = false

    private var bottomInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.bottom ?? 34
    }

    private var topInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.top ?? 44
    }

    private let folderAreaH: CGFloat = 190

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
                .overlay(DotPattern().ignoresSafeArea())

            VStack(spacing: 0) {
                // Шапка
                ZStack {
                    Text("New Item")
                        .font(.system(size: 17, weight: .regular, design: .monospaced))
                        .kerning(-1)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                    HStack {
                        BackButton(action: onDismiss)
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, topInset + 8)
                .padding(.bottom, 16)

                // Зона изображения
                ZStack {
                    if let img = processedImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .transition(.scale(scale: 0.72, anchor: .center).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

                // Папки — появляются справа
                if !isProcessing {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(Array(folders.enumerated()), id: \.element.id) { index, folder in
                                let isSelected = selectedFolder?.id == folder.id
                                let isNew = folder.name == newlyAddedFolderName && newFolderIsAnimating
                                Button {
                                    selectedFolder = folder
                                    tappedFolder = folder.id
                                    Task { @MainActor in
                                        try? await Task.sleep(for: .milliseconds(120))
                                        tappedFolder = nil
                                    }
                                } label: {
                                    FolderPreviewCell(folder: folder, isSelected: isSelected)
                                }
                                .buttonStyle(.plain)
                                .rotationEffect(.degrees(folderRotation(name: folder.name, index: index) + (isNew ? 10 : 0)))
                                .scaleEffect(isNew ? 1.2 : (tappedFolder == folder.id ? 0.88 : 1.0))
                                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: isNew)
                                .animation(.spring(response: 0.25, dampingFraction: 0.4), value: tappedFolder)
                                .animation(.easeInOut(duration: 0.15), value: isSelected)
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
                            }
                            SecondaryButton(action: { isCreatingFolder = true })
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .scrollClipDisabled()
                    .frame(height: folderAreaH)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .padding(.top, 36)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                // Кнопка — появляется снизу
                if !isProcessing {
                    Button { triggerSave() } label: {
                        Text("Save")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundStyle(canSave ? .white : Color(white: 0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                ZStack {
                                    VariableBlurView(intensity: 0.1)
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(red: 54/255, green: 54/255, blue: 54/255))
                                        .opacity(canSave ? 1.0 : 0.0)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            )
                            .animation(.easeInOut(duration: 0.2), value: canSave)
                    }
                    .disabled(!canSave || isSaving)
                    .padding(.horizontal, 24)
                    .padding(.top, 36)
                    .padding(.bottom, bottomInset + 16)
                    .allowsHitTesting(true)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        }
        .overlay {
            if processingError != nil {
                VStack(spacing: 16) {
                    GIFView(name: "sock")
                        .frame(width: 150, height: 150)
                    Text("Item not found")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(white: 0.35))
                }
                .transition(.opacity)
            } else if isProcessing {
                VStack(spacing: 16) {
                    GIFView(name: "knee")
                        .frame(width: 150, height: 150)
                    Text("Removing background")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color(white: 0.35))
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .task { await processImage() }
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

    // MARK: - Приватные

    private var canSave: Bool {
        processedImage != nil && selectedFolder != nil
    }

    private func folderRotation(name: String, index: Int) -> Double {
        let charSum: Int = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Double((charSum + index * 7) % 21) - 10.0
    }

    private func triggerSave() {
        guard let folder = selectedFolder else {
            print("❌ Папка не выбрана")
            return
        }
        print("✅ triggerSave: папка '\(folder.name)'")
        isSaving = true
        saveItem()
    }

    private func processImage() async {
        let image = originalImage
        do {
            let result = try await Task.detached(priority: .utility) {
                try await BackgroundRemovalService.removeBackground(from: image)
            }.value
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                processedImage = result
                isProcessing = false
            }
        } catch {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
                processingError = "Предмет не найден"
                isProcessing = false
            }
        }
    }

    private func saveItem() {
        guard let img = processedImage, let folder = selectedFolder else {
            print("❌ saveItem: нет image или folder")
            return
        }
        print("💾 Сохраняем item в папку '\(folder.name)'")
        let item = CollectionItem(folder: folder)
        item.name = "Item #\(allItems.count + 1)"
        do {
            try ImageStorage.save(img, id: item.id)
            print("📁 Image сохранён: \(item.id)")
            modelContext.insert(item)
            print("✅ Item вставлен в modelContext")
            try modelContext.save()
            print("💾 modelContext сохранён")
            onItemSaved?(img, folder)
            onDismiss()
            print("👋 onDismiss() вызван")
        } catch {
            print("❌ Ошибка сохранения: \(error)")
        }
    }
}

struct PhotoReviewView_Previews: PreviewProvider {
    static var previews: some View {
        let types: [any PersistentModel.Type] = [Folder.self, CollectionItem.self]
        let schema = Schema(types)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        return PhotoReviewView(originalImage: UIImage(systemName: "photo")!, onDismiss: {})
            .modelContainer(container)
    }
}
