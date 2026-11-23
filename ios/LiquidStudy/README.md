# Liquid Study

Four music players, each built around a different liquid on a normal iPhone screen. Each opens on its own song picker; the chosen record moves to the middle and the liquid reacts to the song. All four play the same 24-second song at 120 BPM from `Beat.swift`, and the visuals follow its envelopes.

| # | App | Picker | Liquid |
| --- | --- | --- | --- |
| 1 | Water | Four sleeves floating in a swimming pool | Tiles and a lane line wobble under the surface, caustics move across the floor, the sun glitters on the waves, and every kick sends a ring out from under the sleeve (Metal `layerEffect`) |
| 2 | Mercury | Four chrome droplets, one per record | The droplets roll together and merge into one pool that mirrors the sleeve hanging above it; kicks and touches bend the reflection (Metal `colorEffect`, metaballs) |
| 3 | Honey | A cluster of honeycomb cells | Honey hangs from the top, drips stretch down over the sleeve on the beat, let go and fill a rising pool; a touch drops a slow-sliding dab (Metal `layerEffect`, signed distances) |
| 4 | Ink | Four marbled targets in four inks | Suminagashi: every kick drops ink or clear water into the centre and pushes the older rings outward; touches swirl them (Metal `colorEffect`) |

Each app's state is a function of one `step` counter plus the time since each step. In demo mode (`-style 1...4 -demo YES`) the app taps the target registered with `.demoTap(n)` for each step.

Building the shaders needs Xcode's Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`).

## Video

```
xcodegen generate
xcodebuild -project LiquidStudy.xcodeproj -scheme LiquidStudy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
video/capture.sh            # simulator must be booted
python3 video/sync.py       # copy the last column into START in compose.py
python3 video/track.py      # -> video/track.wav
NODE_PATH=<node_modules with playwright> node video/layers.cjs   # Node 20+, run inside video/
python3 video/compose.py    # -> video/liquid-apps.mp4 (2x2 grid with sound)
```
