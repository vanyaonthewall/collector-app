import SwiftUI

struct MainButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "camera")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .padding(24)
                .background(
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(
                            isPressed
                                ? Color(white: 0.419).opacity(0.4)
                                : Color(white: 0.525).opacity(0.4)
                        )
                    }
                )
        }
        .buttonStyle(CollectorButtonStyle(isPressed: $isPressed))
    }
}

struct SecondaryButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .padding(8)
                .background(
                    ZStack {
                        Circle().fill(.ultraThinMaterial)
                        Circle().fill(
                            isPressed
                                ? Color(white: 0.419).opacity(0.4)
                                : Color(white: 0.525).opacity(0.4)
                        )
                    }
                )
        }
        .buttonStyle(CollectorButtonStyle(isPressed: $isPressed))
    }
}

private struct CollectorButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

#Preview("MainButton") {
    ZStack {
        Color.black.ignoresSafeArea()
        MainButton(action: {})
    }
}

#Preview("SecondaryButton") {
    ZStack {
        Color.black.ignoresSafeArea()
        SecondaryButton(action: {})
    }
}
