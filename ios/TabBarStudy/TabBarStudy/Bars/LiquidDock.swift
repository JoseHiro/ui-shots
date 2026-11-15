import SwiftUI

/// Floating glass capsule. The highlight's two edges move on different springs,
/// so it stretches toward the new tab and snaps back like a drop of liquid.
struct LiquidDock: View {
    @Binding var selection: Int
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
                    Image(systemName: symbol(t, filled: on))
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(on ? .white : Theme.ink.opacity(0.45))
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
                .fill(LinearGradient(colors: [Theme.lavender, Theme.lavenderDeep],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: trail - lead + itemW, height: itemH)
                .shadow(color: Theme.lavender.opacity(0.5), radius: 10, y: 4)
                .offset(x: pad + lead)
        }
        .background(.ultraThinMaterial, in: Capsule())
        .background(Capsule().fill(.white.opacity(0.6)))
        .overlay(Capsule().stroke(.white, lineWidth: 1))
        .shadow(color: Theme.lavenderDeep.opacity(0.2), radius: 24, y: 12)
        .padding(.bottom, 4)
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
