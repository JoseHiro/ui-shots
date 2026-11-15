import SwiftUI

/// Neo-brutalist bar: black outlines, a notch that follows a bubble, and a
/// hard offset shadow. Each tab paints the bubble in its own color.
struct BrutalNotch: View {
    @Binding var selection: Int
    let tabs: [TabItem]
    private let barH: CGFloat = 72

    var body: some View {
        GeometryReader { g in
            let cw = g.size.width / CGFloat(tabs.count)
            let cx = cw * (CGFloat(selection) + 0.5)
            ZStack(alignment: .topLeading) {
                NotchShape(x: cx)
                    .fill(.white)
                    .overlay(NotchShape(x: cx).stroke(.black, lineWidth: 2.5))
                    .ignoresSafeArea(edges: .bottom)

                ZStack {
                    Circle().fill(.black).offset(x: 3, y: 4)
                    Circle()
                        .fill(tabs[selection].color)
                        .overlay(Circle().stroke(.black, lineWidth: 2.5))
                    Image(systemName: tabs[selection].symbol(true))
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.black)
                        .id(selection)
                        .transition(.asymmetric(insertion: .scale(scale: 0.1).combined(with: .opacity),
                                                removal: .opacity))
                }
                .frame(width: 58, height: 58)
                .rotationEffect(.degrees(selection.isMultiple(of: 2) ? -6 : 6))
                .position(x: cx, y: 0)

                HStack(spacing: 0) {
                    ForEach(tabs) { t in
                        let on = selection == t.id
                        Button { selection = t.id } label: {
                            VStack(spacing: 6) {
                                Image(systemName: t.symbol(false))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.black)
                                    .opacity(on ? 0 : 1)
                                    .scaleEffect(on ? 0.3 : 1)
                                Text(t.title.uppercased())
                                    .font(.system(size: 10, weight: .black))
                                    .kerning(1.2)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Rectangle().fill(on ? tabs[selection].color : .clear))
                                    .overlay(Rectangle().stroke(.black, lineWidth: on ? 1.5 : 0))
                                    .offset(y: on ? 8 : 0)
                            }
                            .frame(width: cw, height: barH - 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .tabFrame(t.id)
                    }
                }
                .padding(.top, 10)
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.58), value: selection)
        }
        .frame(height: barH)
    }
}

struct NotchShape: Shape {
    var x: CGFloat
    var animatableData: CGFloat {
        get { x }
        set { x = newValue }
    }

    func path(in r: CGRect) -> Path {
        let depth: CGFloat = 38, half: CGFloat = 44, corner: CGFloat = 22
        var p = Path()
        p.move(to: CGPoint(x: 0, y: corner))
        p.addQuadCurve(to: CGPoint(x: corner, y: 0), control: .zero)
        p.addLine(to: CGPoint(x: x - half - 16, y: 0))
        p.addCurve(to: CGPoint(x: x, y: depth),
                   control1: CGPoint(x: x - half + 8, y: 0),
                   control2: CGPoint(x: x - half + 2, y: depth))
        p.addCurve(to: CGPoint(x: x + half + 16, y: 0),
                   control1: CGPoint(x: x + half - 2, y: depth),
                   control2: CGPoint(x: x + half - 8, y: 0))
        p.addLine(to: CGPoint(x: r.width - corner, y: 0))
        p.addQuadCurve(to: CGPoint(x: r.width, y: corner), control: CGPoint(x: r.width, y: 0))
        p.addLine(to: CGPoint(x: r.width, y: r.height))
        p.addLine(to: CGPoint(x: 0, y: r.height))
        p.closeSubpath()
        return p
    }
}
