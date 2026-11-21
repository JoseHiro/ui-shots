import SwiftUI

/// Postcard: a travel scrapbook. A new polaroid drops in and develops, the
/// postcard turns over and writes itself, gets postmarked, and flies off.
struct PostcardApp: View {
    @EnvironmentObject var demo: Demo

    static let paper = Color(hex: 0xF3EBDD)
    static let ink = Color(hex: 0x2B2A33)
    static let navy = Color(hex: 0x1F3C88)
    static let red = Color(hex: 0xC8452B)
    static func script(_ s: CGFloat) -> Font { .custom("SnellRoundhand-Bold", size: s) }
    static func hand(_ s: CGFloat) -> Font { .custom("Noteworthy-Bold", size: s) }
    static func type(_ s: CGFloat) -> Font { .custom("AmericanTypewriter", size: s) }

    /// Pause before each step: add photo, turn the card over, postmark, send.
    static let script: [Double] = [1.8, 3.0, 3.4, 2.4]

    private var dropped: Bool { demo.step >= 1 }
    private var flipped: Bool { demo.step >= 2 }
    private var stamped: Bool { demo.step >= 3 }
    private var sent: Bool { demo.step >= 4 }

    var body: some View {
        ZStack {
            Self.paper.ignoresSafeArea()
            PaperGrain().ignoresSafeArea()
            VStack(spacing: 0) {
                header.reveal(0).padding(.horizontal, 22)
                collage.padding(.top, 6)
                toolbar.reveal(5).padding(.horizontal, 20)
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: -6) {
                Text("Lisbon").font(Self.script(50)).foregroundStyle(Self.ink)
                Text("DAY 4 · NOV 21").font(Self.type(13)).kerning(2).foregroundStyle(Self.ink.opacity(0.55))
            }
            Spacer()
            Washi(color: Color(hex: 0xE9A6A0)).frame(width: 74, height: 22).rotationEffect(.degrees(8))
                .overlay(Text("p. 12").font(Self.hand(13)).foregroundStyle(Self.ink.opacity(0.7)).rotationEffect(.degrees(8)))
                .padding(.bottom, 16)
        }
    }

    private var collage: some View {
        ZStack {
            Polaroid(scene: 0, caption: "tram 28!")
                .frame(width: 166)
                .rotationEffect(.degrees(-7))
                .overlay(alignment: .top) { Washi(color: Color(hex: 0x9CC7C4)).frame(width: 60, height: 18).offset(y: -8) }
                .position(x: 104, y: 128)
                .reveal(1)
            Ticket()
                .rotationEffect(.degrees(10))
                .position(x: 304, y: 70)
                .reveal(2)
            Polaroid(scene: 1, caption: "sunset at the pier")
                .frame(width: 166)
                .rotationEffect(.degrees(6))
                .overlay(alignment: .topTrailing) { Washi(color: Color(hex: 0xF2CF6B)).frame(width: 54, height: 18).rotationEffect(.degrees(40)).offset(x: 10, y: 4) }
                .position(x: 294, y: 212)
                .reveal(2)
            // The new photo falls in from above and then develops.
            Polaroid(scene: 2, caption: "alfama rooftops", develop: demo.step >= 1)
                .frame(width: 156)
                .rotationEffect(.degrees(dropped ? -3 : -28))
                .scaleEffect(dropped ? 1 : 1.25)
                .shadow(color: .black.opacity(dropped ? 0.12 : 0.3), radius: dropped ? 6 : 22, y: dropped ? 4 : 20)
                .position(x: dropped ? 190 : 230, y: dropped ? 176 : -460)
                .animation(.spring(response: 0.7, dampingFraction: 0.68), value: dropped)
            postcard
                .rotationEffect(.degrees(sent ? 24 : -2))
                .scaleEffect(sent ? 0.25 : 1)
                .offset(x: sent ? 260 : 0, y: sent ? -420 : 0)
                .opacity(sent ? 0 : 1)
                .animation(.easeIn(duration: 0.9), value: sent)
                .position(x: 201, y: 462)
                .reveal(3)
            if sent {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                    Text("Sent to Tokyo").font(Self.hand(17))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18).frame(height: 44)
                .background(Capsule().fill(Self.navy))
                .shadow(color: Self.navy.opacity(0.35), radius: 10, y: 5)
                .transition(.scale(scale: 0.6).combined(with: .opacity).animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.7)))
                .position(x: 201, y: 462)
            }
        }
        .frame(width: 402, height: 600)
    }

    private var postcard: some View {
        Flip(angle: flipped ? 180 : 0, front: CardFront(), back: CardBack(write: flipped, stamped: stamped))
            .animation(.spring(response: 0.9, dampingFraction: 0.8), value: flipped)
            .frame(width: 346, height: 224)
            .rotationEffect(.degrees(stamped && !sent ? 0.6 : 0))
            .animation(.spring(response: 0.12, dampingFraction: 0.2).delay(0.25), value: stamped)
            .scaleEffect(demo.isPressing(2) ? 0.97 : 1)
            .demoTap(2)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            tool("camera.fill", "Photo", step: 1)
            tool("seal.fill", "Stamp", step: 3)
            tool("paperplane.fill", "Send", step: 4, filled: true)
        }
    }

    private func tool(_ icon: String, _ label: String, step: Int, filled: Bool = false) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold))
            Text(label).font(Self.hand(16))
        }
        .foregroundStyle(filled ? .white : Self.ink)
        .frame(maxWidth: .infinity).frame(height: 50)
        .background(Capsule().fill(filled ? Self.red : Color(hex: 0xE5D6BC)))
        .overlay(Capsule().strokeBorder(Self.ink.opacity(0.18), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])).padding(3))
        .scaleEffect(demo.isPressing(step) ? 0.92 : 1)
        .demoTap(step)
    }
}

