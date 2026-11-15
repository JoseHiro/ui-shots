const { chromium } = require('playwright');
const font='<link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Nunito:wght@700;800&display=swap" rel="stylesheet">';
const bg=`${font}<style>html,body{margin:0;width:1080px;height:1920px;background:#F3F1FA;font-family:Fredoka,sans-serif}
h1{margin:0;position:absolute;top:70px;width:100%;text-align:center;font-size:92px;font-weight:700;color:#2B2840;letter-spacing:-1px}
p{margin:0;position:absolute;top:186px;width:100%;text-align:center;font-size:40px;font-weight:600;color:#8B7CF6}</style>
<h1>iOS Tab Bars</h1><p>4 styles, built in SwiftUI</p>`;
const names=["Liquid Dock","Bubble Notch","Soft Pill","Color Chips"], cols=["#8B7CF6","#4AA8F0","#F7739B","#1FB37F"];
const labels=`${font}<style>html,body{margin:0;width:1080px;height:1920px;background:transparent}
.c{position:absolute;left:46px;display:flex;align-items:center;gap:12px;padding:10px 20px 10px 10px;background:rgba(255,255,255,.95);border-radius:999px;
 box-shadow:0 6px 18px -6px rgba(90,70,170,.35);font-family:Fredoka,sans-serif;font-weight:600;font-size:32px;color:#2B2840}
.n{width:44px;height:44px;border-radius:50%;display:grid;place-items:center;color:#fff;font-weight:700;font-size:26px}</style>`+
 names.map((n,i)=>`<div class="c" style="top:${262+i*411+20}px"><span class="n" style="background:${cols[i]}">${i+1}</span>${n}</div>`).join('');
(async()=>{
  const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1080,height:1920}});
  await p.setContent(bg); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({path:'bg.png'});
  await p.setContent(labels); await p.evaluate(()=>document.fonts.ready); await p.waitForTimeout(300); await p.screenshot({path:'labels.png',omitBackground:true});
  await b.close();
})();
