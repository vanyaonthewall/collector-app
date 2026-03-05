import SwiftUI

// MARK: - Icons

private struct IcCamera: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 40
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            var body = Path()
            body.move(to: pt(32.5, 32.5))
            body.addLine(to: pt(7.5, 32.5))
            body.addCurve(to: pt(5.732, 31.768), control1: pt(6.837, 32.5),   control2: pt(6.201, 32.237))
            body.addCurve(to: pt(5, 30),          control1: pt(5.263, 31.299), control2: pt(5, 30.663))
            body.addLine(to: pt(5, 12.5))
            body.addCurve(to: pt(5.732, 10.732),  control1: pt(5, 11.837),    control2: pt(5.263, 11.201))
            body.addCurve(to: pt(7.5, 10),        control1: pt(6.201, 10.263),control2: pt(6.837, 10))
            body.addLine(to: pt(12.5, 10))
            body.addLine(to: pt(15, 6.25))
            body.addLine(to: pt(25, 6.25))
            body.addLine(to: pt(27.5, 10))
            body.addLine(to: pt(32.5, 10))
            body.addCurve(to: pt(34.268, 10.732), control1: pt(33.163, 10),   control2: pt(33.799, 10.263))
            body.addCurve(to: pt(35, 12.5),       control1: pt(34.737, 11.201),control2: pt(35, 11.837))
            body.addLine(to: pt(35, 30))
            body.addCurve(to: pt(34.268, 31.768), control1: pt(35, 30.663),   control2: pt(34.737, 31.299))
            body.addCurve(to: pt(32.5, 32.5),     control1: pt(33.799, 32.237),control2: pt(33.163, 32.5))
            body.closeSubpath()

            let lens = Path(ellipseIn: CGRect(x: 14.375 * s, y: 15 * s, width: 11.25 * s, height: 11.25 * s))

            let style = StrokeStyle(lineWidth: 1.5 * s, lineCap: .round, lineJoin: .round)
            context.stroke(body, with: .color(.white), style: style)
            context.stroke(lens, with: .color(.white), style: style)
        }
    }
}

private struct IcPlus: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 32
            let inset: CGFloat = 5 * s
            let cx = size.width / 2
            let cy = size.height / 2

            var h = Path()
            h.move(to: CGPoint(x: inset, y: cy))
            h.addLine(to: CGPoint(x: size.width - inset, y: cy))

            var v = Path()
            v.move(to: CGPoint(x: cx, y: inset))
            v.addLine(to: CGPoint(x: cx, y: size.height - inset))

            let style = StrokeStyle(lineWidth: 1.5 * s, lineCap: .round)
            context.stroke(h, with: .color(.white), style: style)
            context.stroke(v, with: .color(.white), style: style)
        }
    }
}

