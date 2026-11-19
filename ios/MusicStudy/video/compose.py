"""Builds music-players.mp4 (1080x1920): all four players playing side by side in a 2x2 grid."""
import subprocess, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
START = [1.700, 1.778, 1.678, 1.965]   # from sync.py: marker gone = board starts entering
D = 18.6                               # full demo, ending on the exit so it loops
E = dict(w=380, h=827, xs=[140, 560], ys=[168, 1031])

inputs = ['-loop', '1', '-t', str(D), '-i', 'endbg.png']
chain = '[0:v]fps=30,format=rgba[b0];'
for i in range(4):
    inputs += ['-i', f'raw{i+1}.mp4']
    chain += (f'[{i+1}:v]trim=start={START[i] - 0.1},setpts=PTS-STARTPTS,fps=30,tpad=stop_mode=clone:stop_duration=6,'
              f'trim=duration={D},scale={E["w"]}:{E["h"]}:flags=lanczos,format=rgba[s{i}];')
inputs += ['-loop', '1', '-i', 'mask_s.png', '-loop', '1', '-i', 'badges.png']
chain += f'[5:v]format=gray,trim=duration={D},split=4[k0][k1][k2][k3];'
for i in range(4):
    chain += f'[s{i}][k{i}]alphamerge[t{i}];[b{i}][t{i}]overlay={E["xs"][i%2]}:{E["ys"][i>>1]}[b{i+1}];'
chain += '[b4][6:v]overlay=0:0:shortest=1,format=yuv420p[out]'
subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', *inputs, '-filter_complex', chain, '-map', '[out]', '-t', str(D),
                '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p', '-r', '30',
                '-movflags', '+faststart', 'music-players.mp4'], check=True)
