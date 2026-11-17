import SwiftUI

/// Reach: creator analytics set like a Swiss poster. Hairline rules, a huge
/// compressed figure, cobalt bars with one coral peak.
struct Reach: View {
    @EnvironmentObject var demo: Demo

    static let bg = Color(hex: 0xF4F3EE)
    static let ink = Color(hex: 0x111111)
    static let mute = Color(hex: 0x7B7A73)
    static let rule = Color(hex: 0x111111, alpha: 0.14)
    static let cobalt = Color(hex: 0x2B44FF)
    static let coral = Color(hex: 0xFF5A3C)

    static let ranges = ["30D", "90D", "1Y"]
    static let totals = [1_284_000.0, 3_942_000, 14_610_000]
    static let deltas = [24.6, 18.2, 212.0]
    static let spans = [30, 90, 365]
    static let series: [[Double]] = [
        bars(seed: 0.6, trend: 0.3), bars(seed: 2.2, trend: 0.5), bars(seed: 4.0, trend: 1.2),
    ]
    static func bars(seed: Double, trend: Double) -> [Double] {
        (0..<30).map { i in
            let t = Double(i) / 29
            let spike = exp(-pow((t - 0.7 + seed * 0.02) * 9, 2)) * 0.9
            return 0.22 + trend * 0.35 * t + 0.16 * (sin(t * 23 + seed) * 0.5 + 0.5) + spike
        }
    }
    static let kpis: [[(String, String, [Double])]] = [
        [("FOLLOWERS", "+12.4K", wave(12, seed: 1, from: 0, to: 1, vol: 0.1)), ("LIKES", "214K", wave(12, seed: 2, from: 0.3, to: 0.9, vol: 0.2)),
         ("AVG WATCH", "38s", wave(12, seed: 3, from: 0.5, to: 0.7, vol: 0.2))],
        [("FOLLOWERS", "+31.8K", wave(12, seed: 4, from: 0, to: 1, vol: 0.15)), ("LIKES", "602K", wave(12, seed: 5, from: 0.2, to: 1, vol: 0.2)),
         ("AVG WATCH", "35s", wave(12, seed: 6, from: 0.6, to: 0.5, vol: 0.2))],
        [("FOLLOWERS", "+108K", wave(12, seed: 7, from: 0, to: 1, vol: 0.05)), ("LIKES", "2.3M", wave(12, seed: 8, from: 0, to: 1, vol: 0.1)),
         ("AVG WATCH", "33s", wave(12, seed: 9, from: 0.4, to: 0.6, vol: 0.2))],
    ]

    private var r: Int { min(demo.range, 2) }

