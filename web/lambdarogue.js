/*
 * LambdaRogue page: windows (rvip-wm.js), message log, inventory and
 * visible lists sent by the game (port/rvip.pas RvipLists), prompt line,
 * saves mirrored to IndexedDB, autosave, help, export/import.
 * The engine (wasm, blits, keys) is web/lr.js.
 */
import { start, keyEvent, LR, status } from './lr.js';
import { File, Directory } from './vendor/wasi/index.js';

const $ = id => document.getElementById(id);
const hero = { x: 400, y: 300 };
let wm = null, savedLayout = null, zoomAdj = 0, face = '', lastSave = 0, wantSave = false;

/* ---------- files: memory FS <-> IndexedDB (saves/, lambdarogue.cfg, web-layout.json) ---------- */
const DB = 'lambdarogue', STORE = 'files';
function idb() {
	return new Promise((res, rej) => {
		const r = indexedDB.open(DB, 1);
		r.onupgradeneeded = () => r.result.createObjectStore(STORE);
		r.onsuccess = () => res(r.result);
		r.onerror = () => rej(r.error);
	});
}
async function idbAll() {
	const db = await idb();
	return new Promise((res, rej) => {
		const out = new Map(), req = db.transaction(STORE).objectStore(STORE).openCursor();
		req.onsuccess = () => { const c = req.result; if (!c) return res(out); out.set(c.key, c.value); c.continue(); };
		req.onerror = () => rej(req.error);
	});
}
async function idbWrite(sets, dels) {
	const db = await idb();
	return new Promise((res, rej) => {
		const tx = db.transaction(STORE, 'readwrite'), st = tx.objectStore(STORE);
		for (const [k, v] of sets) st.put(v, k);
		for (const k of dels) st.delete(k);
		tx.oncomplete = () => res(); tx.onerror = () => rej(tx.error);
	});
}
const written = new Map();
const same = (a, b) => a && a.length === b.length && a.every((v, i) => v === b[i]);
function savesDir() { return LR.root && LR.root.contents.get('saves'); }
function files() {
	const out = new Map(), s = savesDir();
	if (s) for (const [n, f] of s.contents) if (f instanceof File && n !== 'delete.me') out.set('saves/' + n, f.data);
	const cfg = LR.root && LR.root.contents.get('lambdarogue.cfg');
	if (cfg) out.set('lambdarogue.cfg', cfg.data);
	if (wm) out.set('web-layout.json', new TextEncoder().encode(JSON.stringify({ wm: wm.state(), face, zoomAdj, sound: sound.on, music: sound.musicOn })));
	return out;
}
let persisting = null;
function persist() {
	if (persisting) return persisting.then(persist);
	const sets = [], dels = [], now = files();
	for (const [k, v] of now) if (!same(written.get(k), v)) { const c = v.slice(); sets.push([k, c]); written.set(k, c); }
	for (const k of written.keys()) if (k.startsWith('saves/') && !now.has(k)) { dels.push(k); written.delete(k); }
	if (!sets.length && !dels.length) return Promise.resolve();
	persisting = idbWrite(sets, dels).catch(err => {
		status('Saving to browser storage (IndexedDB) failed: ' + err + '. Use "Export save" to keep a copy.', true);
	}).then(() => { persisting = null; });
	return persisting;
}
async function prepare(root) {
	try {
		for (const [k, v] of await idbAll()) {
			written.set(k, v);
			if (k === 'web-layout.json') { try { savedLayout = JSON.parse(new TextDecoder().decode(v)); } catch (e) { } continue; }
			if (k === 'lambdarogue.cfg') { root.contents.set(k, new File(v.slice())); continue; }
			if (k.startsWith('saves/')) {
				if (!root.contents.has('saves')) root.contents.set('saves', new Directory([]));
				root.contents.get('saves').contents.set(k.slice(6), new File(v.slice()));
			}
		}
	} catch (err) {
		status('Could not read saved games from IndexedDB (' + err + '). Saving may not work in this browser mode.', true);
	}
	if (!root.contents.has('saves')) root.contents.set('saves', new Directory([]));
	if (savedLayout) { if (savedLayout.fonts && savedLayout.wm && !savedLayout.wm.fs) savedLayout.wm.fs = savedLayout.fonts;   /* old layout: sizes were ours */
		face = savedLayout.face || ''; $('sel-font').value = face; loadFace(face); zoomAdj = savedLayout.zoomAdj || 0; sound.set(savedLayout.sound, savedLayout.music); }
	setupWM();
}
function saveNames() { const s = savesDir(); return s ? [...s.contents.keys()].filter(n => /\.lambdarogue$/.test(n)) : []; }
/* ---------- windows ---------- */
const WINS = [{ id: 'map', title: 'Map' }, { id: 'log', title: 'Log messages' }, { id: 'inv', title: 'Inventory' }, { id: 'vis', title: 'Visible' }];
const MULTI = { d: 'v', r: 0.83, a: { d: 'h', r: 0.74, a: 'map', b: { d: 'v', r: 0.55, a: 'inv', b: 'vis' } }, b: 'log' };
function fitMap() {
	const b = $('map'), c = LR.screen || $('screen');
	if (!b.clientWidth) return;
	/* whole-number zoom only (nearest-neighbour, never below 1:1); A-/A+ on the
	   title bar adjust it. A screen bigger than its window scrolls with the
	   player (RvipWM.center on the hero pixel the game sends, be_hero). */
	const s = Math.min(b.clientWidth / c.width, b.clientHeight / c.height);
	const z = Math.max(1, Math.floor(s) + zoomAdj), w = c.width * z, h = c.height * z;
	c.style.width = w + 'px'; c.style.height = h + 'px';
	if (w > b.clientWidth || h > b.clientHeight) {
		b.style.alignItems = b.style.justifyContent = 'flex-start';
		RvipWM.center(c, hero.x * z, hero.y * z, w, h, b.clientWidth, b.clientHeight);
	} else { b.style.alignItems = b.style.justifyContent = ''; c.style.marginLeft = c.style.marginTop = ''; }
}
function applyFonts() { for (const id of ['log', 'inv', 'vis']) { $(id).style.fontFamily = face ? '"' + face + '", ui-monospace, monospace' : ''; } }
function loadFace(n) {
	if (!n) { applyFonts(); return; }
	const ff = new FontFace(n, 'url(../fonts/' + n + '.woff)');
	ff.load().then(() => { document.fonts.add(ff); applyFonts(); }).catch(() => status('Could not load the font ' + n + '.', true));
}
function setupWM() {
	wm = RvipWM({
		area: $('game'), menu: $('btn-layout'), wins: WINS, multi: MULTI, single: 'map',
		state: savedLayout && savedLayout.wm || null,
		save: () => persist(),
		layout: () => fitMap(),
		zoom: { map: (px, d) => { zoomAdj = Math.max(-4, Math.min(4, zoomAdj + d)); fitMap(); persist(); } },   /* text windows: WM-owned sizes */
		onReset: () => { zoomAdj = 0; applyFonts(); fitMap(); persist(); },
	});
	applyFonts();
	wm.apply();
}

