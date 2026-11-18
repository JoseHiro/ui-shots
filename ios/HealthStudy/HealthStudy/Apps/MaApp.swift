import SwiftUI

/// Ma (間): a mindfulness app in sumi ink on washi paper. A brushed ensō
/// guides the breath, and finishing a session presses a vermilion seal onto
/// today in the streak.
struct MaApp: View {
    @EnvironmentObject var demo: Demo

    static let paper = Color(hex: 0xF2ECDF)
    static let ink = Color(hex: 0x1C1A17)
    static let gray = Color(hex: 0x8E877A)
    static let shu = Color(hex: 0xC23B22)
    static func mincho(_ size: CGFloat, bold: Bool = false) -> Font { .custom(bold ? "HiraMinProN-W6" : "HiraMinProN-W3", size: size) }

    /// Pause before each step: choose Breath, start, finish, choose Sleep.
    static let script: [Double] = [1.8, 1.5, 6.2, 2.0]

    static let practices = [("呼吸", "Breath", "5分"), ("ヨガ", "Yoga", "20分"), ("眠り", "Sleep", "10分")]
    private var selected: Int { demo.step >= 4 ? 2 : demo.step >= 1 ? 0 : 1 }
    private var inSession: Bool { demo.step == 2 }
    private var finished: Bool { demo.step >= 3 }

