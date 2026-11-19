import SwiftUI

/// Platter: a turntable on a walnut plinth. The record spins with real inertia,
/// the tonearm swings in, and picking a sleeve from the crate swaps the record.
struct PlatterApp: View {
    @EnvironmentObject var demo: Demo
    @Namespace private var ns

    static let paper = Color(hex: 0xEFE7D7)
    static let ink = Color(hex: 0x2A2119)
    static let brass = Color(hex: 0xC59A52)
    static func serif(_ s: CGFloat, italic: Bool = false) -> Font { .custom(italic ? "Baskerville-Italic" : "Baskerville", size: s) }
    static func caps(_ s: CGFloat) -> Font { .system(size: s, weight: .semibold) }

    /// Pause before each step: play, 45 rpm, second record, third record.
    static let script: [Double] = [1.8, 2.8, 2.6, 4.0]

    struct Album { let title: String; let artist: String; let track: String; let year: String; let color: Color; let label: Color }
    static let albums = [
        Album(title: "Slow Harbor", artist: "June Ames", track: "A2 · Low Tide", year: "1974",
              color: Color(hex: 0xC8452B), label: Color(hex: 0xF4E9D4)),
        Album(title: "Blue Hours", artist: "The Lantern Club", track: "A1 · Streetlight", year: "1968",
              color: Color(hex: 0x2D5A8C), label: Color(hex: 0xF4E9D4)),
        Album(title: "Field Notes", artist: "Okra & Wren", track: "A1 · Tall Grass", year: "1979",
              color: Color(hex: 0xDDA53F), label: Color(hex: 0x2A2119)),
    ]

    private var album: Int { demo.step >= 4 ? 2 : demo.step >= 3 ? 1 : 0 }

    var body: some View {
        ZStack {
            Self.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header.reveal(0)
                Deck().reveal(1).padding(.top, 22)
                info.reveal(2).padding(.top, 22)
                sideMap.reveal(3).padding(.top, 24)
                crate.reveal(4).padding(.top, 34)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text("NOW SPINNING").font(Self.caps(11)).kerning(2.5).foregroundStyle(Self.ink.opacity(0.5))
                Text("Platter").font(Self.serif(40, italic: true)).foregroundStyle(Self.ink)
            }
            Spacer()
            HStack(spacing: 0) {
                ForEach(["33", "45"], id: \.self) { s in
                    let on = (s == "45") == (demo.step == 2)
                    Text(s).font(Self.serif(19)).foregroundStyle(on ? Self.paper : Self.ink.opacity(0.6))
                        .frame(width: 50, height: 34)
                        .background {
                            if on { Capsule().fill(Self.ink).matchedGeometryEffect(id: "rpm", in: ns) }
                        }
                        .demoTap(s == "45" ? 2 : 99)
                }
            }
            .padding(3)
            .overlay(Capsule().stroke(Self.ink.opacity(0.25), lineWidth: 1))
            .overlay(alignment: .top) {
                Text("RPM").font(Self.caps(9)).kerning(2).foregroundStyle(Self.ink.opacity(0.45)).offset(y: -15)
            }
            .padding(.bottom, 8)
        }
    }

    private var info: some View {
        let a = Self.albums[album]
        return HStack(alignment: .center) {
            ZStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(a.track.uppercased()).font(Self.caps(11)).kerning(2).foregroundStyle(a.color)
                    Text(a.title).font(Self.serif(34)).foregroundStyle(Self.ink)
                    Text("\(a.artist), \(a.year)").font(Self.serif(17, italic: true)).foregroundStyle(Self.ink.opacity(0.6))
                }
                .id(album)
                .transition(.asymmetric(insertion: .opacity.combined(with: .offset(y: 10)).animation(.easeOut(duration: 0.4).delay(0.18)),
                                        removal: .opacity.animation(.easeOut(duration: 0.15))))
            }
            Spacer()
            ZStack {
                Circle().fill(Self.ink)
                Circle().stroke(Self.brass, lineWidth: 2).padding(5)
                Image(systemName: demo.step >= 1 ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(Self.paper)
                    .offset(x: demo.step >= 1 ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 68, height: 68)
            .shadow(color: Self.ink.opacity(0.25), radius: 10, y: 5)
            .scaleEffect(demo.isPressing(1) ? 0.88 : 1)
            .demoTap(1)
        }
    }

    /// Side A as a strip of tracks, sized by length, with the one playing filled in.
    private var sideMap: some View {
        let lengths: [CGFloat] = [3.4, 4.1, 2.8, 5.0, 3.6]
        let current = album == 0 ? 1 : 0
        return HStack(spacing: 10) {
            Text("SIDE A").font(Self.caps(10)).kerning(2).foregroundStyle(Self.ink.opacity(0.5))
            GeometryReader { g in
                let total = lengths.reduce(0, +), gap: CGFloat = 4
                let unit = (g.size.width - gap * CGFloat(lengths.count - 1)) / total
                HStack(spacing: gap) {
                    ForEach(0..<lengths.count, id: \.self) { i in
                        Capsule()
                            .fill(i == current ? Self.albums[album].color : i < current ? Self.ink.opacity(0.55) : Self.ink.opacity(0.12))
                            .frame(width: lengths[i] * unit, height: 6)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 14)
            Text("\(current + 1)/5").font(Self.serif(14, italic: true)).foregroundStyle(Self.ink.opacity(0.5))
        }
    }

    private var crate: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("THE CRATE").font(Self.caps(11)).kerning(2.5).foregroundStyle(Self.ink.opacity(0.5))
                Spacer()
                Text("3 records").font(Self.serif(14, italic: true)).foregroundStyle(Self.ink.opacity(0.5))
            }
            HStack(spacing: 13) {
                ForEach(0..<3, id: \.self) { i in
                    let on = album == i
                    VStack(spacing: 8) {
                        Sleeve(kind: i)
                            .frame(width: 112, height: 112)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .shadow(color: Self.ink.opacity(on ? 0.35 : 0.15), radius: on ? 12 : 4, y: on ? 9 : 3)
                            .offset(y: on ? -8 : 0)
                            .scaleEffect(demo.isPressing(i + 2) ? 0.94 : 1)
                        Circle().fill(on ? Self.albums[i].color : .clear).frame(width: 6, height: 6)
                    }
                    .demoTap(i == 0 ? 99 : i + 2)
                }
            }
        }
    }
}

