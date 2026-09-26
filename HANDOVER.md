# LambdaRogue 1.6.4: handover

## Cloud experiment (read this first)

The RVIP import ran in a Claude Code **cloud** session (stages 1–6), not on
the maintainer's Mac. The procedure bundle it worked from (`rvip/`: a
snapshot of RVIP.md, the shared page code, the BOSS/Prospector templates,
`rvip/LESSONS.md`) lived in the private repo **memmaker/lambdarogue-cloud**
(`~/Games/lambdarogue-cloud`); this public repo has the same history without
`rvip/` (`git filter-repo`). The lessons are merged into
`~/Games/rvip-tools/RVIP.md` (O-LambdaRogue). `web/build.sh` takes the shared
`rvip-wm.js` / `rvip-sound.js` from `~/Games/rvip-tools/web/`.

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

### Stage 6 — Docs + sound (done in the cloud; Docs page to merge on the Mac)
- **Sound**: the game's own SDL_mixer calls (`ExternSFX.PlaySFX`,
  `ExternMusic.PlayMusic`) → `Mix_PlayChannel` / `Mix_PlayMusic` /
  `Mix_HaltMusic` / `Mix_VolumeMusic` in `port/webbe.pas` → `be_sfx(path,
  vol)`, `be_music(path, loops, vol)`, `be_music_vol(v)`,
  `be_music_playing()`. The page (`web/lambdarogue.js` `sound`) plays the
  game's `sound/*.ogg` and `music/*.ogg` with `Audio` elements. **Top-bar
  toggles Sound and Music, both off by default**, saved in
  `web-layout.json`. `web/lambdarogue.cfg` turns the game's music option on
  (`PlayMusic = True`, `VolumeMusic 64`) so the game names its songs; the
  in-game volume options still work. (`rvip-sound.js` is loaded but not
  used: it only plays `.wav` sequences; the game's files are Ogg.)
- Tested (Chromium): at start both toggles off, the game still sends
  `music/3.ogg` and `sound/steps.ogg` (on the stairs); after clicking
  Music + Sound a music `Audio` plays (`paused = false`).
- **Docs**: `web/docs_entry.py` holds the Docs entry (tagline, About,
  Tips = the game's own tip-of-the-day list, essentials, complete key list
  from the game's help screen + z / < > / Enter, new-player guide,
  "In the browser" part, credits, GPL v2). `web/make-help.py` renders it
  into `web/dist/help.html` (Help button, run by `web/build.sh`; it prefers
  `~/Desktop/Games/Roguelikes/Docs` when that exists) and with `--page`
  into **`docs/web/lambdarogue-docs.html`** (standalone, BOSS help shape).
  Shot: `web/shots/stage6-help.png`.
- **Mac side**: add `GAME` / `GUIDE` from `web/docs_entry.py` to
  `build-docs.py` `GAMES` and `guides.py` `GUIDES` (file
  `lambdarogue.html`), run `python3 build-docs.py`, rebuild `help.html`.
- Next: stage 7 (publish: memmaker repo exists already —
  github.com/memmaker/lambdarogue; README with upstream link and compare
  view, tree entry, deploy from the Mac).

### Stage 7 — Publish (done, Mac)
- **Mac check** (browser pane, own tab, `web/dist` served locally): title →
  quickstart, all four windows, tiles, `z` explore, `>` walk + descend,
  Enter menu → Items → inventory → item menu → eat (Aspirin x20 → x19),
  quit/autosave (`document.hidden` faked) → reload → Continue lists the
  character and restores it, Help, Sound/Music off at start. No console errors.
  **Fixed** (`42abb12` in the cloud history, `5e2e6d1` here): an empty
  character name saved `saves/.lambdarogue`, which FPC's Unix `FindFirst`
  skips as hidden, so the save vanished → the web build refuses empty names
  (both name prompts in `fprl.pas`, `{$IFDEF WEB}`); floor hints said
  "[ENTER] or [a]" → "[a]" (`UserInterface.pas`, `StringReplace` under WEB).
- **Toolchain (Mac)**: `web/build.sh` defaults to `~/Games/fpc-wasm` (FPC trunk
  3.3.1 @ 20e80cb5, the BOSS build; no rebuild needed), Homebrew emscripten
  6.0.10's `wasm-ld`, Homebrew `wasm-opt` 133. Build ~35 s.
- **Docs**: entry `lambdarogue.html` in `~/Desktop/Games/Roguelikes/Docs`
  (`build-docs.py` GAMES, `guides.py` GUIDES + SAVING); `web/make-help.py`
  reads it like Forays (the cloud's `web/docs_entry.py` is gone) and also
  writes `docs/web/lambdarogue-docs.html` with `--page`.
- **Repos**: this folder = public **memmaker/lambdarogue** (remote
  `memmaker`, branch `main`), history without `rvip/`; the cloud history is
  private **memmaker/lambdarogue-cloud** (`~/Games/lambdarogue-cloud`).
  Upstream commit `798c8e6`; README with the compare view.
- **Live**: https://ruzzoli.de/roguelikes/lambdarogue/ (`sh web/build.sh && sh
  web/deploy.sh`). Card on https://ruzzoli.de/roguelikes/ (`lambdarogue.png`:
  18 monster sprites from `tileset-2-big-m-soldier.png`, 40×80, on its stone
  floor, 384×160), tree: standalone original between DoomRL and Brogue
  (`li.insp`, 2006 · Mario Donick; year from the handover/`docs`, web check
  left for stage 8). og block in `web/index.html` by hand (image
  `roguelikes/lambdarogue.png`). The page title links to
  `../shrine/lambdarogue.html`, which stage 8 creates.

Next: stage 8 (shrine). Template `~/Games/roguelikes-index/shrine/forays.html`
(commit `0055d41`). Material:
- Manual/help: no manual file in the source drop; the in-game help screens
  (`?`, `fprl.pas` `HelpScreen*`, `HelpScreenKeys`), the tips list, the web
  guide (`dist/help.html`, Docs `lambdarogue.html`,
  `docs/web/lambdarogue-docs.html`).
- Licence: GNU GPL v2 (`docs/copying.txt`); soundtrack under its own CC
  licences (`music/LambdaRogue Soundtrack Credits.txt`); image and sound
  credits in `docs/image credits.txt`, `sound/sound credits.txt`.
- Changelog: `docs/ChangeLog.txt` (1.6.4 and earlier).
- Walkthrough: none in the source; check the web (Google Code wiki, RogueBasin,
  the author's site), else report as missing.
- Links to add: Info button on the card, ✦ in the tree entry, game-title link
  on the shrine page to `../lambdarogue/`; shrine page gets its own og block
  (image `roguelikes/lambdarogue.png`).

### Stage 8 — shrine (done)
- **Shrine**: https://ruzzoli.de/roguelikes/shrine/lambdarogue.html
  (`~/Games/roguelikes-index/shrine/lambdarogue.html` + `shrine/lambdarogue/`:
  `manual.html` = the in-game help topics a–o from `data/story/help_*.txt` +
  the key screen with this build's keys (developer's postal address left
  out), `changelog.txt` = `docs/ChangeLog.txt`, `license.txt` = GPL v2 +
  soundtrack credits). og block by hand (image `roguelikes/lambdarogue.png`).
  Info button on the card, ✦ on the tree entry; the game title already
  linked here. roguelikes-index commit `12dce46`.
- **Lineage checked on the web**: 0.1 (alpha 1) 20 July 2006 (change log,
  first dated entry 14 July 2006; RogueBasin "Jul, 2006 (0.1)"), started as
  a C++ experiment, moved to Free Pascal (author on Pascal Game Development,
  21 May 2010); 1.0 on 3 Aug 2008, SourceForge → Google Code 18 Aug 2009
  (SourceForge news); 1.6.4 patch 10 June 2012, source 17 Nov 2012 (Google
  Code archive JSON); last version 1.7 on itch.io, 29 Dec 2018 (RogueBasin).
  Tree entry (2006 · Mario Donick, standalone) confirmed. Tile artist:
  game credits "Cecilia Favo De Mel", RogueBasin "Cecilia Souza Santos".
- **Missing**: no manual file (help screens used), no walkthrough or
  strategy guide found (lambdarogue.net and its forum gone, fandom wiki
  unreachable), no cheats (debug console `CheatCodes` unreachable: its key
  is commented out). Changelog exists.
- Open: itch.io and SourceForge answer 403 to scripts (Cloudflare), Pascal
  Game Development has an expired TLS certificate; links kept.

Next: stage 9 (graveyard + leaderboard).
