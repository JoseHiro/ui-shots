import SwiftUI

/// Lull: a sleep tracker at dusk. Twinkling sky, an angular score ring and a
/// hypnogram whose line takes the color of each sleep stage.
struct Lull: View {
    @EnvironmentObject var demo: Demo

    static let text = Color(hex: 0xEEEBFF)
    static let mute = Color(hex: 0x9D98C8)
    static let awake = Color(hex: 0xFFB98A)
    static let rem = Color(hex: 0xF28DC2)
    static let core = Color(hex: 0x9D8CFF)
    static let deep = Color(hex: 0x5A6BFF)
    static let stages: [(String, Color)] = [("Deep", deep), ("Core", core), ("REM", rem), ("Awake", awake)]

    static let ranges = ["Last night", "Sat", "Fri"]
    static let scores = [86, 78, 91]
    static let windows = ["11:08 PM – 6:50 AM", "11:46 PM – 7:02 AM", "10:52 PM – 6:58 AM"]
    static let quality = ["Restful", "Light", "Excellent"]
    static let nights: [[Int]] = [night(0), night(1), night(2)]

    /// 48 ten-minute slots: 0 deep, 1 core, 2 REM, 3 awake.
    static func night(_ s: Int) -> [Int] {
        let src = ["311000011122111000112221111011222111122211222113",
                   "331100111221113110011222111112223111222111222333",
                   "310000011221110000111222111001222211112221112221"][s]
        return src.map { Int(String($0))! }
    }

