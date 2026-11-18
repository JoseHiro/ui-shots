import SwiftUI

/// Macro: a nutrition tracker set like a Bauhaus poster. Calories are a yellow
/// sun with a black arc; protein, carbs and fat are a quarter circle, a square
/// and a half circle that fill up as you log meals.
struct MacroApp: View {
    @EnvironmentObject var demo: Demo

    static let cream = Color(hex: 0xF1E6D2)
    static let ink = Color(hex: 0x161616)
    static let red = Color(hex: 0xD63A2B)
    static let yellow = Color(hex: 0xF2B42C)
    static let blue = Color(hex: 0x1E4C9A)
    static func futura(_ size: CGFloat, _ w: String = "Bold") -> Font { .custom("Futura-\(w)", size: size) }

    /// Pause before each step: +lunch, +snack, protein, carbs, fat, +dinner.
    static let script: [Double] = [1.8, 1.6, 1.8, 1.3, 1.3, 1.9]

    struct Meal { let name: String; let item: String; let kcal: Double; let macros: [Double]; let step: Int }
    static let meals = [
        Meal(name: "Breakfast", item: "Oats, berries, yogurt", kcal: 420, macros: [28, 52, 14], step: 0),
        Meal(name: "Lunch", item: "Salmon rice bowl", kcal: 620, macros: [42, 58, 22], step: 1),
        Meal(name: "Snack", item: "Apple & almonds", kcal: 180, macros: [12, 18, 7], step: 2),
        Meal(name: "Dinner", item: "Chicken, greens, quinoa", kcal: 540, macros: [38, 40, 20], step: 6),
    ]
    static let goals: [Double] = [140, 240, 70]
    static let kcalGoal = 2200.0
    static let macroNames = ["PROTEIN", "CARBS", "FAT"]
    static let macroColors = [red, blue, ink]

    private var logged: [Meal] { Self.meals.filter { demo.step >= $0.step } }
    private var kcal: Double { logged.map(\.kcal).reduce(0, +) }
    private func macro(_ i: Int) -> Double { logged.map { $0.macros[i] }.reduce(0, +) }
    private var focus: Int? { (3...5).contains(demo.step) ? demo.step - 3 : nil }

