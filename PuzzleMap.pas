{
     Copyright (C) 2006-2011 by Mario Donick
     mario.donick@gmail.com

     This program is free software; you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation; either version 2 of the License, or
     (at your option) any later version.

     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.

     You should have received a copy of the GNU General Public License
     along with this program; if not, write to the
     Free Software Foundation, Inc.,
     59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

unit PuzzleMap;


interface

uses
  Constants, WebBE, SysUtils, StrUtils, Quests, Player;

var
  Landstring: array[1..150] of string;
  Part: array[1..90, 1..11] of string;
  TotalParts: integer;

procedure CreatePuzzleLandscape(lvl: integer);


implementation

procedure CreatePuzzleMisc(lvl: integer);
var
  i, x, y, r, n: integer;
  LeftFromNPC, RightFromNPC, zeile: string;
  blCreateNPC: boolean;
begin

  // NPCs

  blCreateNPC:=true;

  if lvl=16 then
  begin
    if ThePlayer.intQuestState[1,3]=2 then
      if ThePlayer.intQuestState[24,1]=2 then
        if ThePlayer.intQuestState[16,5]=2 then
          if ThePlayer.blUnkilled[ReturnMonTeByName('Astaroth')]=true then
            blCreateNPC:=false;

    if (ThePlayer.intQuestState[1,3]<>2) or (ThePlayer.intQuestState[24,1]<>2) then
      blCreateNPC:=false;
  end;

  if lvl=24 then
  begin
    if ThePlayer.intQuestState[1,3]<>2 then
      blCreateNPC:=false;
  end;

  if ThePlayer.blCoffeeBreak=true then
    blCreateNPC:=false;

  if blCreateNPC=true then
  begin
    for i := 1 to 9 do
      if Quest[lvl, i].strNPCname <> '-' then
      begin
        n := 0;
        repeat
          Inc(n);
          x     := 5 + trunc(random(35));
          y     := 5 + trunc(random(35));
          zeile := Landstring[y];
        until (n = 5000) or (zeile[x] = '-') or (zeile[x] = 'S') or (zeile[x] = '.') or (zeile[x] = ',');
        LeftFromNPC := LeftStr(Landstring[y], x - 1);
        r := abs(length(Landstring[y]) - length(LeftFromNPC)) - 1;
        RightFromNPC := RightStr(Landstring[y], r);
        Landstring[y] := LeftFromNPC + IntToStr(i) + RightFromNPC;
      end;
  end;


  // Unique Monster
  repeat
    x     := 5 + trunc(random(35));
    y     := 5 + trunc(random(35));
    zeile := Landstring[y];
  until (zeile[x] = '.') or (zeile[x] = ',') or (zeile[x] = 'g') or
    (zeile[x] = 'W') or (zeile[x] = 'z') or (zeile[x] = 'I');

  LeftFromNPC := LeftStr(Landstring[y], x - 1);
  r := abs(length(Landstring[y]) - length(LeftFromNPC)) - 1;
  RightFromNPC := RightStr(Landstring[y], r);
  Landstring[y] := LeftFromNPC + 'X' + RightFromNPC;


  // stairs to next area
  if (lvl < 20) or (lvl = 22) or (lvl = 23) or (lvl = 24) or (lvl = 26) then
  begin
    repeat
      x     := 5 + trunc(random(35));
      y     := 5 + trunc(random(35));
      zeile := Landstring[y];
    until (zeile[x] <> '^') and (zeile[x] <> '#') and (zeile[x] <> '$') and
      (zeile[x] <> '&') and (zeile[x] <> '?') and (zeile[x] <> '@') and (zeile[x] <> '-');

    LeftFromNPC := LeftStr(Landstring[y], x - 1);
    r := abs(length(Landstring[y]) - length(LeftFromNPC)) - 1;
    RightFromNPC := RightStr(Landstring[y], r);
    Landstring[y] := LeftFromNPC + '>' + RightFromNPC;
  end;


  // Portal to prev. area
  if ((lvl > 1) and (lvl < 21)) or (lvl = 23) or (lvl = 24) or (lvl = 25) or (lvl = 27) then
  begin
    repeat
      x     := 5 + trunc(random(35));
      y     := 5 + trunc(random(35));
      zeile := Landstring[y];
    until (zeile[x] <> '^') and (zeile[x] <> '#') and (zeile[x] <> '$') and
      (zeile[x] <> '&') and (zeile[x] <> '?') and (zeile[x] <> '@') and (zeile[x] <> '-');

    LeftFromNPC := LeftStr(Landstring[y], x - 1);
    r := abs(length(Landstring[y]) - length(LeftFromNPC)) - 1;
    RightFromNPC := RightStr(Landstring[y], r);
    Landstring[y] := LeftFromNPC + '<' + RightFromNPC;
  end;
end;

procedure CreatePuzzleCorridorH(y, lvl: integer);
var
  n, i, x: integer;
begin

  {$i PuzzleTiles_CorridorH.inc}

  x := 0;

  for i := y to y + 10 do
    Landstring[i] := '';

  while x < 50 do
  begin
    n := 1 + trunc(random(TotalParts));
    for i := 1 to 11 do
      Landstring[(y - 1) + i] := Landstring[(y - 1) + i] + Part[n, i];

    Inc(x, 11);
  end;
end;

procedure CreatePuzzleCorridorV(x, lvl: integer);
var
  n, i, y, r: integer;
  LeftFromRiver, RightFromRiver: string;
begin

  {$i PuzzleTiles_CorridorV.inc}

  y := 0;

  while y < 51 do
  begin
    n := 1 + trunc(random(TotalParts));
    for i := 1 to 11 do
    begin
      LeftFromRiver := LeftStr(Landstring[y + i], x - 1);
      r := length(Landstring[y + i]) + 1 - (x + 11);
      RightFromRiver := RightStr(Landstring[y + i], r);
      Landstring[y + i] := LeftFromRiver + Part[n, i] + RightFromRiver;
    end;
    Inc(y, 11);
  end;
end;


procedure CreatePuzzleRiverH(y: integer);
var
  n, i, x: integer;
begin

  {$i PuzzleTiles_RiverH.inc}

  x := 0;

  for i := y to y + 10 do
    Landstring[i] := '';

  while x < 50 do
  begin
    n := 1 + trunc(random(TotalParts));
    for i := 1 to 11 do
      Landstring[(y - 1) + i] := Landstring[(y - 1) + i] + Part[n, i];

    Inc(x, 11);
  end;
end;



procedure CreatePuzzleRiverV(x: integer);
var
  n, i, y, r: integer;
  LeftFromRiver, RightFromRiver: string;
begin

  {$i PuzzleTiles_RiverV.inc}

  y := 0;

  while y < 51 do
  begin
    n := 1 + trunc(random(TotalParts));
    for i := 1 to 11 do
    begin
      LeftFromRiver := LeftStr(Landstring[y + i], x - 1);
      r := length(Landstring[y + i]) + 1 - (x + 11);
      RightFromRiver := RightStr(Landstring[y + i], r);
      Landstring[y + i] := LeftFromRiver + Part[n, i] + RightFromRiver;
    end;
    Inc(y, 11);
  end;
end;

procedure CreatePuzzleBase(y, m, lvl: integer);
var
  n, i, j: integer;
begin

  {$i PuzzleTiles_1_22.inc}           // Wilderness
  {$i PuzzleTiles_2_3.inc}            // Catacombs / Sewers
  {$i PuzzleTiles_4.inc}              // Old Mine
  {$i PuzzleTiles_5.inc}              // Lost Outpost
  {$i PuzzleTiles_6_7.inc}            // Dungeon
  {$i PuzzleTiles_8_9.inc}            // Caves
  {$i PuzzleTiles_10_11.inc}          // Caves
  {$i PuzzleTiles_12_13.inc}          // Old Maze
  {$i PuzzleTiles_14_15.inc}          // Ash Caves
  {$i PuzzleTiles_16_17_18.inc}       // New Maze
  {$i PuzzleTiles_19_23_24_25.inc}    // Dark Temple / Forgotten Realm
  {$i PuzzleTiles_20.inc}             // Halls of Eris
  {$i PuzzleTiles_21.inc}             // Noldarur
  {$i PuzzleTiles_26_27.inc}          // spaceship

  i := 0;

  while i < 50 do  // 90
  begin
    Inc(i, 11);

    n := 1 + trunc(random(TotalParts));
    for j := 1 to 11 do
      Landstring[y + j] := Landstring[y + j] + Part[n, j];
  end;
end;

procedure CreatePuzzleLandscape(lvl: integer);
var
  i, x, y: integer;
  MapFile: textfile;
  tl, tr:  string;
begin

  for i := 1 to 150 do            // 150 only to clear the max. available array
    Landstring[i] := '';

  y := 0;
  while y < 51 do  // 73
  begin
    CreatePuzzleBase(y, 0, lvl);
    Inc(y, 11);
  end;

  // river
  if (lvl = 1) or (lvl = 22) then
  begin
    x := 11 * trunc(1 + random(4));
    if random(400) > 200 then
      CreatePuzzleRiverV(x)
    else
      CreatePuzzleRiverH(x);
  end;

  // big corridor
  if (lvl = 3) or (lvl = 6) or (lvl=23) then
  begin
    x := 11 * trunc(1 + random(4));
    CreatePuzzleCorridorV(x, lvl);
    x := 11 * trunc(1 + random(4));
    CreatePuzzleCorridorH(x, lvl);
  end;

  if lvl = 21 then
  begin
    x := 11 * trunc(1 + random(4));
    CreatePuzzleCorridorV(x, lvl);
  end;



  // optimize
  for i := 1 to y do
  begin
    // replace double doors by one door
    Landstring[i] := AnsiReplaceText(Landstring[i], '++', '+-');
    Landstring[i] := AnsiReplaceText(Landstring[i], '@@', '@-');

    // smooth beaches
    Landstring[i] := AnsiReplaceText(Landstring[i], ',==', ',A=');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g==', 'gA=');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'b==', 'bA=');
    Landstring[i] := AnsiReplaceText(Landstring[i], 't==', 'tA=');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h==', 'hA=');

    Landstring[i] := AnsiReplaceText(Landstring[i], '==,', '=J,');
    Landstring[i] := AnsiReplaceText(Landstring[i], '==g', '=Jg');
    Landstring[i] := AnsiReplaceText(Landstring[i], '==b', '=Jb');
    Landstring[i] := AnsiReplaceText(Landstring[i], '==t', '=Jt');
    Landstring[i] := AnsiReplaceText(Landstring[i], '==h', '=Jh');

    Landstring[i] := AnsiReplaceText(Landstring[i], 'A=,', 'AJ,');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'A=g', 'AJg');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'A=h', 'AJh');

    Landstring[i] := AnsiReplaceText(Landstring[i], '^=,', '^j,');
    Landstring[i] := AnsiReplaceText(Landstring[i], '^=g', '^jg');
    Landstring[i] := AnsiReplaceText(Landstring[i], '^=b', '^jb');
    Landstring[i] := AnsiReplaceText(Landstring[i], '^=t', '^jt');
    Landstring[i] := AnsiReplaceText(Landstring[i], '^=h', '^jh');

    Landstring[i] := AnsiReplaceText(Landstring[i], ',=J', ',AJ');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',=^', ',j^');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',=,', ',j,');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',=g', ',jg');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',=t', ',jt');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',=b', ',jb');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',=h', ',jh');

    Landstring[i] := AnsiReplaceText(Landstring[i], 'g=J', 'gAJ');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g=^', 'gj^');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g=g', 'gjg');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g=,', 'gj,');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g=b', 'gjb');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g=t', 'gjt');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g=h', 'gjh');

    Landstring[i] := AnsiReplaceText(Landstring[i], 't=,', 'tj,');
    Landstring[i] := AnsiReplaceText(Landstring[i], 't=t', 'tjt');
    Landstring[i] := AnsiReplaceText(Landstring[i], 't=b', 'tjb');
    Landstring[i] := AnsiReplaceText(Landstring[i], 't=h', 'tjh');
    Landstring[i] := AnsiReplaceText(Landstring[i], 't=g', 'tjg');

    Landstring[i] := AnsiReplaceText(Landstring[i], 'b=,', 'bj,');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'b=b', 'bjb');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'b=t', 'bjt');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'b=h', 'bjh');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'b=g', 'bjg');

    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=J', 'hAJ');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=h', 'hjh');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=,', 'hj,');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=g', 'hjg');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=b', 'hjb');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=t', 'hjt');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=^', 'hA^');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'h=#', 'hA#');

    // smooth border between grass and sand
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g,,', 'gE,');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',gg', ',Fg');
    Landstring[i] := AnsiReplaceText(Landstring[i], 'g,', 'FE');
    Landstring[i] := AnsiReplaceText(Landstring[i], ',g', 'EF');

    // make border left and right
    tl := LeftStr(Landstring[i], length(Landstring[i]) - 1);
    Landstring[i] := tl + '^';
    tr := RightStr(Landstring[i], length(Landstring[i]) - 1);
    Landstring[i] := '^' + tr;
  end;

  Landstring[1] := AnsiReplaceText(Landstring[1], '.', '^');
  Landstring[1] := AnsiReplaceText(Landstring[1], '+', '^');
  Landstring[1] := AnsiReplaceText(Landstring[1], '@', '^');
  Landstring[y] := AnsiReplaceText(Landstring[y], '.', '^');
  Landstring[y] := AnsiReplaceText(Landstring[y], '+', '^');
  Landstring[y] := AnsiReplaceText(Landstring[y], '@', '^');


  // Miscellanous things (portals, NPCs and Unique Monster)
  //     writeln ('- misc');
  CreatePuzzleMisc(lvl);


  // save level file

  Assign(MapFile, CONST_DATADIR + 'data/levels/random/' + IntToStr(lvl) + '.txt');
  Rewrite(MapFile);

  for i := 1 to 50 do
    writeln(MapFile, Landstring[i]);
  Close(MapFile);


 // writeln ('Map data/levels/random/' + IntToStr(lvl) +'.txt created.');
end;

end.
