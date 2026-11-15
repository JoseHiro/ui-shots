import SwiftUI

/// Roam: a travel app built from travel paper. Boarding passes with airport
/// codes and barcodes, postcards with stamps, and a ticket-stub tab bar.
struct TravelApp: View {
    @Binding var selection: Int

    static let bg = Color(hex: 0xEFEBE2)
    static let paper = Color(hex: 0xFBF8F1)
    static let ink = BoardingPass.ink
    static let stamp = BoardingPass.stamp
    static let tabs = [
        TabItem(id: 0, title: "Explore", icon: "globe.europe.africa", iconOn: "globe.europe.africa.fill", color: stamp),
        TabItem(id: 1, title: "Trips", icon: "airplane.departure", iconOn: "airplane.departure", color: stamp),
        TabItem(id: 2, title: "Saved", icon: "bookmark", iconOn: "bookmark.fill", color: stamp),
        TabItem(id: 3, title: "Passport", icon: "person.text.rectangle", iconOn: "person.text.rectangle.fill", color: stamp),
    ]
    private let flights: [(String, String, String, String, String, String)] = [
        ("TYO", "Tokyo", "LIS", "Lisbon", "RM 204", "14A"), ("LIS", "Lisbon", "KEF", "Reykjavík", "RM 311", "03C"),
        ("KEF", "Reykjavík", "JTR", "Santorini", "RM 078", "22F"), ("JTR", "Santorini", "RAK", "Marrakech", "RM 145", "09B"),
    ]
    private let places: [(String, String, UInt32, UInt32, String)] = [
        ("Kyoto", "JAPAN", 0xE76F51, 0xF4A261, "building.columns.fill"), ("Lisbon", "PORTUGAL", 0x2A9D8F, 0xE9C46A, "tram.fill"),
        ("Reykjavík", "ICELAND", 0x264653, 0x8AB17D, "mountain.2.fill"), ("Santorini", "GREECE", 0x1D4E89, 0x7FB3D5, "sailboat.fill"),
        ("Marrakech", "MOROCCO", 0xB5403A, 0xF2A65A, "sun.haze.fill"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Self.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) { page }
                .scrollDisabled(true)
                .id(selection)
                .transition(.asymmetric(insertion: .offset(x: 24).combined(with: .opacity), removal: .opacity))

            BoardingPass(selection: $selection, tabs: Self.tabs)
        }
        .animation(.easeInOut(duration: 0.35), value: selection)
        .preferredColorScheme(.light)
    }

    private var page: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Roam").font(.system(size: 30, weight: .bold, design: .serif)).italic()
                Spacer()
                Text("BON VOYAGE, ALEX").font(.system(size: 10, weight: .semibold, design: .monospaced)).kerning(1)
                    .foregroundStyle(Self.ink.opacity(0.55))
            }
            .foregroundStyle(Self.ink)

            ticket(flights[selection])

            Text(["Postcards from", "Next up", "Saved for later", "Stamps collected"][selection])
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Self.ink)

            HStack(spacing: 14) {
                ForEach(0..<2, id: \.self) { i in
                    postcard(places[(i + selection) % places.count], tilt: i == 0 ? -2.5 : 2)
                }
            }

            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    let p = places[(i + selection + 2) % places.count]
                    HStack(spacing: 14) {
                        Text(String(format: "%02d", i + 1)).font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Self.stamp)
                        Text(p.0).font(.system(size: 18, weight: .semibold, design: .serif)).foregroundStyle(Self.ink)
                        Spacer()
                        Text(p.1).font(.system(size: 10, weight: .semibold, design: .monospaced)).kerning(1)
                            .foregroundStyle(Self.ink.opacity(0.5))
                    }
                    .padding(.vertical, 14)
                    .overlay(alignment: .bottom) { Rectangle().fill(Self.ink.opacity(0.12)).frame(height: 1) }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func ticket(_ f: (String, String, String, String, String, String)) -> some View {
        VStack(spacing: 0) {
            HStack {
                code(f.0, f.1, .leading)
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "airplane").font(.system(size: 16, weight: .semibold)).foregroundStyle(Self.stamp)
                    Text("11H 40M").font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(Self.ink.opacity(0.5))
                }
                Spacer()
                code(f.2, f.3, .trailing)
            }
            .padding(18)
            .frame(height: 96)

            Line().stroke(Self.ink.opacity(0.25), style: StrokeStyle(lineWidth: 1.2, dash: [4, 5])).frame(height: 16)
                .padding(.horizontal, 16)

            HStack(alignment: .center) {
                field("FLIGHT", f.4)
                field("GATE", "B12")
                field("SEAT", f.5)
                Spacer()
                Barcode().frame(width: 74, height: 30)
            }
            .padding(.horizontal, 18).padding(.vertical, 14)
        }
        .background(Self.paper)
        .clipShape(TicketCard(tearY: 104), style: FillStyle(eoFill: true))
        .shadow(color: Self.ink.opacity(0.08), radius: 12, y: 6)
    }

    private func code(_ c: String, _ city: String, _ a: HorizontalAlignment) -> some View {
        VStack(alignment: a, spacing: 2) {
            Text(c).font(.system(size: 38, weight: .bold, design: .serif)).foregroundStyle(Self.ink)
            Text(city.uppercased()).font(.system(size: 10, weight: .semibold, design: .monospaced)).kerning(1)
                .foregroundStyle(Self.ink.opacity(0.55))
        }
    }

    private func field(_ k: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(k).font(.system(size: 8.5, weight: .semibold, design: .monospaced)).kerning(1).foregroundStyle(Self.ink.opacity(0.45))
            Text(v).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(Self.ink)
        }
        .padding(.trailing, 16)
    }

    private func postcard(_ p: (String, String, UInt32, UInt32, String), tilt: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle()
                .fill(gradient(p.2, p.3))
                .frame(height: 118)
                .overlay(alignment: .bottomLeading) {
                    Image(systemName: p.4).font(.system(size: 40)).foregroundStyle(.white.opacity(0.4)).padding(10)
                }
                .overlay(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(.white, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                        .frame(width: 30, height: 36)
                        .overlay(Image(systemName: "seal.fill").font(.system(size: 13)).foregroundStyle(.white))
                        .padding(8)
                }
            Text(p.0).font(.system(size: 18, weight: .semibold, design: .serif)).italic().foregroundStyle(Self.ink)
            Text(p.1).font(.system(size: 9, weight: .semibold, design: .monospaced)).kerning(1.5).foregroundStyle(Self.ink.opacity(0.5))
        }
        .padding(8)
        .background(Self.paper)
        .shadow(color: Self.ink.opacity(0.12), radius: 8, y: 4)
        .rotationEffect(.degrees(tilt))
    }
}

private struct Line: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r.midY))
        p.addLine(to: CGPoint(x: r.width, y: r.midY))
        return p
    }
}

/// Card with semicircle bites on both sides at the tear line (use an even-odd fill).
private struct TicketCard: Shape {
    let tearY: CGFloat
    func path(in r: CGRect) -> Path {
        let n: CGFloat = 11
        var p = RoundedRectangle(cornerRadius: 18, style: .continuous).path(in: r)
        p.addEllipse(in: CGRect(x: -n, y: tearY - n, width: n * 2, height: n * 2))
        p.addEllipse(in: CGRect(x: r.width - n, y: tearY - n, width: n * 2, height: n * 2))
        return p
    }
}

private struct Barcode: View {
    private let widths: [CGFloat] = [2, 1, 3, 1, 1, 2, 1, 3, 2, 1, 1, 2, 3, 1, 2, 1, 1, 3, 1, 2, 2, 1]
    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(Array(widths.enumerated()), id: \.offset) { _, w in
                Rectangle().fill(BoardingPass.ink).frame(width: w)
            }
        }
    }
}
