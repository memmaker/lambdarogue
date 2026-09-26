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

### Stage 3 — Enter menu + inventory (done)
- **Enter menu**: `RvipMenu` in `port/rvip.pas`, hooked in `fprl.pas`
  KEYLOOP (`case k of 13: k := RvipMenu`; `a` stays the general action, so
  Enter does nothing else at the prompt; keypad Enter too). Two levels:
  groups (m Move and explore, i Items, g Magic and gods, p People and
  fighting, n Information, q Game) as the help screen "Keys used to perform
  actions" groups them, then the commands with their *current* keys (the
  `Key*` variables, so rebinding shows) incl. `z`, `<`, `>`. The chosen
  key is returned as `k` (runs as if typed). Help line changed to
  "[a] … ([ENTER]: menu of all commands)".
- **Pop-up drawing** (`port/rvipui.pas`, unit `RvipUI`): `UIMenu(title,
  entries, cur)` draws a box sized to its content (longest entry + 1 space
  each side, one row per entry, title row) with the game's own 10x20 font
  over a filled rectangle — new backend primitive `web_fill` = blit record
  with `src = -1`, colour in `sx` (page: `fillRect`). Keys: arrows / 8 2
  move, Enter / Space / 5 / 6 / Right choose, Esc / 0 close, 4 / Left back,
  the entry's key (`x` or `[x]`) runs it; mouse hover moves, click chooses,
  right click closes.
- **Inventory** (`InventoryScreen.ShowInventory`, `{$IFDEF WEB}`): the
  prompt `GetKeyInput('[i]nfo …')` is replaced by `RvipInventoryKey`
  (cursor bar over slot rows 5–20 or the equipment slots; up/down or 8/2
  move, Tab / Left / Right / 4 / 6 switch inventory ↔ equipment, Enter /
  Space / 5 / click = item menu of the fitting actions: eat/drink, study,
  equip, grease, drop or sell, examine; equipment: remove, details; `+` =
  main action (consume > study > equip > examine), `-` drop, `*` examine,
  0 / . / Esc close; the game's own letters c s d e i g r D act on the
  cursor item). **How actions run: key queue** — `RvipInventoryPreselect`
  queues the cursor slot number + Enter (`web_type`) which the action's own
  `GetTextInput('Which item …')` prompt reads; `r` on equipment queues the
  slot letter for `RemoveItem`'s prompt; leftovers are dropped
  (`web_untype`). After an action the list reopens unless a monster is in
  view (`RvipInventoryClose`).
- Tested headless: menu → Items → inventory opens; item menu → `c` eats
  the Aspirin (x20 → x19); `+` eats the Meat; equipment → `r` removes the
  Sword into slot 3. Chromium shots `web/shots/stage3-menu.png`,
  `web/shots/stage3-inventory.png`. Checked native run (3 seeds × 20000
  random keys, Enter included) found a hang (cursor loop over an empty
  inventory, fixed) and no range/overflow error; `check.sh` now reports
  hangs (timeout 300 s).
- Not done: other item prompts outside the inventory (shops, throw, quick
  keys) still take the typed slot number (the list is on screen there).
  Numpad-only in shops untested.
- Next: stage 4 (tiles). Decided in stage 1: the game's own sheets, 100%
  coverage; stage 4 = check sprites at cell size and nearest-neighbour
  scaling in the page.

### Stage 4 — Tiles (done)
- **Tile set**: LambdaRogue's own (the only one; decided in stage 1,
  `web/tiles-coverage.py`: 100% of 175 drawable codes on all 9 small
  sheets). Source: `graphics/tiles/tileset-2-small-<m|f>-<soldier|archer|
  enchanter|thief>.png` (20x40 cells, cell = chr − 32; the player sprite
  differs per sex/profession), `tileset-2-small-old.png` (old look option),
  `tileset-2-big-*` (40x80, option "small tiles = False"). Font sheets:
  `tileset-1.png` (10x20, 4 colour rows), `graphics/extra.png` (7x12 small
  font, icons, UI pieces).
- **Loader**: `BaseOutput.pas` `InitGraphics` / `LoadImage_Tiles(prof, sex)`
  → `IMG_Load` → `be_image(id, path)`; the page (`web/lr.js`) loads the PNG
  by URL (asyncified wait) and keeps it as a surface; `BigCharXY` blits the
  cell. Unknown grids are not drawn (black); "halfdark" shading = the
  sheet's semi-transparent cells blitted on top (alpha blits).
