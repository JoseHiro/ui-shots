import SwiftUI

/// Terminal: chat as a CLI session on a phosphor CRT. Messages stream in
/// character by character, receipts update in place like a progress line,
/// and a photo arrives as ASCII art.
struct TerminalApp: View {
    @EnvironmentObject var demo: Demo

    /// Pause before each RETURN: message, /send photo, reply.
    static let script: [Double] = [3.3, 4.4, 4.0]

    static let bg = Color(hex: 0x070B08)
    static let green = Color(hex: 0x52FF9A)
    static let dim = Color(hex: 0x2F7A4C)
    static let amber = Color(hex: 0xFFB84D)
    static let cyan = Color(hex: 0x5CE1E6)
    static let pink = Color(hex: 0xFF6B9A)
    static func mono(_ s: CGFloat, _ w: Font.Weight = .medium) -> Font { .system(size: s, weight: w, design: .monospaced) }

    enum Kind {
        case text(String, Color, cps: Double)
        case progress(String, dur: Double, Color)
        case typing
    }

    /// One scripted line: shown `at` seconds after step `s` (0 = app appeared).
    /// Lines that share a `slot` replace each other in place; `until` removes it.
    struct Entry {
        let s: Int
        let at: Double
        var slot: String? = nil
        var until: Double? = nil
        let kind: Kind
    }

    static func t(_ s: Int, _ at: Double, _ text: String, _ c: Color = green, cps: Double = 0, slot: String? = nil) -> Entry {
        Entry(s: s, at: at, slot: slot, kind: .text(text, c, cps: cps))
    }

    static let bowl = [
        "      (  )   (   )  )",
        "       ) (    )  (",
        "    .-'''''''''''''-.",
        "   (  ~~~ ramen ~~~  )",
        "    \\  @  ~  ()  ~  /",
        "     '.___________.'",
        "        '-------'",
    ]
    static let heart = [
        "     ****     ****",
        "   ******** ********",
        "   *****************",
        "     *************",
        "       *********",
        "         *****",
        "           *",
    ]

    static let entries: [Entry] = {
        var e: [Entry] = [
            t(0, 0.0, "  ___ _  _   _ _____ ", cyan),
            t(0, 0.06, " / __| || | /_\\_   _|", cyan),
            t(0, 0.12, "| (__| __ |/ _ \\| |  ", cyan),
            t(0, 0.18, " \\___|_||_/_/ \\_\\_|  v2.6", cyan),
            t(0, 0.24, " ", dim),
            t(0, 0.3, "Last login: Fri Nov 21 09:38 on ttys001", dim),
            t(0, 0.25, "$ chat --connect mika@kyoto", green, cps: 38),
            Entry(s: 0, at: 1.0, slot: "boot", kind: .progress("connecting", dur: 0.5, cyan)),
            t(0, 1.55, "✓ e2e channel open · session 4f2a", cyan, slot: "boot"),
            t(0, 1.75, "────────────────── #mika ──", dim),
            t(0, 1.9, "[09:38] mika> hey, you back?", amber),
            t(0, 2.0, "[09:39]  you> just landed ✈", green),
            // step 1: plain message
            t(1, 0.0, "[09:41]  you> dinner tonight?"),
            Entry(s: 1, at: 0.05, slot: "r1", kind: .progress("  └ sending", dur: 0.5, dim)),
            t(1, 0.6, "  └ delivered ✓", dim, slot: "r1"),
            t(1, 1.25, "  └ read ✓✓ 09:41:12", cyan, slot: "r1"),
            Entry(s: 1, at: 1.5, until: 2.6, kind: .typing),
            t(1, 2.6, "[09:41] mika> yes!! ramen at 7?", amber, cps: 40),
            // step 2: a photo
            t(2, 0.0, "[09:42]  you> /send ramen.jpg"),
            Entry(s: 2, at: 0.05, slot: "up", kind: .progress("  uploading ramen.jpg", dur: 0.85, cyan)),
            t(2, 0.95, "  └ ramen.jpg 42KB → ascii", dim, slot: "up"),
        ]
        for (i, l) in bowl.enumerated() { e.append(t(2, 1.05 + Double(i) * 0.07, l, Color(hex: 0xFFE08A))) }
        e += [
            t(2, 1.7, "  └ read ✓✓ 09:42:03", cyan),
            Entry(s: 2, at: 1.9, until: 2.7, kind: .typing),
            t(2, 2.7, "[09:42] mika> lol it's ALWAYS ramen", amber, cps: 40),
            // step 3: the sign-off, answered with a heart
            t(3, 0.0, "[09:43]  you> see you at 7 <3"),
            Entry(s: 3, at: 0.05, slot: "r3", kind: .progress("  └ sending", dur: 0.4, dim)),
            t(3, 0.5, "  └ delivered ✓", dim, slot: "r3"),
            t(3, 1.0, "  └ read ✓✓ 09:43:20", cyan, slot: "r3"),
            Entry(s: 3, at: 1.2, until: 2.0, kind: .typing),
            t(3, 2.0, "[09:43] mika>", amber),
        ]
        for (i, l) in heart.enumerated() { e.append(t(3, 2.1 + Double(i) * 0.08, l, pink)) }
        e.append(t(3, 2.9, "mika is away · ctrl-d to close", dim))
        return e
    }()

    /// Draft typed at the prompt after step `s`, sent by the next RETURN.
    static let drafts: [(s: Int, at: Double, text: String)] = [
        (0, 2.25, "dinner tonight?"),
        (1, 3.2, "/send ramen.jpg"),
        (2, 3.0, "see you at 7 <3"),
    ]

