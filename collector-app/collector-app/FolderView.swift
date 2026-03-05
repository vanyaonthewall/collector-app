import SwiftUI
import UIKit

// MARK: - Variable blur (UIKit bridge)

struct VariableBlurView: UIViewRepresentable {
    var intensity: Double  // 0.0 = no blur, 1.0 = full systemUltraThinMaterial blur

    class BlurView: UIVisualEffectView {
        var animator: UIViewPropertyAnimator?

        init() {
            super.init(effect: nil)
            isUserInteractionEnabled = false
        }
        required init?(coder: NSCoder) { fatalError() }

        func setIntensity(_ value: Double) {
            animator?.stopAnimation(true)
            effect = nil
            let anim = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
                self?.effect = UIBlurEffect(style: .systemUltraThinMaterial)
            }
            anim.startAnimation()
            anim.pauseAnimation()
            anim.fractionComplete = value
            animator = anim
        }
    }

    func makeUIView(context: Context) -> BlurView { BlurView() }
    func updateUIView(_ view: BlurView, context: Context) { view.setIntensity(intensity) }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                // Backdrop blur ~5px (intensity ≈ 5/25 of systemUltraThinMaterial)
                VariableBlurView(intensity: 0.2)
                    .clipShape(FolderShape())

                // Color fill: #6A6A6A at 10%
                FolderShape()
                    .fill(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 0.1))

                // Gradient stroke: #c9c9c9 @ 50% → transparent
                // Direction from Figma gradientTransform (bottom-left → top-right)
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
            }
            .frame(width: 160, height: 130)

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
