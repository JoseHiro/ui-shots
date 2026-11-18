import SwiftUI

/// SET: a gym logger built like a piece of hardware. A green segment LCD with
/// ghost digits, beveled push buttons and an orange LOG key.
struct SetApp: View {
    @EnvironmentObject var demo: Demo

    static let body1 = Color(hex: 0x1B1C1F)
    static let panel = Color(hex: 0x26282C)
    static let lcdInk = Color(hex: 0x1D2718)
    static let orange = Color(hex: 0xF26A1B)
    static let engrave = Color(hex: 0x6A6D73)
    static let lcdFont = "DBLCDTempBlack"

    /// Pause before each step: +kg, log, log, next exercise, +kg, log, log.
    static let script: [Double] = [1.8, 1.4, 2.2, 1.8, 1.4, 1.4, 2.2]

    struct Exercise { let name: String; let sets: Int; let reps: Int; let kg: Double; let step: Double }
    static let exercises = [
        Exercise(name: "BENCH PRESS", sets: 4, reps: 8, kg: 80, step: 2.5),
        Exercise(name: "INCLINE DB PRESS", sets: 3, reps: 10, kg: 24, step: 2),
        Exercise(name: "CABLE FLY", sets: 3, reps: 12, kg: 15, step: 2.5),
        Exercise(name: "TRICEPS DIP", sets: 3, reps: 10, kg: 0, step: 5),
    ]

    struct State { var ex = 0; var kg: [Double]; var done = [1, 0, 0, 0]; var restStep: Int? }
    static func state(_ step: Int) -> State {
        var s = State(kg: exercises.map(\.kg))
        if step >= 1 { s.kg[0] = 82.5 }
        if step >= 2 { s.done[0] = 2; s.restStep = 2 }
        if step >= 3 { s.done[0] = 3; s.restStep = 3 }
        if step >= 4 { s.ex = 1; s.restStep = nil }
        if step >= 5 { s.kg[1] = 26 }
        if step >= 6 { s.done[1] = 1; s.restStep = 6 }
        if step >= 7 { s.done[1] = 2; s.restStep = 7 }
        return s
    }

    var body: some View {
        let s = Self.state(demo.step)
        ZStack {
            LinearGradient(colors: [Color(hex: 0x222327), Color(hex: 0x111214)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    Text("SET").font(.system(size: 22, weight: .black, design: .monospaced)).foregroundStyle(.white)
                    Text("·01  WORKOUT LOGGER").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(Self.engrave)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(Self.orange).frame(width: 7, height: 7).shadow(color: Self.orange, radius: 4)
                        Text("REC").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(Self.engrave)
                    }
                }
                .reveal(0)
                lcd(s).reveal(1)
                keys.reveal(2)
                list(s).reveal(3)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: LCD

    private func lcd(_ s: State) -> some View {
        let e = Self.exercises[s.ex]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PUSH DAY · WK 06")
                Spacer()
                Text("SET \(min(s.done[s.ex] + 1, e.sets))/\(e.sets)").contentTransition(.numericText())
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))

            Text(e.name).font(.system(size: 19, weight: .heavy, design: .monospaced)).kerning(1)
                .id(s.ex).transition(.opacity)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                SegText(text: String(format: "%5.1f", s.kg[s.ex]), height: 62)
                Text("KG").font(.system(size: 15, weight: .heavy, design: .monospaced))
                Spacer()
                SegText(text: "×" + String(format: "%2d", e.reps), height: 34)
            }

            Rectangle().fill(Self.lcdInk.opacity(0.25)).frame(height: 1.5)

