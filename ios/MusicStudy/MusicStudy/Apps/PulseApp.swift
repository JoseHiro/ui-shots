import SwiftUI

/// Pulse: a neon synthwave player. A ring of glowing bars dances to the beat
/// around the cover, a laser grid scrolls underneath, and each mode changes
/// the tempo and the colors.
struct PulseApp: View {
    @EnvironmentObject var demo: Demo
    @Namespace private var ns

    static let bg = Color(hex: 0x07051A)
    static func wide(_ s: CGFloat, _ w: Font.Weight = .black) -> Font { .system(size: s, weight: w).width(.expanded) }

    /// Pause before each step: play, drive, rave, next track.
    static let script: [Double] = [1.8, 2.6, 2.6, 2.6]

    static let modes = ["CHILL", "DRIVE", "RAVE"]
    static let bpm: [Double] = [92, 112, 128]
    static let tracks = [("Midnight Arcade", "VHS Hearts"), ("Chrome Sunset", "Laserdisc Kid")]
    static let palettes = [(RGB(1, 0.17, 0.84), RGB(0.13, 0.89, 1)), (RGB(1, 0.45, 0.05), RGB(1, 0.15, 0.45))]

    private var mode: Int { demo.step >= 3 ? 2 : demo.step >= 2 ? 1 : 0 }
    private var track: Int { demo.step >= 4 ? 1 : 0 }

    private var beat: Motor {
        var e: [(Date, Double)] = []
        for n in 1...3 { if let d = demo.stepDate[n] { e.append((d, Self.bpm[n - 1] / 60)) } }
        return Motor(e, tau: 0.6)
    }

