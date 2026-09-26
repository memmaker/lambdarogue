/*
 * LambdaRogue in the browser. The game (lr.wasm, port/webbe.pas) hands over
 * a list of blits (surface, source rect, target point, alpha); this page only
 * copies those rectangles from the game's own PNG/JPG sheets onto the 800x600
 * screen canvas. Keys/mouse go back through be_poll, which waits via
 * Binaryen's Asyncify (web/build.sh); so do be_sleep and be_image.
 * Files: in-memory WASI file system (vendor/wasi) built from fs.json.
 */
import { WASI, WASIProcExit, File, Directory, OpenFile, PreopenDirectory, ConsoleStdout } from './vendor/wasi/index.js';

const $ = id => document.getElementById(id);
export const LR = { screen: null, ctx: null, surf: {}, events: [], waiter: null, blits: 0, polls: 0, atCmd: false, root: null };
function status(msg, isError) {
	const s = $('status'); if (!s) return;
	s.textContent = msg; s.hidden = !msg; s.classList.toggle('error', !!isError);
}

/* ---------- surfaces: 1 = screen canvas, others = the game's images ---------- */
function canvasOf(id) {
	const s = LR.surf[id];
	if (!s) return null;
	if (s instanceof HTMLCanvasElement) return s;
	const c = document.createElement('canvas'); c.width = s.naturalWidth; c.height = s.naturalHeight;
	c.getContext('2d').drawImage(s, 0, 0); LR.surf[id] = c; return c;
}
function frame(p, n) {
	const a = new Int32Array(LR.mem.buffer, p, n * 9);
	for (let i = 0; i < n; i++) {
		let [src, sx, sy, sw, sh, dst, dx, dy, alpha] = a.subarray(i * 9, i * 9 + 9);
		let img = LR.surf[src];
		const out = dst === 1 ? LR.screen : canvasOf(dst);
		if (!img || !out) continue;
		const W = img.naturalWidth || img.width, H = img.naturalHeight || img.height;
		if (sw < 0) { sx = 0; sy = 0; sw = W; sh = H; }
		if (sx < 0) { sw += sx; dx -= sx; sx = 0; } if (sy < 0) { sh += sy; dy -= sy; sy = 0; }
		sw = Math.min(sw, W - sx); sh = Math.min(sh, H - sy);
		if (sw <= 0 || sh <= 0) continue;
		if (img === out) { const t = document.createElement('canvas'); t.width = sw; t.height = sh; t.getContext('2d').drawImage(img, sx, sy, sw, sh, 0, 0, sw, sh); img = t; sx = sy = 0; }
		const g = out.getContext('2d');
		g.globalAlpha = alpha >= 255 ? 1 : alpha / 255;
		g.drawImage(img, sx, sy, sw, sh, dx, dy, sw, sh);
		LR.blits++;
	}
	LR.ctx.globalAlpha = 1;
}
function loadImage(id, path) {
	return new Promise(res => {
		const im = new Image();
		im.onload = () => { LR.surf[id] = im; res(0); };
		im.onerror = () => { console.warn('image missing', path); res(0); };
		im.src = path;
	});
}

/* ---------- input: SDL 1.2 keysyms, unicode like SDL with NumLock on ---------- */
const SYM = { ArrowUp: 273, ArrowDown: 274, ArrowRight: 275, ArrowLeft: 276, Insert: 277, Home: 278, End: 279,
	PageUp: 280, PageDown: 281, Enter: 13, Escape: 27, Backspace: 8, Tab: 9, Delete: 127 };
for (let i = 1; i <= 12; i++) SYM['F' + i] = 281 + i;
export function keyEvent(e) {
	if (e.target && /input|textarea/i.test(e.target.tagName)) return;
	if (e.metaKey || (e.ctrlKey && !/^[a-z]$/i.test(e.key))) return;
	let sym = 0, uni = 0;
	const kp = /^Numpad(\d)$/.exec(e.code);
	if (kp) { sym = 256 + +kp[1]; uni = /\d/.test(e.key) ? e.key.charCodeAt(0) : 0; }
	else if (e.code === 'NumpadEnter') { sym = 271; uni = 13; }
	else if (SYM[e.key]) { sym = SYM[e.key]; uni = sym < 128 ? sym : 0; }
	else if (e.key.length === 1) { uni = e.key.charCodeAt(0); sym = e.key.toLowerCase().charCodeAt(0); if (e.ctrlKey) uni = uni & 31; }
	else return;
	e.preventDefault();
	push([1, sym, uni]);
}
export function push(ev) {
	LR.events.push(ev);
	if (LR.waiter) { const w = LR.waiter; LR.waiter = null; w(); }
}
function mouse(type, e) {
	const r = LR.screen.getBoundingClientRect();
	const x = Math.floor((e.clientX - r.left) * LR.screen.width / r.width), y = Math.floor((e.clientY - r.top) * LR.screen.height / r.height);
	if (x < 0 || y < 0 || x >= LR.screen.width || y >= LR.screen.height) return;
	if (type === 4 && LR.events.length && LR.events.at(-1)[0] === 4) LR.events.pop();  // coalesce moves
	push([type, x, y, e.button === 2 ? 3 : e.button === 1 ? 2 : 1]);
}
function poll(atcmd) {
	LR.polls++; LR.atCmd = !!atcmd;
	if (LR.onPoll) LR.onPoll(atcmd);
	const take = () => { const ev = LR.events.shift(); LR.ev = ev; return ev ? ev[0] : 0; };
	if (LR.events.length) return Promise.resolve(take());
	return new Promise(res => {
		const t = setTimeout(() => { LR.waiter = null; res(take()); }, 30);
		LR.waiter = () => { clearTimeout(t); res(take()); };
	});
}

