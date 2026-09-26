#!/bin/sh
# Upload web/dist to https://ruzzoli.de/roguelikes/lambdarogue/ (RVIP.md W9).
# Written in the cloud run, never run there: run it on the Mac after
# `sh web/build.sh`, from a clean, pushed tree.
set -e
cd "$(dirname "$0")/.."
# guard (RVIP.md step 9): deploy only committed and pushed work
if [ -n "$(git status --porcelain)" ]; then echo "deploy: working tree is dirty, commit first" >&2; exit 1; fi
git fetch -q origin
if [ -n "$(git log --oneline @{u}..HEAD 2>/dev/null)" ] || ! git rev-parse -q --verify @{u} >/dev/null; then
	echo "deploy: HEAD is not pushed to its upstream" >&2; exit 1
fi
[ -f web/dist/lr.wasm ] || { echo "deploy: build first (sh web/build.sh)" >&2; exit 1; }
ssh ruzzoli.de 'sudo mkdir -p /var/www/ruzzoli.de/roguelikes/lambdarogue && sudo chown -R felix:www-data /var/www/ruzzoli.de/roguelikes/lambdarogue'
rsync -rtz --delete web/dist/ ruzzoli.de:/var/www/ruzzoli.de/roguelikes/lambdarogue/
