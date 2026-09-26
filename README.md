**RVIP port** of LambdaRogue: The Book of Stars 1.6.4 (Mario Donick,
2006–2012), from the source archive `LambdaRouge_1.6.4_src.zip` (2012-11-17)
on the [Google Code archive](https://code.google.com/archive/p/lambdarogue/downloads);
commit `798c8e6` is that archive untouched.
Play: https://ruzzoli.de/roguelikes/lambdarogue/
Our changes: https://github.com/memmaker/lambdarogue/compare/798c8e6...main

LambdaRogue is an original graphical roguelike RPG (no ancestor game) written
in Free Pascal with JEDI-SDL: sent by the priestess Ahna, you search the
dungeons below the Temple of Enoa for the lost Book of Stars. Story mode has
quests, NPCs and professions; Coffeebreak mode is a dive to Eris on level 20.
The upstream manual, change log and licence are in `docs/`.

What this port adds (the game code is nearly untouched):
- **Web backend** `port/webbe.pas`: one unit replaces the JEDI-SDL units
  (SDL, SDL_image, SDL_mixer) and FPC's Crt/Video/Keyboard. Every
  `SDL_BlitSurface` becomes a record in a blit list that the page
  (`web/lr.js`) draws on a canvas; keys, mouse, images and sounds go through
  `be_*` wasm imports. Built with Free Pascal trunk for `wasm32-wasip1`
  and `wasm-opt --asyncify` (no Emscripten); files and saves in the
  browser's IndexedDB, autosave.
- **Windows** (`web/lambdarogue.js`, shared `rvip-wm.js`): the game screen
  as the Map window (whole-number zoom), Log messages, Inventory, Visible.
- **Explore** `z`, **`<` / `>`** walk to the known staircase and take it
  (`port/rvip.pas`).
- **Enter menu** of all commands with their current keys, **inventory
  cursor** with item menus (`port/rvip.pas`, `port/rvipui.pas`).
- **Tiles**: the game's own hand-drawn sheets (`graphics/tiles/`), nearest-
  neighbour. **Sound and music**: the game's own effects and soundtrack,
  off by default (top-bar toggles).

Controls: arrows / numpad / `hjklyubn` move and attack, `a` general action
(stairs, chests, altars, wells), `i` inventory, `m` songbook, `p` pray,
`z` explore, `<`/`>` stairs, Enter command menu, `?` help, Esc game menu.
The Help button opens the game guide.

Build: `sh web/build.sh` → `web/dist` (FPC trunk wasm32-wasip1 cross
compiler, `wasm-ld`, `wasm-opt`; see `web/toolchain.sh`). Test:
`node web/test.mjs "<keys>"`. Deploy: `sh web/deploy.sh`. Notes: `HANDOVER.md`.

Credits: game, graphics and text by Mario Donick; character photos by the
DeviantART artists in `docs/image credits.txt`; sound effects from PacDV and
Partners in Rhyme (`sound/sound credits.txt`); soundtrack by Nagual Art,
BLUnderwood and Alvaro M. Rocha under Creative Commons licences
(`music/LambdaRogue Soundtrack Credits.txt`). Licence: GNU GPL v2
(`docs/copying.txt`); the soundtrack keeps its own CC licences.
Web port: memmaker.
