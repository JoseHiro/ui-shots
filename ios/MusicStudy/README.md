# Music Study

Four music players, each in its own visual style:

| # | App | Format | Style |
| --- | --- | --- | --- |
| 1 | Platter | Vinyl | Walnut turntable: the record spins with inertia, the tonearm swings in, sleeves from the crate swap the record |
| 2 | Tape | Cassette | 80s deck: tape moves between spools, VU needles, mechanical counter, latching piano keys, flips to side B |
| 3 | Mono | Minimal | Off-white Helvetica, one orange accent; the waveform is the scrubber and morphs between songs |
| 4 | Pulse | Neon | Synthwave: glowing radial spectrum on the beat, scrolling laser grid, modes change tempo and colors |

Each app's state is a function of one `step` counter, and anything that spins or keeps time uses `Motor` (speed eases toward each new target, so nothing jumps). In demo mode (`-style 1...4 -demo YES`) the app taps the target registered with `.demoTap(n)` for each step, using the pauses in its `script`. Without arguments you can swipe between the apps and tap the same targets yourself.

## Video

```
xcodegen generate
xcodebuild -project MusicStudy.xcodeproj -scheme MusicStudy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
video/capture.sh            # simulator must be booted
python3 video/sync.py       # copy the last column into START in compose.py
NODE_PATH=<node_modules with playwright> node video/layers.cjs   # Node 20+, run inside video/
python3 video/compose.py    # -> video/music-players.mp4 (2x2 grid, loops)
```