// MARK: - Pieces

private struct PaperGrain: View {
    var body: some View {
        Canvas { ctx, size in
            var seed: UInt64 = 3
            func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat(seed >> 33) / CGFloat(1 << 31) }
            for _ in 0..<900 {
                let r = 0.6 + rnd() * 1.4
                ctx.fill(Path(ellipseIn: CGRect(x: rnd() * size.width, y: rnd() * size.height, width: r, height: r)),
                         with: .color(Color(hex: 0x8A6E45).opacity(0.05 + 0.08 * Double(rnd()))))
            }
        }
    }
}

private struct Washi: View {
    let color: Color
    var body: some View {
        Rectangle().fill(color.opacity(0.75))
            .overlay(
                HStack(spacing: 5) {
                    ForEach(0..<14, id: \.self) { _ in Rectangle().fill(.white.opacity(0.3)).frame(width: 2) }
                }
                .rotationEffect(.degrees(20))
            )
            .clipped()
            .mask(ZigzagEnds())
    }
}

private struct ZigzagEnds: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 5, d: CGFloat = 3
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        for k in 0..<n {
            let y = r.minY + r.height * CGFloat(k * 2 + 1) / CGFloat(n * 2)
            p.addLine(to: CGPoint(x: r.maxX - d, y: y))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * CGFloat(k + 1) / CGFloat(n)))
        }
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        for k in 0..<n {
            let y = r.maxY - r.height * CGFloat(k * 2 + 1) / CGFloat(n * 2)
            p.addLine(to: CGPoint(x: r.minX + d, y: y))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * CGFloat(k + 1) / CGFloat(n)))
        }
        p.closeSubpath()
        return p
    }
}

private struct Polaroid: View {
    let scene: Int
    let caption: String
    var develop = true

    var body: some View {
        VStack(spacing: 6) {
            Photo(scene: scene)
                .aspectRatio(1, contentMode: .fit)
                .saturation(develop ? 1 : 0)
                .overlay(Color(hex: 0xEDEAE2).opacity(develop ? 0 : 1))
                .animation(.easeInOut(duration: 2.0).delay(0.9), value: develop)
            Text(caption).font(PostcardApp.hand(14)).foregroundStyle(PostcardApp.ink.opacity(0.8))
                .frame(height: 20)
        }
        .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 6)
        .background(Color(hex: 0xFDFCF8))
        .shadow(color: .black.opacity(0.14), radius: 6, y: 4)
    }
}

