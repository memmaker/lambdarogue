"""LambdaRogue's entry for the Docs page (~/Desktop/Games/Roguelikes/Docs),
written in the cloud run where that folder does not exist. Shaped like a
build-docs.py GAMES entry plus a guides.py GUIDES entry, so the Mac side can
paste GAME into GAMES and GUIDE into GUIDES; web/make-help.py renders both
into help.html and docs/web/lambdarogue-docs.html meanwhile.
Keys: the game's own help screen "Keys used to perform actions"
(fprl.pas HelpScreenKeys, default keyset) + the RVIP additions."""

PAGE = 'lambdarogue.html'

ABOUT = ('<p><strong>LambdaRogue: The Book of Stars</strong> (2006–2012) by Mario Donick is a '
         'graphical roguelike RPG written in Free Pascal with SDL. You are sent by Ahna, the priestess '
         'of the Temple of Enoa, to find the lost Book of Stars in the dungeons beneath the temple. '
         'Story mode has quests, NPCs, profession ranks and diplomas; Coffeebreak mode is a plain '
         'dive: reach dungeon level 20 and kill Eris, the evil deity.</p>'
         '<p>It is its own game, not a variant of Rogue, Hack or Angband: Greek gods you pray to, '
         'songs of magic learned from books, a resource workshop, life insurance at the hospital '
         'and hand-drawn tiles and portraits. Licence: GNU GPL v2 (<code>docs/copying.txt</code>).</p>')

TIPS = '<ul>' + ''.join(f'<li>{t}.</li>' for t in [
    'Sell old stuff frequently, to gain money for better items',
    'Dipping items into a well may lead to interesting results',
    'Try sacrificing items at altars',
    'Keep your rage level as high as possible to use special abilities',
    'Collect and sell resources at resource workshops for money',
    'If you are trapped in an antbee web, just wait some turns',
    'Think tactically: use the dungeon layout to your advantage',
    'Train your skills at an academy or using a book shelf',
    'Dig your way through rock in caves to find rare items',
    'To regain psychic power, sit down on a stool for a while',
    'If you feel trapped, search (<kbd>S</kbd>) for hidden doors',
    'If you are chased, run away and shut the doors behind you (<kbd>D</kbd>)',
    'If peaceful caveworms block your way, wait some turns',
    'Buy a life insurance at a hospital: dying then only knocks you out',
    'You can throw and shoot one tile farther than you can see',
    'Dropping one item onto another may combine them',
    'Defensive tactics (<kbd>-</kbd>) halve the damage you take and deal',
    'To use weapon special effects, your weapon skill must be at least the weapon\'s WP',
    'Grease your weapon with a potion to add its effect',
]) + '</ul>'

ESSENTIALS = [
    ('Moving', [('arrows / numpad', 'Move and attack (NumLock on)'), ('h j k l y u b n', 'Move (vi keys)'),
                ('z', 'Auto-explore (any key stops)'), ('< >', 'Walk to the known staircase and take it'),
                ('a', 'General action: stairs, chest, altar, well, crypt')]),
    ('Items', [('i', 'Inventory (cursor, Enter = item menu)'), ('g', 'Pick up item'),
               ('T', 'Throw an item'), ('f', 'Fire long-range weapon')]),
    ('Magic and gods', [('m', 'Songbook (spells)'), ('c', 'Chant last spell again'), ('p', 'Pray to your god'),
                        ('F1–F12', 'Quick keys (items, spells)')]),
    ('Game', [('Enter', 'Menu of all commands'), ('?', 'Help'), ('Esc / Q', 'Game menu: options, keys, save and quit')]),
]

ALL = [
    ('Enter', 'menu of all commands'), ('arrows / numpad / hjklyubn', 'move, attack'),
    ('z', 'auto-explore'), ('>', 'walk to known stairs down, take them'), ('<', 'walk to known stairs up, take them'),
    ('a', 'general action (stairs, chest, altar, well, crypt)'), ('g', 'pick up item'), ('i', 'show inventory'),
    ('m', 'show songbook (spells)'), ('c', 'chant last spell again'), ('t', 'talk to NPC or trader'),
    ('f', 'fire long-range weapon'), ('d', 'dig / disarm trap'), ('p', 'pray to your god'),
    ('s', 'show status screen'), ('L', 'show questlog'), ('.', 'rest one turn'), ('r', 'rest a number of turns'),
    ('I', 'identify tile'), ('Q / Esc', 'game menu'), ('S', 'search / steal'), ('C', 'show and reset quick keys'),
    ('D', 'close door'), ('M', 'show big minimap'), ('T', 'throw an item'), ('-', 'switch tactics'),
    ('x', 'use talent'), ('X', 'divine rage'), ('F1–F12', 'quick keys'), ('?', 'help'),
]

GAME = {
    'file': PAGE, 'name': 'LambdaRogue', 'tagline': 'LambdaRogue: The Book of Stars (1.6.4, 2012) — a graphical roguelike RPG by Mario Donick.',
    'info': {'About the game': ABOUT, 'Tips': TIPS},
    'essentials': ESSENTIALS, 'all': ALL,
}

GUIDE = {
    'How LambdaRogue differs': ABOUT,
    'Your first game': '<ol>'
        '<li>Title screen: <kbd>2</kbd> Quickstart, then <kbd>c</kbd> Coffeebreak for a plain dive (or <kbd>s</kbd> Story), '
        'pick a preset (<kbd>3</kbd> enchanter is the easiest), type a name, <kbd>Enter</kbd>.</li>'
        '<li>Press <kbd>i</kbd> and look at your items: the cursor and <kbd>Enter</kbd> show what you can do with each.</li>'
        '<li>Press <kbd>z</kbd> to explore; it stops when an enemy shows up. Walk into enemies to fight them.</li>'
        '<li>Hurt? Eat or drink healing items from the inventory, or rest with <kbd>r</kbd> when nothing is around.</li>'
        '<li>Press <kbd>&gt;</kbd> to walk to the known down staircase and descend.</li></ol>',
    'Staying alive': '<ul><li>Fight in corridors and doorways so only one enemy reaches you.</li>'
        '<li>Switch to defensive tactics (<kbd>-</kbd>) against strong monsters.</li>'
        '<li>Pray (<kbd>p</kbd>) when things go wrong; your god may help.</li>'
        '<li>Buy a life insurance at the hospital in the temple: dying then knocks you out instead of ending the game.</li></ul>',
    'Magic': '<p>Spells are songs: study (<kbd>s</kbd> in the inventory) a songbook item to learn one, chant with '
        '<kbd>m</kbd>, repeat with <kbd>c</kbd>; the quick keys <kbd>F1</kbd>–<kbd>F12</kbd> hold spells and items (<kbd>C</kbd> shows and resets them). Chanting costs psychic '
        'power (PP); sitting on a stool restores it.</p>',
}