// MARK: - Deck

private struct Deck: View {
    @EnvironmentObject var demo: Demo
    static let size = CGSize(width: 362, height: 318)
    static let center = CGPoint(x: 166, y: 159)
    static let pivot = CGPoint(x: 332, y: 44)
    static let armLength: CGFloat = 228
    static let rps = 0.555

    private var swaps: [Date] { [demo.stepDate[3], demo.stepDate[4]].compactMap { $0 } }

    private var motor: Motor {
        var e: [(Date, Double)] = []
        if let d = demo.stepDate[1] { e.append((d, Self.rps)) }
        if let d = demo.stepDate[2] { e.append((d, 0.75)) }
        for s in swaps { e.append((s, 0)); e.append((s + 1.9, Self.rps)) }
        return Motor(e, tau: 0.5)
    }

    var body: some View {
        TimelineView(.animation) { tl in
            let now = tl.date
            let m = motor.state(at: now)
            let shown = swaps.filter { now.timeIntervalSince($0) >= 1.0 }.count
            let startPos = swaps.last.map { motor.state(at: $0 + 1.9).pos } ?? 0
            let seconds = (shown == 0 ? 62 : 0) + max(0, m.pos - startPos) / Self.rps

            ZStack(alignment: .topLeading) {
                Plinth()
                // Platter rim with strobe dots that turn with the record.
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xE4E1DA), Color(hex: 0x8D8981), Color(hex: 0xCFCBC3)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 304, height: 304)
                    .shadow(color: .black.opacity(0.45), radius: 10, y: 6)
                    .position(Self.center)
                StrobeDots().frame(width: 304, height: 304)
                    .rotationEffect(.degrees(m.pos * 360))
                    .position(Self.center)
                Record(album: PlatterApp.albums[shown])
                    .frame(width: 288, height: 288)
                    .rotationEffect(.degrees(m.pos * 360))
                    .overlay(Sheen())
                    .offset(x: recordOffset(now))
                    .position(Self.center)
                arm(now, seconds: seconds)
                plate(seconds: seconds, spinning: m.vel > 0.05)
            }
            .frame(width: Self.size.width, height: Self.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .shadow(color: Color(hex: 0x2A1608).opacity(0.35), radius: 18, y: 12)
    }

