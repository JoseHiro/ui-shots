import SwiftUI

/// Gate: airport signage. A split-flap departures board whose letters really
/// flip, and a boarding pass that turns over to its code and loses its stub.
struct GateApp: View {
    @EnvironmentObject var demo: Demo

    static let yellow = Color(hex: 0xFFD200)
    static let ink = Color(hex: 0x111214)
    static let paper = Color(hex: 0xF4F3EF)
    static func helv(_ s: CGFloat, _ w: String = "Bold") -> Font { .custom("HelveticaNeue-\(w)", size: s) }

    /// Pause before each step: pick flight, flip pass, board, refresh the board.
    static let script: [Double] = [2.8, 2.4, 2.6, 2.8]

    struct Row { let time: String; let dest: String; let gate: String; let code: String }
    static let rows = [
        Row(time: "09:40", dest: "HELSINKI", gate: "B12", code: "AY 074"),
        Row(time: "09:55", dest: "LISBON", gate: "A03", code: "TP 089"),
        Row(time: "10:10", dest: "SINGAPORE", gate: "C21", code: "SQ 637"),
        Row(time: "10:25", dest: "NEW YORK", gate: "D07", code: "JL 006"),
    ]
    /// After the refresh (step 4) some cells change.
    static let later = [
        Row(time: "09:40", dest: "HELSINKI", gate: "B12", code: "AY 074"),
        Row(time: "09:55", dest: "LISBON", gate: "A11", code: "TP 089"),
        Row(time: "10:45", dest: "SINGAPORE", gate: "C21", code: "SQ 637"),
        Row(time: "10:25", dest: "NEW YORK", gate: "D07", code: "JL 006"),
    ]

    private func remark(_ i: Int) -> (String, Color) {
        let refreshed = demo.step >= 4
        switch i {
        case 0: return demo.step >= 4 ? ("Final call", Color(hex: 0xFF8A3D)) : demo.step >= 1 ? ("Boarding", Self.yellow) : ("On time", Color(hex: 0x3DDC84))
        case 1: return refreshed ? ("Gate change", Self.yellow) : ("On time", Color(hex: 0x3DDC84))
        case 2: return ("Delayed", Color(hex: 0xFF5A4F))
        default: return refreshed ? ("Gate open", Color(hex: 0x3DDC84)) : ("On time", Color(hex: 0x3DDC84))
        }
    }

    var body: some View {
        ZStack {
            Self.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header.reveal(0)
                board.reveal(1).padding(.top, 20)
                passArea.padding(.top, 22)
                footer.reveal(3).padding(.top, 16)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane.departure").font(.system(size: 24, weight: .bold))
                .foregroundStyle(Self.ink)
                .frame(width: 50, height: 50)
                .background(RoundedRectangle(cornerRadius: 8).fill(Self.yellow))
            VStack(alignment: .leading, spacing: 0) {
                Text("Gate").font(Self.helv(34)).foregroundStyle(Self.ink)
                Text("Haneda · Terminal 3").font(Self.helv(13, "Medium")).foregroundStyle(Self.ink.opacity(0.5))
            }
            Spacer()
            Text("09:21").font(Self.helv(28)).monospacedDigit().foregroundStyle(Self.ink)
        }
    }

    // MARK: Board

