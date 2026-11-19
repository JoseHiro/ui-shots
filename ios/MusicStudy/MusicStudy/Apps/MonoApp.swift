import SwiftUI

/// Mono: a minimal player. Off-white paper, Helvetica, one orange accent.
/// The waveform is the scrubber, and it morphs into the next song's shape.
struct MonoApp: View {
    @EnvironmentObject var demo: Demo

    static let paper = Color(hex: 0xF2F1EC)
    static let ink = Color(hex: 0x111111)
    static let mute = Color(hex: 0xCBC9C2)
    static let accent = Color(hex: 0xFF4A1C)
    static func helv(_ s: CGFloat, _ w: String = "Medium") -> Font { .custom("HelveticaNeue-\(w)", size: s) }

    /// Pause before each step: play, seek, save, next, next.
    static let script: [Double] = [1.8, 2.6, 2.0, 2.4, 3.2]
    static let seekTo = 0.68

    struct Track { let title: String; let album: String; let length: Double; let seed: Double }
    static let tracks = [
        Track(title: "Paper Moons", album: "Quiet Rooms", length: 223, seed: 1.3),
        Track(title: "Concrete Bloom", album: "Quiet Rooms", length: 198, seed: 4.1),
        Track(title: "Low Season", album: "Quiet Rooms", length: 241, seed: 7.7),
    ]

    static func wave(_ seed: Double) -> [Double] {
        (0..<54).map { i in
            let t = Double(i)
            let v = 0.42 + 0.28 * sin(t * 0.37 + seed) + 0.2 * sin(t * 1.9 + seed * 2) + 0.14 * sin(t * 0.11 + seed * 3)
            return min(1, max(0.1, v))
        }
    }

    private var track: Int { max(0, demo.step - 3) }

    /// Seconds into the current track at `now`.
    private func elapsed(_ now: Date) -> Double {
        guard demo.step >= 1, let d1 = demo.stepDate[1] else { return 48 }
        switch demo.step {
        case 1:
            return 48 + now.timeIntervalSince(d1)
        case 2, 3:
            guard let d2 = demo.stepDate[2] else { return 48 }
            let before = 48 + d2.timeIntervalSince(d1)
            let target = Self.seekTo * Self.tracks[0].length
            return before + (target - before) * smooth(now.timeIntervalSince(d2) / 0.5) + now.timeIntervalSince(d2)
        default:
            return demo.stepDate[demo.step].map { now.timeIntervalSince($0) } ?? 0
        }
    }

