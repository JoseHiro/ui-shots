import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

func gradient(_ a: UInt32, _ b: UInt32) -> LinearGradient {
    LinearGradient(colors: [Color(hex: a), Color(hex: b)], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct TabItem: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let iconOn: String
    let color: Color

    func symbol(_ on: Bool) -> String { on ? iconOn : icon }
}

enum BarStyle: Int, CaseIterable, Identifiable {
    case liquidDock = 1, bubbleNotch, softPill, colorChips
    var id: Int { rawValue }
    var name: String {
        switch self {
        case .liquidDock: "Liquid Dock"
        case .bubbleNotch: "Bubble Notch"
        case .softPill: "Soft Pill"
        case .colorChips: "Color Chips"
        }
    }
    var app: String {
        switch self {
        case .liquidDock: "Wave · Music"
        case .bubbleNotch: "Bento · Food"
        case .softPill: "Pulse · Fitness"
        case .colorChips: "Roam · Travel"
        }
    }
}

// Each tab reports its frame so the demo can draw a touch at the right spot.
struct TabFramesKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func tabFrame(_ id: Int) -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: TabFramesKey.self, value: [id: g.frame(in: .named("screen"))])
        })
    }
}
