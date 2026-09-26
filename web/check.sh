#!/bin/sh
# RVIP stage 1 "ASan run" for Pascal (RVIP.md A-BOSS): native build with
# range/overflow/IO/stack checks and line info, headless backend of
# port/webbe.pas feeding random keys after a scripted game start.
# Usage: sh web/check.sh [seeds] [keys]   (runs in a scratch copy)
set -e
cd "$(dirname "$0")/.."
B=${TMPDIR:-/tmp}/lr-check
rm -rf "$B" && mkdir -p "$B/obj" "$B/run"
fpc -dWEB -Mobjfpc -Cr -Co -Ci -Ct -gl -Fuport -FU"$B/obj" -FE"$B/obj" fprl.pas | grep -E "Error|Fatal" || true
cp -r data graphics saves lambdarogue.cfg "$B/run/"
cd "$B/run"
for s in ${1:-1 2 3 4 5}; do
	rm -f saves/*.lambdarogue
	echo "seed $s:"
	LR_SEED=$s LR_MAX=${2:-20000} LR_KEYS="$(printf '2 \r\rtester\r\r\r\r')" timeout 600 "$B/obj/fprl" > out.txt 2>&1 || true
	grep -v "^STATUS INFO" out.txt | tail -15
done
