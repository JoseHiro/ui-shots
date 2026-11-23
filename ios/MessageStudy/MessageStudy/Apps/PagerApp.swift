import SwiftUI

/// Pager: 90s Japanese pocket bell. Messages are number codes (0840 = おはよう),
/// punched in on a payphone keypad and decoded on a buzzing LCD.
struct PagerApp: View {
    @EnvironmentObject var demo: Demo

    /// Pause before each step: read, send, read, send.
    static let script: [Double] = [2.7, 3.4, 3.6, 3.0]

    static let bgTop = Color(hex: 0xFFE3CC)
    static let bgBottom = Color(hex: 0xF8CFE0)
    static let body1 = Color(hex: 0x7B5CF0)
    static let body2 = Color(hex: 0x4B33B8)
    static let lcd = Color(hex: 0xB7C79C)
    static let lcdInk = Color(hex: 0x1E2A18)
    static let phone = Color(hex: 0x2F9E62)
    static let phoneDark = Color(hex: 0x1F7448)
    static let ink = Color(hex: 0x2A1E3D)
    static func lcdFont(_ s: CGFloat) -> Font { .custom("DBLCDTempBlack", size: s) }
    static func round(_ s: CGFloat, _ w: Font.Weight = .bold) -> Font { .system(size: s, weight: w, design: .rounded) }

    struct Code { let digits: String; let kana: String; let english: String; let incoming: Bool }
    static let codes = [
        Code(digits: "0840", kana: "オハヨウ", english: "Good morning", incoming: true),
        Code(digits: "724106", kana: "ナニシテル?", english: "What are you up to?", incoming: false),
        Code(digits: "14106", kana: "アイシテル", english: "I love you", incoming: true),
        Code(digits: "39", kana: "サンキュー", english: "Thank you!", incoming: false),
    ]

