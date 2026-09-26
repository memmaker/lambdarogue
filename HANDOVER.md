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

(nothing yet — start with stage 1)