    private var board: some View {
        TimelineView(.animation) { tl in
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("DEPARTURES").font(Self.helv(14)).kerning(2).foregroundStyle(Self.yellow)
                    Text("出発").font(.system(size: 13, weight: .bold)).foregroundStyle(Self.yellow.opacity(0.7))
                    Spacer()
                    Image(systemName: "arrow.clockwise").font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Self.yellow)
                        .rotationEffect(.degrees(demo.step >= 4 ? 360 : 0))
                        .animation(.easeInOut(duration: 0.7), value: demo.step >= 4)
                        .frame(width: 34, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6).stroke(Self.yellow.opacity(0.5), lineWidth: 1))
                        .scaleEffect(demo.isPressing(4) ? 0.85 : 1)
                        .demoTap(4)
                }
                .padding(.bottom, 10)
                ForEach(0..<4, id: \.self) { i in
                    flightRow(i, now: tl.date)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Self.ink))
        }
    }

    private func flightRow(_ i: Int, now: Date) -> some View {
        let r = Self.rows[i], n = Self.later[i]
        let (text, color) = remark(i)
        let on = i == 0 && demo.step >= 1
        let blink = text == "Boarding" || text == "Final call"
            ? 0.45 + 0.55 * abs(cos(now.timeIntervalSinceReferenceDate * 3)) : 1
        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 9) {
                flaps(r.time, n.time, row: i, col: 0, now: now)
                flaps(r.dest.padding(toLength: 9, withPad: " ", startingAt: 0),
                      n.dest.padding(toLength: 9, withPad: " ", startingAt: 0), row: i, col: 5, now: now)
                flaps(r.gate, n.gate, row: i, col: 14, now: now)
            }
            HStack(spacing: 8) {
                Text(r.code).font(Self.helv(11, "Medium")).foregroundStyle(.white.opacity(0.45))
                Circle().fill(color).frame(width: 6, height: 6)
                Text(text).font(Self.helv(11)).foregroundStyle(color)
                    .contentTransition(.opacity)
            }
            .opacity(blink)
        }
        .padding(.vertical, 8).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(on ? .white.opacity(0.08) : .clear))
        .overlay(alignment: .leading) {
            Rectangle().fill(Self.yellow).frame(width: 3).padding(.vertical, 6).offset(x: -6).opacity(on ? 1 : 0)
        }
        .contentShape(Rectangle())
        .demoTap(i == 0 ? 1 : 99)
    }

    /// One group of split-flap cells. Each cell flips from its old letter to its new one.
    private func flaps(_ from: String, _ to: String, row: Int, col: Int, now: Date) -> some View {
        let a = Array(from), b = Array(to)
        return HStack(spacing: 1.5) {
            ForEach(0..<a.count, id: \.self) { k in
                let changed = demo.step >= 4 && a[k] != b[k]
                let start: Date? = changed
                    ? demo.stepDate[4].map { $0 + 0.2 + Double(k) * 0.04 }
                    : demo.appearDate.map { $0 + 0.2 + Double(row) * 0.12 + Double(col + k) * 0.03 }
                FlapCell.at(now, from: changed ? a[k] : " ", to: changed ? b[k] : a[k], start: start)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            ForEach([("figure.walk", "6 min to B12"), ("cup.and.saucer.fill", "Lounge L3"), ("wifi", "Free Wi-Fi")], id: \.1) { icon, text in
                HStack(spacing: 6) {
                    Image(systemName: icon).font(.system(size: 13, weight: .bold))
                    Text(text).font(Self.helv(12)).lineLimit(1)
                }
                .foregroundStyle(Self.ink)
                .frame(maxWidth: .infinity).frame(height: 40)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Self.ink.opacity(0.08), lineWidth: 1))
            }
        }
    }

    // MARK: Boarding pass

    private var passArea: some View {
        ZStack(alignment: .top) {
            if demo.step >= 1 {
                Flip(angle: demo.step >= 3 ? 360 : demo.step >= 2 ? 180 : 0, front: PassFront(torn: demo.step >= 3), back: PassBack())
                    .animation(.spring(response: 0.9, dampingFraction: 0.8), value: demo.step)
                    .scaleEffect(demo.isPressing(2, 3) ? 0.97 : 1)
                    .demoTap(2, 3)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                    Text("Tap your flight to get the pass")
                }
                .font(Self.helv(14, "Medium")).foregroundStyle(Self.ink.opacity(0.4))
                .frame(maxWidth: .infinity).frame(height: 244)
                .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Self.ink.opacity(0.15), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
                .reveal(2)
            }
        }
        .frame(height: 252, alignment: .top)
    }
}

// MARK: - Split-flap cell

private struct FlapCell: View {
    static let w: CGFloat = 16.5, h: CGFloat = 27
    static let alphabet = Array(" ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789:")
    static let flip = 0.06

    let cur: Character
    let next: Character
    let f: Double?