/// Little painted scenes: a yellow tram on a hill, a pier sunset, rooftops.
private struct Photo: View {
    let scene: Int
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                switch scene {
                case 0:
                    LinearGradient(colors: [Color(hex: 0x8CC8EA), Color(hex: 0xD8EEF5)], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<4, id: \.self) { k in
                        Rectangle().fill([Color(hex: 0xF2B8A0), Color(hex: 0xF5E1A4), Color(hex: 0xA9D3C8), Color(hex: 0xE9C2D4)][k])
                            .frame(width: w * 0.28, height: h * (0.42 + 0.1 * CGFloat(k % 2)))
                            .position(x: w * (0.12 + 0.26 * CGFloat(k)), y: h * 0.45)
                    }
                    Path { p in p.move(to: CGPoint(x: 0, y: h * 0.95)); p.addLine(to: CGPoint(x: w, y: h * 0.62)); p.addLine(to: CGPoint(x: w, y: h)); p.addLine(to: CGPoint(x: 0, y: h)) }
                        .fill(Color(hex: 0x8B8178))
                    RoundedRectangle(cornerRadius: 5).fill(Color(hex: 0xF7C531))
                        .frame(width: w * 0.5, height: h * 0.3)
                        .overlay(HStack(spacing: 3) { ForEach(0..<4, id: \.self) { _ in Rectangle().fill(Color(hex: 0x3B4A5A)).frame(height: h * 0.1) } }.padding(.horizontal, 5).offset(y: -h * 0.04))
                        .overlay(alignment: .bottom) { Rectangle().fill(.white).frame(height: 3).padding(.bottom, 6) }
                        .rotationEffect(.degrees(-16))
                        .position(x: w * 0.5, y: h * 0.7)
                case 1:
                    LinearGradient(colors: [Color(hex: 0xF7A35C), Color(hex: 0xF06B7A), Color(hex: 0x7A5BA6)], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Color(hex: 0xFFE3A3)).frame(width: w * 0.36).position(x: w * 0.5, y: h * 0.56)
                    Rectangle().fill(Color(hex: 0x3B3D7A)).frame(height: h * 0.34).position(x: w / 2, y: h * 0.83)
                    ForEach(0..<4, id: \.self) { k in
                        Capsule().fill(Color(hex: 0xFFE3A3).opacity(0.7)).frame(width: w * (0.3 - 0.06 * CGFloat(k)), height: 2)
                            .position(x: w * 0.5, y: h * (0.71 + 0.06 * CGFloat(k)))
                    }
                    Rectangle().fill(Color(hex: 0x2A2440)).frame(width: w * 0.5, height: 4).position(x: w * 0.25, y: h * 0.69)
                default:
                    LinearGradient(colors: [Color(hex: 0xBFE3F2), Color(hex: 0xF6EBDD)], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<9, id: \.self) { k in
                        let col = CGFloat(k % 3), row = CGFloat(k / 3)
                        let c = [Color(hex: 0xF2E3C6), Color(hex: 0xF0B39B), Color(hex: 0xF7D77E), Color(hex: 0xC9DDE8)][k % 4]
                        VStack(spacing: 0) {
                            Triangle().fill(Color(hex: 0xC8613F)).frame(width: w * 0.32, height: h * 0.1)
                            Rectangle().fill(c).frame(width: w * 0.28, height: h * 0.18)
                                .overlay(HStack(spacing: 4) { ForEach(0..<2, id: \.self) { _ in Rectangle().fill(Color(hex: 0x4A5D74)).frame(width: 4, height: 6) } })
                        }
                        .position(x: w * (0.18 + 0.32 * col) + (row == 1 ? w * 0.08 : 0), y: h * (0.36 + 0.22 * row))
                    }
                    Text("✦").font(.system(size: 10)).foregroundStyle(.white).position(x: w * 0.8, y: h * 0.14)
                }
            }
            .clipped()
        }
    }
}

private struct Ticket: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("TRAM 28").font(PostcardApp.type(15)).bold()
            Text("SINGLE · ZONE 1").font(PostcardApp.type(9)).kerning(1)
            Text("Nº 004821").font(PostcardApp.type(9)).opacity(0.6)
        }
        .foregroundStyle(PostcardApp.ink)
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(Color(hex: 0xF7D77E))
        .overlay(alignment: .trailing) {
            VStack(spacing: 3) { ForEach(0..<6, id: \.self) { _ in Circle().fill(PostcardApp.paper).frame(width: 5, height: 5) } }.offset(x: 2.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

private struct CardFront: View {
    var body: some View {
        ZStack {
            // Azulejo tiles.
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0xF7F3EA)))
                let s: CGFloat = 33
                let blue = Color(hex: 0x1F4FA0)
                var y: CGFloat = 0, r = 0
                while y < size.height {
                    var x: CGFloat = 0
                    while x < size.width {
                        let c = CGPoint(x: x + s / 2, y: y + s / 2)
                        var d = Path()
                        d.move(to: CGPoint(x: c.x, y: c.y - s * 0.42)); d.addLine(to: CGPoint(x: c.x + s * 0.42, y: c.y))
                        d.addLine(to: CGPoint(x: c.x, y: c.y + s * 0.42)); d.addLine(to: CGPoint(x: c.x - s * 0.42, y: c.y)); d.closeSubpath()
                        ctx.stroke(d, with: .color(blue), lineWidth: 2)
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 4, y: c.y - 4, width: 8, height: 8)), with: .color(blue))
                        for q in 0..<4 {
                            let px = q % 2 == 0 ? x : x + s, py = q < 2 ? y : y + s
                            ctx.fill(Path(ellipseIn: CGRect(x: px - 5, y: py - 5, width: 10, height: 10)), with: .color(blue.opacity(0.85)))
                        }
                        ctx.stroke(Path(CGRect(x: x, y: y, width: s, height: s)), with: .color(blue.opacity(0.18)), lineWidth: 0.6)
                        x += s
                    }
                    y += s; r += 1
                }
            }
            VStack(spacing: -4) {
                Text("Greetings from").font(PostcardApp.type(13)).kerning(2)
                Text("Lisbon").font(PostcardApp.script(54))
            }
            .foregroundStyle(PostcardApp.navy)
            .padding(.horizontal, 26).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xFBF8F1)))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(PostcardApp.navy, lineWidth: 2).padding(4))
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white, lineWidth: 7))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
    }
}

