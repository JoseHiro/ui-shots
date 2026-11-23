import SwiftUI

/// Bubble: a playful chat. Messages land with a squash-and-stretch spring,
/// receipts tick from Sent to Read, and reactions burst out of the bubble.
struct BubbleApp: View {
    @EnvironmentObject var demo: Demo

    /// Pause before each step: send, heart the reply, send again, tap the sticker.
    static let script: [Double] = [2.4, 3.6, 3.0, 3.4]

    static let bg = Color(hex: 0xF6F4FF)
    static let ink = Color(hex: 0x1B1730)
    static let violet = Color(hex: 0x7C5CFF)
    static let pink = Color(hex: 0xC64CFF)
    static let mineFill = LinearGradient(colors: [violet, pink], startPoint: .topLeading, endPoint: .bottomTrailing)
    static func rounded(_ s: CGFloat, _ w: Font.Weight = .medium) -> Font { .system(size: s, weight: w, design: .rounded) }

    struct Msg: Identifiable {
        let id: Int
        let text: String
        let mine: Bool
        var big = false
        var photo = false
        var born: Date?
    }

    @State private var msgs: [Msg] = [
        Msg(id: 0, text: "Look what I found in Kyoto 🍁", mine: false),
        Msg(id: 1, text: "", mine: false, photo: true),
        Msg(id: 2, text: "Wow 😍 so jealous", mine: true),
        Msg(id: 3, text: "Are you back in Tokyo?", mine: false),
        Msg(id: 4, text: "Just landed 🙌", mine: true),
        Msg(id: 5, text: "So tired lol", mine: true),
        Msg(id: 6, text: "We should catch up this week", mine: false),
    ]
    @State private var draft = ""
    @State private var draftStart = Date.distantFuture
    @State private var receipt = 0          // 1 sent, 2 delivered, 3 read
    @State private var receiptFor = 5
    @State private var typing = false
    @State private var heart: Date?
    @State private var party: Date?

