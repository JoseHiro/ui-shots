import SwiftUI

/// Isle: a pastel isometric island. Picking a spot flies the camera in and the
/// building pops up out of the ground; the last step draws the day's route.
struct IsleApp: View {
    @EnvironmentObject var demo: Demo

    static let sky = Color(hex: 0xEAF6F4)
    static let deep = Color(hex: 0x23545C)
    static let teal = Color(hex: 0x2BA39A)
    static let coral = Color(hex: 0xF28B6E)
    static func round(_ s: CGFloat, _ w: Font.Weight = .bold) -> Font { .system(size: s, weight: w, design: .rounded) }

    /// Pause before each step: lighthouse, onsen, café, route.
    static let script: [Double] = [1.9, 2.9, 2.9, 2.9]

    // Island heights, row j by column i: 0 water, 1 sand, 2 grass, 3 hill.
    static let heights: [[Int]] = [
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 1, 0, 0, 0, 0],
        [0, 1, 2, 2, 2, 1, 1, 0, 0],
        [0, 1, 2, 3, 3, 2, 2, 1, 0],
        [0, 1, 2, 3, 3, 2, 2, 1, 0],
        [0, 0, 1, 2, 2, 2, 2, 1, 0],
        [0, 0, 1, 2, 2, 2, 1, 1, 0],
        [0, 0, 0, 1, 1, 1, 1, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ]
    static let tw: CGFloat = 40, th: CGFloat = 20, hu: CGFloat = 9
    static let mapSize = CGSize(width: 402, height: 500)
    static let origin = CGPoint(x: 201, y: 150)