    var body: some View {
        ZStack {
            Self.paper.ignoresSafeArea()
            WashiFibers().ignoresSafeArea()
            VStack(spacing: 0) {
                header.reveal(0)
                enso.reveal(1).padding(.top, 14)
                list.reveal(2).padding(.top, 10)
                streak.reveal(3).padding(.top, 24)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .top) {
            HStack(alignment: .center, spacing: 12) {
                Text("間").font(Self.mincho(50, bold: true)).foregroundStyle(Self.ink)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ma").font(.system(size: 20, weight: .regular, design: .serif)).italic().foregroundStyle(Self.ink)
                    Text("a pause, every day").font(.system(size: 12, design: .serif)).foregroundStyle(Self.gray)
                }
            }
            Spacer()
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 2) {
                    ForEach(Array(Array("十一月十八日").enumerated()), id: \.offset) { _, c in
                        Text(String(c)).font(Self.mincho(13))
                    }
                }
                .foregroundStyle(Self.ink.opacity(0.75))
                Seal(text: "静", size: 34)
            }
        }
    }

    // MARK: Ensō

    private var enso: some View {
        VStack(spacing: 12) {
            ZStack {
                InkWash(start: inSession ? demo.stepDate[2] : nil)
                    .frame(width: 210, height: 210)
                Enso(drawn: demo.appeared)
                    .frame(width: 236, height: 236)
                center
            }
            .frame(height: 250)
            .contentShape(Circle())
            .demoTap(2)

            Group {
                if inSession {
                    Text("終える  ·  finish").font(Self.mincho(14)).foregroundStyle(Self.shu)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .overlay(Capsule().stroke(Self.shu.opacity(0.6), lineWidth: 1))
                        .demoTap(3)
                        .transition(.opacity)
                } else {
                    Text(finished ? "今日の一息、おつかれさま" : "円の中に触れて、始める")
                        .font(Self.mincho(13)).foregroundStyle(Self.gray)
                        .padding(.vertical, 8)
                        .transition(.opacity)
                }
            }
            .frame(height: 36)
        }
    }

    @ViewBuilder private var center: some View {
        if inSession, let t0 = demo.stepDate[2] {
            TimelineView(.animation) { tl in
                let e = tl.date.timeIntervalSince(t0)
                let inhale = e.truncatingRemainder(dividingBy: 8) < 4
                let left = max(0, 300 - e)
                VStack(spacing: 6) {
                    Text(inhale ? "吸う" : "吐く").font(Self.mincho(40, bold: true)).foregroundStyle(Self.ink)
                        .id(inhale).transition(.opacity)
                    Text(inhale ? "breathe in" : "breathe out").font(.system(size: 13, design: .serif)).italic().foregroundStyle(Self.gray)
                    Text(String(format: "%d:%02d", Int(left) / 60, Int(left) % 60)).font(.system(size: 13, design: .serif))
                        .monospacedDigit().foregroundStyle(Self.ink.opacity(0.6)).padding(.top, 4)
                }
                .animation(.easeInOut(duration: 0.6), value: inhale)
            }
            .transition(.opacity)
        } else {
            VStack(spacing: 6) {
                Text(finished ? "了" : "始").font(Self.mincho(46, bold: true)).foregroundStyle(Self.ink)
                Text(finished ? "5 min · done" : Self.practices[selected].1 + " · " + Self.practices[selected].2.replacingOccurrences(of: "分", with: " min"))
                    .font(.system(size: 13, design: .serif)).italic().foregroundStyle(Self.gray)
            }
            .scaleEffect(demo.isPressing(2) ? 0.92 : 1)
            .transition(.opacity)
        }
    }

    // MARK: Practices

    private var list: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                let p = Self.practices[i]
                let on = selected == i
                VStack(spacing: 4) {
                    Text(p.0).font(Self.mincho(22, bold: on)).foregroundStyle(Self.ink.opacity(on ? 1 : 0.45))
                    Text(p.1 + " · " + p.2).font(.system(size: 11, design: .serif)).foregroundStyle(Self.gray)
                    BrushStroke()
                        .trim(from: 0, to: on ? 1 : 0)
                        .stroke(Self.ink, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 58, height: 8)
                        .animation(.easeOut(duration: 0.5), value: on)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .demoTap(i == 0 ? 1 : i == 2 ? 4 : 99)
                if i < 2 { Rectangle().fill(Self.ink.opacity(0.15)).frame(width: 1, height: 44) }
            }
        }
    }

    // MARK: Streak

    private var streak: some View {
        let done: Set<Int> = [0, 1, 3, 4, 5, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
        let today = 27
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("連続").font(Self.mincho(15)).foregroundStyle(Self.ink)
                Text(finished ? "13" : "12").font(.system(size: 30, weight: .regular, design: .serif)).foregroundStyle(Self.ink)
                    .contentTransition(.numericText())
                Text("日 · days in a row").font(Self.mincho(13)).foregroundStyle(Self.gray)
                Spacer()
                Text("霜月").font(Self.mincho(13)).foregroundStyle(Self.gray)
            }
            Grid(horizontalSpacing: 0, verticalSpacing: 12) {
                ForEach(0..<4, id: \.self) { r in
                    GridRow {
                        ForEach(0..<7, id: \.self) { c in
                            let d = r * 7 + c
                            ZStack {
                                if d == today {
                                    Circle().stroke(Self.ink.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                                        .frame(width: 30, height: 30)
                                    if finished {
                                        Seal(text: "了", size: 30).rotationEffect(.degrees(-8))
                                            .transition(.asymmetric(insertion: .scale(scale: 2.4).combined(with: .opacity), removal: .opacity))
                                    }
                                } else if done.contains(d) {
                                    InkDot(seed: d).frame(width: 22, height: 22)
                                } else {
                                    Circle().fill(Self.ink.opacity(0.08)).frame(width: 7, height: 7)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 30)
                        }
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.55), value: finished)
        }
    }
}

/// A hand-brushed circle: several offset strokes and a dry-brush streak layer.
private struct Enso: View {
    let drawn: Bool
    /// (start, end, width, opacity): wide strokes stop early, thin ones run on, so the circle tapers like a brush.
    private let layers: [(Double, Double, CGFloat, Double)] = [
        (0.0, 0.55, 18, 0.92), (0.005, 0.72, 14, 0.9), (0.01, 0.84, 10, 0.85), (0.015, 0.91, 6.5, 0.8), (0.02, 0.95, 3.5, 0.7),
    ]
    var body: some View {
        ZStack {
            ForEach(0..<layers.count, id: \.self) { k in
                let l = layers[k]
                Circle()
                    .trim(from: l.0, to: drawn ? l.1 : l.0)
                    .stroke(MaApp.ink.opacity(l.3), style: StrokeStyle(lineWidth: l.2, lineCap: .round))
                    .offset(x: CGFloat(k) * 0.9, y: -CGFloat(k) * 0.5)
            }
            // Dry-brush streaks where the ink runs out.
            Circle()
                .trim(from: 0.5, to: drawn ? 0.93 : 0.5)
                .stroke(MaApp.ink.opacity(0.4), style: StrokeStyle(lineWidth: 16, lineCap: .butt, dash: [1.1, 2.4]))
        }
        .rotationEffect(.degrees(-100))
        .animation(.timingCurve(0.5, 0, 0.3, 1, duration: 1.8).delay(0.35), value: drawn)
    }
}

/// Soft ink wash that swells on the inhale and settles on the exhale.
private struct InkWash: View {
    let start: Date?
    var body: some View {
        TimelineView(.animation) { tl in
            let e = start.map { tl.date.timeIntervalSince($0) } ?? 0
            let phase = (1 - cos(e / 8 * 2 * .pi)) / 2
            Circle()
                .fill(RadialGradient(colors: [MaApp.ink.opacity(0.16), MaApp.ink.opacity(0.03)], center: .center, startRadius: 0, endRadius: 110))
                .scaleEffect(start == nil ? 0.55 : 0.5 + 0.45 * phase)
        }
    }
}

/// Vermilion hanko with a white character.
struct Seal: View {
    let text: String
    let size: CGFloat
    var body: some View {
        Text(text)
            .font(MaApp.mincho(size * 0.62, bold: true))
            .foregroundStyle(MaApp.paper)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.12).fill(MaApp.shu))
            .overlay(RoundedRectangle(cornerRadius: size * 0.12).stroke(MaApp.paper.opacity(0.5), lineWidth: 1).padding(2.5))
    }
}

