import SwiftUI

/// Bar with a curved notch that slides under a floating bubble.
struct BubbleNotch: View {
    @Binding var selection: Int
    let tabs: [TabItem]
    let bar: Color
    let bubble: LinearGradient
    let glow: Color
    let active: Color
    let muted: Color
    private let barH: CGFloat = 70

    var body: some View {
        GeometryReader { g in
            let cw = g.size.width / CGFloat(tabs.count)
            let cx = cw * (CGFloat(selection) + 0.5)
            ZStack(alignment: .topLeading) {
                NotchShape(x: cx)
                    .fill(bar)
                    .shadow(color: glow.opacity(0.16), radius: 18, y: -2)
                    .ignoresSafeArea(edges: .bottom)

                Circle()
                    .fill(bubble)
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: tabs[selection].symbol(true))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .id(selection)
                            .transition(.asymmetric(insertion: .scale(scale: 0.2).combined(with: .opacity),
                                                    removal: .opacity))
                    }
                    .shadow(color: glow.opacity(0.5), radius: 12, y: 6)
                    .position(x: cx, y: 0)

                HStack(spacing: 0) {
                    ForEach(tabs) { t in
                        let on = selection == t.id
                        Button { selection = t.id } label: {
                            VStack(spacing: 5) {
                                Image(systemName: t.symbol(false))
                                    .font(.system(size: 21, weight: .medium))
                                    .foregroundStyle(muted)
                                    .opacity(on ? 0 : 1)
                                    .offset(y: on ? -18 : 0)
                                Text(t.title)
                                    .font(.system(size: 11, weight: on ? .bold : .semibold, design: .rounded))
                                    .foregroundStyle(on ? active : muted)
                                    .offset(y: on ? 6 : 0)
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
            .animation(.spring(response: 0.5, dampingFraction: 0.72), value: selection)
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
        let depth: CGFloat = 36, half: CGFloat = 44, corner: CGFloat = 26
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