private struct IcEdit: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 24
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            var p = Path()

            // Subpath 1: outer pencil body
            p.move(to: pt(21.1781, 7.01062))
            p.addLine(to: pt(16.9884, 2.82093))
            p.addCurve(to: pt(16.5626, 2.53638), control1: pt(16.8666, 2.69904), control2: pt(16.7219, 2.60235))
            p.addCurve(to: pt(16.0603, 2.43646), control1: pt(16.4034, 2.47042), control2: pt(16.2327, 2.43646))
            p.addCurve(to: pt(15.558,  2.53638), control1: pt(15.8879, 2.43646), control2: pt(15.7173, 2.47042))
            p.addCurve(to: pt(15.1322, 2.82093), control1: pt(15.3988, 2.60235), control2: pt(15.2541, 2.69904))
            p.addLine(to: pt(3.57188, 14.3822))
            p.addCurve(to: pt(3.28695, 14.8078), control1: pt(3.44975, 14.5039), control2: pt(3.35292, 14.6485))
            p.addCurve(to: pt(3.1875,  15.3103), control1: pt(3.22098, 14.9671), control2: pt(3.18718, 15.1379))
            p.addLine(to: pt(3.1875,  19.5))
            p.addCurve(to: pt(3.57192, 20.4281), control1: pt(3.1875,  19.8481), control2: pt(3.32578, 20.1819))
            p.addCurve(to: pt(4.5,    20.8125), control1: pt(3.81807, 20.6742), control2: pt(4.15191, 20.8125))
            p.addLine(to: pt(8.68969, 20.8125))
            p.addCurve(to: pt(9.19216, 20.713),  control1: pt(8.8621,  20.8128), control2: pt(9.03287, 20.779))
            p.addCurve(to: pt(9.61781, 20.4281), control1: pt(9.35145, 20.6471), control2: pt(9.49611, 20.5502))
            p.addLine(to: pt(21.1781, 8.86687))
            p.addCurve(to: pt(21.4627, 8.44105), control1: pt(21.3,    8.74499), control2: pt(21.3967, 8.6003))
            p.addCurve(to: pt(21.5626, 7.93874), control1: pt(21.5286, 8.2818),  control2: pt(21.5626, 8.11112))
            p.addCurve(to: pt(21.4627, 7.43644), control1: pt(21.5626, 7.76637), control2: pt(21.5286, 7.59569))
            p.addCurve(to: pt(21.1781, 7.01062), control1: pt(21.3967, 7.27719), control2: pt(21.3,    7.1325))
            p.closeSubpath()

            // Subpath 2: paper face
            p.move(to: pt(8.82188, 19.6322))
            p.addCurve(to: pt(8.68969, 19.6875), control1: pt(8.78688, 19.6674), control2: pt(8.73934, 19.6873))
            p.addLine(to: pt(4.5,    19.6875))
            p.addCurve(to: pt(4.36742, 19.6326), control1: pt(4.45027, 19.6875), control2: pt(4.40258, 19.6677))
            p.addCurve(to: pt(4.3125,  19.5),    control1: pt(4.33226, 19.5974), control2: pt(4.3125,  19.5497))
            p.addLine(to: pt(4.3125, 15.3103))
            p.addCurve(to: pt(4.36781, 15.1781), control1: pt(4.31271, 15.2607), control2: pt(4.3326,  15.2131))
            p.addLine(to: pt(12.75,  6.79499))
            p.addLine(to: pt(17.2041, 11.25))
            p.addLine(to: pt(8.82188, 19.6322))
            p.closeSubpath()

            // Subpath 3: pencil tip
            p.move(to: pt(20.3822, 8.07187))
            p.addLine(to: pt(18,    10.4541))
            p.addLine(to: pt(13.5459, 5.99999))
            p.addLine(to: pt(15.9281, 3.61687))
            p.addCurve(to: pt(15.989,  3.57617), control1: pt(15.9455, 3.59944), control2: pt(15.9662, 3.58561))
            p.addCurve(to: pt(16.0608, 3.56188), control1: pt(16.0117, 3.56674), control2: pt(16.0361, 3.56188))
            p.addCurve(to: pt(16.1326, 3.57617), control1: pt(16.0854, 3.56188), control2: pt(16.1098, 3.56674))
            p.addCurve(to: pt(16.1934, 3.61687), control1: pt(16.1553, 3.58561), control2: pt(16.176,  3.59944))
            p.addLine(to: pt(20.3822, 7.80656))
            p.addCurve(to: pt(20.4229, 7.86741), control1: pt(20.3996, 7.82397), control2: pt(20.4135, 7.84465))
            p.addCurve(to: pt(20.4372, 7.93921), control1: pt(20.4323, 7.89017), control2: pt(20.4372, 7.91457))
            p.addCurve(to: pt(20.4229, 8.01101), control1: pt(20.4372, 7.96385), control2: pt(20.4323, 7.98825))
            p.addCurve(to: pt(20.3822, 8.07187), control1: pt(20.4135, 8.03378), control2: pt(20.3996, 8.05446))
            p.closeSubpath()

            context.fill(p, with: .color(.white))
        }
    }
}