    /// The cell at time `now`: it steps through the alphabet from `from` to `to`.
    static func at(_ now: Date, from: Character, to: Character, start: Date?) -> FlapCell {
        guard let start else { return FlapCell(cur: from, next: from, f: nil) }
        let n = alphabet.count
        let i0 = alphabet.firstIndex(of: from) ?? 0, i1 = alphabet.firstIndex(of: to) ?? 0
        var dist = (i1 - i0 + n) % n
        var first = i0
        if dist > 12 { first = (i1 - 12 + n) % n; dist = 12 }
        let t = now.timeIntervalSince(start) / flip
        if t < 0 { return FlapCell(cur: from, next: from, f: nil) }
        if t >= Double(dist) { return FlapCell(cur: to, next: to, f: nil) }
        let k = Int(t)
        let c = k == 0 ? from : alphabet[(first + k) % n]
        return FlapCell(cur: c, next: alphabet[(first + k + 1) % n], f: t - Double(k))
    }

    var body: some View {
        ZStack {
            half(f == nil ? cur : next, top: true)
            half(cur, top: false)
            if let f {
                if f < 0.5 {
                    half(cur, top: true).brightness(-0.25 * f)
                        .rotation3DEffect(.degrees(-f * 180), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.5)
                        .frame(height: Self.h, alignment: .top)
                } else {
                    half(next, top: false).brightness(-0.25 * (1 - f))
                        .rotation3DEffect(.degrees((1 - f) * 180), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.5)
                        .frame(height: Self.h, alignment: .bottom)
                }
            }
            Rectangle().fill(.black).frame(height: 1)
        }
        .frame(width: Self.w, height: Self.h)
    }

    private func half(_ c: Character, top: Bool) -> some View {
        Text(String(c))
            .font(.custom("HelveticaNeue-Bold", size: 19))
            .foregroundStyle(Color(hex: 0xEDEDE8))
            .frame(width: Self.w, height: Self.h)
            .frame(height: Self.h / 2, alignment: top ? .top : .bottom)
            .clipped()
            .background(top ? Color(hex: 0x26272B) : Color(hex: 0x202125))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: top ? 3 : 0, bottomLeadingRadius: top ? 0 : 3,
                                              bottomTrailingRadius: top ? 0 : 3, topTrailingRadius: top ? 3 : 0))
            .frame(height: Self.h, alignment: top ? .top : .bottom)
    }
}

// MARK: - Pass faces

