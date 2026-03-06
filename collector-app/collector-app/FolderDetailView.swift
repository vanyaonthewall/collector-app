import SwiftUI
import SwiftData
import UIKit

private struct BackSwipeEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }
    func updateUIViewController(_ vc: UIViewController, context: Context) {
        DispatchQueue.main.async {
            vc.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            vc.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
}

// MARK: - Async image cell

private struct ItemCell: View {
    let item: CollectionItem
    let rotation: Double

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .rotationEffect(.degrees(rotation))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.92))
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
            }
        }
        .task(id: item.id) {
            let id = item.id
            let loaded = await Task.detached(priority: .userInitiated) {
                ImageStorage.load(id: id)
            }.value
            image = loaded
        }
    }
}

struct FolderDetailView: View {
    var folder: Folder

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scrollOffset: CGFloat = 0
    @State private var isEditing = false
    @State private var editName = ""
    @State private var selectedItem: CollectionItem? = nil
    @State private var deletingItemId: UUID? = nil

    private var isScrolled: Bool { scrollOffset > 20 }

    private func itemRotation(for item: CollectionItem) -> Double {
        let sum: Int = folder.name.utf8.reduce(0) { $0 &+ Int($1) }
        let baseRotation = Double(sum % 21) - 10.0
        let itemIndex = folder.items.firstIndex(where: { $0.id == item.id }) ?? 0
        return baseRotation + Double((itemIndex * 3) % 8) - 4.0
    }

    private var topInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.top ?? 44
    }

    var body: some View {
        let headerH = topInset + 72

        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
                .overlay(DotPattern().ignoresSafeArea())

            if folder.items.isEmpty {
                Text("nothing here yet")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(white: 0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        Color.clear.frame(height: headerH + 20)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 24) {
                            ForEach(folder.items) { item in
                                Button { selectedItem = item } label: {
                                    ItemCell(item: item, rotation: itemRotation(for: item))
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(deletingItemId == item.id ? 0 : 1.0)
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: deletingItemId)
                            }
                        }
                        .padding(.horizontal, 24)
                        Color.clear.frame(height: 40)
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { scrollGeo in
                    scrollGeo.contentOffset.y
                } action: { _, offset in
                    scrollOffset = max(0, offset)
                }
            }

            ZStack {
                Text(folder.name)
                    .font(.system(size: 17, weight: .regular, design: .monospaced))
                    .kerning(-2)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    BackButton(action: { dismiss() })
                    Spacer()
                    FolderEditButton(action: {
                        editName = folder.name
                        isEditing = true
                    })
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, topInset + 8)
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
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
        .background(BackSwipeEnabler())
        .onDisappear { selectedItem = nil }
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item, onDelete: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                deletingItemId = item.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    modelContext.delete(item)
                    deletingItemId = nil
                }
            })
        }
        .alert("Edit Collection", isPresented: $isEditing) {
            TextField("Name", text: $editName)
            Button("Delete", role: .destructive) {
                modelContext.delete(folder)
                dismiss()
            }
            Button("Save") {
                let trimmed = editName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { folder.name = trimmed }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct FolderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let types: [any PersistentModel.Type] = [Folder.self, CollectionItem.self]
        let schema = Schema(types)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let folder = Folder(name: "Test Folder")
        container.mainContext.insert(folder)
        return FolderDetailView(folder: folder)
            .modelContainer(container)
    }
}
