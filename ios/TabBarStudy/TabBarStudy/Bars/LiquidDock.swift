import SwiftUI

/// Floating dark-glass capsule with a specular rim. The highlight's two edges
/// move on different springs, so it stretches toward the new tab and snaps
/// back like a drop of liquid.
struct LiquidDock: View {
    @Binding var selection: Int
    let tabs: [TabItem]
    let highlight: LinearGradient
    let glow: Color

    @State private var lead: CGFloat = 0
    @State private var trail: CGFloat = 0
    private let itemW: CGFloat = 70
    private let itemH: CGFloat = 54
    private let pad: CGFloat = 7

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { t in
                let on = selection == t.id
                Button { selection = t.id } label: {
                    Image(systemName: t.symbol(on))
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(on ? .white : .white.opacity(0.5))
                        .contentTransition(.symbolEffect(.replace))
                        .scaleEffect(on ? 1.08 : 1)
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
                .overlay(Capsule().fill(LinearGradient(colors: [.white.opacity(0.45), .clear],
                                                       startPoint: .top, endPoint: .center)))
                .frame(width: trail - lead + itemW, height: itemH)
                .shadow(color: glow.opacity(0.75), radius: 16, y: 4)
                .offset(x: pad + lead)
        }
        .background(.ultraThinMaterial, in: Capsule())
        .background(Capsule().fill(Color.white.opacity(0.04)))
        .overlay(
            Capsule().strokeBorder(
                LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05), .white.opacity(0.18)],
                               startPoint: .top, endPoint: .bottom),
                lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.5), radius: 30, y: 16)
        .environment(\.colorScheme, .dark)
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