    static func iso(_ i: Double, _ j: Double, _ h: CGFloat) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(i - j) * tw / 2, y: origin.y + CGFloat(i + j) * th / 2 - h)
    }
    /// Center of the top of tile (i, j).
    static func top(_ i: Int, _ j: Int) -> CGPoint {
        iso(Double(i) + 0.5, Double(j) + 0.5, CGFloat(heights[j][i]) * hu)
    }

    static let spots = [(4, 1), (3, 3), (2, 6)]   // lighthouse, onsen, café
    static let trees = [(2, 2, 0), (6, 3, 1), (5, 5, 0), (6, 4, 0), (4, 6, 1), (2, 3, 1), (5, 2, 2), (3, 5, 0), (6, 6, 2)]

    struct Info { let title: String; let text: String; let meta: String; let symbol: String; let color: Color }
    static let infos = [
        Info(title: "Nagi Island", text: "Capes, hot springs and slow mornings.", meta: "3 days · 3 spots", symbol: "map.fill", color: teal),
        Info(title: "Cape Lighthouse", text: "Built in 1903. Climb 98 steps for sunrise.", meta: "Day 1 · 05:40", symbol: "sun.horizon.fill", color: coral),
        Info(title: "Hilltop Onsen", text: "Open-air bath with a view of both coasts.", meta: "Day 1 · 16:00", symbol: "drop.fill", color: Color(hex: 0x4FB3D9)),
        Info(title: "Shore Café", text: "Grilled fish set and shaved ice on the sand.", meta: "Day 2 · 12:30", symbol: "cup.and.saucer.fill", color: Color(hex: 0xE0A43B)),
        Info(title: "Your route", text: "Lighthouse → Onsen → Café", meta: "6.2 km · 1h 40m on foot", symbol: "figure.walk", color: teal),
    ]

    private var focus: (CGPoint, CGFloat) {
        guard (1...3).contains(demo.step) else { return (CGPoint(x: Self.origin.x, y: Self.origin.y + 92), 1.32) }
        let (i, j) = Self.spots[demo.step - 1]
        let p = Self.top(i, j)
        return (CGPoint(x: p.x, y: p.y - 18), 2.0)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Self.sky.ignoresSafeArea()
            VStack(spacing: 0) {
                header.reveal(0).padding(.horizontal, 20)
                map.reveal(1).padding(.top, 8)
                card.reveal(2).padding(.horizontal, 20).padding(.top, -34)
                chips.reveal(3).padding(.horizontal, 20).padding(.top, 14)
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Isle").font(Self.round(36, .heavy)).foregroundStyle(Self.deep)
                Text("Nagi Island · Seto Sea").font(Self.round(14, .semibold)).foregroundStyle(Self.deep.opacity(0.5))
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill").foregroundStyle(Color(hex: 0xF5B83D))
                Text("24°").font(Self.round(17)).foregroundStyle(Self.deep)
            }
            .padding(.horizontal, 12).frame(height: 36)
            .background(Capsule().fill(.white))
        }
    }

    private var map: some View {
        let (c, zoom) = focus
        let mc = CGPoint(x: Self.mapSize.width / 2, y: Self.mapSize.height / 2)
        return TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                Water(t: t)
                Terrain()
                Boat(t: t)
                ForEach(0..<Self.trees.count, id: \.self) { k in
                    let (i, j, kind) = Self.trees[k]
                    Tree(kind: kind)
                        .scaleEffect(demo.appeared ? 1 : 0.01, anchor: .bottom)
                        .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.5 + Double(k) * 0.06), value: demo.appeared)
                        .position(x: Self.top(i, j).x, y: Self.top(i, j).y - 13)
                }
                ForEach(0..<3, id: \.self) { k in spot(k, t: t) }
                route
            }
            .frame(width: Self.mapSize.width, height: Self.mapSize.height)
            .scaleEffect(zoom)
            .offset(x: (mc.x - c.x) * zoom, y: (mc.y - c.y) * zoom)
            .animation(.spring(response: 1.15, dampingFraction: 0.86), value: demo.step)
        }
        .frame(width: Self.mapSize.width, height: Self.mapSize.height)
        .clipped()
        .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .init(x: 0.5, y: 0.08)))
    }

    @ViewBuilder private func spot(_ k: Int, t: Double) -> some View {
        let (i, j) = Self.spots[k]
        let p = Self.top(i, j)
        let built = demo.step >= k + 1
        Group {
            switch k {
            case 0: Lighthouse(t: t)
            case 1: Onsen(t: t)
            default: Cafe()
            }
        }
        .scaleEffect(x: built ? 1 : 0.4, y: built ? 1 : 0.01, anchor: .bottom)
        .opacity(built ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.5).delay(built ? 0.55 : 0), value: built)
        .position(x: p.x, y: p.y - (k == 0 ? 40 : k == 1 ? 6 : 18))
        // A bobbing pin until it is built.
        Circle().fill(Self.coral).frame(width: 14, height: 14)
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(color: Self.deep.opacity(0.3), radius: 3, y: 2)
            .offset(y: -10 - 4 * abs(sin(t * 2.6 + Double(k))))
            .opacity(built ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: built)
            .position(p)
        // Route badge.
        Text("\(k + 1)").font(Self.round(12, .heavy)).foregroundStyle(.white)
            .frame(width: 22, height: 22).background(Circle().fill(Self.deep))
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .scaleEffect(demo.step >= 4 ? 1 : 0.01)
            .animation(.spring(response: 0.4, dampingFraction: 0.55).delay(0.6 + Double(k) * 0.45), value: demo.step >= 4)
            .position(x: p.x + 18, y: p.y - (k == 0 ? 78 : 30))
    }

    private var route: some View {
        let pts = Self.spots.map { Self.top($0.0, $0.1) }
        return Path { p in
            p.move(to: pts[0])
            p.addQuadCurve(to: pts[1], control: CGPoint(x: (pts[0].x + pts[1].x) / 2 + 40, y: (pts[0].y + pts[1].y) / 2 + 10))
            p.addQuadCurve(to: pts[2], control: CGPoint(x: (pts[1].x + pts[2].x) / 2 + 30, y: (pts[1].y + pts[2].y) / 2 + 30))
        }
        .trim(from: 0, to: demo.step >= 4 ? 1 : 0)
        .stroke(Self.deep, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 7]))
        .animation(.easeInOut(duration: 1.5).delay(0.5), value: demo.step >= 4)
    }

    private var card: some View {
        let info = Self.infos[min(demo.step, 4)]
        return HStack(spacing: 14) {
            Image(systemName: info.symbol).font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14).fill(info.color))
            VStack(alignment: .leading, spacing: 3) {
                Text(info.title).font(Self.round(19, .heavy)).foregroundStyle(Self.deep)
                Text(info.text).font(Self.round(13, .medium)).foregroundStyle(Self.deep.opacity(0.6))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(info.meta).font(Self.round(12, .bold)).foregroundStyle(info.color)
            }
            Spacer(minLength: 0)
        }
        .id(demo.step)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        .padding(14)
        .frame(height: 96)
        .background(RoundedRectangle(cornerRadius: 22).fill(.white))
        .shadow(color: Self.deep.opacity(0.15), radius: 16, y: 8)
        .clipped()
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(Array(["Lighthouse", "Onsen", "Café", "Route"].enumerated()), id: \.offset) { k, name in
                let on = demo.step == k + 1
                Text(name).font(Self.round(14, .bold))
                    .foregroundStyle(on ? .white : Self.deep)
                    .frame(maxWidth: .infinity).frame(height: 42)
                    .background(Capsule().fill(on ? Self.deep : .white))
                    .overlay(Capsule().stroke(Self.deep.opacity(on ? 0 : 0.12), lineWidth: 1))
                    .scaleEffect(demo.isPressing(k + 1) ? 0.92 : 1)
                    .demoTap(k + 1)
            }
        }
    }
}

