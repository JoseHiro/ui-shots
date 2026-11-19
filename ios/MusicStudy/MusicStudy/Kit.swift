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
    /// Staggered entrance: rise, unblur and fade in once the app has appeared.
    func reveal(_ i: Int) -> some View { modifier(Reveal(i: i)) }

    /// Registers this view as the tap target for the given demo steps ("s1", "s2"...).
    /// Tapping it for real also advances the script when it is the next step.
    func demoTap(_ steps: Int...) -> some View { modifier(DemoTap(steps: steps)) }
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

struct DemoTap: ViewModifier {
    @EnvironmentObject var demo: Demo
    let steps: [Int]
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture { if steps.contains(demo.step + 1) { demo.advance() } }
            .background(GeometryReader { g in
                Color.clear.preference(key: FramesKey.self,
                                       value: Dictionary(uniqueKeysWithValues: steps.map { ("s\($0)", g.frame(in: .named("screen"))) }))
            })
    }
}

extension Demo {
    /// True while the demo finger is down on the target for one of these steps.
    func isPressing(_ steps: Int...) -> Bool { pressed && steps.contains(pressingStep) }
}

// MARK: - Time

func smooth(_ x: Double) -> Double {
    let c = min(1, max(0, x))
    return c * c * (3 - 2 * c)
}

/// 0 → 1 over `dur` seconds, starting `delay` after `start`. 0 when there is no start yet.
func ramp(_ now: Date, _ start: Date?, delay: Double = 0, dur: Double) -> Double {
    guard let s = start else { return 0 }
    return smooth((now.timeIntervalSince(s) - delay) / dur)
}

/// Something with inertia (a platter, a reel, a beat clock). At each event its speed
/// eases toward a new target; `state` integrates that exactly, so position never jumps.
struct Motor {
    var events: [(Date, Double)]
    var tau = 0.35

    init(_ events: [(Date, Double)], tau: Double = 0.35) {
        self.events = events.sorted { $0.0 < $1.0 }
        self.tau = tau
    }

    func state(at now: Date) -> (pos: Double, vel: Double) {
        var pos = 0.0, v = 0.0
        for (i, e) in events.enumerated() where e.0 < now {
            let end = i + 1 < events.count ? min(events[i + 1].0, now) : now
            let dt = end.timeIntervalSince(e.0)
            let k = exp(-dt / tau)
            pos += e.1 * dt + (v - e.1) * tau * (1 - k)
            v = e.1 + (v - e.1) * k
        }
        return (pos, v)
    }
}

func clock(_ seconds: Double) -> String {
    let s = max(0, Int(seconds))
    return String(format: "%d:%02d", s / 60, s % 60)
}

// MARK: - Shapes

/// A list of numbers SwiftUI can interpolate, so bars can morph between tracks.
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

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Plain RGB so colors can be blended frame by frame (Color.mix needs iOS 18).
struct RGB {
    var r, g, b: Double
    init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
    init(hue h: Double) {
        let x = (h - floor(h)) * 6
        let f = x - floor(x)
        switch Int(x) {
        case 0: self.init(1, f, 0)
        case 1: self.init(1 - f, 1, 0)
        case 2: self.init(0, 1, f)
        case 3: self.init(0, 1 - f, 1)
        case 4: self.init(f, 0, 1)
        default: self.init(1, 0, 1 - f)
        }
    }
    func mix(_ o: RGB, _ t: Double) -> RGB { RGB(r + (o.r - r) * t, g + (o.g - g) * t, b + (o.b - b) * t) }
    var color: Color { Color(.sRGB, red: r, green: g, blue: b) }
}
