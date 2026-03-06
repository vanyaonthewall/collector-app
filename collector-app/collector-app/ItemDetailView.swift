import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let item: CollectionItem
    var onDelete: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage? = nil
    @State private var isRenaming = false
    @State private var editName = ""

    private var bottomInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.bottom ?? 34
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()
                .overlay(DotPattern().ignoresSafeArea())

            VStack(spacing: 0) {
                // Изображение — большая верхняя часть
                Group {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.clear
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Название внизу
                Button {
                    editName = item.name
                    isRenaming = true
                } label: {
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.system(size: 22, weight: .regular, design: .monospaced))
                            .kerning(-1)
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.center)
                        IcEdit(color: Color(white: 0.55))
                            .frame(width: 20, height: 20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, bottomInset + 32)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            }

            // Кнопка удаления — правый верхний угол
            ItemDeleteButton {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete?()
                }
            }
            .padding(.top, 16)
            .padding(.trailing, 24)
        }
        .task {
            let id = item.id
            image = await Task.detached(priority: .userInitiated) {
                ImageStorage.load(id: id)
            }.value
        }
        .alert("Rename", isPresented: $isRenaming) {
            TextField("Name", text: $editName)
            Button("Save") {
                let trimmed = editName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { item.name = trimmed }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
