import SwiftUI

/// Floating glass capsule. The highlight's two edges move on different springs,
/// so it stretches toward the new tab and snaps back like a drop of liquid.
struct LiquidDock: View {
    @Binding var selection: Int
    let tabs: [TabItem]
    let highlight: LinearGradient
    let glow: Color
    let inactive: Color
    let onHighlight: Color

    @State private var lead: CGFloat = 0
    @State private var trail: CGFloat = 0
    private let itemW: CGFloat = 70
    private let itemH: CGFloat = 52
    private let pad: CGFloat = 7

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { t in
                let on = selection == t.id
                Button { selection = t.id } label: {
                    Image(systemName: t.symbol(on))
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(on ? onHighlight : inactive)
                        .contentTransition(.symbolEffect(.replace))
                        .scaleEffect(on ? 1.06 : 1)
                        .frame(width: itemW, height: itemH)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .tabFrame(t.id)
            }
        }
        .animation(.easeOut(duration: 0.2), value: selection)
        .padding(pad)
        .background(alignment: .leading) {
            Capsule()
                .fill(highlight)
                .frame(width: trail - lead + itemW, height: itemH)
                .shadow(color: glow.opacity(0.6), radius: 14, y: 4)
                .offset(x: pad + lead)
        }
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        .onAppear {
            lead = x(selection)
            trail = lead
        }
        .onChange(of: selection) { old, new in
            let target = x(new)
            let right = new > old
            withAnimation(.spring(response: right ? 0.55 : 0.3, dampingFraction: 0.75)) { lead = target }
            withAnimation(.spring(response: right ? 0.3 : 0.55, dampingFraction: 0.75)) { trail = target }
        }
    }

    private func x(_ i: Int) -> CGFloat { CGFloat(i) * itemW }
}
