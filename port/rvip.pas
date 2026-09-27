{ RVIP additions to LambdaRogue (web build): auto-explore on 'z', stair
  walking on '<' / '>' (RVIP.md steps 2 and 3) and the command menu on
  Enter (step 3b, RvipMenu).

  Hook (fprl.pas KEYLOOP): RvipAuto is asked before every key poll at the
  command prompt; while a walk runs it returns the next movement key (or
  KeyEnter when '<' / '>' is pressed on the staircase; a walk stops on
  arrival) instead of reading one. The walk is a BFS over
  what the player knows (DngLvl[].blKnown), one step per turn. It stops on a
  new message (MessageLog.ShowTransMessage -> web_msgs), a hostile monster
  in view (explore; a stair walk stops when more come into view), any key,
  or a step that did not move. It avoids known traps, harmful auras and lava,
  walks through closed doors (moving into one opens it) and never tries
  locked doors or gates. }
unit Rvip;

{$mode objfpc}

interface

procedure RvipStart(c: char);
procedure RvipStop;
function RvipAuto: longint;
function RvipMenu: longint;

implementation

uses WebBE, SysUtils, Constants, RandomArea, Player, Items, Quests, MessageLog, BaseOutput, RvipUI, DrawDungeon, FileIO;

const
  MODE_NONE = 0; MODE_EXPLORE = 1; MODE_DOWN = 2; MODE_UP = 3;
  DX: array [0..7] of integer = (0, 0, 1, -1, 1, -1, 1, -1);
  DY: array [0..7] of integer = (-1, 1, 0, 0, -1, -1, 1, 1);
var
  mode: integer = MODE_NONE;
  firstauto: boolean = false;   { the first RvipAuto after RvipStart }
  lastmsgs, expectmsgs, lastx, lasty, lastlevel, startmon: longint;
  stepped: boolean;

function DirKey(d: integer): char;
begin
  case d of
    0: DirKey := KeyNorth;
    1: DirKey := KeySouth;
    2: DirKey := KeyEast;
    3: DirKey := KeyWest;
    4: DirKey := KeyNorthEast;
    5: DirKey := KeyNorthWest;
    6: DirKey := KeySouthEast;
  else DirKey := KeySouthWest;
  end;
end;

function Inside(x, y: integer): boolean;
begin
  Inside := (x >= 1) and (y >= 1) and (x <= DngMaxWidth) and (y <= DngMaxHeight);
end;

function Occupied(x, y: integer): boolean;
var m: integer;
begin
  Occupied := true;
  for m := 1 to 9 do
    if (NPC[m].intX = x) and (NPC[m].intY = y) then exit;
  for m := 1 to 550 do
    if (Monster[m].intX = x) and (Monster[m].intY = y) and (Monster[m].intHP > 0) then exit;
  Occupied := false;
end;

{ may the walk step onto this known tile? }
function Walkable(x, y: integer): boolean;
begin
  Walkable := false;
  if not Inside(x, y) then exit;
  with DngLvl[x, y] do
  begin
    if not blKnown then exit;
    if (intIntegrity <> 0) and (intFloorType <> 3) then exit;   { walls; 3 = closed door }
    if intFloorType in [20, 24, 64] then exit;                    { lava, locked door, locked gate }
    if intAirType in [1, 2, 3, 5, 6, 8] then exit;                { harmful auras, known trap }
    if intBuilding > 0 then exit;                                 { shop entrance }
  end;
  Walkable := true;
end;

function IsTarget(x, y: integer): boolean;
var d: integer;
begin
  IsTarget := false;
  case mode of
    MODE_DOWN: IsTarget := DngLvl[x, y].intFloorType = 9;
    MODE_UP: IsTarget := DngLvl[x, y].intFloorType = 8;
    MODE_EXPLORE:
      for d := 0 to 7 do
        if Inside(x + DX[d], y + DY[d]) and not DngLvl[x + DX[d], y + DY[d]].blKnown then
          exit(true);
  end;
end;

{ BFS from the player; first step towards the nearest target, -1 = none }
function NextDir: integer;
var
  first: array [1..DngMaxWidth, 1..DngMaxHeight] of shortint;
  qx, qy: array [0..DngMaxWidth * DngMaxHeight] of smallint;
  head, tail, x, y, nx, ny, d: longint;
