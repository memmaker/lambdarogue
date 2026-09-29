# LambdaRogue 1.6.4: handover

RVIP import, all stages done. Stages 1–6 ran in a Claude Code cloud session (private
`memmaker/lambdarogue-cloud`, deleted 2026-09-27); this public repo has the same history
without the procedure bundle.

## Source

- `LambdaRouge_1.6.4_src.zip` from the Google Code archive
  (https://code.google.com/archive/p/lambdarogue/downloads), 2012-11-17, Mario Donick.
  Upstream commit `798c8e6`. GNU GPL v2 (`docs/copying.txt`); soundtrack under its own CC
  licences (`music/LambdaRogue Soundtrack Credits.txt`).
- Free Pascal + JEDI-SDL (SDL 1.2); main program `fprl.pas`, data in `data/`, `graphics/`,
  `sound/`, `music/`. Sources are CRLF: edit with perl/binary Python.

## Build, test, deploy

- `sh web/build.sh` → `web/dist` (~35 s). FPC trunk 3.3.1 `wasm32-wasip1` cross compiler in
  `~/Games/fpc-wasm` (the BOSS build; `web/toolchain.sh` records how), Homebrew emscripten's
  `wasm-ld`, Homebrew `wasm-opt` (`--asyncify`, imports `be_poll be_sleep be_image`).
- `sh web/deploy.sh` (guard: clean + pushed tree) → https://ruzzoli.de/roguelikes/lambdarogue/.
  Repo: public **memmaker/lambdarogue** (remote `memmaker`, branch `main`).
- Headless: `node web/test.mjs "2c1\rz>zzz" -q -m` (quickstart → dungeon; prints screen text;
  `LR_DEBUG=1` traces explore). Browser: `node web/browser-check.mjs <shot> "<keys>"`
  (Playwright). Native range/overflow check: `sh web/check.sh "1 2 3" 20000` — does **not link
  on the Mac** (ppca64 link error); it worked in the cloud.
- Help: `web/make-help.py` reads the Docs entry `lambdarogue.html` in
  `~/Desktop/Games/Roguelikes/Docs`; `--page` writes `docs/web/lambdarogue-docs.html`.

## Port (case O, the BOSS way: FPC → wasm, the page only blits)

- **`port/webbe.pas`** (unit `WebBE`) replaces JEDI-SDL and FPC's Crt/Video/Keyboard/Process
  (the SDL units stay in the tree unused). Every `SDL_BlitSurface` → a blit record
  `{src, sx, sy, sw, sh, dst, dx, dy, alpha}` flushed with `be_frame`; `src = -1` = fill.
  Keys arrive as SDL 1.2 keysym + unicode (keypad = digits). Sound: SDL_mixer calls →
  `be_sfx` / `be_music*`; the page plays the game's own Ogg files (Sound and Music toggles,
  off by default; `rvip-sound.js` loaded but unused).
- **`port/rvip.pas`**: explore `z`, `<`/`>` walk to the nearest known stairs (BFS over
  `blKnown`), Enter menu (`RvipMenu`, groups as the help screen, current key bindings),
  inventory cursor + item menus (`RvipInventoryKey`; actions run by queueing the slot number
  into the game's own prompt via `web_type`). Hooks in `fprl.pas` KEYLOOP (`k := RvipAuto`,
  `13: k := RvipMenu`). `RvipAuto` sets `web_at_cmd` (prompt-line wait flag) and runs the
  autosave (`SaveGame`) when the page asks (`be_want_save`).
- **`port/rvipui.pas`**: pop-up menus drawn with the game's 10x20 font.
- Page: `web/index.html`, `web/lambdarogue.js` (windows Map / Log messages / Inventory /
  Visible, IndexedDB `lambdarogue` store `files`, mirrored every 15 s), `web/lr.js` (wasm,
  blits, input). Shared `../rvip-wm.js`, `../rvip-app.js` (help, export/import/new game hooks),
  `../rvip-sound.js` from the site.
- Tiles: the game's own sheets `graphics/tiles/tileset-2-small-<sex>-<profession>.png`
  (20x40, cell = chr − 32), 100% coverage (`web/tiles-coverage.py`). `web/lambdarogue.cfg`
  (in `fs.json`): SDL output, small tiles, 800x600, music on.
- Web-only changes in the game (`{$IFDEF WEB}`): no console-output option, empty character
  names refused (FPC's `FindFirst` hides `saves/.lambdarogue`), floor hint "[a]" only.
- Beacon (stage 9): `Player.pas` `GameOver` (real death only, not the hospital wake-up) and
  `WinGame` → `web_beacon` → `be_beacon` → `RvipWM.report`. Killer = text after the last " by "
  of the reason (`RvipKiller`). No `ev=quit` (the game has no give-up). Killer art:
  `lambdarogue()` in `roguelikes-index/killers/make.py`.
- Shrine: `~/Games/roguelikes-index/shrine/lambdarogue.html` (manual = in-game help topics;
  no walkthrough found).

## Open

- A won coffeebreak character stays saved (upstream `SaveGame` after the loop while HP > 0);
  loading it runs `WinGame` again → a second win report with a new id. Win path never played.
- Item prompts outside the inventory (shops, throw, quick keys) still take the typed slot number.
- Explore sometimes stops right after a door (the game acts on the tile behind it; harmless).