    var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()
            TimelineView(.animation) { tl in
                VStack(spacing: 0) {
                    titleBar.reveal(0)
                    screen(tl.date).reveal(1)
                    prompt(tl.date).reveal(2)
                    keys.reveal(3)
                }
            }
            crt
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Pieces

    private var titleBar: some View {
        HStack(spacing: 8) {
            ForEach([0xFF5F57, 0xFEBC2E, 0x28C840], id: \.self) { c in
                Circle().fill(Color(hex: UInt32(c))).frame(width: 12, height: 12)
            }
            Spacer()
            Text("mika@kyoto — chat — 80×24").font(Self.mono(13, .semibold)).foregroundStyle(Self.green.opacity(0.7))
            Spacer()
            Image(systemName: "lock.fill").font(.system(size: 12)).foregroundStyle(Self.cyan.opacity(0.8))
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(Color(hex: 0x0E1611))
        .overlay(alignment: .bottom) { Rectangle().fill(Self.green.opacity(0.18)).frame(height: 1) }
    }

    private func base(_ s: Int) -> Date? { s == 0 ? demo.appearDate : demo.stepDate[s] }

    private struct Shown: Identifiable { let id: String; let kind: Kind; let age: Double }

    private func visible(_ now: Date) -> [Shown] {
        var out: [Shown] = []
        for (i, e) in Self.entries.enumerated() {
            guard let b = base(e.s) else { continue }
            let age = now.timeIntervalSince(b) - e.at
            guard age >= 0 else { continue }
            if let u = e.until, now.timeIntervalSince(b) >= u { continue }
            if let slot = e.slot, let j = out.firstIndex(where: { $0.id == slot }) {
                out[j] = Shown(id: slot, kind: e.kind, age: age)
            } else {
                out.append(Shown(id: e.slot ?? "\(i)", kind: e.kind, age: age))
            }
        }
        return out
    }

    private func line(_ l: Shown, now: Date) -> some View {
        let text: String, color: Color
        switch l.kind {
        case let .text(s, c, cps):
            text = cps > 0 ? String(s.prefix(Int(l.age * cps))) : s
            color = c
        case let .progress(label, dur, c):
            let p = min(1, l.age / dur), n = 12
            let filled = Int(p * Double(n))
            text = "\(label) [\(String(repeating: "█", count: filled))\(String(repeating: "░", count: n - filled))] \(Int(p * 100))%"
            color = c
        case .typing:
            let spin = Array("⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏")
            text = "mika is typing \(spin[Int(l.age * 14) % spin.count])"
            color = Self.amber.opacity(0.75)
        }
        return Text(text)
            .font(Self.mono(15.5))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.55), radius: 4)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 22)
    }

    private func screen(_ now: Date) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ForEach(visible(now)) { l in line(l, now: now) }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
        .clipped()
    }

    private func prompt(_ now: Date) -> some View {
        let d = Self.drafts.first { $0.s == demo.step }
        var typed = ""
        if let d, let b = base(d.s) {
            typed = String(d.text.prefix(max(0, Int((now.timeIntervalSince(b) - d.at) * 17))))
        }
        let on = sin(now.timeIntervalSinceReferenceDate * 6) > -0.3
        return HStack(spacing: 0) {
            Text("you> ").foregroundStyle(Self.green.opacity(0.6))
            Text(typed).foregroundStyle(Self.green)
            Rectangle().fill(Self.green).frame(width: 9, height: 19).opacity(on ? 0.9 : 0)
            Spacer()
        }
        .font(Self.mono(16, .semibold))
        .shadow(color: Self.green.opacity(0.5), radius: 4)
        .padding(.horizontal, 16)
        .frame(height: 50)
        .overlay(alignment: .top) { Rectangle().fill(Self.green.opacity(0.18)).frame(height: 1) }
    }

    private var keys: some View {
        HStack(spacing: 8) {
            ForEach(["esc", "tab", "/", "↑", "ctrl"], id: \.self) { k in
                Text(k).font(Self.mono(13, .semibold)).foregroundStyle(Self.green.opacity(0.75))
                    .frame(width: 50, height: 46)
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Self.green.opacity(0.3), lineWidth: 1.2))
            }
            let down = demo.isPressing(1, 2, 3)
            HStack(spacing: 6) {
                Image(systemName: "return").font(.system(size: 15, weight: .bold))
                Text("RET").font(Self.mono(14, .bold))
            }
            .foregroundStyle(down ? Self.bg : Self.green)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(RoundedRectangle(cornerRadius: 8).fill(Self.green.opacity(down ? 1 : 0.14)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Self.green, lineWidth: 1.4))
            .shadow(color: Self.green.opacity(down ? 0.8 : 0.35), radius: down ? 14 : 6)
            .scaleEffect(down ? 0.93 : 1)
            .animation(.easeOut(duration: 0.12), value: down)
            .demoTap(1, 2, 3)
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    /// Scanlines, a slow rolling band and a vignette over everything.
    private var crt: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                var y: CGFloat = 0
                while y < size.height {
                    ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1.2)), with: .color(.black.opacity(0.28)))
                    y += 3
                }
                let band = CGFloat((tl.date.timeIntervalSinceReferenceDate * 0.25).truncatingRemainder(dividingBy: 1)) * (size.height + 200) - 100
                ctx.fill(Path(CGRect(x: 0, y: band, width: size.width, height: 90)),
                         with: .linearGradient(Gradient(colors: [.clear, Self.green.opacity(0.05), .clear]),
                                               startPoint: CGPoint(x: 0, y: band), endPoint: CGPoint(x: 0, y: band + 90)))
            }
            .overlay(RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 260, endRadius: 560))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