begin
  NextDir := -1;
  fillchar(first, sizeof(first), $ff);
  head := 0; tail := 0;
  x := ThePlayer.intX; y := ThePlayer.intY;
  first[x, y] := 8;
  for d := 0 to 7 do
  begin
    nx := x + DX[d]; ny := y + DY[d];
    if Walkable(nx, ny) and (first[nx, ny] < 0) and not Occupied(nx, ny) then
    begin
      first[nx, ny] := d;
      qx[tail] := nx; qy[tail] := ny; inc(tail);
    end;
  end;
  while head < tail do
  begin
    x := qx[head]; y := qy[head]; inc(head);
    if IsTarget(x, y) then exit(first[x, y]);
    { walk through doors but not along them diagonally into the unknown }
    for d := 0 to 7 do
    begin
      nx := x + DX[d]; ny := y + DY[d];
      if Walkable(nx, ny) and (first[nx, ny] < 0) then
      begin
        first[nx, ny] := first[x, y];
        qx[tail] := nx; qy[tail] := ny; inc(tail);
      end;
    end;
  end;
end;

procedure RvipStop;
begin
  mode := MODE_NONE;
end;

procedure Say(const s: string);
begin
  ShowTransMessage(s, False);
  lastmsgs := web_msgs;
end;

procedure RvipStart(c: char);
var d: longint;
begin
  case c of
    'z': mode := MODE_EXPLORE;
    '>': mode := MODE_DOWN;
    '<': mode := MODE_UP;
  end;
  lastmsgs := web_msgs;
  expectmsgs := 0;
  stepped := false;
  firstauto := true;
  lastlevel := DungeonLevel;
  startmon := MonstersInView;
  if (mode = MODE_EXPLORE) and (startmon > 0) then
  begin
    if GetEnvironmentVariable('LR_DEBUG') <> '' then
      for d := 1 to 550 do
        with Monster[d] do
          if (intHP > 0) and Inside(intX, intY) and (intInvis = 0) and DngLvl[intX, intY].blLOS and DngLvl[intX, intY].blKnown then
            writeln(stderr, 'in view: ', strName, ' at ', intX, ',', intY, ' player ', ThePlayer.intX, ',', ThePlayer.intY);
    Say('Not with an enemy in view.');
    mode := MODE_NONE;
  end;
  if (mode = MODE_UP) and (DungeonLevel <= 1) then
  begin
    Say('There is no way up from here.');
    mode := MODE_NONE;
  end;
end;

{ ---- page windows (RVIP step 5): Inventory (+ equipment) and Visible, sent
  at every command prompt. Colours are the game's own item name colours
  (Items.SetItemNameColor: white, yellow = rare, purple = unique / set,
  green = magic) as CSS. }
function ItemColour(const name: string): string;
begin
  SetItemNameColor(name);
  case GlobalFontColor of
    FONTCOLOR_GREEN: ItemColour := '#7fd66b';
    FONTCOLOR_PURPLE: ItemColour := '#c890f0';
    FONTCOLOR_YELLOW: ItemColour := '#f0d060';
  else ItemColour := '#e8e8e8';
  end;
  GlobalFontColor := FONTCOLOR_WHITE;
end;

procedure RvipLists;
const
  SLOT: array [1..7] of string = ('Weapon', 'Armour', 'Hat', 'Shoes', 'Ring (left)', 'Ring (right)', 'Shield / extra');
var
  inv, vis: ansistring;
  i, t, x, y, m: longint;
  function Eq(i: longint): longint;
  begin
    case i of
      1: Eq := ThePlayer.intWeapon; 2: Eq := ThePlayer.intArmour; 3: Eq := ThePlayer.intHat;
      4: Eq := ThePlayer.intFeet; 5: Eq := ThePlayer.intRingLeft; 6: Eq := ThePlayer.intRingRight;
    else Eq := ThePlayer.intExtra;
    end;
  end;