    var body: some View {
        ZStack {
            Self.cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header.reveal(0)
                Rectangle().fill(Self.ink).frame(height: 3).padding(.top, 10).reveal(0)
                poster.reveal(1).padding(.top, 18)
                detail.reveal(2).padding(.top, 14)
                Rectangle().fill(Self.ink).frame(height: 3).padding(.top, 14).reveal(2)
                meals.reveal(3)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Nº 322 — TUE 18.11").font(Self.futura(12, "Medium")).kerning(2).foregroundStyle(Self.ink.opacity(0.6))
                Text("MACRO").font(Self.futura(46, "CondensedExtraBold")).foregroundStyle(Self.ink)
            }
            Spacer()
            HStack(spacing: 6) {
                Circle().fill(Self.red).frame(width: 18, height: 18)
                Rectangle().fill(Self.blue).frame(width: 18, height: 18)
                Triangle().fill(Self.yellow).frame(width: 20, height: 18)
            }
            .padding(.bottom, 10)
        }
    }

    private var poster: some View {
        HStack(alignment: .center, spacing: 22) {
            ZStack {
                Circle().fill(Self.yellow)
                Circle()
                    .trim(from: 0, to: demo.appeared ? kcal / Self.kcalGoal : 0)
                    .stroke(Self.ink, style: StrokeStyle(lineWidth: 12, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                    .padding(-14)
                    .animation(.spring(response: 1.0, dampingFraction: 0.85), value: kcal)
                    .animation(.easeOut(duration: 1.3).delay(0.3), value: demo.appeared)
                Circle().stroke(Self.ink.opacity(0.12), lineWidth: 12).padding(-14)
                VStack(spacing: 0) {
                    Counter(value: demo.appeared ? Self.kcalGoal - kcal : Self.kcalGoal) { Fmt.num($0) }
                        .font(Self.futura(38)).foregroundStyle(Self.ink)
                        .animation(.spring(response: 1.0, dampingFraction: 0.85), value: kcal)
                        .animation(.easeOut(duration: 1.3).delay(0.3), value: demo.appeared)
                    Text("KCAL LEFT").font(Self.futura(12, "Medium")).kerning(2).foregroundStyle(Self.ink)
                }
            }
            .frame(width: 150, height: 150)
            .padding(14)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(0..<3, id: \.self) { i in macroRow(i) }
            }
        }
    }

    private func macroRow(_ i: Int) -> some View {
        let pct = min(1, macro(i) / Self.goals[i])
        let dim = focus != nil && focus != i
        return HStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                MacroShape(kind: i).fill(Self.cream)
                Rectangle().fill(Self.macroColors[i])
                    .frame(height: 52 * pct * (demo.appeared ? 1 : 0))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .clipShape(MacroShape(kind: i))
                    .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(demo.appeared && demo.step == 0 ? 0.5 + Double(i) * 0.12 : 0), value: demo.appeared)
                MacroShape(kind: i).stroke(Self.ink, lineWidth: 2.5)
            }
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 1) {
                Text(Self.macroNames[i]).font(Self.futura(11, "Medium")).kerning(1.5).foregroundStyle(Self.ink.opacity(0.65))
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(macro(i)))").font(Self.futura(24)).contentTransition(.numericText()).fixedSize()
                    Text("/\(Int(Self.goals[i]))g").font(Self.futura(12, "Medium")).foregroundStyle(Self.ink.opacity(0.55))
                }
                .foregroundStyle(Self.ink)
            }
        }
        .opacity(dim ? 0.3 : 1)
        .scaleEffect(focus == i ? 1.08 : 1, anchor: .leading)
        .demoTap(i + 3)
    }

    private var detail: some View {
        let i = focus
        let lines = ["Protein is 76% there. A dinner with chicken or tofu closes it.",
                     "Carbs are on pace. Most came from oats and rice today.",
                     "Fat is low and steady. Almonds and salmon did the work."]
        return HStack(alignment: .top, spacing: 10) {
            Rectangle().fill(i.map { Self.macroColors[$0] } ?? Self.ink).frame(width: 8, height: 34)
            Text(i.map { lines[$0] } ?? "Eaten \(Fmt.num(kcal)) of \(Fmt.num(Self.kcalGoal)) kcal. \(["One meal", "Two meals", "Three meals", "All four meals"][logged.count - 1]) logged so far.")
                .font(Self.futura(14, "Medium")).foregroundStyle(Self.ink)
                .fixedSize(horizontal: false, vertical: true)
                .id(i ?? -1).transition(.asymmetric(insertion: .opacity, removal: .identity))
        }
        .frame(height: 40, alignment: .top)
    }

    private var meals: some View {
        VStack(spacing: 0) {
            ForEach(0..<Self.meals.count, id: \.self) { i in
                let m = Self.meals[i]
                let done = demo.step >= m.step
                HStack(spacing: 14) {
                    MealGlyph(kind: i).frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(m.name.uppercased()).font(Self.futura(17)).foregroundStyle(Self.ink)
                        Text(done ? m.item : "Nothing logged").font(Self.futura(13, "Medium"))
                            .foregroundStyle(Self.ink.opacity(done ? 0.65 : 0.35))
                    }
                    Spacer()
                    if done {
                        Text("\(Int(m.kcal))").font(Self.futura(22)).foregroundStyle(Self.ink)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    } else {
                        Image(systemName: "plus").font(.system(size: 16, weight: .heavy)).foregroundStyle(Self.cream)
                            .frame(width: 38, height: 38).background(Circle().fill(Self.ink))
                            .scaleEffect(demo.isPressing(m.step) ? 0.85 : 1)
                            .demoTap(m.step)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                .padding(.vertical, 13)
                .overlay(alignment: .bottom) { Rectangle().fill(Self.ink).frame(height: i < 3 ? 1.2 : 3) }
            }
        }
    }
}

private struct MacroShape: Shape {
    let kind: Int
    func path(in r: CGRect) -> Path {
        switch kind {
        case 0: // quarter circle
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.minX, y: r.minY))
            p.addArc(center: CGPoint(x: r.minX, y: r.maxY), radius: r.width, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            p.closeSubpath()
            return p
        case 1:
            return Rectangle().path(in: r)
        default: // half ellipse (arch), flat side down
            let k: CGFloat = 0.5523
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.maxY))
            p.addCurve(to: CGPoint(x: r.midX, y: r.minY), control1: CGPoint(x: r.minX, y: r.maxY - r.height * k),
                       control2: CGPoint(x: r.midX - r.width / 2 * k, y: r.minY))
            p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY), control1: CGPoint(x: r.midX + r.width / 2 * k, y: r.minY),
                       control2: CGPoint(x: r.maxX, y: r.maxY - r.height * k))
            p.closeSubpath()
            return p
        }
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct MealGlyph: View {
    let kind: Int
    var body: some View {
        switch kind {
        case 0: Circle().fill(MacroApp.red)
        case 1: Triangle().fill(MacroApp.yellow)
        case 2: Rectangle().fill(MacroApp.blue).padding(3)
        default:
            ZStack {
                Circle().fill(MacroApp.ink)
                Rectangle().fill(MacroApp.cream).frame(height: 15).offset(y: 7.5)
            }
        }
    }
}
