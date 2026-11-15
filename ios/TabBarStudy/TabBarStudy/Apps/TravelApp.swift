import SwiftUI

/// Roam: an airy travel app with serif headlines and sunset destination cards.
struct TravelApp: View {
    @Binding var selection: Int

    static let ink = Color(hex: 0x0F172A)
    static let muted = Color(hex: 0x94A3B8)
    static let tabs = [
        TabItem(id: 0, title: "Explore", icon: "safari", iconOn: "safari.fill", color: Color(hex: 0x0EA5E9)),
        TabItem(id: 1, title: "Trips", icon: "airplane", iconOn: "airplane", color: Color(hex: 0xF59E0B)),
        TabItem(id: 2, title: "Saved", icon: "heart", iconOn: "heart.fill", color: Color(hex: 0xEC4899)),
        TabItem(id: 3, title: "Profile", icon: "person", iconOn: "person.fill", color: Color(hex: 0x10B981)),
    ]
    private let titles = ["Where to\nnext?", "Your upcoming\ntrips", "Places you\nloved", "Hello,\nAlex"]
    private let places: [(String, String, String, UInt32, UInt32, String)] = [
        ("Kyoto", "Japan", "4.9", 0xFF9A8B, 0xFF6A88, "building.columns"),
        ("Lisbon", "Portugal", "4.8", 0xFDC830, 0xF37335, "tram.fill"),
        ("Reykjavík", "Iceland", "4.9", 0x667EEA, 0x64B6FF, "mountain.2.fill"),
        ("Santorini", "Greece", "4.7", 0x56CCF2, 0x2F80ED, "sailboat.fill"),
        ("Marrakech", "Morocco", "4.8", 0xF7971E, 0xC0392B, "sun.haze.fill"),
    ]

    var body: some View {
        let tint = Self.tabs[selection].color
        ZStack(alignment: .bottom) {
            Color(hex: 0xF7F9FC).ignoresSafeArea()
            LinearGradient(colors: [tint.opacity(0.22), Color(hex: 0xF7F9FC).opacity(0)], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) { page }
                .scrollDisabled(true)
                .id(selection)
                .transition(.opacity.combined(with: .offset(x: 12)))
                .frame(maxHeight: .infinity, alignment: .top)

            ColorChips(selection: $selection, tabs: Self.tabs, bar: .white, muted: Self.muted)
        }
        .animation(.easeInOut(duration: 0.3), value: selection)
        .preferredColorScheme(.light)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                Text(titles[selection])
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(Self.ink)
                Spacer()
                Circle()
                    .fill(gradient(0xFDBA74, 0xF472B6))
                    .frame(width: 44, height: 44)
                    .overlay(Text("A").font(.system(size: 18, weight: .bold, design: .serif)).foregroundStyle(.white))
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                Text("Search destinations")
                Spacer()
                Image(systemName: "calendar")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Self.muted)
            .padding(.horizontal, 16).frame(height: 50)
            .background(.white, in: Capsule())
            .shadow(color: Self.ink.opacity(0.05), radius: 10, y: 4)

            HStack {
                Text("Popular").font(.system(size: 20, weight: .semibold, design: .serif)).foregroundStyle(Self.ink)
                Spacer()
                Text("See all").font(.system(size: 14, weight: .semibold)).foregroundStyle(Self.tabs[selection].color)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        destination(places[(i + selection) % places.count])
                    }
                }
            }
            .scrollDisabled(true)
            .scrollClipDisabled()

            Text("Nearby stays").font(.system(size: 20, weight: .semibold, design: .serif)).foregroundStyle(Self.ink)

            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { i in
                    let p = places[(i + selection + 2) % places.count]
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(gradient(p.3, p.4))
                            .frame(width: 64, height: 64)
                            .overlay(Image(systemName: p.5).foregroundStyle(.white))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Casa \(p.0)").font(.system(size: 16, weight: .semibold, design: .serif)).foregroundStyle(Self.ink)
                            Text("2 nights · $\(180 + i * 45)").font(.system(size: 13, weight: .medium)).foregroundStyle(Self.muted)
                        }
                        Spacer()
                        Image(systemName: "heart").foregroundStyle(Self.muted)
                    }
                    .padding(10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func destination(_ p: (String, String, String, UInt32, UInt32, String)) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(gradient(p.3, p.4))
            .frame(width: 210, height: 250)
            .overlay(alignment: .topTrailing) {
                Image(systemName: p.5)
                    .font(.system(size: 58))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(18)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(p.0).font(.system(size: 26, weight: .semibold, design: .serif))
                    HStack(spacing: 6) {
                        Text(p.1)
                        Text("·")
                        Image(systemName: "star.fill").font(.system(size: 11))
                        Text(p.2)
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(0.9)
                }
                .foregroundStyle(.white)
                .padding(18)
            }
    }
}
