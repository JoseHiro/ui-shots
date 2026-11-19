import SwiftUI

/// Tape: an 80s cassette deck. Reels turn and the tape really moves from one
/// spool to the other, VU needles bounce, piano keys latch down, and the
/// cassette flips over to side B.
struct TapeApp: View {
    @EnvironmentObject var demo: Demo

    static let shell = Color(hex: 0xE7DFCB)
    static let brown = Color(hex: 0x2E2520)
    static let orange = Color(hex: 0xE4572E)
    static let mustard = Color(hex: 0xEFA73A)
    static let teal = Color(hex: 0x2C7A73)
    static func cond(_ s: CGFloat) -> Font { .custom("AvenirNextCondensed-Heavy", size: s) }
    static func condDemi(_ s: CGFloat) -> Font { .custom("AvenirNextCondensed-DemiBold", size: s) }
    static func hand(_ s: CGFloat) -> Font { .custom("Noteworthy-Bold", size: s) }

    /// Pause before each step: play, fast-forward, play, flip to side B.
    static let script: [Double] = [1.8, 2.6, 1.8, 3.0]

    static let sides = [["Coastline Drive", "Peach Fuzz", "Night Swim", "Polaroid Summer"],
                        ["Rollerdisco", "Long Way Home", "Sundown Radio", "Last Bus"]]

    private var flipped: Bool { demo.step >= 4 }

    private var motor: Motor {
        var e: [(Date, Double)] = []
        if let d = demo.stepDate[1] { e.append((d, 1)) }
        if let d = demo.stepDate[2] { e.append((d, 5)) }
        if let d = demo.stepDate[3] { e.append((d, 1)) }
        if let d = demo.stepDate[4] { e.append((d, 0)); e.append((d + 1.1, 1)) }
        return Motor(e, tau: 0.25)
    }

    /// How far through the current side the tape is, 0...1.
    private func progress(_ pos: Double) -> Double {
        if let d = demo.stepDate[4] {
            let base = motor.state(at: d + 1.1).pos
            return min(0.98, 0.02 + max(0, pos - base) * 0.035)
        }
        return min(0.98, 0.18 + pos * 0.035)
    }

    var body: some View {
        ZStack {
            Self.shell.ignoresSafeArea()
            TimelineView(.animation) { tl in
                let m = motor.state(at: tl.date)
                let p = progress(m.pos)
                let ff = ramp(tl.date, demo.stepDate[2], dur: 0.25) * (1 - ramp(tl.date, demo.stepDate[3], dur: 0.25))
                let level = min(1, m.vel) * (1 - ff)
                VStack(spacing: 0) {
                    header.reveal(0)
                    door(pos: m.pos, p: p).reveal(1).padding(.top, 16)
                    HStack(spacing: 10) {
                        VUMeter(label: "L", level: level, t: tl.date.timeIntervalSinceReferenceDate)
                        VUMeter(label: "R", level: level, t: tl.date.timeIntervalSinceReferenceDate + 0.37)
                        Odometer(value: m.pos * 3)
                    }
                    .reveal(2).padding(.top, 18)
                    jCard(p: p).reveal(3).padding(.top, 18)
                    keys.reveal(4).padding(.top, 22)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("TAPE").font(Self.cond(42)).foregroundStyle(Self.brown)
            HStack(spacing: 4) {
                ForEach([Self.orange, Self.mustard, Self.teal], id: \.self) { c in
                    Rectangle().fill(c).frame(width: 9, height: 30).rotationEffect(.degrees(18))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("AUTO REVERSE").font(Self.condDemi(12)).kerning(1.5)
                Text("TYPE II · HIGH BIAS").font(Self.condDemi(12)).kerning(1.5).opacity(0.5)
            }
            .foregroundStyle(Self.brown)
        }
    }

    private func door(pos: Double, p: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0x231D19))
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x15110E)).padding(8)
                .shadow(color: .black, radius: 6)
            Flip(angle: flipped ? 180 : 0,
                 front: Cassette(side: "A", title: "Summer Mix '86", p: p, spin: pos),
                 back: Cassette(side: "B", title: "Summer Mix '86", p: p, spin: pos))
                .animation(.spring(response: 0.95, dampingFraction: 0.78), value: flipped)
                .scaleEffect(1.08)
            // Smoked glass over the door.
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [.white.opacity(0.13), .white.opacity(0.02), .clear, .white.opacity(0.05)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(8).allowsHitTesting(false)
        }
        .frame(height: 270)
    }

    private func jCard(p: Double) -> some View {
        let side = flipped ? 1 : 0
        let current = min(3, Int(p * 4))
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("SIDE \(flipped ? "B" : "A")").font(Self.cond(15)).kerning(2).foregroundStyle(Self.orange)
                Spacer()
                Text(flipped ? "for the ride home" : "for the drive out").font(Self.hand(13)).foregroundStyle(Self.brown.opacity(0.5))
            }
            ForEach(0..<4, id: \.self) { i in
                HStack(spacing: 8) {
                    Image(systemName: "play.fill").font(.system(size: 9)).foregroundStyle(Self.orange)
                        .opacity(i == current ? 1 : 0)
                    Text("\(i + 1).").font(Self.condDemi(14)).foregroundStyle(Self.brown.opacity(0.45))
                    Text(Self.sides[side][i]).font(Self.hand(16))
                        .foregroundStyle(Self.brown.opacity(i == current ? 1 : 0.45))
                    Spacer()
                }
                .frame(height: 27)
                .overlay(alignment: .bottom) { Rectangle().fill(Self.teal.opacity(0.25)).frame(height: 1) }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xFBF6EA)))
        .overlay(alignment: .leading) {
            Rectangle().fill(Self.orange.opacity(0.6)).frame(width: 1).padding(.leading, 30)
        }
        .shadow(color: Self.brown.opacity(0.15), radius: 6, y: 3)
    }

    private var keys: some View {
        HStack(spacing: 8) {
            PianoKey(icon: "backward.fill", label: "REW", tint: Self.shell, down: false)
            PianoKey(icon: "play.fill", label: "PLAY", tint: Self.orange,
                     down: [1, 3, 4].contains(demo.step) || demo.isPressing(1, 3))
                .demoTap(1, 3)
            PianoKey(icon: "forward.fill", label: "FF", tint: Self.shell, down: demo.step == 2 || demo.isPressing(2))
                .demoTap(2)
            PianoKey(icon: "arrow.left.arrow.right", label: "FLIP", tint: Self.mustard, down: demo.isPressing(4))
                .demoTap(4)
        }
    }
}