// MARK: - Terrain

private struct Water: View {
    let t: Double
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x8ED6E6)))
            // Shallows around the island, breathing slowly.
            let grow = 1.28 + 0.05 * sin(t * 1.3)
            for (j, row) in IsleApp.heights.enumerated() {
                for (i, h) in row.enumerated() where h > 0 {
                    let c = IsleApp.iso(Double(i) + 0.5, Double(j) + 0.5, -2)
                    let dx = IsleApp.tw / 2 * grow, dy = IsleApp.th / 2 * grow
                    var p = Path()
                    p.move(to: CGPoint(x: c.x, y: c.y - dy)); p.addLine(to: CGPoint(x: c.x + dx, y: c.y))
                    p.addLine(to: CGPoint(x: c.x, y: c.y + dy)); p.addLine(to: CGPoint(x: c.x - dx, y: c.y))
                    ctx.fill(p, with: .color(Color(hex: 0xB9ECF3)))
                }
            }
            // Little wave glints drifting across.
            for k in 0..<26 {
                let fx = Double((k * 37) % 100) / 100, fy = Double((k * 61) % 100) / 100
                let x = (fx * Double(size.width) + t * 9).truncatingRemainder(dividingBy: Double(size.width) + 40) - 20
                let y = fy * Double(size.height)
                let a = 0.5 + 0.5 * sin(t * 1.7 + Double(k))
                ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: 14, height: 2.5), cornerRadius: 1.25), with: .color(.white.opacity(0.55 * a)))
            }
        }
    }
}

private struct Terrain: View {
    var body: some View {
        Canvas { ctx, _ in
            let tops = [Color.clear, Color(hex: 0xF4DDA8), Color(hex: 0x9ED17F), Color(hex: 0x86C36B)]
            let lefts = [Color.clear, Color(hex: 0xE2C48A), Color(hex: 0xC99D6C), Color(hex: 0xC99D6C)]
            let rights = [Color.clear, Color(hex: 0xD2B276), Color(hex: 0xB4875A), Color(hex: 0xB4875A)]
            let cells = (0..<9).flatMap { j in (0..<9).map { i in (i, j) } }.sorted { $0.0 + $0.1 < $1.0 + $1.1 }
            for (i, j) in cells {
                let l = IsleApp.heights[j][i]
                guard l > 0 else { continue }
                let h = CGFloat(l) * IsleApp.hu
                let di = Double(i), dj = Double(j)
                let a = IsleApp.iso(di, dj, h), b = IsleApp.iso(di + 1, dj, h)
                let c = IsleApp.iso(di + 1, dj + 1, h), d = IsleApp.iso(di, dj + 1, h)
                let b0 = IsleApp.iso(di + 1, dj, -5), c0 = IsleApp.iso(di + 1, dj + 1, -5), d0 = IsleApp.iso(di, dj + 1, -5)
                ctx.fill(poly([d, c, c0, d0]), with: .color(lefts[l]))
                ctx.fill(poly([c, b, b0, c0]), with: .color(rights[l]))
                ctx.fill(poly([a, b, c, d]), with: .color(tops[l]))
                if (i + j) % 2 == 0 { ctx.fill(poly([a, b, c, d]), with: .color(.white.opacity(0.08))) }
            }
        }
    }

    private func poly(_ pts: [CGPoint]) -> Path {
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        return p
    }
}

