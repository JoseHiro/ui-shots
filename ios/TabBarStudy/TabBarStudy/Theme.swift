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
    case liquidGlass = 1, brutalNotch, voltTrack, boardingPass
    var id: Int { rawValue }
    var name: String {
        switch self {
        case .liquidGlass: "Liquid Glass"
        case .brutalNotch: "Brutal Notch"
        case .voltTrack: "Volt Track"
        case .boardingPass: "Boarding Pass"
        }
    }
}

/// A flat, offset shadow in the neo-brutalist style.
extension View {
    func hardShadow<S: Shape>(_ shape: S, x: CGFloat = 4, y: CGFloat = 4) -> some View {
        background(shape.fill(.black).offset(x: x, y: y))
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