// MARK: - Cassette

/// A card that turns over around its vertical axis, showing `back` past 90°.
private struct Flip<Front: View, Back: View>: View, Animatable {
    var angle: Double
    let front: Front
    let back: Back
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    var body: some View {
        ZStack {
            front.opacity(angle < 90 ? 1 : 0)
            back.scaleEffect(x: -1).opacity(angle < 90 ? 0 : 1)
        }
        .scaleEffect(1 - 0.12 * sin(angle * .pi / 180))
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

private struct Cassette: View {
    let side: String
    let title: String
    let p: Double
    let spin: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color(hex: 0x3A3532))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.1), lineWidth: 1))
            ForEach(0..<4, id: \.self) { i in
                Screw().position(x: i % 2 == 0 ? 13 : 307, y: i < 2 ? 13 : 191)
            }
            label.frame(width: 290, height: 140).position(x: 160, y: 84)
            Trapezoid().fill(Color(hex: 0x2B2725)).frame(width: 196, height: 40).position(x: 160, y: 184)
            HStack(spacing: 30) {
                ForEach(0..<4, id: \.self) { i in
                    Circle().fill(Color(hex: 0x15110E)).frame(width: i == 1 || i == 2 ? 11 : 8)
                }
            }
            .position(x: 160, y: 188)
        }
        .frame(width: 320, height: 204)
        .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
    }

    private var label: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                Text(side).font(TapeApp.cond(26)).foregroundStyle(TapeApp.brown)
                Text(title).font(TapeApp.hand(19)).foregroundStyle(Color(hex: 0x1F3C8F))
                    .rotationEffect(.degrees(-2))
                Spacer()
                Text("C60").font(TapeApp.cond(13)).foregroundStyle(TapeApp.brown.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            ZStack {
                VStack(spacing: 0) {
                    TapeApp.orange.frame(height: 20)
                    TapeApp.mustard.frame(height: 20)
                    TapeApp.teal.frame(height: 20)
                }
                window
            }
            .frame(height: 66)
            HStack {
                Text("NR ON").font(TapeApp.condDemi(10)).kerning(1.5)
                Spacer()
                Text("70µs · 30 MIN").font(TapeApp.condDemi(10)).kerning(1.5)
            }
            .foregroundStyle(TapeApp.brown.opacity(0.6))
            .padding(.horizontal, 12)
            .frame(height: 36, alignment: .center)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xF4EEDD)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Two spools seen through the window. Tape leaves the left one and builds up on the right.
    private var window: some View {
        let hub: CGFloat = 15, full: CGFloat = 56
        let rl = sqrt(hub * hub + (full * full - hub * hub) * (1 - p))
        let rr = sqrt(hub * hub + (full * full - hub * hub) * p)
        return ZStack {
            Color(hex: 0x1A1512)
            Circle().fill(Color(hex: 0x5A3522)).frame(width: rl * 2, height: rl * 2).offset(x: -62)
            Circle().fill(Color(hex: 0x5A3522)).frame(width: rr * 2, height: rr * 2).offset(x: 62)
            Hub().rotationEffect(.degrees(spin * 150)).offset(x: -62)
            Hub().rotationEffect(.degrees(spin * 150)).offset(x: 62)
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { _ in Rectangle().fill(.white.opacity(0.35)).frame(width: 1, height: 8) }
            }
            LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .top, endPoint: .center)
        }
        .frame(width: 204, height: 58)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(.black.opacity(0.5), lineWidth: 1.5))
    }
}