    private var r: Int { min(demo.range, 2) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x080C24), Color(hex: 0x1A1645), Color(hex: 0x3A2258)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Stars().ignoresSafeArea()
            RadialGradient(colors: [Self.rem.opacity(0.18), .clear], center: .bottom, startRadius: 0, endRadius: 380).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header.reveal(0)
                    RangePicker(options: Self.ranges, font: .system(size: 13, weight: .medium, design: .rounded),
                                on: Self.text, off: Self.mute, spacing: 2,
                                itemPadding: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)) {
                        Capsule().fill(.white.opacity(0.14)).overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 0.8))
                    }
                    .padding(3)
                    .background(.white.opacity(0.05), in: Capsule())
                    .reveal(1)
                    hero.reveal(2)
                    hypnogram.reveal(3)
                    breakdown.reveal(4)
                    HStack(spacing: 12) {
                        vital("heart.fill", Self.rem, "52", "bpm resting", wave(16, seed: 1.5, from: 0.7, to: 0.3, vol: 0.12))
                        vital("waveform.path.ecg", Self.core, "68", "ms HRV", wave(16, seed: 3.3, from: 0.3, to: 0.8, vol: 0.15))
                    }
                    .reveal(5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollDisabled(true)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good morning").font(.system(size: 28, weight: .light, design: .rounded)).foregroundStyle(Self.text)
                Text("You slept well, Noa").font(.system(size: 14, design: .rounded)).foregroundStyle(Self.mute)
            }
            Spacer()
            Image(systemName: "moon.stars.fill").font(.system(size: 18)).foregroundStyle(Self.awake)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.white.opacity(0.06)))
                .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 0.8))
        }
    }

    private var hero: some View {
        let score = Double(Self.scores[r])
        let mins = Self.nights[r].filter { $0 != 3 }.count * 10
        return HStack(spacing: 22) {
            ZStack {
                Circle().stroke(.white.opacity(0.08), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: demo.appeared ? score / 100 : 0)
                    .stroke(AngularGradient(colors: [Self.deep, Self.core, Self.rem, Self.awake], center: .center,
                                            startAngle: .degrees(0), endAngle: .degrees(360 * score / 100)),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Self.rem.opacity(0.45), radius: 10)
                    .animation(.spring(response: 1.4, dampingFraction: 0.9).delay(0.3), value: demo.appeared)
                VStack(spacing: 0) {
                    Counter(value: demo.appeared ? score : 0) { "\(Int($0.rounded()))" }
                        .font(.system(size: 46, weight: .semibold, design: .rounded)).foregroundStyle(Self.text)
                        .animation(.easeOut(duration: 1.3).delay(0.3), value: demo.appeared)
                    Text("SCORE").font(.system(size: 10, weight: .semibold, design: .rounded)).kerning(2).foregroundStyle(Self.mute)
                }
            }
            .frame(width: 140, height: 140)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(mins / 60)h \(mins % 60)m").font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundStyle(Self.text).contentTransition(.numericText())
                    Text("asleep").font(.system(size: 13, design: .rounded)).foregroundStyle(Self.mute)
                }
                Text(Self.windows[r]).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(Self.text.opacity(0.85))
                    .contentTransition(.numericText())
                Text(Self.quality[r]).font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1A1645))
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(LinearGradient(colors: [Self.awake, Self.rem], startPoint: .leading, endPoint: .trailing), in: Capsule())
            }
            Spacer(minLength: 0)
        }
    }

    private var hypnogram: some View {
        let levels = Self.nights[r]
        let ys = levels.map { 0.08 + 0.84 * Double($0) / 3 }
        return VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading) {
                    ForEach(Array(Self.stages.reversed().enumerated()), id: \.offset) { i, s in
                        if i > 0 { Spacer() }
                        Text(s.0).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(s.1)
                    }
                }
                .padding(.vertical, 2)
                .frame(width: 40, alignment: .leading)

                GeometryReader { g in
                    ZStack(alignment: .topLeading) {
                        ForEach(0..<4, id: \.self) { k in
                            Line().stroke(.white.opacity(0.07), style: StrokeStyle(lineWidth: 1, dash: [2, 4])).frame(height: 1)
                                .offset(y: g.size.height * (0.08 + 0.84 * CGFloat(k) / 3))
                        }
                        StepShape(data: Vec(v: ys), closed: true)
                            .fill(LinearGradient(colors: [Self.awake.opacity(0.22), Self.rem.opacity(0.16), Self.core.opacity(0.12), Self.deep.opacity(0.02)],
                                                 startPoint: .top, endPoint: .bottom))
                            .opacity(demo.appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.8).delay(1.3), value: demo.appeared)
                        StepShape(data: Vec(v: ys))
                            .trim(from: 0, to: demo.appeared ? 1 : 0)
                            .stroke(LinearGradient(stops: [.init(color: Self.awake, location: 0.08), .init(color: Self.rem, location: 0.36),
                                                           .init(color: Self.core, location: 0.64), .init(color: Self.deep, location: 0.92)],
                                                   startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .shadow(color: Self.core.opacity(0.7), radius: 6)
                            .animation(.easeInOut(duration: 1.6).delay(0.45), value: demo.appeared)

                        if let s = demo.scrub {
                            let i = min(47, Int(s * 48))
                            let x = g.size.width * (CGFloat(i) + 0.5) / 48
                            let y = g.size.height * (1 - CGFloat(ys[i]))
                            let st = Self.stages[levels[i]]
                            Rectangle().fill(.white.opacity(0.3)).frame(width: 1, height: g.size.height).position(x: x, y: g.size.height / 2)
                            Circle().fill(st.1).frame(width: 11, height: 11).overlay(Circle().stroke(.white, lineWidth: 2))
                                .shadow(color: st.1, radius: 8).position(x: x, y: y)
                            HStack(spacing: 6) {
                                Text(time(i)).foregroundStyle(Self.text)
                                Text(st.0).foregroundStyle(st.1)
                            }
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Capsule().fill(Color(hex: 0x241C52)))
                            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.8))
                            .fixedSize()
                            .position(x: min(max(x, 62), g.size.width - 62), y: -16)
                        }
                    }
                    .scrubbable(demo)
                }
                .demoFrame("chart")
            }
            .frame(height: 140)
            HStack {
                ForEach(["11 PM", "1 AM", "3 AM", "5 AM", "7 AM"], id: \.self) { t in
                    Text(t).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Self.mute)
                    if t != "7 AM" { Spacer() }
                }
            }
            .padding(.leading, 50)
        }
        .padding(.top, 26)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white.opacity(0.1), lineWidth: 0.8))
        .overlay(alignment: .topLeading) {
            Text("STAGES").font(.system(size: 11, weight: .semibold, design: .rounded)).kerning(2).foregroundStyle(Self.mute)
                .padding(16)
        }
    }

    private func vital(_ icon: String, _ c: Color, _ v: String, _ unit: String, _ d: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12)).foregroundStyle(c)
                Text(unit).font(.system(size: 12, design: .rounded)).foregroundStyle(Self.mute)
            }
            HStack(alignment: .bottom) {
                Text(v).font(.system(size: 28, weight: .medium, design: .rounded)).foregroundStyle(Self.text)
                Spacer()
                Sparkline(data: d, color: c, width: 2).frame(width: 70, height: 26).shadow(color: c.opacity(0.6), radius: 4)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.1), lineWidth: 0.8))
    }

    private func time(_ slot: Int) -> String {
        let m = 23 * 60 + slot * 10
        let h = (m / 60) % 24, mm = m % 60
        return String(format: "%d:%02d %@", h % 12 == 0 ? 12 : h % 12, mm, h >= 12 && h < 24 ? "PM" : "AM")
    }

    private var breakdown: some View {
        let levels = Self.nights[r]
        let mins = (0..<4).map { s in levels.filter { $0 == s }.count * 10 }
        let maxM = Double(mins.max() ?? 1)
        return VStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { s in
                let st = Self.stages[s]
                HStack(spacing: 12) {
                    Text(st.0).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(Self.text)
                        .frame(width: 50, alignment: .leading)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.06))
                            Capsule().fill(LinearGradient(colors: [st.1.opacity(0.6), st.1], startPoint: .leading, endPoint: .trailing))
                                .frame(width: g.size.width * Double(mins[s]) / maxM * (demo.appeared ? 1 : 0))
                                .shadow(color: st.1.opacity(0.5), radius: 6)
                        }
                    }
                    .frame(height: 8)
                    .animation(.spring(response: 1, dampingFraction: 0.85).delay(0.8 + Double(s) * 0.08), value: demo.appeared)
                    Text("\(mins[s] / 60)h \(mins[s] % 60)m").font(.system(size: 13, weight: .medium, design: .rounded))
                        .monospacedDigit().foregroundStyle(Self.mute).frame(width: 56, alignment: .trailing)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Stepped line for a hypnogram; `data` holds one y (0...1) per slot.