    /// When each code reaches the pager or is sent: incoming ones arrive on a clock,
    /// outgoing ones are dialled on a clock and sent by a tap.
    private func times(_ now: Date) -> (w: Double, s1: Double, s2: Double, s3: Double, s4: Double) {
        func since(_ s: Int) -> Double { demo.stepDate[s].map { now.timeIntervalSince($0) } ?? -1 }
        return (demo.appearDate.map { now.timeIntervalSince($0) } ?? -1, since(1), since(2), since(3), since(4))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Self.bgTop, Self.bgBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            memphis
            TimelineView(.animation) { tl in
                let t = times(tl.date)
                VStack(spacing: 0) {
                    header.reveal(0)
                    pager(t, now: tl.date).reveal(1).padding(.top, 12)
                    log(t).reveal(2).padding(.top, 12)
                    Spacer(minLength: 8)
                    payphone(t).reveal(3)
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.light)
    }

    private var memphis: some View {
        Canvas { ctx, size in
            for i in 0..<26 {
                let x = hash01(i, 4) * size.width, y = hash01(i, 5) * size.height
                let c: Color = [Color(hex: 0x7B5CF0), Color(hex: 0x2FB9A8), Color(hex: 0xFF8A5B), Color(hex: 0xFFC53D)][i % 4]
                var p = Path()
                switch i % 3 {
                case 0: p.addEllipse(in: CGRect(x: x, y: y, width: 9, height: 9))
                case 1:
                    p.move(to: CGPoint(x: x, y: y))
                    for k in 1...4 { p.addLine(to: CGPoint(x: x + CGFloat(k) * 7, y: y + (k % 2 == 0 ? 0 : 7))) }
                default: p.addRect(CGRect(x: x, y: y, width: 3, height: 14))
                }
                ctx.stroke(p, with: .color(c.opacity(0.35)), lineWidth: 2.5)
            }
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("POCKET BELL").font(.system(size: 30, weight: .black, design: .rounded)).italic()
                .foregroundStyle(LinearGradient(colors: [Self.body1, Color(hex: 0xFF5FA2)], startPoint: .leading, endPoint: .trailing))
            Text("ポケベル").font(.system(size: 15, weight: .heavy)).foregroundStyle(Self.ink.opacity(0.55))
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right").font(.system(size: 18, weight: .bold))
                .foregroundStyle(Self.ink.opacity(0.6))
        }
        .padding(.top, 4)
    }

    // MARK: Pager

    private enum Screen { case idle, ring(Code), read(Code), sent(Code) }

    /// What the LCD shows, and when the last buzz started.
    private func state(_ t: (w: Double, s1: Double, s2: Double, s3: Double, s4: Double)) -> (Screen, Double?) {
        if t.s4 >= 0 { return (.sent(Self.codes[3]), nil) }
        if t.s3 >= 0 { return (.read(Self.codes[2]), nil) }
        if t.s2 >= 1.4 { return (.ring(Self.codes[2]), t.s2 - 1.4) }
        if t.s2 >= 0 { return (.sent(Self.codes[1]), nil) }
        if t.s1 >= 0 { return (.read(Self.codes[0]), nil) }
        if t.w >= 0.9 { return (.ring(Self.codes[0]), t.w - 0.9) }
        return (.idle, nil)
    }

    private func pager(_ t: (w: Double, s1: Double, s2: Double, s3: Double, s4: Double), now: Date) -> some View {
        let (screen, buzzAge) = state(t)
        let buzz = buzzAge.map { $0 < 1.1 ? sin($0 * 70) * 4 * (1 - $0 / 1.1) : 0 } ?? 0
        let ringing: Bool = { if case .ring = screen { return true }; return false }()
        let led = ringing && sin(now.timeIntervalSinceReferenceDate * 12) > 0
        return ZStack(alignment: .top) {
            // Body
            RoundedRectangle(cornerRadius: 34)
                .fill(LinearGradient(colors: [Self.body1, Self.body2], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 34).stroke(.white.opacity(0.35), lineWidth: 2).padding(2)
                )
                .overlay(alignment: .topLeading) {
                    Capsule().fill(.white.opacity(0.22)).frame(width: 160, height: 18).rotationEffect(.degrees(-4)).offset(x: 26, y: 12)
                }
                .shadow(color: Self.body2.opacity(0.45), radius: 20, y: 12)
            VStack(spacing: 12) {
                HStack {
                    Text("TOKYO TELEMESSAGE").font(.system(size: 10, weight: .heavy)).kerning(1.5).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Circle().fill(led ? Color(hex: 0xFF3B3B) : Color(hex: 0x5A1A1A))
                        .frame(width: 12, height: 12)
                        .shadow(color: led ? Color(hex: 0xFF3B3B) : .clear, radius: 8)
                }
                lcdView(screen, now: now)
                HStack(spacing: 14) {
                    pagerButton("MODE", demoSteps: [])
                    pagerButton("READ", demoSteps: [1, 3])
                    pagerButton("▲▼", demoSteps: [])
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
        }
        .frame(height: 244)
        .rotationEffect(.degrees(buzz * 0.4))
        .offset(x: buzz)
        .overlay {
            if let a = buzzAge, a < 1.6 {
                ForEach(0..<3, id: \.self) { i in
                    let k = max(0, min(1, (a - Double(i) * 0.25) / 0.9))
                    RoundedRectangle(cornerRadius: 40).stroke(Self.body1.opacity(0.5 * (1 - k)), lineWidth: 3)
                        .padding(-24 * k)
                }
            }
        }
    }

    private func pagerButton(_ label: String, demoSteps: [Int]) -> some View {
        let down = demo.pressed && demoSteps.contains(demo.pressingStep)
        return Text(label).font(.system(size: 13, weight: .heavy)).kerning(1)
            .foregroundStyle(Self.ink.opacity(0.8))
            .frame(width: 84, height: 34)
            .background(Capsule().fill(Color(hex: 0xEDE7FF)).shadow(color: .black.opacity(down ? 0 : 0.3), radius: 0, y: down ? 0 : 3))
            .offset(y: down ? 3 : 0)
            .animation(.easeOut(duration: 0.1), value: down)
            .modifier(OptionalTap(steps: demoSteps))
    }

    private struct OptionalTap: ViewModifier {
        let steps: [Int]
        func body(content: Content) -> some View {
            if steps.count == 2 { content.demoTap(steps[0], steps[1]) } else { content }
        }
    }

    private func lcdView(_ screen: Screen, now: Date) -> some View {
        let blink = sin(now.timeIntervalSinceReferenceDate * 9) > -0.2
        var top = "11/21 FRI  09:38", big = "", kana = "", tag = ""
        switch screen {
        case .idle: big = "------"
        case .ring(let c): top = "着信 ♪  1件"; big = blink ? c.digits : ""; tag = "未読"
        case .read(let c): top = c.incoming ? "既読  09:41" : top; big = c.digits; kana = c.kana; tag = "既読"
        case .sent(let c): top = "送信完了 ✓"; big = c.digits; kana = c.kana
        }
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10).fill(Self.lcd)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.35), lineWidth: 3))
                .overlay(
                    LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .top, endPoint: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                )
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(top).font(.system(size: 13, weight: .heavy, design: .monospaced))
                    Spacer()
                    if !tag.isEmpty {
                        Text(tag).font(.system(size: 11, weight: .heavy))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .foregroundStyle(tag == "未読" ? Self.lcd : Self.lcdInk)
                            .background(RoundedRectangle(cornerRadius: 3).fill(tag == "未読" ? Self.lcdInk : .clear))
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Self.lcdInk, lineWidth: 1.2))
                    }
                }
                ZStack(alignment: .leading) {
                    Text("8888888888").font(Self.lcdFont(44)).foregroundStyle(Self.lcdInk.opacity(0.07))
                    Text(big).font(Self.lcdFont(44)).foregroundStyle(Self.lcdInk)
                }
                Text(kana.isEmpty ? " " : kana)
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .kerning(4)
            }
            .foregroundStyle(Self.lcdInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(height: 128)
    }

    // MARK: Log

    private func log(_ t: (w: Double, s1: Double, s2: Double, s3: Double, s4: Double)) -> some View {
        let shown = [t.s1 >= 0, t.s2 >= 0, t.s3 >= 0, t.s4 >= 0]
        return VStack(spacing: 7) {
            ForEach(0..<4, id: \.self) { i in
                if shown[i] {
                    let c = Self.codes[i]
                    HStack(spacing: 10) {
                        Image(systemName: c.incoming ? "arrow.down.left" : "arrow.up.right")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(c.incoming ? Self.body1 : Self.phone))
                        Text(c.digits).font(Self.lcdFont(20)).foregroundStyle(Self.ink)
                            .frame(width: 78, alignment: .leading)
                        Text("= \(c.kana)").font(.system(size: 15, weight: .heavy)).foregroundStyle(Self.ink.opacity(0.75))
                        Spacer(minLength: 4)
                        Text(c.english).font(Self.round(14, .semibold)).foregroundStyle(Self.ink.opacity(0.55))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 38)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.7)))
                    .transition(.asymmetric(insertion: .scale(scale: 0.6, anchor: c.incoming ? .leading : .trailing).combined(with: .opacity),
                                            removal: .opacity))
                }
            }
        }
        .frame(height: 4 * 38 + 3 * 7, alignment: .top)
        .animation(.spring(response: 0.42, dampingFraction: 0.62), value: shown)
    }

    // MARK: Payphone

    /// Digits dialled for the next outgoing code, one key every 0.24 s.
    private func dialling(_ t: (w: Double, s1: Double, s2: Double, s3: Double, s4: Double)) -> (String, Int?, Double) {
        let (code, start, sent): (Code, Double, Bool) = t.s3 >= 0 ? (Self.codes[3], t.s3 - 1.0, t.s4 >= 0)
            : (Self.codes[1], t.s1 - 0.9, t.s2 >= 0)
        if t.s1 < 0 { return ("", nil, -1) }
        let n = start < 0 ? 0 : min(code.digits.count, Int(start / 0.24) + 1)
        let pressing = start >= 0 && start.truncatingRemainder(dividingBy: 0.24) < 0.15 && Int(start / 0.24) < code.digits.count
            ? Array(code.digits)[Int(start / 0.24)].wholeNumberValue : nil
        let sentAge = sent ? (t.s4 >= 0 ? t.s4 : t.s2) : -1
        return (String(code.digits.prefix(n)), sent ? nil : pressing, sentAge)
    }

    private func payphone(_ t: (w: Double, s1: Double, s2: Double, s3: Double, s4: Double)) -> some View {
        let (dialled, key, sentAge) = dialling(t)
        let sending = sentAge >= 0 && sentAge < 0.8
        let status = sentAge >= 0.8 ? "送信完了 ✓" : sending ? "送信中…" : dialled.isEmpty ? "番号を入力" : "＃で送信"
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(status).font(.system(size: 11, weight: .heavy)).foregroundStyle(Self.lcdInk.opacity(0.7))
                    Text(dialled.isEmpty ? " " : dialled).font(Self.lcdFont(28)).foregroundStyle(Self.lcdInk)
                        .opacity(sending ? (sin(sentAge * 30) > 0 ? 1 : 0.3) : 1)
                }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 8).fill(Self.lcd))
                let down = demo.isPressing(2, 4)
                VStack(spacing: 0) {
                    Text("＃").font(.system(size: 20, weight: .black))
                    Text("送信").font(.system(size: 11, weight: .heavy))
                }
                .foregroundStyle(Self.phoneDark)
                .frame(width: 86, height: 56)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0xFFE45C))
                    .shadow(color: .black.opacity(down ? 0 : 0.3), radius: 0, y: down ? 0 : 4))
                .offset(y: down ? 4 : 0)
                .animation(.easeOut(duration: 0.1), value: down)
                .demoTap(2, 4)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 8) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"], id: \.self) { k in
                    let lit = key != nil && k == String(key!)
                    Text(k).font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(lit ? .white : Self.ink.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(RoundedRectangle(cornerRadius: 10).fill(lit ? Color(hex: 0xFF8A5B) : Color(hex: 0xF6F2EA))
                            .shadow(color: .black.opacity(lit ? 0 : 0.28), radius: 0, y: lit ? 0 : 4))
                        .offset(y: lit ? 4 : 0)
                        .animation(.easeOut(duration: 0.06), value: lit)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22).fill(Self.phone)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Self.phoneDark, lineWidth: 3))
                .overlay(alignment: .topTrailing) {
                    Text("公衆電話").font(.system(size: 10, weight: .heavy)).foregroundStyle(.white.opacity(0.75))
                        .offset(x: -16, y: -16).opacity(0)
                }
        )
    }
}