/* ---------- lists from the game ---------- */
/* list icon: the sprite the game named (tile = cell of its loaded tile
   sheet, 1:2 cells as BigCharXY draws them), scaled keeping the aspect */
function icon(t) {
	const im = LR.tileSheet;
	if (!im || !(t >= 0)) return null;
	const H = im.naturalHeight, W = im.naturalWidth, h = 20, w = 10, k = h / H;
	const i = document.createElement('i');
	i.className = 'ic';
	i.style.cssText = `background:url(${im.src}) -${t * (H / 2) * k}px 0/${W * k}px ${h}px no-repeat`;
	return i;
}
let invCache = '';
function showInv(s) {
	if (s === undefined) s = invCache; else invCache = s;
	const b = $('inv'); b.textContent = '';
	for (const l of s.split('\n')) {
		if (!l) continue;
		const d = document.createElement('div');
		if (l[0] === '=') { d.className = 'h'; d.textContent = l.slice(1); }
		else {
			const [col, t, tile] = l.split('\t'), ic = icon(+tile);
			d.className = 'row'; d.style.color = col;
			if (ic) d.appendChild(ic);
			d.appendChild(document.createTextNode(t));
		}
		b.appendChild(d);
	}
}

/* ---------- sound (stage 6 wires the files; off by default) ---------- */
const sound = {
	on: false, musicOn: false, music: null, musicName: null,
	set(s, m) { this.on = !!s; this.musicOn = !!m; this.buttons(); },
	buttons() { $('chk-sound').checked = this.on; $('chk-music').checked = this.musicOn; },
	sfx(path, vol) {
		LR.lastSfx = path;
		if (!this.on) return;
		const a = new Audio(path); a.volume = Math.max(0, Math.min(1, vol / 128)); a.play().catch(() => {});
	},
	/* the game's Mix_PlayMusic / Mix_HaltMusic (path null); path undefined = the toggle */
	play(path, loops, vol) {
		if (path) LR.lastMusic = path;
		if (path !== undefined) { this.musicName = path; this.loops = loops; this.musicVol = vol; }
		if (this.music) { this.music.pause(); this.music = null; }
		if (!this.musicName || !this.musicOn) return;
		const a = new Audio(this.musicName); a.loop = this.loops === -1;
		a.volume = Math.max(0, Math.min(1, (this.musicVol || 64) / 128));
		a.play().catch(() => {}); this.music = a;
	},
	volume(v) { this.musicVol = v; if (this.music) this.music.volume = Math.max(0, Math.min(1, v / 128)); },
	playing() { return this.music && !this.music.paused && !this.music.ended ? 1 : 0; },
};