private struct PassFront: View {
    let torn: Bool
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("AY 074").font(GateApp.helv(13))
                    Spacer()
                    Text("BOARDING PASS").font(GateApp.helv(10)).kerning(1.5)
                }
                .foregroundStyle(GateApp.ink)
                .padding(.horizontal, 16).frame(height: 34)
                .background(GateApp.yellow)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("HND").font(GateApp.helv(40))
                        Text("Tokyo").font(GateApp.helv(12, "Medium")).opacity(0.5)
                    }
                    Spacer()
                    Image(systemName: "airplane").font(.system(size: 18, weight: .bold))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("HEL").font(GateApp.helv(40))
                        Text("Helsinki").font(GateApp.helv(12, "Medium")).opacity(0.5)
                    }
                }
                .foregroundStyle(GateApp.ink)
                .padding(.horizontal, 16).padding(.top, 12)
                HStack(spacing: 0) {
                    field("PASSENGER", "TANAKA/Y").frame(width: 112, alignment: .leading)
                    field("SEAT", "14A")
                    field("GATE", "B12")
                }
                .padding(.horizontal, 16).padding(.top, 14)
                HStack(spacing: 0) {
                    field("BOARDING", "09:10").frame(width: 112, alignment: .leading)
                    field("DEPARTS", "09:40")
                    field("ZONE", "2")
                }
                .padding(.horizontal, 16).padding(.top, 10)
                Spacer(minLength: 0)
            }
            .background(Color.white)
            .overlay(alignment: .center) {
                Text("BOARDED")
                    .font(GateApp.helv(26)).kerning(3)
                    .foregroundStyle(Color(hex: 0x1F8A4C))
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0x1F8A4C), lineWidth: 3))
                    .rotationEffect(.degrees(-12))
                    .opacity(torn ? 0.85 : 0)
                    .scaleEffect(torn ? 1 : 2.2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6).delay(1.3), value: torn)
                    .offset(y: 30)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16))
            Perforation().frame(width: 1)
            stub
                .rotationEffect(.degrees(torn ? 16 : 0), anchor: .bottomLeading)
                .offset(x: torn ? 40 : 0, y: torn ? 380 : 0)
                .opacity(torn ? 0 : 1)
                .animation(.easeIn(duration: 0.9).delay(0.7), value: torn)
        }
        .frame(height: 244)
        .shadow(color: .black.opacity(0.15), radius: 14, y: 8)
    }

    private var stub: some View {
        VStack(spacing: 8) {
            Text("14A").font(GateApp.helv(24)).foregroundStyle(GateApp.ink)
            Barcode().frame(width: 60, height: 120)
            Text("AY074").font(GateApp.helv(10, "Medium")).foregroundStyle(GateApp.ink.opacity(0.5))
        }
        .frame(width: 96, height: 244)
        .background(Color.white)
        .clipShape(UnevenRoundedRectangle(bottomTrailingRadius: 16, topTrailingRadius: 16))
    }

    private func field(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(k).font(GateApp.helv(9, "Medium")).kerning(1).foregroundStyle(GateApp.ink.opacity(0.45))
            Text(v).font(GateApp.helv(16)).foregroundStyle(GateApp.ink).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PassBack: View {
    var body: some View {
        HStack(spacing: 18) {
            QRCode().frame(width: 150, height: 150)
            VStack(alignment: .leading, spacing: 6) {
                Text("Scan at the gate").font(GateApp.helv(20)).foregroundStyle(.white)
                Text("Gate B12 closes\n20 minutes before\ndeparture.").font(GateApp.helv(13, "Medium")).foregroundStyle(.white.opacity(0.6))
                Spacer(minLength: 0)
                Text("Tap to board").font(GateApp.helv(13)).foregroundStyle(GateApp.ink)
                    .padding(.horizontal, 12).frame(height: 30)
                    .background(Capsule().fill(GateApp.yellow))
            }
            .frame(height: 150)
        }
        .frame(maxWidth: .infinity).frame(height: 244)
        .background(RoundedRectangle(cornerRadius: 16).fill(GateApp.ink))
        .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
    }
}

private struct Perforation: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 4
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: 1, height: 4)), with: .color(.black.opacity(0.25)))
                y += 8
            }
        }
        .background(Color.white)
    }
}

/// Deterministic bars and modules, so the codes look real but stay the same every run.
private struct Barcode: View {
    var body: some View {
        Canvas { ctx, size in
            var x: CGFloat = 0, i = 0
            while x < size.width {
                let w: CGFloat = [1, 2, 1, 3, 1, 2][i % 6] + CGFloat((i * 7) % 3 == 0 ? 1 : 0)
                if i % 2 == 0 { ctx.fill(Path(CGRect(x: x, y: 0, width: w, height: size.height)), with: .color(GateApp.ink)) }
                x += w; i += 1
            }
        }
    }
}

private struct QRCode: View {
    var body: some View {
        Canvas { ctx, size in
            let n = 25, c = size.width / CGFloat(n)
            ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8), with: .color(.white))
            let inner = CGRect(x: c, y: c, width: size.width - 2 * c, height: size.height - 2 * c)
            let m = 23, cc = inner.width / CGFloat(m)
            func finder(_ x: Int, _ y: Int) -> Bool { x < 7 && y < 7 || x >= m - 7 && y < 7 || x < 7 && y >= m - 7 }
            for y in 0..<m {
                for x in 0..<m {
                    var on: Bool
                    if finder(x, y) {
                        let fx = x >= m - 7 ? x - (m - 7) : x, fy = y >= m - 7 ? y - (m - 7) : y
                        on = fx == 0 || fy == 0 || fx == 6 || fy == 6 || (fx >= 2 && fx <= 4 && fy >= 2 && fy <= 4)
                    } else {
                        on = (x * 31 + y * 17 + x * y * 7) % 5 < 2
                    }
                    if on {
                        ctx.fill(Path(CGRect(x: inner.minX + CGFloat(x) * cc, y: inner.minY + CGFloat(y) * cc, width: cc + 0.3, height: cc + 0.3)),
                                 with: .color(GateApp.ink))
                    }
                }
            }
        }
    }
}
