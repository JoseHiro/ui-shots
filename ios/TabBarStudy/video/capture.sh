#!/bin/zsh
D=79A63161-C78D-4245-889E-FD795C27996B
OUT=${0:A:h}
APP=/Users/joseysekine/Documents/programming_projects/ui-shots/ios/TabBarStudy/build/Build/Products/Debug-iphonesimulator/TabBarStudy.app
xcrun simctl install $D $APP
for s in 1 2 3 4; do
  xcrun simctl terminate $D com.josehiro.TabBarStudy 2>/dev/null
  /bin/sleep 0.5
  xcrun simctl launch $D com.josehiro.TabBarStudy -style $s -demo YES >/dev/null
  /bin/sleep 1.0
  xcrun simctl io $D recordVideo --codec=h264 --force $OUT/raw$s.mp4 2>/dev/null &
  pid=$!
  /bin/sleep 14.5
  kill -INT $pid; wait $pid
  echo "style $s done"
done
xcrun simctl terminate $D com.josehiro.TabBarStudy
