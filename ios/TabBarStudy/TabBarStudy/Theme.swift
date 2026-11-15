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

enum Theme {
    static let bg = Color(hex: 0xF3F1FA)
    static let ink = Color(hex: 0x2B2840)
    static let muted = Color(hex: 0x9C99B3)
    static let lavender = Color(hex: 0x8B7CF6)
    static let lavenderDeep = Color(hex: 0x6D5CE8)
    static let mint = Color(hex: 0x1FB37F)
    static let peach = Color(hex: 0xF5A524)
    static let pink = Color(hex: 0xF7739B)
    static let sky = Color(hex: 0x4AA8F0)
}

struct TabItem: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let color: Color
}

let tabs: [TabItem] = [
    TabItem(id: 0, title: "Home", icon: "house", color: Theme.lavender),
    TabItem(id: 1, title: "Search", icon: "magnifyingglass", color: Theme.sky),
    TabItem(id: 2, title: "Saved", icon: "heart", color: Theme.pink),
    TabItem(id: 3, title: "Profile", icon: "person", color: Theme.mint),
]

func symbol(_ t: TabItem, filled: Bool) -> String {
    filled && t.icon != "magnifyingglass" ? t.icon + ".fill" : t.icon
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
