import AVFoundation
import SwiftUI

/// One 24-second song at 120 BPM, shared by all four apps. The visuals read the same
/// envelopes the synth plays, so every ripple, grain, spike and flame lands on the beat.
/// (video/track.py renders the identical song for the recording.)
///
/// Beats  0-7   intro: kick, hats, pad
/// Beats  8-15  + bass
/// Beats 16-31  drop: + clap and arpeggio
/// Beats 32-39  breakdown: no kick, soft bass, rising noise into...
/// Beats 40-47  the last drop
enum Beat {
    static let bpm = 120.0
    static let spb = 60 / bpm
    static let loop = 48.0
    static let length = loop * spb
    /// The demo's steps: 1 picks a song, 2 presses play.
    static let playStep = 2
    /// Bass roots per two bars: A1, F1, C2, G1.
    static let roots: [Double] = [55.0, 43.65, 65.41, 49.0]
    /// Arpeggio notes per two bars (Am, F, C, G).
    static let arps: [[Double]] = [[440, 523.25, 659.25, 523.25], [349.23, 440, 523.25, 440],
                                   [523.25, 659.25, 783.99, 659.25], [392, 493.88, 587.33, 493.88]]

    struct Track {
        let title: String
        let artist: String
        /// The same song moved up or down, so each pick sounds different when played by hand.
        let pitch: Double
    }
    static let library: [Track] = [
        Track(title: "Low Tide", artist: "Harbor Lights", pitch: 0.8909),
        Track(title: "Afterglow", artist: "Mika Sato", pitch: 1),
        Track(title: "Paper Moon", artist: "The Quiet Hours", pitch: 1.1225),
        Track(title: "Static Bloom", artist: "Northwind", pitch: 0.9439),
    ]
    static let demoTrack = 1

    struct Levels {
        var playing = false
        var beat = 0.0          // beats since play
        var kick = 0.0          // 0...1, spikes on every beat
        var hat = 0.0
        var clap = 0.0
        var bass = 0.0
        var arp = 0.0           // 16th-note plucks from the drop on
        var energy = 0.0        // slow section level
        var build = 0.0         // 0 → 1 over the four beats before the last drop
        var chord = 0           // which two bars we are in (0...3)
        var section = 0         // 0 intro, 1 groove, 2 drop, 3 breakdown, 4 last drop
    }

    static func section(_ lb: Double) -> Int {
        lb < 8 ? 0 : lb < 16 ? 1 : lb < 32 ? 2 : lb < 40 ? 3 : 4
    }

    private static let starts: [Double] = [0, 8, 16, 32, 40]
    private static let levelOf: [Double] = [0.35, 0.65, 1, 0.38, 1]

    static func levels(_ t: Double?) -> Levels {
        guard let t, t >= 0 else { return Levels() }
        let b = t / spb
        let lb = b.truncatingRemainder(dividingBy: loop)
        let sec = section(lb)
        var l = Levels(playing: true, beat: b)
        let frac = lb - floor(lb)
        let sinceBeat = frac * spb
        let quiet = sec == 3
        l.kick = quiet ? 0 : exp(-sinceBeat * 7) * (sec == 0 ? 0.8 : 1)
        let off = frac >= 0.5 ? (frac - 0.5) * spb : 99
        l.hat = exp(-off * 28) * (quiet ? 0.3 : 0.7)
        if sec >= 1 { l.bass = quiet ? 0.3 : exp(-off * 5) * 0.9 + 0.1 }
        if sec == 2 || sec == 4 { l.clap = Int(floor(lb)) % 2 == 1 ? exp(-sinceBeat * 9) : 0 }
        if sec >= 2 {
            let sx = lb * 4
            l.arp = exp(-(sx - floor(sx)) * spb / 4 * 12) * (quiet ? 0.7 : 0.5)
        }
        l.build = lb >= 36 && lb < 40 ? pow((lb - 36) / 4, 2) : 0
        let prev = sec == 0 ? 0 : levelOf[sec - 1]
        l.energy = prev + (levelOf[sec] - prev) * smooth((lb - starts[sec]) / 1.2) + l.build * 0.5
        l.chord = Int(lb / 8) % 4
        l.section = sec
        return l
    }

    // MARK: - Synth (the same maths as video/track.py)