            HStack(alignment: .center) {
                RestClock(from: s.restStep.flatMap { demo.stepDate[$0] })
                Spacer()
                HStack(spacing: 5) {
                    ForEach(0..<e.sets, id: \.self) { k in
                        Rectangle().fill(Self.lcdInk.opacity(k < s.done[s.ex] ? 1 : 0.1)).frame(width: 18, height: 12)
                    }
                }
            }
        }
        .foregroundStyle(Self.lcdInk)
        .padding(.horizontal, 18).padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xB6C3A2), Color(hex: 0x9CAB8A)], startPoint: .top, endPoint: .bottom))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 4)
                    .blur(radius: 2).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)))
        )
        .opacity(demo.appeared ? 1 : 0.15)
        .animation(.easeIn(duration: 0.08).repeatCount(3).delay(0.2), value: demo.appeared)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Self.panel)
            .shadow(color: .black.opacity(0.6), radius: 14, y: 10))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom), lineWidth: 1))
        .overlay(alignment: .topLeading) { screws }
    }

    private var screws: some View {
        GeometryReader { g in
            ForEach(0..<4, id: \.self) { i in
                Circle().fill(Color(hex: 0x3A3C41)).frame(width: 5, height: 5)
                    .position(x: i % 2 == 0 ? 6 : g.size.width - 6, y: i < 2 ? 6 : g.size.height - 6)
            }
        }
    }

    // MARK: Keys

    private var keys: some View {
        HStack(alignment: .top, spacing: 0) {
            key(label: "REPS", glyph: "minus", size: 66, color: Color(hex: 0x3A3C41), pressed: false)
                .frame(maxWidth: .infinity)
            key(label: "LOG SET", glyph: "checkmark", size: 92, color: Self.orange, pressed: demo.isPressing(2, 3, 6, 7))
                .demoTap(2, 3, 6, 7)
                .frame(maxWidth: .infinity)
            key(label: "KG", glyph: "plus", size: 66, color: Color(hex: 0x3A3C41), pressed: demo.isPressing(1, 5))
                .demoTap(1, 5)
                .frame(maxWidth: .infinity)
        }
    }

    private func key(label: String, glyph: String, size: CGFloat, color: Color, pressed: Bool) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(.black.opacity(0.6)).offset(y: pressed ? 1 : 5).blur(radius: 3)
                Circle().fill(LinearGradient(colors: [color.opacity(1), color.opacity(0.78)], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(LinearGradient(colors: [.white.opacity(0.35), .black.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5))
                Image(systemName: glyph).font(.system(size: size * 0.3, weight: .heavy)).foregroundStyle(.white.opacity(0.92))
            }
            .frame(width: size, height: size)
            .scaleEffect(pressed ? 0.93 : 1)
            .offset(y: pressed ? 3 : 0)
            .animation(.easeOut(duration: 0.1), value: pressed)
            Text(label).font(.system(size: 10, weight: .bold, design: .monospaced)).kerning(1.5).foregroundStyle(Self.engrave)
        }
        .frame(height: 116, alignment: .center)
    }

    // MARK: List

    private func list(_ s: State) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY").font(.system(size: 11, weight: .bold, design: .monospaced)).kerning(2).foregroundStyle(Self.engrave)
                Spacer()
                let total = s.done.reduce(0, +), all = Self.exercises.map(\.sets).reduce(0, +)
                Text("\(total)/\(all) SETS").font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Self.orange).contentTransition(.numericText())
            }
            ForEach(0..<Self.exercises.count, id: \.self) { i in
                let e = Self.exercises[i]
                let on = s.ex == i
                HStack(spacing: 12) {
                    Rectangle().fill(on ? Self.orange : .clear).frame(width: 3, height: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(e.name.capitalized).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white.opacity(on ? 1 : 0.75))
                        Text("\(e.sets) × \(e.reps)  ·  " + (e.kg > 0 ? String(format: "%g KG", s.kg[i]) : "BODYWEIGHT"))
                            .font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(Self.engrave)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(0..<e.sets, id: \.self) { k in
                            RoundedRectangle(cornerRadius: 1.5).fill(k < s.done[i] ? Self.orange : Color.white.opacity(0.1))
                                .frame(width: 8, height: 18)
                        }
                    }
                }
                .padding(.vertical, 10).padding(.trailing, 14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(on ? 0.07 : 0.035)))
                .demoTap(i == 1 ? 4 : 99)
            }
        }
    }
}

/// Rest countdown from 1:30, blinking REST while it runs.
private struct RestClock: View {
    let from: Date?
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { tl in
            let left = from.map { max(0, 90 - tl.date.timeIntervalSince($0)) }
            let blink = Int(tl.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(left == nil ? "READY" : "REST")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .opacity(left != nil && !blink ? 0.2 : 1)
                SegText(text: left.map { String(format: "%02d:%02d", Int($0.rounded(.up)) / 60, Int($0.rounded(.up)) % 60) } ?? "--:--", height: 24)
            }
        }
    }
}

