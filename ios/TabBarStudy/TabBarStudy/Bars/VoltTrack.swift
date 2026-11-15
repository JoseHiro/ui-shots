import SwiftUI

/// Athletic black capsule. A volt pill slides between tabs and opens to show
/// the label in wide, all-caps type.
struct VoltTrack: View {
    @Binding var selection: Int
    let tabs: [TabItem]
    @Namespace private var ns
    static let volt = Color(hex: 0xC8F53B)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { t in
                let on = selection == t.id
                Button { selection = t.id } label: {
                    HStack(spacing: 8) {
                        Image(systemName: t.symbol(on))
                            .font(.system(size: 18, weight: .bold))
                        if on {
                            Text(t.title.uppercased())
                                .font(.system(size: 12, weight: .heavy).width(.expanded))
                                .lineLimit(1)
                                .fixedSize()
                                .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .leading)))
                        }
                    }
                    .foregroundStyle(on ? .black : .white.opacity(0.5))
                    .padding(.horizontal, on ? 18 : 0)
                    .frame(height: 50)
                    .frame(maxWidth: on ? nil : .infinity)
                    .background {
                        if on {
                            Capsule()
                                .fill(Self.volt)
                                .matchedGeometryEffect(id: "pill", in: ns)
                                .shadow(color: Self.volt.opacity(0.5), radius: 12)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .layoutPriority(on ? 1 : 0)
                .tabFrame(t.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.66), value: selection)
        .padding(7)
        .background(Capsule().fill(Color(hex: 0x0B0B0C)))
        .overlay(Capsule().stroke(.white.opacity(0.08)))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }
}
