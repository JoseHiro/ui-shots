# Travel Study

Four travel apps, each in its own visual style, some with real or faked 3D:

| # | App | What it does | Style |
| --- | --- | --- | --- |
| 1 | Orbit | Flight search from Tokyo | Real 3D dot globe (SceneKit, bloom): turns to each route and draws a glowing great-circle arc |
| 2 | Gate | Departures and boarding pass | Airport signage: split-flap board whose letters flip in 3D, pass that turns over to its code and loses its stub |
| 3 | Isle | Island trip planner | Pastel isometric island: camera flies to each spot, buildings pop out of the ground, route draws itself |
| 4 | Postcard | Travel scrapbook | Paper, washi tape and polaroids: a photo drops in and develops, the postcard flips, writes itself, is postmarked and sent |

Each app's state is a function of one `step` counter. In demo mode (`-style 1...4 -demo YES`) the app taps the target registered with `.demoTap(n)` for each step, using the pauses in its `script`. Without arguments you can swipe between the apps and tap the same targets yourself.

`Apps/LandMask.swift` is a coarse 1° land/sea grid (360 × 180 bits) used to place the globe's dots.

## Video

```
xcodegen generate
xcodebuild -project TravelStudy.xcodeproj -scheme TravelStudy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
video/capture.sh            # simulator must be booted
python3 video/sync.py       # copy the last column into START in compose.py
NODE_PATH=<node_modules with playwright> node video/layers.cjs   # Node 20+, run inside video/
python3 video/compose.py    # -> video/travel-apps.mp4 (2x2 grid, loops)
```
