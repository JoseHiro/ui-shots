"""Builds dashboards.mp4 (1080x1920): one scene per board, then a 2x2 end card."""
import subprocess, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
START = [1.635, 1.815, 1.797, 1.802]   # from sync.py: marker gone = board starts entering
D, X, END = 8.8, 0.4, 3.0              # scene length, crossfade, end card length
P = (170, 176, 740, 1609)
E = dict(w=360, h=783, xs=[160, 560], ys=[236, 1062])

def ff(*a): subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', *a], check=True)
enc = ['-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p', '-r', '30']

for i in range(4):
    s = START[i] - 0.1
    ff('-loop', '1', '-t', str(D), '-i', 'bg.png', '-i', f'raw{i+1}.mp4', '-loop', '1', '-i', 'mask.png',
       '-loop', '1', '-i', f'label{i+1}.png',
       '-filter_complex',
       f'[1:v]trim=start={s},setpts=PTS-STARTPTS,fps=30,tpad=stop_mode=clone:stop_duration=3,trim=duration={D},'
       f'scale={P[2]}:{P[3]}:flags=lanczos,format=rgba[ph];[2:v]format=gray,trim=duration={D}[m];[ph][m]alphamerge[phm];'
       f'[0:v]fps=30,format=rgba[bg];[bg][phm]overlay={P[0]}:{P[1]}[a];[a][3:v]overlay=0:0:shortest=1,format=yuv420p[out]',
       '-map', '[out]', '-t', str(D), *enc, f'scene{i+1}.mp4')
    # Last frame of the scene's phone (simctl only writes frames on change, so pad like the scene does).
    ff('-i', f'raw{i+1}.mp4', '-vf', f'trim=start={s},setpts=PTS-STARTPTS,fps=30,tpad=stop_mode=clone:stop_duration=3,trim=duration={D}',
       '-update', '1', f'still{i+1}.png')

inputs, chain = ['-loop', '1', '-i', 'endbg.png'], '[0:v]format=rgba[b0];'
for i in range(4):
    inputs += ['-i', f'still{i+1}.png']
    chain += f'[{i+1}:v]scale={E["w"]}:{E["h"]}:flags=lanczos,format=rgba[s{i}];'
inputs += ['-i', 'mask_s.png', '-i', 'badges.png']
chain += '[5:v]format=gray,split=4[k0][k1][k2][k3];'
for i in range(4):
    chain += f'[s{i}][k{i}]alphamerge[t{i}];[b{i}][t{i}]overlay={E["xs"][i%2]}:{E["ys"][i>>1]}[b{i+1}];'
chain += '[b4][6:v]overlay=0:0,fps=30,format=yuv420p[out]'
ff(*inputs, '-filter_complex', chain, '-map', '[out]', '-t', str(END), *enc, 'end.mp4')

clips = [f'scene{i+1}.mp4' for i in range(4)] + ['end.mp4']
args, fc, prev, off = [], [], '0:v', 0.0
for c in clips: args += ['-i', c]
for i in range(1, len(clips)):
    off += D - X
    trans = 'fade' if i == 4 else 'smoothleft'
    fc.append(f'[{prev}][{i}:v]xfade=transition={trans}:duration={X}:offset={off:.3f}[x{i}]')
    prev = f'x{i}'
ff(*args, '-filter_complex', ';'.join(fc), '-map', f'[{prev}]', *enc, '-movflags', '+faststart', 'dashboards.mp4')
