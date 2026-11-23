import SwiftUI

/// Water: pick a record from the crate, the water rises over the deck and the record
/// plays under it. Every kick sends a ring out from the spindle, the sleeve standing
/// behind is mirrored in the surface, the breakdown rains on it, and a finger on the
/// water makes its own ripple.
struct WaterApp: View {
    static let script: [Double] = [2.0, 1.0, 5.6, 5.0, 6.6]
    @EnvironmentObject var demo: Demo

    private let ink = Color(hex: 0x0B0F1D)
    private let surface: CGFloat = 392
    private let platterC = CGPoint(x: 201, y: 562)
    /// Where the demo finger touches the water (steps 3, 4, 5).
    private let touches: [CGPoint] = [CGPoint(x: 84, y: 452), CGPoint(x: 330, y: 700), CGPoint(x: 96, y: 690)]

    struct Cover {
        let colors: [UInt32]
        let ink: UInt32
    }
    static let covers: [Cover] = [
        Cover(colors: [0xA5DAE6, 0x5BA4C0, 0x2F6F96], ink: 0x0E2233),
        Cover(colors: [0xF9C4D0, 0xF4A7BB, 0xE88EA6], ink: 0x2A1420),
        Cover(colors: [0xF5EAD0, 0xEBD6A8, 0xD9B878], ink: 0x3A2A12),
        Cover(colors: [0xD6CCF7, 0xA898EA, 0x7E6CD6], ink: 0x1E1640),
    ]

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let rise = smooth(ramp(now, demo.stepDate[1], delay: 0.15, dur: 1.1))
                let top = 874 - (874 - surface) * rise
                scene(now: now, t: t, lv: lv, size: g.size, top: top, rise: rise)
                    .layerEffect(ShaderLibrary.water(.float2(g.size), .float(now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)),
                                                     .float(top), .floatArray(ripples(t: t, now: now)),
                                                     .float(0.25 + lv.hat * 0.25 + lv.energy * 0.35 + lv.build * 0.6), .float(0)),
                                 maxSampleOffset: CGSize(width: 24, height: 24))
            }
        }
        .background(ink)
        .ignoresSafeArea()
    }

    /// Rings from the spindle on every kick, from the needle on claps, raindrops in the
    /// breakdown, and the demo finger's touches.
    private func ripples(t: Double?, now: Date) -> [Float] {
        var r: [Float] = []
        let c = platterC
        if let t, t >= 0 {
            let b = Int(floor(t / Beat.spb))
            for k in max(0, b - 5)...b {
                let lb = Double(k).truncatingRemainder(dividingBy: Beat.loop)
                let sec = Beat.section(lb)
                let age = Float(t - Double(k) * Beat.spb)
                if sec == 3 {
                    // Rain: one drop per beat somewhere on the water, two as it builds.
                    for d in 0..<(lb >= 36 ? 2 : 1) {
                        let x = 40 + hash01(k * 7 + d, 1) * 322
                        let y = Double(surface) + 40 + hash01(k * 7 + d, 2) * 330
                        r += [Float(x), Float(y), age - Float(d) * 0.25, 1.3]
                    }
                } else {
                    r += [Float(c.x), Float(c.y), age, Float([1.6, 2.2, 2.8, 0, 3.2][sec])]
                    if sec == 2 || sec == 4, k % 2 == 1 {
                        r += [Float(c.x + 96), Float(c.y - 70), age, 1.2]
                    }
                }
            }
        }
        for (i, s) in [3, 4, 5].enumerated() {
            if let d = demo.stepDate[s] {
                r += [Float(touches[i].x), Float(touches[i].y), Float(now.timeIntervalSince(d)), 3.4]
            }
        }
        return r.isEmpty ? [0, 0, -1, 0] : r
    }

    @ViewBuilder
    private func scene(now: Date, t: Double?, lv: Beat.Levels, size: CGSize, top: CGFloat, rise: Double) -> some View {
        let pick = smooth(ramp(now, demo.stepDate[1], dur: 0.8))
        let player = ramp(now, demo.stepDate[1], delay: 0.45, dur: 0.7)
        ZStack {
            ink
            LinearGradient(colors: [Color(hex: 0x1B2340), ink], startPoint: .top, endPoint: .center)
            crate.opacity(1 - pick)
            Group {
                header.position(x: 201, y: 74)
                titleBlock.position(x: 201, y: 352)
            }
            .opacity(player)
            .reveal(0)
            // Under the water.
            Group {
                platter(now: now).position(platterC)
                tonearm(now: now).position(x: platterC.x + 128, y: platterC.y - 128)
                progress(t: t).position(x: 201, y: 742)
                controls(lv: lv).position(x: 201, y: 800)
            }
            .opacity(rise)
            .offset(y: (1 - rise) * 80)
            .reveal(2)
            // The sleeve mirrored in the water.
            sleeveArt(demo.track, 220)
                .scaleEffect(x: 1, y: -1)
                .mask(LinearGradient(colors: [.white.opacity(0.36), .white.opacity(0.06), .clear], startPoint: .top, endPoint: .bottom))
                .blendMode(.screen)
                .position(x: 201, y: top + (top - 320) + 116)
                .opacity(rise)
                .allowsHitTesting(false)
                .reveal(1)
            // The chosen sleeve flies from the crate to its stand.
            hero(pick: pick)
            // Touch targets on the water itself.
            ForEach(Array(touches.enumerated()), id: \.0) { i, p in
                Color.clear.frame(width: 60, height: 60).demoTap(i + 3).position(p)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    // MARK: Crate

    private func gridPoint(_ i: Int) -> CGPoint { CGPoint(x: i % 2 == 0 ? 110 : 292, y: i < 2 ? 300 : 530) }

    private var crate: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("TIDE RECORDS").font(.system(size: 11, weight: .bold)).tracking(4).foregroundStyle(.white.opacity(0.45))
                Text("Pick a record").font(.custom("Didot", size: 36)).foregroundStyle(.white)
                Text("4 albums · tap one to put it on").font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .position(x: 201, y: 128)
            .reveal(0)
            ForEach(0..<4, id: \.self) { i in
                let p = gridPoint(i)
                VStack(spacing: 10) {
                    Group {
                        if i == demo.track { Color.clear } else { sleeveArt(i, 160).shadow(color: .black.opacity(0.45), radius: 12, y: 8) }
                    }
                    .frame(width: 160, height: 160)
                    VStack(spacing: 2) {
                        Text(Beat.library[i].title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                        Text(Beat.library[i].artist).font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
                    }
                }
                .modifier(Pick(i: i))
                .position(x: p.x, y: p.y + 24)
                .reveal(1 + i)
            }
            Text("Now spinning in 2,418 rooms").font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.35))
                .position(x: 201, y: 790)
                .reveal(5)
        }
    }

    private func hero(pick: Double) -> some View {
        let from = gridPoint(demo.track), to = CGPoint(x: 201, y: 210)
        let x = from.x + (to.x - from.x) * pick
        let y = from.y + (to.y - from.y) * pick - sin(.pi * pick) * 30
        let s = (160 + 60 * pick) / 220
        return sleeveArt(demo.track, 220)
            .shadow(color: .black.opacity(0.55), radius: 18, y: 12)
            .scaleEffect(s)
            .rotation3DEffect(.degrees(sin(.pi * pick) * 14), axis: (x: 1, y: 0, z: 0))
            .position(x: x, y: y)
            .reveal(demo.step == 0 ? 2 : 1)
            .allowsHitTesting(false)
    }

    /// A square album sleeve: gradient, a motif and the title.
    private func sleeveArt(_ i: Int, _ size: CGFloat) -> some View {
        let c = Self.covers[i], k = size / 220, tr = Beat.library[i]
        return ZStack {
            RoundedRectangle(cornerRadius: 5 * k).fill(LinearGradient(colors: c.colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing))
            motif(i, k).foregroundStyle(Color(hex: c.ink).opacity(0.22))
            VStack(spacing: 6 * k) {
                Spacer()
                Text(tr.title.uppercased()).font(.custom("Didot", size: 25 * k)).tracking(4 * k)
                Rectangle().frame(width: 90 * k, height: 0.8)
                Text(tr.artist).font(.custom("Didot-Italic", size: 13 * k))
            }
            .foregroundStyle(Color(hex: c.ink))
            .padding(.bottom, 18 * k)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder private func motif(_ m: Int, _ k: CGFloat) -> some View {
        switch m {
        case 0:
            VStack(spacing: 9 * k) {
                ForEach(0..<6, id: \.self) { j in
                    Capsule().frame(width: (150 - CGFloat(j) * 14) * k, height: 3 * k)
                }
            }
            .offset(y: -36 * k)
        case 1:
            Circle().frame(width: 110 * k, height: 110 * k)
                .mask(Rectangle().frame(width: 110 * k, height: 55 * k).offset(y: -27.5 * k))
                .offset(y: -22 * k)
        case 2:
            ZStack {
                Circle().frame(width: 92 * k, height: 92 * k)
                Circle().fill(Color(hex: 0xF0E2C2)).frame(width: 92 * k, height: 92 * k).offset(x: 26 * k, y: -10 * k)
            }
            .offset(y: -38 * k)
        default:
            ZStack {
                ForEach(0..<6, id: \.self) { j in
                    Capsule().frame(width: 22 * k, height: 70 * k).offset(y: -30 * k).rotationEffect(.degrees(Double(j) * 60))
                }
            }
            .offset(y: -36 * k)
        }
    }

    // MARK: Player

    private var header: some View {
        HStack {
            Image(systemName: "chevron.down").font(.system(size: 17, weight: .semibold))
            Spacer()
            VStack(spacing: 2) {
                Text("PLAYING FROM").font(.system(size: 10, weight: .semibold)).tracking(2).opacity(0.5)
                Text("Tide Records").font(.system(size: 14, weight: .semibold))
            }
            Spacer()
            Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 26)
    }

    private var titleBlock: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(demo.chosen.title).font(.custom("Didot", size: 24)).foregroundStyle(.white)
                Text(demo.chosen.artist.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(2).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "heart.fill").font(.system(size: 20)).foregroundStyle(Color(hex: Self.covers[demo.track].colors[1]))
        }
        .padding(.horizontal, 30)
    }

    private func platter(now: Date) -> some View {
        let spin = Motor(demo.stepDate[Beat.playStep].map { [($0, 0.55)] } ?? [], tau: 0.6).state(at: now).pos
        let c = Self.covers[demo.track]
        return ZStack {
            Circle().fill(Color(hex: 0x1C2236)).frame(width: 300, height: 300)
            Circle().fill(Color(hex: 0x07080D)).frame(width: 284, height: 284)
            ForEach(0..<17, id: \.self) { i in
                Circle().stroke(Color.white.opacity(i % 3 == 0 ? 0.07 : 0.035), lineWidth: 0.8)
                    .frame(width: 274 - CGFloat(i) * 10, height: 274 - CGFloat(i) * 10)
            }
            Circle().fill(AngularGradient(colors: [.clear, .white.opacity(0.10), .clear, .clear, .white.opacity(0.07), .clear], center: .center))
                .frame(width: 284, height: 284)
            ZStack {
                Circle().fill(LinearGradient(colors: c.colors.map { Color(hex: $0) }, startPoint: .top, endPoint: .bottom)).frame(width: 98, height: 98)
                Text(demo.chosen.title.uppercased()).font(.custom("Didot", size: 10)).tracking(2).offset(y: -22)
                Text("A · 33⅓").font(.custom("Didot", size: 9)).offset(y: 24)
            }
            .foregroundStyle(Color(hex: c.ink))
            .rotationEffect(.degrees(spin * 360))
            Circle().fill(Color(hex: 0xC9CCD6)).frame(width: 9, height: 9)
        }
    }

    private func tonearm(now: Date) -> some View {
        let arm = ramp(now, demo.stepDate[Beat.playStep], dur: 0.7)
        return ZStack(alignment: .top) {
            Circle().fill(Color(hex: 0x2A3046)).frame(width: 50, height: 50)
            Circle().fill(Color(hex: 0xB8BCC8)).frame(width: 22, height: 22).offset(y: 14)
            RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xC9CCD6)).frame(width: 5, height: 190).offset(y: 25)
            RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0xDDE0E8)).frame(width: 16, height: 30).offset(y: 202)
        }
        .frame(width: 50, height: 240, alignment: .top)
        .rotationEffect(.degrees(4 + 22 * arm), anchor: UnitPoint(x: 0.5, y: 25 / 240))
        .offset(y: 95)
    }

    private func progress(t: Double?) -> some View {
        let p = Progress(t: t)
        return VStack(spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15)).frame(height: 4)
                Capsule().fill(.white.opacity(0.85)).frame(width: max(4, 312 * p.fraction), height: 4)
            }
            .frame(width: 312)
            HStack {
                Text(p.elapsed)
                Spacer()
                Text(p.remaining)
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.5))
            .frame(width: 312)
        }
    }

    private func controls(lv: Beat.Levels) -> some View {
        HStack(spacing: 26) {
            Image(systemName: "shuffle").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            glass("backward.fill", 48)
            glass(demo.step >= Beat.playStep ? "pause.fill" : "play.fill", 70)
                .scaleEffect(demo.isPressing(Beat.playStep) ? 0.88 : 1 + lv.kick * 0.05)
                .demoTap(Beat.playStep)
            glass("forward.fill", 48)
            Image(systemName: "repeat").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
        }
    }

    private func glass(_ icon: String, _ d: CGFloat) -> some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.06)], startPoint: .top, endPoint: .bottom))
            Circle().stroke(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom), lineWidth: 1.2)
            Image(systemName: icon).font(.system(size: d * 0.34, weight: .bold)).foregroundStyle(.white)
        }
        .frame(width: d, height: d)
    }
}

/// Makes a library item pickable: the demo's song registers as step 1, the others can be
/// tapped by hand.
struct Pick: ViewModifier {
    @EnvironmentObject var demo: Demo
    let i: Int
    func body(content: Content) -> some View {
        if i == Beat.demoTrack {
            content.demoTap(1)
        } else {
            content.contentShape(Rectangle()).onTapGesture { demo.choose(i) }
        }
    }
}