    var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header.reveal(0)
                    hero.reveal(1).padding(.top, 18)
                    chart.reveal(2).padding(.top, 14)
                    kpiRow.reveal(3).padding(.top, 22)
                    posts.reveal(4).padding(.top, 22)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollDisabled(true)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("REACH").font(.system(size: 15, weight: .black)).kerning(3)
                    Text("/ Analytics").font(.system(size: 15, weight: .regular)).foregroundStyle(Self.mute)
                }
                .foregroundStyle(Self.ink)
                Spacer()
                HStack(spacing: 8) {
                    Circle().fill(LinearGradient(colors: [Self.coral, Self.cobalt], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 26, height: 26)
                    Text("@josehiro").font(.system(size: 13, weight: .semibold)).foregroundStyle(Self.ink)
                }
                .padding(.leading, 4).padding(.trailing, 12).padding(.vertical, 4)
                .overlay(Capsule().stroke(Self.ink, lineWidth: 1))
            }
            Rectangle().fill(Self.ink).frame(height: 1.5)
        }
    }

    private var hero: some View {
        let xs = Self.series[r]
        let sum = xs.reduce(0, +)
        let idx = demo.scrub.map { min(29, Int($0 * 30)) }
        let value = idx.map { Self.totals[r] * xs[$0] / sum } ?? Self.totals[r]
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(idx == nil ? "VIEWS" : "VIEWS ON \(day(idx!).uppercased())")
                    .font(.system(size: 12, weight: .bold)).kerning(2).foregroundStyle(Self.ink)
                Spacer()
                RangePicker(options: Self.ranges, font: .system(size: 13, weight: .bold), on: Self.bg, off: Self.ink, spacing: 2,
                            itemPadding: EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)) {
                    Capsule().fill(Self.ink)
                }
            }
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Counter(value: demo.appeared ? value : 0) { Fmt.compact($0) }
                    .font(.system(size: 96, weight: .black).width(.compressed))
                    .foregroundStyle(Self.ink)
                    .animation(.easeOut(duration: 1.4).delay(0.25), value: demo.appeared)
                    .padding(.bottom, -10)
                if idx == nil {
                    Text("▲ " + String(format: "%.1f%%", Self.deltas[r]))
                        .font(.system(size: 15, weight: .bold)).monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9).padding(.vertical, 4)
                        .background(Self.cobalt)
                        .transition(.opacity)
                }
            }
        }
    }

    private func day(_ i: Int) -> String {
        let daysAgo = Double(Self.spans[r]) * (1 - Double(i) / 29)
        let d = Date(timeIntervalSince1970: 1_794_960_000 - daysAgo * 86_400)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d"
        return f.string(from: d)
    }

    private var chart: some View {
        let xs = Self.series[r]
        let hi = xs.max() ?? 1
        let peak = xs.firstIndex(of: hi) ?? 0
        let sel = demo.scrub.map { min(29, Int($0 * 30)) }
        return VStack(spacing: 8) {
            GeometryReader { g in
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<30, id: \.self) { i in
                        let color = sel == i ? Self.ink : (i == peak ? Self.coral : Self.cobalt)
                        Rectangle()
                            .fill(color)
                            .opacity(sel != nil && sel != i ? 0.25 : 1)
                            .frame(height: max(2, g.size.height * xs[i] / hi * (demo.appeared ? 1 : 0)))
                            .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.35 + Double(i) * 0.02), value: demo.appeared)
                    }
                }
                .frame(height: g.size.height, alignment: .bottom)
                .scrubbable(demo)
            }
            .frame(height: 170)
            .demoFrame("chart")
            Rectangle().fill(Self.ink).frame(height: 1.5)
            HStack {
                Text(day(0)).font(.system(size: 11, weight: .semibold)).foregroundStyle(Self.mute)
                Spacer()
                Text("PEAK  " + day(peak)).font(.system(size: 11, weight: .bold)).kerning(1).foregroundStyle(Self.coral)
                Spacer()
                Text("TODAY").font(.system(size: 11, weight: .semibold)).foregroundStyle(Self.mute)
            }
        }
    }

    private var kpiRow: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { i in
                let k = Self.kpis[r][i]
                VStack(alignment: .leading, spacing: 6) {
                    Text(k.0).font(.system(size: 10, weight: .bold)).kerning(1.2).foregroundStyle(Self.mute)
                    Text(k.1).font(.system(size: 30, weight: .black).width(.compressed)).foregroundStyle(Self.ink)
                        .contentTransition(.numericText())
                    Sparkline(data: k.2, color: Self.cobalt, width: 1.5).frame(height: 20)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    if i > 0 { Rectangle().fill(Self.rule).frame(width: 1) }
                }
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(Self.rule).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(Self.rule).frame(height: 1) }
    }

    private var posts: some View {
        let rows: [(String, String, UInt32, UInt32)] = [
            ("Penalty upload animation", "412K", 0x2B44FF, 0x7FA0FF), ("iOS tab bars, 4 ways", "286K", 0xFF5A3C, 0xFFB199),
            ("Dashboards in SwiftUI", "174K", 0x111111, 0x5A5A5A),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            Text("TOP POSTS").font(.system(size: 12, weight: .bold)).kerning(2).foregroundStyle(Self.ink)
            ForEach(0..<3, id: \.self) { i in
                let p = rows[i]
                HStack(spacing: 14) {
                    Text(String(format: "%02d", i + 1)).font(.system(size: 26, weight: .black).width(.compressed))
                        .foregroundStyle(i == 0 ? Self.coral : Self.ink.opacity(0.25)).frame(width: 30, alignment: .leading)
                    Rectangle().fill(LinearGradient(colors: [Color(hex: p.2), Color(hex: p.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 50)
                        .overlay(Image(systemName: "play.fill").font(.system(size: 12)).foregroundStyle(.white))
                    Text(p.0).font(.system(size: 15, weight: .semibold)).foregroundStyle(Self.ink)
                    Spacer()
                    Text(p.1).font(.system(size: 20, weight: .black).width(.compressed)).foregroundStyle(Self.ink)
                }
            }
        }
    }
}