- **Pref**: `web/lambdarogue.cfg` (packed into `fs.json`): `UseSDL = True`,
  `SmallTiles = True`, `1024x768 = False` (800x600 screen; the in-game
  option switches to 1024x768, `be_screen` resizes the canvas).
- **Scale**: the game draws 1:1 into an 800x600 canvas; the page zooms the
  canvas by whole numbers with CSS `image-rendering: pixelated`
  (`imageSmoothingEnabled = false` for blits): nearest-neighbour only.
  Checked: `web/shots/stage4-tiles-2x.png` (every cell of the soldier sheet
  at 2x: player, NPCs, monsters, rings, potions, terrain), 
  `web/shots/stage4-zoom2-crop.png` (in-game at 2x, crisp).
- Notes: letters J V X Y o q t in the sheet are ornamental glyphs, not
  sprites; no monster or item uses them (monster letters are all sprites).
- Next: stage 5 (web page with `rvip/web/rvip-wm.js` windows).

### Stage 5 — Web page (done in the cloud; not deployed)
- Page: `web/index.html` (BOSS layout: top bar Help · Windows ▾ · Sound ·
  Music · Export/Import save · New game), `web/lambdarogue.js` (windows,
  lists, IndexedDB, autosave, help, overlay), engine `web/lr.js` (wasm,
  blits, keys, mouse, Asyncify), shared `rvip-wm.js` / `rvip-sound.js`
  copied from `rvip/web/` by `web/build.sh` (not forked).
- Windows (rvip-wm.js): **Map** (the game's 800x600 screen canvas; whole-
  number zoom ≥ 1, A−/A+ on its title bar; when the screen is bigger than
  the window it scrolls with the player: the game sends the hero's screen
  pixel `be_hero` from `RvipLists`, the page calls `RvipWM.center`),
  **Log messages** (`be_msg` from `MessageLog.ShowTransMessage`, repeats
  folded by the game), **Inventory** (inventory + equipment sections, sent
  by the game `be_lists` at every command prompt, colours = the game's own
  item name colours: white, yellow rare, purple unique/set, green magic),
  **Visible** (monsters + items in line of sight, `RvipWM.visible`).
  Default on: all four (multi: map left, inventory/visible right, log at
  the bottom); one-window mode = map only. Layout, fonts, zoom and sound
  toggles are saved in IndexedDB (`web-layout.json`).
- Prompt line: `web_prompt` from `Input.GetKeyInput` / `GetTextInput` and
  every new message → `RvipWM.prompt.text`; `be_poll(atcmd)` →
  `RvipWM.prompt.wait` (`web_at_cmd` set by `RvipAuto` at the KEYLOOP).
- Persistence: IndexedDB database `lambdarogue`, store `files`: `saves/*`,
  `lambdarogue.cfg`, `web-layout.json`; loaded into the WASI tree before
  start, mirrored every 15 s, on `be_sync` (after autosave), tab hidden,
  pagehide. Autosave: the page raises `be_want_save` every 2 min / tab
  hidden; `RvipAuto` (idle at the command prompt) calls the game's own
  `SaveGame` (note: with a life insurance the latest save is the restore
  point; that was also true for any manual save+quit). Export downloads the
  `.lambdarogue` files, Import adds one, New game deletes all saves.
  Quit/end → "Play again" overlay; crashes (also unhandled rejections) show
  a message. `beforeunload` warns while the game runs.
- Tested with Playwright + Chromium from `web/dist` served by
  `python3 -m http.server` (`web/browser-check.mjs`, new `{reload}` and
  `{eval:…}` steps): `web/shots/stage5-page.png` (all windows filled),
  `stage5-reload.png` (character "test" saved with Esc → 3, page reloaded,
  save still listed), `stage5-end.png` (title → 5 quit → overlay; one-
  window mode leaves only the map). No console errors.
- **Not done here**: the page is not live. `web/deploy.sh` is written
  (guard: clean + pushed tree, then rsync to
  `/var/www/ruzzoli.de/roguelikes/lambdarogue/`) but never run in the
  cloud (no ruzzoli.de key). The Mac runs `sh web/build.sh && sh
  web/deploy.sh` and checks `https://ruzzoli.de/roguelikes/lambdarogue/`.
  Help button needs `help.html` (stage 6 `web/make-help.py`). Beacon
  (step 12), shrine link target and OG tags are later stages.
- Next: stage 6 (docs + sound).
