{ RVIP additions to LambdaRogue (web build): auto-explore on 'z' and stair
  walking on '<' / '>' (RVIP.md steps 2 and 3).

  Hook (fprl.pas KEYLOOP): RvipAuto is asked before every key poll at the
  command prompt; while a walk runs it returns the next movement key (or
  KeyEnter on the staircase) instead of reading one. The walk is a BFS over
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

implementation

uses WebBE, SysUtils, Constants, RandomArea, Player, Quests, MessageLog;

const
  MODE_NONE = 0; MODE_EXPLORE = 1; MODE_DOWN = 2; MODE_UP = 3;
  DX: array [0..7] of integer = (0, 0, 1, -1, 1, -1, 1, -1);
  DY: array [0..7] of integer = (-1, 1, 0, 0, -1, -1, 1, 1);
var
  mode: integer = MODE_NONE;
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

function MonstersInView: longint;
var m, n: longint;
begin
  n := 0;
  for m := 1 to 550 do
    with Monster[m] do
      if (intHP > 0) and Inside(intX, intY) and (intInvis = 0) and
        DngLvl[intX, intY].blLOS and DngLvl[intX, intY].blKnown then
        inc(n);
  MonstersInView := n;
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

function RvipAuto: longint;
var d: integer;
    ev: TSDL_Event;
begin
  web_at_cmd := true;
  RvipAuto := 0;
  if mode = MODE_NONE then exit;
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
  { on the staircase: take it }
  if ((mode = MODE_DOWN) and (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 9)) or
    ((mode = MODE_UP) and (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 8)) then
  begin
    RvipStop;
    exit(ord(KeyEnter));
  end;
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
  RvipAuto := ord(DirKey(d));
end;

end.
