// Real-browser check (Chromium via Playwright): serves web/dist, types keys,
// saves a screenshot to web/shots/<name>.png and reads canvas pixels.
// Usage: node web/browser-check.mjs <name> "<keys>" [port]
//   keys: chars, \r Enter, \e Esc, {ArrowUp} etc. (Playwright key names), {wait:ms}
// Needs the playwright package: NODE_PATH=~/pwtools/node_modules (see web/toolchain.sh).
import { chromium } from 'playwright';
import { spawn } from 'child_process';
const [name = 'check', keys = '', port = '8765'] = process.argv.slice(2);
const dist = new URL('dist/', import.meta.url).pathname;
const srv = spawn('python3', ['-m', 'http.server', port, '-d', dist], { stdio: 'ignore' });
await new Promise(r => setTimeout(r, 800));
let code = 0;
try {
	const exe = process.env.CHROMIUM || undefined;
	const browser = await chromium.launch(exe ? { executablePath: exe } : {});
	const page = await browser.newPage({ viewport: { width: +(process.env.VW || 1280), height: +(process.env.VH || 800) } });
	const errors = [];
	page.on('pageerror', e => errors.push(String(e)));
	page.on('console', m => { if (m.type() === 'error' && !/favicon|404/.test(m.text())) errors.push(m.text()); });
	page.on('dialog', d => d.accept());
	await page.goto(`http://127.0.0.1:${port}/`);
	await page.waitForFunction(() => window.LR && LR.polls > 0, null, { timeout: 60000 });
	await page.waitForTimeout(1500);
	const spec = keys.replace(/\\r/g, '\r').replace(/\\e/g, '\x1b');
	for (let i = 0; i < spec.length; i++) {
		if (spec[i] === '{') {
			const j = spec.indexOf('}', i), k = spec.slice(i + 1, j); i = j;
			if (k.startsWith('wait:')) await page.waitForTimeout(+k.slice(5));
			else if (k === 'reload') { await page.reload(); await page.waitForFunction(() => window.LR && LR.polls > 0, null, { timeout: 60000 }); await page.waitForTimeout(1500); }
			else if (k.startsWith('eval:')) console.log('eval', k.slice(5), '=>', JSON.stringify(await page.evaluate(k.slice(5))));
			else await page.keyboard.press(k);
		} else await page.keyboard.press(spec[i] === '\r' ? 'Enter' : spec[i] === '\x1b' ? 'Escape' : spec[i]);
		await page.waitForTimeout(250);
	}
	await page.waitForTimeout(1500);
	const info = await page.evaluate(() => {
		const c = document.getElementById('screen'), g = c.getContext('2d');
		const d = g.getImageData(0, 0, c.width, c.height).data;
		let lit = 0, colours = new Set();
		for (let i = 0; i < d.length; i += 4 * 97) { if (d[i] + d[i + 1] + d[i + 2] > 30) lit++; colours.add(d[i] >> 4 << 8 | d[i + 1] >> 4 << 4 | d[i + 2] >> 4); }
		return { w: c.width, h: c.height, blits: LR.blits, polls: LR.polls, sampledLit: lit, colours: colours.size, title: document.title };
	});
	await page.screenshot({ path: new URL(`shots/${name}.png`, import.meta.url).pathname });
	console.log(JSON.stringify(info), errors.length ? 'ERRORS: ' + errors.join(' | ') : 'no console errors');
	if (errors.length || info.blits === 0) code = 1;
	await browser.close();
} finally { srv.kill(); }
process.exit(code);
