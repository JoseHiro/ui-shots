import SwiftUI

/// Wave: a dark music app with neon album art and a mini player above a glass dock.
struct MusicApp: View {
    @Binding var selection: Int

    static let tabs = [
        TabItem(id: 0, title: "Home", icon: "house", iconOn: "house.fill", color: .white),
        TabItem(id: 1, title: "Explore", icon: "safari", iconOn: "safari.fill", color: .white),
        TabItem(id: 2, title: "Library", icon: "square.stack", iconOn: "square.stack.fill", color: .white),
        TabItem(id: 3, title: "Profile", icon: "person", iconOn: "person.fill", color: .white),
    ]
    private let titles = ["Good evening", "Explore", "Your Library", "Profile"]
    private let sections = ["Recently played", "New releases", "Playlists", "Top artists this month"]
    static let art: [(UInt32, UInt32, String)] = [
        (0xFF4D8D, 0xFF9F43, "waveform"), (0x7C3AED, 0x22D3EE, "music.note"), (0x10B981, 0x3B82F6, "headphones"),
        (0xF43F5E, 0x8B5CF6, "sparkles"), (0xF59E0B, 0xEF4444, "flame"), (0x06B6D4, 0x6366F1, "moon.stars"),
        (0xEC4899, 0x8B5CF6, "heart"), (0x22C55E, 0xEAB308, "sun.max"),
    ]
    private let albums = [("Neon Coast", "Mira Sol"), ("Afterglow", "The Lumen"), ("Deep Blue", "Kaito"),
                          ("Velvet", "Nova Ray"), ("Heatwave", "Sunny Ko"), ("Night Swim", "Ocean Fm"),
                          ("Sugar Rush", "Pip & Lu"), ("Golden", "Ari Vale")]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: 0x0A0A12).ignoresSafeArea()
            RadialGradient(colors: [Color(hex: 0x7C3AED, alpha: 0.45), .clear], center: .topLeading,
                           startRadius: 10, endRadius: 460)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) { page }
                .scrollDisabled(true)
                .id(selection)
                .transition(.opacity)
                .frame(maxHeight: .infinity, alignment: .top)

            VStack(spacing: 12) {
                MiniPlayer()
                LiquidDock(selection: $selection, tabs: Self.tabs,
                           highlight: gradient(0xFF4D8D, 0xFF9F43), glow: Color(hex: 0xFF4D8D),
                           inactive: .white.opacity(0.55), onHighlight: .white)
                    .environment(\.colorScheme, .dark)
            }
            .padding(.bottom, 4)
        }
        .animation(.easeInOut(duration: 0.3), value: selection)
        .preferredColorScheme(.dark)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(titles[selection])
                    .font(.system(size: 30, weight: .heavy))
                Spacer()
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .foregroundStyle(.white)

            let hero = Self.art[(selection * 3) % Self.art.count]
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(gradient(hero.0, hero.1))
                .frame(height: 160)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: hero.2)
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(20)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DAILY MIX").font(.system(size: 11, weight: .heavy)).kerning(1.5).opacity(0.8)
                        Text("Late Night Drive").font(.system(size: 24, weight: .heavy))
                        Text("Synthwave · 42 songs").font(.system(size: 13, weight: .medium)).opacity(0.8)
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                }

            Text(sections[selection])
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    let k = (i + selection * 2) % albums.count
                    let a = Self.art[k]
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(gradient(a.0, a.1))
                            .aspectRatio(1.25, contentMode: .fit)
                            .overlay(Image(systemName: a.2)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85)))
                        Text(albums[k].0).font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        Text(albums[k].1).font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

private struct MiniPlayer: View {
    @State private var progress: CGFloat = 0.28

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(gradient(0xFF4D8D, 0xFF9F43))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: "waveform").font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text("Midnight Drive").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                Text("Neon Coast").font(.system(size: 13)).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "backward.fill").foregroundStyle(.white.opacity(0.7))
            Image(systemName: "pause.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 38, height: 38)
                .background(.white, in: Circle())
            Image(systemName: "forward.fill").foregroundStyle(.white.opacity(0.7))
        }
        .padding(10)
        .padding(.trailing, 6)
        .background(Color(hex: 0x1B1A2B).opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .bottom) {
            GeometryReader { g in
                Capsule().fill(.white.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule().fill(gradient(0xFF4D8D, 0xFF9F43)).frame(width: g.size.width * progress)
                    }
            }
            .frame(height: 3)
            .padding(.horizontal, 16)
            .padding(.bottom, 3)
        }
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(.white.opacity(0.08)))
        .padding(.horizontal, 16)
        .onAppear { withAnimation(.linear(duration: 30)) { progress = 0.9 } }
    }
}