    var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()
            blobs
            VStack(spacing: 0) {
                header.reveal(0)
                Divider().opacity(0.4).padding(.top, 10)
                messages
                composer.reveal(7)
            }
        }
        .overlay {
            if let p = party, let f = demo.frames["s4"] {
                Confetti(start: p, origin: CGPoint(x: f.midX, y: f.midY))
            }
        }
        .preferredColorScheme(.light)
        .onChange(of: demo.appeared) { _, on in if on { type("Dinner tonight? 🍜", after: 0.6) } }
        .onChange(of: demo.step) { _, s in beat(s) }
    }

    // MARK: Beats

    private func beat(_ s: Int) {
        switch s {
        case 1: send(id: 7, reply: Msg(id: 8, text: "Yes!! The usual ramen place at 7?", mine: false), at: 2.5)
        case 2:
            heart = Date()
            type("Perfect, see you there ✨", after: 0.7)
        case 3: send(id: 9, reply: Msg(id: 10, text: "🥳", mine: false, big: true), at: 2.2)
        case 4: party = Date()
        default: break
        }
    }

    private func type(_ text: String, after d: Double) {
        later(d, nil) { draft = text; draftStart = Date() }
    }

    private func send(id: Int, reply: Msg, at replyAt: Double) {
        let text = draft
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            msgs.append(Msg(id: id, text: text, mine: true, born: Date()))
            draft = ""
            draftStart = .distantFuture
            receipt = 1
            receiptFor = id
        }
        later(0.6) { receipt = 2 }
        later(1.2) { receipt = 3 }
        later(1.45) { typing = true }
        later(replyAt, .spring(response: 0.42, dampingFraction: 0.8)) {
            typing = false
            var r = reply
            r.born = Date()
            msgs.append(r)
        }
    }

    // MARK: Chrome

    private var blobs: some View {
        ZStack {
            Circle().fill(Self.violet.opacity(0.16)).frame(width: 320).blur(radius: 70).offset(x: -150, y: -300)
            Circle().fill(Color(hex: 0xFF7AC6).opacity(0.14)).frame(width: 300).blur(radius: 70).offset(x: 170, y: 160)
        }
        .ignoresSafeArea()
    }

    private var avatar: some View {
        Circle()
            .fill(LinearGradient(colors: [Color(hex: 0xFFB86B), Color(hex: 0xFF5FA2)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(Text("M").font(Self.rounded(20, .bold)).foregroundStyle(.white))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.left").font(.system(size: 21, weight: .semibold)).foregroundStyle(Self.violet)
            ZStack(alignment: .bottomTrailing) {
                avatar.frame(width: 48, height: 48)
                Circle().fill(Color(hex: 0x34D27B)).frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Self.bg, lineWidth: 2.5))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text("Mika").font(Self.rounded(21, .bold)).foregroundStyle(Self.ink)
                Text(typing ? "typing…" : "online")
                    .font(Self.rounded(14, .semibold))
                    .foregroundStyle(typing ? Self.violet : Self.ink.opacity(0.45))
                    .contentTransition(.opacity)
            }
            Spacer()
            ForEach(["phone.fill", "video.fill"], id: \.self) { s in
                Image(systemName: s).font(.system(size: 16, weight: .semibold)).foregroundStyle(Self.violet)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Self.violet.opacity(0.1)))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
    }

    // MARK: Messages

    private var messages: some View {
        TimelineView(.animation) { tl in
            VStack(spacing: 7) {
                Spacer(minLength: 0)
                Text("Today 9:38").font(Self.rounded(12, .semibold)).foregroundStyle(Self.ink.opacity(0.35))
                    .padding(.bottom, 6)
                    .reveal(1)
                ForEach(Array(msgs.enumerated()), id: \.element.id) { i, m in
                    bubble(m, now: tl.date)
                        .reveal(min(i, 6) + 1)
                        .transition(.identity)
                    if m.id == receiptFor && receipt > 0 {
                        receiptRow.transition(.opacity)
                    }
                }
                if typing {
                    typingRow(tl.date)
                        .transition(.scale(scale: 0.3, anchor: .bottomLeading).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(minHeight: 0, maxHeight: .infinity, alignment: .bottom)
        .clipped()
    }

    private func bubble(_ m: Msg, now: Date) -> some View {
        let t = m.born.map { now.timeIntervalSince($0) } ?? 10
        let p = max(0, boing(t))
        let wob = t < 0 ? 0 : exp(-6 * t) * sin(18 * t) * 0.16
        let rise = m.mine ? (1 - smooth(t / 0.3)) * 80 : 0
        var hop = 1.0
        if m.id == 10, let s = party { let u = now.timeIntervalSince(s); hop = 1 + (u > 0 ? exp(-4 * u) * sin(15 * u) * 0.35 : 0) }
        return HStack(spacing: 0) {
            if m.mine { Spacer(minLength: 64) }
            content(m, now: now)
                .scaleEffect(x: p * (1 + wob) * hop, y: p * (1 - wob) * hop, anchor: m.mine ? .bottomTrailing : .bottomLeading)
                .offset(y: rise)
                .demoTap(m.id == 8 ? 2 : m.id == 10 ? 4 : 0)
            if !m.mine { Spacer(minLength: 64) }
        }
    }

    @ViewBuilder private func content(_ m: Msg, now: Date) -> some View {
        if m.photo {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color(hex: 0xFFB36B), Color(hex: 0xFF6F91), Color(hex: 0x8E6BFF)],
                               startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hex: 0xFFF1C9)).frame(width: 46).offset(x: 140, y: -78)
                Image(systemName: "mountain.2.fill").font(.system(size: 120)).foregroundStyle(Color(hex: 0x4B2C7A).opacity(0.55))
                    .offset(x: 70, y: 22)
                Text("Kyoto · 6:12 pm").font(Self.rounded(13, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(.black.opacity(0.25)))
                    .padding(10)
            }
            .frame(width: 236, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Self.ink.opacity(0.12), radius: 10, y: 4)
        } else if m.big {
            Text(m.text).font(.system(size: 84))
                .padding(.leading, 6)
        } else {
            let shape = UnevenRoundedRectangle(cornerRadii: .init(topLeading: 22, bottomLeading: m.mine ? 22 : 7,
                                                                  bottomTrailing: m.mine ? 7 : 22, topTrailing: 22))
            Text(m.text)
                .font(Self.rounded(18, .medium))
                .foregroundStyle(m.mine ? .white : Self.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(
                    shape.fill(m.mine ? AnyShapeStyle(Self.mineFill) : AnyShapeStyle(.white))
                        .shadow(color: (m.mine ? Self.violet : Self.ink).opacity(m.mine ? 0.28 : 0.07), radius: 10, y: 4)
                )
                .overlay(alignment: .topTrailing) {
                    if m.id == 8, let h = heart { heartBadge(now.timeIntervalSince(h)).offset(x: 14, y: -16) }
                }
        }
    }

    private var receiptRow: some View {
        HStack(spacing: 5) {
            Spacer()
            if receipt == 3 { avatar.frame(width: 15, height: 15).transition(.scale.combined(with: .opacity)) }
            Image(systemName: receipt == 1 ? "checkmark" : "checkmark.circle.fill")
                .font(.system(size: 11, weight: .bold))
                .contentTransition(.symbolEffect(.replace))
            Text(["", "Sent", "Delivered", "Read 9:41"][receipt])
                .font(Self.rounded(12, .semibold))
                .contentTransition(.opacity)
        }
        .foregroundStyle(receipt == 3 ? Self.violet : Self.ink.opacity(0.4))
        .padding(.trailing, 4)
        .padding(.top, -2)
    }

    private func typingRow(_ now: Date) -> some View {
        let t = now.timeIntervalSinceReferenceDate
        return HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(Self.violet.opacity(0.75)).frame(width: 9, height: 9)
                        .offset(y: -6 * max(0, sin(t * 9 - Double(i) * 0.8)))
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 42)
            .background(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 22, bottomLeading: 7, bottomTrailing: 22, topTrailing: 22))
                .fill(.white).shadow(color: Self.ink.opacity(0.07), radius: 10, y: 4))
            Spacer()
        }
    }

    private func heartBadge(_ t: Double) -> some View {
        let p = max(0, boing(t, k: 6, w: 15))
        return ZStack {
            ForEach(0..<8, id: \.self) { i in
                let a = Double(i) / 8 * 2 * .pi
                let d = smooth(t / 0.6) * 42
                Image(systemName: "heart.fill").font(.system(size: 10))
                    .foregroundStyle(i % 2 == 0 ? Color(hex: 0xFF4D8D) : Self.violet)
                    .offset(x: cos(a) * d, y: sin(a) * d)
                    .opacity(t < 0.05 ? 0 : 1 - smooth((t - 0.3) / 0.45))
            }
            Image(systemName: "heart.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(LinearGradient(colors: [Color(hex: 0xFF7AB0), Color(hex: 0xFF2E73)],
                                                         startPoint: .top, endPoint: .bottom)))
                .overlay(Circle().stroke(Self.bg, lineWidth: 3))
                .scaleEffect(p)
                .rotationEffect(.degrees(-14 * exp(-5 * t) * sin(14 * t)))
        }
    }

    // MARK: Composer

    private var composer: some View {
        TimelineView(.animation) { tl in
            let n = Int(max(0, tl.date.timeIntervalSince(draftStart)) / 0.055)
            let shown = String(draft.prefix(n))
            let blink = sin(tl.date.timeIntervalSinceReferenceDate * 7) > -0.2 ? 1.0 : 0.0
            HStack(spacing: 10) {
                Image(systemName: "plus").font(.system(size: 19, weight: .bold)).foregroundStyle(Self.violet)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Self.violet.opacity(0.1)))
                HStack(spacing: 1) {
                    if shown.isEmpty {
                        Rectangle().fill(Self.violet).frame(width: 2, height: 22).opacity(blink)
                        Text("Message").foregroundStyle(Self.ink.opacity(0.3))
                    } else {
                        Text(shown).foregroundStyle(Self.ink)
                        Rectangle().fill(Self.violet).frame(width: 2, height: 22).opacity(blink)
                    }
                    Spacer(minLength: 0)
                }
                .transaction { $0.animation = nil }
                .font(Self.rounded(17, .medium))
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(Capsule().fill(.white).shadow(color: Self.ink.opacity(0.06), radius: 8, y: 3))
                Image(systemName: "arrow.up").font(.system(size: 20, weight: .heavy)).foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Self.mineFill).shadow(color: Self.violet.opacity(0.4), radius: 10, y: 4))
                    .opacity(shown.isEmpty ? 0.45 : 1)
                    .scaleEffect(demo.isPressing(1, 3) ? 0.8 : 1)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: demo.isPressing(1, 3))
                    .demoTap(1, 3)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}
