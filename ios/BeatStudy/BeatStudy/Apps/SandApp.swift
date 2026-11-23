import SwiftUI

/// Sand: every song has its own figure. Pick one and its little plate grows into the big
/// one, the sand slumps flat, and on play it shivers on every kick and gathers on the
/// plate's still lines (Chladni figures); each new bass note draws a new figure. The
/// last drop throws all the sand in the air, and so does a tap on the plate.
struct SandApp: View {
    static let script: [Double] = [2.0, 1.0, 7.4, 9.6]
    @EnvironmentObject var demo: Demo

    private let paper = Color(hex: 0xECE6DB)
    private let ink = Color(hex: 0x1E1B17)
    private let brass = Color(hex: 0xB08A5A)
    private let side: CGFloat = 330
    private let plateC = CGPoint(x: 201, y: 418)
    static let count = 3400

    /// Figures as (n, m, sign) of cos(nπx)cos(mπy) ± cos(mπx)cos(nπy).
    static let modes: [(Double, Double, Double)] = [(2, 5, -1), (3, 7, 1), (1, 4, 1), (4, 7, -1)]
    static let scatter: [CGPoint] = (0..<count).map { CGPoint(x: hash01($0, 1), y: hash01($0, 2)) }
    /// Where every grain ends up on each figure, found once by walking it onto a still line.
    static let targets: [[CGPoint]] = modes.map { m in scatter.enumerated().map { i, p in settle(p, m, i) } }

    static func settle(_ p0: CGPoint, _ m: (Double, Double, Double), _ i: Int) -> CGPoint {
        var x = p0.x, y = p0.y
        let (n, k, s) = m
        for _ in 0..<14 {
            let f = cos(n * .pi * x) * cos(k * .pi * y) + s * cos(k * .pi * x) * cos(n * .pi * y)
            let fx = -n * .pi * sin(n * .pi * x) * cos(k * .pi * y) - s * k * .pi * sin(k * .pi * x) * cos(n * .pi * y)
            let fy = -k * .pi * cos(n * .pi * x) * sin(k * .pi * y) - s * n * .pi * cos(k * .pi * x) * sin(n * .pi * y)
            let g2 = max(fx * fx + fy * fy, 1)
            x = min(1, max(0, x - f * fx / g2 * 0.8))
            y = min(1, max(0, y - f * fy / g2 * 0.8))
        }
        // A little spread so the lines have body.
        return CGPoint(x: x + (hash01(i, 5) - 0.5) * 0.012, y: y + (hash01(i, 6) - 0.5) * 0.012)
    }

    private func hz(_ track: Int, _ chord: Int) -> Double { Beat.roots[chord] * 4 * Beat.library[track].pitch }

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let pick = smooth(ramp(now, demo.stepDate[1], dur: 0.85))
                let player = ramp(now, demo.stepDate[1], delay: 0.4, dur: 0.7)
                ZStack {
                    paper
                    library.opacity(1 - pick)
                    Group {
                        header.position(x: 201, y: 76)
                        readout(lv).position(x: 201, y: 156)
                        caption.position(x: 201, y: 622)
                        meter(lv).position(x: 201, y: 680)
                        progress(t).position(x: 201, y: 732)
                        controls(lv).position(x: 201, y: 800)
                    }
                    .opacity(player)
                    .offset(y: (1 - player) * 20)
                    .reveal(2)
                    hero(now: now, lv: lv, pick: pick)
                    Color.clear.frame(width: 120, height: 120).demoTap(3, 4).position(plateC)
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .background(paper)
        .ignoresSafeArea()
    }

    // MARK: Library

    private func rowY(_ i: Int) -> CGFloat { 252 + CGFloat(i) * 106 }

