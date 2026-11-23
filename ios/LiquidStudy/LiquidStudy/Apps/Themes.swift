import SwiftUI

extension Theme {
    // MARK: Water: a swimming pool, tiles wobbling under clear water.

    static let water = Theme(
        brand: "TIDE RECORDS", font: "Didot", text: Color(hex: 0x0B2A3F), dim: Color(hex: 0x0B2A3F).opacity(0.72), accent: Color(hex: 0x0B2A3F),
        covers: [
            Cover(colors: [0xFFF4D6, 0xFFE0A3, 0xF7C873], ink: 0x3A2A12),
            Cover(colors: [0xF9C4D0, 0xF4A7BB, 0xE88EA6], ink: 0x2A1420),
            Cover(colors: [0x2F6F96, 0x1E4D73, 0x10304D], ink: 0xE6F6FF),
            Cover(colors: [0xD6CCF7, 0xA898EA, 0x7E6CD6], ink: 0x1E1640),
        ],
        shadow: (0.42, 34),
        pool: { _, _ in
            AnyView(ZStack {
                LinearGradient(colors: [Color(hex: 0x8FE3EE), Color(hex: 0x45BCD8), Color(hex: 0x1F8FBA)], startPoint: .top, endPoint: .bottom)
                PoolTiles(size: 30).stroke(Color(hex: 0xE8FBFF).opacity(0.6), lineWidth: 1.2)
                // The lane line along the floor, with its T at the far end.
                Group {
                    Rectangle().frame(width: 22, height: 760).position(x: 201, y: 500)
                    Rectangle().frame(width: 110, height: 22).position(x: 201, y: 131)
                }
                .foregroundStyle(Color(hex: 0x123F7A).opacity(0.75))
                // Deeper toward the bottom of the screen.
                LinearGradient(colors: [.clear, Color(hex: 0x0B5C8A).opacity(0.35)], startPoint: .center, endPoint: .bottom)
            })
        },
        button: { icon, d, primary in
            AnyView(ZStack {
                Circle().fill(.white.opacity(primary ? 0.9 : 0.6))
                Circle().stroke(.white, lineWidth: 1.2)
                Image(systemName: icon).font(.system(size: d * 0.34, weight: .bold)).foregroundStyle(Color(hex: 0x0B2A3F))
            }
            .frame(width: d, height: d)
            .shadow(color: Color(hex: 0x0B2A3F).opacity(0.25), radius: 10, y: 8))
        }
    )
}

/// Square pool tiles.
struct PoolTiles: Shape {
    let size: CGFloat
    func path(in r: CGRect) -> Path {
        var p = Path()
        var x = r.minX
        while x <= r.maxX { p.move(to: CGPoint(x: x, y: r.minY)); p.addLine(to: CGPoint(x: x, y: r.maxY)); x += size }
        var y = r.minY
        while y <= r.maxY { p.move(to: CGPoint(x: r.minX, y: y)); p.addLine(to: CGPoint(x: r.maxX, y: y)); y += size }
        return p
    }
}

/// A faint honeycomb under the honey.
struct Honeycomb: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let s: CGFloat = 26, h = s * sqrt(3)
        var row = 0
        var y = r.minY
        while y < r.maxY + h {
            var x = r.minX + (row % 2 == 0 ? 0 : s * 1.5)
            while x < r.maxX + s * 3 {
                for k in 0..<6 {
                    let a = CGFloat(k) * .pi / 3
                    let pt = CGPoint(x: x + s * cos(a), y: y + s * sin(a))
                    if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
                x += s * 3
            }
            y += h / 2
            row += 1
        }
        return p
    }
}
