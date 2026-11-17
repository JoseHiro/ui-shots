import SwiftUI

/// Hearth: a home energy hub in warm paper tones. A live flow diagram shows
/// where power is going right now; paired bars compare usage with solar.
struct Hearth: View {
    @EnvironmentObject var demo: Demo

    static let bg = Color(hex: 0xF3EEE6)
    static let ink = Color(hex: 0x1F2520)
    static let mute = Color(hex: 0x8C8B82)
    static let track = Color(hex: 0xEAE3D7)
    static let sun = Color(hex: 0xF2A93B)
    static let clay = Color(hex: 0xDD6B4D)
    static let sage = Color(hex: 0x5E9A76)

    static let ranges = ["Today", "Week", "Year"]
    /// (usage, solar) per bar, 12 bars for every range so the bars morph.
    static let data: [[(Double, Double)]] = [
        [(0.30, 0), (0.22, 0), (0.20, 0), (0.42, 0.10), (0.55, 0.48), (0.38, 0.82), (0.34, 0.95), (0.40, 0.88), (0.52, 0.60), (0.78, 0.22), (0.86, 0.02), (0.48, 0)],
        [(0.62, 0.70), (0.55, 0.82), (0.70, 0.40), (0.58, 0.66), (0.66, 0.90), (0.84, 0.74), (0.78, 0.52), (0.60, 0.80), (0.52, 0.88), (0.74, 0.36), (0.68, 0.60), (0.58, 0.72)],
        [(0.86, 0.22), (0.78, 0.34), (0.66, 0.52), (0.54, 0.70), (0.46, 0.86), (0.42, 0.96), (0.44, 0.98), (0.48, 0.90), (0.56, 0.70), (0.66, 0.48), (0.78, 0.30), (0.90, 0.18)],
    ]
    static let labels = [["12a", "", "", "6a", "", "", "12p", "", "", "6p", "", ""],
                         ["M", "T", "W", "T", "F", "S", "S", "M", "T", "W", "T", "F"],
                         ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]]
    static let totals = [18.4, 142.7, 6_120.0]
    static let units = ["kWh today", "kWh this week", "kWh this year"]
    static let solarShare = [64, 71, 58]

    private var r: Int { min(demo.range, 2) }

    var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header.reveal(0)
                    flow.reveal(1)
                    usage.reveal(2)
                    rooms.reveal(3)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
            .scrollDisabled(true)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Maple House").font(.system(size: 28, weight: .semibold, design: .rounded)).foregroundStyle(Self.ink)
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill").foregroundStyle(Self.sun)
                    Text("Sunny · 21°  ·  Mon 17 Nov")
                }
                .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(Self.mute)
            }
            Spacer()
            Image(systemName: "plus").font(.system(size: 16, weight: .semibold)).foregroundStyle(Self.ink)
                .frame(width: 44, height: 44).background(.white, in: Circle())
                .shadow(color: Self.ink.opacity(0.06), radius: 8, y: 3)
        }
    }

    private func card<C: View>(@ViewBuilder _ c: () -> C) -> some View {
        c()
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color(hex: 0x6B5A3E).opacity(0.07), radius: 18, y: 8)
    }

    private var flow: some View {
        card {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Energy now").font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(Self.ink)
                    Spacer()
                    HStack(spacing: 6) {
                        LiveDot(color: Self.sage)
                        Text("Live").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Self.sage)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Self.sage.opacity(0.12), in: Capsule())
                }
                FlowDiagram().frame(height: 176)
            }
        }
    }

    private var usage: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Counter(value: demo.appeared ? Self.totals[r] : 0) { v in Fmt.num(v, v < 1000 ? 1 : 0) }
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .foregroundStyle(Self.ink)
                            .animation(.easeOut(duration: 1.3).delay(0.4), value: demo.appeared)
                        Text(Self.units[r]).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(Self.mute)
                    }
                    Spacer()
                    RangePicker(options: Self.ranges, font: .system(size: 13, weight: .semibold, design: .rounded),
                                on: Self.ink, off: Self.mute, spacing: 0,
                                itemPadding: EdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 11)) {
                        Capsule().fill(.white).shadow(color: Self.ink.opacity(0.12), radius: 4, y: 2)
                    }
                    .padding(3)
                    .background(Self.track, in: Capsule())
                }
                bars
                HStack(spacing: 14) {
                    legend(Self.clay, "Usage")
                    legend(Self.sun, "Solar")
                    Spacer()
                    Text("Solar covered \(Self.solarShare[r])%").font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Self.sage).contentTransition(.numericText())
                }
            }
        }
    }

    private func legend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 10, height: 10)
            Text(t).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Self.mute)
        }
    }

    private var bars: some View {
        let d = Self.data[r]
        let sel = demo.scrub.map { min(11, Int($0 * 12)) }
        return VStack(spacing: 8) {
            GeometryReader { g in
                let slot = g.size.width / 12
                ZStack(alignment: .bottomLeading) {
                    ForEach(0..<3, id: \.self) { k in
                        Line().stroke(Self.track, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            .frame(height: 1).offset(y: -g.size.height * CGFloat(k + 1) / 3 + 0.5)
                    }
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(0..<12, id: \.self) { i in
                            let dim = sel != nil && sel != i
                            HStack(alignment: .bottom, spacing: 3) {
                                bar(d[i].0, Self.clay, g.size.height, i)
                                bar(d[i].1, Self.sun, g.size.height, i)
                            }
                            .opacity(dim ? 0.3 : 1)
                            .frame(width: slot)
                        }
                    }
                    if let i = sel {
                        tip(d[i]).position(x: min(max(slot * (CGFloat(i) + 0.5), 50), g.size.width - 50), y: 8)
                    }
                }
                .scrubbable(demo)
            }
            .frame(height: 140)
            .demoFrame("chart")
            HStack(spacing: 0) {
                ForEach(0..<12, id: \.self) { i in
                    Text(Self.labels[r][i]).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Self.mute)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func bar(_ v: Double, _ c: Color, _ h: CGFloat, _ i: Int) -> some View {
        UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 1.5, bottomTrailingRadius: 1.5, topTrailingRadius: 4)
            .fill(c)
            .frame(width: 8, height: max(3, h * 0.8 * CGFloat(v) * (demo.appeared ? 1 : 0)))
            .animation(.spring(response: 0.8, dampingFraction: 0.78).delay(0.45 + Double(i) * 0.035), value: demo.appeared)
    }

    private func tip(_ v: (Double, Double)) -> some View {
        let s = Self.totals[r] / 12 / 0.55
        return HStack(spacing: 8) {
            Text(Fmt.num(v.0 * s, 1)).foregroundStyle(Self.clay)
            Text(Fmt.num(v.1 * s, 1)).foregroundStyle(Color(hex: 0xC9861B))
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .monospacedDigit()
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(.white, in: Capsule())
        .shadow(color: Self.ink.opacity(0.14), radius: 6, y: 2)
        .fixedSize()
    }

    private var rooms: some View {
        HStack(spacing: 12) {
            tile("thermometer.medium", Self.clay, "Living", "21.5°", 0.62)
            tile("lightbulb.fill", Self.sun, "Lights", "4 on", 0.4)
            tile("car.fill", Self.sage, "EV", "82%", 0.82)
        }
    }

    private func tile(_ icon: String, _ c: Color, _ name: String, _ value: String, _ p: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(c)
                .frame(width: 34, height: 34).background(c.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.system(size: 19, weight: .semibold, design: .rounded)).foregroundStyle(Self.ink)
                Text(name).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(Self.mute)
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Self.track)
                    Capsule().fill(c).frame(width: g.size.width * p * (demo.appeared ? 1 : 0))
                }
            }
            .frame(height: 4)
            .animation(.spring(response: 1, dampingFraction: 0.85).delay(0.9), value: demo.appeared)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: 0x6B5A3E).opacity(0.07), radius: 14, y: 6)
    }
}

