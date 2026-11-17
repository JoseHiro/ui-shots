import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255, opacity: alpha)
    }
}

// MARK: - Frames for the demo driver

struct FramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func demoFrame(_ id: String) -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: FramesKey.self, value: [id: g.frame(in: .named("screen"))])
        })
    }

    /// Staggered entrance: rise, unblur and fade in once the board has appeared.
    func reveal(_ i: Int) -> some View { modifier(Reveal(i: i)) }
}

struct Reveal: ViewModifier {
    @EnvironmentObject var demo: Demo
    let i: Int
    func body(content: Content) -> some View {
        content
            .opacity(demo.appeared ? 1 : 0)
            .offset(y: demo.appeared ? 0 : 26)
            .blur(radius: demo.appeared ? 0 : 8)
            .animation(.spring(response: 0.75, dampingFraction: 0.86).delay(Double(i) * 0.075), value: demo.appeared)
    }
}

// MARK: - Numbers

struct Counter: View, Animatable {
    var value: Double
    let format: (Double) -> String
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    var body: some View { Text(format(value)).monospacedDigit() }
}

enum Fmt {
    private static let nf: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return f
    }()
    static func num(_ v: Double, _ digits: Int = 0) -> String {
        nf.minimumFractionDigits = digits
        nf.maximumFractionDigits = digits
        return nf.string(from: NSNumber(value: v)) ?? ""
    }
    static func compact(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.2fM", v / 1_000_000) }
        if v >= 1_000 { return String(format: "%.1fK", v / 1_000) }
        return String(format: "%.0f", v)
    }
}

// MARK: - Chart geometry

/// A list of numbers SwiftUI can interpolate, so a chart can morph between ranges.
struct Vec: VectorArithmetic {
    var v: [Double]
    static var zero: Vec { Vec(v: []) }
    private static func zip(_ a: Vec, _ b: Vec, _ op: (Double, Double) -> Double) -> Vec {
        let n = max(a.v.count, b.v.count)
        return Vec(v: (0..<n).map { op($0 < a.v.count ? a.v[$0] : 0, $0 < b.v.count ? b.v[$0] : 0) })
    }
    static func + (a: Vec, b: Vec) -> Vec { zip(a, b, +) }
    static func - (a: Vec, b: Vec) -> Vec { zip(a, b, -) }
    mutating func scale(by s: Double) { v = v.map { $0 * s } }
    var magnitudeSquared: Double { v.reduce(0) { $0 + $1 * $1 } }
}

func normalize(_ xs: [Double], pad: Double = 0.08) -> [Double] {
    let lo = xs.min() ?? 0, hi = xs.max() ?? 1, span = max(hi - lo, 1e-9)
    return xs.map { pad + (1 - 2 * pad) * ($0 - lo) / span }
}

/// Smooth line (Catmull-Rom), optionally closed down to the baseline for a fill.
struct LineShape: Shape {
    var data: Vec
    var closed = false
    var animatableData: Vec {
        get { data }
        set { data = newValue }
    }
    func path(in r: CGRect) -> Path {
        let n = data.v.count
        guard n > 1 else { return Path() }
        let pts = data.v.enumerated().map { CGPoint(x: r.minX + r.width * CGFloat($0.offset) / CGFloat(n - 1),
                                                     y: r.minY + r.height * (1 - CGFloat($0.element))) }
        var p = Path()
        p.move(to: pts[0])
        for i in 0..<(n - 1) {
            let p0 = pts[max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(i + 2, n - 1)]
            p.addCurve(to: p2,
                       control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                       control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        if closed {
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
        }
        return p
    }
}

/// Point on the chart for a 0...1 scrub position.
func chartPoint(_ xs: [Double], _ s: CGFloat, in size: CGSize) -> (index: Int, point: CGPoint) {
    let n = xs.count
    let i = min(n - 1, max(0, Int((s * CGFloat(n - 1)).rounded())))
    return (i, CGPoint(x: size.width * CGFloat(i) / CGFloat(n - 1), y: size.height * (1 - CGFloat(xs[i]))))
}

/// Deterministic wiggle for fake data.
func wave(_ n: Int, seed: Double, from a: Double, to b: Double, vol: Double) -> [Double] {
    (0..<n).map { i in
        let t = Double(i) / Double(n - 1)
        let w = sin(t * 13 + seed) * 0.55 + sin(t * 31 + seed * 2.1) * 0.25 + sin(t * 5.3 + seed * 0.7) * 0.45
        return a + (b - a) * t + vol * w * (i == n - 1 ? 0 : 1)
    }
}

struct Sparkline: View {
    let data: [Double]
    let color: Color
    var width: CGFloat = 1.6
    @EnvironmentObject var demo: Demo
    var body: some View {
        LineShape(data: Vec(v: normalize(data, pad: 0.1)))
            .trim(from: 0, to: demo.appeared ? 1 : 0)
            .stroke(color, style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
            .animation(.easeInOut(duration: 1.2).delay(0.5), value: demo.appeared)
    }
}

/// Sliding selection for a row of range options. `style` draws the indicator.
struct RangePicker<Indicator: View>: View {
    let options: [String]
    let font: Font
    let on: Color
    let off: Color
    var spacing: CGFloat = 4
    var itemPadding = EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
    @ViewBuilder let indicator: () -> Indicator
    @EnvironmentObject var demo: Demo
    @Namespace private var ns

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(options.enumerated()), id: \.offset) { i, o in
                let sel = demo.range == i
                Text(o)
                    .font(font)
                    .foregroundStyle(sel ? on : off)
                    .padding(itemPadding)
                    .background {
                        if sel { indicator().matchedGeometryEffect(id: "sel", in: ns) }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { demo.setRange(i) }
                    .demoFrame("seg\(i)")
            }
        }
    }
}

extension View {
    /// Drag anywhere on the chart to scrub it.
    func scrubbable(_ demo: Demo) -> some View {
        GeometryReader { g in
            self.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { demo.scrub = min(1, max(0, $0.location.x / g.size.width)) }
                    .onEnded { _ in withAnimation(.easeOut(duration: 0.25)) { demo.scrub = nil } })
        }
    }
}