begin
  inv := '=Inventory (' + IntToStr(ThePlayer.longGold) + ' credits)' + #10;
  for i := 1 to 16 do
  begin
    t := Inventory[i].intType;
    if t > 0 then
      inv := inv + ItemColour(Thing[t].strRealName) + #9 + Format('%2d ', [i]) + Thing[t].strName +
        ' x' + IntToStr(Inventory[i].longNumber) + #10;
  end;
  inv := inv + '=Equipment' + #10;
  for i := 1 to 7 do
  begin
    t := Eq(i);
    if t > 0 then
      inv := inv + ItemColour(Thing[t].strName) + #9 + SLOT[i] + ': ' + Thing[t].strName + #10;
  end;
  vis := '';
  for m := 1 to 550 do
    with Monster[m] do
      if (intHP > 0) and (intX >= 1) and (intY >= 1) and (intX <= DngMaxWidth) and (intY <= DngMaxHeight) and
        (intInvis = 0) and DngLvl[intX, intY].blLOS and DngLvl[intX, intY].blKnown then
        vis := vis + 'M' + chLetter + strName + #10;
  for x := 1 to DngMaxWidth do
    for y := 1 to DngMaxHeight do
      if (DngLvl[x, y].intItem > 0) and DngLvl[x, y].blLOS and DngLvl[x, y].blKnown then
      begin
        t := DngLvl[x, y].intItem;
        vis := vis + 'I*' + Thing[t].strName + #9 + ItemColour(Thing[t].strRealName) + #10;
      end;
  web_lists(inv, vis);
  { the player's screen pixel (DrawDungeon draws the hero at intBX, intBY + 1 in 20x40 cells) }
  web_hero(ThePlayer.intBX * 20 + 10, (ThePlayer.intBY + 1) * 40 + 20);
end;

function RvipAuto: longint;
var d: integer;
    ev: TSDL_Event;
begin
  web_at_cmd := true;
  RvipAuto := 0;
  if mode = MODE_NONE then
  begin
    RvipLists;
    { quiet autosave when the page asks (every 2 min / tab hidden) }
    if web_want_save and (ThePlayer.intHP > 0) and not ThePlayer.blDead then
    begin
      SaveGame(ThePlayer.strName, DungeonLevel);
      web_sync;
    end;
    exit;
  end;
  { disturbances }
  if web_pending then
  begin
    SDL_PollEvent(@ev);       { the key only stops the walk }
    RvipStop; exit;
  end;
  if (web_msgs - lastmsgs > expectmsgs) or (DungeonLevel <> lastlevel) or
    (ThePlayer.intHP < 1) then
  begin
    RvipStop; exit;
  end;
  if stepped and (ThePlayer.intX = lastx) and (ThePlayer.intY = lasty) and (expectmsgs = 0) then
  begin
    RvipStop; exit;
  end;
  if (mode = MODE_EXPLORE) and (MonstersInView > 0) then
  begin
    RvipStop; exit;
  end;
  if (mode <> MODE_EXPLORE) and (MonstersInView > startmon) then
  begin
    RvipStop; exit;
  end;
  { on the staircase: stop there; the player presses < / > again (or the
    action key) to take the stairs (RVIP finetuning: auto-stairs only walks) }
  if ((mode = MODE_DOWN) and (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 9)) or
    ((mode = MODE_UP) and (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 8)) then
  begin
    RvipStop;
    if firstauto then exit(ord(KeyEnter));   { pressed while on them: take them }
    exit;
  end;
  firstauto := false;
  d := NextDir;
  if d < 0 then
  begin
    if GetEnvironmentVariable('LR_DEBUG') <> '' then
      for lasty := ThePlayer.intY - 3 to ThePlayer.intY + 3 do
      begin
        for lastx := ThePlayer.intX - 5 to ThePlayer.intX + 5 do
          if Inside(lastx, lasty) then
            if DngLvl[lastx, lasty].blKnown then write(stderr, DngLvl[lastx, lasty].intFloorType:3, '/', DngLvl[lastx, lasty].intIntegrity:3)
            else write(stderr, '   ?    ');
        writeln(stderr);
      end;
    case mode of
      MODE_EXPLORE: Say('Nothing left to explore.');
      MODE_DOWN: Say('You know no way down.');
      MODE_UP: Say('You know no way up.');
    end;
    RvipStop; exit;
  end;
  lastmsgs := web_msgs;
  { moving into a closed door opens it: that turn says "You open a door." }
  if DngLvl[ThePlayer.intX + DX[d], ThePlayer.intY + DY[d]].intFloorType = 3 then
    expectmsgs := 1
  else
    expectmsgs := 0;
  if GetEnvironmentVariable('LR_DEBUG') <> '' then
    writeln(stderr, 'step ', d, ' from ', ThePlayer.intX, ',', ThePlayer.intY, ' into floor ',
      DngLvl[ThePlayer.intX + DX[d], ThePlayer.intY + DY[d]].intFloorType, ' msgs ', web_msgs);
  lastx := ThePlayer.intX; lasty := ThePlayer.intY;
  stepped := true;
  { let the page paint every step (RVIP finetuning: explore moves visibly) }
  if lastlevel = DungeonLevel then delay(40);
  RvipAuto := ord(DirKey(d));
end;

{ ---- Enter: floating command menu, grouped like the game's help screen
  "Keys used to perform actions"; returns the chosen command's key (0 = none) }
type
  TCmd = record k: char; t: string; end;
  TGroup = record name: string; k: char; first, last: longint; end;
var
  cmds: array [0..40] of TCmd;
  ncmds: longint;
  groups: array [0..7] of TGroup;
  ngroups: longint;
  gcur: longint = 0;

procedure Cmd(k: char; const t: string);
begin
  cmds[ncmds].k := k; cmds[ncmds].t := t; inc(ncmds);
  groups[ngroups - 1].last := ncmds - 1;
end;

procedure Group(k: char; const name: string);
begin
  groups[ngroups].name := name; groups[ngroups].k := k; groups[ngroups].first := ncmds; inc(ngroups);
end;

procedure BuildMenu;
begin
  ncmds := 0; ngroups := 0;
  Group('m', 'Move and explore');
  Cmd('z', 'explore (any key stops)');
  Cmd('>', 'walk to known stairs down (again: take them)');
  Cmd('<', 'walk to known stairs up (again: take them)');
  Cmd(KeyEnter, 'act: stairs, chest, altar, well, crypt');
  Cmd(KeyShortRest, 'rest one turn');
  Cmd(KeyRest, 'rest a number of turns');
  Cmd(KeyCloseDoor, 'close door');
  Cmd(KeyTunnel, 'dig / disarm trap');
  Group('i', 'Items');
  Cmd(KeyInventory, 'inventory');
  Cmd(KeyTake, 'pick up item');
  Cmd(KeyThrow, 'throw an item');
  Cmd(KeyShoot, 'fire long-range weapon');
  Group('g', 'Magic and gods');
  Cmd(KeyChant, 'songbook (spells)');
  Cmd(KeyChantLast, 'chant last spell again');
  Cmd(KeySetQuickKeys, 'show and reset quick keys');
  Cmd(KeyPray, 'pray to your god');
  Cmd(KeySpecial, 'use talent');
  Cmd(KeySpecialDiv, 'divine rage');
  Group('p', 'People and fighting');
  Cmd(KeyTrade, 'talk to NPC or trader');
  Cmd(KeySearchSteal, 'search / steal');
  Cmd(KeyTactics, 'switch tactics');
  Group('n', 'Information');
  Cmd(KeyStatus, 'status screen');
  Cmd(KeyQuestlog, 'questlog');
  Cmd(KeyLook, 'identify tile');
  Cmd(KeyBigMap, 'big minimap');
  Cmd(KeyHelp, 'help');
  Group('q', 'Game');
  Cmd(KeyQuit, 'game menu: options, keys, save and quit');
end;

function RvipMenu: longint;
var
  ge: array [0..7] of TMenuEntry;
  ce: array [0..40] of TMenuEntry;
  i, r, c, n: longint;
begin
  RvipMenu := 0;
  BuildMenu;
  for i := 0 to ngroups - 1 do
  begin
    ge[i].key := groups[i].k; ge[i].text := groups[i].name;
  end;
  repeat
    r := UIMenu('Commands', slice(ge, ngroups), gcur);
    if r < 0 then break;
    n := 0;
    for i := groups[r].first to groups[r].last do
    begin
      ce[n].key := cmds[i].k; ce[n].text := cmds[i].t; inc(n);
    end;
    c := 0;
    c := UIMenu(groups[r].name, slice(ce, n), c);
    if c >= 0 then
    begin
      RvipMenu := ord(cmds[groups[r].first + c].k);
      break;
    end;
  until c = MENU_CLOSE;
  ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  SDL_UpdateRect(screen, 0, 0, 0, 0);
end;

end.