/* ---------- shared page code (rvip-app.js): help, status line, export/import/new game.
 * Saves live in the WASI memory FS mirrored to our own IndexedDB store (read/sync hooks);
 * several characters export as one bundle. LR.running (lr.js) stays the running flag, so crashes too. ---------- */
const app = RvipApp({
	name: 'lambdarogue',
	save: () => { const n = saveNames().map(n => 'saves/' + n); return n.length === 1 ? n[0] : n; },
	read: p => savesDir().contents.get(p.slice(6)).data,
	clear: () => { LR.running = false; for (const n of saveNames()) savesDir().contents.delete(n); },
	put: (file, data) => {
		const name = file.name.replace(/^.*\//, '');
		savesDir().contents.set(/\.lambdarogue$/.test(name) ? name : name + '.lambdarogue', new File(data));
	},
	sync: cb => { persist().then(() => cb(), cb); },
	noSave: 'There is no saved character yet.'
});

/* ---------- startup ---------- */
function onKey(e) {
	if (!LR.running) return;
	wantSave = true;
	keyEvent(e);
}
function crashed(err) {
	LR.running = false;
	console.error('[lambdarogue] crash:', err);
	status('The game crashed (' + (err && err.message || err) + '). Reload the page to continue from the last autosave.', true);
}
async function ended() {
	LR.running = false;
	await persist();
	$('overlay-msg').textContent = saveNames().length ? 'Your characters are saved in this browser. Play again to continue.' : 'The game is over.';
	$('overlay').hidden = false;
}
/* newest message always in view (history fills from the top) */
LR.onMsg = (t, fold) => { const l = $('log'); RvipWM.log(l, t, fold); l.scrollTop = l.scrollHeight; };
LR.onPoll = atCmd => RvipWM.prompt.wait(atCmd);
LR.onScreen = () => fitMap();
LR.onSfx = (p, v) => sound.sfx(p, v);
LR.onMusic = (p, loops, v) => sound.play(p, loops, v);
LR.musicPlaying = () => sound.playing();
const imports = {
	be_lists: (i, v) => { showInv(cstr(i)); RvipWM.visible($('vis'), cstr(v), icon); },
	be_prompt: p => RvipWM.prompt.text(cstr(p)),
	/* autosave: every 2 minutes and when the tab is hidden, at most every 2 s */
	be_want_save: () => {
		const now = performance.now();
		if (!wantSave || (now - lastSave < 120000 && !document.hidden)) return 0;
		wantSave = false; lastSave = now; return 1;
	},
	be_sync: () => { persist(); },
	be_music_vol: v => sound.volume(v),
	be_hero: (x, y) => { hero.x = x; hero.y = y; fitMap(); },
	/* finished run (step 12): the game builds the query (Player.pas GameOver/WinGame), the page only sends it */
	be_beacon: p => {
		const q = cstr(p);
		try { if (window.RvipWM && RvipWM.report) RvipWM.report(q); else fetch('/roguelikes/beacon?' + q, { keepalive: true, mode: 'no-cors' }).catch(function () {}); } catch (e) {}
	},
};
function cstr(p) { const b = new Uint8Array(LR.mem.buffer, p); let e = 0; while (b[e]) e++; return new TextDecoder('latin1').decode(b.slice(0, e)); }

document.addEventListener('visibilitychange', () => { if (document.hidden) { lastSave = 0; persist(); } });
addEventListener('pagehide', () => persist());
addEventListener('beforeunload', e => { if (LR.running) { persist(); e.preventDefault(); e.returnValue = ''; } });
addEventListener('resize', () => wm && wm.apply());
addEventListener('unhandledrejection', e => crashed(e.reason));
addEventListener('error', e => crashed(e.error || e.message));
setInterval(() => { if (LR.running) persist(); }, 15000);
document.addEventListener('keydown', onKey);
$('btn-restart').onclick = () => location.reload();
$('chk-sound').onchange = function () { sound.on = this.checked; persist(); };
$('chk-music').onchange = function () { sound.musicOn = this.checked; sound.play(); persist(); };
RvipWM.dropdown($('btn-audio'), $('menu-audio'));
RvipWM.dropdown($('btn-file'), $('menu-file'));
/* text font: a face from the index page's fonts/ (web/build.sh lists them in fonts.json) */
fetch('fonts.json').then(r => r.json()).then(list => {
	for (const n of list) { const o = document.createElement('option'); o.value = n; o.textContent = n.replace(/^Web(Plus|437)_/, '').replace(/_/g, ' '); $('sel-font').appendChild(o); }
	$('sel-font').value = face;
}).catch(() => {});
$('sel-font').onchange = function () { face = this.value; loadFace(face); persist(); this.blur(); };
document.querySelectorAll('button').forEach(b => b.addEventListener('mousedown', e => e.preventDefault()));
window.LR = LR; LR.sound = sound;
start({ prepare, imports, onExit: ended, onCrash: crashed }).catch(crashed);
