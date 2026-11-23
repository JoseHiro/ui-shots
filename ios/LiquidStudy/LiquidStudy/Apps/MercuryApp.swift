import SwiftUI

/// Mercury: four chrome droplets on a dark table, each holding a record. Picking one rolls
/// the others into it and they melt into a single pool, which then mirrors the sleeve
/// hanging above it. Every kick sends a ring through the metal and bends the reflection.
struct MercuryApp: View {
    @EnvironmentObject var demo: Demo

    private let centre = CGPoint(x: 201, y: 400)
    private let poolR: CGFloat = 150
    private let dropR: CGFloat = 32
    private let touches: [CGPoint] = [CGPoint(x: 140, y: 352), CGPoint(x: 268, y: 462), CGPoint(x: 176, y: 466)]
    private let ink = Color(hex: 0xF2F3F5)

    static let covers: [Theme.Cover] = [
        Theme.Cover(colors: [0xF4F5F7, 0xC9CDD4, 0x9AA0AA], ink: 0x15171B),
        Theme.Cover(colors: [0xFFB37A, 0xFF6A2B, 0xD9400F], ink: 0x2A0E02),
        Theme.Cover(colors: [0x8FB2FF, 0x3E6BEA, 0x1C3FA8], ink: 0xF2F5FF),
        Theme.Cover(colors: [0xC6F26B, 0x7CC21A, 0x3C6A08], ink: 0x10200A),
    ]

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let pick = smooth(ramp(now, demo.stepDate[1], dur: 1.4))
                let player = ramp(now, demo.stepDate[1], delay: 0.8, dur: 0.7)
                let time = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)
                ZStack {
                    RadialGradient(colors: [Color(hex: 0x30333B), Color(hex: 0x0B0C0F)], center: UnitPoint(x: 0.5, y: 0.45), startRadius: 20, endRadius: 560)
                    // Soft glow of the strip lights on the table.
                    Ellipse().fill(.white.opacity(0.05)).frame(width: 360, height: 360).blur(radius: 60).position(centre)
                    Rectangle().fill(.white)
                        .colorEffect(ShaderLibrary.mercury(.float2(g.size), .float(time), .float3(201, 437, 1400), .float(260),
                                                           .float2(centre), .float(225), .image(SleeveImage.image(demo.track)),
                                                           .float(smooth((pick - 0.5) / 0.5)),
                                                           .floatArray(drops(pick: pick, time: time, lv: lv)), .floatArray(ripples(t: t, now: now))))
                        .reveal(1)
                    labels.opacity(1 - pick)
                    header(pick: pick)
                    titleBlock.position(x: 201, y: 616).opacity(player).reveal(2)
                    Group {
                        progress(t: t).position(x: 201, y: 692)
                        controls(lv: lv).position(x: 201, y: 764)
                    }
                    .opacity(player)
                    .reveal(3)
                    Text("Tap a drop to play it")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(ink.opacity(0.5))
                        .position(x: 201, y: 790).opacity(1 - pick).reveal(5)
                    ForEach(0..<4, id: \.self) { i in
                        Color.clear.frame(width: 80, height: 110).modifier(PickIf(i: i)).position(x: grid(i).x, y: grid(i).y + 20)
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

    private func grid(_ i: Int) -> CGPoint { CGPoint(x: [62, 154, 248, 340][i], y: 420) }

    /// x, y, radius and tint for each droplet: a row of four, then all rolling into the
    /// chosen one, which swells into the pool and throbs with the kick.
    private func drops(pick: Double, time: Double, lv: Beat.Levels) -> [Float] {
        var out: [Float] = []
        let p = CGFloat(pick)
        for i in 0..<4 {
            let g = grid(i)
            let wob = CGFloat(sin(time * 2.1 + Double(i) * 1.9)) * 1.5
            var at: CGPoint, r: CGFloat
            if i == demo.track {
                let m = CGFloat(smooth(pick / 0.7))
                at = CGPoint(x: g.x + (centre.x - g.x) * m, y: g.y + (centre.y - g.y) * m)
                r = dropR + (poolR - dropR) * CGFloat(smooth((pick - 0.3) / 0.7)) + wob + CGFloat(lv.kick * 6 + lv.bass * 3)
            } else {
                let m = CGFloat(smooth(pick * 1.25))
                at = CGPoint(x: g.x + (centre.x - g.x) * m, y: g.y + (centre.y - g.y) * m - sin(.pi * min(1, p * 1.25)) * 30)
                r = dropR * (1 - CGFloat(smooth((pick - 0.45) / 0.45))) + wob
            }
            let c = Self.covers[i].colors[1]
            out += [Float(at.x), Float(at.y + CGFloat(sin(time * 1.4 + Double(i))) * 2), Float(r),
                    Float((c >> 16) & 0xFF) / 255, Float((c >> 8) & 0xFF) / 255, Float(c & 0xFF) / 255]
        }
        return out
    }

    /// Rings through the pool on every kick, beside the centre on claps, rain in the
    /// breakdown, a splash as the drops merge, and the touches.
    private func ripples(t: Double?, now: Date) -> [Float] {
        var r: [Float] = []
        if let t, t >= 0 {
            let b = Int(floor(t / Beat.spb))
            for k in max(0, b - 5)...b {
                let lb = Double(k).truncatingRemainder(dividingBy: Beat.loop)
                let sec = Beat.section(lb)
                let age = Float(t - Double(k) * Beat.spb)
                if sec == 3 {
                    for d in 0..<(lb >= 36 ? 2 : 1) {
                        let a = hash01(k * 7 + d, 1) * 2 * .pi, rr = hash01(k * 7 + d, 2) * 110
                        r += [Float(centre.x + cos(a) * rr), Float(centre.y + sin(a) * rr), age - Float(d) * 0.25, 1.6]
                    }
                } else {
                    r += [Float(centre.x), Float(centre.y), age, Float([2.0, 2.6, 3.2, 0, 3.6][sec])]
                    if sec == 2 || sec == 4, k % 2 == 1 {
                        let side: Float = k % 4 == 1 ? -1 : 1
                        r += [Float(centre.x) + side * 80, Float(centre.y) + 50, age, 1.8]
                    }
                }
            }
        }
        if let d = demo.stepDate[1] { r += [Float(centre.x), Float(centre.y), Float(now.timeIntervalSince(d)) - 1.0, 3.0] }
        for (i, s) in [3, 4, 5].enumerated() {
            if let d = demo.stepDate[s] {
                r += [Float(touches[i].x), Float(touches[i].y), Float(now.timeIntervalSince(d)), 3.4]
            }
        }
        return r.isEmpty ? [0, 0, -1, 0] : r
    }

    // MARK: Chrome

    private var labels: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                VStack(spacing: 3) {
                    Text(Beat.library[i].title).font(.system(size: 12, weight: .bold)).foregroundStyle(ink)
                    Text(Beat.library[i].artist).font(.system(size: 10, weight: .medium)).foregroundStyle(ink.opacity(0.45))
                }
                .fixedSize()
                .position(x: grid(i).x, y: 486)
                .reveal(2 + i)
            }
        }
    }

    private func header(pick: Double) -> some View {
        ZStack {
            VStack(spacing: 8) {
                Text("QUICKSILVER").font(.system(size: 11, weight: .bold)).tracking(5).foregroundStyle(ink.opacity(0.45))
                Text("Pick a drop").font(.custom("HelveticaNeue-CondensedBlack", size: 40)).foregroundStyle(ink)
                Text("Each one holds a record").font(.system(size: 13)).foregroundStyle(ink.opacity(0.45))
            }
            .position(x: 201, y: 150)
            .opacity(1 - pick)
            HStack {
                Text("QUICKSILVER").font(.system(size: 12, weight: .heavy)).tracking(4)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: 0xFF4B3A)).frame(width: 7, height: 7)
                    Text("LIVE · 120 BPM").font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().stroke(ink.opacity(0.3), lineWidth: 1))
            }
            .foregroundStyle(ink)
            .padding(.horizontal, 26)
            .position(x: 201, y: 78)
            .opacity(smooth((pick - 0.5) / 0.5))
        }
        .reveal(0)
    }

    private var titleBlock: some View {
        VStack(spacing: 6) {
            Text(demo.chosen.title.uppercased()).font(.custom("HelveticaNeue-CondensedBlack", size: 34)).tracking(1).foregroundStyle(ink)
            Text("\(demo.chosen.artist) · Side A").font(.system(size: 13, weight: .medium)).foregroundStyle(ink.opacity(0.5))
        }
    }

    private func progress(t: Double?) -> some View {
        let p = Progress(t: t)
        return HStack(spacing: 12) {
            Text(p.elapsed)
            ZStack(alignment: .leading) {
                Capsule().fill(ink.opacity(0.15)).frame(height: 2)
                Capsule().fill(LinearGradient(colors: [Color(hex: 0x9AA0AA), .white], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(2, 220 * p.fraction), height: 2)
                Circle().fill(LinearGradient(colors: [.white, Color(hex: 0x8E949E)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 12, height: 12).offset(x: 220 * p.fraction - 6)
            }
            .frame(width: 220)
            Text(p.remaining)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(ink.opacity(0.5))
    }

    private func controls(lv: Beat.Levels) -> some View {
        HStack(spacing: 30) {
            chrome("backward.fill", 46)
            chrome(demo.step >= Beat.playStep ? "pause.fill" : "play.fill", 68)
                .scaleEffect(demo.isPressing(Beat.playStep) ? 0.88 : 1 + lv.kick * 0.05)
                .demoTap(Beat.playStep)
            chrome("forward.fill", 46)
        }
    }

    private func chrome(_ icon: String, _ d: CGFloat) -> some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0x9EA4AE), Color(hex: 0xE6E9ED), Color(hex: 0x6E747E)],
                                         startPoint: .top, endPoint: .bottom))
            Circle().inset(by: 3).stroke(.white.opacity(0.7), lineWidth: 1)
            Image(systemName: icon).font(.system(size: d * 0.34, weight: .black)).foregroundStyle(Color(hex: 0x15171B))
        }
        .frame(width: d, height: d)
        .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
    }
}

/// The sleeves rendered once to images, for the metal to reflect.
@MainActor
enum SleeveImage {
    private static var cache: [Int: Image] = [:]

    static func image(_ i: Int) -> Image {
        if let im = cache[i] { return im }
        let r = ImageRenderer(content: MercurySleeve(i: i))
        r.scale = 2
        let im = r.uiImage.map { Image(uiImage: $0) } ?? Image(systemName: "square")
        cache[i] = im
        return im
    }
}

struct MercurySleeve: View {
    let i: Int
    var body: some View {
        let c = MercuryApp.covers[i], tr = Beat.library[i]
        ZStack {
            Rectangle().fill(LinearGradient(colors: c.colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing))
            Motif(m: i, k: 1).foregroundStyle(Color(hex: c.ink).opacity(0.24))
            VStack(spacing: 6) {
                Spacer()
                Text(tr.title.uppercased()).font(.custom("HelveticaNeue-CondensedBlack", size: 26)).tracking(2)
                Rectangle().frame(width: 90, height: 1)
                Text(tr.artist).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color(hex: c.ink))
            .padding(.bottom, 20)
        }
        .frame(width: 220, height: 220)
    }
}
