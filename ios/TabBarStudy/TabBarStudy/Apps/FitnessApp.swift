import SwiftUI

/// Pulse: an athletic tracker in black, white and volt, with wide numerals.
struct FitnessApp: View {
    @Binding var selection: Int

    static let paper = Color(hex: 0xEDEEE8)
    static let ink = Color(hex: 0x0B0B0C)
    static let volt = VoltTrack.volt
    static let tabs = [
        TabItem(id: 0, title: "Today", icon: "bolt", iconOn: "bolt.fill", color: volt),
        TabItem(id: 1, title: "Train", icon: "figure.run", iconOn: "figure.run", color: volt),
        TabItem(id: 2, title: "Stats", icon: "chart.bar", iconOn: "chart.bar.fill", color: volt),
        TabItem(id: 3, title: "You", icon: "person", iconOn: "person.fill", color: volt),
    ]
    private let hero: [(String, String, String, CGFloat)] = [
        ("8,432", "STEPS", "84% OF DAILY GOAL", 0.84), ("5.2", "KM RUN", "PACE 5'23\" / KM", 0.62),
        ("612", "KCAL", "+12% VS LAST WEEK", 0.76), ("28", "DAY STREAK", "PERSONAL BEST", 0.93),
    ]
    private let weeks: [[CGFloat]] = [[0.5, 0.8, 0.4, 0.9, 0.7, 1.0, 0.6], [0.7, 0.4, 0.9, 0.6, 1.0, 0.5, 0.8],
                                      [0.9, 0.6, 0.7, 0.4, 0.8, 0.7, 1.0], [0.4, 0.7, 0.6, 1.0, 0.5, 0.9, 0.7]]
    private let sessions = [("figure.run", "TEMPO RUN", "06:30 · 5.2 KM"), ("figure.strengthtraining.traditional", "UPPER BODY", "12:00 · 45 MIN"),
                            ("figure.yoga", "MOBILITY", "19:00 · 20 MIN"), ("bicycle", "RIDE", "SAT · 14.8 KM")]

    var body: some View {
        ZStack(alignment: .bottom) {
            Self.paper.ignoresSafeArea()

            ScrollView(showsIndicators: false) { page }
                .scrollDisabled(true)

            VoltTrack(selection: $selection, tabs: Self.tabs)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: selection)
        .preferredColorScheme(.light)
    }

    private var page: some View {
        let h = hero[selection]
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("PULSE").font(.system(size: 13, weight: .black).width(.expanded)).kerning(2)
                Spacer()
                Text("SAT 15 NOV").font(.system(size: 11, weight: .bold).width(.expanded)).foregroundStyle(.black.opacity(0.5))
            }
            .foregroundStyle(Self.ink)

            Text(Self.tabs[selection].title.uppercased())
                .font(.system(size: 46, weight: .black).width(.expanded))
                .foregroundStyle(Self.ink)
                .contentTransition(.numericText())

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(h.0)
                        .font(.system(size: 62, weight: .black).width(.expanded))
                        .foregroundStyle(Self.volt)
                        .contentTransition(.numericText())
                    Text(h.1).font(.system(size: 13, weight: .heavy).width(.expanded)).foregroundStyle(.white)
                }
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.12))
                        Capsule().fill(Self.volt).frame(width: g.size.width * h.3)
                    }
                }
                .frame(height: 10)
                Text(h.2).font(.system(size: 11, weight: .bold).width(.expanded)).foregroundStyle(.white.opacity(0.55))
            }
            .padding(20)
            .background(Self.ink, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            HStack(spacing: 12) {
                stat("72", "BPM", "heart.fill")
                stat("7:20", "SLEEP", "moon.fill")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("THIS WEEK").font(.system(size: 12, weight: .heavy).width(.expanded)).foregroundStyle(Self.ink)
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(0..<7, id: \.self) { d in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(d == 5 ? Self.volt : Self.ink)
                                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Self.ink, lineWidth: d == 5 ? 2 : 0))
                                .frame(height: 70 * weeks[selection][d])
                            Text(["M", "T", "W", "T", "F", "S", "S"][d])
                                .font(.system(size: 10, weight: .heavy).width(.expanded)).foregroundStyle(.black.opacity(0.45))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 90, alignment: .bottom)
            }
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    let s = sessions[(i + selection) % sessions.count]
                    HStack(spacing: 14) {
                        Image(systemName: s.0).font(.system(size: 18, weight: .bold)).foregroundStyle(Self.ink)
                            .frame(width: 46, height: 46).background(Self.volt, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.1).font(.system(size: 14, weight: .heavy).width(.expanded)).foregroundStyle(Self.ink)
                            Text(s.2).font(.system(size: 11, weight: .semibold).width(.expanded)).foregroundStyle(.black.opacity(0.5))
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .bold)).foregroundStyle(Self.ink)
                    }
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func stat(_ value: String, _ label: String, _ icon: String) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 26, weight: .black).width(.expanded)).foregroundStyle(Self.ink)
                Text(label).font(.system(size: 10, weight: .heavy).width(.expanded)).foregroundStyle(.black.opacity(0.45))
            }
            Spacer()
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(Self.ink)
                .frame(width: 36, height: 36).background(Self.volt, in: Circle())
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
