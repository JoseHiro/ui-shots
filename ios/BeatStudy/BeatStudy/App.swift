import SwiftUI

@main
struct BeatStudyApp: App {
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
    /// When the app finished its entrance, for clock-driven intros.
    var appearDate: Date?
    /// When each step happened, for animations that run on a clock.
    var stepDate: [Int: Date] = [:]
    var frames: [String: CGRect] = [:]
    /// The song picked on the first screen. The demo always picks the one the video's
    /// soundtrack is rendered from.
    @Published var track = Beat.demoTrack

    /// Picking a song by hand (the demo taps the row registered with `.demoTap(1)`).
    func choose(_ i: Int) {
        guard step == 0 else { return }
        track = i
        advance()
    }

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
        appearDate = Date()
        appeared = true
        let t0 = Date()
        for pause in script {
            try? await Task.sleep(for: .seconds(pause))
            await tap(step + 1)
        }
        // Every app leaves on the same beat of the music (just before the song ends), so the
        // four recordings end together. Polled rather than one long sleep, which can wake late.
        let end = max(Date().addingTimeInterval(1.2), (stepDate[Beat.playStep] ?? t0).addingTimeInterval(Beat.length - 0.2))
        while Date() < end { try? await Task.sleep(for: .milliseconds(20)) }
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
        // By hand the music really plays; the recording gets its sound from video/track.py.
        .onChange(of: demo.step) { _, s in if s >= Beat.playStep && !isDemo { BeatPlayer.shared.start(track: demo.track) } }
        .task {
            if isDemo { await demo.run(script: Self.scripts[style - 1]) } else {
                try? await Task.sleep(for: .milliseconds(300))
                demo.appearDate = Date()
                demo.appeared = true
            }
        }
    }

    static let scripts: [[Double]] = [WaterApp.script, SandApp.script, FerroApp.script, FireApp.script]

    @ViewBuilder private func app(_ s: Int) -> some View {
        switch s {
        case 2: SandApp()
        case 3: FerroApp()
        case 4: FireApp()
        default: WaterApp()
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
