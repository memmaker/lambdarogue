#!/bin/sh
# Upload web/dist to https://ruzzoli.de/roguelikes/lambdarogue/ (RVIP.md W9).
# Run after `sh web/build.sh`, from a clean, pushed tree.
set -e
cd "$(dirname "$0")/.."
# guard (RVIP.md step 9, as ~/Games/roguelikes-index/deploy.sh): committed and pushed only
git fetch -q && [ -z "$(git status --porcelain)" ] && [ "$(git rev-parse @)" = "$(git rev-parse @{u})" ] || { echo "commit + push first"; exit 1; }
[ -f web/dist/lr.wasm ] || { echo "deploy: build first (sh web/build.sh)" >&2; exit 1; }
ssh ruzzoli.de 'sudo mkdir -p /var/www/ruzzoli.de/roguelikes/lambdarogue && sudo chown -R felix:www-data /var/www/ruzzoli.de/roguelikes/lambdarogue'
rsync -rtz --delete web/dist/ ruzzoli.de:/var/www/ruzzoli.de/roguelikes/lambdarogue/
