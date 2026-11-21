import SwiftUI
import SceneKit

/// Orbit: a real 3D dot globe (SceneKit). Picking a destination turns the
/// globe to the route and draws a glowing great-circle arc from Tokyo.
struct OrbitApp: View {
    @EnvironmentObject var demo: Demo

    static let bg = Color(hex: 0x04070F)
    static let amber = Color(hex: 0xFFB547)
    static let ice = Color(hex: 0x9CC2FF)

    /// Pause before each step: Reykjavík, Lisbon, Cape Town, book.
    static let script: [Double] = [1.8, 3.4, 3.4, 3.2]

    struct Place { let city: String; let country: String; let code: String; let lat: Double; let lon: Double; let symbol: String; let price: Int }
    static let home = Place(city: "Tokyo", country: "Japan", code: "HND", lat: 35.55, lon: 139.78, symbol: "", price: 0)
    static let places = [
        Place(city: "Reykjavík", country: "Iceland", code: "KEF", lat: 63.98, lon: -22.6, symbol: "snowflake", price: 148_000),
        Place(city: "Lisbon", country: "Portugal", code: "LIS", lat: 38.77, lon: -9.13, symbol: "tram.fill", price: 126_000),
        Place(city: "Cape Town", country: "South Africa", code: "CPT", lat: -33.97, lon: 18.6, symbol: "sun.max.fill", price: 173_000),
    ]

    static func km(_ p: Place) -> Double {
        let r = Double.pi / 180
        let a = sin((p.lat - home.lat) * r / 2), b = sin((p.lon - home.lon) * r / 2)
        let h = a * a + cos(home.lat * r) * cos(p.lat * r) * b * b
        return 2 * 6371 * asin(sqrt(h))
    }

    private var selected: Int? { demo.step == 0 ? nil : min(demo.step, 3) - 1 }
    private var booked: Bool { demo.step >= 4 }

    var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()
            Stars().ignoresSafeArea().reveal(0)
            VStack(spacing: 0) {
                header.reveal(0)
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Color(hex: 0x2B5BFF).opacity(0.45), Color(hex: 0x2B5BFF).opacity(0.12), .clear],
                                             center: .center, startRadius: 150, endRadius: 215))
                        .frame(width: 440, height: 440)
                    GlobeView(selected: selected, booked: booked)
                        .frame(width: 402, height: 372)
                }
                .frame(width: 402, height: 372)
                .scaleEffect(demo.appeared ? 1 : 0.7)
                .opacity(demo.appeared ? 1 : 0)
                .animation(.spring(response: 1.1, dampingFraction: 0.8), value: demo.appeared)
                route.reveal(2).padding(.top, 2).padding(.horizontal, 20)
                cards.reveal(3).padding(.top, 14).padding(.horizontal, 20)
                book.reveal(4).padding(.top, 14).padding(.horizontal, 20)
                Spacer(minLength: 0)
            }
            .padding(.top, 6)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Orbit").font(.system(size: 34, weight: .semibold)).foregroundStyle(.white)
                Text("From Tokyo · HND").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "airplane").font(.system(size: 16, weight: .semibold)).foregroundStyle(Self.amber)
                .frame(width: 42, height: 42)
                .background(Circle().fill(.white.opacity(0.08)))
                .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private var route: some View {
        let p = selected.map { Self.places[$0] }
        return HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    Text("HND").foregroundStyle(.white)
                    Image(systemName: "airplane").font(.system(size: 15, weight: .bold)).foregroundStyle(Self.amber)
                    Text(p?.code ?? "···").foregroundStyle(p == nil ? .white.opacity(0.3) : .white)
                        .contentTransition(.numericText())
                }
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                Text(p.map { "Tokyo → \($0.city)" } ?? "Pick a destination")
                    .font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.55))
                    .contentTransition(.opacity)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Counter(value: p.map { Self.km($0) } ?? 0) { "\(Int($0).formatted()) km" }
                    .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
                Counter(value: p.map { Self.km($0) / 830 + 0.6 } ?? 0) { h in
                    "\(Int(h))h \(String(format: "%02d", Int((h - floor(h)) * 60)))m"
                }
                .font(.system(size: 14, weight: .medium)).foregroundStyle(Self.ice)
            }
            .animation(.easeOut(duration: 1.2), value: demo.step)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.12), lineWidth: 1))
    }

    private var cards: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { i in
                let p = Self.places[i]
                let on = selected == i
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: p.symbol).font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(on ? Self.amber : .white.opacity(0.7))
                    Spacer(minLength: 0)
                    Text(p.city).font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    Text("¥\(p.price.formatted())").font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 100)
                .background(RoundedRectangle(cornerRadius: 16).fill(on ? Self.amber.opacity(0.14) : .white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(on ? Self.amber : .white.opacity(0.12), lineWidth: on ? 1.5 : 1))
                .shadow(color: Self.amber.opacity(on ? 0.45 : 0), radius: 12)
                .scaleEffect(demo.isPressing(i + 1) ? 0.94 : 1)
                .demoTap(i + 1)
            }
        }
    }

    private var book: some View {
        HStack(spacing: 10) {
            Image(systemName: booked ? "checkmark" : "airplane.departure")
                .contentTransition(.symbolEffect(.replace))
            Text(booked ? "Booked · Cape Town" : "Book flight")
                .contentTransition(.opacity)
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(Color(hex: 0x1A1205))
        .frame(maxWidth: .infinity).frame(height: 54)
        .background(Capsule().fill(booked ? Color(hex: 0x7CE0A3) : Self.amber))
        .shadow(color: (booked ? Color(hex: 0x7CE0A3) : Self.amber).opacity(0.5), radius: 14)
        .scaleEffect(demo.isPressing(4) ? 0.95 : 1)
        .demoTap(4)
    }
}