private struct Boat: View {
    let t: Double
    var body: some View {
        let a = t * 0.32
        let c = IsleApp.iso(4.5, 4.5, 0)
        let x = c.x + 205 * cos(a), y = c.y + 112 * sin(a)
        let flip: CGFloat = -sin(a) > 0 ? 1 : -1
        ZStack {
            Capsule().fill(.white.opacity(0.6)).frame(width: 26, height: 4).offset(x: -16 * flip, y: 6)
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: 26, y: 0))
                p.addLine(to: CGPoint(x: 21, y: 7)); p.addLine(to: CGPoint(x: 4, y: 7)); p.closeSubpath()
            }
            .fill(Color(hex: 0xF28B6E)).frame(width: 26, height: 7).offset(y: 3)
            Triangle().fill(.white).frame(width: 14, height: 18).offset(x: 2, y: -10)
        }
        .scaleEffect(x: flip, y: 1)
        .position(x: x, y: y)
    }
}

private struct Tree: View {
    let kind: Int
    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle().fill(Color(hex: 0x9A6B47)).frame(width: 3, height: 8)
            switch kind {
            case 0:
                Circle().fill(Color(hex: 0x5FAE55)).frame(width: 18, height: 18).offset(y: -6)
                    .overlay(Circle().fill(.white.opacity(0.25)).frame(width: 6, height: 6).offset(x: -3, y: -10))
            case 1:
                VStack(spacing: -6) {
                    Triangle().fill(Color(hex: 0x3F9460)).frame(width: 13, height: 12)
                    Triangle().fill(Color(hex: 0x3F9460)).frame(width: 17, height: 13)
                }
                .offset(y: -6)
            default:
                Capsule().fill(Color(hex: 0x6FBF63)).frame(width: 18, height: 6).rotationEffect(.degrees(-30)).offset(x: -5, y: -16)
                Capsule().fill(Color(hex: 0x6FBF63)).frame(width: 18, height: 6).rotationEffect(.degrees(30)).offset(x: 5, y: -16)
                Rectangle().fill(Color(hex: 0x9A6B47)).frame(width: 2.5, height: 18)
            }
        }
        .frame(width: 24, height: 28, alignment: .bottom)
    }
}

// MARK: - Buildings

/// An isometric box with a pyramid roof, drawn from its footprint.
private struct IsoHouse: View {
    let a: CGFloat, b: CGFloat, h: CGFloat, roof: CGFloat
    let wall: Color, roofColor: Color
    var body: some View {
        Canvas { ctx, size in
            let o = CGPoint(x: size.width / 2, y: size.height - 2 - (a + b) * IsleApp.th / 2)
            func pt(_ i: CGFloat, _ j: CGFloat, _ z: CGFloat) -> CGPoint {
                CGPoint(x: o.x + (i - j) * IsleApp.tw / 2, y: o.y + (i + j) * IsleApp.th / 2 - z)
            }
            func poly(_ ps: [CGPoint]) -> Path { var p = Path(); p.addLines(ps); p.closeSubpath(); return p }
            let n = pt(-a, -b, h), e = pt(a, -b, h), s = pt(a, b, h), w = pt(-a, b, h)
            let e0 = pt(a, -b, 0), s0 = pt(a, b, 0), w0 = pt(-a, b, 0)
            ctx.fill(poly([w, s, s0, w0]), with: .color(wall))
            ctx.fill(poly([s, e, e0, s0]), with: .color(wall.opacity(0.82)))
            ctx.fill(poly([pt(-a * 0.3, b, 0), pt(-a * 0.3, b, h * 0.55), pt(a * 0.15, b, h * 0.55), pt(a * 0.15, b, 0)]),
                     with: .color(IsleApp.deep.opacity(0.75)))
            let apex = pt(0, 0, h + roof)
            let ov: CGFloat = 1.18
            let rn = pt(-a * ov, -b * ov, h), re = pt(a * ov, -b * ov, h), rs = pt(a * ov, b * ov, h), rw = pt(-a * ov, b * ov, h)
            _ = n; _ = e; _ = s; _ = w
            ctx.fill(poly([rn, re, apex]), with: .color(roofColor.opacity(0.9)))
            ctx.fill(poly([rn, rw, apex]), with: .color(roofColor.opacity(0.95)))
            ctx.fill(poly([rw, rs, apex]), with: .color(roofColor))
            ctx.fill(poly([rs, re, apex]), with: .color(roofColor.opacity(0.78)))
        }
    }
}

