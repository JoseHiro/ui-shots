import SwiftUI

@main
struct DashboardStudyApp: App {
    // Launch with `-style 1...4 -demo YES` to auto-play the recording sequence.
    private let style = max(1, UserDefaults.standard.integer(forKey: "style"))
    private let demo = UserDefaults.standard.bool(forKey: "demo")

    var body: some Scene {
        WindowGroup { RootView(style: style, isDemo: demo) }
    }
}

/// Shared state every dashboard reads: whether it has entered, the selected
/// range, and where the chart is being scrubbed (0...1, nil when not touched).
@MainActor
final class Demo: ObservableObject {
    @Published var appeared = false
    @Published var range = 0
    @Published var scrub: CGFloat?
    @Published var touch: CGPoint?
    @Published var pressed = false
    /// Red square used only to line up recordings. Cropped out of the final video.
    @Published var syncMarker = false
    var frames: [String: CGRect] = [:]

    func setRange(_ i: Int) {
        withAnimation(.spring(response: 0.65, dampingFraction: 0.86)) { range = i }
    }

    func run() async {
        try? await Task.sleep(for: .seconds(1.5))
        syncMarker = true
        try? await Task.sleep(for: .seconds(0.5))
        syncMarker = false
        appeared = true
        try? await Task.sleep(for: .seconds(2.3))
        await tap("seg1") { self.setRange(1) }
        try? await Task.sleep(for: .seconds(1.0))
        await scrubChart()
        try? await Task.sleep(for: .seconds(0.35))
        await tap("seg2") { self.setRange(2) }
    }

    private func tap(_ id: String, action: @escaping () -> Void) async {
        guard let f = frames[id] else { action(); return }
        withAnimation(.easeOut(duration: 0.12)) { touch = CGPoint(x: f.midX, y: f.midY); pressed = true }
        try? await Task.sleep(for: .milliseconds(130))
        action()
        try? await Task.sleep(for: .milliseconds(130))
        withAnimation(.easeOut(duration: 0.2)) { pressed = false }
        try? await Task.sleep(for: .milliseconds(160))
        withAnimation(.easeOut(duration: 0.2)) { touch = nil }
    }

    private func scrubChart() async {
        guard let f = frames["chart"] else { return }
        let pt = { (s: CGFloat) in CGPoint(x: f.minX + s * f.width, y: f.minY + f.height * 0.82) }
        withAnimation(.easeOut(duration: 0.12)) { touch = pt(0.16); pressed = true }
        scrub = 0.16
        try? await Task.sleep(for: .milliseconds(180))
        await glide(from: 0.16, to: 0.88, steps: 84, pt: pt)
        await glide(from: 0.88, to: 0.58, steps: 38, pt: pt)
        try? await Task.sleep(for: .milliseconds(450))
        withAnimation(.easeOut(duration: 0.25)) { pressed = false; scrub = nil }
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.easeOut(duration: 0.2)) { touch = nil }
    }

    private func glide(from a: CGFloat, to b: CGFloat, steps: Int, pt: (CGFloat) -> CGPoint) async {
        for k in 0...steps {
            let t = Double(k) / Double(steps)
            let e = t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
            let s = a + (b - a) * CGFloat(e)
            scrub = s
            touch = pt(s)
            try? await Task.sleep(for: .milliseconds(16))
        }
    }
}

struct RootView: View {
    @StateObject private var demo = Demo()
    let style: Int
    let isDemo: Bool

    var body: some View {
        Group {
            if isDemo {
                board(style)
            } else {
                TabView {
                    ForEach(1...4, id: \.self) { board($0) }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
        }
        .environmentObject(demo)
        .coordinateSpace(.named("screen"))
        .overlay(alignment: .topLeading) {
            if demo.syncMarker { Rectangle().fill(.red).frame(width: 60, height: 60).ignoresSafeArea() }
        }
        .overlay {
            if let p = demo.touch { TouchDot(point: p, pressed: demo.pressed) }
        }
        .onPreferenceChange(FramesKey.self) { demo.frames = $0 }
        .task {
            if isDemo { await demo.run() } else {
                try? await Task.sleep(for: .milliseconds(300))
                demo.appeared = true
            }
        }
    }

    @ViewBuilder private func board(_ s: Int) -> some View {
        switch s {
        case 2: Hearth()
        case 3: Lull()
        case 4: Reach()
        default: Ledger()
        }
    }
}

struct TouchDot: View {
    let point: CGPoint
    let pressed: Bool
    var body: some View {
        Circle()
            .fill(Color(hex: 0x6B7280).opacity(0.3))
            .overlay(Circle().stroke(.white, lineWidth: 2.5))
            .frame(width: 46, height: 46)
            .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
            .scaleEffect(pressed ? 0.78 : 1)
            .position(point)
            .allowsHitTesting(false)
            .transition(.opacity)
    }
}