/* ---------- WASI files ---------- */
function buildFS(files) {
	const root = new Directory([]);
	for (const [path, b64] of Object.entries(files)) {
		const parts = path.split('/'); let d = root;
		for (const p of parts.slice(0, -1)) { if (!d.contents.has(p)) { const n = new Directory([]); n.parent = d; d.contents.set(p, n); } d = d.contents.get(p); }
		if (parts.at(-1)) d.contents.set(parts.at(-1), new File(Uint8Array.from(atob(b64), c => c.charCodeAt(0))));
	}
	return root;
}

/* ---------- run ---------- */
export async function start(opts = {}) {
	LR.screen = $('screen'); LR.ctx = LR.screen.getContext('2d');
	LR.surf[1] = LR.screen;
	LR.screen.addEventListener('mousemove', e => mouse(4, e));
	LR.screen.addEventListener('mousedown', e => { e.preventDefault(); mouse(2, e); });
	LR.screen.addEventListener('mouseup', e => mouse(3, e));
	LR.screen.addEventListener('contextmenu', e => e.preventDefault());
	status('Loading…');
	const [files, wasm] = await Promise.all([fetch('fs.json').then(r => r.json()), fetch('lr.wasm').then(r => r.arrayBuffer())]);
	if (opts.files) opts.files(files);
	LR.root = buildFS(files);
	const cstr = p => { const b = new Uint8Array(LR.mem.buffer, p); let e = 0; while (b[e]) e++; return new TextDecoder('latin1').decode(b.slice(0, e)); };
	const lr = {
		be_frame: frame,
		be_image: (id, p) => loadImage(id, cstr(p)),
		be_free: id => { delete LR.surf[id]; },
		be_poll: poll,
		be_evarg: i => LR.ev ? LR.ev[i + 1] : 0,
		be_sleep: ms => new Promise(r => setTimeout(r, ms)),
		be_sfx: (p, v) => LR.onSfx && LR.onSfx(cstr(p), v),
		be_music: (p, loops, v) => LR.onMusic && LR.onMusic(p ? cstr(p) : null, loops, v),
		be_music_playing: () => LR.musicPlaying ? LR.musicPlaying() : 0,
		be_title: p => { document.title = cstr(p); },
		be_msg: (p, fold) => LR.onMsg && LR.onMsg(cstr(p), fold),
		be_pending: () => LR.events.filter(e => e[0] !== 4).length,
		be_screen: (w, h) => { LR.screen.width = w; LR.screen.height = h; LR.onScreen && LR.onScreen(w, h); },
		...(opts.imports || {}),
	};
	const ASYNC = new Set(['be_poll', 'be_sleep', 'be_image']);
	let ex, pending, value, data;
	const imp = {};
	for (const [n, f] of Object.entries(lr)) imp[n] = (...a) => {
		if (ASYNC.has(n) && ex.asyncify_get_state() === 2) { ex.asyncify_stop_rewind(); return value; }
		if (!ASYNC.has(n)) return f(...a);
		pending = f(...a); ex.asyncify_start_unwind(data); return 0;
	};
	const w = new WASI(['lambdarogue'], [], [new OpenFile(new File([])), ConsoleStdout.lineBuffered(s => console.log(s)),
		ConsoleStdout.lineBuffered(s => console.warn(s)), new PreopenDirectory('.', LR.root.contents)], { debug: false });
	const { instance } = await WebAssembly.instantiate(wasm, { wasi_snapshot_preview1: w.wasiImport, lr: imp });
	ex = instance.exports; w.inst = instance; LR.mem = ex.memory; LR.ex = ex;
	data = ex.memory.grow(16) * 65536;
	new Int32Array(ex.memory.buffer, data, 2).set([data + 8, data + 16 * 65536]);
	status('');
	LR.running = true;
	try {
		ex._start();
		while (ex.asyncify_get_state() === 1) {
			ex.asyncify_stop_unwind();
			value = await pending;
			ex.asyncify_start_rewind(data);
			ex._start();
		}
	} catch (e) {
		if (!(e instanceof WASIProcExit)) { status('The game crashed: ' + e + ' — reload the page.', true); throw e; }
	}
	LR.running = false;
	if (opts.onExit) opts.onExit();
}