private struct Stars: View {
    var body: some View {
        Canvas { ctx, size in
            var seed: UInt64 = 7
            func rnd() -> Double { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Double(seed >> 33) / Double(1 << 31) }
            for _ in 0..<140 {
                let x = rnd() * size.width, y = rnd() * size.height, r = 0.4 + rnd() * 1.1
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(0.2 + rnd() * 0.5)))
            }
        }
    }
}

// MARK: - SceneKit globe

private struct GlobeView: UIViewRepresentable {
    let selected: Int?
    let booked: Bool

    func makeCoordinator() -> GlobeScene { GlobeScene() }

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        v.scene = context.coordinator.scene
        v.backgroundColor = .clear
        v.antialiasingMode = .multisampling4X
        v.rendersContinuously = true
        v.isPlaying = true
        v.delegate = context.coordinator
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ v: SCNView, context: Context) {
        context.coordinator.target = selected
        context.coordinator.booked = booked
    }
}

final class GlobeScene: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    var target: Int?
    var booked = false

    private let globe = SCNNode()
    private var arcDots: [SCNNode] = []
    private var arcPoints: [SIMD3<Float>] = []
    private let head = SCNNode()
    private let homePin = SCNNode(), destPin = SCNNode()
    private var shown: Int?? = .none
    private var fromQ = simd_quatf(angle: 0, axis: [0, 1, 0])
    private var currentQ = simd_quatf(angle: 0, axis: [0, 1, 0])
    private var changeT: Double = 0
    private var bookT: Double?
    private let t0 = CACurrentMediaTime()
    private static let arcCount = 90

    override init() {
        super.init()
        let cam = SCNCamera()
        cam.fieldOfView = 38
        cam.wantsHDR = true
        cam.bloomIntensity = 1.1
        cam.bloomThreshold = 0.75
        cam.bloomBlurRadius = 8
        let camNode = SCNNode()
        camNode.camera = cam
        camNode.position = SCNVector3(0, 0, 3.35)
        scene.rootNode.addChildNode(camNode)

        let key = SCNNode()
        key.light = SCNLight()
        key.light!.type = .directional
        key.light!.intensity = 900
        key.eulerAngles = SCNVector3(-0.5, -0.6, 0)
        scene.rootNode.addChildNode(key)
        let amb = SCNNode()
        amb.light = SCNLight()
        amb.light!.type = .ambient
        amb.light!.intensity = 250
        scene.rootNode.addChildNode(amb)

        let sphere = SCNSphere(radius: 0.995)
        sphere.segmentCount = 96
        let m = SCNMaterial()
        m.lightingModel = .lambert
        m.diffuse.contents = UIColor(red: 0.05, green: 0.10, blue: 0.24, alpha: 1)
        m.shaderModifiers = [.fragment: """
            float f = pow(1.0 - saturate(dot(_surface.normal, _surface.view)), 2.6);
            _output.color.rgb += float3(0.25, 0.5, 1.0) * f * 1.1;
            """]
        sphere.firstMaterial = m
        globe.addChildNode(SCNNode(geometry: sphere))
        globe.addChildNode(SCNNode(geometry: Self.landDots()))
        scene.rootNode.addChildNode(globe)

        let dot = SCNSphere(radius: 0.0085)
        dot.segmentCount = 8
        dot.firstMaterial = Self.glow(UIColor(red: 1.6, green: 1.05, blue: 0.4, alpha: 1))
        for _ in 0..<Self.arcCount {
            let n = SCNNode(geometry: dot)
            n.opacity = 0
            globe.addChildNode(n)
            arcDots.append(n)
        }
        let h = SCNSphere(radius: 0.022)
        h.firstMaterial = Self.glow(UIColor(red: 2.2, green: 1.9, blue: 1.4, alpha: 1))
        head.geometry = h
        head.opacity = 0
        globe.addChildNode(head)

        for (pin, color) in [(homePin, UIColor(red: 1.6, green: 1.6, blue: 1.8, alpha: 1)),
                             (destPin, UIColor(red: 1.8, green: 1.2, blue: 0.45, alpha: 1))] {
            let core = SCNSphere(radius: 0.02)
            core.firstMaterial = Self.glow(color)
            pin.addChildNode(SCNNode(geometry: core))
            let ring = SCNTorus(ringRadius: 0.03, pipeRadius: 0.0035)
            ring.firstMaterial = Self.glow(color)
            let rn = SCNNode(geometry: ring)
            rn.name = "ring"
            pin.addChildNode(rn)
            globe.addChildNode(pin)
        }
        place(homePin, lat: OrbitApp.home.lat, lon: OrbitApp.home.lon)
        destPin.opacity = 0
        currentQ = Self.view(lat: 22, lon: 150)
        fromQ = currentQ
    }

    private static func glow(_ c: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = c
        return m
    }

    static func point(lat: Double, lon: Double, r: Float = 1) -> SIMD3<Float> {
        let la = Float(lat * .pi / 180), lo = Float(lon * .pi / 180)
        return SIMD3(r * cos(la) * sin(lo), r * sin(la), r * cos(la) * cos(lo))
    }

    /// Orientation that brings (lat, lon) to face the camera.
    static func view(lat: Double, lon: Double) -> simd_quatf {
        simd_quatf(angle: Float(lat * .pi / 180), axis: [1, 0, 0]) * simd_quatf(angle: Float(-lon * .pi / 180), axis: [0, 1, 0])
    }

    private func place(_ n: SCNNode, lat: Double, lon: Double) {
        let p = Self.point(lat: lat, lon: lon, r: 1.004)
        n.simdPosition = p
        n.simdOrientation = simd_quatf(from: [0, 1, 0], to: simd_normalize(p))
    }

    /// Every land cell as a small hexagon lying flat on the surface.
    private static func landDots() -> SCNGeometry {
        var verts: [SIMD3<Float>] = []
        var idx: [UInt32] = []
        let step = 1.5, r: Float = 0.0066
        var lat = -84.0
        while lat <= 84 {
            let n = max(1, Int(360 * cos(lat * .pi / 180) / step))
            for k in 0..<n {
                let lon = -180 + (Double(k) + 0.5) * 360 / Double(n)
                guard LandMask.isLand(lat: lat, lon: lon) else { continue }
                let p = point(lat: lat, lon: lon, r: 1.001)
                let up = simd_normalize(p)
                let e1 = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), up) + SIMD3(0.0001, 0, 0))
                let e2 = simd_cross(up, e1)
                let base = UInt32(verts.count)
                verts.append(p)
                for s in 0..<6 {
                    let a = Float(s) * .pi / 3
                    verts.append(p + r * (cos(a) * e1 + sin(a) * e2))
                }
                for s in 0..<6 { idx += [base, base + 1 + UInt32(s), base + 1 + UInt32((s + 1) % 6)] }
            }
            lat += step
        }
        let src = SCNGeometrySource(vertices: verts.map { SCNVector3($0.x, $0.y, $0.z) })
        let el = SCNGeometryElement(indices: idx, primitiveType: .triangles)
        let g = SCNGeometry(sources: [src], elements: [el])
        let m = glow(UIColor(red: 0.55, green: 0.74, blue: 1.0, alpha: 1))
        m.isDoubleSided = true
        g.firstMaterial = m
        return g
    }

    private func buildArc(to p: OrbitApp.Place) {
        let a = simd_normalize(Self.point(lat: OrbitApp.home.lat, lon: OrbitApp.home.lon))
        let b = simd_normalize(Self.point(lat: p.lat, lon: p.lon))
        let angle = acos(simd_clamp(simd_dot(a, b), -1, 1))
        let lift = min(0.32, 0.1 + angle * 0.12)
        arcPoints = (0..<Self.arcCount).map { i in
            let s = Float(i) / Float(Self.arcCount - 1)
            let v = simd_normalize((sin((1 - s) * angle) * a + sin(s * angle) * b) / sin(angle))
            return v * (1.005 + lift * sin(.pi * s))
        }
        for (n, q) in zip(arcDots, arcPoints) { n.simdPosition = q; n.opacity = 0 }
        place(destPin, lat: p.lat, lon: p.lon)
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let t = CACurrentMediaTime()
        if shown == .none || shown! != target {
            shown = .some(target)
            fromQ = currentQ
            changeT = t
            if let i = target { buildArc(to: OrbitApp.places[i]) }
            destPin.opacity = 0
            head.opacity = 0
        }
        if booked, bookT == nil { bookT = t }

        // Where the globe faces: drifting idle spin, or the middle of the route.
        let drift = sin((t - t0) * 0.35) * 4
        let goal: simd_quatf
        if let i = target {
            let p = OrbitApp.places[i]
            let a = simd_normalize(Self.point(lat: OrbitApp.home.lat, lon: OrbitApp.home.lon))
            let b = simd_normalize(Self.point(lat: p.lat, lon: p.lon))
            let m = simd_normalize(a + b)
            let lat = Double(asin(m.y)) * 180 / .pi, lon = Double(atan2(m.x, m.z)) * 180 / .pi
            // Look a little off the route's middle so the great circle reads as a curve.
            let span = Double(acos(simd_clamp(simd_dot(a, b), -1, 1))) * 180 / .pi
            let off = max(0, 70 - span / 2) * 0.55
            goal = Self.view(lat: lat - 4 - off, lon: lon + off * 0.8 + drift)
        } else {
            goal = Self.view(lat: 24, lon: 150 - (t - t0) * 7)
        }
        let k = Float(smooth((t - changeT) / 1.7))
        currentQ = target == nil ? goal : simd_slerp(fromQ, goal, k)
        globe.simdOrientation = currentQ

        // The arc draws once the turn is mostly done, then a bright comet runs along it.
        if target != nil {
            let draw = min(1, max(0, (t - changeT - 0.9) / 1.3))
            let speed = bookT == nil ? 0.55 : 1.1
            let comet = draw < 1 ? draw : ((t - changeT - 2.2) * speed).truncatingRemainder(dividingBy: 1.0)
            for (i, n) in arcDots.enumerated() {
                let s = Double(i) / Double(Self.arcCount - 1)
                let near = max(0, 1 - abs(s - comet) * 9)
                n.opacity = s <= draw ? CGFloat(0.35 + 0.65 * near) : 0
                n.scale = SCNVector3(repeating: Float(1 + near * 0.8))
            }
            let hi = min(Self.arcCount - 1, Int(comet * Double(Self.arcCount - 1)))
            head.simdPosition = arcPoints[hi]
            head.opacity = 1
            destPin.opacity = CGFloat(smooth((draw - 0.9) / 0.1))
        }
        for (pin, phase) in [(homePin, 0.0), (destPin, 0.5)] {
            let f = ((t - t0) * 0.8 + phase).truncatingRemainder(dividingBy: 1)
            let boost = pin === destPin && bookT != nil ? 1.6 : 1
            if let ring = pin.childNode(withName: "ring", recursively: false) {
                ring.scale = SCNVector3(repeating: Float(1 + f * 2.2 * boost))
                ring.opacity = CGFloat(1 - f)
            }
        }
    }
}

private extension SCNVector3 {
    init(repeating v: Float) { self.init(v, v, v) }
}
