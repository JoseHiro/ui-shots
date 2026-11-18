import SwiftUI

/// Sip: a hydration tracker in claymorphism. Puffy pastel shapes with soft
/// double shadows, and a bottle with a little face that fills with live water.
struct SipApp: View {
    @EnvironmentObject var demo: Demo

    static let ink = Color(hex: 0x2B3150)
    static let mute = Color(hex: 0x7C83A6)
    static let water = Color(hex: 0x5AA9FF)
    static let card = Color(hex: 0xEEF3FF)
    static let goal = 2000.0

    /// Pause before each step: glass, tea, glass, bottle, glass (goal), reminder.
    static let script: [Double] = [1.8, 1.5, 1.5, 1.7, 1.7, 2.4]
    static let adds: [Double] = [250, 150, 250, 500, 250]
    static let addButtons: [(String, String, Double, UInt32, UInt32)] = [
        ("cup.and.heat.waves.fill", "Tea", 150, 0xFFC9A8, 0xE89A6E), ("drop.fill", "Glass", 250, 0x9CC8FF, 0x5C93E0),
        ("waterbottle.fill", "Bottle", 500, 0xA8E6CF, 0x5DB592),
    ]
    /// Which button each add step presses (index into addButtons).
    static let addTarget = [1, 0, 1, 2, 1]

    private var total: Double { 750 + Self.adds.prefix(min(demo.step, 5)).reduce(0, +) }
    private var reached: Bool { total >= Self.goal }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xD8E6FF), Color(hex: 0xEDE3FF)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 22) {
                header.reveal(0)
                hero.reveal(1)
                buttons.reveal(2)
                week.reveal(3)
                reminder.reveal(4)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Sip").font(.system(size: 34, weight: .heavy, design: .rounded)).foregroundStyle(Self.ink)
                Text("Tuesday, 18 Nov").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(Self.mute)
            }
            Spacer()
            Text("A").font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: 0x8A5CD8))
                .frame(width: 48, height: 48)
                .clay(Color(hex: 0xE3D5FF), shadow: Color(hex: 0x9B86D6), radius: 24)
        }
    }

    private var hero: some View {
        HStack(spacing: 18) {
            Bottle(level: total / Self.goal, happy: reached)
                .frame(width: 130, height: 210)
                .overlay(alignment: .top) {
                    if demo.step > 0 && demo.step <= 5 {
                        FloatUp(text: "+\(Int(Self.adds[demo.step - 1])) ml").id(demo.step)
                    }
                }
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY").font(.system(size: 12, weight: .heavy, design: .rounded)).kerning(1.5).foregroundStyle(Self.mute)
                Counter(value: demo.appeared ? total : 0) { Fmt.num($0) }
                    .font(.system(size: 46, weight: .heavy, design: .rounded)).foregroundStyle(Self.ink)
                    .animation(.spring(response: 0.8, dampingFraction: 0.85), value: total)
                    .animation(.easeOut(duration: 1.2).delay(0.3), value: demo.appeared)
                Text("of 2,000 ml").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Self.mute)
                Group {
                    if reached {
                        Label("Goal reached!", systemImage: "sparkles")
                            .foregroundStyle(Color(hex: 0x2E8B6A))
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .clay(Color(hex: 0xBDF0D9), shadow: Color(hex: 0x6CC4A0), radius: 18)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    } else {
                        Label("\(Int(Self.goal - total)) ml to go", systemImage: "drop")
                            .foregroundStyle(Self.water)
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .clay(.white, shadow: Color(hex: 0x9DB4E6), radius: 18)
                            .contentTransition(.numericText())
                    }
                }
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .padding(.top, 8)
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .clay(Self.card, shadow: Color(hex: 0x9DB0E0), radius: 40)
    }

    private var buttons: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { i in
                let b = Self.addButtons[i]
                let steps = (0..<5).filter { Self.addTarget[$0] == i }.map { $0 + 1 }
                let pressing = demo.pressed && steps.contains(demo.pressingStep)
                VStack(spacing: 8) {
                    Image(systemName: b.0).font(.system(size: 26, weight: .bold)).foregroundStyle(Color(hex: b.4))
                    VStack(spacing: 0) {
                        Text(b.1).font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Self.ink)
                        Text("+\(Int(b.2)) ml").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Self.mute)
                    }
                }
                .frame(maxWidth: .infinity).frame(height: 108)
                .clay(Color(hex: b.3), shadow: Color(hex: b.4), radius: 32, pressed: pressing)
                .scaleEffect(pressing ? 0.92 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: pressing)
                .modifier(DemoTap(steps: steps))
            }
        }
    }

    private var week: some View {
        let days = [0.82, 1.0, 0.64, 1.0, 0.9, 0.72, total / Self.goal]
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This week").font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(Self.ink)
                Spacer()
                Text("5 day streak").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: 0xE8895A))
            }
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(0..<7, id: \.self) { d in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            Capsule().fill(Color(hex: 0xDCE5FA))
                                .overlay(Capsule().stroke(LinearGradient(colors: [.black.opacity(0.1), .white.opacity(0.8)], startPoint: .top, endPoint: .bottom), lineWidth: 2))
                            Capsule().fill(LinearGradient(colors: [Color(hex: 0x8CC4FF), Self.water], startPoint: .top, endPoint: .bottom))
                                .frame(height: 84 * min(1, days[d]) * (demo.appeared ? 1 : 0.05))
                                .overlay(alignment: .top) { Capsule().fill(.white.opacity(0.5)).frame(width: 8, height: 4).padding(.top, 5) }
                        }
                        .frame(width: 22, height: 84)
                        .animation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.5 + Double(d) * 0.05), value: demo.appeared)
                        Text(["M", "T", "W", "T", "F", "S", "T"][d])
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(d == 6 ? Self.water : Self.mute)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .clay(Self.card, shadow: Color(hex: 0x9DB0E0), radius: 34)
    }

    private var reminder: some View {
        let on = demo.step >= 6
        return HStack(spacing: 14) {
            Image(systemName: "bell.fill").font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0xE8A23C))
                .frame(width: 42, height: 42)
                .clay(Color(hex: 0xFFE7B8), shadow: Color(hex: 0xDDB060), radius: 21)
            VStack(alignment: .leading, spacing: 1) {
                Text("Hourly nudge").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundStyle(Self.ink)
                Text(on ? "On · next at 3:00 PM" : "Off").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Self.mute)
            }
            Spacer()
            ZStack(alignment: on ? .trailing : .leading) {
                Capsule().fill(on ? Color(hex: 0x8FD8B8) : Color(hex: 0xD5DCEE))
                    .overlay(Capsule().stroke(LinearGradient(colors: [.black.opacity(0.12), .white.opacity(0.7)], startPoint: .top, endPoint: .bottom), lineWidth: 2))
                Circle().fill(.white).frame(width: 28, height: 28).padding(3)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
            }
            .frame(width: 62, height: 34)
            .demoTap(6)
        }
        .padding(16)
        .clay(Self.card, shadow: Color(hex: 0x9DB0E0), radius: 28)
    }
}

