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
        await scrubChart([0.16, 0.88, 0.58], steps: [84, 38])
        try? await Task.sleep(for: .seconds(0.35))
        await tap("seg2") { self.setRange(2) }
        try? await Task.sleep(for: .seconds(1.4))
        await scrubChart([0.9, 0.22, 0.5], steps: [90, 40])
        try? await Task.sleep(for: .seconds(0.6))
        await tap("seg0") { self.setRange(0) }
        try? await Task.sleep(for: .seconds(1.4))
        await scrubChart([0.3, 0.74], steps: [70])
        try? await Task.sleep(for: .seconds(1.2))
        // Leave the way it came in, so the video loops back to its first frame.
        appeared = false
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

    private func scrubChart(_ stops: [CGFloat], steps: [Int]) async {
        guard let f = frames["chart"] else { return }
        let pt = { (s: CGFloat) in CGPoint(x: f.minX + s * f.width, y: f.minY + f.height * 0.82) }
        withAnimation(.easeOut(duration: 0.12)) { touch = pt(stops[0]); pressed = true }
        scrub = stops[0]
        try? await Task.sleep(for: .milliseconds(180))
        for k in 0..<steps.count {
            await glide(from: stops[k], to: stops[k + 1], steps: steps[k], pt: pt)
        }
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
