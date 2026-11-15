import subprocess, sys
F='/System/Library/Fonts/SFNSRounded.ttf'
M=[1.983333,2.166667,2.328333,2.168333]
N=["Liquid Dock","Bubble Notch","Soft Pill","Color Chips"]
D=10.8; R=34
alpha=f"if(gt(abs(X-W/2),W/2-{R})*gt(abs(Y-H/2),H/2-{R}),if(lte(hypot(abs(X-W/2)-(W/2-{R}),abs(Y-H/2)-(H/2-{R})),{R}),255,0),255)"
fc=[]
for i in range(4):
    st=M[i]-0.2
    fc.append(f"[{i+1}:v]trim=start={st},setpts=PTS-STARTPTS,fps=30,tpad=stop_mode=clone:stop_duration=2,trim=duration={D},"
              f"crop=1206:432:0:2190,scale=1032:370:flags=lanczos,"
              f"format=rgba,geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='{alpha}'[r{i+1}]")
fc.append("[0:v]fps=30,format=rgba[bg]")
prev='bg'
for i in range(4):
    out=f"o{i}"
    fc.append(f"[{prev}][r{i+1}]overlay=24:{150+i*440+60}[{out}]"); prev=out
fc.append("[o3][5:v]overlay=0:0,format=yuv420p[out]")
cmd=['ffmpeg','-loglevel','error','-y','-loop','1','-t',str(D),'-i','bg.png']
for i in range(4): cmd+=['-i',f'raw{i+1}.mp4']
cmd+=['-i','labels.png']
cmd+=['-filter_complex',';'.join(fc),'-map','[out]','-pix_fmt','yuv420p','-c:v','libx264','-preset','slow','-crf','16','-r','30','-movflags','+faststart','tabbars.mp4']
subprocess.run(cmd,check=True)