    static func sample(_ t: Double, _ n: Int, pitch: Double = 1) -> Double {
        let b = t / spb
        let lb = b.truncatingRemainder(dividingBy: loop)
        let sec = section(lb)
        let frac = lb - floor(lb)
        let beatT = frac * spb
        let chord = Int(lb / 8) % 4
        var s = 0.0
        // Kick: sine falling from 120 Hz to 45 Hz. Rests in the breakdown.
        if sec != 3 {
            let kv = sec == 0 ? 0.8 : 1
            s += kv * 0.9 * exp(-beatT * 7) * sin(2 * .pi * (45 * beatT + 75 * (1 - exp(-30 * beatT)) / 30))
        }
        // Hat and bass on the off-beats.
        if frac >= 0.5 {
            let ot = (frac - 0.5) * spb
            s += (sec == 3 ? 0.07 : 0.16) * exp(-ot * 45) * (noise(n) - noise(n - 1))
            if sec >= 1 && sec != 3 {
                let p = 2 * Double.pi * roots[chord] * pitch * ot
                s += 0.5 * exp(-ot * 5) * (sin(p) + 0.35 * sin(2 * p)) * min(1, ot * 200)
            }
        }
        if sec == 3 { s += 0.16 * sin(2 * .pi * roots[chord] * pitch * t) }
        if sec == 2 || sec == 4 {
            if Int(floor(lb)) % 2 == 1 { s += 0.32 * exp(-beatT * 18) * noise(n) }
        }
        if sec >= 2 {
            let sx = lb * 4
            let st = (sx - floor(sx)) * spb / 4
            let note = arps[chord][Int(floor(sx)) % 4] * pitch
            s += (sec == 3 ? 0.13 : 0.11) * exp(-st * 12) * sin(2 * .pi * note * st) * min(1, st * 300)
        }
        // Rising noise into the last drop.
        if lb >= 36 && lb < 40 {
            let r = (lb - 36) / 4
            s += 0.13 * r * r * (noise(n) - noise(n - 1))
        }
        // Soft pad: the chord's root, third and fifth, low and quiet.
        let a = arps[chord]
        for (i, f) in [a[0] / 2, a[1] / 2, a[2] / 2].enumerated() {
            s += (sec == 3 ? 0.06 : 0.035) * sin(2 * .pi * f * pitch * t + Double(i)) * (0.8 + 0.2 * sin(t * 1.3 + Double(i)))
        }
        return tanh(s * 0.9)
    }

    /// Repeatable white noise in -1...1.
    static func noise(_ n: Int) -> Double {
        let x = sin(Double(n) * 12.9898) * 43758.5453
        return (x - floor(x)) * 2 - 1
    }
}

/// Plays the song for real when the app is used by hand (the recording uses track.py instead).
final class BeatPlayer {
    static let shared = BeatPlayer()
    private let engine = AVAudioEngine()
    private var n = 0
    private var pitch = 1.0

    func start(track: Int) {
        pitch = Beat.library[track].pitch
        guard !engine.isRunning else { return }
        let sr = 44_100.0
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        let node = AVAudioSourceNode(format: fmt) { [unowned self] _, _, count, abl -> OSStatus in
            let buf = UnsafeMutableAudioBufferListPointer(abl)
            let out = buf[0].mData!.assumingMemoryBound(to: Float.self)
            for i in 0..<Int(count) {
                out[i] = Float(Beat.sample(Double(n) / sr, n, pitch: pitch))
                n += 1
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: fmt)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? engine.start()
    }

    func stop() { engine.stop() }
}

extension Demo {
    /// Seconds since play was pressed, nil before.
    func playTime(_ now: Date) -> Double? {
        guard let s = stepDate[Beat.playStep] else { return nil }
        return now.timeIntervalSince(s)
    }

    var chosen: Beat.Track { Beat.library[track] }
}

/// "0:07 / -0:17" progress for the player screens.
struct Progress {
    let t: Double?
    var fraction: Double { min(1, max(0, (t ?? 0) / Beat.length)) }
    var elapsed: String { clock(min(Beat.length, t ?? 0)) }
    var remaining: String { "-" + clock(Beat.length - min(Beat.length, t ?? 0)) }
}
