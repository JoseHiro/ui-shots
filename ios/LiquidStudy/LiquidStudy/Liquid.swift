import SwiftUI

/// What makes each app different: its liquid, what shows in it, and its records.
struct Theme {
    struct Cover {
        let colors: [UInt32]
        let ink: UInt32
    }
    var brand: String
    var font: String
    var text: Color
    var dim: Color
    var accent: Color
    var covers: [Cover]
    /// How dark the floating cover's shadow is on the liquid, and how far it falls.
    var shadow: (Double, CGFloat)
    /// What is seen in or under the liquid (full screen). Bent by the ripples.
    var pool: (_ lv: Beat.Levels, _ now: Date) -> AnyView
    var button: (_ icon: String, _ d: CGFloat, _ primary: Bool) -> AnyView
}

/// The shared stage: the whole screen is a pool of liquid seen from above. Four records
/// float on it; picking one (step 1) sinks the others and floats it to the middle, play
/// (step 2) starts the song and every kick rings out from under the record, steps 3-5
/// touch the surface.
struct LiquidStage: View {
    static let script: [Double] = [2.0, 1.0, 5.6, 5.0, 6.6]
    @EnvironmentObject var demo: Demo
    let theme: Theme

    private let centre = CGPoint(x: 201, y: 372)
    private let big: CGFloat = 250
    private let touches: [CGPoint] = [CGPoint(x: 340, y: 196), CGPoint(x: 66, y: 610), CGPoint(x: 336, y: 600)]

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let pick = smooth(ramp(now, demo.stepDate[1], dur: 1.0))
                let player = ramp(now, demo.stepDate[1], delay: 0.55, dur: 0.7)
                ZStack {
                    ZStack {
                        theme.pool(lv, now)
                        // Shadows and colored light of the floating covers, bent by the waves.
                        ForEach(0..<4, id: \.self) { i in
                            let p = place(i, pick: pick, now: now, lv: lv)
                            ZStack {
                                RoundedRectangle(cornerRadius: 14).fill(Color(hex: theme.covers[i].colors[1]).opacity(0.35))
                                    .frame(width: p.size * 1.25, height: p.size * 1.25).blur(radius: 30)
                                RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x06324A).opacity(theme.shadow.0))
                                    .frame(width: p.size, height: p.size).blur(radius: 12).offset(x: theme.shadow.1 * 0.6, y: theme.shadow.1)
                            }
                            .opacity(p.alpha)
                            .position(p.at)
                            .reveal(1 + i)
                        }
                    }
                    .frame(width: g.size.width, height: g.size.height)
                    .drawingGroup()
                    .layerEffect(ShaderLibrary.water(.float2(g.size), .float(now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)),
                                                     .floatArray(ripples(t: t, now: now)),
                                                     .float(lv.hat * 0.5 + lv.energy * 0.6 + lv.build * 0.8)),
                                 maxSampleOffset: CGSize(width: 30, height: 30))
                    // The floating records.
                    ForEach([0, 2, 3, 1].sorted { z($0) < z($1) }, id: \.self) { i in
                        let p = place(i, pick: pick, now: now, lv: lv)
                        sleeve(i, p.size)
                            .rotationEffect(.degrees(p.tilt))
                            .blur(radius: p.sink * 6)
                            .opacity(p.alpha)
                            .modifier(PickIf(i: i))
                            .position(p.at)
                            .reveal(1 + i)
                    }
                    header(pick: pick).position(x: 201, y: 118)
                    titleBlock.position(x: 201, y: 556).opacity(player).reveal(2)
                    Group {
                        progress(t: t).position(x: 201, y: 680)
                        controls(lv: lv).position(x: 201, y: 752)
                    }
                    .offset(y: sin(now.timeIntervalSinceReferenceDate * 1.7) * 1.5 - lv.kick * 2)
                    .opacity(player)
                    .reveal(3)
                    Text("Tap a record to play it")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(theme.dim)
                        .position(x: 201, y: 790).opacity(1 - pick).reveal(5)
                    ForEach(Array(touches.enumerated()), id: \.0) { i, p in
                        Color.clear.frame(width: 60, height: 60).demoTap(i + 3).position(p)
                    }
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Liquid

    private func grid(_ i: Int) -> CGPoint { CGPoint(x: i % 2 == 0 ? 112 : 290, y: i < 2 ? 318 : 520) }

    /// Rings from under the record on every kick, from beside it on claps, rain in the
    /// breakdown, splashes where records sink and where play is pressed, and the touches.
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
                        let x = 30 + hash01(k * 7 + d, 1) * 342
                        let y = 90 + hash01(k * 7 + d, 2) * 700
                        r += [Float(x), Float(y), age - Float(d) * 0.25, 1.4]
                    }
                } else {
                    r += [Float(centre.x), Float(centre.y), age, Float([2.0, 2.6, 3.2, 0, 3.6][sec])]
                    if sec == 2 || sec == 4, k % 2 == 1 {
                        let side: Float = k % 4 == 1 ? -1 : 1
                        r += [Float(centre.x) + side * 150, Float(centre.y) + 120, age, 1.6]
                    }
                }
            }
        }
        if let d = demo.stepDate[1] {
            let age = Float(now.timeIntervalSince(d))
            for i in 0..<4 where i != demo.track {
                let p = grid(i)
                r += [Float(p.x), Float(p.y), age - 0.35, 2.4]
            }
            r += [Float(centre.x), Float(centre.y), age - 0.9, 2.0]
        }
        if let d = demo.stepDate[2] { r += [201, 752, Float(now.timeIntervalSince(d)), 2.0] }
        for (i, s) in [3, 4, 5].enumerated() {
            if let d = demo.stepDate[s] {
                r += [Float(touches[i].x), Float(touches[i].y), Float(now.timeIntervalSince(d)), 3.4]
            }
        }
        return r.isEmpty ? [0, 0, -1, 0] : r
    }

    // MARK: Records

    /// Where record `i` floats: a 2x2 raft before the pick, then the chosen one drifts to
    /// the middle and grows while the others sink.
    private func place(_ i: Int, pick: Double, now: Date, lv: Beat.Levels) -> (at: CGPoint, size: CGFloat, tilt: Double, sink: Double, alpha: Double) {
        let s = now.timeIntervalSinceReferenceDate
        let bob = CGPoint(x: sin(s * 0.9 + Double(i) * 1.7) * 3, y: sin(s * 1.3 + Double(i) * 2.3) * 4)
        let tilt = sin(s * 0.7 + Double(i)) * 1.6
        let g = grid(i), p = CGFloat(pick)
        if i == demo.track {
            let at = CGPoint(x: g.x + (centre.x - g.x) * p + bob.x, y: g.y + (centre.y - g.y) * p + bob.y - CGFloat(lv.kick) * 3)
            return (at, (150 + (big - 150) * p) * (1 + CGFloat(lv.kick) * 0.025), tilt * (1 - pick * 0.6), 0, 1)
        }
        let sink = smooth(pick * 1.4)
        let away = CGPoint(x: (g.x - centre.x) * 0.25 * p, y: (g.y - centre.y) * 0.25 * p)
        return (CGPoint(x: g.x + away.x + bob.x, y: g.y + away.y + bob.y), 150 * (1 - 0.25 * sink), tilt, sink, 1 - sink)
    }

    private func z(_ i: Int) -> Int { i == demo.track ? 9 : 0 }

    /// A square album sleeve: gradient, a motif and the title.
    private func sleeve(_ i: Int, _ size: CGFloat) -> some View {
        let c = theme.covers[i], k = size / 220, tr = Beat.library[i]
        return ZStack {
            RoundedRectangle(cornerRadius: 8 * k).fill(LinearGradient(colors: c.colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing))
            Motif(m: i, k: k).foregroundStyle(Color(hex: c.ink).opacity(0.24))
            VStack(spacing: 6 * k) {
                Spacer()
                Text(tr.title.uppercased()).font(.custom(theme.font, size: 24 * k)).tracking(3 * k)
                Rectangle().frame(width: 90 * k, height: 0.8)
                Text(tr.artist).font(.custom(theme.font, size: 12 * k))
            }
            .foregroundStyle(Color(hex: c.ink))
            .padding(.bottom, 18 * k)
            // A wet edge.
            RoundedRectangle(cornerRadius: 8 * k)
                .stroke(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.05), .white.opacity(0.25)], startPoint: .top, endPoint: .bottom), lineWidth: 1.2)
        }
        .frame(width: size, height: size)
        .compositingGroup()
    }

    // MARK: Chrome

    private func header(pick: Double) -> some View {
        ZStack {
            VStack(spacing: 6) {
                Text(theme.brand).font(.system(size: 11, weight: .bold)).tracking(4).foregroundStyle(theme.dim)
                Text("Pick a record").font(.custom(theme.font, size: 34)).foregroundStyle(theme.text)
            }
            .opacity(1 - pick)
            HStack {
                Image(systemName: "chevron.down").font(.system(size: 17, weight: .semibold))
                Spacer()
                VStack(spacing: 2) {
                    Text("PLAYING FROM").font(.system(size: 10, weight: .semibold)).tracking(2).opacity(0.55)
                    Text(theme.brand.capitalized).font(.system(size: 14, weight: .semibold))
                }
                Spacer()
                Image(systemName: "ellipsis").font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(theme.text)
            .padding(.horizontal, 26)
            .offset(y: -40)
            .opacity(smooth((pick - 0.4) / 0.6))
        }
        .reveal(0)
    }

    private var titleBlock: some View {
        VStack(spacing: 5) {
            Text(demo.chosen.title).font(.custom(theme.font, size: 30)).foregroundStyle(theme.text)
            Text(demo.chosen.artist.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(2).foregroundStyle(theme.dim)
        }
    }

    private func progress(t: Double?) -> some View {
        let p = Progress(t: t)
        return HStack(spacing: 10) {
            Text(p.elapsed)
            ZStack(alignment: .leading) {
                Capsule().fill(theme.text.opacity(0.18)).frame(height: 3)
                Capsule().fill(theme.accent).frame(width: max(3, 230 * p.fraction), height: 3)
            }
            .frame(width: 230)
            Text(p.remaining)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(theme.dim)
    }

    private func controls(lv: Beat.Levels) -> some View {
        HStack(spacing: 30) {
            theme.button("backward.fill", 46, false)
            theme.button(demo.step >= Beat.playStep ? "pause.fill" : "play.fill", 66, true)
                .scaleEffect(demo.isPressing(Beat.playStep) ? 0.88 : 1 + lv.kick * 0.05)
                .demoTap(Beat.playStep)
            theme.button("forward.fill", 46, false)
        }
    }
}

/// Makes a floating record pickable: the demo's song registers as step 1.
struct PickIf: ViewModifier {
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

struct Motif: View {
    let m: Int
    let k: CGFloat
    var body: some View {
        switch m {
        case 0:
            VStack(spacing: 9 * k) {
                ForEach(0..<6, id: \.self) { j in Capsule().frame(width: (150 - CGFloat(j) * 14) * k, height: 3 * k) }
            }
            .offset(y: -36 * k)
        case 1:
            Circle().frame(width: 110 * k, height: 110 * k)
                .mask(Rectangle().frame(width: 110 * k, height: 55 * k).offset(y: -27.5 * k))
                .offset(y: -22 * k)
        case 2:
            ZStack {
                Circle().frame(width: 92 * k, height: 92 * k)
                Circle().fill(.white.opacity(0.5)).frame(width: 92 * k, height: 92 * k).offset(x: 26 * k, y: -10 * k).blendMode(.destinationOut)
            }
            .compositingGroup()
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
}