extension View {
    /// Clay: puffy fill, a light rim up top, a soft inner shade below and two outer shadows.
    func clay(_ color: Color, shadow: Color, radius: CGFloat, pressed: Bool = false) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return background(
            shape.fill(color)
                .overlay(shape.stroke(LinearGradient(colors: [.white.opacity(0.9), .clear], startPoint: .topLeading, endPoint: .center), lineWidth: 4)
                    .blur(radius: 3).clipShape(shape))
                .overlay(shape.stroke(LinearGradient(colors: [.clear, shadow.opacity(0.45)], startPoint: .center, endPoint: .bottomTrailing), lineWidth: 8)
                    .blur(radius: 6).clipShape(shape))
                .shadow(color: shadow.opacity(pressed ? 0.25 : 0.45), radius: pressed ? 6 : 16, x: pressed ? 3 : 8, y: pressed ? 4 : 12)
                .shadow(color: .white.opacity(0.85), radius: 10, x: -6, y: -6)
        )
    }
}

/// Glassy bottle with live water and a face that cheers up at the goal.
private struct Bottle: View {
    let level: Double
    let happy: Bool
    var body: some View {
        ZStack {
            BottleShape().fill(.white.opacity(0.55))
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100)
                ZStack {
                    WaterShape(level: min(level, 1) * 0.86, phase: t * 2.4, amp: 5)
                        .fill(Color(hex: 0x8CC4FF).opacity(0.7))
                    WaterShape(level: min(level, 1) * 0.86, phase: t * 1.7 + 2, amp: 6)
                        .fill(LinearGradient(colors: [Color(hex: 0x7BB8FF), Color(hex: 0x4E97F0)], startPoint: .top, endPoint: .bottom))
                }
            }
            .clipShape(BottleShape())
            .animation(.spring(response: 0.9, dampingFraction: 0.7), value: level)
            face.offset(y: 30)
            BottleShape().stroke(.white, lineWidth: 3)
            Capsule().fill(.white.opacity(0.6)).frame(width: 9, height: 70).offset(x: -40, y: 20)
            RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0x9CC8FF))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.8), lineWidth: 2))
                .frame(width: 50, height: 24).offset(y: -96)
        }
        .shadow(color: Color(hex: 0x5A8FE0).opacity(0.35), radius: 16, x: 6, y: 12)
    }

    private var face: some View {
        VStack(spacing: 6) {
            HStack(spacing: 26) {
                ForEach(0..<2, id: \.self) { _ in
                    if happy {
                        SmileArc().stroke(SipApp.ink, style: StrokeStyle(lineWidth: 3.5, lineCap: .round)).frame(width: 14, height: 8)
                            .rotationEffect(.degrees(180))
                    } else {
                        Capsule().fill(SipApp.ink).frame(width: 9, height: 13)
                    }
                }
            }
            .frame(height: 14)
            SmileArc().stroke(SipApp.ink, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .frame(width: happy ? 26 : 16, height: happy ? 12 : 7)
        }
        .overlay {
            HStack(spacing: 50) {
                ForEach(0..<2, id: \.self) { _ in Ellipse().fill(Color(hex: 0xFF8FA8).opacity(happy ? 0.7 : 0.35)).frame(width: 14, height: 8) }
            }
            .offset(y: 6)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: happy)
    }
}

