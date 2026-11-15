import SwiftUI

/// Wave: a dark music app lit by blurred album colors, with a spinning vinyl
/// in the mini player and a liquid-glass dock.
struct MusicApp: View {
    @Binding var selection: Int

    static let tabs = [
        TabItem(id: 0, title: "Home", icon: "house", iconOn: "house.fill", color: .white),
        TabItem(id: 1, title: "Explore", icon: "safari", iconOn: "safari.fill", color: .white),
        TabItem(id: 2, title: "Library", icon: "square.stack", iconOn: "square.stack.fill", color: .white),
        TabItem(id: 3, title: "Profile", icon: "person", iconOn: "person.fill", color: .white),
    ]
    /// Album palettes; the screen's ambient light follows the one for the current tab.
    static let palettes: [(UInt32, UInt32, UInt32)] = [
        (0xFF3D7F, 0xFF9F43, 0x7C3AED), (0x22D3EE, 0x7C3AED, 0x3B82F6),
        (0x34D399, 0x3B82F6, 0xA3E635), (0xF472B6, 0xF59E0B, 0xEF4444),
    ]
    private let titles = ["Good evening", "Explore", "Library", "Profile"]
    private let covers: [(String, String, UInt32, UInt32)] = [
        ("Neon Coast", "Mira Sol", 0xFF3D7F, 0xFF9F43), ("Afterglow", "The Lumen", 0x7C3AED, 0x22D3EE),
        ("Deep Blue", "Kaito", 0x0EA5E9, 0x312E81), ("Velvet", "Nova Ray", 0xF43F5E, 0x7C3AED),
        ("Heatwave", "Sunny Ko", 0xF59E0B, 0xEF4444), ("Night Swim", "Ocean FM", 0x06B6D4, 0x4F46E5),
        ("Sugar", "Pip & Lu", 0xEC4899, 0xA855F7), ("Golden", "Ari Vale", 0xFACC15, 0xF97316),
    ]

    var body: some View {
        let pal = Self.palettes[selection]
        ZStack(alignment: .bottom) {
            Color(hex: 0x06060B).ignoresSafeArea()
            AmbientLight(colors: [Color(hex: pal.0), Color(hex: pal.1), Color(hex: pal.2)])
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) { page }
                .scrollDisabled(true)
                .id(selection)
                .transition(.opacity)

            LinearGradient(colors: [.clear, Color(hex: 0x06060B).opacity(0.85)], startPoint: .top, endPoint: .bottom)
                .frame(height: 220)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                MiniPlayer(colors: (pal.0, pal.1))
                LiquidDock(selection: $selection, tabs: Self.tabs,
                           highlight: gradient(pal.0, pal.1), glow: Color(hex: pal.0))
            }
            .padding(.bottom, 2)
        }
        .animation(.easeInOut(duration: 0.45), value: selection)
        .preferredColorScheme(.dark)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WAVE").font(.system(size: 12, weight: .heavy)).kerning(4).foregroundStyle(.white.opacity(0.5))
                    Text(titles[selection]).font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                }
                Spacer()
                Circle().fill(gradient(0xFDE68A, 0xF472B6)).frame(width: 40, height: 40)
                    .overlay(Text("M").font(.system(size: 16, weight: .bold)).foregroundStyle(.black.opacity(0.7)))
            }

            featured

            HStack {
                Text("Made for you").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                Spacer()
                Text("See all").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 18) {
                ForEach(0..<6, id: \.self) { i in
                    let c = covers[(i + selection * 2) % covers.count]
                    VStack(alignment: .leading, spacing: 8) {
                        Cover(a: c.2, b: c.3, seed: i + selection)
                            .aspectRatio(1, contentMode: .fit)
                        Text(c.0).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                        Text(c.1).font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private var featured: some View {
        let c = covers[(selection * 3) % covers.count]
        return HStack(spacing: 16) {
            Cover(a: c.2, b: c.3, seed: selection + 7)
                .frame(width: 112, height: 112)
            VStack(alignment: .leading, spacing: 6) {
                Text("ON REPEAT").font(.system(size: 10, weight: .heavy)).kerning(2).foregroundStyle(.white.opacity(0.55))
                Text(c.0).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                Text(c.1).font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
                HStack(alignment: .center, spacing: 3) {
                    ForEach(0..<18, id: \.self) { k in
                        Capsule().fill(.white.opacity(k < 7 ? 0.95 : 0.3))
                            .frame(width: 3, height: CGFloat([8, 14, 20, 12, 18, 6, 16, 22, 10, 14, 8, 18, 12, 20, 6, 14, 10, 16][k]))
                    }
                }
                .frame(height: 24)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white.opacity(0.1)))
    }
}

/// Three soft color fields drifting behind the content.
private struct AmbientLight: View {
    let colors: [Color]
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                Circle().fill(colors[0]).frame(width: 340).offset(x: -120 + sin(t * 0.5) * 30, y: -300 + cos(t * 0.4) * 20)
                Circle().fill(colors[1]).frame(width: 300).offset(x: 150 + cos(t * 0.45) * 30, y: -120 + sin(t * 0.35) * 30)
                Circle().fill(colors[2]).frame(width: 360).offset(x: -60 + sin(t * 0.3) * 40, y: 330 + cos(t * 0.5) * 20)
            }
            .blur(radius: 90)
            .opacity(0.55)
        }
    }
}

/// Generative album cover: gradient plus a few circles.
private struct Cover: View {
    let a: UInt32, b: UInt32, seed: Int
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(gradient(a, b))
            .overlay {
                GeometryReader { g in
                    let s = g.size.width
                    ZStack {
                        Circle().stroke(.white.opacity(0.35), lineWidth: 1.5)
                            .frame(width: s * 0.62).offset(x: s * (seed.isMultiple(of: 2) ? 0.18 : -0.15), y: s * 0.1)
                        Circle().fill(.white.opacity(0.18))
                            .frame(width: s * 0.34).offset(x: -s * 0.2, y: -s * 0.18)
                        Circle().fill(.black.opacity(0.18))
                            .frame(width: s * 0.5).offset(x: s * 0.28, y: s * 0.3)
                    }
                    .frame(width: s, height: g.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(hex: a).opacity(0.35), radius: 16, y: 8)
    }
}

private struct MiniPlayer: View {
    let colors: (UInt32, UInt32)
    @State private var spin = 0.0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: 0x111111))
                ForEach(0..<4, id: \.self) { k in
                    Circle().stroke(.white.opacity(0.08), lineWidth: 0.8).padding(CGFloat(4 + k * 3))
                }
                Circle().fill(gradient(colors.0, colors.1)).frame(width: 18, height: 18)
                Circle().fill(.black).frame(width: 4, height: 4)
            }
            .frame(width: 46, height: 46)
            .rotationEffect(.degrees(spin))
            VStack(alignment: .leading, spacing: 2) {
                Text("Midnight Drive").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                Text("Neon Coast  ·  2:14").font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
            Image(systemName: "heart.fill").foregroundStyle(Color(hex: colors.0))
            Image(systemName: "pause.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 40, height: 40)
                .background(.white, in: Circle())
        }
        .padding(8)
        .padding(.trailing, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .strokeBorder(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom)))
        .environment(\.colorScheme, .dark)
        .padding(.horizontal, 16)
        .onAppear { withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) { spin = 360 } }
    }
}
