import SwiftUI

/// Fireplace: pick tonight's mood and a little flame flies off the card into the hearth.
/// On play the embers catch; the flames jump on every kick, sparks fly on the claps, the
/// fire sinks low through the breakdown, swells with the build and roars for the last
/// drop. Poking the fire throws up a shower of sparks.
struct FireApp: View {
    static let script: [Double] = [2.0, 1.0, 6.0, 8.6]
    @EnvironmentObject var demo: Demo

    private let room = Color(hex: 0x140C08)
    private let cream = Color(hex: 0xFBE6D3)
    private let amber = Color(hex: 0xFFB27A)
    private let flameSize = CGSize(width: 262, height: 300)
    private let hearthC = CGPoint(x: 201, y: 444)
    static let moods: [(String, String)] = [("cloud.rain.fill", "Rainy night"), ("sun.horizon.fill", "Golden hour"),
                                             ("snowflake", "Snowed in"), ("moon.stars.fill", "Late talk")]

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let pick = ramp(now, demo.stepDate[1], dur: 0.9)
                let player = ramp(now, demo.stepDate[1], delay: 0.3, dur: 0.8)
                // A small fire from the flame that flew in, the real one from play.
                let kindled = ramp(now, demo.stepDate[1], delay: 0.8, dur: 0.6)
                let lit = ramp(now, demo.stepDate[Beat.playStep], dur: 1.6)
                let flare = flares(now)
                ZStack {
                    room
                    RadialGradient(colors: [Color(hex: 0xFF7A1F).opacity(0.06 + kindled * 0.06 + lit * (0.2 + 0.2 * lv.energy) + lv.kick * 0.12 * lit + flare * 0.15), .clear],
                                   center: UnitPoint(x: 0.5, y: 0.55), startRadius: 20, endRadius: 520)
                    moodList.opacity(1 - smooth(pick * 1.6))
                    Group {
                        header(lv).position(x: 201, y: 112)
                        hearth(now: now, lv: lv, kindled: kindled, lit: lit, flare: flare).position(hearthC)
                        progress(t).position(x: 201, y: 718)
                        controls(lv).position(x: 201, y: 790)
                    }
                    .opacity(player)
                    .reveal(2)
                    spark(pick: pick)
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .ignoresSafeArea()
    }

    /// 0...1 bursts: the demo's pokes and the start of the last drop.
    private func flares(_ now: Date) -> Double {
        var ages = [3, 4].compactMap { demo.stepDate[$0] }.map { now.timeIntervalSince($0) }
        if let t = demo.playTime(now) { ages.append(t - 40 * Beat.spb) }
        return ages.map { s in s > 0 ? s * exp(-s * 3.5) * 9.5 : 0 }.reduce(0, +)
    }

    // MARK: Moods

    private func rowY(_ i: Int) -> CGFloat { 270 + CGFloat(i) * 112 }

