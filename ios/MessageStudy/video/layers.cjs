// Renders the still layers for the video: studio background, per-scene labels,
// phone masks and the end card background. Run with NODE_PATH pointing at a playwright install.
const { chromium } = require('playwright');
const font = '<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Inter:wght@500;600;700&display=swap" rel="stylesheet">';
const base = `html,body{margin:0;width:1080px;height:1920px}body{font-family:Inter,sans-serif}`;
const studio = `background:radial-gradient(120% 70% at 50% 35%,#F6F4EF 0%,#E9E6DF 70%,#E1DDD4 100%)`;
const P = { x: 170, y: 176, w: 740, h: 1609, r: 102 };
const boards = [
  ['Bubble', 'Bouncy', '#7C5CFF'], ['Letter', 'Snail mail', '#A3271F'],
  ['Terminal', 'CLI', '#22B864'], ['Pager', '90s Japan', '#FF8A5B'],
];
const scene = (i) => `${font}<style>${base}
.k{position:absolute;left:${P.x}px;top:46px;font-size:22px;font-weight:600;letter-spacing:4px;color:#8A867C}
.k b{color:${boards[i][2]}}
.t{position:absolute;left:${P.x - 4}px;top:74px;font-family:'Instrument Serif',serif;font-style:italic;font-size:84px;line-height:1;color:#16151A}
.t span{font-family:Inter;font-style:normal;font-size:30px;font-weight:500;color:#7A766D;margin-left:18px;letter-spacing:0}
</style><div class="k"><b>0${i + 1}</b>&nbsp;/ 04 &nbsp;·&nbsp; SWIFTUI MESSAGING APPS</div>
<div class="t">${boards[i][0]}<span>${boards[i][1]}</span></div>`;
const bg = `<style>${base}body{${studio}}.p{position:absolute;left:${P.x}px;top:${P.y}px;width:${P.w}px;height:${P.h}px;border-radius:${P.r}px;
box-shadow:0 40px 90px rgba(40,30,10,.22),0 10px 24px rgba(40,30,10,.12)}</style><div class="p"></div>`;
const mask = (w, h, r) => `<style>html,body{margin:0;width:${w}px;height:${h}px;background:#000}div{width:${w}px;height:${h}px;border-radius:${r}px;background:#fff}</style><div></div>`;
const E = { w: 380, h: 827, r: 52, xs: [140, 560], ys: [168, 1031] };
const end = `${font}<style>${base}body{${studio}}
h1{margin:0;position:absolute;top:66px;width:100%;text-align:center;font-family:'Instrument Serif',serif;font-style:italic;font-weight:400;font-size:58px;color:#16151A;line-height:1}
.p{position:absolute;width:${E.w}px;height:${E.h}px;border-radius:${E.r}px;box-shadow:0 26px 60px rgba(40,30,10,.22)}
.n{position:absolute;width:56px;height:56px;border-radius:50%;display:grid;place-items:center;color:#fff;font-weight:700;font-size:26px;box-shadow:0 6px 16px rgba(0,0,0,.2)}
</style><h1>Which one would you use?</h1>` +
  boards.map((b, i) => { const x = E.xs[i % 2], y = E.ys[i >> 1];
    return `<div class="p" style="left:${x}px;top:${y}px"></div>`; }).join('');
const badges = `${font}<style>${base}.n{position:absolute;height:50px;padding:0 20px 0 6px;border-radius:25px;display:flex;align-items:center;gap:10px;
background:#fff;font-family:Inter;font-weight:600;font-size:24px;color:#16151A;box-shadow:0 6px 16px rgba(0,0,0,.18)}
.n i{font-style:normal;width:38px;height:38px;border-radius:50%;display:grid;place-items:center;color:#fff;font-weight:700;font-size:20px}</style>` +
  boards.map((b, i) => { const x = E.xs[i % 2], y = E.ys[i >> 1];
    return `<div class="n" style="left:${x + E.w / 2}px;top:${y + 8}px;transform:translateX(-50%)"><i style="background:${b[2]}">${i + 1}</i>${b[0]}</div>`; }).join('');
(async () => {
  const b = await chromium.launch();
  const shot = async (html, path, vp, transparent) => {
    const p = await b.newPage({ viewport: vp || { width: 1080, height: 1920 } });
    await p.setContent(html); await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(400);
    await p.screenshot({ path, omitBackground: !!transparent }); await p.close();
  };
  await shot(bg, 'bg.png');
  for (let i = 0; i < 4; i++) await shot(scene(i), `label${i + 1}.png`, null, true);
  await shot(mask(P.w, P.h, P.r), 'mask.png', { width: P.w, height: P.h });
  await shot(mask(E.w, E.h, E.r), 'mask_s.png', { width: E.w, height: E.h });
  await shot(end, 'endbg.png');
  await shot(badges, 'badges.png', null, true);
  await b.close();
})();