/// Seven-segment readout with unlit "ghost" segments, like a real LCD.
struct SegText: View {
    let text: String
    let height: CGFloat
    var color = SetApp.lcdInk

    var body: some View {
        HStack(alignment: .bottom, spacing: height * 0.12) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, c in
                if let d = c.wholeNumberValue {
                    Digit(on: Self.map[d], h: height, color: color)
                } else if c == "." {
                    Rectangle().fill(color).frame(width: height * 0.11, height: height * 0.11).padding(.leading, -height * 0.06)
                } else if c == ":" {
                    VStack(spacing: height * 0.28) {
                        Rectangle().fill(color).frame(width: height * 0.1, height: height * 0.1)
                        Rectangle().fill(color).frame(width: height * 0.1, height: height * 0.1)
                    }
                    .padding(.bottom, height * 0.2)
                } else if c == " " {
                    Digit(on: Array(repeating: false, count: 7), h: height, color: color)
                } else if c == "-" {
                    Digit(on: [false, false, false, false, false, false, true], h: height, color: color)
                } else {
                    Text(String(c)).font(.system(size: height * 0.5, weight: .heavy)).foregroundStyle(color)
                }
            }
        }
        .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.08, d: 1, tx: height * 0.04, ty: 0))
    }

    // a b c d e f g
    static let map: [[Bool]] = [
        [true, true, true, true, true, true, false], [false, true, true, false, false, false, false],
        [true, true, false, true, true, false, true], [true, true, true, true, false, false, true],
        [false, true, true, false, false, true, true], [true, false, true, true, false, true, true],
        [true, false, true, true, true, true, true], [true, true, true, false, false, false, false],
        [true, true, true, true, true, true, true], [true, true, true, true, false, true, true],
    ]

    private struct Digit: View {
        let on: [Bool]
        let h: CGFloat
        let color: Color
        var body: some View {
            let w = h * 0.55
            ZStack {
                ForEach(0..<7, id: \.self) { i in
                    Segment(index: i, t: h * 0.13).fill(color.opacity(on[i] ? 1 : 0.07))
                }
            }
            .frame(width: w, height: h)
        }
    }

    private struct Segment: Shape {
        let index: Int
        let t: CGFloat
        func path(in r: CGRect) -> Path {
            let w = r.width, h = r.height, g = t * 0.18, m = h / 2
            func hbar(_ y: CGFloat) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: g + t / 2, y: y))
                p.addLine(to: CGPoint(x: g + t, y: y - t / 2))
                p.addLine(to: CGPoint(x: w - g - t, y: y - t / 2))
                p.addLine(to: CGPoint(x: w - g - t / 2, y: y))
                p.addLine(to: CGPoint(x: w - g - t, y: y + t / 2))
                p.addLine(to: CGPoint(x: g + t, y: y + t / 2))
                p.closeSubpath()
                return p
            }
            func vbar(_ x: CGFloat, _ y0: CGFloat, _ y1: CGFloat) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: x, y: y0 + g))
                p.addLine(to: CGPoint(x: x + t / 2, y: y0 + g + t / 2))
                p.addLine(to: CGPoint(x: x + t / 2, y: y1 - g - t / 2))
                p.addLine(to: CGPoint(x: x, y: y1 - g))
                p.addLine(to: CGPoint(x: x - t / 2, y: y1 - g - t / 2))
                p.addLine(to: CGPoint(x: x - t / 2, y: y0 + g + t / 2))
                p.closeSubpath()
                return p
            }
            let l = t / 2, rx = w - t / 2, top = t / 2, bot = h - t / 2
            switch index {
            case 0: return hbar(top)
            case 1: return vbar(rx, top, m)
            case 2: return vbar(rx, m, bot)
            case 3: return hbar(bot)
            case 4: return vbar(l, m, bot)
            case 5: return vbar(l, top, m)
            default: return hbar(m)
            }
        }
    }
}