    private var moodList: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("HEARTH").font(.system(size: 12, weight: .bold)).tracking(6).foregroundStyle(amber.opacity(0.75))
                Text("What's the mood\ntonight?").font(.custom("Georgia-Italic", size: 32)).foregroundStyle(cream)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .position(x: 201, y: 136)
            .reveal(0)
            ForEach(0..<4, id: \.self) { i in
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color(hex: 0xFF7A1F).opacity(0.16))
                        Image(systemName: Self.moods[i].0).font(.system(size: 20)).foregroundStyle(amber)
                    }
                    .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(Self.moods[i].1).font(.custom("Georgia-Italic", size: 21)).foregroundStyle(cream)
                        Text("\(Beat.library[i].title) · \(Beat.library[i].artist)").font(.system(size: 12, weight: .medium)).foregroundStyle(cream.opacity(0.5))
                    }
                    Spacer()
                    Image(systemName: "flame").font(.system(size: 18)).foregroundStyle(amber.opacity(i == demo.track && demo.step >= 1 ? 0 : 0.8))
                }
                .padding(.horizontal, 16)
                .frame(height: 88)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(amber.opacity(0.16), lineWidth: 1))
                .modifier(Pick(i: i))
                .padding(.horizontal, 18)
                .position(x: 201, y: rowY(i))
                .reveal(1 + i)
            }
        }
    }

    /// The chosen card's flame flies into the fireplace and lights it.
    private func spark(pick: Double) -> some View {
        let from = CGPoint(x: 359, y: rowY(demo.track)), to = CGPoint(x: hearthC.x, y: hearthC.y + 150)
        let k = smooth(pick)
        let x = from.x + (to.x - from.x) * k
        let y = from.y + (to.y - from.y) * k - sin(.pi * k) * 160
        return Image(systemName: "flame.fill")
            .font(.system(size: 22 + 16 * sin(.pi * k)))
            .foregroundStyle(LinearGradient(colors: [Color(hex: 0xFFE3A3), Color(hex: 0xFF7A1F)], startPoint: .top, endPoint: .bottom))
            .shadow(color: Color(hex: 0xFF7A1F).opacity(0.9), radius: 12)
            .position(x: x, y: y)
            .opacity(pick > 0 && pick < 1 ? 1 : 0)
            .allowsHitTesting(false)
    }

    // MARK: Player

    private func header(_ lv: Beat.Levels) -> some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("HEARTH · \(Self.moods[demo.track].1.uppercased())").font(.system(size: 11, weight: .bold)).tracking(4).foregroundStyle(amber.opacity(0.8))
                Spacer()
                Image(systemName: "timer").font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(cream.opacity(0.8))
            .padding(.horizontal, 26)
            .padding(.bottom, 8)
            Text(demo.chosen.title).font(.custom("Georgia-Italic", size: 34)).foregroundStyle(cream)
            Text(demo.chosen.artist).font(.system(size: 13, weight: .medium)).foregroundStyle(cream.opacity(0.5))
        }
    }

    private func hearth(now: Date, lv: Beat.Levels, kindled: Double, lit: Double, flare: Double) -> some View {
        let height = 0.06 + kindled * 0.07 + lit * (0.3 + 0.36 * lv.energy + 0.26 * lv.kick + 0.1 * lv.bass) + flare * 0.3
        let time = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)
        let glow = max(kindled * 0.4, lit)
        return ZStack {
            bricks
            UnevenRoundedRectangle(topLeadingRadius: 130, topTrailingRadius: 130)
                .fill(LinearGradient(colors: [Color(hex: 0x050302), Color(hex: 0x1A0D07)], startPoint: .top, endPoint: .bottom))
                .frame(width: 270, height: 290)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 130, topTrailingRadius: 130)
                        .fill(RadialGradient(colors: [Color(hex: 0xFF8A2A).opacity(glow * (0.35 + 0.25 * lv.kick) + flare * 0.2), .clear],
                                             center: .bottom, startRadius: 0, endRadius: 240)))
                .offset(y: 35)
            Rectangle().fill(.white)
                .frame(width: flameSize.width, height: flameSize.height)
                .colorEffect(ShaderLibrary.fire(.float2(flameSize), .float(time), .float(height), .float(flare)))
                .blendMode(.screen)
                .offset(y: 30)
            logs(glow: glow, lv: lv).offset(y: 166)
            Sparks(now: now, t: demo.playTime(now), pokes: [3, 4].compactMap { demo.stepDate[$0] })
                .frame(width: 270, height: 420)
                .offset(y: -20)
            mantel(now: now, lv: lv, glow: glow)
            Color.clear.frame(width: 120, height: 120).demoTap(3, 4).offset(y: 120)
        }
        .frame(width: 360, height: 400)
    }

    private var bricks: some View {
        Canvas { ctx, size in
            let bw: CGFloat = 44, bh: CGFloat = 20
            for row in 0..<Int(size.height / bh) + 1 {
                let y = CGFloat(row) * bh
                let shift: CGFloat = row % 2 == 0 ? 0 : bw / 2
                var x = -shift
                var i = 0
                while x < size.width {
                    let tone = 0.75 + 0.25 * hash01(row * 13 + i, 4)
                    ctx.fill(Path(roundedRect: CGRect(x: x + 1.5, y: y + 1.5, width: bw - 3, height: bh - 3), cornerRadius: 2),
                             with: .color(Color(.sRGB, red: 0.42 * tone, green: 0.17 * tone, blue: 0.11 * tone)))
                    x += bw; i += 1
                }
            }
        }
        .frame(width: 340, height: 320)
        .mask(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8))
        .offset(y: 38)
    }

    /// Mantel shelf with two candles and a little framed picture.
    private func mantel(now: Date, lv: Beat.Levels, glow: Double) -> some View {
        let time = now.timeIntervalSinceReferenceDate
        return ZStack {
            RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [Color(hex: 0x5A3826), Color(hex: 0x3B2418)], startPoint: .top, endPoint: .bottom))
                .frame(width: 372, height: 22)
            ForEach(0..<2, id: \.self) { c in
                let x: CGFloat = c == 0 ? -140 : 128
                let h: CGFloat = c == 0 ? 38 : 28
                VStack(spacing: 2) {
                    Ellipse().fill(RadialGradient(colors: [Color(hex: 0xFFF1C9), Color(hex: 0xFF9A3C).opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: 7))
                        .frame(width: 9, height: 16)
                        .scaleEffect(y: 1 + 0.15 * sin(time * 11 + Double(c) * 2) + lv.arp * 0.2, anchor: .bottom)
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xF1E4CC)).frame(width: 12, height: h)
                }
                .offset(x: x, y: -11 - (h + 18) / 2)
            }
            // Picture frame.
            ZStack {
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x8A6A44)).frame(width: 46, height: 38)
                RoundedRectangle(cornerRadius: 1).fill(LinearGradient(colors: [Color(hex: 0x3B5A7A), Color(hex: 0xC98B5A)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 36, height: 28)
            }
            .offset(x: 70, y: -30)
            // Firelight catching the front edge.
            Rectangle().fill(Color(hex: 0xFF8A2A).opacity(0.25 * glow + 0.1 * lv.kick)).frame(width: 372, height: 2).offset(y: 10)
        }
        .offset(y: -150)
    }

    private func logs(glow: Double, lv: Beat.Levels) -> some View {
        let g = Color(hex: 0xFF6A1A).opacity(0.25 + 0.6 * glow * (0.6 + 0.4 * lv.kick))
        return ZStack {
            Capsule().fill(Color(hex: 0x3A2214)).frame(width: 190, height: 30).rotationEffect(.degrees(-9))
                .overlay(Capsule().fill(LinearGradient(colors: [g, .clear], startPoint: .top, endPoint: .bottom)).rotationEffect(.degrees(-9)))
            Capsule().fill(Color(hex: 0x4A2C1A)).frame(width: 190, height: 30).rotationEffect(.degrees(9))
                .overlay(Capsule().fill(LinearGradient(colors: [g, .clear], startPoint: .top, endPoint: .bottom)).rotationEffect(.degrees(9)))
            Capsule().fill(g).frame(width: 150, height: 8).blur(radius: 6).offset(y: -10)
        }
    }

    private func progress(_ t: Double?) -> some View {
        let p = Progress(t: t)
        return VStack(spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule().fill(cream.opacity(0.14)).frame(height: 3)
                Capsule().fill(LinearGradient(colors: [Color(hex: 0xFF7A1F), amber], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(3, 300 * p.fraction), height: 3)
            }
            .frame(width: 300)
            HStack { Text(p.elapsed); Spacer(); Text(p.remaining) }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(cream.opacity(0.45))
                .frame(width: 300)
        }
    }

    private func controls(_ lv: Beat.Levels) -> some View {
        HStack(spacing: 34) {
            Image(systemName: "backward.fill").font(.system(size: 20))
            ZStack {
                Circle().fill(Color(hex: 0xFF7A1F).opacity(0.18))
                Circle().stroke(amber.opacity(0.6), lineWidth: 1.2)
                Image(systemName: demo.step >= Beat.playStep ? "pause.fill" : "play.fill").font(.system(size: 24, weight: .bold))
            }
            .frame(width: 70, height: 70)
            .scaleEffect(demo.isPressing(Beat.playStep) ? 0.88 : 1 + lv.kick * 0.04)
            .demoTap(Beat.playStep)
            Image(systemName: "forward.fill").font(.system(size: 20))
        }
        .foregroundStyle(cream)
    }
}

