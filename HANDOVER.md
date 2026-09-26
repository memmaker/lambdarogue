# LambdaRogue 1.6.4: handover

## Cloud experiment (read this first)

This repo is an experiment: the RVIP import runs in a Claude Code **cloud**
session instead of on the maintainer's Mac. Everything the procedure normally
takes from sibling folders is bundled under `rvip/`:

- `rvip/RVIP.md` — the procedure (a snapshot; the canonical copy lives on the
  Mac and is merged by hand). **Write lessons into `rvip/LESSONS.md`** (new
  file, one bullet per lesson with the RVIP section it belongs to) instead of
  editing `rvip/RVIP.md`.
- `rvip/web/rvip-wm.js`, `rvip/web/rvip-sound.js` — the shared page code every
  game loads (window manager, sound). Use, don't fork.
- `rvip/templates/boss/` — the Free Pascal worked example (BOSS: Beyond
  Moria): `port/bcrt.pas` (crt replacement calling `be_*` wasm imports),
  `web/boss.js` (draws, keys, WASI shim, IndexedDB mirror), `web/build.sh`
  (FPC trunk → `wasm32-wasip1` → `wasm-opt --asyncify`), `web/test.mjs`
  (headless node test), `HANDOVER.md`. Read RVIP.md section **A-BOSS**.
- `rvip/templates/prospector-webgfx.c` + `prospector-HANDOVER.md` — the other
  graphical port (FreeBASIC game with its own framebuffer driver handed to a
  canvas). LambdaRogue is graphical too (SDL, tiles, TTF fonts, music), so
  its port is BOSS's toolchain + Prospector's idea: replace the JEDI-SDL units
  (`sdl.pas`, `sdl_image.pas`, `sdl_ttf.pas`, `sdl_mixer.pas`, `sdlinput.pas`
  …) with one web backend unit that keeps a framebuffer/tile-blit list and
  key queue and talks to the page through `be_*` imports; the page only blits.
  The game code (`GFX.pas`, `BaseOutput.pas`, `Input.pas`, …) should stay as
  untouched as BOSS's did.

**Differences from a local run**
- No browser pane and no ruzzoli.de deploy key here. Stages 1–6 are in scope.
  Replace "test in the browser pane" with: `node web/test.mjs` headless runs
  (as BOSS), plus a real browser check with Playwright/Chromium if it can be
  installed (`npx playwright install chromium`), saving a screenshot into
  `web/shots/` and reading the canvas pixels. Stage 5's "page live" becomes
  "page serves from `web/dist` with `python3 -m http.server` and passes the
  Playwright check". Write `web/deploy.sh` like BOSS's but never run it.
