import SwiftUI

/// Letter: slow mail. The note writes itself, folds into thirds in 3D, slides into
/// an envelope that is sealed with wax and posted. "Read" is the seal being broken.
struct LetterApp: View {
    @EnvironmentObject var demo: Demo

    /// Pause before each step: fold and seal, send, open the reply.
    static let script: [Double] = [3.3, 3.4, 3.4]

    static let desk = Color(hex: 0xEDE3D0)
    static let ink = Color(hex: 0x233061)
    static let cream = Color(hex: 0xFBF6EA)
    static let paperBack = Color(hex: 0xEFE6D2)
    static let kraft = Color(hex: 0xE4CFA8)
    static let kraftDark = Color(hex: 0xC9AE82)
    static let kraftFlap = Color(hex: 0xDCC499)
    static let wax = Color(hex: 0xA3271F)
    static let brown = Color(hex: 0x5A4632)
    static func hand(_ s: CGFloat) -> Font { .custom("BradleyHandITCTT-Bold", size: s) }
    static func serif(_ s: CGFloat, _ w: Font.Weight = .regular) -> Font { .system(size: s, weight: w, design: .serif) }

    static let W: CGFloat = 320, H: CGFloat = 390, ph: CGFloat = 130
    static let EW: CGFloat = 344, EH: CGFloat = 216
    static let lineH: CGFloat = 44, top: CGFloat = 34

    static let outgoing = ["Dear Mika,", "Tokyo is cold, but the", "ramen is still perfect.",
                           "Dinner on Friday?", "Write back soon,", "               — Sam"]
    static let reply = ["Dear Sam,", "Friday is perfect!", "The usual place at 7?",
                        "I'll bring the photos", "from Kyoto ✿", "               — Mika"]
    static let perChar = 0.026

