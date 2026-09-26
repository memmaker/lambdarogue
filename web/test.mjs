// Headless check of web/dist/lr.wasm: node web/test.mjs "keys" — prints the
// text the game drew (reconstructed from its font blits) and the map chars.
// Keys: plain chars, \r Enter, \e Escape, {up} {down} {left} {right} {kp1}..{kp9} {f1}..{f12}.
// Every be_poll/be_sleep/be_image goes through an Asyncify unwind/rewind, as in the browser.
import { WASI, WASIProcExit, File, Directory, PreopenDirectory, OpenFile, ConsoleStdout } from './vendor/wasi/index.js';
import fs from 'fs';
const dir = new URL('dist/', import.meta.url).pathname;
const files = JSON.parse(fs.readFileSync(dir + 'fs.json'));
const root = new Directory([]);
for (const [path, b64] of Object.entries(files)) {
	const parts = path.split('/'); let d = root;
	for (const p of parts.slice(0, -1)) { if (!d.contents.has(p)) d.contents.set(p, new Directory([])); d = d.contents.get(p); }
	if (parts.at(-1)) d.contents.set(parts.at(-1), new File(Buffer.from(b64, 'base64')));
}
const SYM = { up: 273, down: 274, right: 275, left: 276, insert: 277, home: 278, end: 279, pageup: 280, pagedown: 281, enter: 271 };
for (let i = 0; i <= 9; i++) SYM['kp' + i] = 256 + i;
for (let i = 1; i <= 12; i++) SYM['f' + i] = 281 + i;
const keys = [];
const spec = (process.argv[2] || '').replace(/\\r/g, '\r').replace(/\\e/g, '\x1b');
for (let i = 0; i < spec.length; i++) {
	if (spec[i] === '{') { const j = spec.indexOf('}', i); keys.push([SYM[spec.slice(i + 1, j)], 0]); i = j; continue; }
	const c = spec.charCodeAt(i); keys.push([c >= 65 && c <= 90 ? c + 32 : c, c]);
}
const quiet = process.argv.includes('-q');
// text: 10x20 font cells of tileset-1.png; map: 20x40 tiles of tileset-2-*
let text = [], tiles = [], nblits = 0, images = {}, screenW = 800, screenH = 600, polls = 0;
const clear = () => { text = Array.from({ length: 40 }, () => Array(103).fill(' ')); tiles = Array.from({ length: 20 }, () => Array(52).fill(' ')); };
clear();
const show = (why) => {
	console.log('--- text (' + why + ', ' + nblits + ' blits, ' + polls + ' polls)');
	for (const r of text) { const s = r.join('').trimEnd(); if (s) console.log(s); }
	console.log('--- map tiles');
	for (const r of tiles) { const s = r.join('').trimEnd(); if (s) console.log(s); }
};
let mem;
const lr = {
	be_frame(p, n) {
		const a = new Int32Array(mem.buffer, p, n * 9);
		for (let i = 0; i < n; i++) {
			const [src, sx, sy, sw, sh, dst, dx, dy] = a.slice(i * 9, i * 9 + 8); nblits++;
			if (dst !== 1) continue;
			const name = images[src] || '';
			if (sw < 0 && /bg|title|\.jpg/.test(name)) clear();
			if (/tileset-1\./.test(name) && sw === 10 && sh === 20) {
				const y = Math.floor(dy / 20), x = Math.floor(dx / 10);
				if (text[y] && x >= 0 && x < 103) text[y][x] = String.fromCharCode(32 + sx / 10);
			} else if (/tileset-2/.test(name) && sw === 20 && sh === 40 && sx < 3440) {
				const y = Math.floor(dy / 40), x = Math.floor(dx / 20);
				if (tiles[y] && x >= 0 && x < 52) { const c = 32 + sx / 20; tiles[y][x] = c < 127 ? String.fromCharCode(c) : String.fromCharCode(0x100 + c); }
			} else if (/extra\.png/.test(name) && sw === 7 && sh === 12 && sx >= 760) {
				const y = Math.floor(dy / 20), x = Math.floor(dx / 10);  // small font: approximate cell
				if (text[y] && x >= 0 && x < 103 && text[y][x] === ' ') text[y][x] = String.fromCharCode(32 + (sx - 760) / 7);
			}
		}
	},
	be_image(id, p) { images[id] = cstr(p); },
	be_free(id) { delete images[id]; },
	be_poll(atcmd) {
		polls++;
		if (keys.length) { ev = [1, ...keys.shift()]; return 1; }
		show('out of keys'); process.exit(0);
	},
	be_evarg(i) { return ev[i + 1]; },
	be_sleep() {},
	be_sfx(p) { if (!quiet) console.log('sfx', cstr(p)); },
	be_music(p) { if (!quiet) console.log('music', p ? cstr(p) : '(stop)'); },
	be_music_playing() { return 0; },
	be_title(p) { console.log('title', cstr(p)); },
	be_screen(w, h) { screenW = w; screenH = h; },
};
let ev = [0];
const cstr = (p) => { const b = new Uint8Array(mem.buffer, p); let e = 0; while (b[e]) e++; return Buffer.from(b.slice(0, e)).toString('latin1'); };
const ASYNC = new Set(['be_poll', 'be_sleep', 'be_image']);
let ex, pending, value, data;
const imp = {};
for (const [n, f] of Object.entries(lr)) imp[n] = (...a) => {
	if (ASYNC.has(n) && ex.asyncify_get_state() === 2) { ex.asyncify_stop_rewind(); return value; }
	if (!ASYNC.has(n)) return f(...a);
	pending = f(...a); ex.asyncify_start_unwind(data); return 0;
};
const w = new WASI(['lambdarogue'], [], [new OpenFile(new File([])), ConsoleStdout.lineBuffered(s => quiet || console.log(s)), ConsoleStdout.lineBuffered(console.log),
	new PreopenDirectory('.', root.contents)], { debug: false });
const { instance } = await WebAssembly.instantiate(fs.readFileSync(dir + 'lr.wasm'), { wasi_snapshot_preview1: w.wasiImport, lr: imp });
ex = instance.exports; w.inst = instance; mem = ex.memory;
data = ex.memory.grow(16) * 65536;
new Int32Array(ex.memory.buffer, data, 2).set([data + 8, data + 16 * 65536]);
try {
	ex._start();
	while (ex.asyncify_get_state() === 1) { ex.asyncify_stop_unwind(); value = pending; ex.asyncify_start_rewind(data); ex._start(); }
} catch (e) { if (!(e instanceof WASIProcExit)) { show('crash'); throw e; } }
show('exited');
