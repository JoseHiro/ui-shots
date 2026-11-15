import SwiftUI

/// Floating bar where every tab has its own color. The selected tab
/// opens into a tinted chip with its label; the others stay icon-only.
struct ColorChips: View {
    @Binding var selection: Int
    let tabs: [TabItem]
    let bar: Color
    let muted: Color

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { t in
                let on = selection == t.id
                Button { selection = t.id } label: {
                    HStack(spacing: 8) {
                        Image(systemName: t.symbol(on))
                            .font(.system(size: 19, weight: .semibold))
                        if on {
                            Text(t.title)
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                                .fixedSize()
                                .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .leading)),
                                                        removal: .opacity))
                        }
                    }
                    .foregroundStyle(on ? t.color : muted)
                    .padding(.horizontal, on ? 18 : 0)
                    .frame(height: 50)
                    .frame(maxWidth: on ? nil : .infinity)
                    .background(Capsule().fill(t.color.opacity(on ? 0.14 : 0)))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .layoutPriority(on ? 1 : 0)
                .tabFrame(t.id)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: selection)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 33, style: .continuous).fill(bar))
        .shadow(color: Color(hex: 0x0F172A).opacity(0.14), radius: 22, y: 10)
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
    }
}
