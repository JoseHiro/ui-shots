import SwiftUI

struct RootView: View {
    @StateObject private var demo = Demo()
    @State var style: BarStyle
    let isDemo: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()

            ZStack {
                ForEach(tabs) { t in
                    if demo.selection == t.id {
                        ContentPage(tab: t)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.28), value: demo.selection)
            .frame(maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .top) {
                if !isDemo {
                    Picker("Style", selection: $style) {
                        ForEach(BarStyle.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                }
            }

            bar
        }
        .coordinateSpace(name: "screen")
        .overlay(alignment: .topLeading) {
            if demo.syncMarker {
                Rectangle().fill(.red).frame(width: 60, height: 60).ignoresSafeArea()
            }
        }
        .overlay {
            if let p = demo.touch {
                TouchDot(point: p, pressed: demo.pressed)
            }
        }
        .onPreferenceChange(TabFramesKey.self) { demo.frames = $0 }
        .task {
            if isDemo { await demo.run() }
        }
    }

    @ViewBuilder private var bar: some View {
        switch style {
        case .liquidDock: LiquidDock(selection: $demo.selection)
        case .bubbleNotch: BubbleNotch(selection: $demo.selection)
        case .softPill: SoftPill(selection: $demo.selection)
        case .colorChips: ColorChips(selection: $demo.selection)
        }
    }
}

struct ContentPage: View {
    let tab: TabItem
    private let cardIcons = ["sparkles", "music.note", "camera", "leaf", "cup.and.saucer", "star", "paperplane", "moon"]
    private var hero: String {
        switch tab.id {
        case 0: "Good morning"
        case 1: "Find something new"
        case 2: "Your favorites"
        default: "Hi, Alex"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tab.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [tab.color, tab.color.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 170)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: symbol(tab, filled: true))
                            .font(.system(size: 26, weight: .semibold))
                        Text(hero)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                }
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(0..<8, id: \.self) { i in card(i) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func card(_ i: Int) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.white)
            .frame(height: 118)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tab.color.opacity(0.14 + Double(i % 3) * 0.06))
                        .frame(width: 42, height: 42)
                        .overlay(Image(systemName: cardIcons[(i + tab.id * 2) % cardIcons.count])
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(tab.color))
                    Capsule().fill(Theme.ink.opacity(0.7)).frame(width: 74, height: 8)
                    Capsule().fill(Theme.muted.opacity(0.35)).frame(width: 52, height: 7)
                }
                .padding(14)
            }
            .shadow(color: Theme.lavenderDeep.opacity(0.08), radius: 10, y: 4)
    }
}
