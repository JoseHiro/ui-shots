import SwiftUI

/// Honey: a band of honey along the top of the screen, slowly dripping. The records sit in
/// a cluster of comb cells. The chosen cell moves to the middle, and once the song plays the
/// drips stretch down over its sleeve on the beat, let go, and fill a pool at the bottom.
/// A touch drops a dab of honey that slides slowly down the sleeve.
struct HoneyApp: View {
    @EnvironmentObject var demo: Demo

    private let centre = CGPoint(x: 201, y: 365)
    private let top: CGFloat = 100
    private let touches: [CGPoint] = [CGPoint(x: 132, y: 300), CGPoint(x: 280, y: 392), CGPoint(x: 172, y: 446)]
    private let brown = Color(hex: 0x3A1E04)
    private let cream = Color(hex: 0xFFF4D8)

    static let covers: [Theme.Cover] = [
        Theme.Cover(colors: [0xF6B79A, 0xE07B55, 0xB8512F], ink: 0x2E1206),
        Theme.Cover(colors: [0xFFF8E8, 0xF4E6C4, 0xE6CF9C], ink: 0x4A3214),
        Theme.Cover(colors: [0xD7E3C0, 0xA9BF8A, 0x7A9562], ink: 0x24301A),
        Theme.Cover(colors: [0x3B2A1E, 0x2A1C12, 0x160E08], ink: 0xF2C46A),
    ]