    private var library: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("RESONANCE").font(.system(size: 11, weight: .bold)).tracking(5).foregroundStyle(ink.opacity(0.45))
                Text("Every song draws\nits own figure").font(.system(size: 32, weight: .light, design: .serif)).foregroundStyle(ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 26)
            .position(x: 201, y: 130)
            .reveal(0)
            ForEach(0..<4, id: \.self) { i in
                HStack(spacing: 16) {
                    Group {
                        if i == demo.track { Color.clear } else { thumb(i) }
                    }
                    .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(Beat.library[i].title).font(.system(size: 19, weight: .regular, design: .serif))
                        Text(Beat.library[i].artist).font(.system(size: 12, weight: .medium)).opacity(0.5)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.0f", hz(i, 0))).font(.system(size: 20, weight: .light, design: .serif))
                        Text("Hz").font(.system(size: 10, weight: .semibold)).tracking(1).opacity(0.45)
                    }
                }
                .foregroundStyle(ink)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white.opacity(0.5)))
                .modifier(Pick(i: i))
                .padding(.horizontal, 18)
                .position(x: 201, y: rowY(i))
                .reveal(1 + i)
            }
            Text("Put a little sand on your speaker").font(.system(size: 12, weight: .medium)).foregroundStyle(ink.opacity(0.4))
                .position(x: 201, y: 790)
                .reveal(6)
        }
    }

    /// A small plate already showing its song's figure.
    private func thumb(_ i: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9).fill(Color(hex: 0x16161A))
            Canvas { ctx, size in
                var p = Path()
                for j in stride(from: 0, to: Self.count, by: 5) {
                    let q = Self.targets[i][j]
                    p.addRect(CGRect(x: 4 + q.x * (size.width - 8), y: 4 + q.y * (size.height - 8), width: 1, height: 1))
                }
                ctx.fill(p, with: .color(Color(hex: 0xF3EBDD)))
            }
        }
    }

    /// The chosen song's plate: small in its row, then the big plate.
    private func hero(now: Date, lv: Beat.Levels, pick: Double) -> some View {
        let from = CGPoint(x: 18 + 10 + 36, y: rowY(demo.track)), to = plateC
        let x = from.x + (to.x - from.x) * pick
        let y = from.y + (to.y - from.y) * pick
        let s = (72 + (side - 72) * pick) / side
        return plate(now: now, lv: lv, pick: pick)
            .scaleEffect(s * (1 + lv.kick * 0.006))
            .position(x: x, y: y)
            .reveal(demo.step == 0 ? 2 : 1)
            .allowsHitTesting(false)
    }

    // MARK: Plate

    private func plate(now: Date, lv: Beat.Levels, pick: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x16161A))
            RoundedRectangle(cornerRadius: 12).fill(RadialGradient(colors: [.white.opacity(0.10), .clear], center: UnitPoint(x: 0.3, y: 0.2), startRadius: 0, endRadius: 300))
            RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1)
            Canvas { ctx, size in drawSand(ctx, size, now: now, lv: lv, pick: pick) }
            Circle().fill(Color(hex: 0x3A3A40)).frame(width: 14, height: 14)
                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
            // Brass screws in the corners.
            ForEach(0..<4, id: \.self) { c in
                Circle().fill(LinearGradient(colors: [Color(hex: 0xE2C38E), brass], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 9, height: 9)
                    .overlay(Rectangle().fill(Color(hex: 0x6B5232)).frame(width: 6, height: 1).rotationEffect(.degrees(Double(c) * 35 + 20)))
                    .offset(x: (c % 2 == 0 ? -1 : 1) * (side / 2 - 12), y: (c < 2 ? -1 : 1) * (side / 2 - 12))
            }
        }
        .frame(width: side, height: side)
        .shadow(color: .black.opacity(0.32), radius: 26, y: 18)
    }

    private func drawSand(_ ctx: GraphicsContext, _ size: CGSize, now: Date, lv: Beat.Levels, pick: Double) {
        let inset: CGFloat = 12
        let w = size.width - inset * 2
        let own = Self.targets[demo.track]
        // Before play: the song's figure in the library, slumping flat once picked.
        var from = own, to = Self.scatter, p = pick
        if lv.playing {
            let lb = lv.beat.truncatingRemainder(dividingBy: Beat.loop)
            let c = lv.chord
            to = Self.targets[c]
            let edge = floor(lb / 8) * 8
            if lv.beat < 8 { from = Self.scatter; p = smooth(lv.beat / 3.5) } else {
                from = Self.targets[(c + 3) % 4]; p = smooth((lb - edge) / 2.2)
            }
        }
        // Throws: the demo's taps and the last drop.
        var blast = 0.0
        var throwsAt = [3, 4].compactMap { demo.stepDate[$0] }.map { now.timeIntervalSince($0) }
        if let t = demo.playTime(now) { throwsAt.append(t - 40 * Beat.spb) }
        for s in throwsAt where s > 0 { blast += s * exp(-s * 2.6) * 2.6 }
        let beatIdx = Int(floor(lv.beat))
        var path = Path()
        var dust = Path()
        let jig = lv.kick * (0.7 + lv.energy * 1.6) + lv.build * 2.5 + lv.arp * 0.3
        for i in 0..<Self.count {
            let a = from[i], b = to[i]
            // Each grain leaves at its own moment, hops, and lands.
            let delay = hash01(i, 7) * 0.35
            let q = smooth((p - delay) / 0.65)
            var x = a.x + (b.x - a.x) * q
            var y = a.y + (b.y - a.y) * q
            y -= sin(.pi * q) * 0.02
            let dx = x - 0.5, dy = y - 0.5
            let dist = max(sqrt(dx * dx + dy * dy), 0.02)
            let push = blast * 0.4 * exp(-dist * 2.2) * (0.5 + hash01(i, 8))
            x += dx / dist * push
            y += dy / dist * push
            x += (hash01(i &* 31 &+ beatIdx, 3) - 0.5) * jig * 0.012
            y += (hash01(i &* 17 &+ beatIdx, 4) - 0.5) * jig * 0.012
            x = min(1, max(0, x)); y = min(1, max(0, y))
            let r = CGRect(x: inset + x * w - 0.9, y: inset + y * w - 0.9, width: 1.8, height: 1.8)
            if i % 5 == 0 { dust.addRect(r.insetBy(dx: 0.3, dy: 0.3)) } else { path.addRect(r) }
        }
        ctx.fill(path, with: .color(Color(hex: 0xF3EBDD)))
        ctx.fill(dust, with: .color(Color(hex: 0xC9B99E)))
    }

    // MARK: Player chrome

    private var header: some View {
        HStack {
            Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
            Spacer()
            Text("RESONANCE").font(.system(size: 12, weight: .bold)).tracking(5).opacity(0.55)
            Spacer()
            Image(systemName: "slider.horizontal.3").font(.system(size: 17, weight: .semibold))
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 26)
    }

    private func readout(_ lv: Beat.Levels) -> some View {
        let m = Self.modes[lv.chord]
        return VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(lv.playing ? String(format: "%.1f", hz(demo.track, lv.chord)) : "—").font(.system(size: 54, weight: .light, design: .serif))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: lv.chord)
                Text("Hz").font(.system(size: 18, weight: .regular, design: .serif)).opacity(0.5)
            }
            Text(lv.playing ? "mode \(Int(m.0)) · \(Int(m.1))" : "plate at rest")
                .font(.system(size: 12, weight: .medium, design: .monospaced)).opacity(0.5)
        }
        .foregroundStyle(ink)
    }

    private var caption: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(demo.chosen.title).font(.system(size: 22, weight: .regular, design: .serif))
                Text(demo.chosen.artist).font(.system(size: 13, weight: .medium)).opacity(0.5)
            }
            Spacer()
            Text("No. \(demo.track + 1)").font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().stroke(ink.opacity(0.3), lineWidth: 1))
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 38)
    }

    private func meter(_ lv: Beat.Levels) -> some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<28, id: \.self) { i in
                let x = Double(i) / 27
                let v = lv.playing ? (lv.kick * exp(-x * 3) + lv.bass * 0.5 * exp(-abs(x - 0.25) * 6) + lv.hat * 0.5 * x
                                      + lv.clap * 0.4 * (1 - abs(x - 0.6)) + lv.arp * 0.5 * exp(-abs(x - 0.75) * 8)) : 0.02
                Capsule().fill(ink.opacity(0.75)).frame(width: 5, height: 4 + 38 * min(1, v * (0.6 + 0.4 * lv.energy)))
            }
        }
        .frame(height: 42, alignment: .bottom)
    }

    private func progress(_ t: Double?) -> some View {
        let p = Progress(t: t)
        return HStack(spacing: 12) {
            Text(p.elapsed)
            ZStack(alignment: .leading) {
                Capsule().fill(ink.opacity(0.12)).frame(height: 3)
                Capsule().fill(ink).frame(width: max(3, 240 * p.fraction), height: 3)
            }
            .frame(width: 240)
            Text(p.remaining)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(ink.opacity(0.6))
    }

    private func controls(_ lv: Beat.Levels) -> some View {
        HStack(spacing: 40) {
            Image(systemName: "backward.end.fill").font(.system(size: 20))
            ZStack {
                Circle().fill(ink)
                Image(systemName: demo.step >= Beat.playStep ? "pause.fill" : "play.fill").font(.system(size: 26, weight: .bold)).foregroundStyle(paper)
            }
            .frame(width: 72, height: 72)
            .scaleEffect(demo.isPressing(Beat.playStep) ? 0.88 : 1)
            .demoTap(Beat.playStep)
            Image(systemName: "forward.end.fill").font(.system(size: 20))
        }
        .foregroundStyle(ink.opacity(0.7))
    }
}
