"""Renders track.wav: the same song Beat.swift plays, placed where play is pressed in the
composed video (pick a song, then play) and faded out with the exit."""
import numpy as np, wave, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))

SR = 44100
SPB = 0.5
LOOP = 48
ROOTS = np.array([55.0, 43.65, 65.41, 49.0])
ARPS = np.array([[440, 523.25, 659.25, 523.25], [349.23, 440, 523.25, 440],
                 [523.25, 659.25, 783.99, 659.25], [392, 493.88, 587.33, 493.88]])
D = 29.4           # video length
START = 3.70       # play pressed, measured from the recording
END = START + 24.0


def noise(n):
    x = np.sin(n.astype(np.float64) * 12.9898) * 43758.5453
    return (x - np.floor(x)) * 2 - 1


def music(t, n):
    b = t / SPB
    lb = np.mod(b, LOOP)
    sec = np.select([lb < 8, lb < 16, lb < 32, lb < 40], [0, 1, 2, 3], 4)
    frac = lb - np.floor(lb)
    beat_t = frac * SPB
    chord = (lb // 8).astype(int) % 4
    s = np.zeros_like(t)
    kv = np.where(sec == 0, 0.8, 1.0)
    s += np.where(sec != 3, kv * 0.9 * np.exp(-beat_t * 7) * np.sin(2 * np.pi * (45 * beat_t + 75 * (1 - np.exp(-30 * beat_t)) / 30)), 0)
    off = frac >= 0.5
    ot = (frac - 0.5) * SPB
    s += np.where(off, np.where(sec == 3, 0.07, 0.16) * np.exp(-ot * 45) * (noise(n) - noise(n - 1)), 0)
    p = 2 * np.pi * ROOTS[chord] * ot
    s += np.where(off & (sec >= 1) & (sec != 3), 0.5 * np.exp(-ot * 5) * (np.sin(p) + 0.35 * np.sin(2 * p)) * np.minimum(1, ot * 200), 0)
    s += np.where(sec == 3, 0.16 * np.sin(2 * np.pi * ROOTS[chord] * t), 0)
    drop = (sec == 2) | (sec == 4)
    s += np.where(drop & (np.floor(lb).astype(int) % 2 == 1), 0.32 * np.exp(-beat_t * 18) * noise(n), 0)
    sx = lb * 4
    st = (sx - np.floor(sx)) * SPB / 4
    note = ARPS[chord, np.floor(sx).astype(int) % 4]
    s += np.where(sec >= 2, np.where(sec == 3, 0.13, 0.11) * np.exp(-st * 12) * np.sin(2 * np.pi * note * st) * np.minimum(1, st * 300), 0)
    r = (lb - 36) / 4
    s += np.where((lb >= 36) & (lb < 40), 0.13 * r * r * (noise(n) - noise(n - 1)), 0)
    for i in range(3):
        fr = ARPS[chord, i] / 2
        s += np.where(sec == 3, 0.06, 0.035) * np.sin(2 * np.pi * fr * t + i) * (0.8 + 0.2 * np.sin(t * 1.3 + i))
    return np.tanh(s * 0.9)


tv = np.arange(int(D * SR)) / SR
t = tv - START
n = np.round(t * SR).astype(np.int64)
out = np.where((t >= 0) & (tv < END), music(np.maximum(t, 0), n), 0)
# The app leaves 0.2 s before the song ends; let the last bar ring out gently.
fade = np.clip((END + 0.6 - tv) / 1.2, 0, 1)
out *= fade * 0.85
pcm = (np.clip(out, -1, 1) * 32767).astype(np.int16)
stereo = np.repeat(pcm[:, None], 2, axis=1)
with wave.open('track.wav', 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes(stereo.tobytes())
print('track.wav', len(pcm) / SR, 's')