private struct InkDot: View {
    let seed: Int
    var body: some View {
        let s = 0.7 + 0.3 * abs(sin(Double(seed) * 3.1))
        Circle()
            .fill(RadialGradient(colors: [MaApp.ink.opacity(0.95), MaApp.ink.opacity(0.75)], center: .init(x: 0.4, y: 0.4), startRadius: 0, endRadius: 12))
            .scaleEffect(x: s, y: s * (0.9 + 0.1 * sin(Double(seed))))
            .rotationEffect(.degrees(Double(seed * 37 % 90)))
    }
}

private struct BrushStroke: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + 1))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY - 1), control: CGPoint(x: r.midX, y: r.minY))
        return p
    }
}

/// Faint fibers so the background reads as washi paper.
private struct WashiFibers: View {
    var body: some View {
        Canvas { ctx, size in
            for i in 0..<160 {
                let a = Double(i)
                let x = abs(sin(a * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1) * size.width
                let y = abs(sin(a * 78.233) * 12543.123).truncatingRemainder(dividingBy: 1) * size.height
                let ang = sin(a * 3.7) * .pi
                let len = 10 + 26 * abs(sin(a * 1.3))
                var p = Path()
                p.move(to: CGPoint(x: x, y: y))
                p.addQuadCurve(to: CGPoint(x: x + cos(ang) * len, y: y + sin(ang) * len),
                               control: CGPoint(x: x + cos(ang + 0.6) * len / 2, y: y + sin(ang + 0.6) * len / 2))
                ctx.stroke(p, with: .color(Color(hex: 0x8A7A5C).opacity(0.10 + 0.08 * abs(sin(a)))), lineWidth: 0.7)
            }
        }
    }
}