/// Solar, home, battery and grid with animated dashes running along each path.
private struct FlowDiagram: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let solar = CGPoint(x: w * 0.13, y: h * 0.5)
            let home = CGPoint(x: w * 0.5, y: h * 0.5)
            let batt = CGPoint(x: w * 0.87, y: h * 0.2)
            let grid = CGPoint(x: w * 0.87, y: h * 0.8)
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10)
                ZStack {
                    flowLine(from: solar, to: home, color: Hearth.sun, phase: t, bend: 0)
                    flowLine(from: home, to: batt, color: Hearth.sage, phase: t, bend: -1)
                    flowLine(from: home, to: grid, color: Hearth.clay, phase: t, bend: 1)
                }
            }
            node("sun.max.fill", Hearth.sun, "3.8 kW", "Solar").position(solar)
            node("battery.75percent", Hearth.sage, "84%", "Battery").position(batt)
            node("bolt.horizontal.fill", Hearth.clay, "1.4 kW", "To grid").position(grid)
            VStack(spacing: 1) {
                Image(systemName: "house.fill").font(.system(size: 16)).foregroundStyle(Hearth.ink)
                Text("2.4").font(.system(size: 24, weight: .semibold, design: .rounded)).foregroundStyle(Hearth.ink)
                Text("kW in use").font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Hearth.mute)
            }
            .frame(width: 104, height: 104)
            .background(Circle().fill(Hearth.bg))
            .overlay(Circle().stroke(Hearth.track, lineWidth: 6))
            .position(home)
        }
    }

    private func path(_ a: CGPoint, _ b: CGPoint, _ bend: CGFloat) -> Path {
        var p = Path()
        p.move(to: a)
        if bend == 0 { p.addLine(to: b) } else {
            p.addCurve(to: b, control1: CGPoint(x: a.x + (b.x - a.x) * 0.55, y: a.y), control2: CGPoint(x: a.x + (b.x - a.x) * 0.45, y: b.y))
        }
        return p
    }

    private func flowLine(from a: CGPoint, to b: CGPoint, color: Color, phase: Double, bend: CGFloat) -> some View {
        ZStack {
            path(a, b, bend).stroke(color.opacity(0.16), lineWidth: 5)
            path(a, b, bend).stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [0.1, 13.9],
                                                              dashPhase: -CGFloat((phase * 28).truncatingRemainder(dividingBy: 14))))
        }
    }

    private func node(_ icon: String, _ c: Color, _ value: String, _ name: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(c)
                .frame(width: 46, height: 46).background(Circle().fill(Color(hex: 0xFFFBF4)))
                .overlay(Circle().stroke(c.opacity(0.35), lineWidth: 1.5))
            VStack(spacing: 0) {
                Text(value).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(Hearth.ink)
                Text(name).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(Hearth.mute)
            }
        }
        .offset(y: 16)
    }
}

struct LiveDot: View {
    let color: Color
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6
            ZStack {
                Circle().fill(color.opacity(0.35 * (1 - t))).frame(width: 7 + 9 * t, height: 7 + 9 * t)
                Circle().fill(color).frame(width: 7, height: 7)
            }
        }
        .frame(width: 14, height: 14)
    }
}

struct Line: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        return p
    }
}