private struct Hub: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0xF1EDE4)).frame(width: 30, height: 30)
            Circle().fill(Color(hex: 0x1A1512)).frame(width: 18, height: 18)
            ForEach(0..<6, id: \.self) { i in
                Rectangle().fill(Color(hex: 0xF1EDE4)).frame(width: 3, height: 5)
                    .offset(y: -7).rotationEffect(.degrees(Double(i) * 60))
            }
            Circle().fill(TapeApp.orange).frame(width: 5, height: 5).offset(y: -12)
        }
    }
}

private struct Screw: View {
    var body: some View {
        Circle().fill(Color(hex: 0x8B857E)).frame(width: 9, height: 9)
            .overlay(Rectangle().fill(Color(hex: 0x3A3532)).frame(width: 7, height: 1.4).rotationEffect(.degrees(35)))
    }
}

private struct Trapezoid: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 18, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - 18, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Meters and keys

private struct VUMeter: View {
    let label: String
    let level: Double
    let t: Double

    var body: some View {
        let music = 0.55 + 0.25 * sin(t * 7.1) * sin(t * 2.3) + 0.2 * sin(t * 13.7 + 1)
        let angle = -48 + 96 * level * max(0, min(1, music))
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x2A231F))
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: [Color(hex: 0xFCEBC0), Color(hex: 0xEFCF8A)], startPoint: .top, endPoint: .bottom))
                .padding(5)
                .shadow(color: Color(hex: 0xFFB84D).opacity(0.25 + 0.5 * level), radius: 8)
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height + 14)
                for i in 0...10 {
                    let a = (-48 + Double(i) * 9.6 - 90) * .pi / 180
                    let r1: CGFloat = 50, r2: CGFloat = i % 5 == 0 ? 60 : 56
                    var p = Path()
                    p.move(to: CGPoint(x: c.x + r1 * cos(a), y: c.y + r1 * sin(a)))
                    p.addLine(to: CGPoint(x: c.x + r2 * cos(a), y: c.y + r2 * sin(a)))
                    ctx.stroke(p, with: .color(i >= 8 ? TapeApp.orange : TapeApp.brown), lineWidth: 1.2)
                }
                var arc = Path()
                arc.addArc(center: c, radius: 50, startAngle: .degrees(-138), endAngle: .degrees(-42), clockwise: false)
                ctx.stroke(arc, with: .color(TapeApp.brown.opacity(0.7)), lineWidth: 1)
            }
            .padding(5)
            Text("VU").font(TapeApp.cond(11)).foregroundStyle(TapeApp.brown.opacity(0.6)).offset(y: 10)
            Text(label).font(TapeApp.cond(10)).foregroundStyle(TapeApp.brown.opacity(0.5)).offset(x: -38, y: 20)
            Capsule().fill(TapeApp.brown).frame(width: 1.6, height: 58)
                .offset(y: -29)
                .rotationEffect(.degrees(angle), anchor: .center)
                .offset(y: 47)
                .frame(width: 100, height: 76)
                .clipped()
        }
        .frame(height: 76)
    }
}

/// Mechanical tape counter: the ones drum turns smoothly, the others roll over in step.
private struct Odometer: View {
    let value: Double

    var body: some View {
        let ones = value.truncatingRemainder(dividingBy: 10)
        let tens = floor(value / 10) + max(0, ones - 9)
        let tensFrac = tens.truncatingRemainder(dividingBy: 10)
        let hundreds = floor(value / 100) + max(0, tensFrac - 9)
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                drum(hundreds.truncatingRemainder(dividingBy: 10))
                drum(tensFrac)
                drum(ones)
            }
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0x2A231F)))
            Text("COUNTER").font(TapeApp.condDemi(10)).kerning(1.5).foregroundStyle(TapeApp.brown.opacity(0.6))
        }
        .frame(width: 104, height: 76)
    }

    private func drum(_ v: Double) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<11, id: \.self) { d in
                Text("\(d % 10)").font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white).frame(width: 24, height: 34)
            }
        }
        .offset(y: 34 * 5 - 34 * v)
        .frame(width: 24, height: 34)
        .clipped()
        .background(Color(hex: 0x14100D))
        .overlay(LinearGradient(colors: [.black.opacity(0.6), .clear, .clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
    }
}

private struct PianoKey: View {
    let icon: String
    let label: String
    let tint: Color
    let down: Bool

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 7).fill(Color(hex: 0x2A231F)).frame(height: 74).offset(y: 7)
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 17, weight: .heavy))
                Text(label).font(TapeApp.cond(11)).kerning(1.5)
            }
            .foregroundStyle(TapeApp.brown)
            .frame(maxWidth: .infinity).frame(height: 74)
            .background(RoundedRectangle(cornerRadius: 7).fill(tint))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.4), lineWidth: 1).padding(1))
            .brightness(down ? -0.08 : 0)
            .offset(y: down ? 6 : 0)
        }
        .frame(height: 81, alignment: .top)
    }
}
