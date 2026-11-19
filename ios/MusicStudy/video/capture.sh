#!/bin/zsh
# Records each player's demo on the iPhone 17 Pro simulator (must be booted).
D=79A63161-C78D-4245-889E-FD795C27996B
OUT=${0:A:h}
APP=${0:A:h:h}/build/Build/Products/Debug-iphonesimulator/MusicStudy.app
xcrun simctl install $D $APP
for s in 1 2 3 4; do
  xcrun simctl terminate $D com.josehiro.MusicStudy 2>/dev/null
  /bin/sleep 0.5
  xcrun simctl launch $D com.josehiro.MusicStudy -style $s -demo YES >/dev/null
  /bin/sleep 0.4
  xcrun simctl io $D recordVideo --codec=h264 --force $OUT/raw$s.mp4 2>/dev/null &
  pid=$!
  /bin/sleep 24
  kill -INT $pid; wait $pid
  echo "style $s done"
done
xcrun simctl terminate $D com.josehiro.MusicStudy
