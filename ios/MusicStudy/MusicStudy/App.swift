import SwiftUI

@main
struct MusicStudyApp: App {
    // Launch with `-style 1...4 -demo YES` to auto-play the recording sequence.
    private let style = max(1, UserDefaults.standard.integer(forKey: "style"))
    private let demo = UserDefaults.standard.bool(forKey: "demo")

    var body: some Scene {
        WindowGroup { RootView(style: style, isDemo: demo) }
    }
}

/// Every app's state is a function of `step`: the demo taps the target for
/// step N+1 (registered with `.demoTap`) and then advances.
@MainActor
final class Demo: ObservableObject {
    @Published var appeared = false
    @Published var step = 0
    @Published var touch: CGPoint?
    @Published var pressed = false
    @Published var pressingStep = 0
    /// Red square used only to line up recordings. Cropped out of the final video.
    @Published var syncMarker = false
    /// When each step happened, for animations that run on a clock.
    var stepDate: [Int: Date] = [:]
    var frames: [String: CGRect] = [:]

    func advance() {
        stepDate[step + 1] = Date()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { step += 1 }
    }

    /// `script` holds the pause before each step.
    func run(script: [Double]) async {
        try? await Task.sleep(for: .seconds(1.5))
        syncMarker = true
        try? await Task.sleep(for: .seconds(0.5))
        syncMarker = false
        appeared = true
        let t0 = Date()
        for pause in script {
            try? await Task.sleep(for: .seconds(pause))
            await tap(step + 1)
        }
        // Every app holds until the same moment, so the four recordings end together.
        try? await Task.sleep(for: .seconds(max(1.2, 16.6 - Date().timeIntervalSince(t0))))
        appeared = false
    }

    private func tap(_ n: Int) async {
        guard let f = frames["s\(n)"] else { advance(); return }
        pressingStep = n
        withAnimation(.easeOut(duration: 0.12)) { touch = CGPoint(x: f.midX, y: f.midY); pressed = true }
        try? await Task.sleep(for: .milliseconds(140))
        advance()
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.easeOut(duration: 0.2)) { pressed = false }
        try? await Task.sleep(for: .milliseconds(160))
        withAnimation(.easeOut(duration: 0.2)) { touch = nil }
    }
}

struct RootView: View {
    @StateObject private var demo = Demo()
    let style: Int
    let isDemo: Bool

    var body: some View {
        Group {
            if isDemo {
                app(style)
            } else {
                TabView {
                    ForEach(1...4, id: \.self) { app($0) }
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
            if isDemo { await demo.run(script: Self.scripts[style - 1]) } else {
                try? await Task.sleep(for: .milliseconds(300))
                demo.appeared = true
            }
        }
    }

    static let scripts: [[Double]] = [PlatterApp.script, TapeApp.script, MonoApp.script, PulseApp.script]

    @ViewBuilder private func app(_ s: Int) -> some View {
        switch s {
        case 2: TapeApp()
        case 3: MonoApp()
        case 4: PulseApp()
        default: PlatterApp()
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