struct StepShape: Shape {
    var data: Vec
    var closed = false
    var animatableData: Vec {
        get { data }
        set { data = newValue }
    }
    func path(in r: CGRect) -> Path {
        let n = data.v.count
        guard n > 0 else { return Path() }
        let w = r.width / CGFloat(n)
        let y = { (i: Int) in r.height * (1 - CGFloat(data.v[i])) }
        var p = Path()
        p.move(to: CGPoint(x: 0, y: y(0)))
        for i in 0..<n {
            p.addLine(to: CGPoint(x: CGFloat(i) * w, y: y(i)))
            p.addLine(to: CGPoint(x: CGFloat(i + 1) * w, y: y(i)))
        }
        if closed {
            p.addLine(to: CGPoint(x: r.width, y: r.height))
            p.addLine(to: CGPoint(x: 0, y: r.height))
            p.closeSubpath()
        }
        return p
    }
}

private struct Stars: View {
    private let stars: [(CGFloat, CGFloat, CGFloat, Double)] = (0..<46).map { i in
        let a = Double(i)
        return (CGFloat((sin(a * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1).magnitude),
                CGFloat((sin(a * 78.233) * 12543.123).truncatingRemainder(dividingBy: 1).magnitude) * 0.55,
                CGFloat(1 + (i % 3)) * 0.8, a * 0.7)
    }
    var body: some View {
        GeometryReader { g in
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<stars.count, id: \.self) { i in
                        let s = stars[i]
                        Circle().fill(.white)
                            .frame(width: s.2, height: s.2)
                            .opacity(0.25 + 0.6 * (0.5 + 0.5 * sin(t * 1.3 + s.3)))
                            .position(x: s.0 * g.size.width, y: s.1 * g.size.height)
                    }
                }
            }
        }
    }
}
