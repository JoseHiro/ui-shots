import SwiftUI

/// Bento: a loud, neo-brutalist food app. Thick outlines, flat offset shadows,
/// sticker price tags and a notch bar that matches.
struct FoodApp: View {
    @Binding var selection: Int

    static let butter = Color(hex: 0xFFF0CF)
    static let tomato = Color(hex: 0xFF5533)
    static let yellow = Color(hex: 0xFFD23F)
    static let mint = Color(hex: 0x3DDC97)
    static let blue = Color(hex: 0x6C8CFF)
    static let tabs = [
        TabItem(id: 0, title: "Home", icon: "house", iconOn: "house.fill", color: tomato),
        TabItem(id: 1, title: "Search", icon: "magnifyingglass", iconOn: "magnifyingglass", color: yellow),
        TabItem(id: 2, title: "Orders", icon: "bag", iconOn: "bag.fill", color: mint),
        TabItem(id: 3, title: "Me", icon: "person", iconOn: "person.fill", color: blue),
    ]
    private let headlines = [("HUNGRY?", "LET'S EAT."), ("FIND", "YOUR FIX."), ("ON ITS", "WAY! 12 MIN"), ("HEY SAM,", "SNACK TIME?")]
    private let dishes: [(String, String, String, Color)] = [
        ("SALMON POKE", "fish.fill", "$12", Color(hex: 0xFF8A65)), ("GREEN BOWL", "leaf.fill", "$9", Color(hex: 0x3DDC97)),
        ("BERRY CAKE", "birthday.cake.fill", "$6", Color(hex: 0xFF8FB8)), ("FLAT WHITE", "cup.and.saucer.fill", "$4", Color(hex: 0xC9A27E)),
        ("CARROT SOUP", "carrot.fill", "$7", Color(hex: 0xFFD23F)), ("BENTO BOX", "takeoutbag.and.cup.and.straw.fill", "$14", Color(hex: 0x6C8CFF)),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Self.butter.ignoresSafeArea()

            ScrollView(showsIndicators: false) { page }
                .scrollDisabled(true)
                .id(selection)
                .transition(.asymmetric(insertion: .offset(y: 30).combined(with: .opacity), removal: .opacity))

            BrutalNotch(selection: $selection, tabs: Self.tabs)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selection)
        .preferredColorScheme(.light)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("BENTO")
                    .font(.system(size: 18, weight: .black))
                    .kerning(2)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Self.yellow)
                    .overlay(Rectangle().stroke(.black, lineWidth: 2.5))
                    .hardShadow(Rectangle(), x: 3, y: 3)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(.white, in: Circle())
                        .overlay(Circle().stroke(.black, lineWidth: 2.5))
                        .hardShadow(Circle(), x: 3, y: 3)
                    Text("3").font(.system(size: 11, weight: .black)).foregroundStyle(.white)
                        .frame(width: 20, height: 20).background(Self.tomato, in: Circle())
                        .overlay(Circle().stroke(.black, lineWidth: 2)).offset(x: 5, y: -5)
                }
            }
            .foregroundStyle(.black)

            VStack(alignment: .leading, spacing: -6) {
                Text(headlines[selection].0)
                Text(headlines[selection].1).foregroundStyle(Self.tabs[selection].color)
                    .shadow(color: .black, radius: 0, x: 2.5, y: 2.5)
            }
            .font(.system(size: 46, weight: .black).width(.condensed))
            .foregroundStyle(.black)

            HStack(spacing: 10) {
                ForEach(Array(["ALL", "BOWLS", "SWEET", "COFFEE"].enumerated()), id: \.offset) { i, c in
                    let on = i == selection
                    Text(c)
                        .font(.system(size: 12, weight: .black))
                        .kerning(1)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(on ? Self.tabs[selection].color : .white, in: Capsule())
                        .overlay(Capsule().stroke(.black, lineWidth: 2.5))
                        .hardShadow(Capsule(), x: on ? 3 : 0, y: on ? 3 : 0)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)], spacing: 20) {
                ForEach(0..<6, id: \.self) { i in
                    dish(dishes[(i + selection) % dishes.count], tilt: i.isMultiple(of: 2) ? -7 : 6)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.trailing, 4)
    }

    private func dish(_ d: (String, String, String, Color), tilt: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(d.3)
                .frame(height: 96)
                .overlay(Image(systemName: d.1).font(.system(size: 38, weight: .bold)).foregroundStyle(.black))
                .overlay(Rectangle().stroke(.black, lineWidth: 2.5))
            HStack(alignment: .center) {
                Text(d.0).font(.system(size: 14, weight: .black)).foregroundStyle(.black)
                Spacer()
                Image(systemName: "plus").font(.system(size: 12, weight: .black)).foregroundStyle(.white)
                    .frame(width: 26, height: 26).background(.black, in: Circle())
            }
        }
        .padding(10)
        .background(.white)
        .overlay(Rectangle().stroke(.black, lineWidth: 2.5))
        .hardShadow(Rectangle(), x: 5, y: 5)
        .overlay(alignment: .topTrailing) {
            Text(d.2)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.black)
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(Self.yellow)
                .overlay(Rectangle().stroke(.black, lineWidth: 2))
                .rotationEffect(.degrees(tilt))
                .offset(x: 8, y: -8)
        }
    }
}
