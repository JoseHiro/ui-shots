import SwiftUI

/// A ticket stub: paper, a perforated edge with side cut-outs, a plane that
/// flies along the perforation, and a postal stamp ring that draws itself
/// around the chosen tab.
struct BoardingPass: View {
    @Binding var selection: Int
    let tabs: [TabItem]

    static let paper = Color(hex: 0xFBF8F1)
    static let ink = Color(hex: 0x1C2B4A)
    static let stamp = Color(hex: 0xD9442B)

    @State private var ring: CGFloat = 1
    @State private var heading: CGFloat = 1
    private let perfY: CGFloat = 14

    var body: some View {
        GeometryReader { g in
            let cw = g.size.width / CGFloat(tabs.count)
            let cx = cw * (CGFloat(selection) + 0.5)
            ZStack(alignment: .topLeading) {
                TicketShape(perfY: perfY)
                    .fill(Self.paper)
                    .shadow(color: Self.ink.opacity(0.14), radius: 16, y: -4)
                    .ignoresSafeArea(edges: .bottom)

                Path { p in
                    p.move(to: CGPoint(x: 18, y: perfY))
                    p.addLine(to: CGPoint(x: g.size.width - 18, y: perfY))
                }
                .stroke(Self.ink.opacity(0.28), style: StrokeStyle(lineWidth: 1.4, dash: [4, 5]))

                Image(systemName: "airplane")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Self.stamp)
                    .scaleEffect(x: heading, y: 1)
                    .padding(5)
                    .background(Self.paper, in: Circle())
                    .position(x: cx, y: perfY)

                HStack(spacing: 0) {
                    ForEach(tabs) { t in
                        let on = selection == t.id
                        Button { selection = t.id } label: {
                            VStack(spacing: 5) {
                                ZStack {
                                    Circle()
                                        .trim(from: 0, to: on ? ring : 0)
                                        .stroke(Self.stamp, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                                        .rotationEffect(.degrees(-90))
                                    Circle()
                                        .trim(from: 0, to: on ? ring : 0)
                                        .stroke(Self.stamp.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                                        .padding(4)
                                        .rotationEffect(.degrees(90))
                                    Image(systemName: t.symbol(on))
                                        .font(.system(size: 18, weight: on ? .semibold : .regular))
                                        .foregroundStyle(on ? Self.stamp : Self.ink.opacity(0.75))
                                }
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(on ? -10 : 0))
                                Text(t.title.uppercased())
                                    .font(.system(size: 9.5, weight: .semibold, design: .serif))
                                    .kerning(1.6)
                                    .foregroundStyle(on ? Self.stamp : Self.ink.opacity(0.6))
                            }
                            .frame(width: cw, height: 66)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .tabFrame(t.id)
                    }
                }
                .padding(.top, 24)
            }
            .animation(.spring(response: 0.62, dampingFraction: 0.82), value: selection)
        }
        .frame(height: 92)
        .onChange(of: selection) { old, new in
            heading = new > old ? 1 : -1
            ring = 0
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { ring = 1 }
        }
    }
}

struct TicketShape: Shape {
    let perfY: CGFloat

    func path(in r: CGRect) -> Path {
        let notch: CGFloat = 10
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: r.width, y: 0))
        p.addLine(to: CGPoint(x: r.width, y: perfY - notch))
        p.addArc(center: CGPoint(x: r.width, y: perfY), radius: notch,
                 startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
        p.addLine(to: CGPoint(x: r.width, y: r.height))
        p.addLine(to: CGPoint(x: 0, y: r.height))
        p.addLine(to: CGPoint(x: 0, y: perfY + notch))
        p.addArc(center: CGPoint(x: 0, y: perfY), radius: notch,
                 startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)
        p.closeSubpath()
        return p
    }
}
