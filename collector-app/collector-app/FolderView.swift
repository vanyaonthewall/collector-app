import SwiftUI
import UIKit

// MARK: - Variable blur (UIKit bridge)

struct VariableBlurView: UIViewRepresentable {
    var intensity: Double  // 0.0 = no blur, 1.0 = full systemUltraThinMaterial blur

    class BlurView: UIVisualEffectView {
        var animator: UIViewPropertyAnimator?
        var lastIntensity: Double = -1

        init() {
            super.init(effect: nil)
            isUserInteractionEnabled = false
        }
        required init?(coder: NSCoder) { fatalError() }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            guard lastIntensity >= 0 else { return }
            let v = lastIntensity
            lastIntensity = -1
            DispatchQueue.main.async { [weak self] in
                self?.setIntensity(v)
            }
        }

        func setIntensity(_ value: Double) {
            guard abs(value - lastIntensity) > 0.001 else { return }
            animator?.stopAnimation(true)
            animator = nil
            effect = nil
            lastIntensity = value
            guard value > 0 else { return }
            let anim = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
                self?.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            }
            anim.startAnimation()
            anim.pauseAnimation()
            anim.fractionComplete = CGFloat(value)
            animator = anim
            // После навигационных анимаций fractionComplete может сброситься —
            // проверяем в 3 контрольных точках
            scheduleStabilization()
        }

        private func scheduleStabilization() {
            let target = lastIntensity
            for delay in [0.3, 0.6, 1.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.fixIfNeeded(target: target)
                }
            }
        }

        private func fixIfNeeded(target: Double) {
            guard window != nil, target > 0 else { return }
            guard let a = animator, Double(a.fractionComplete) > target + 0.05 else { return }
            lastIntensity = -1
            setIntensity(target)
        }
    }

    func makeUIView(context: Context) -> BlurView { BlurView() }
    func updateUIView(_ view: BlurView, context: Context) {
        // Выносим за пределы CATransaction SwiftUI — иначе animator
        // запускается внутри SwiftUI-транзакции и добегает до fractionComplete=1.0
        let target = intensity
        DispatchQueue.main.async { [weak view] in
            guard let view else { return }
            let actual = Double(view.animator?.fractionComplete ?? 0)
            if actual > target + 0.05 && target < 0.99 { view.lastIntensity = -1 }
            view.setIntensity(target)
        }
    }
    static func dismantleUIView(_ uiView: BlurView, coordinator: ()) {
        uiView.animator?.stopAnimation(true)
        uiView.animator = nil
        uiView.effect = nil
    }
}

// MARK: - Folder shape (exact from folder.svg, viewBox 0 0 160 130)

struct FolderShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 160
        let sy = rect.height / 130

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }

        var p = Path()
        p.move(to: pt(63.0827, 0))
        p.addCurve(to: pt(77.8175, 14.9449),
                   control1: pt(71.2202, 0),
                   control2: pt(77.8174, 6.69132))
        p.addCurve(to: pt(91.6917, 29.0179),
                   control1: pt(77.8175, 22.717),
                   control2: pt(84.0289, 29.0178))
        p.addLine(to: pt(141.516, 29.0179))
        p.addCurve(to: pt(160, 47.7656),
                   control1: pt(151.724, 29.0181),
                   control2: pt(160, 37.4117))
        p.addLine(to: pt(160, 111.252))
        p.addCurve(to: pt(141.516, 130),
                   control1: pt(160, 121.606),
                   control2: pt(151.724, 130))
        p.addLine(to: pt(18.484, 130))
        p.addCurve(to: pt(0, 111.252),
                   control1: pt(8.27588, 130),
                   control2: pt(0, 121.606))
        p.addLine(to: pt(0, 18.7476))
        p.addCurve(to: pt(18.484, 0),
                   control1: pt(0, 8.39391),
                   control2: pt(8.27589, 0))
        p.addLine(to: pt(63.0827, 0))
        p.closeSubpath()
        return p
    }
}

// MARK: - FolderView

struct FolderView: View {
    var name: String = "text-folder"
    var fillOpacity: Double = 0.1
    var previewImages: [UIImage] = []
    var lastImageScale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .bottom) {
                // Превью предметов — торчат из-под папки сверху
                if !previewImages.isEmpty {
                    let shown = Array(previewImages.suffix(3))
                    let rotations: [Double] = [-10, -2, 6]
                    let size: CGFloat = 93

                    ZStack {
                        ForEach(0..<shown.count, id: \.self) { i in
                            Image(uiImage: shown[i])
                                .resizable()
                                .scaledToFit()
                                .frame(width: size, height: size)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .rotationEffect(.degrees(rotations[i % 3]))
                                .offset(x: CGFloat(i) * 28 - CGFloat(shown.count - 1) * 14)
                                .scaleEffect(i == shown.count - 1 ? lastImageScale : 1.0)
                        }
                    }
                    .offset(x: 10, y: -40)
                }

                FolderShape()
                    .fill(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: fillOpacity))
                    .background(
                        VariableBlurView(intensity: 0.1)
                            .clipShape(FolderShape())
                    )
                    .overlay(
                        FolderShape()
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: Color(red: 201/255, green: 201/255, blue: 201/255, opacity: 0.5), location: 0),
                                        .init(color: Color(red: 201/255, green: 201/255, blue: 201/255, opacity: 0), location: 1)
                                    ],
                                    startPoint: UnitPoint(x: -0.028, y: 0.549),
                                    endPoint: UnitPoint(x: 0.576, y: 0.082)
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(width: 160, height: 130)
            }
            .frame(width: 160, height: 175)
            .id(name)

            Text(name)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color(white: 0.21))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
        }
        .frame(width: 160)
    }
}

#Preview("Default") {
    ZStack {
        Color.white.ignoresSafeArea()
        Canvas { context, size in
            let dotRadius: CGFloat = 1
            let spacing: CGFloat = 10
            let color = Color(red: 225/255, green: 225/255, blue: 225/255)
            var x: CGFloat = spacing / 2
            while x < size.width {
                var y: CGFloat = spacing / 2
                while y < size.height {
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - dotRadius, y: y - dotRadius,
                                               width: dotRadius * 2, height: dotRadius * 2)),
                        with: .color(color)
                    )
                    y += spacing
                }
                x += spacing
            }
        }
        .ignoresSafeArea()
        FolderView(name: "Монеты")
    }
}
