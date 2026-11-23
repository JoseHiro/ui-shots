# Message Study

Four messaging apps, each in its own visual style, all built around sending a message and seeing it read:

| # | App | What it does | Style |
| --- | --- | --- | --- |
| 1 | Bubble | Chat with a friend | Playful and bouncy: bubbles land with squash-and-stretch, receipts go Sent → Delivered → Read, a heart reaction bursts out, a sticker throws confetti |
| 2 | Letter | Slow mail | Paper and kraft envelopes: the note writes itself, folds into thirds in 3D, is sealed with wax and posted; "read" is the seal being broken, then the reply arrives and unfolds |
| 3 | Terminal | Chat as a CLI session | Phosphor CRT: lines stream in, receipts update in place like progress bars, a photo arrives as ASCII art |
| 4 | Pager | 90s Japanese pocket bell | Number codes (0840 = おはよう, 14106 = アイシテル) punched in on a payphone keypad and decoded on a buzzing LCD with 未読 / 既読 |

Each app's state is a function of one `step` counter plus the time since each step. In demo mode (`-style 1...4 -demo YES`) the app taps the target registered with `.demoTap(n)` for each step, using the pauses in its `script`. Without arguments you can swipe between the apps and tap the same targets yourself.

## Video

```
xcodegen generate
xcodebuild -project MessageStudy.xcodeproj -scheme MessageStudy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
video/capture.sh            # simulator must be booted
python3 video/sync.py       # copy the last column into START in compose.py
NODE_PATH=<node_modules with playwright> node video/layers.cjs   # Node 20+, run inside video/
python3 video/compose.py    # -> video/message-apps.mp4 (2x2 grid, loops)
```
