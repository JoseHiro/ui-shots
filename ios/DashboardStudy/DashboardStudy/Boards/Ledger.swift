import SwiftUI

/// Ledger: private banking. Near-black, champagne gold hairlines and serif
/// numerals. Scrubbing the chart rewrites the net-worth figure in place.
struct Ledger: View {
    @EnvironmentObject var demo: Demo

    static let bg = Color(hex: 0x0C0C0E)
    static let gold = Color(hex: 0xDABD8E)
    static let ivory = Color(hex: 0xF2EDE4)
    static let mute = Color(hex: 0x8B867D)
    static let hair = Color(hex: 0x2A2830)
    static let sage = Color(hex: 0xAFCBA6)

    static let total = 248_930.52
    static let ranges = ["1W", "1M", "1Y", "ALL"]
    static let spans = [7.0, 30, 365, 1460]
    static let series: [[Double]] = [
        wave(40, seed: 1.2, from: 246_100, to: total, vol: 650),
        wave(40, seed: 2.9, from: 241_800, to: total, vol: 1_600),
        wave(40, seed: 0.4, from: 196_400, to: total, vol: 5_800),
        wave(40, seed: 4.1, from: 88_000, to: total, vol: 9_500),
    ]
    static let periods = ["past week", "past month", "past year", "all time"]

    private var r: Int { min(demo.range, 3) }

