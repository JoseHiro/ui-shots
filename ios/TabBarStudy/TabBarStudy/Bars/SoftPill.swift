import SwiftUI

/// Full-width bar. The selected icon gets a tinted pill that grows out from
/// the center, the icon fills in and bounces, and the label takes the tab color.
struct SoftPill: View {
    @Binding var selection: Int
    let tabs: [TabItem]
    let bar: Color
    let muted: Color
    @State private var bounces = [0, 0, 0, 0]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { t in
                let on = selection == t.id
                Button { selection = t.id } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            Capsule()
                                .fill(t.color.opacity(0.15))
                                .frame(width: 62, height: 34)
                                .scaleEffect(x: on ? 1 : 0.3, y: on ? 1 : 0.6)
                                .opacity(on ? 1 : 0)
                            Image(systemName: t.symbol(on))
                                .font(.system(size: 20, weight: on ? .semibold : .regular))
                                .foregroundStyle(on ? t.color : muted)
                                .symbolEffect(.bounce.up, value: bounces[t.id])
                        }
                        Text(t.title)
                            .font(.system(size: 11, weight: on ? .bold : .medium))
                            .foregroundStyle(on ? t.color : muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .tabFrame(t.id)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.7), value: selection)
        .background {
            bar
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle().fill(.black.opacity(0.06)).frame(height: 1)
                }
        }
        .onChange(of: selection) { _, new in bounces[new] += 1 }
    }
}
