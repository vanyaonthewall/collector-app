import SwiftUI
import SwiftData
import UIKit

struct FolderDetailView: View {
    var folder: Folder
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var scrollOffset: CGFloat = 0
    @State private var isEditing = false
    @State private var editName = ""

    private var isScrolled: Bool { scrollOffset > 20 }

    private var topInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.top ?? 44
    }

    var body: some View {
        let headerH = topInset + 72

        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()
                .overlay(DotPattern().ignoresSafeArea())

            ScrollView {
                Color.clear.frame(height: headerH + 20)
                // future folder content
                Color.clear.frame(height: 120)
            }
            .onScrollGeometryChange(for: CGFloat.self) { scrollGeo in
                scrollGeo.contentOffset.y
            } action: { _, offset in
                scrollOffset = max(0, offset)
            }

            ZStack {
                Text(folder.name)
                    .font(.system(size: 17, weight: .regular, design: .monospaced))
                    .kerning(-2)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    BackButton(action: onDismiss)
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
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    guard value.translation.width > 80,
                          abs(value.translation.height) < abs(value.translation.width)
                    else { return }
                    onDismiss()
                }
        )
        .sheet(isPresented: $isEditing) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Edit Collection")
                    .font(.system(size: 17, weight: .regular, design: .monospaced))
                    .kerning(-1)
                    .foregroundStyle(.black)

                TextField("Name", text: $editName)
                    .font(.system(size: 15, design: .monospaced))
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 12) {
                    Button {
                        modelContext.delete(folder)
                        isEditing = false
                        onDismiss()
                    } label: {
                        Text("Delete")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                ZStack {
                                    VariableBlurView(intensity: 0.08)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 134/255, green: 134/255, blue: 134/255, opacity: 0.4))
                                }
                            }
                    }

                    Button {
                        let trimmed = editName.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { folder.name = trimmed }
                        isEditing = false
                    } label: {
                        Text("Save")
                            .font(.system(size: 15, design: .monospaced))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                ZStack {
                                    VariableBlurView(intensity: 0.08)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 134/255, green: 134/255, blue: 134/255, opacity: 0.4))
                                }
                            }
                    }
                }
            }
            .padding(24)
            .presentationDetents([.height(210)])
            .presentationDragIndicator(.visible)
            .presentationBackground {
                ZStack {
                    VariableBlurView(intensity: 0.2)
                    Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 0.1)
                }
            }
        }
    }
}
