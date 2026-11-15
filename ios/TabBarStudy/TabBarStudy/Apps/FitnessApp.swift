import SwiftUI

/// Pulse: a clean fitness tracker with activity rings, stats and a weekly chart.
struct FitnessApp: View {
    @Binding var selection: Int

    static let ink = Color(hex: 0x0E1A16)
    static let muted = Color(hex: 0x95A39E)
    static let tabs = [
        TabItem(id: 0, title: "Today", icon: "flame", iconOn: "flame.fill", color: Color(hex: 0xFF5A3C)),
        TabItem(id: 1, title: "Workouts", icon: "figure.run", iconOn: "figure.run", color: Color(hex: 0x16A865)),
        TabItem(id: 2, title: "Stats", icon: "chart.bar", iconOn: "chart.bar.fill", color: Color(hex: 0x2F7BF6)),
        TabItem(id: 3, title: "Profile", icon: "person", iconOn: "person.fill", color: Color(hex: 0x8B5CF6)),
    ]
    private let workouts = [("figure.run", "Morning Run", "5.2 km · 28 min"), ("figure.strengthtraining.traditional", "Upper Body", "45 min · 310 kcal"),
                            ("figure.yoga", "Evening Yoga", "30 min · Calm"), ("bicycle", "City Ride", "14.8 km · 41 min")]
    private let weeks: [[CGFloat]] = [[0.5, 0.8, 0.4, 0.9, 0.7, 1.0, 0.6], [0.7, 0.4, 0.9, 0.6, 1.0, 0.5, 0.8],
                                      [0.9, 0.6, 0.7, 0.4, 0.8, 0.7, 1.0], [0.4, 0.7, 0.6, 1.0, 0.5, 0.9, 0.7]]

    var body: some View {
        let tint = Self.tabs[selection].color
        ZStack(alignment: .bottom) {
            Color(hex: 0xF4F6F5).ignoresSafeArea()

            ScrollView(showsIndicators: false) { page(tint: tint) }
                .scrollDisabled(true)
                .frame(maxHeight: .infinity, alignment: .top)

            SoftPill(selection: $selection, tabs: Self.tabs, bar: .white, muted: Self.muted)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selection)
        .preferredColorScheme(.light)
    }

    private func page(tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SATURDAY, NOV 15").font(.system(size: 12, weight: .bold)).kerning(1).foregroundStyle(Self.muted)
                Text(Self.tabs[selection].title)
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(Self.ink)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 20) {
                ZStack {
                    ring(0.86 - CGFloat(selection) * 0.06, Color(hex: 0xFF5A3C), 110)
                    ring(0.72 + CGFloat(selection) * 0.05, Color(hex: 0x16A865), 82)
                    ring(0.6 + CGFloat(selection % 2) * 0.25, Color(hex: 0x2F7BF6), 54)
                }
                .frame(width: 120, height: 120)
                VStack(alignment: .leading, spacing: 10) {
                    metric("Move", "512", "/600 kcal", Color(hex: 0xFF5A3C))
                    metric("Exercise", "38", "/45 min", Color(hex: 0x16A865))
                    metric("Stand", "10", "/12 h", Color(hex: 0x2F7BF6))
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            HStack(spacing: 12) {
                tile("shoeprints.fill", "8,432", "steps")
                tile("heart.fill", "72", "bpm")
                tile("bed.double.fill", "7h 20", "sleep")
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("This week").font(.system(size: 17, weight: .bold)).foregroundStyle(Self.ink)
                    Spacer()
                    Text("+12%").font(.system(size: 13, weight: .heavy)).foregroundStyle(tint)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(tint.opacity(0.12), in: Capsule())
                }
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(0..<7, id: \.self) { d in
                        VStack(spacing: 6) {
                            Capsule()
                                .fill(d == 5 ? tint : tint.opacity(0.25))
                                .frame(height: 80 * weeks[selection][d])
                            Text(["M", "T", "W", "T", "F", "S", "S"][d])
                                .font(.system(size: 11, weight: .bold)).foregroundStyle(Self.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100, alignment: .bottom)
            }
            .padding(18)
            .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))

            VStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { i in
                    let w = workouts[(i + selection) % workouts.count]
                    HStack(spacing: 14) {
                        Image(systemName: w.0)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(tint)
                            .frame(width: 44, height: 44)
                            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(w.1).font(.system(size: 15, weight: .bold)).foregroundStyle(Self.ink)
                            Text(w.2).font(.system(size: 13, weight: .medium)).foregroundStyle(Self.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Self.muted)
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 6)
            .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func ring(_ v: CGFloat, _ c: Color, _ size: CGFloat) -> some View {
        ZStack {
            Circle().stroke(c.opacity(0.15), lineWidth: 11)
            Circle().trim(from: 0, to: v).stroke(c, style: StrokeStyle(lineWidth: 11, lineCap: .round)).rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }

    private func metric(_ label: String, _ value: String, _ unit: String, _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Self.muted)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value).font(.system(size: 20, weight: .heavy)).foregroundStyle(c)
                Text(unit).font(.system(size: 12, weight: .semibold)).foregroundStyle(Self.muted)
            }
        }
    }

    private func tile(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(Self.tabs[selection].color)
            Text(value).font(.system(size: 19, weight: .heavy)).foregroundStyle(Self.ink)
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Self.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