private struct CardBack: View {
    let write: Bool
    let stamped: Bool

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Dear Mom & Dad,").font(PostcardApp.hand(15))
                Text("The trams climb hills you would\nnot believe. Ate pastéis twice\ntoday. Home on Sunday!").font(PostcardApp.hand(12.5))
                    .lineSpacing(1)
                Text("— Yuki").font(PostcardApp.hand(15)).padding(.top, 2)
            }
            .foregroundStyle(PostcardApp.navy)
            .mask(alignment: .leading) {
                Rectangle().frame(width: write ? 200 : 0)
                    .animation(.linear(duration: 2.0).delay(0.8), value: write)
            }
            .frame(width: 176, alignment: .leading)
            .padding(.leading, 16)
            Rectangle().fill(PostcardApp.ink.opacity(0.25)).frame(width: 1).padding(.vertical, 22)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Stamp()
                        .overlay {
                            Postmark()
                                .frame(width: 92, height: 60)
                                .offset(x: -26, y: 8)
                                .opacity(stamped ? 0.82 : 0)
                                .scaleEffect(stamped ? 1 : 2.4)
                                .animation(.easeIn(duration: 0.22).delay(0.05), value: stamped)
                        }
                }
                Spacer()
                ForEach(["Mom & Dad Tanaka", "2-14 Sakura-dori", "Tokyo, JAPAN"], id: \.self) { line in
                    Text(line).font(PostcardApp.hand(12)).foregroundStyle(PostcardApp.navy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .bottom) { Rectangle().fill(PostcardApp.ink.opacity(0.3)).frame(height: 1).offset(y: 2) }
                        .padding(.bottom, 9)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: write ? 140 : 0)
                                .animation(.linear(duration: 0.6).delay(2.7), value: write)
                        }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color(hex: 0xFBF8F1)))
        .overlay(alignment: .top) {
            Text("POST CARD").font(PostcardApp.type(10)).kerning(4).foregroundStyle(PostcardApp.ink.opacity(0.45)).padding(.top, 8)
        }
        .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
    }
}

private struct Stamp: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color(hex: 0xF7D77E))
            VStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 2).fill(PostcardApp.red).frame(width: 26, height: 14)
                    .overlay(HStack(spacing: 2) { ForEach(0..<3, id: \.self) { _ in Rectangle().fill(.white).frame(width: 5, height: 5) } })
                Text("PORTUGAL").font(.system(size: 5.5, weight: .bold)).kerning(0.5)
                Text("0,95").font(.system(size: 8, weight: .heavy))
            }
            .foregroundStyle(PostcardApp.ink)
        }
        .frame(width: 46, height: 54)
        .padding(3)
        .background(Color.white)
        .mask(Perforated().fill(style: FillStyle(eoFill: true)))
        .rotationEffect(.degrees(3))
    }
}

/// White stamp border with scalloped edges.
private struct Perforated: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path(r)
        let d: CGFloat = 4
        var x = r.minX + d / 2
        while x < r.maxX { p.addEllipse(in: CGRect(x: x - d / 2, y: r.minY - d / 2, width: d, height: d)); p.addEllipse(in: CGRect(x: x - d / 2, y: r.maxY - d / 2, width: d, height: d)); x += d * 1.6 }
        var y = r.minY + d / 2
        while y < r.maxY { p.addEllipse(in: CGRect(x: r.minX - d / 2, y: y - d / 2, width: d, height: d)); p.addEllipse(in: CGRect(x: r.maxX - d / 2, y: y - d / 2, width: d, height: d)); y += d * 1.6 }
        return p
    }
}

private struct Postmark: View {
    var body: some View {
        ZStack {
            Circle().stroke(PostcardApp.ink, lineWidth: 2).frame(width: 52, height: 52)
            Circle().stroke(PostcardApp.ink, lineWidth: 1).frame(width: 40, height: 40)
            VStack(spacing: 0) {
                Text("LISBOA").font(.system(size: 7, weight: .heavy)).kerning(1)
                Text("21·XI·26").font(.system(size: 8, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(PostcardApp.ink)
            VStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { _ in
                    WavyLine().stroke(PostcardApp.ink, lineWidth: 1.6).frame(width: 46, height: 5)
                }
            }
            .offset(x: 46)
        }
    }
}

private struct WavyLine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        var x = r.minX
        while x < r.maxX {
            p.addQuadCurve(to: CGPoint(x: x + 8, y: r.midY), control: CGPoint(x: x + 4, y: (Int(x / 8) % 2 == 0) ? r.minY : r.maxY))
            x += 8
        }
        return p
    }
}