private struct IcChevron: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 24
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            var p = Path()
            p.move(to: pt(15.397, 19.1026))
            p.addCurve(to: pt(15.5273, 19.2852), control1: pt(15.4523, 19.1541), control2: pt(15.4966, 19.2162))
            p.addCurve(to: pt(15.5759, 19.5042), control1: pt(15.5581, 19.3542), control2: pt(15.5746, 19.4287))
            p.addCurve(to: pt(15.5351, 19.7248), control1: pt(15.5773, 19.5798), control2: pt(15.5634, 19.6548))
            p.addCurve(to: pt(15.4113, 19.9119), control1: pt(15.5068, 19.7949), control2: pt(15.4647, 19.8585))
            p.addCurve(to: pt(15.2242, 20.0357), control1: pt(15.3579, 19.9653), control2: pt(15.2942, 20.0074))
            p.addCurve(to: pt(15.0036, 20.0766), control1: pt(15.1542, 20.064), control2: pt(15.0791, 20.0779))
            p.addCurve(to: pt(14.7846, 20.028), control1: pt(14.9281, 20.0752), control2: pt(14.8536, 20.0587))
            p.addCurve(to: pt(14.602, 19.8976), control1: pt(14.7156, 19.9972), control2: pt(14.6535, 19.9529))
            p.addLine(to: pt(7.10201, 12.3976))
            p.addCurve(to: pt(6.9375, 12.0001), control1: pt(6.99667, 12.2922), control2: pt(6.9375, 12.1492))
            p.addCurve(to: pt(7.10201, 11.6026), control1: pt(6.9375, 11.8511), control2: pt(6.99667, 11.7081))
            p.addLine(to: pt(14.602, 4.10263))
            p.addCurve(to: pt(14.9954, 3.95175), control1: pt(14.7086, 4.00327), control2: pt(14.8497, 3.94918))
            p.addCurve(to: pt(15.3832, 4.11641), control1: pt(15.1411, 3.95432), control2: pt(15.2802, 4.01335))
            p.addCurve(to: pt(15.5479, 4.50424), control1: pt(15.4863, 4.21947), control2: pt(15.5453, 4.35851))
            p.addCurve(to: pt(15.397, 4.89763), control1: pt(15.5505, 4.64996), control2: pt(15.4964, 4.791))
            p.addLine(to: pt(8.29544, 12.0001))
            p.addLine(to: pt(15.397, 19.1026))
            p.closeSubpath()
            context.fill(p, with: .color(.white))
        }
    }
}

// MARK: - Buttons

struct MainButton: View {
    let action: () -> Void
    var padding: CGFloat = 24

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            IcCamera()
                .frame(width: 40, height: 40)
                .padding(padding)
                .background(
                    ZStack {
                        VariableBlurView(intensity: 0.08).clipShape(Circle())
                        Circle().fill(
                            isPressed
                                ? Color(red: 107/255, green: 107/255, blue: 107/255, opacity: 0.4)
                                : Color(red: 134/255, green: 134/255, blue: 134/255, opacity: 0.4)
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
            IcPlus()
                .frame(width: 32, height: 32)
                .padding(8)
                .background(
                    ZStack {
                        VariableBlurView(intensity: 0.08).clipShape(Circle())
                        Circle().fill(
                            isPressed
                                ? Color(red: 107/255, green: 107/255, blue: 107/255, opacity: 0.4)
                                : Color(red: 134/255, green: 134/255, blue: 134/255, opacity: 0.4)
                        )
                    }
                )
        }
        .buttonStyle(CollectorButtonStyle(isPressed: $isPressed))
    }
}

struct BackButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            IcChevron()
                .frame(width: 24, height: 24)
                .padding(12)
                .background(
                    ZStack {
                        VariableBlurView(intensity: 0.08).clipShape(Circle())
                        Circle().fill(
                            isPressed
                                ? Color(red: 107/255, green: 107/255, blue: 107/255, opacity: 0.4)
                                : Color(red: 134/255, green: 134/255, blue: 134/255, opacity: 0.4)
                        )
                    }
                )
        }
        .buttonStyle(CollectorButtonStyle(isPressed: $isPressed))
    }
}

struct FolderEditButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            IcEdit()
                .frame(width: 24, height: 24)
                .padding(12)
                .background(
                    ZStack {
                        VariableBlurView(intensity: 0.08).clipShape(Circle())
                        Circle().fill(
                            isPressed
                                ? Color(red: 107/255, green: 107/255, blue: 107/255, opacity: 0.4)
                                : Color(red: 134/255, green: 134/255, blue: 134/255, opacity: 0.4)
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
