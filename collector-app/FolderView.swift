import SwiftUI

// Exact shape from folder.svg (viewBox 0 0 160 130)
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

struct FolderView: View {
    var name: String = "text-folder"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                FolderShape()
                    .fill(.ultraThinMaterial)
                FolderShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.3),
                                Color.gray.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
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
