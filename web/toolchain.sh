#!/bin/sh
# The toolchain that built LambdaRogue for the web in the RVIP cloud run
# (Ubuntu 24.04, 2026-09-26). Every command as run; paths are the cloud VM's.
# On the Mac: FPC trunk as in RVIP.md A-BOSS (~/Games/fpc-wasm), Emscripten's
# wasm-ld via -XP, Homebrew binaryen; set FPCW / LLVM / WASMOPT for web/build.sh.
set -e

# 0. The image had two dead PPAs (403) that made every apt run fail:
mkdir -p /tmp/aptdis
sudo mv /etc/apt/sources.list.d/*ondrej* /etc/apt/sources.list.d/*deadsnakes* /tmp/aptdis/ || true
sudo apt-get update -qq

# 1. FPC 3.2.2 (native checked build, web/check.sh, and bootstrap compiler for
#    trunk) + binaryen 108 (wasm-opt --asyncify). wasm-ld 18 (lld) was already
#    installed (/usr/bin/wasm-ld).
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fpc binaryen
#    NOT `npm i -g binaryen`: its wasm-opt is the JS build, shadows the apt one
#    on PATH and ran >10 min without finishing asyncify (build.sh calls
#    /usr/bin/wasm-opt explicitly).

# 2. FPC trunk (3.3.1, commit c71f0a97c8, 2026-09-26) as wasm32-wasip1 cross
#    compiler. PP/FPC must be given explicitly: without them the Makefile ran
#    `-iVSPTPSOTO` with an empty compiler name ("doesn't support target -").
#    No -j (crossall and crossinstall raced).
mkdir -p ~/fpc && cd ~/fpc
git clone --depth 1 https://gitlab.com/freepascal.org/fpc/source.git fpc-src
cd fpc-src
make crossall OS_TARGET=wasip1 CPU_TARGET=wasm32 PP=/usr/bin/ppcx64 FPC=/usr/bin/ppcx64
make crossinstall OS_TARGET=wasip1 CPU_TARGET=wasm32 PP=/usr/bin/ppcx64 FPC=/usr/bin/ppcx64 INSTALL_PREFIX=$HOME/fpc/fpc-wasm
#    -> ~/fpc/fpc-wasm/lib/fpc/3.3.1/ppcrosswasm32 + units/wasm32-wasip1/*

# 3. Browser check: Playwright 1.63 in a tools folder (not in the repo), with
#    the preinstalled Chromium (/opt/pw-browsers/chromium; `playwright install`
#    is not allowed here, its own headless shell build is missing).
mkdir -p ~/pwtools && cd ~/pwtools && npm init -y && npm i playwright
ln -sfn ~/pwtools/node_modules "$OLDPWD/web/node_modules" 2>/dev/null || true
#    run: CHROMIUM=/opt/pw-browsers/chromium node web/browser-check.mjs <shot> "<keys>"

# 4. Tile coverage script needs Pillow
pip install pillow --break-system-packages
