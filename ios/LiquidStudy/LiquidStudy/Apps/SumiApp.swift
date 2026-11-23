import SwiftUI

/// Ink: suminagashi on washi. Each record is a little marbled target of its own ink. Picking
/// one floats it to the middle, and from then on every kick drops more ink (or clear water)
/// into its centre, pushing the older rings outward. Touches swirl the rings.
struct SumiApp: View {
    @EnvironmentObject var demo: Demo

    private let centre = CGPoint(x: 201, y: 350)
    private let touches: [CGPoint] = [CGPoint(x: 150, y: 330), CGPoint(x: 262, y: 392), CGPoint(x: 182, y: 420)]
    private let ink = Color(hex: 0x17181C)
    private let red = Color(hex: 0xC8432B)

    private static let paper: UInt32 = 0xF4EFE6
    private static let sumi: UInt32 = 0x17181C
    static let inks: [UInt32] = [0x2D3F8F, 0xC8432B, 0x4F7A3C, 0x7B3D72]
    private static let names = ["藍", "朱", "苔", "紫"]

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let pick = smooth(ramp(now, demo.stepDate[1], dur: 1.3))
                let player = ramp(now, demo.stepDate[1], delay: 0.7, dur: 0.7)
                let time = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)
                ZStack {
                    Rectangle().fill(.white)
                        .colorEffect(ShaderLibrary.sumi(.float2(g.size), .float(time), .float3(0.957, 0.937, 0.902),
                                                        .floatArray(ops(pick: pick, now: now, t: t))))
                        .reveal(1)
                    labels.opacity(1 - pick)
                    header(pick: pick)
                    card(t: t, lv: lv).opacity(player)
                    Text("Tap an ink to play it")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(ink.opacity(0.45))
                        .position(x: 201, y: 790).opacity(1 - pick).reveal(5)
                    ForEach(0..<4, id: \.self) { i in
                        Color.clear.frame(width: 110, height: 130).modifier(PickIf(i: i)).position(x: grid(i).x, y: grid(i).y + 20)
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

    private func grid(_ i: Int) -> CGPoint { CGPoint(x: i % 2 == 0 ? 116 : 286, y: i < 2 ? 352 : 548) }

    private func rgb(_ c: UInt32) -> (Float, Float, Float) {
        (Float((c >> 16) & 0xFF) / 255, Float((c >> 8) & 0xFF) / 255, Float(c & 0xFF) / 255)
    }

    private func drop(_ at: CGPoint, _ r: Double, _ c: UInt32, _ alpha: Double = 1) -> [Float] {
        let (cr, cg, cb) = rgb(c)
        return [0, Float(at.x), Float(at.y), Float(max(0, r)), cr, cg, cb, Float(alpha)]
    }

    /// Every drop and swirl so far, oldest first: the four targets, then the beat's drops
    /// and the touches in the order they happened.
    private func ops(pick: Double, now: Date, t: Double?) -> [Float] {
        var out: [Float] = []
        let grow = 1 + 0.65 * pick
        for i in (0..<4).filter({ $0 != demo.track }) + [demo.track] {
            let g = grid(i)
            var at = g, s = 1.0, a = 1.0
            if i == demo.track {
                at = CGPoint(x: g.x + (centre.x - g.x) * pick, y: g.y + (centre.y - g.y) * pick)
                s = grow
            } else {
                s = 1 - smooth((pick - 0.05) / 0.55)
                a = s
            }
            for (k, r) in [40.0, 30, 20, 10].enumerated() {
                out += drop(at, r * s, k % 2 == 0 ? Self.inks[i] : Self.paper, a)
            }
        }
        var timed: [(Double, [Float])] = []
        if let t, t >= 0 {
            let b = Int(floor(t / Beat.spb))
            let own = Self.inks[demo.track]
            for k in 0...b {
                let start = Double(k) * Beat.spb
                let age = t - start
                let lb = Double(k).truncatingRemainder(dividingBy: Beat.loop)
                let sec = Beat.section(lb)
                let open = 1 - exp(-age * 6)
                if sec == 3 {
                    // Breakdown: a light rain of small drops across the rings.
                    for d in 0..<(lb >= 36 ? 2 : 1) {
                        let a = hash01(k * 7 + d, 1) * 2 * .pi, rr = 30 + hash01(k * 7 + d, 2) * 120
                        let p = CGPoint(x: centre.x + cos(a) * rr, y: centre.y + sin(a) * rr)
                        let c = d == 0 ? Self.sumi : own
                        timed.append((start + Double(d) * 0.25, drop(p, (12 + hash01(k, 3) * 6) * (1 - exp(-(age - Double(d) * 0.25) * 6)), c)))
                    }
                } else {
                    let scale = [0.85, 1, 1.15, 0, 1.15][sec]
                    let c = [Self.sumi, Self.paper, own, Self.paper][k % 4]
                    let r = [30.0, 18, 26, 14][k % 4] * scale
                    timed.append((start, drop(centre, r * open, c)))
                    if sec == 2 || sec == 4, k % 2 == 1 {
                        let side: CGFloat = k % 4 == 1 ? -1 : 1
                        timed.append((start + 0.001, drop(CGPoint(x: centre.x + side * 92, y: centre.y + 70), 13 * open, Self.sumi)))
                    }
                }
            }
        }
        if let play = demo.stepDate[Beat.playStep] {
            for (i, s) in [3, 4, 5].enumerated() {
                guard let d = demo.stepDate[s] else { continue }
                let age = now.timeIntervalSince(d)
                let turn = (i % 2 == 0 ? 2.4 : -2.4) * (1 - exp(-age * 2.2))
                timed.append((d.timeIntervalSince(play), [1, Float(touches[i].x), Float(touches[i].y), Float(turn), 0, 0, 0, 72]))
            }
        }
        for (_, v) in timed.sorted(by: { $0.0 < $1.0 }) { out += v }
        return out
    }

    // MARK: Chrome

    private var labels: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                VStack(spacing: 3) {
                    Text(Beat.library[i].title).font(.custom("HiraMinProN-W6", size: 14)).foregroundStyle(ink)
                    Text("\(Self.names[i]) · \(Beat.library[i].artist)").font(.system(size: 10, weight: .medium)).foregroundStyle(ink.opacity(0.5))
                }
                .fixedSize()
                .position(x: grid(i).x, y: grid(i).y + 66)
                .reveal(2 + i)
            }
        }
    }

    private func header(pick: Double) -> some View {
        ZStack {
            VStack(spacing: 10) {
                Text("墨  SUMI FM").font(.system(size: 11, weight: .bold)).tracking(5).foregroundStyle(ink.opacity(0.5))
                Text("Choose an ink").font(.custom("HiraMinProN-W6", size: 34)).foregroundStyle(ink)
                Text("Each ink plays a record").font(.system(size: 13)).foregroundStyle(ink.opacity(0.5))
            }
            .position(x: 201, y: 168)
            .opacity(1 - pick)
            HStack(alignment: .center) {
                Text("墨  SUMI FM").font(.system(size: 12, weight: .heavy)).tracking(4).foregroundStyle(ink)
                Spacer()
                seal("流", 34)
            }
            .padding(.horizontal, 26)
            .position(x: 201, y: 80)
            .opacity(smooth((pick - 0.5) / 0.5))
            Text("墨\n流\nし").font(.custom("HiraMinProN-W3", size: 13)).lineSpacing(6).foregroundStyle(ink.opacity(0.55))
                .position(x: 376, y: 190)
                .opacity(smooth((pick - 0.5) / 0.5))
        }
        .reveal(0)
    }

    private func seal(_ s: String, _ d: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: d * 0.16).fill(red)
            RoundedRectangle(cornerRadius: d * 0.12).inset(by: 2.5).stroke(Color(hex: 0xF4EFE6).opacity(0.7), lineWidth: 1)
            Text(s).font(.custom("HiraMinProN-W6", size: d * 0.52)).foregroundStyle(Color(hex: 0xF4EFE6))
        }
        .frame(width: d, height: d)
        .rotationEffect(.degrees(-4))
    }

    /// A sheet of paper over the bottom with the title and controls.
    private func card(t: Double?, lv: Beat.Levels) -> some View {
        let p = Progress(t: t)
        return ZStack {
            RoundedRectangle(cornerRadius: 30).fill(Color(hex: 0xFBF8F2))
                .overlay(RoundedRectangle(cornerRadius: 30).stroke(ink.opacity(0.08), lineWidth: 1))
                .shadow(color: ink.opacity(0.12), radius: 18, y: -4)
                .frame(width: 402, height: 320)
                .position(x: 201, y: 774)
                .reveal(2)
            VStack(spacing: 6) {
                Text(demo.chosen.title).font(.custom("HiraMinProN-W6", size: 30)).foregroundStyle(ink)
                Text("\(demo.chosen.artist) · \(Self.names[demo.track])の墨").font(.system(size: 13, weight: .medium)).foregroundStyle(ink.opacity(0.5))
            }
            .position(x: 201, y: 672)
            .reveal(2)
            Group {
                HStack(spacing: 12) {
                    Text(p.elapsed)
                    ZStack(alignment: .leading) {
                        Capsule().fill(ink.opacity(0.12)).frame(height: 3)
                        Capsule().fill(ink).frame(width: max(3, 230 * p.fraction), height: 3)
                        Circle().fill(red).frame(width: 9, height: 9).offset(x: 230 * p.fraction - 4.5)
                    }
                    .frame(width: 230)
                    Text(p.remaining)
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(ink.opacity(0.5))
                .position(x: 201, y: 740)
                HStack(spacing: 46) {
                    Image(systemName: "backward.end.fill").font(.system(size: 22)).foregroundStyle(ink)
                    seal("", 66)
                        .overlay(Image(systemName: demo.step >= Beat.playStep ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .bold)).foregroundStyle(Color(hex: 0xF4EFE6)))
                        .scaleEffect(demo.isPressing(Beat.playStep) ? 0.88 : 1 + lv.kick * 0.05)
                        .demoTap(Beat.playStep)
                    Image(systemName: "forward.end.fill").font(.system(size: 22)).foregroundStyle(ink)
                }
                .position(x: 201, y: 806)
            }
            .reveal(3)
        }
    }
}
