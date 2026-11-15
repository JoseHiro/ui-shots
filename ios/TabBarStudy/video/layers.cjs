const { chromium } = require('playwright');
const font='<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Nunito:wght@700;800&display=swap" rel="stylesheet">';
const bg=`${font}<style>html,body{margin:0;width:1080px;height:1920px;background:#ECEEF3;font-family:Fredoka,sans-serif}
h1{margin:0;position:absolute;top:34px;width:100%;text-align:center;font-size:76px;font-weight:700;color:#1B1B24;letter-spacing:-1px}
p{margin:0;position:absolute;top:118px;width:100%;text-align:center;font-size:32px;font-weight:600;color:#6B7280}</style>
<h1>iOS Tab Bars</h1><p>4 apps · 4 styles · SwiftUI</p>`;
const names=["Liquid Dock","Bubble Notch","Soft Pill","Color Chips"], apps=["Music","Food","Fitness","Travel"], cols=["#FF4D8D","#FF5A1F","#16A865","#0EA5E9"];
const labels=`${font}<style>html,body{margin:0;width:1080px;height:1920px;background:transparent}
.c{position:absolute;left:24px;display:flex;align-items:center;gap:12px;padding:10px 20px 10px 10px;background:transparent;font-family:Fredoka,sans-serif;font-weight:600;font-size:32px;color:#2B2840}
.a{font-weight:500;color:#6B7280;font-size:26px}
.n{width:44px;height:44px;border-radius:50%;display:grid;place-items:center;color:#fff;font-weight:700;font-size:26px}</style>`+
 names.map((n,i)=>`<div class="c" style="top:${150+i*440+2}px"><span class="n" style="background:${cols[i]}">${i+1}</span>${n}<span class="a">· ${apps[i]}</span></div>`).join('');
(async()=>{
  const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});
  await p.setContent(bg); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({path:'bg.png'});
  await p.setContent(labels); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({path:'labels.png',omitBackground:true});
  await b.close();
})();
