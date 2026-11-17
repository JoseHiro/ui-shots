# Dashboard Study

Four SwiftUI dashboards, each for a different kind of app:

| # | Board | App | Look |
| --- | --- | --- | --- |
| 1 | Ledger | Private banking | Near-black, champagne gold, serif numerals; scrubbing rewrites net worth |
| 2 | Hearth | Home energy | Warm paper cards, live energy-flow diagram, usage vs solar bars |
| 3 | Lull | Sleep | Dusk gradient with stars, score ring, stage-colored hypnogram |
| 4 | Reach | Creator analytics | Swiss editorial: hairlines, compressed figures, cobalt bars with a coral peak |

Run without arguments to swipe between the boards. Launch with `-style 1...4 -demo YES` to play the recording sequence: entrance, range switch, chart scrub, range switch.

## Video

```
xcodegen generate
xcodebuild -project DashboardStudy.xcodeproj -scheme DashboardStudy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
video/capture.sh            # simulator must be booted
python3 video/sync.py       # update START in compose.py with the last column
NODE_PATH=<path to node_modules with playwright> node video/layers.cjs   # run inside video/
python3 video/compose.py    # -> video/dashboards.mp4 (2x2 grid, all four playing together)
```