- Toolchain must be installed in the cloud VM: FPC 3.2.x from apt (`fpc`) for
  native/ASan-style checks, FPC trunk built as a `wasm32-wasip1` cross
  compiler exactly as A-BOSS describes (clone
  https://gitlab.com/freepascal.org/fpc/source.git), `wasm-ld` from LLVM,
  `wasm-opt` from binaryen (`npm i -g binaryen` or apt). Record the exact
  commands in `web/toolchain.sh` so the Mac can reproduce them.
- Commit after every stage (`RVIP: stage N <topic>`) and **push to `origin`**
  (github.com/memmaker/lambdarogue, private) so the Mac can pull. Every commit
  message ends with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- The Docs page (stage 6, `~/Desktop/Games/Roguelikes/Docs`) is not here:
  write `docs/web/lambdarogue-docs.html` in the same shape as BOSS's
  `web/make-help.py` output and note it for the Mac side.
- One tile set per game (≥95% coverage of every drawable thing, else the
  fallback named in RVIP.md; never mix). LambdaRogue ships its own tiles in
  `graphics/`; count coverage with a script and record the number.

## Game facts (from the source drop)

- Source: `LambdaRouge_1.6.4_src.zip` from the Google Code archive
  (https://code.google.com/archive/p/lambdarogue/downloads), 2012-11-17;
  author Mario Donick; licence: see `docs/`. Build script `buildmac.sh`,
  Lazarus project `fprl.lpi`, main program `fprl.pas`. Free Pascal + JEDI-SDL
  (SDL 1.2, SDL_image, SDL_ttf, SDL_mixer, smpeg). Data in `data/`,
  `graphics/`, `sound/`, `music/`, saves in `saves/`.

## RVIP progress

### Stage 1 — Get + build (done)
- Folder: repo root (flat Pascal sources). Case: **O** (graphical SDL game),
  built the A-BOSS way (FPC trunk → `wasm32-wasip1`, no Emscripten) with
  Prospector's idea (the game hands the page a blit list; the page only blits).
- **Web backend: `port/webbe.pas`** (unit `WebBE`), the only replacement for
  JEDI-SDL (`sdl.pas`, `sdl_image.pas`, `sdl_mixer.pas`, …, left in the tree
  unused) and FPC's `Crt`/`Video`/`Keyboard`/`Process`. Every
  `SDL_BlitSurface` → one record `{src, sx, sy, sw, sh, dst, dx, dy, alpha}`
  (surface ids: 1 = screen, ≥2 = `IMG_Load`ed sheets); `SDL_UpdateRect`,
  `SDL_PollEvent`, `delay` flush it with `be_frame(ptr, n)`. Imports (module
  `lr`): `be_frame be_image be_free be_poll be_evarg be_sleep be_sfx be_music
  be_music_playing be_title be_screen`; asyncified: `be_poll be_sleep
  be_image`. Keys arrive as SDL 1.2 keysym + unicode (keypad = digits, as SDL
  with NumLock on). Mouse: be_poll types 2/3/4 + `SDL_GetMouseState`.
  `web_at_cmd` (Pascal var) is passed to `be_poll` for the prompt line (not
  set yet: stage 2/5 must set it at the command prompt, `fprl.pas` KEYLOOP
  ~line 11808).
- Game code changes: `uses` lists (SDL/SDL_Image/SDL_Mixer/Crt/Video/Keyboard/
  Process → `WebBE`), `{$IFNDEF WEB}` around the options entry "a use
  graphical output" (console mode can't work in a browser) and around
  `{$R *.res}`. Sources are CRLF: edit with perl/binary Python.
- Build: `sh web/build.sh` → `web/dist` (lr.wasm 2.2 MB, fs.json = `data/`
  + `web/lambdarogue.cfg` + empty `graphics/**` names for `fileexists`, plus
  graphics/sound/music served as files). Flags: `-Twasip1 -O2 -dWEB -Mobjfpc`
  (mode as `buildmac.sh`), units rtl, rtl-objpas, rtl-extra, fcl-base;
  `-XP/usr/bin/` (wasm-ld 18); `/usr/bin/wasm-opt -O2 --asyncify
  --pass-arg=asyncify-imports@lr.be_poll,lr.be_sleep,lr.be_image` + feature
  flags one by one. Toolchain: `web/toolchain.sh` (FPC trunk c71f0a97c8
  in `~/fpc/fpc-wasm`).
- Page (stage-1 minimum): `web/index.html` + `web/lr.js` (800x600 canvas,
  WASI shim `web/vendor/wasi` from BOSS, keys, mouse, asyncify loop).
- Tests: `node web/test.mjs "2c1\r"` (quickstart, coffeebreak, soldier →
  dungeon) prints the screen text rebuilt from font blits + map tile codes;
  `node web/browser-check.mjs <shot> "<keys>"` (Playwright + Chromium,
  `CHROMIUM=/opt/pw-browsers/chromium`) → `web/shots/stage1-title.png`,
  `web/shots/stage1-dungeon.png` (title and first dungeon level with tiles,
  no console errors).
- "ASan" run: `sh web/check.sh "1 2 3 4 5" 20000` = native FPC 3.2.2 build
  with `-Cr -Co -Ci -Ct -gl`, headless backend (scripted start `LR_KEYS`,
  then 20000 random keys per seed): **no range/overflow/IO error** in 5 seeds
  (a save was written, so the runs reached the dungeon). Objects in /tmp.
- **Tiles (decided now):** LambdaRogue's own sheets `graphics/tiles/
  tileset-2-small-<sex>-<profession>.png` (20x40 cells from chr 32; the big
  40x80 set is the in-game option). `python3 web/tiles-coverage.py`: **100%**
  (175/175 drawable codes: every `chr(N)` in the code + monster/item letters,
  all 9 small sheets). One set, no fallback.
- Quirks: `CreatePuzzleLandscape` writes `data/levels/random/*.txt` at every
  start (in-memory FS, fine). The quickstart name prompt accepts an empty
  name. Messages use the 7x12 small font from `graphics/extra.png` (test.mjs
  rebuilds it only roughly).
- Next: stage 2 (explore + stairs). Main loop: `fprl.pas` KEYLOOP (`case k
  of`, ~line 11860); movement/`KeyEnter` ('a' = take stairs when on them).

### Stage 2 — Explore + stairs (done)
- **Explore key `z`** (free in the default keyset; `Q`/Esc = game menu,
  `a`/Enter = general action). **`<` / `>`**: on the right staircase take it
  (queues `KeyEnter`), else walk to the nearest *known* one and take it.
- Code: **`port/rvip.pas`** (unit `Rvip`: `RvipStart`, `RvipAuto`,
  `RvipStop`). BFS over `DngLvl[x, y].blKnown` tiles ("known grid" test;
  Lambdarogue never forgets floor except in darkness auras, airtype 5), 8
  directions, one step per game turn. Walkable = known, `intIntegrity = 0`
  or a closed door (floor 3: moving into it opens it, the expected "You open
  a door." does not stop the walk); never lava (20), locked door (24),
  locked gate (64), auras 1/2/3/5/6, known traps (airtype 8), shop entrances,
  NPC/monster squares. Stairs: floor 9 = down, 8 = up (none up on DLV 1).
- **Main-loop hook**: `fprl.pas` KEYLOOP: `k := RvipAuto;` before the poll
  (a running walk supplies the next movement key instead of reading one),
  and after the key loop `z` / `<` / `>` call `RvipStart`. `RvipAuto` also
  sets `web_at_cmd := true` (the command-prompt flag, passed to `be_poll`),
  cleared after the key loop.
- Stops: new message (`MessageLog.ShowTransMessage` → `web_message` →
  `web_msgs` counter, also sent to the page as `be_msg(text, fold)` with
  "(xN)" folding), hostile monster in view (explore refuses to start with
  one: "Not with an enemy in view."; a stair walk stops only when more come
  into view), any key/click (`be_pending`), a step that did not move,
  level change, death. "Nothing left to explore." / "You know no way down."
- Help: row 23 of "Keys used to perform actions" (`HelpScreenKeys`).
- Tested (`node web/test.mjs "2c1\rz>zzz" -q -m`, `LR_DEBUG=1` prints each
  step to stderr): explore of the start room and DLV 2, doors opened, stops
  at monsters; `>` walks to the down stairs and descends; `<` walks back up
  ("Returning to the Temple of Enoa"); Chromium shot
  `web/shots/stage2-explore.png`; checked native run with `z<>` in the
  random keys, 3 seeds × 20000: no range/overflow error.
- Open: explore sometimes stops right after passing a door (the game's
  move code checks the tile *behind* the door in the same turn, e.g. kicks a
  barrel there: an unexpected message stops the walk; harmless).
- Next: stage 3 (Enter menu + inventory). Enter (13) is mapped to
  `KeyEnter` in KEYLOOP (`case k of 13: k := Ord(KeyEnter)`): stage 3 must
  make Enter open the command menu instead (`a` stays the general action)
  and fix the help line "[ENTER] or [a]". Inventory: `InventoryScreen.pas`.