    var body: some View {
        ZStack {
            Self.paper.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                top.reveal(0)
                art.reveal(1).padding(.top, 16)
                titles.reveal(2).padding(.top, 24)
                waveform.reveal(3).padding(.top, 24)
                controls.reveal(4).padding(.top, 26)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
        .preferredColorScheme(.light)
    }

    private var top: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Mono").font(Self.helv(15, "Bold"))
                Spacer()
                Text("Now playing").font(Self.helv(13, "Light"))
                Spacer()
                Text("\(track + 1) / 12").font(Self.helv(13, "Light")).monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundStyle(Self.ink)
            Rectangle().fill(Self.ink).frame(height: 1)
        }
    }

    private var art: some View {
        ZStack {
            MonoArt(kind: track)
                .id(track)
                .transition(.push(from: .trailing))
        }
        .frame(height: 362)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var titles: some View {
        let t = Self.tracks[track]
        return HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(t.title).font(Self.helv(40)).kerning(-1.2).foregroundStyle(Self.ink)
                Text("Ilse Varga — \(t.album)").font(Self.helv(16, "Light")).foregroundStyle(Self.ink.opacity(0.6))
            }
            .id(track)
            .transition(.push(from: .trailing))
            Spacer(minLength: 0)
        }
        .clipped()
    }

    private var waveform: some View {
        let t = Self.tracks[track]
        return VStack(spacing: 8) {
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Bars(data: Vec(v: Self.wave(t.seed))).fill(Self.mute)
                    Bars(data: Vec(v: Self.wave(t.seed))).fill(Self.ink)
                        .mask(alignment: .leading) {
                            TimelineView(.animation) { tl in
                                Rectangle().frame(width: w * min(1, elapsed(tl.date) / t.length))
                            }
                        }
                    TimelineView(.animation) { tl in
                        Rectangle().fill(Self.accent).frame(width: 2, height: 64)
                            .offset(x: w * min(1, elapsed(tl.date) / t.length) - 1)
                    }
                    Color.clear.frame(width: 30, height: 60)
                        .demoTap(2)
                        .offset(x: w * Self.seekTo - 15)
                }
            }
            .frame(height: 64)
            TimelineView(.animation) { tl in
                let e = elapsed(tl.date)
                HStack {
                    Text(clock(e))
                    Spacer()
                    Text("-" + clock(t.length - e))
                }
                .font(Self.helv(12)).monospacedDigit().foregroundStyle(Self.ink.opacity(0.55))
            }
        }
    }

    private var controls: some View {
        let saved = demo.step == 3
        return HStack {
            VStack(spacing: 4) {
                Image(systemName: saved ? "heart.fill" : "heart")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(saved ? Self.accent : Self.ink)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: saved)
                Text(saved ? "Saved" : "Save").font(Self.helv(10)).foregroundStyle(Self.ink.opacity(0.55))
            }
            .frame(width: 46)
            .demoTap(3)
            Spacer()
            Image(systemName: "backward.end.fill").font(.system(size: 20)).foregroundStyle(Self.ink)
            Spacer()
            ZStack {
                Circle().fill(Self.ink)
                Image(systemName: demo.step >= 1 ? "pause.fill" : "play.fill")
                    .font(.system(size: 26)).foregroundStyle(Self.paper)
                    .offset(x: demo.step >= 1 ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 78, height: 78)
            .scaleEffect(demo.isPressing(1) ? 0.9 : 1)
            .demoTap(1)
            Spacer()
            Image(systemName: "forward.end.fill").font(.system(size: 20)).foregroundStyle(Self.ink)
                .scaleEffect(demo.isPressing(4, 5) ? 0.8 : 1)
                .frame(width: 44, height: 44)
                .demoTap(4, 5)
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "list.bullet").font(.system(size: 20))
                Text("Queue").font(Self.helv(10)).foregroundStyle(Self.ink.opacity(0.55))
            }
            .foregroundStyle(Self.ink)
            .frame(width: 46)
        }
    }
}

/// Vertical bars mirrored around the middle, like a waveform.
private struct Bars: Shape {
    var data: Vec
    var animatableData: Vec {
        get { data }
        set { data = newValue }
    }
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = data.v.count
        guard n > 0 else { return p }
        let step = r.width / CGFloat(n)
        let w = step * 0.46
        for (i, v) in data.v.enumerated() {
            let h = max(3, r.height * CGFloat(v))
            p.addRoundedRect(in: CGRect(x: r.minX + CGFloat(i) * step + (step - w) / 2, y: r.midY - h / 2, width: w, height: h),
                             cornerSize: CGSize(width: w / 2, height: w / 2))
        }
        return p
    }
}

/// Flat geometric covers, one per track.
private struct MonoArt: View {
    let kind: Int
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                switch kind {
                case 0:
                    Color(hex: 0xE4E2DB)
                    Circle().fill(MonoApp.accent).frame(width: 250, height: 250).position(x: w - 70, y: h * 0.55)
                    Rectangle().fill(MonoApp.ink).frame(width: 150, height: 7).position(x: 75, y: h * 0.62)
                    Circle().fill(MonoApp.ink).frame(width: 26, height: 26).position(x: 46, y: 50)
                case 1:
                    MonoApp.ink
                    Circle().fill(MonoApp.paper).frame(width: 300, height: 300).position(x: w / 2, y: h + 20)
                    Rectangle().fill(MonoApp.accent).frame(width: 44, height: 44).position(x: w - 52, y: 52)
                default:
                    MonoApp.accent
                    ForEach(0..<3, id: \.self) { i in
                        Rectangle().fill(MonoApp.ink)
                            .frame(width: 36, height: CGFloat(110 + i * 55))
                            .position(x: CGFloat(48 + i * 52), y: h - CGFloat(110 + i * 55) / 2)
                    }
                    Circle().fill(MonoApp.paper).frame(width: 64, height: 64).position(x: w - 70, y: 74)
                }
                Text(MonoApp.tracks[kind].title.uppercased())
                    .font(MonoApp.helv(10, "Bold")).kerning(2)
                    .foregroundStyle(kind == 0 ? MonoApp.ink : kind == 1 ? MonoApp.accent : MonoApp.paper)
                    .padding(14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }
}