private struct BottleShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height, neck = w * 0.36, top = h * 0.06, shoulder = h * 0.26
        var p = Path()
        p.move(to: CGPoint(x: (w - neck) / 2, y: top))
        p.addLine(to: CGPoint(x: (w + neck) / 2, y: top))
        p.addLine(to: CGPoint(x: (w + neck) / 2, y: h * 0.12))
        p.addCurve(to: CGPoint(x: w, y: shoulder + 24), control1: CGPoint(x: (w + neck) / 2 + 6, y: shoulder - 8), control2: CGPoint(x: w, y: shoulder - 6))
        p.addLine(to: CGPoint(x: w, y: h - 30))
        p.addQuadCurve(to: CGPoint(x: w - 30, y: h), control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 30, y: h))
        p.addQuadCurve(to: CGPoint(x: 0, y: h - 30), control: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: shoulder + 24))
        p.addCurve(to: CGPoint(x: (w - neck) / 2, y: h * 0.12), control1: CGPoint(x: 0, y: shoulder - 6), control2: CGPoint(x: (w - neck) / 2 - 6, y: shoulder - 8))
        p.closeSubpath()
        return p
    }
}

private struct WaterShape: Shape {
    var level: Double
    let phase: Double
    let amp: CGFloat
    var animatableData: Double {
        get { level }
        set { level = newValue }
    }
    func path(in r: CGRect) -> Path {
        let y0 = r.height * (1 - CGFloat(level))
        var p = Path()
        p.move(to: CGPoint(x: 0, y: r.height))
        for x in stride(from: 0, through: r.width, by: 3) {
            p.addLine(to: CGPoint(x: x, y: y0 + amp * CGFloat(sin(Double(x) / r.width * .pi * 2.4 + phase))))
        }
        p.addLine(to: CGPoint(x: r.width, y: r.height))
        p.closeSubpath()
        return p
    }
}

private struct SmileArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 2 - r.minY))
        return p
    }
}

/// "+250 ml" that floats up and fades.
private struct FloatUp: View {
    let text: String
    @State private var go = false
    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(SipApp.water)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.white, in: Capsule())
            .shadow(color: SipApp.water.opacity(0.3), radius: 8, y: 4)
            .fixedSize()
            .offset(y: go ? -46 : 10)
            .opacity(go ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 1.3)) { go = true } }
    }
}