    /// The old record slides off to the left, then the new one slides back in.
    private func recordOffset(_ now: Date) -> CGFloat {
        guard let s = swaps.last else { return 0 }
        let dt = now.timeIntervalSince(s)
        if dt < 0.5 { return 0 }
        if dt < 1.0 { let x = (dt - 0.5) / 0.5; return -420 * x * x }
        return -420 * (1 - smooth((dt - 1.0) / 0.6))
    }

    /// 0 = resting, 1 = on the record. Lifts off and comes back around each swap.
    private func armDown(_ now: Date) -> Double {
        var on = ramp(now, demo.stepDate[1], dur: 1.0)
        for s in swaps { on *= 1 - ramp(now, s, dur: 0.55) + ramp(now, s, delay: 1.65, dur: 0.6) }
        return on
    }

    @ViewBuilder private func arm(_ now: Date, seconds: Double) -> some View {
        let on = armDown(now)
        let lifted = on > 0.01 && on < 0.99
        let angle = on * (21 + 7 * min(1, seconds / 300))
        let p = Self.pivot
        Circle()
            .fill(RadialGradient(colors: [Color(hex: 0xE6C98E), PlatterApp.brass, Color(hex: 0x7E5E2B)],
                                 center: .init(x: 0.35, y: 0.3), startRadius: 2, endRadius: 30))
            .frame(width: 50, height: 50)
            .shadow(color: .black.opacity(0.4), radius: 5, y: 3)
            .position(p)
        Tonearm(length: Self.armLength)
            .scaleEffect(lifted ? 1.015 : 1)
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.4), radius: lifted ? 7 : 2.5, x: lifted ? 9 : 3, y: lifted ? 12 : 4)
            .position(p)
        Circle().fill(Color(hex: 0x1D1A17)).frame(width: 16, height: 16)
            .overlay(Circle().fill(Color(hex: 0xBDB8AE)).frame(width: 6, height: 6))
            .position(p)
    }

    private func plate(seconds: Double, spinning: Bool) -> some View {
        HStack(spacing: 6) {
            Circle().fill(spinning ? Color(hex: 0xFF6A3D) : Color(hex: 0x5A2A1E))
                .frame(width: 6, height: 6)
                .shadow(color: Color(hex: 0xFF6A3D).opacity(spinning ? 0.9 : 0), radius: 4)
            Text(clock(seconds)).font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(hex: 0xE6C98E))
        }
        .padding(.horizontal, 9).frame(height: 26)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x1B120B).opacity(0.85)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(PlatterApp.brass.opacity(0.5), lineWidth: 1))
        .position(x: 314, y: 296)
    }
}

private struct Plinth: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(LinearGradient(colors: [Color(hex: 0x6E4527), Color(hex: 0x4A2C17), Color(hex: 0x5B3820)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                Canvas { ctx, size in
                    // Walnut grain: long wavy lines of slightly different shades.
                    for i in 0..<46 {
                        let y0 = CGFloat(i) * size.height / 44 - 6
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: y0))
                        for x in stride(from: 0.0, through: Double(size.width), by: 12) {
                            let y = y0 + CGFloat(sin(x / 61 + Double(i) * 0.9) * 4 + sin(x / 23 + Double(i) * 2.3) * 1.4)
                            p.addLine(to: CGPoint(x: x, y: y))
                        }
                        let a = 0.05 + 0.07 * Double((i * 7) % 5) / 4
                        ctx.stroke(p, with: .color((i % 3 == 0 ? Color.black : Color(hex: 0xC48A55)).opacity(a)), lineWidth: i % 4 == 0 ? 2 : 0.8)
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.12), lineWidth: 1).padding(1))
            .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

private struct StrobeDots: View {
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<72 {
                let a = Double(i) / 72 * 2 * .pi
                let p = CGPoint(x: c.x + 148 * cos(a), y: c.y + 148 * sin(a))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.3, y: p.y - 1.3, width: 2.6, height: 2.6)),
                         with: .color(.black.opacity(0.35)))
            }
        }
    }
}