private struct Cafe: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            IsoHouse(a: 0.34, b: 0.3, h: 20, roof: 15, wall: Color(hex: 0xFFF6E8), roofColor: IsleApp.coral)
                .frame(width: 40, height: 52)
            // A striped beach umbrella beside it.
            VStack(spacing: 0) {
                Circle().trim(from: 0.5, to: 1).fill(Color(hex: 0x4FB3D9)).frame(width: 20, height: 20)
                    .overlay(Circle().trim(from: 0.66, to: 0.83).fill(.white).frame(width: 20, height: 20))
                    .frame(height: 10, alignment: .top)
                Rectangle().fill(Color(hex: 0x9A6B47)).frame(width: 1.5, height: 12)
            }
            .offset(x: 26, y: 4)
        }
        .frame(width: 70, height: 56)
    }
}

private struct Lighthouse: View {
    let t: Double
    var body: some View {
        ZStack(alignment: .bottom) {
            // Sweeping beam: its length follows the cosine of the turn, so it reads as rotating.
            let c = cos(t * 1.6)
            Canvas { ctx, size in
                let lamp = CGPoint(x: size.width / 2, y: size.height - 57)
                let ex = lamp.x + CGFloat(c) * 78, spread = 6 + 8 * CGFloat(abs(c))
                var p = Path()
                p.move(to: lamp)
                p.addLine(to: CGPoint(x: ex, y: lamp.y - spread))
                p.addLine(to: CGPoint(x: ex, y: lamp.y + spread))
                p.closeSubpath()
                ctx.fill(p, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFF2A8).opacity(0.9), Color(hex: 0xFFF2A8).opacity(0)]),
                                                  startPoint: lamp, endPoint: CGPoint(x: ex, y: lamp.y)))
            }
            VStack(spacing: 0) {
                Triangle().fill(Color(hex: 0xD9503D)).frame(width: 16, height: 9)
                Circle().fill(Color(hex: 0xFFE98A)).frame(width: 10, height: 10)
                    .shadow(color: Color(hex: 0xFFD54A), radius: 6)
                Rectangle().fill(Color(hex: 0x3A4A52)).frame(width: 18, height: 3)
                Tower().frame(width: 18, height: 50)
            }
        }
        .frame(width: 170, height: 82)
    }
}

private struct Tower: View {
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            p.move(to: CGPoint(x: size.width * 0.18, y: 0)); p.addLine(to: CGPoint(x: size.width * 0.82, y: 0))
            p.addLine(to: CGPoint(x: size.width, y: size.height)); p.addLine(to: CGPoint(x: 0, y: size.height)); p.closeSubpath()
            ctx.fill(p, with: .color(.white))
            ctx.clip(to: p)
            for k in 0..<3 {
                let y = CGFloat(k) * size.height / 3 + size.height / 9
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: size.height / 6)), with: .color(Color(hex: 0xE8604C)))
            }
            ctx.fill(Path(CGRect(x: size.width / 2, y: 0, width: size.width / 2, height: size.height)), with: .color(.black.opacity(0.1)))
        }
    }
}

private struct Onsen: View {
    let t: Double
    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height - 12)
                func diamond(_ s: CGFloat) -> Path {
                    var p = Path()
                    p.move(to: CGPoint(x: c.x, y: c.y - IsleApp.th / 2 * s)); p.addLine(to: CGPoint(x: c.x + IsleApp.tw / 2 * s, y: c.y))
                    p.addLine(to: CGPoint(x: c.x, y: c.y + IsleApp.th / 2 * s)); p.addLine(to: CGPoint(x: c.x - IsleApp.tw / 2 * s, y: c.y)); p.closeSubpath()
                    return p
                }
                ctx.fill(diamond(0.9), with: .color(Color(hex: 0x9AA3A0)))
                ctx.fill(diamond(0.72), with: .color(Color(hex: 0x6FCBE3)))
                ctx.fill(diamond(0.4), with: .color(.white.opacity(0.25 + 0.15 * sin(t * 2))))
            }
            .frame(width: 44, height: 40)
            // Steam.
            ForEach(0..<3, id: \.self) { k in
                let f = (t * 0.45 + Double(k) / 3).truncatingRemainder(dividingBy: 1)
                Capsule().fill(.white.opacity(0.75 * (1 - f)))
                    .frame(width: 5 + 6 * f, height: 12 + 8 * f)
                    .offset(x: CGFloat(k - 1) * 9 + CGFloat(sin(f * 6 + Double(k))) * 3, y: -CGFloat(f) * 34 - 6)
                    .blur(radius: 1.5 + 2 * f)
            }
        }
        .frame(width: 44, height: 40)
    }
}