    // Seven drip lanes: where they hang, how short and long they get, how many beats one
    // drip takes, and the beat it starts on.
    private let laneX: [CGFloat] = [34, 92, 146, 206, 258, 316, 370]
    private let lMin: [CGFloat] = [18, 26, 14, 24, 20, 16, 22]
    private let lMax: [CGFloat] = [150, 300, 240, 360, 270, 330, 170]
    private let cycle: [Double] = [7, 6, 9, 5, 8, 6, 7]
    private let offset: [Double] = [0.5, 2, 1, 3.5, 0, 4.5, 2.5]

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let pick = smooth(ramp(now, demo.stepDate[1], dur: 1.3))
                let player = ramp(now, demo.stepDate[1], delay: 0.8, dur: 0.7)
                let time = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)
                let pool = 846 - 44 * CGFloat(Progress(t: t).fraction)
                let (el, land) = honey(t: t, now: now, lv: lv, pool: pool)
                ZStack {
                    ZStack {
                        Color(hex: 0xFBF1DC)
                        Honeycomb().stroke(Color(hex: 0xB9760F).opacity(0.08), lineWidth: 1.2)
                        RadialGradient(colors: [.clear, Color(hex: 0xC98A2A).opacity(0.18)], center: .center, startRadius: 200, endRadius: 560)
                        ForEach(0..<4, id: \.self) { i in
                            let pl = place(i, pick: pick, lv: lv)
                            cell(i, pl.r).scaleEffect(pl.s).opacity(pl.a).position(pl.at).zIndex(i == demo.track ? 1 : 0)
                        }
                    }
                    .frame(width: g.size.width, height: g.size.height)
                    .drawingGroup()
                    .layerEffect(ShaderLibrary.honey(.float2(g.size), .float(time), .float(top), .float(pool), .floatArray(el), .floatArray(land)),
                                 maxSampleOffset: CGSize(width: 20, height: 20))
                    .reveal(1)
                    header(pick: pick)
                    titleBlock.position(x: 201, y: 576).opacity(player).reveal(2)
                    Group {
                        progress(t: t).position(x: 201, y: 636)
                        controls(lv: lv).position(x: 201, y: 706)
                    }
                    .opacity(player)
                    .reveal(3)
                    Text("Tap a comb to play it")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(brown.opacity(0.5))
                        .position(x: 201, y: 790).opacity(1 - pick).reveal(5)
                    ForEach(0..<4, id: \.self) { i in
                        Color.clear.frame(width: 100, height: 110).modifier(PickIf(i: i)).position(grid(i))
                    }
                    ForEach(Array(touches.enumerated()), id: \.0) { i, p in
                        Color.clear.frame(width: 60, height: 60).demoTap(i + 3).position(p)
                    }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .ignoresSafeArea()
    }

    /// A diamond of four comb cells.
    private func grid(_ i: Int) -> CGPoint {
        [CGPoint(x: 201, y: 300), CGPoint(x: 139, y: 408), CGPoint(x: 263, y: 408), CGPoint(x: 201, y: 516)][i]
    }

    private func place(_ i: Int, pick: Double, lv: Beat.Levels) -> (at: CGPoint, r: CGFloat, s: Double, a: Double) {
        let g = grid(i)
        if i == demo.track {
            let m = CGFloat(pick)
            return (CGPoint(x: g.x + (centre.x - g.x) * m, y: g.y + (centre.y - g.y) * m), 66 + 70 * m, 1 + lv.kick * 0.015, 1)
        }
        let out = CGFloat(smooth(pick * 1.3))
        let dir = CGPoint(x: g.x - 201, y: g.y - 408)
        return (CGPoint(x: g.x + dir.x * out * 1.2, y: g.y + dir.y * out * 1.2), 66, 1 - smooth(pick * 1.4) * 0.6, 1 - smooth(pick * 1.4))
    }

    /// The honey's shapes (drips, falling drops and dabs) and where drops hit the pool.
    private func honey(t: Double?, now: Date, lv: Beat.Levels, pool: CGFloat) -> ([Float], [Float]) {
        var el: [Float] = [], land: [Float] = []
        func cone(_ a: CGPoint, _ b: CGPoint, _ r1: CGFloat, _ r2: CGFloat) {
            el += [Float(a.x), Float(a.y), Float(b.x), Float(b.y), Float(r1), Float(r2)]
        }
        let b = (t ?? -1) / Beat.spb
        for i in 0..<7 {
            let x = laneX[i]
            let ph = b - offset[i]
            var L = lMin[i]
            if t != nil, ph >= 0 {
                let c = cycle[i], secs = c * Beat.spb
                let n = floor(ph / c), u = ph / c - n
                let span = lMax[i] - lMin[i]
                let from = top + lMax[i]
                let sLand = (-60 + sqrt(3600 + 3000 * Double(pool - from))) / 1500
                if u < 0.72 {
                    L = lMin[i] + span * CGFloat(pow(u / 0.72, 1.7))
                } else {
                    let s = (u - 0.72) * secs
                    L = lMin[i] + span * 0.3 * CGFloat(exp(-s * 4))
                    if s < sLand {
                        let y = from + CGFloat(750 * s * s + 60 * s)
                        let r = 10 + CGFloat(lv.kick * 2)
                        cone(CGPoint(x: x, y: y - r * 1.4), CGPoint(x: x, y: y), r * 0.6, r)
                    } else {
                        land += [Float(x), Float(s - sLand), 14]
                    }
                }
                if n >= 1 {
                    // The drop from the drip before, still settling into the pool.
                    let s = (u + 0.28) * secs
                    land += [Float(x), Float(s - sLand), 14]
                }
            }
            L += CGFloat(sin(Double(i) * 1.7 + now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000) * 0.9)) * 2
            let tip = top + L
            let rb = 8 + 4 * min(1, L / 160) + CGFloat(lv.kick * 2.5)
            cone(CGPoint(x: x, y: top - 6), CGPoint(x: x, y: max(top - 6, tip - rb * 0.7)), 13, 4.5)
            cone(CGPoint(x: x, y: tip), CGPoint(x: x, y: tip), rb, rb)
        }
        for (i, s) in [3, 4, 5].enumerated() {
            guard let d = demo.stepDate[s] else { continue }
            let age = now.timeIntervalSince(d)
            let r = 22 * CGFloat(1 - exp(-age * 8))
            let slide = CGFloat(8 * age + 24 * (1 - exp(-age * 1.5)))
            let p = touches[i]
            cone(CGPoint(x: p.x, y: p.y - 4), CGPoint(x: p.x, y: p.y + slide), r * 0.55, r)
        }
        return (el, land.isEmpty ? [0, -1, 0] : land)
    }

    // MARK: Chrome

    private func cell(_ i: Int, _ r: CGFloat) -> some View {
        let c = Self.covers[i], tr = Beat.library[i]
        let k = r / 136
        return ZStack {
            Hexagon().fill(LinearGradient(colors: c.colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing))
            Motif(m: i, k: k * 1.2).foregroundStyle(Color(hex: c.ink).opacity(0.2)).offset(y: -6 * k)
            VStack(spacing: 4 * k) {
                Text(tr.title).font(.custom("Baskerville-SemiBoldItalic", size: max(13, 30 * k)))
                Text(tr.artist.uppercased()).font(.system(size: max(7, 10 * k), weight: .bold)).tracking(2 * k)
            }
            .foregroundStyle(Color(hex: c.ink))
            .offset(y: 46 * k)
            Hexagon().stroke(Color(hex: 0x8A4A06).opacity(0.35), lineWidth: 2)
        }
        .frame(width: r * sqrt(3), height: r * 2)
        .shadow(color: Color(hex: 0x6E3604).opacity(0.25), radius: 12, y: 8)
    }

    private func header(pick: Double) -> some View {
        ZStack {
            Text("APIARY").font(.system(size: 12, weight: .heavy)).tracking(6).foregroundStyle(cream)
                .position(x: 201, y: 72)
                .opacity(1 - pick)
            HStack {
                Text("APIARY").font(.system(size: 12, weight: .heavy)).tracking(6)
                Spacer()
                Text("RAW · 120 BPM").font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(cream)
            .padding(.horizontal, 26)
            .position(x: 201, y: 72)
            .opacity(smooth((pick - 0.5) / 0.5))
            VStack(spacing: 8) {
                Text("Pick a comb").font(.custom("Baskerville-SemiBoldItalic", size: 36)).foregroundStyle(brown)
                Text("Every cell holds a record").font(.system(size: 13)).foregroundStyle(brown.opacity(0.55))
            }
            .position(x: 201, y: 176)
            .opacity(1 - pick)
        }
        .reveal(0)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(demo.chosen.title).font(.custom("Baskerville-SemiBoldItalic", size: 34)).foregroundStyle(brown)
            Text(demo.chosen.artist.uppercased()).font(.system(size: 11, weight: .bold)).tracking(3).foregroundStyle(brown.opacity(0.55))
        }
    }

    private func progress(t: Double?) -> some View {
        let p = Progress(t: t)
        return HStack(spacing: 12) {
            Text(p.elapsed)
            ZStack(alignment: .leading) {
                Capsule().fill(brown.opacity(0.12)).frame(height: 6)
                Capsule().fill(LinearGradient(colors: [Color(hex: 0xF7BE48), Color(hex: 0xC9700C)], startPoint: .top, endPoint: .bottom))
                    .frame(width: max(6, 220 * p.fraction), height: 6)
            }
            .frame(width: 220)
            Text(p.remaining)
        }
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .foregroundStyle(brown.opacity(0.55))
    }

    private func controls(lv: Beat.Levels) -> some View {
        HStack(spacing: 30) {
            bead("backward.fill", 46)
            bead(demo.step >= Beat.playStep ? "pause.fill" : "play.fill", 70)
                .scaleEffect(demo.isPressing(Beat.playStep) ? 0.88 : 1 + lv.kick * 0.05)
                .demoTap(Beat.playStep)
            bead("forward.fill", 46)
        }
    }

    /// A round bead of honey.
    private func bead(_ icon: String, _ d: CGFloat) -> some View {
        ZStack {
            Hexagon().fill(RadialGradient(colors: [Color(hex: 0xFFE2A0), Color(hex: 0xF0AE3A), Color(hex: 0xB86A0C)],
                                          center: UnitPoint(x: 0.4, y: 0.3), startRadius: 2, endRadius: d * 0.7))
            Ellipse().fill(.white.opacity(0.55)).frame(width: d * 0.36, height: d * 0.14).offset(x: -d * 0.1, y: -d * 0.26).blur(radius: 1.5)
            Image(systemName: icon).font(.system(size: d * 0.32, weight: .bold)).foregroundStyle(brown)
        }
        .frame(width: d * 0.94, height: d)
        .shadow(color: Color(hex: 0x6E3604).opacity(0.4), radius: 8, y: 5)
    }
}

/// A pointy-topped hexagon filling its frame.
struct Hexagon: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let rad = min(r.width / sqrt(3), r.height / 2)
        for k in 0..<6 {
            let a = (-90 + Double(k) * 60) * .pi / 180
            let pt = CGPoint(x: r.midX + rad * cos(a), y: r.midY + rad * sin(a))
            if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}