    /// The two colors of the moment: magenta/cyan, then sunset, then a running rainbow.
    private func colors(_ now: Date) -> (RGB, RGB) {
        let r2 = ramp(now, demo.stepDate[2], dur: 0.7), r3 = ramp(now, demo.stepDate[3], dur: 0.7)
        let hue = now.timeIntervalSinceReferenceDate * 0.11
        let a = Self.palettes[0].0.mix(Self.palettes[1].0, r2).mix(RGB(hue: hue), r3)
        let b = Self.palettes[0].1.mix(Self.palettes[1].1, r2).mix(RGB(hue: hue + 0.45), r3)
        return (a, b)
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let now = tl.date
            let (a, b) = colors(now)
            let m = beat.state(at: now)
            let env = exp(-(m.pos - floor(m.pos)) * 5)
            let amp = 0.12 + 0.88 * ramp(now, demo.stepDate[1], dur: 0.8)
            ZStack {
                Self.bg.ignoresSafeArea()
                RadialGradient(colors: [a.color.opacity(0.35), .clear], center: .init(x: 0.5, y: 0.3), startRadius: 10, endRadius: 330)
                    .ignoresSafeArea()
                LaserGrid(scroll: m.pos * 0.5, color: a, glow: b)
                    .frame(height: 300)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea()
                    .reveal(5)
                // Strobe on the beat in rave mode.
                a.color.opacity(0.10 * env * ramp(now, demo.stepDate[3], dur: 0.5)).ignoresSafeArea()
                VStack(spacing: 0) {
                    header(bpm: m.vel * 60, a: a).reveal(0)
                    visualizer(now: now, beat: m.pos, env: env, amp: amp, a: a, b: b).reveal(1).padding(.top, 6)
                    titles(a: a, b: b).reveal(2).padding(.top, 4)
                    progress(now: now, a: a, b: b).reveal(3).padding(.top, 20)
                    modePicker(a: a).reveal(3).padding(.top, 22)
                    controls(a: a, b: b).reveal(4).padding(.top, 22)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func header(bpm: Double, a: RGB) -> some View {
        HStack {
            Text("PULSE").font(Self.wide(24)).kerning(3).foregroundStyle(.white)
                .shadow(color: a.color, radius: 8).shadow(color: a.color.opacity(0.6), radius: 2)
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(a.color).frame(width: 7, height: 7).shadow(color: a.color, radius: 4)
                Text("\(Int(bpm.rounded())) BPM").font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 12).frame(height: 28)
            .background(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
        }
    }

    private func visualizer(now: Date, beat: Double, env: Double, amp: Double, a: RGB, b: RGB) -> some View {
        let t = now.timeIntervalSinceReferenceDate
        let gain = 0.6 + 0.25 * ramp(now, demo.stepDate[2], dur: 0.6) + 0.15 * ramp(now, demo.stepDate[3], dur: 0.6)
        return ZStack {
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let n = 84, r0: CGFloat = 104
                var bars: [(Path, Color)] = []
                for i in 0..<n {
                    let k = Double(min(i, n - i)) / Double(n / 2)   // 0 at the top, 1 at the bottom, mirrored
                    let ang = Double(i) / Double(n) * 2 * .pi - .pi / 2
                    let bass = env * (1 - k) * 0.9
                    let mids = 0.5 + 0.5 * sin(t * (5 + k * 9) + Double(i) * 1.7) * sin(t * 2.1 + Double(i) * 0.9)
                    let level = amp * gain * min(1, bass + mids * 0.55 * (0.5 + env * 0.5))
                    let len = 5 + 60 * CGFloat(level)
                    var p = Path()
                    p.move(to: CGPoint(x: c.x + (r0 + 6) * cos(ang), y: c.y + (r0 + 6) * sin(ang)))
                    p.addLine(to: CGPoint(x: c.x + (r0 + 6 + len) * cos(ang), y: c.y + (r0 + 6 + len) * sin(ang)))
                    bars.append((p, a.mix(b, k).color))
                }
                ctx.drawLayer { l in
                    l.addFilter(.blur(radius: 9))
                    for (p, col) in bars { l.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: 6, lineCap: .round)) }
                }
                for (p, col) in bars { ctx.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: 3, lineCap: .round)) }
                for (p, _) in bars { ctx.stroke(p, with: .color(.white.opacity(0.45)), style: StrokeStyle(lineWidth: 1, lineCap: .round)) }
                // A ring that pushes out on every beat.
                let f = CGFloat(beat - floor(beat))
                let rr = r0 + 8 + f * 90
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2)),
                           with: .color(b.color.opacity(Double(1 - f) * 0.55 * (amp - 0.12))), lineWidth: 2)
            }
            Circle().stroke(a.color, lineWidth: 2).frame(width: 206, height: 206)
                .shadow(color: a.color, radius: 10)
            PulseArt(kind: track)
                .frame(width: 196, height: 196)
                .clipShape(Circle())
                .scaleEffect(1 + 0.035 * env * (amp - 0.12))
                .id(track)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
        .frame(height: 340)
    }

    private func titles(a: RGB, b: RGB) -> some View {
        let tr = Self.tracks[track]
        return VStack(spacing: 6) {
            Text(tr.0.uppercased()).font(Self.wide(25)).foregroundStyle(.white)
                .shadow(color: a.color, radius: 10).shadow(color: a.color.opacity(0.7), radius: 3)
            Text(tr.1).font(.system(size: 16, weight: .semibold)).kerning(1).foregroundStyle(b.color)
                .shadow(color: b.color.opacity(0.8), radius: 6)
        }
        .id(track)
        .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 1.2)), removal: .opacity))
    }

    private func progress(now: Date, a: RGB, b: RGB) -> some View {
        let start = demo.step >= 4 ? demo.stepDate[4] : demo.stepDate[1]
        let e = (demo.step >= 4 ? 0 : 34) + (start.map { now.timeIntervalSince($0) } ?? 0)
        let length = 214.0
        return VStack(spacing: 8) {
            GeometryReader { g in
                let x = g.size.width * min(1, e / length)
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12)).frame(height: 4)
                    Capsule().fill(LinearGradient(colors: [b.color, a.color], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, x), height: 4)
                        .shadow(color: a.color, radius: 6)
                    Circle().fill(.white).frame(width: 12, height: 12).shadow(color: a.color, radius: 8)
                        .offset(x: x - 6)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 14)
            HStack {
                Text(clock(e))
                Spacer()
                Text(clock(length))
            }
            .font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
        }
    }

    private func modePicker(a: RGB) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Text(Self.modes[i]).font(Self.wide(13, .heavy)).kerning(1.5)
                    .foregroundStyle(mode == i ? .white : .white.opacity(0.4))
                    .frame(maxWidth: .infinity).frame(height: 40)
                    .background {
                        if mode == i {
                            Capsule().stroke(a.color, lineWidth: 2)
                                .background(Capsule().fill(a.color.opacity(0.18)))
                                .shadow(color: a.color, radius: 8)
                                .matchedGeometryEffect(id: "mode", in: ns)
                        }
                    }
                    .scaleEffect(demo.isPressing(i + 1) && i > 0 ? 0.92 : 1)
                    .demoTap(i == 0 ? 99 : i + 1)
            }
        }
        .padding(4)
        .background(Capsule().fill(.white.opacity(0.06)))
    }

    private func controls(a: RGB, b: RGB) -> some View {
        HStack {
            Image(systemName: "shuffle").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Image(systemName: "backward.fill").font(.system(size: 22)).foregroundStyle(.white)
            Spacer()
            ZStack {
                Circle().fill(.white.opacity(0.06))
                Circle().stroke(AngularGradient(colors: [a.color, b.color, a.color], center: .center), lineWidth: 3)
                    .shadow(color: a.color, radius: 10)
                Image(systemName: demo.step >= 1 ? "pause.fill" : "play.fill")
                    .font(.system(size: 28)).foregroundStyle(.white)
                    .offset(x: demo.step >= 1 ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 78, height: 78)
            .scaleEffect(demo.isPressing(1) ? 0.9 : 1)
            .demoTap(1)
            Spacer()
            Image(systemName: "forward.fill").font(.system(size: 22)).foregroundStyle(.white)
                .scaleEffect(demo.isPressing(4) ? 0.8 : 1)
                .frame(width: 44, height: 44)
                .demoTap(4)
            Spacer()
            Image(systemName: "repeat").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
        }
    }
}

