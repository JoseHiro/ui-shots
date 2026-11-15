import SwiftUI

/// Bento: a warm food delivery app with rounded type and dish cards.
struct FoodApp: View {
    @Binding var selection: Int

    static let orange = Color(hex: 0xFF5A1F)
    static let ink = Color(hex: 0x2A1E17)
    static let muted = Color(hex: 0xB3A194)
    static let tabs = [
        TabItem(id: 0, title: "Home", icon: "house", iconOn: "house.fill", color: orange),
        TabItem(id: 1, title: "Search", icon: "magnifyingglass", iconOn: "magnifyingglass", color: orange),
        TabItem(id: 2, title: "Orders", icon: "bag", iconOn: "bag.fill", color: orange),
        TabItem(id: 3, title: "Profile", icon: "person", iconOn: "person.fill", color: orange),
    ]
    private let titles = ["What are you\ncraving today?", "Find your\nnext bite", "Your orders\nare on the way", "Hi Sam,\nhungry again?"]
    private let categories = [("All", "fork.knife"), ("Bowls", "leaf"), ("Sweets", "birthday.cake"), ("Coffee", "cup.and.saucer"), ("Veggie", "carrot")]
    private let dishes: [(String, String, String, UInt32, UInt32)] = [
        ("Salmon Poke", "fish", "$12.40", 0xFFB36B, 0xFF6B2C), ("Green Bowl", "leaf", "$9.80", 0x8EDB9A, 0x2E9E5B),
        ("Berry Cake", "birthday.cake", "$6.50", 0xFFA8B6, 0xFF5C7A), ("Flat White", "cup.and.saucer", "$4.20", 0xD9B48F, 0x8B5E3C),
        ("Carrot Soup", "carrot", "$7.90", 0xFFD166, 0xF4A261), ("Bento Box", "takeoutbag.and.cup.and.straw", "$14.00", 0x9AD0EC, 0x4A90C2),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: 0xFFF6EE).ignoresSafeArea()

            ScrollView(showsIndicators: false) { page }
                .scrollDisabled(true)
                .id(selection)
                .transition(.opacity.combined(with: .offset(y: 8)))
                .frame(maxHeight: .infinity, alignment: .top)

            BubbleNotch(selection: $selection, tabs: Self.tabs, bar: .white,
                        bubble: gradient(0xFF8A4C, 0xFF4E12), glow: Self.orange,
                        active: Self.orange, muted: Self.muted)
        }
        .animation(.easeInOut(duration: 0.28), value: selection)
        .preferredColorScheme(.light)
        .fontDesign(.rounded)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deliver to").font(.system(size: 12, weight: .semibold)).foregroundStyle(Self.muted)
                    HStack(spacing: 4) {
                        Text("Home · 12 Elm St").font(.system(size: 15, weight: .bold))
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Self.ink)
                }
                Spacer()
                Image(systemName: "bell.badge")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Self.orange)
                    .frame(width: 42, height: 42)
                    .background(Self.orange.opacity(0.12), in: Circle())
            }

            Text(titles[selection])
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(Self.ink)
                .lineSpacing(-2)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(Self.muted)
                Text("Poke, ramen, cake…").foregroundStyle(Self.muted)
                Spacer()
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Self.orange, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .font(.system(size: 15, weight: .semibold))
            .padding(.leading, 16).padding(.trailing, 7).frame(height: 48)
            .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.offset) { i, c in
                    let on = i == selection
                    VStack(spacing: 6) {
                        Image(systemName: c.1)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(on ? .white : Self.orange)
                            .frame(width: 54, height: 54)
                            .background(on ? Self.orange : .white, in: Circle())
                        Text(c.0).font(.system(size: 12, weight: .bold)).foregroundStyle(Self.ink)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text("Popular near you").font(.system(size: 19, weight: .heavy)).foregroundStyle(Self.ink)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(0..<6, id: \.self) { i in
                    let d = dishes[(i + selection) % dishes.count]
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(gradient(d.3, d.4))
                            .frame(height: 92)
                            .overlay(Image(systemName: d.1).font(.system(size: 34, weight: .semibold)).foregroundStyle(.white))
                            .overlay(alignment: .topTrailing) {
                                Text("20 min").font(.system(size: 10, weight: .bold)).foregroundStyle(Self.ink)
                                    .padding(.horizontal, 7).padding(.vertical, 4)
                                    .background(.white, in: Capsule()).padding(8)
                            }
                        Text(d.0).font(.system(size: 15, weight: .bold)).foregroundStyle(Self.ink)
                        HStack {
                            Text(d.2).font(.system(size: 15, weight: .heavy)).foregroundStyle(Self.orange)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Self.ink, in: Circle())
                        }
                    }
                    .padding(10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}