    var body: some View {
        ZStack {
            Self.desk.ignoresSafeArea()
            RadialGradient(colors: [.white.opacity(0.45), .clear], center: .init(x: 0.5, y: 0.4), startRadius: 20, endRadius: 520)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                header.reveal(0)
                TimelineView(.animation) { tl in
                    VStack(spacing: 0) {
                        stage(tl.date).reveal(1)
                        bottom(tl.date).reveal(2)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Letters").font(.custom("SnellRoundhand-Bold", size: 44)).foregroundStyle(Self.ink)
                Text("Correspondence with Mika · Kyoto").font(Self.serif(14).italic()).foregroundStyle(Self.brown.opacity(0.7))
            }
            Spacer()
            stamp.rotationEffect(.degrees(6))
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    private var stamp: some View {
        VStack(spacing: 2) {
            Image(systemName: "leaf.fill").font(.system(size: 18)).foregroundStyle(Color(hex: 0x4F7B4A))
            Text("¥110").font(Self.serif(10, .bold)).foregroundStyle(Self.brown)
        }
        .frame(width: 46, height: 54)
        .background(Rectangle().fill(Color(hex: 0xF7EFDD)).padding(3).background(Color(hex: 0xC8442E).opacity(0.85)))
        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }

    // MARK: Stage

    private struct Pose {
        var a1 = 0.0, a2 = 0.0               // bottom and top third folded (0...180)
        var sheetY: CGFloat = 0, sheetScale: CGFloat = 1
        var env = false
        var envY: CGFloat = 0, flap = 180.0
        var seal = 0.0, crack = 0.0, label = 0.0
        var gx: CGFloat = 0, gy: CGFloat = 0, rot = 0.0, scale: CGFloat = 1
        var incoming = false
        var write: Double? = nil            // seconds since writing began; nil = fully written
    }

    private func pose(_ now: Date) -> Pose {
        func since(_ s: Int) -> Double { demo.stepDate[s].map { now.timeIntervalSince($0) } ?? -1 }
        let f = since(1), g = since(2), h = since(3)
        var p = Pose()
        if g < 2.2 {
            p.write = demo.appearDate.map { now.timeIntervalSince($0) - 0.4 } ?? 0
            guard f >= 0 else { return p }
            p.a1 = smooth(f / 0.55) * 180
            p.a2 = smooth((f - 0.5) / 0.55) * 180
            p.env = f > 1.0
            p.envY = 50 + 660 * (1 - smooth((f - 1.05) / 0.6))
            p.sheetScale = 1 - 0.06 * smooth((f - 1.2) / 0.5)
            p.sheetY = 50 * smooth((f - 1.7) / 0.4)
            p.flap = 180 * (1 - smooth((f - 2.1) / 0.4))
            p.seal = f > 2.5 ? max(0, boing(f - 2.5, k: 8, w: 16)) : 0
            p.label = smooth((f - 2.8) / 0.5)
            if g >= 0 {
                let fly = smooth(g / 0.95)
                p.gy = -820 * fly * fly
                p.gx = 70 * fly
                p.rot = -12 * fly
                p.scale = 1 - 0.45 * fly
            }
        } else {
            p.incoming = true
            let k = g - 2.3
            let arrive = k < 0 ? 0 : boing(k, k: 6, w: 11)
            p.gy = -760 * (1 - arrive)
            p.rot = 8 * (1 - arrive)
            p.a1 = 180; p.a2 = 180
            p.env = true
            p.envY = 50; p.sheetY = 50; p.sheetScale = 0.94
            p.flap = 0; p.seal = 1; p.label = 1
            if h >= 0 {
                p.crack = smooth(h / 0.35)
                p.flap = 180 * smooth((h - 0.3) / 0.45)
                let out = smooth((h - 0.75) / 0.55), back = smooth((h - 1.5) / 0.5)
                p.sheetY = 50 - 210 * out + 160 * back
                p.sheetScale = 0.94 + 0.06 * back
                p.envY = 50 + 720 * smooth((h - 1.25) / 0.5)
                p.env = h < 1.8
                p.a2 = 180 * (1 - smooth((h - 1.9) / 0.5))
                p.a1 = 180 * (1 - smooth((h - 2.3) / 0.5))
            }
        }
        return p
    }

    private func stage(_ now: Date) -> some View {
        let p = pose(now)
        let lines = p.incoming ? Self.reply : Self.outgoing
        let paper = paperView(lines, write: p.incoming ? nil : p.write)
        let openFlap = p.flap > 90
        return ZStack {
            Group {
                if p.env { envBack.offset(y: p.envY) }
                if p.env && openFlap { flap(p.flap).offset(y: p.envY) }
                folded(paper, a1: p.a1, a2: p.a2)
                    .scaleEffect(p.sheetScale)
                    .offset(y: p.sheetY)
                if p.env {
                    envFront(label: p.label, from: p.incoming).offset(y: p.envY)
                    if !openFlap { flap(p.flap).offset(y: p.envY) }
                    if p.seal > 0 { seal(p.seal, crack: p.crack, letter: p.incoming ? "M" : "S").offset(y: p.envY - Self.EH / 2 + Self.EH * 0.56 - 4) }
                }
            }
            .rotationEffect(.degrees(p.rot))
            .scaleEffect(p.scale)
            .offset(x: p.gx, y: p.gy)

            if let w = p.write, demo.step == 0 { pen(lines, write: w) }

            Color.clear.frame(width: Self.EW, height: Self.EH).padding(.top, 100).demoTap(3)
        }
        .frame(width: 402, height: 500)
    }

    // MARK: Paper

    private func reveal(_ lines: [String], _ i: Int, write: Double?) -> Double {
        guard let w = write else { return 1 }
        let start = lines[..<i].reduce(0) { $0 + Double($1.count) * Self.perChar + 0.12 }
        return min(1, max(0, (w - start) / (Double(lines[i].count) * Self.perChar)))
    }

    private func estWidth(_ s: String) -> CGFloat { CGFloat(s.count) * 11.5 + 14 }

    private func paperView(_ lines: [String], write: Double?) -> some View {
        ZStack(alignment: .topLeading) {
            Self.cream
            Canvas { ctx, size in
                for i in 0..<7 {
                    let y = Self.top + CGFloat(i + 1) * Self.lineH - 6
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(Color(hex: 0x7C94C4).opacity(0.25)))
                }
                ctx.fill(Path(CGRect(x: 30, y: 0, width: 1.2, height: size.height)), with: .color(Color(hex: 0xD86A5E).opacity(0.35)))
            }
            ForEach(lines.indices, id: \.self) { i in
                let r = reveal(lines, i, write: write)
                Text(lines[i])
                    .font(Self.hand(24))
                    .foregroundStyle(Self.ink)
                    .fixedSize()
                    .frame(height: Self.lineH, alignment: .bottomLeading)
                    .mask(alignment: .leading) { Rectangle().frame(width: r >= 1 ? 400 : estWidth(lines[i]) * r) }
                    .offset(x: 40, y: Self.top + CGFloat(i) * Self.lineH - 12)
            }
        }
        .frame(width: Self.W, height: Self.H)
    }

    private func pen(_ lines: [String], write: Double) -> some View {
        let total = lines.indices.reduce(0.0) { $0 + Double(lines[$1].count) * Self.perChar + 0.12 }
        let i = lines.indices.last { reveal(lines, $0, write: write) > 0 } ?? 0
        let x = -Self.W / 2 + 40 + estWidth(lines[i]) * reveal(lines, i, write: write)
        let y = -Self.H / 2 + Self.top + CGFloat(i) * Self.lineH + 14
        let wiggle = sin(write * 40) * 1.5
        return Image(systemName: "pencil")
            .font(.system(size: 30, weight: .regular))
            .foregroundStyle(Self.ink)
            .rotationEffect(.degrees(-10))
            .offset(x: x + 14, y: y - 14 + wiggle)
            .opacity(write > 0 && write < total + 0.3 ? 1 : 0)
            .animation(.easeOut(duration: 0.25), value: write < total + 0.3)
    }

    private func panel<P: View>(_ paper: P, _ i: Int, angle: Double) -> some View {
        let back = angle > 90
        return paper
            .offset(y: CGFloat(1 - i) * Self.ph)
            .frame(width: Self.W, height: Self.ph)
            .clipped()
            .overlay(Self.paperBack.opacity(back ? 1 : 0))
            .overlay(Color.black.opacity(0.14 * sin(angle * .pi / 180)))
    }

    private func folded<P: View>(_ paper: P, a1: Double, a2: Double) -> some View {
        ZStack {
            panel(paper, 1, angle: 0)
            panel(paper, 2, angle: a1)
                .rotation3DEffect(.degrees(a1), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.35)
                .offset(y: Self.ph)
            panel(paper, 0, angle: a2)
                .rotation3DEffect(.degrees(-a2), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.35)
                .offset(y: -Self.ph)
        }
        .compositingGroup()
        .shadow(color: .black.opacity(0.14), radius: 10, y: 6)
    }

    // MARK: Envelope

    private var envBack: some View {
        RoundedRectangle(cornerRadius: 4).fill(Self.kraftDark)
            .frame(width: Self.EW, height: Self.EH)
            .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
    }

    private struct Pocket: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.52))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.closeSubpath()
            return p
        }
    }

    private struct FlapShape: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.58),
                           control: CGPoint(x: r.midX + r.width * 0.12, y: r.minY + r.height * 0.5))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY),
                           control: CGPoint(x: r.midX - r.width * 0.12, y: r.minY + r.height * 0.5))
            return p
        }
    }

    private func envFront(label: Double, from: Bool) -> some View {
        ZStack {
            Pocket().fill(Self.kraft)
            Canvas { ctx, s in
                var l = Path()
                l.move(to: CGPoint(x: 0, y: s.height)); l.addLine(to: CGPoint(x: s.width * 0.43, y: s.height * 0.48))
                l.move(to: CGPoint(x: s.width, y: s.height)); l.addLine(to: CGPoint(x: s.width * 0.57, y: s.height * 0.48))
                ctx.stroke(l, with: .color(Self.kraftDark.opacity(0.7)), lineWidth: 1)
            }
            Text(from ? "from Mika, Kyoto" : "to Mika, Kyoto")
                .font(Self.hand(22)).foregroundStyle(Self.ink)
                .mask(alignment: .leading) { Rectangle().frame(width: 200 * label) }
                .frame(width: 190, alignment: .leading)
                .offset(x: 66, y: 74)
        }
        .frame(width: Self.EW, height: Self.EH)
    }

    private func flap(_ angle: Double) -> some View {
        FlapShape().fill(angle > 90 ? Self.kraftDark.opacity(0.9) : Self.kraftFlap)
            .overlay(FlapShape().stroke(Self.kraftDark.opacity(0.6), lineWidth: 1))
            .frame(width: Self.EW, height: Self.EH)
            .shadow(color: .black.opacity(angle > 90 ? 0 : 0.12), radius: 3, y: 2)
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.4)
    }

    private struct Blob: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            let c = CGPoint(x: r.midX, y: r.midY), R = min(r.width, r.height) / 2
            for i in 0...48 {
                let a = Double(i) / 48 * 2 * .pi
                let k = R * (0.92 + 0.05 * sin(a * 7) + 0.03 * sin(a * 11 + 1))
                let pt = CGPoint(x: c.x + cos(a) * k, y: c.y + sin(a) * k)
                i == 0 ? p.move(to: pt) : p.addLine(to: pt)
            }
            p.closeSubpath()
            return p
        }
    }

    private func sealFace(_ letter: String) -> some View {
        ZStack {
            Blob().fill(Self.wax)
            Circle().stroke(Color.black.opacity(0.2), lineWidth: 2).padding(10)
            Circle().stroke(Color.white.opacity(0.18), lineWidth: 1).padding(12)
            Text(letter).font(.custom("SnellRoundhand-Bold", size: 34)).foregroundStyle(Color.black.opacity(0.28))
                .offset(x: 1, y: 1)
            Text(letter).font(.custom("SnellRoundhand-Bold", size: 34)).foregroundStyle(Color(hex: 0xD9584C))
        }
        .frame(width: 66, height: 66)
        .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
    }

    private func seal(_ pop: Double, crack: Double, letter: String) -> some View {
        let face = sealFace(letter)
        let slam = 1 + 1.6 * max(0, 1 - pop)
        return ZStack {
            if crack <= 0 {
                face
            } else {
                face.mask(Rectangle().frame(width: 33).offset(x: -16.5))
                    .rotationEffect(.degrees(-35 * crack)).offset(x: -26 * crack, y: 50 * crack * crack)
                face.mask(Rectangle().frame(width: 33).offset(x: 16.5))
                    .rotationEffect(.degrees(30 * crack)).offset(x: 26 * crack, y: 46 * crack * crack)
            }
        }
        .opacity(1 - crack)
        .scaleEffect(slam)
    }

    // MARK: Bottom

    private func bottom(_ now: Date) -> some View {
        let g = demo.stepDate[2].map { now.timeIntervalSince($0) } ?? -1
        let h = demo.stepDate[3].map { now.timeIntervalSince($0) } ?? -1
        return ZStack {
            if demo.step < 2 {
                actionButton.transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                tracker(g: g, h: h).transition(.opacity.combined(with: .offset(y: 16)))
            }
        }
        .frame(height: 150)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: demo.step < 2)
    }

    private var actionButton: some View {
        let fold = demo.step == 0
        return HStack(spacing: 10) {
            Image(systemName: fold ? "envelope.fill" : "paperplane.fill")
                .contentTransition(.symbolEffect(.replace))
            Text(fold ? "Fold & seal" : "Post the letter")
                .contentTransition(.opacity)
        }
        .font(Self.serif(19, .semibold))
        .foregroundStyle(Self.cream)
        .padding(.horizontal, 30)
        .frame(height: 58)
        .background(Capsule().fill(Self.ink).shadow(color: Self.ink.opacity(0.35), radius: 12, y: 6))
        .scaleEffect(demo.isPressing(1, 2) ? 0.92 : 1)
        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: demo.isPressing(1, 2))
        .demoTap(1, 2)
    }

    private func tracker(g: Double, h: Double) -> some View {
        let marks = [0.2, 0.7, 1.2, 1.7]
        let names = ["Posted", "In transit", "Delivered", "Opened"]
        let icons = ["tray.and.arrow.up.fill", "truck.box.fill", "mailbox.fill", "envelope.open.fill"]
        let lit = marks.filter { g >= $0 }.count
        let fill = max(0, min(1, (g - 0.2) / 1.5))
        let status: String = h >= 0 ? "A letter from Mika · Kyoto"
            : g >= 2.4 ? "Mika wrote back · tap to open"
            : ["", "Sealed and posted", "On its way to Kyoto", "Delivered to Mika", "Mika broke the seal · 9:58"][lit]
        return VStack(spacing: 14) {
            ZStack(alignment: .leading) {
                Capsule().fill(Self.brown.opacity(0.15)).frame(height: 4)
                Capsule().fill(Self.wax).frame(width: 300 * fill, height: 4)
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        if i > 0 { Spacer(minLength: 0) }
                        let on = i < lit
                        Image(systemName: icons[i])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(on ? Self.cream : Self.brown.opacity(0.4))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(on ? (i == 3 ? Self.wax : Self.ink) : Self.cream))
                            .overlay(Circle().stroke(Self.brown.opacity(on ? 0 : 0.25), lineWidth: 1.5))
                            .scaleEffect(on ? 1 : 0.85)
                            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: on)
                    }
                }
            }
            .frame(width: 338)
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    Text(names[i]).font(Self.serif(12, .semibold))
                        .foregroundStyle(Self.brown.opacity(i < lit ? 0.9 : 0.4))
                        .frame(width: 84)
                }
            }
            Text(status)
                .font(Self.serif(17).italic())
                .foregroundStyle(lit == 4 && h < 0 && g < 2.4 ? Self.wax : Self.ink)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: status)
        }
        .padding(.top, 6)
    }
}
