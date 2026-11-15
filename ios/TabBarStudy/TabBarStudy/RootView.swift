import SwiftUI

struct RootView: View {
    @StateObject private var demo = Demo()
    @State var style: BarStyle
    let isDemo: Bool

    var body: some View {
        app
            .safeAreaInset(edge: .top) {
                if !isDemo {
                    Picker("Style", selection: $style) {
                        ForEach(BarStyle.allCases) { Text($0.name).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                }
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

    @ViewBuilder private var app: some View {
        switch style {
        case .liquidDock: MusicApp(selection: $demo.selection)
        case .bubbleNotch: FoodApp(selection: $demo.selection)
        case .softPill: FitnessApp(selection: $demo.selection)
        case .colorChips: TravelApp(selection: $demo.selection)
        }
    }
}
