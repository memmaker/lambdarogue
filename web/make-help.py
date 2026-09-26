#!/usr/bin/env python3
"""Writes the in-page game guide for the web build (stdout -> dist/help.html)
and, with --page FILE, the standalone Docs page (docs/web/lambdarogue-docs.html).

On the Mac the game part comes from ~/Desktop/Games/Roguelikes/Docs
(build-docs.py + guides.py) like BOSS's make-help.py; that folder was not
available in the cloud run, so the entry lives in web/docs_entry.py (to be
merged into the Docs by hand) and is used when the Docs lack it."""
import html, importlib.util, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = os.path.expanduser('~/Desktop/Games/Roguelikes/Docs')
sys.path.insert(0, HERE)
import docs_entry as E   # noqa: E402

game, guide = E.GAME, dict(E.GUIDE)
if os.path.exists(os.path.join(DOCS, 'build-docs.py')):
    sys.path.insert(0, DOCS)
    spec = importlib.util.spec_from_file_location('build_docs', os.path.join(DOCS, 'build-docs.py'))
    docs = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(docs)
    from guides import GUIDES   # noqa: E402
    game = next((g for g in docs.GAMES if g['file'] == E.PAGE), game)
    guide = dict(GUIDES.get(E.PAGE, guide))
esc = html.escape


def kbd(k):
    return '<span class="or">/</span>'.join(f'<kbd>{esc(p.strip())}</kbd>' for p in k.split(' / '))


SAVING = '''<ul>
<li><strong>Saving is automatic.</strong> Your character is stored in this browser (IndexedDB): the page asks the game to save every two minutes and when you switch tabs, and the game saves when you quit (<kbd>Esc</kbd> → <kbd>3</kbd> Save and Quit).</li>
<li>Reloading the page brings you back to the title screen; <kbd>1</kbd> Create / Continue lists your saved characters.</li>
<li>Without a life insurance, death deletes the character's save, as in the original. With one, you wake up at the hospital from the last save.</li>
<li><em>Export save</em> downloads your <code>.lambdarogue</code> files; <em>Import save</em> adds one (also a save from the desktop version 1.6.x). <em>New game</em> deletes all saved characters in this browser.</li>
<li>Options (tiles, volume, keys) are kept in <code>lambdarogue.cfg</code> in the same storage. Private windows and "clear site data" delete everything: export first.</li>
</ul>'''

WEB = '''<ul>
<li>The Map window is the game's own 800×600 screen, scaled up by whole numbers only (sharp pixels). <em>A−</em>/<em>A+</em> on a window's title bar change its zoom or text size; <em>Windows ▾</em> switches between one window and several (map, log, inventory, visible monsters and items) and resets the layout.</li>
<li>The mouse works as in the original: hover over the status area or the quickbar for details, click the quickbar, right-click to move it.</li>
<li><strong>Sound</strong> and <strong>Music</strong> in the top bar are off at the start; the game's own volume options are in <kbd>Esc</kbd> → <kbd>1</kbd>.</li>
<li>Console (text) mode of the desktop version is not available in the browser.</li>
<li>If the game ever crashes, a message appears at the top; reload the page to continue from the last autosave.</li>
</ul>'''

KEY_HINTS = [('?', 'In-game help'), ('z', 'Auto-explore: walk to the nearest unexplored spot'),
             ('Enter', 'Menu of all commands'), ('i', 'Inventory with a cursor: Enter = everything you can do with the item'),
             ('>', 'Go down (walks to the nearest known staircase)'), ('Esc', 'Game menu: options, keys, save and quit')]


def dl(items):
    return '<dl>' + ''.join(f'<dt>{kbd(k)}</dt><dd>{esc(d)}</dd>' for k, d in items) + '</dl>'


def section(anchor, title, body):
    return f'<h2 id="h-{anchor}">{esc(title)}</h2>{body}'


def body():
    parts = []
    toc = [('about', 'About the game'), ('keys', 'Keyboard controls'), ('saving', 'Saving your game'),
           ('tips', 'Tips'), ('guide', "New player's guide"), ('web', 'Playing in the browser'), ('version', 'About this version')]
    parts.append('<p>' + esc(game['tagline']) + '</p><ul class="toc">' +
                 ''.join(f'<li><a href="#h-{a}">{esc(t)}</a></li>' for a, t in toc) + '</ul>')
    g = dict(guide)
    parts.append(section('about', 'About the game', g.pop('How LambdaRogue differs', game['info']['About the game'])))
    ess = ''.join(f'<div class="box"><h3>{esc(cat)}</h3>{dl(items)}</div>' for cat, items in game['essentials'])
    all_keys = game['all']() if callable(game['all']) else game['all']
    full = ''.join(f'<div>{kbd(k)}<span>{esc(d)}</span></div>' for k, d in all_keys)
    parts.append(section('keys', 'Keyboard controls',
                         '<div class="box key"><h3>The keys to remember</h3>' + dl(KEY_HINTS) + '</div>'
                         '<h3>Essential keys</h3><div class="grid">' + ess + '</div>'
                         '<details><summary>Complete key list (' + str(len(all_keys)) + ' commands)</summary>'
                         '<div class="all">' + full + '</div></details>'))
    parts.append(section('saving', 'Saving your game', SAVING))
    parts.append(section('tips', 'Tips', game['info']['Tips']))
    parts.append(section('guide', "New player's guide", ''.join(f'<h3>{esc(t)}</h3>{b}' for t, b in g.items())))
    parts.append(section('web', 'Playing in the browser', WEB))
    parts.append('<h2 id="h-version">About this version</h2><ul>'
                 '<li>Based on <strong>LambdaRogue 1.6.4</strong> by Mario Donick (2012-11-17), source archive '
                 '<code>LambdaRouge_1.6.4_src.zip</code> from the Google Code archive '
                 '(<a href="https://code.google.com/archive/p/lambdarogue/downloads">code.google.com/archive/p/lambdarogue</a>).</li>'
                 '<li>Our changes (web backend replacing SDL, auto-explore, stair walking, command menu, inventory cursor '
                 'and item menus, windows, web build): <a href="https://github.com/memmaker/lambdarogue">github.com/memmaker/lambdarogue</a> '
                 '(first commit = the untouched source).</li>'
                 '<li>Credits: game, graphics and text by Mario Donick; character photos, sounds and the Creative Commons '
                 'soundtrack as listed in <code>docs/image credits.txt</code>, <code>sound/sound credits.txt</code> and '
                 '<code>music/LambdaRogue Soundtrack Credits.txt</code>. Licence GNU GPL v2.</li></ul>')
    return '\n'.join(parts)


if len(sys.argv) > 2 and sys.argv[1] == '--page':
    css = open(os.path.join(HERE, 'index.html'), encoding='utf-8').read()
    style = css[css.index(':root'):css.index('</style>')]
    out = ('<!DOCTYPE html>\n<html lang="en"><head><meta charset="utf-8">'
           '<meta name="viewport" content="width=device-width, initial-scale=1"><title>LambdaRogue — keys and guide</title>'
           '<style>' + style.replace('overflow: hidden;', '') + '\n#help-body{max-width:980px;margin:0 auto}</style></head>'
           '<body><div id="help-body"><h1 style="color:var(--accent)">LambdaRogue</h1>' + body() + '</div></body></html>\n')
    os.makedirs(os.path.dirname(sys.argv[2]) or '.', exist_ok=True)
    open(sys.argv[2], 'w', encoding='utf-8').write(out)
else:
    print(body())