private struct Record: View {
    let album: PlatterApp.Album
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x0F0E0D))
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<54 {
                    let r = 54 + CGFloat(i) * 1.6
                    let gap = [15, 29, 41].contains(i)
                    let a = gap ? 0.16 : 0.035 + 0.05 * Double((i * 7) % 5) / 4
                    ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                               with: .color(.white.opacity(a)), lineWidth: gap ? 1.4 : 0.7)
                }
            }
            label
        }
    }

    private var label: some View {
        ZStack {
            Circle().fill(album.color)
            Circle().stroke(album.label.opacity(0.5), lineWidth: 1).padding(5)
            VStack(spacing: 3) {
                Text(album.title.uppercased()).font(.custom("Baskerville-SemiBold", size: 9)).kerning(1.2)
                Rectangle().fill(album.label.opacity(0.6)).frame(width: 46, height: 0.8)
                Text("SIDE A · 33⅓").font(.system(size: 5.5, weight: .semibold)).kerning(1)
            }
            .foregroundStyle(album.label)
            .offset(y: 20)
            // Something lopsided, so the turning is easy to see.
            Capsule().fill(album.label).frame(width: 22, height: 6).offset(y: -27)
            Circle().fill(Color(hex: 0xD9D5CC)).frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
        }
        .frame(width: 98, height: 98)
    }
}

/// Light on the vinyl. It stays put while the record turns underneath.
private struct Sheen: View {
    var body: some View {
        Circle()
            .fill(AngularGradient(colors: [.white.opacity(0), .white.opacity(0.16), .white.opacity(0), .white.opacity(0),
                                           .white.opacity(0.12), .white.opacity(0), .white.opacity(0)],
                                  center: .center, angle: .degrees(-30)))
            .mask(Circle().strokeBorder(lineWidth: 92))
            .allowsHitTesting(false)
    }
}

private struct Tonearm: View {
    let length: CGFloat
    private let silver = LinearGradient(colors: [Color(hex: 0x8C8880), Color(hex: 0xF4F2EE), Color(hex: 0x9D9890)],
                                        startPoint: .leading, endPoint: .trailing)
    var body: some View {
        VStack(spacing: 0) {
            // Counterweight sits behind the pivot.
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x26221E)).frame(width: 26, height: 30)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.15), lineWidth: 1))
                Capsule().fill(silver).frame(width: 6, height: 14)
            }
            .frame(height: length)
            VStack(spacing: 0) {
                Capsule().fill(silver).frame(width: 6, height: length - 36)
                RoundedRectangle(cornerRadius: 3).fill(Color(hex: 0x1D1A17)).frame(width: 18, height: 36)
                    .overlay(alignment: .trailing) {
                        Capsule().fill(silver).frame(width: 12, height: 3).offset(x: 10, y: -6)
                    }
                    .overlay(alignment: .bottom) { Rectangle().fill(PlatterApp.brass).frame(width: 6, height: 4) }
                Spacer(minLength: 0)
            }
            .frame(height: length)
        }
        .frame(width: 44, height: length * 2)
    }
}

private struct Sleeve: View {
    let kind: Int
    var body: some View {
        let a = PlatterApp.albums[kind]
        ZStack(alignment: .topLeading) {
            a.color
            switch kind {
            case 0:
                Circle().fill(a.label).frame(width: 74, height: 74).offset(x: 46, y: 50)
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in Rectangle().fill(a.color).frame(height: 3) }
                }
                .offset(y: 84)
            case 1:
                ForEach(0..<4, id: \.self) { i in
                    Circle().stroke(a.label.opacity(0.85), lineWidth: 2)
                        .frame(width: CGFloat(40 + i * 26), height: CGFloat(40 + i * 26))
                        .position(x: 80, y: 82)
                }
                Circle().fill(a.label).frame(width: 18, height: 18).position(x: 80, y: 82)
            default:
                ForEach(0..<3, id: \.self) { i in
                    Circle().stroke(a.label, lineWidth: 2.5).frame(width: 46, height: 46)
                        .position(x: CGFloat(34 + i * 22), y: CGFloat(80 - i * 8))
                }
            }
            Text(a.title.uppercased()).font(.custom("Baskerville-SemiBold", size: 9)).kerning(1.2)
                .foregroundStyle(a.label).padding(9)
        }
        .overlay(LinearGradient(colors: [.white.opacity(0.14), .clear, .black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}
