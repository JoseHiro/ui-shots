import SwiftUI

@main
struct TabBarStudyApp: App {
    // Launch with `-style 1...4 -demo YES` to auto-play a tap sequence for recording.
    private let style = BarStyle(rawValue: UserDefaults.standard.integer(forKey: "style")) ?? .liquidDock
    private let demo = UserDefaults.standard.bool(forKey: "demo")

    var body: some Scene {
        WindowGroup {
            RootView(style: style, isDemo: demo)
        }
    }
}

@MainActor
final class Demo: ObservableObject {
    @Published var selection = 0
    @Published var touch: CGPoint?
    @Published var pressed = false
    /// Red square in the top corner, used only to line up recordings. Cropped out of the final video.
    @Published var syncMarker = false
    var frames: [Int: CGRect] = [:]

    static let sequence = [1, 2, 3, 0, 2, 3, 1, 0]

    func run() async {
        try? await Task.sleep(for: .seconds(3.0))
        syncMarker = true
        try? await Task.sleep(for: .seconds(0.5))
        syncMarker = false
        for i in Self.sequence {
            await tap(i)
            try? await Task.sleep(for: .seconds(0.85))
        }
    }

    private func tap(_ i: Int) async {
        guard let f = frames[i] else { return }
        withAnimation(.easeOut(duration: 0.12)) { touch = CGPoint(x: f.midX, y: f.midY) }
        withAnimation(.easeOut(duration: 0.12)) { pressed = true }
        try? await Task.sleep(for: .milliseconds(130))
        selection = i
        try? await Task.sleep(for: .milliseconds(130))
        withAnimation(.easeOut(duration: 0.2)) { pressed = false }
        try? await Task.sleep(for: .milliseconds(140))
        withAnimation(.easeOut(duration: 0.2)) { touch = nil }
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
