# Beat Study

Four music apps where the screen reacts to the beat, each made of a different material. Each opens on its own song picker (a record crate, a list of Chladni figures, a tape shelf, a choice of moods); the chosen song flies into the player. All four play the same 24-second song at 120 BPM from `Beat.swift` (intro, bass, drop, a quiet breakdown, a build and a last drop), and the visuals read the same envelopes the synth plays.

| # | App | What it does | Material |
| --- | --- | --- | --- |
| 1 | Water | Pick a sleeve from the crate; the water rises over the turntable | Every kick sends a ring out from the spindle, the album sleeve is mirrored in the surface, a finger on the water makes its own ripple (Metal `layerEffect`) |
| 2 | Sand | Every song has its own figure; its little plate grows into the big one | Grains shiver on every kick and gather on the plate's still lines (Chladni figures); each bass note draws a new figure, a tap throws the sand up |
| 3 | Ferro | A tape slides off the shelf into the deck, over a dish of ferrofluid | A glossy black puddle grows spikes with the bass and crawls after the magnet when you tap the dish (Metal `colorEffect`) |
| 4 | Fire | Pick tonight's mood; a flame flies off the card into the fireplace | Embers catch on play, flames jump on the kick, sparks fly on the claps, the room breathes with the music; poking the fire throws up a shower of sparks (Metal `colorEffect`) |

The real apps this was inspired by listen through the microphone. Here the visuals follow the loop's own clock instead, so they stay exactly on the beat in the recording. Played by hand (no arguments) the loop really plays through `AVAudioEngine`.

Each app's state is a function of one `step` counter plus the time since each step. In demo mode (`-style 1...4 -demo YES`) the app taps the target registered with `.demoTap(n)` for each step, using the pauses in its `script`.

Building the shaders needs Xcode's Metal Toolchain (`xcodebuild -downloadComponent MetalToolchain`).

## Video

```
xcodegen generate
xcodebuild -project BeatStudy.xcodeproj -scheme BeatStudy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
video/capture.sh            # simulator must be booted
python3 video/sync.py       # copy the last column into START in compose.py
python3 video/track.py      # -> video/track.wav, the same song placed where play is pressed
NODE_PATH=<node_modules with playwright> node video/layers.cjs   # Node 20+, run inside video/
python3 video/compose.py    # -> video/beat-apps.mp4 (2x2 grid with sound, loops)
```
