"""Prints, per raw take, the time the red sync marker disappears (= the board starts entering)."""
import subprocess, re, sys, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
for i in range(1, 5):
    out = subprocess.run(['ffmpeg', '-v', 'quiet', '-i', f'raw{i}.mp4', '-vf',
                          'crop=120:120:0:0,signalstats,metadata=print:key=lavfi.signalstats.VAVG:file=-',
                          '-f', 'null', '-'], capture_output=True, text=True).stdout
    times = re.findall(r'pts_time:([\d.]+)', out)
    vals = [float(v) for v in re.findall(r'VAVG=([\d.]+)', out)]
    on = [float(t) for t, v in zip(times, vals) if v > 180]
    after = [float(t) for t, v in zip(times, vals) if v <= 180 and on and float(t) > on[-1]]
    print(f'{i} {on[0]:.3f} {on[-1]:.3f} {after[0] if after else -1:.3f}')