/// Perspective floor grid running toward the viewer.
private struct LaserGrid: View {
    let scroll: Double
    let color: RGB
    let glow: RGB
    var body: some View {
        Canvas { ctx, size in
            let horizon: CGFloat = 40, h = size.height - horizon
            let cx = size.width / 2
            var lines = Path()
            for j in -12...12 {
                lines.move(to: CGPoint(x: cx + CGFloat(j) * 14, y: horizon))
                lines.addLine(to: CGPoint(x: cx + CGFloat(j) * 120, y: size.height))
            }
            let f = scroll - floor(scroll)
            for n in 0..<18 {
                let d = Double(n) + 1 - f
                let y = horizon + h * CGFloat(1.4 / (d + 0.4))
                if y > size.height { continue }
                lines.move(to: CGPoint(x: 0, y: y))
                lines.addLine(to: CGPoint(x: size.width, y: y))
            }
            let fade = Gradient(colors: [.clear, color.color.opacity(0.9)])
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: 4))
                l.stroke(lines, with: .linearGradient(fade, startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: size.height)), lineWidth: 3)
            }
            ctx.stroke(lines, with: .linearGradient(fade, startPoint: CGPoint(x: 0, y: horizon), endPoint: CGPoint(x: 0, y: size.height)), lineWidth: 1.2)
            var hz = Path()
            hz.move(to: CGPoint(x: 0, y: horizon))
            hz.addLine(to: CGPoint(x: size.width, y: horizon))
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: 6))
                l.stroke(hz, with: .color(glow.color), lineWidth: 4)
            }
        }
        .mask(LinearGradient(colors: [.clear, .black, .black], startPoint: .top, endPoint: .bottom))
    }
}

/// Synthwave covers: a striped sun, and chrome mountains under a moon.
private struct PulseArt: View {
    let kind: Int
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                if kind == 0 {
                    LinearGradient(colors: [Color(hex: 0x1B0B3A), Color(hex: 0x5B0F5E)], startPoint: .top, endPoint: .bottom)
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: 0xFFE45C), Color(hex: 0xFF3D8B)], startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.62, height: w * 0.62)
                        .mask(VStack(spacing: 0) {
                            Rectangle().frame(height: w * 0.62 * 0.5)
                            ForEach(0..<6, id: \.self) { i in
                                Rectangle().frame(height: CGFloat(8 - i)).padding(.bottom, CGFloat(2 + i))
                            }
                            Spacer(minLength: 0)
                        }.frame(height: w * 0.62))
                        .position(x: w / 2, y: h * 0.48)
                    Rectangle().fill(Color(hex: 0x12062A)).frame(height: h * 0.26).position(x: w / 2, y: h * 0.87)
                } else {
                    LinearGradient(colors: [Color(hex: 0x050A2E), Color(hex: 0x123B7A)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Color(hex: 0xE8F7FF)).frame(width: 38, height: 38).position(x: w * 0.68, y: h * 0.3)
                        .shadow(color: Color(hex: 0x22E4FF), radius: 10)
                    Triangle()
                        .fill(LinearGradient(colors: [Color(hex: 0xC8D3E8), Color(hex: 0x3B4A78)], startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.7, height: h * 0.42).position(x: w * 0.36, y: h * 0.62)
                    Triangle()
                        .fill(LinearGradient(colors: [Color(hex: 0xF2F6FF), Color(hex: 0x2A3563)], startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.6, height: h * 0.34).position(x: w * 0.7, y: h * 0.66)
                    Rectangle().fill(Color(hex: 0xFF2BD6).opacity(0.85)).frame(height: 2).position(x: w / 2, y: h * 0.83)
                    Rectangle().fill(Color(hex: 0x0A0626)).frame(height: h * 0.17).position(x: w / 2, y: h * 0.92)
                }
            }
        }
    }
}
