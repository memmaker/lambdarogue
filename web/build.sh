#!/bin/sh
# Build LambdaRogue for the browser into web/dist: Free Pascal trunk
# (wasm32-wasip1 cross compiler, see web/toolchain.sh), then
# wasm-opt --asyncify so SDL_PollEvent / delay / IMG_Load can wait for the page.
# Test: node web/test.mjs "keys"; check: sh web/check.sh; deploy: web/deploy.sh.
set -e
cd "$(dirname "$0")/.."
FPCW=${FPCW:-$HOME/Games/fpc-wasm/lib/fpc/3.3.1}
U=$FPCW/units/wasm32-wasip1
LLVM=${LLVM:-$(ls -d /opt/homebrew/Cellar/emscripten/*/libexec/llvm/bin | tail -1)}
OUT=web/dist
rm -rf "$OUT" web/build && mkdir -p "$OUT" web/build
"$FPCW/ppcrosswasm32" -Twasip1 -O2 -dWEB -Mobjfpc -Fu"$U/rtl" -Fu"$U/rtl-objpas" -Fu"$U/rtl-extra" -Fu"$U/fcl-base" \
	-Fuport -FUweb/build -FEweb/build -XP"$LLVM/" -oweb/build/lr.wasm fprl.pas | grep -E "Error|Fatal" && exit 1
"${WASMOPT:-$(command -v wasm-opt)}" -O2 --enable-reference-types --enable-bulk-memory --enable-sign-ext --enable-nontrapping-float-to-int \
	--enable-mutable-globals --enable-multivalue --asyncify \
	--pass-arg=asyncify-imports@lr.be_poll,lr.be_sleep,lr.be_image \
	web/build/lr.wasm -o "$OUT/lr.wasm"
# the game's files for the WASI file system (the server denies *.txt, so
# they travel inside fs.json); graphics only as empty names for fileexists(),
# the page loads the images themselves by URL
python3 - <<'PY'
import os, json, base64
fs = {}
for top in ('data',):
	for d, _, names in os.walk(top):
		for n in names: fs[os.path.join(d, n)] = base64.b64encode(open(os.path.join(d, n), 'rb').read()).decode()
for d, _, names in os.walk('graphics'):
	for n in names: fs[os.path.join(d, n)] = ''
fs['lambdarogue.cfg'] = base64.b64encode(open('web/lambdarogue.cfg', 'rb').read()).decode()
fs['saves/'] = ''
json.dump(fs, open('web/dist/fs.json', 'w'))
PY
cp -r graphics sound music "$OUT/"
cp web/index.html web/lr.js web/lambdarogue.js "$OUT/"
cp -r web/vendor "$OUT/vendor"
python3 web/make-help.py > "$OUT/help.html"
rm -rf web/build
ls -la "$OUT"
