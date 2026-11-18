# Health Study

Four health and gym trackers, each in its own visual style:

| # | App | What it tracks | Style |
| --- | --- | --- | --- |
| 1 | SET | Gym sets, weight, rest timer | Retro hardware: 7-segment LCD with ghost segments, beveled keys |
| 2 | Sip | Water intake | Claymorphism: puffy pastel shapes, a bottle with a face and live water |
| 3 | Macro | Calories and macros | Bauhaus poster: Futura, primary colors, shapes that fill as you log |
| 4 | Ma (間) | Breathing and practice streak | Sumi ink on washi: brushed ensō, Mincho type, vermilion seal |

Each app's state is a function of one `step` counter. In demo mode (`-style 1...4 -demo YES`) the app taps the target registered with `.demoTap(n)` for each step, using the pauses in its `script`. Without arguments you can swipe between the apps and tap the same targets yourself.

## Video

```
xcodegen generate
xcodebuild -project HealthStudy.xcodeproj -scheme HealthStudy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
video/capture.sh            # simulator must be booted
python3 video/sync.py       # copy the last column into START in compose.py
NODE_PATH=<node_modules with playwright> node video/layers.cjs   # Node 20+, run inside video/
python3 video/compose.py    # -> video/health-apps.mp4 (2x2 grid, loops)
```