/// Sparks: a few on every clap, a shower on every poke and on the last drop.
private struct Sparks: View {
    let now: Date
    let t: Double?
    let pokes: [Date]

    var body: some View {
        Canvas { ctx, size in
            var bursts: [(Double, Int, Int)] = []   // (age, count, seed)
            if let t, t > 0 {
                let b = Int(floor(t / Beat.spb))
                for k in max(0, b - 6)...b {
                    let lb = Double(k).truncatingRemainder(dividingBy: Beat.loop)
                    let sec = Beat.section(lb)
                    let n = sec == 3 ? 1 : (sec == 2 || sec == 4) && k % 2 == 1 ? 14 : 4
                    bursts.append((t - Double(k) * Beat.spb, k == 40 ? 80 : n, k))
                }
            }
            for (j, p) in pokes.enumerated() { bursts.append((now.timeIntervalSince(p), 60, 900 + j)) }
            ctx.blendMode = .plusLighter
            for (age, n, seed) in bursts where age > 0 && age < 2.6 {
                for i in 0..<n {
                    let h = seed * 97 + i
                    let life = 1.2 + hash01(h, 1) * 1.3
                    guard age < life else { continue }
                    let vx = (hash01(h, 2) - 0.5) * 120
                    let vy = -(90 + hash01(h, 3) * 170)
                    let x = size.width / 2 + (hash01(h, 4) - 0.5) * 120 + vx * age + sin(age * 5 + Double(i)) * 8
                    let y = size.height - 70 + vy * age + 30 * age * age
                    let a = 1 - age / life
                    let r = 1.2 + hash01(h, 5) * 1.6
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(Color(.sRGB, red: 1, green: 0.55 + 0.35 * a, blue: 0.2, opacity: a)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
