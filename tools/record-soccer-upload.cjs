// Records a 1080x1920 TikTok take of designs/soccer-upload (no audio).
// Run from a scratch dir:  node <path>/tools/record-soccer-upload.cjs
// Then: ffmpeg -f concat -safe 0 -i list.txt -vf "fps=30,format=yuv420p" -c:v libx264 -crf 17 -movflags +faststart take.mp4
// Needs playwright (npm i -D playwright && npx playwright install chromium).
const { chromium } = require('playwright');
const URL='file://'+require('path').resolve(__dirname,'../designs/soccer-upload/index.html');
(async()=>{
  const b=await chromium.launch();
  const ctx=await b.newContext({viewport:{width:1080,height:1920},deviceScaleFactor:1});
  const fs=require('fs'); fs.rmSync('frames',{recursive:true,force:true}); fs.mkdirSync('frames');
  const frames=[]; let rec=false;
  const t0=Date.now();
  const p=await ctx.newPage();
  await p.goto(URL); await p.evaluate(()=>document.fonts.ready);
  await p.addStyleTag({content:`
    html{zoom:2.4} body{flex-direction:column;gap:18px;justify-content:center;min-height:800px;height:auto}
    .pitch{height:430px!important}
    #ttl{font-family:Fredoka,sans-serif;font-weight:700;text-align:center;line-height:1.02}
    #ttl .a{font-size:40px;color:#2b2840} #ttl .b{font-size:40px;color:#8b7cf6}
    #finger{position:fixed;left:0;top:0;width:34px;height:34px;margin:-17px 0 0 -17px;border-radius:50%;background:rgba(139,124,246,.28);
      border:2.5px solid rgba(255,255,255,.95);box-shadow:0 4px 14px rgba(60,40,140,.35);z-index:99;pointer-events:none;transition:transform .12s,opacity .2s;opacity:0}
    #finger.down{transform:scale(.78);background:rgba(139,124,246,.5)}`});
  await p.evaluate(()=>{
    const t=document.createElement('div'); t.id='ttl'; t.innerHTML='<div class="a">Soccer Upload</div><div class="b">Animation</div>';
    document.body.prepend(t);
    const f=document.createElement('div'); f.id='finger'; document.body.appendChild(f);
    addEventListener('mousemove',e=>{const z=document.getElementById('card').getBoundingClientRect().width/document.getElementById('card').offsetWidth;f.style.left=e.clientX/z+'px';f.style.top=e.clientY/z+'px';f.style.opacity=1});
    addEventListener('mousedown',()=>f.classList.add('down')); addEventListener('mouseup',()=>f.classList.remove('down'));
    dispatchEvent(new Event('resize'));
  });
  await p.waitForTimeout(400);
  const cdp=await ctx.newCDPSession(p);
  cdp.on('Page.screencastFrame',async f=>{ if(rec){ const n=frames.length; fs.writeFileSync(`frames/${String(n).padStart(5,'0')}.jpg`,Buffer.from(f.data,'base64')); frames.push(f.metadata.timestamp);} cdp.send('Page.screencastFrameAck',{sessionId:f.sessionId}).catch(()=>{}); });
  await cdp.send('Page.startScreencast',{format:'jpeg',quality:94,maxWidth:1080,maxHeight:1920,everyNthFrame:1});
  rec=true;
  const start=(Date.now()-t0)/1000;
  const geo=()=>p.evaluate(()=>{const r=e=>document.getElementById(e).getBoundingClientRect();
    const ball=r('ball'), net=r('net'), k=r('keeper');
    return {bx:ball.left+ball.width/2,by:ball.top+ball.height/2,gx:net.left,gw:net.width,gl:net.bottom,kx:k.left+k.width/2}});
  const M=p.mouse;
  await M.move(912,1728); await p.waitForTimeout(900);
  async function shoot(pick){
    let g=await geo();
    await M.move(g.bx+144,g.by+144,{steps:14}); await p.waitForTimeout(150);
    await M.move(g.bx,g.by,{steps:14}); await p.waitForTimeout(250);
    await M.down(); await p.waitForTimeout(250);
    // wind-up: pull back a little
    for(let i=1;i<=10;i++){ await M.move(g.bx,g.by+i*7.2); await p.waitForTimeout(30); }
    await p.waitForTimeout(220);
    g=await geo();
    const tx=pick(g), sy=g.by, sx=g.bx, dy=-24*2.4, dx=(tx-sx)/(sy-g.gl)*24*2.4;
    for(let i=1;i<=6;i++){ await M.move(sx+dx*i,sy+dy*i); await p.waitForTimeout(16); }
    await M.up();
    await M.move(sx+dx*9,sy+dy*9,{steps:6});
  }
  const far=g=>{const L=g.gx+72,R=g.gx+g.gw-72;return Math.abs(L-g.kx)>Math.abs(R-g.kx)?L:R;};
  await shoot(g=>g.kx+10);                  await p.waitForTimeout(2600);  // save
  await shoot(far);                        await p.waitForTimeout(3600);  // goal
  await shoot(g=>far(g)<g.gx+g.gw/2?g.gx+5:g.gx+g.gw-5); await p.waitForTimeout(2700); // post
  await shoot(far);                        await p.waitForTimeout(3600);  // goal
  await shoot(far);                        await p.waitForTimeout(3400);  // goal
  const end=(Date.now()-t0)/1000;
  const count=await p.evaluate(()=>document.getElementById('count').textContent);
  rec=false; await cdp.send('Page.stopScreencast');
  const L=frames.map((t,i)=>`file 'frames/${String(i).padStart(5,'0')}.jpg'\nduration ${((frames[i+1]??t+0.5)-t).toFixed(4)}`).join('\n')+`\nfile 'frames/${String(frames.length-1).padStart(5,'0')}.jpg'\n`;
  fs.writeFileSync('list.txt',L);
  await ctx.close(); await b.close();
  console.log(JSON.stringify({start,end,count,frames:frames.length}));
})();