    var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()
            RadialGradient(colors: [Self.gold.opacity(0.13), .clear], center: .topTrailing, startRadius: 10, endRadius: 420)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header.reveal(0)
                    hero.reveal(1)
                    RangePicker(options: Self.ranges, font: .system(size: 12, weight: .semibold).width(.expanded),
                                on: Self.gold, off: Self.mute, spacing: 2) {
                        Capsule().fill(Self.gold.opacity(0.12)).overlay(Capsule().stroke(Self.gold.opacity(0.35), lineWidth: 0.8))
                    }
                    .reveal(2)
                    chart.reveal(3)
                    allocation.reveal(4)
                    accounts.reveal(5)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
            }
            .scrollDisabled(true)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Good evening,").font(.system(size: 14)).foregroundStyle(Self.mute)
                Text("Mira Laurent").font(.system(size: 21, weight: .medium, design: .serif)).foregroundStyle(Self.ivory)
            }
            Spacer()
            Image(systemName: "bell").font(.system(size: 15, weight: .light)).foregroundStyle(Self.ivory)
                .frame(width: 42, height: 42).overlay(Circle().stroke(Self.hair, lineWidth: 1))
            Text("ML").font(.system(size: 14, weight: .medium, design: .serif)).foregroundStyle(Self.gold)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Self.gold.opacity(0.1)))
                .overlay(Circle().stroke(Self.gold.opacity(0.6), lineWidth: 1))
        }
    }

    private var hero: some View {
        let xs = Self.series[r]
        let idx = demo.scrub.map { s in min(xs.count - 1, Int((s * CGFloat(xs.count - 1)).rounded())) }
        let value = idx.map { xs[$0] } ?? Self.total
        let change = value - xs[0]
        return VStack(alignment: .leading, spacing: 8) {
            Text("NET WORTH").font(.system(size: 11, weight: .semibold).width(.expanded)).kerning(2).foregroundStyle(Self.mute)
            Counter(value: demo.appeared ? value : 0) { v in "$" + Fmt.num(v, 2) }
                .font(.system(size: 44, weight: .light, design: .serif))
                .foregroundStyle(Self.ivory)
                .animation(.easeOut(duration: 1.5).delay(0.25), value: demo.appeared)
            HStack(spacing: 8) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right").font(.system(size: 11, weight: .bold))
                Text("$" + Fmt.num(abs(change), 2) + "  ·  " + String(format: "%.2f%%", abs(change) / xs[0] * 100))
                    .monospacedDigit()
                Text(idx.map { date($0) } ?? Self.periods[r]).foregroundStyle(Self.mute)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(change >= 0 ? Self.sage : Color(hex: 0xE58F7B))
        }
    }

    private func date(_ i: Int) -> String {
        let daysAgo = Self.spans[r] * (1 - Double(i) / 39)
        let d = Calendar.current.date(byAdding: .hour, value: -Int(daysAgo * 24), to: Date(timeIntervalSince1970: 1_794_960_000))!
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = r >= 2 ? "MMM yyyy" : "EEE, MMM d"
        return f.string(from: d)
    }

    private var chart: some View {
        let xs = normalize(Self.series[r], pad: 0.1)
        return GeometryReader { g in
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { i in
                        if i > 0 { Spacer() }
                        Rectangle().fill(Self.hair).frame(height: 0.7)
                    }
                }
                LineShape(data: Vec(v: xs), closed: true)
                    .fill(LinearGradient(colors: [Self.gold.opacity(0.26), Self.gold.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .opacity(demo.appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(1.2), value: demo.appeared)
                LineShape(data: Vec(v: xs))
                    .trim(from: 0, to: demo.appeared ? 1 : 0)
                    .stroke(Self.gold, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .shadow(color: Self.gold.opacity(0.5), radius: 6)
                    .animation(.easeInOut(duration: 1.4).delay(0.35), value: demo.appeared)

                if let s = demo.scrub {
                    let hit = chartPoint(xs, s, in: g.size)
                    Rectangle().fill(Self.ivory.opacity(0.35)).frame(width: 0.8, height: g.size.height)
                        .position(x: hit.point.x, y: g.size.height / 2)
                    marker.position(hit.point)
                } else {
                    let end = CGPoint(x: g.size.width, y: g.size.height * (1 - CGFloat(xs.last ?? 0)))
                    Pulse(color: Self.gold).position(end)
                        .opacity(demo.appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(1.7), value: demo.appeared)
                }
            }
            .scrubbable(demo)
        }
        .frame(height: 188)
        .demoFrame("chart")
    }

    private var marker: some View {
        Circle().fill(Self.gold).frame(width: 10, height: 10)
            .overlay(Circle().stroke(Self.bg, lineWidth: 2))
            .background(Circle().fill(Self.gold.opacity(0.25)).frame(width: 26, height: 26))
    }

    private var allocation: some View {
        let parts: [(String, Double, UInt32)] = [("Equities", 0.52, 0xDABD8E), ("Bonds", 0.21, 0xA38B66),
                                                 ("Cash", 0.15, 0x6A6152), ("Alternatives", 0.12, 0x3F3B35)]
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ALLOCATION").font(.system(size: 11, weight: .semibold).width(.expanded)).kerning(2).foregroundStyle(Self.mute)
                Spacer()
                Text("Balanced · Moderate risk").font(.system(size: 12)).foregroundStyle(Self.mute)
            }
            GeometryReader { g in
                HStack(spacing: 3) {
                    ForEach(0..<parts.count, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3).fill(Color(hex: parts[i].2))
                            .frame(width: max(0, (g.size.width - 9) * parts[i].1 * (demo.appeared ? 1 : 0.02)))
                    }
                }
                .animation(.spring(response: 1.1, dampingFraction: 0.9).delay(0.7), value: demo.appeared)
            }
            .frame(height: 8)
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                ForEach(0..<2, id: \.self) { row in
                    GridRow {
                        ForEach(0..<2, id: \.self) { col in
                            let p = parts[row * 2 + col]
                            HStack(spacing: 8) {
                                Circle().fill(Color(hex: p.2)).frame(width: 7, height: 7)
                                Text(p.0).font(.system(size: 13)).foregroundStyle(Self.ivory.opacity(0.85))
                                Spacer(minLength: 4)
                                Text("\(Int(p.1 * 100))%").font(.system(size: 13, design: .serif)).foregroundStyle(Self.mute)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.035)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Self.hair, lineWidth: 0.8))
    }

    private var accounts: some View {
        let rows: [(String, String, String, Double, Double)] = [
            ("chart.line.uptrend.xyaxis", "Brokerage", "···· 4021", 162_410.40, 3.1),
            ("building.columns", "Savings", "···· 7730", 58_120.12, 0.6),
            ("diamond", "Private Equity", "Fund III", 28_400.00, 5.0),
        ]
        return VStack(spacing: 0) {
            ForEach(0..<rows.count, id: \.self) { i in
                let a = rows[i]
                HStack(spacing: 14) {
                    Image(systemName: a.0).font(.system(size: 15, weight: .light)).foregroundStyle(Self.gold)
                        .frame(width: 40, height: 40)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.05)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.1).font(.system(size: 15, weight: .medium)).foregroundStyle(Self.ivory)
                        Text(a.2).font(.system(size: 12)).foregroundStyle(Self.mute)
                    }
                    Spacer()
                    Sparkline(data: wave(14, seed: a.4, from: 0, to: 1, vol: 0.25), color: Self.sage.opacity(0.8), width: 1.3)
                        .frame(width: 44, height: 18)
                    Text("$" + Fmt.num(a.3, 2)).font(.system(size: 16, design: .serif)).foregroundStyle(Self.ivory)
                        .frame(width: 104, alignment: .trailing)
                }
                .padding(.vertical, 11)
                .overlay(alignment: .bottom) {
                    if i < rows.count - 1 { Rectangle().fill(Self.hair).frame(height: 0.7).padding(.leading, 54) }
                }
            }
        }
    }
}

/// A dot that breathes, marking "now" on a chart.
struct Pulse: View {
    let color: Color
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.8) / 1.8
            ZStack {
                Circle().stroke(color.opacity(0.6 * (1 - t)), lineWidth: 1.2).frame(width: 10 + 22 * t, height: 10 + 22 * t)
                Circle().fill(color).frame(width: 8, height: 8)
            }
        }
        .frame(width: 34, height: 34)
    }
}
