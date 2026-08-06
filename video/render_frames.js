// Render scenes.html to PNG frames at 30fps, timing driven by timing.json.
// Run with: NODE_PATH=<b-01 fixture node_modules> node render_frames.js <workdir>
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const WORK = process.argv[2];
const FPS = 30;
const timing = JSON.parse(fs.readFileSync(path.join(WORK, 'timing.json'), 'utf8'));
const FRAMES = path.join(WORK, 'frames');
fs.mkdirSync(FRAMES, { recursive: true });

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
  await page.goto('file://' + path.resolve(__dirname, 'scenes.html'));
  await page.evaluate(() => document.fonts.ready);
  let frame = 0;
  for (let i = 0; i < timing.scenes.length; i++) {
    const dur = timing.scenes[i].video_s;
    const n = Math.round(dur * FPS);
    for (let f = 0; f < n; f++) {
      await page.evaluate(([idx, t, d]) => window.seek(idx, t, d), [i, f / FPS, dur]);
      await page.screenshot({ path: path.join(FRAMES, `f${String(frame).padStart(6, '0')}.png`) });
      frame++;
    }
    console.log(`scene ${i}: ${n} frames (${dur.toFixed(2)}s)`);
  }
  await browser.close();
  console.log(`total ${frame} frames`);
})();
