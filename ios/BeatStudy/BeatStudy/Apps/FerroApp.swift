import SwiftUI

/// Ferrofluid: pull a tape off the shelf and it slides into the deck. Underneath sits a
/// dish of black magnetic liquid: the bass stands it up in glossy spikes, it lies almost
/// flat through the breakdown and bristles back for the last drop. A tap moves the
/// magnet under the dish and the whole puddle crawls after it.
struct FerroApp: View {
    static let script: [Double] = [2.0, 1.0, 5.0, 5.0, 6.5]
    @EnvironmentObject var demo: Demo

    private let bg = Color(hex: 0xE4E2DE)
    private let ink = Color(hex: 0x17171A)
    private let hot = Color(hex: 0xFF5A36)
    private let dish: CGFloat = 330
    private let dishC = CGPoint(x: 201, y: 478)
    private let deckC = CGPoint(x: 201, y: 146)
    /// Magnet stops for steps 3, 4, 5, as offsets from the dish centre.
    private let stops: [CGPoint] = [CGPoint(x: -40, y: -34), CGPoint(x: 36, y: 38), CGPoint(x: 0, y: 0)]
    static let labels: [UInt32] = [0x2F6F96, 0xFF5A36, 0xE0B341, 0x7E6CD6]

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let now = tl.date
                let t = demo.playTime(now)
                let lv = Beat.levels(t)
                let pick = smooth(ramp(now, demo.stepDate[1], dur: 0.8))
                let player = ramp(now, demo.stepDate[1], delay: 0.35, dur: 0.7)
                ZStack {
                    bg
                    shelf.opacity(1 - pick)
                    Group {
                        deckBody.position(deckC)
                        caption(t).position(x: 201, y: 256)
                        dishView(now: now, lv: lv).position(dishC)
                        meters(lv).position(x: 201, y: 706)
                        controls.position(x: 201, y: 792)
                    }
                    .opacity(player)
                    .offset(y: (1 - player) * 24)
                    .reveal(2)
                    hero(now: now, pick: pick)
                }
                .frame(width: g.size.width, height: g.size.height)
            }
        }
        .background(bg)
        .ignoresSafeArea()
    }

    // MARK: Shelf

    private func rowY(_ i: Int) -> CGFloat { 268 + CGFloat(i) * 112 }

    private var shelf: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("MAG—01  ·  TAPE SHELF").font(.system(size: 11, weight: .heavy, design: .monospaced)).foregroundStyle(hot)
                Text("Pick a tape").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(ink)
                Text("Side A · 0:24 each").font(.system(size: 13, weight: .medium, design: .monospaced)).foregroundStyle(ink.opacity(0.45))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .position(x: 201, y: 128)
            .reveal(0)
            // Shelf boards.
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xCFCBC4)).frame(width: 340, height: 6)
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                    .position(x: 201, y: rowY(i) + 46)
                    .reveal(1 + i)
            }
            ForEach(0..<4, id: \.self) { i in
                Group {
                    if i == demo.track { Color.clear } else { tape(i) }
                }
                .frame(width: 270, height: 84)
                .modifier(Pick(i: i))
                .position(x: 201, y: rowY(i))
                .reveal(1 + i)
            }
        }
    }

    /// A cassette, front on: shell, label with the song in marker, window and reels.
    private func tape(_ i: Int, turn: Double = 0) -> some View {
        let tr = Beat.library[i]
        return ZStack {
            RoundedRectangle(cornerRadius: 9).fill(Color(hex: 0x2A2A2E))
            RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.08), lineWidth: 1)
            VStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(hex: 0xF4EFE4))
                    Rectangle().fill(Color(hex: Self.labels[i])).frame(height: 5).frame(maxHeight: .infinity, alignment: .top)
                    HStack {
                        Text(tr.title).font(.custom("Noteworthy-Bold", size: 15)).foregroundStyle(Color(hex: 0x23232A))
                        Spacer()
                        Text(tr.artist.uppercased()).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.black.opacity(0.45))
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                }
                .frame(height: 30)
                ZStack {
                    Rectangle().fill(Color(hex: 0xF4EFE4))
                    RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0x1D1D20)).frame(width: 150, height: 34)
                    Rectangle().fill(Color(hex: 0x5B3A28).opacity(0.85)).frame(width: 64, height: 14)
                    HStack(spacing: 60) { reel(turn); reel(turn + 0.13) }
                }
                .frame(height: 40)
            }
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(7)
        }
        .frame(width: 270, height: 84)
    }

    private func reel(_ turn: Double) -> some View {
        ZStack {
            Circle().fill(Color(hex: 0xF4F1EA)).frame(width: 28, height: 28)
            ForEach(0..<6, id: \.self) { i in
                Rectangle().fill(Color(hex: 0x1D1D20)).frame(width: 2.5, height: 8).offset(y: -6)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
        }
        .rotationEffect(.degrees(turn * 360))
    }

    private func hero(now: Date, pick: Double) -> some View {
        let reel = Motor(demo.stepDate[Beat.playStep].map { [($0, 0.8)] } ?? [], tau: 0.4).state(at: now).pos
        let from = CGPoint(x: 201, y: rowY(demo.track)), to = CGPoint(x: deckC.x, y: deckC.y + 4)
        // Slides out of the shelf to the right, then swings up into the deck.
        let out = smooth(pick / 0.35)
        let x = from.x + 60 * out * (1 - smooth((pick - 0.35) / 0.65)) + (to.x - from.x) * smooth((pick - 0.2) / 0.8)
        let y = from.y + (to.y - from.y) * smooth((pick - 0.2) / 0.8)
        return tape(demo.track, turn: reel)
            .shadow(color: .black.opacity(0.25 * (1 - pick) + 0.1), radius: 10, y: 6)
            .rotationEffect(.degrees(sin(.pi * pick) * -6))
            .position(x: x, y: y)
            .reveal(demo.step == 0 ? 2 : 1)
            .allowsHitTesting(false)
    }

    // MARK: Deck

    private var deckBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(hex: 0x3A3A40), Color(hex: 0x222226)], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.1), lineWidth: 1)
            // Cassette well.
            RoundedRectangle(cornerRadius: 11).fill(Color.black.opacity(0.45)).frame(width: 284, height: 98)
            HStack {
                Text("MAG—01").font(.system(size: 10, weight: .heavy, design: .monospaced)).foregroundStyle(hot)
                Spacer()
                Circle().fill(demo.step >= Beat.playStep ? hot : Color(hex: 0x55555C)).frame(width: 6, height: 6)
                    .shadow(color: hot.opacity(demo.step >= Beat.playStep ? 0.9 : 0), radius: 4)
                Text("PLAY").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 18)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 9)
        }
        .frame(width: 316, height: 132)
        .shadow(color: .black.opacity(0.2), radius: 16, y: 10)
    }

    private func caption(_ t: Double?) -> some View {
        let p = Progress(t: t)
        let counter = String(format: "%04d", Int((t ?? 0) * 7))
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(demo.chosen.title).font(.system(size: 21, weight: .bold, design: .rounded))
                Text(demo.chosen.artist).font(.system(size: 13, weight: .medium)).opacity(0.5)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 2) {
                    ForEach(Array(counter.enumerated()), id: \.0) { _, ch in
                        Text(String(ch)).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                            .frame(width: 14, height: 22).background(RoundedRectangle(cornerRadius: 3).fill(ink))
                    }
                }
                Text("\(p.elapsed) / 0:24").font(.system(size: 10, weight: .medium, design: .monospaced)).opacity(0.5)
            }
        }
        .foregroundStyle(ink)
        .padding(.horizontal, 40)
    }

    // MARK: Dish

    /// Where the magnet sits, as an offset from the dish centre. Moves smoothly on each tap.
    private func magnet(_ now: Date) -> CGPoint {
        var p = CGPoint.zero
        for (i, q) in stops.enumerated() {
            let k = ramp(now, demo.stepDate[3 + i], dur: 1.1)
            p = CGPoint(x: p.x + (q.x - p.x) * k, y: p.y + (q.y - p.y) * k)
        }
        return p
    }

    private func dishView(now: Date, lv: Beat.Levels) -> some View {
        let m = magnet(now)
        let drive = lv.kick * 0.7 + lv.bass * 0.3 + lv.clap * 0.25 + lv.arp * (lv.section == 3 ? 0.35 : 0.1)
        let spikes = 6 + drive * (16 + 36 * lv.energy) + lv.build * 34
        let radius = 96 + 8 * lv.energy + 6 * lv.kick * lv.energy
        return ZStack {
            Circle().fill(Color.white.opacity(0.55))
            Circle().fill(RadialGradient(colors: [Color(hex: 0xD8D6D1), Color(hex: 0xF4F3F0)], center: .center, startRadius: 60, endRadius: 165))
                .padding(10)
            Circle().stroke(LinearGradient(colors: [.white, .white.opacity(0.2), Color(hex: 0xBEBBB4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
            // Graduations on the glass.
            ForEach(0..<36, id: \.self) { i in
                Rectangle().fill(ink.opacity(i % 9 == 0 ? 0.25 : 0.1)).frame(width: 1, height: i % 9 == 0 ? 10 : 5)
                    .offset(y: -dish / 2 + 20).rotationEffect(.degrees(Double(i) * 10))
            }
            Circle().fill(Color.black.opacity(0.22)).frame(width: radius * 2, height: radius * 2).blur(radius: 14)
                .offset(x: m.x + 6, y: m.y + 12)
            Rectangle().fill(.white)
                .frame(width: dish, height: dish)
                .colorEffect(ShaderLibrary.ferro(.float2(CGSize(width: dish, height: dish)),
                                                 .float(now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)),
                                                 .float2(CGPoint(x: dish / 2 + m.x, y: dish / 2 + m.y)),
                                                 .float(radius), .float(spikes)))
            // Taps land on the glass where the magnet will go.
            ForEach(Array(stops.enumerated()), id: \.0) { i, q in
                Color.clear.frame(width: 50, height: 50).demoTap(3 + i).offset(x: q.x, y: q.y)
            }
        }
        .frame(width: dish, height: dish)
        .shadow(color: .black.opacity(0.12), radius: 20, y: 14)
    }

    // MARK: Meters and keys

    private func meters(_ lv: Beat.Levels) -> some View {
        HStack(spacing: 16) {
            vu(lv.playing ? min(1, lv.kick * 0.6 + lv.bass * 0.3 + lv.energy * 0.25) : 0, "L")
            vu(lv.playing ? min(1, lv.kick * 0.5 + lv.clap * 0.3 + lv.arp * 0.3 + lv.energy * 0.25) : 0, "R")
        }
    }

    private func vu(_ v: Double, _ ch: String) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xF3E9CF))
            RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.15), lineWidth: 1)
            ForEach(0..<11, id: \.self) { i in
                Rectangle().fill(i >= 8 ? hot : ink.opacity(0.6)).frame(width: 1.2, height: i % 5 == 0 ? 9 : 5)
                    .offset(y: -40)
                    .rotationEffect(.degrees(-50 + Double(i) * 10), anchor: .bottom)
                    .offset(y: -6)
            }
            Rectangle().fill(ink).frame(width: 1.5, height: 44)
                .rotationEffect(.degrees(-50 + v * 100), anchor: .bottom)
                .offset(y: -6)
            Text("VU  \(ch)").font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(ink.opacity(0.5)).padding(.bottom, 5)
        }
        .frame(width: 132, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var controls: some View {
        HStack(spacing: 16) {
            key("backward.end.fill", main: false)
            key(demo.step >= Beat.playStep ? "pause.fill" : "play.fill", main: true)
            key("forward.end.fill", main: false)
            key("eject.fill", main: false)
        }
    }

    private func key(_ icon: String, main: Bool) -> some View {
        let down = main && demo.step >= Beat.playStep
        let k = ZStack {
            RoundedRectangle(cornerRadius: 10).fill(main ? hot : Color(hex: 0xF5F4F1))
                .shadow(color: .black.opacity(0.2), radius: down ? 1 : 4, y: down ? 1 : 4)
            Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(main ? .white : ink.opacity(0.75))
        }
        .frame(width: 66, height: 54)
        .offset(y: down ? 3 : 0)
        return Group {
            if main { k.demoTap(Beat.playStep) } else { k }
        }
    }
}
