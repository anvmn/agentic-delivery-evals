// Render ONE scene of scenes.html to PNG frames at 30fps.
// Usage: NODE_PATH=<fixture node_modules> node render_frames.js <workdir> <sceneIdx>
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const WORK = process.argv[2];
const IDX = parseInt(process.argv[3], 10);
const FPS = 30;
const timing = JSON.parse(fs.readFileSync(path.join(WORK, 'timing.json'), 'utf8'));
const sc = timing.scenes[IDX];
const FRAMES = path.join(WORK, `frames-${IDX}`);
fs.mkdirSync(FRAMES, { recursive: true });

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
  await page.goto('file://' + path.resolve(__dirname, 'scenes.html'));
  await page.evaluate(() => document.fonts.ready);
  const dur = sc.video_s;
  const n = Math.round(dur * FPS);
  for (let f = 0; f < n; f++) {
    await page.evaluate(([idx, t, d, cues, sdurs]) => window.seek(idx, t, d, cues, sdurs),
      [IDX, f / FPS, dur, sc.cues || [], sc.sent_durs || []]);
    await page.screenshot({ path: path.join(FRAMES, `f${String(f).padStart(6, '0')}.png`) });
  }
  await browser.close();
  console.log(`scene ${IDX}: ${n} frames (${dur.toFixed(2)}s)`);
})();
