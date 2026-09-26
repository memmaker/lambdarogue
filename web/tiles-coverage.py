#!/usr/bin/env python3
"""RVIP step 4: how much of what LambdaRogue draws on the map has a sprite in
its own tile sheets (graphics/tiles/tileset-2-*.png, 20x40 cells from chr 32).
Drawable things = every chr(N) literal in the game code (terrain, items,
effects, buildings) + every monster Letter in data/monsters.txt + item letters
(Items.pas / items.txt codes). A cell counts when it has an opaque pixel."""
import re, glob, sys
from PIL import Image
codes = {}
for f in glob.glob('*.pas'):
	if f.lower().startswith(('sdl', 'smpeg')): continue
	for n in re.findall(r'chr\((\d+)\)', open(f, encoding='latin-1').read()):
		n = int(n)
		if 33 <= n <= 281: codes.setdefault(n, f)
lines = open('data/monsters.txt', encoding='latin-1').read().splitlines()
for i, l in enumerate(lines):
	if l.strip() == 'Letter:' and i + 1 < len(lines):
		v = lines[i + 1].strip()
		c = int(v) if v.isdigit() and len(v) > 1 else ord(v[0]) if v else 32
		if c > 32: codes.setdefault(c, 'monsters.txt')
lines = open('data/items.txt', encoding='latin-1').read().splitlines()
for i, l in enumerate(lines):
	if l.strip() == 'Letter:' and i + 1 < len(lines):
		v = lines[i + 1].strip()
		if v.isdigit(): codes.setdefault(int(v), 'items.txt')
sheets = sorted(glob.glob('graphics/tiles/tileset-2-small-*.png'))
worst = 100
for s in sheets:
	im = Image.open(s).convert('RGBA')
	W = im.size[0] // 20
	miss = []
	for c in sorted(codes):
		k = c - 32
		if k >= W: miss.append(c); continue
		box = im.crop((k * 20, 0, k * 20 + 20, 40))
		if box.getextrema()[3][1] == 0: miss.append(c)
	pct = 100.0 * (len(codes) - len(miss)) / len(codes)
	worst = min(worst, pct)
	print(f'{s}: {len(codes) - len(miss)}/{len(codes)} = {pct:.1f}%  missing: {[(c, codes[c]) for c in miss]}')
print(f'coverage (worst sheet): {worst:.1f}% of {len(codes)} drawable codes')
