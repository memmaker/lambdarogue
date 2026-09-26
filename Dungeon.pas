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

unit Dungeon;


interface

uses
  Constants, WebBE, SysUtils, GFX, Player, Items, Quests, RandomArea;

var
  CONST_PERCENTMONSTERS, CONST_MIN_ITEMS: integer;

function ReturnLevelName(n: integer): string;
function GetTotalMonsters: integer;
function GetFirstFreeMonsterID: integer;
procedure PlacePlayer(f, FromLevel: integer);
procedure KillAllMonsters;
procedure CreateMonster(n: longint; Name: string; lvl: integer);
procedure CreateUniqueMonster(lvl: integer);
procedure CreateBonesMonster;
procedure FillDungeon(lvl: integer);
procedure InitDungeon;
procedure CreateDungeon(lvl: integer);
function CheckForMonster(x, y: integer): boolean;
function CheckForNPC(x, y: integer): boolean;
procedure Earthquake;
function IsTargetHive(level: integer): boolean;



implementation

function ReturnLevelName(n: integer): string;
var
  levelname: string;
begin
  case n of
    1:
      levelname := 'the Temple of Enoa';
    2:
      levelname := 'the Catacombs of Enoa';
    3:
      levelname := 'the Sewers of Enoa';
    4:
      levelname := 'the Old Mine';
    5:
      levelname := 'the Lost Outpost';
    6:
      levelname := 'the Inner Dungeon';
    7:
      levelname := 'the Outer Dungeon';
    8:
      levelname := 'the Caves, level 1';
    9:
      levelname := 'the Caves, level 2';
    10:
      levelname := 'the Caves, level 3';
    11:
      levelname := 'the Caves, level 4';
    12:
      levelname := 'the Old Maze, level 1';
    13:
      levelname := 'the Old Maze, level 2';
    14:
      levelname := 'the Ash Caves, level 1';
    15:
      levelname := 'the Ash Caves, level 2';
    16:
      levelname := 'the New Maze, level 1'; // TODO: better name
    17:
      levelname := 'the New Maze, level 2'; // TODO: better name
    18:
      levelname := 'Krice''s hideout';
    19:
      levelname := 'the Dark Temple';
    20:
      levelname := 'the Core';
    21:
      levelname := 'the Ice Ruins of Noldarur';
    22:
      levelname := 'the Outskirts of Enoa';
    23:
      levelname := 'the Forgotten Realm, outer part';
    24:
      levelname := 'the Forgotten Realm, inner part';
    25:
      levelname := 'the Forgotten Realm, King''s estate';
    26:
      levelname := 'the "Valeri", deck 1';
    27:
      levelname := 'the "Valeri", deck 2';
  end;
  ReturnLevelName := levelname;
end;

// returns true if the player has a quest to destroy the given level's monster hive
function IsTargetHive(level: integer): boolean;
var
  i, j: integer;
begin
  IsTargetHive := False;
  for i := 1 to WinLevel do
    for j := 1 to 9 do
      if Quest[i, j].intTargetHive = level then
        if ThePlayer.intQuestState[i, j] = 1 then
          IsTargetHive := True;
end;

// returns the total number of currently active monsters (unique and ghost not counted)
function GetTotalMonsters: integer;
var
  r, i: integer;
begin
  r := 0;
  for i := 1 to 508 do
    if (Monster[i].intX <> DngMaxWidth + 10) and (Monster[i].intY <>
      DngMaxHeight + 10) then
      Inc(r);
  GetTotalMonsters := r;
end;


// returns the first free monster ID
function GetFirstFreeMonsterID: integer;
var
  i, r: integer;
begin
  r := -1;
  i := 1;
  repeat
    Inc(i);
    if (Monster[i].intX = DngMaxWidth + 10) and (Monster[i].intY =
      DngMaxHeight + 10) then
    begin
      r := i;
      i := 508;
    end;
  until i = 508;

  //       //writeln ('First free monster ID: ' + IntToStr(r));
  GetFirstFreeMonsterID := r;
end;

// checks if a tile is a trader or NPC
function CheckForNPC(x, y: integer): boolean;
var
  i: integer;
begin
  CheckForNPC := False;
  if DngLvl[x, y].intBuilding > 0 then
    CheckForNPC := True
  else
    for i := 1 to 9 do
      if (NPC[i].intX = x) and (NPC[i].intY = y) then
        CheckForNPC := True;
end;

// this function checks if a given dungeon position contains a monster
function CheckForMonster(x, y: integer): boolean;
var
  i: integer;
begin
  CheckForMonster := False;
  for i := 1 to 510 do
  begin
    if (Monster[i].intX = x) and (Monster[i].intY = y) then
      CheckForMonster := True;

    // also mark solid positions as used
    if (x >= 1) and (x <= 200) and (y >= 1) and (y <= 200) then
    begin
      if DngLvl[x, y].intIntegrity > 0 then
        CheckForMonster := True;
    end
    else
    begin // if x/y is a out-of-range value, mark it as used, so CreateMonster does not alter the value
      // //writeln('Warning: MonsterSearch x/y out of range ('+IntToStr(x)+'/'+IntToStr(y)+')');
      CheckForMonster := True;
    end;
  end;
end;


// clear level from all monsters (except uniques and ghosts)
procedure KillAllMonsters;
var
  i: integer;
begin
  for i := 1 to 508 do
  begin
    Monster[i].intX := DngMaxWidth + 10;
    Monster[i].intY := DngMaxHeight + 10;
  end;
  StoreAchievement('Wiped out an entire level.');
end;

// number, name, level
procedure CreateMonster(n: longint; Name: string; lvl: integer);
var
  rx, ry, a, i: integer;
  MinMonLvl, MaxMonLvl: integer;
  blOkay: boolean;
begin

  if (lvl = 1) or (lvl = 25) then
    exit;

  // no monsters in 23/24/25 if undying king or Eris is dead
  if (lvl = 23) or (lvl = 24) or (lvl = 25) then
    if (ThePlayer.blUnKilled[ReturnMonTeByName('Undying King')] = True) or
      (ThePlayer.blUnKilled[ReturnMonTeByName('Eris')] = True) then
      exit;

      //writeln('-- Create Monster');

  if Name <> '-' then
    a := ReturnMonTeByName(Name)
  else
    a := 0;

  if a = 0 then
  begin
    if lvl < 20 then
    begin
      MinMonLvl := lvl - CONST_MONSTER_DLV_DIFF;
      MaxMonLvl := lvl;
    end;

    if lvl = 20 then
    begin
      MinMonLvl := 20;
      MaxMonLvl := 20;
    end;

    if lvl = 21 then
    begin
      MinMonLvl := 21;
      MaxMonLvl := 21;
    end;

    if lvl = 22 then
    begin
      MinMonLvl := 22;
      MaxMonLvl := 22;
    end;


    if lvl = 23 then
    begin
      MinMonLvl := 23;
      MaxMonLvl := 23;
    end;

    if lvl = 24 then
    begin
      MinMonLvl := 23;
      MaxMonLvl := 24;
    end;

    if lvl = 26 then
    begin
      MinMonLvl := 26;
      MaxMonLvl := 26;
    end;

    if lvl = 27 then
    begin
      MinMonLvl := 26;
      MaxMonLvl := 27;
    end;

    // select type of monster
    //writeln('choose monster between ' + IntToStr(MinMonLvl) + ' and ' + IntToStr(MaxMonLvl));
    repeat
      blOkay := False;
      a      := trunc(1 + random(MonsterTemplates));

      //if a = 0 then a:=MonsterTemplates;

      if (MonTe[a].intLvl >= MinMonLvl) and (MonTe[a].intLvl <= MaxMonLvl) then
        blOkay := True;                 // basic condition: correct level

      if MonTe[a].blUnique = True then
        blOkay := False;                // no uniques!

      if MonTe[a].chLetter = chr(143) then
        blOkay := False;                // no player ghosts!

      if MonTe[a].intQuestG > 0 then
        if ThePlayer.intQuestState[lvl, MonTe[a].intQuestG] <> 1 then
          blOkay := False;
      // if open quest needed: create only if quest is open

      if MonTe[a].intQuestS > 0 then
        if ThePlayer.intQuestState[lvl, MonTe[a].intQuestS] <> 2 then
          blOkay := False;
      // if solved quest needed: create only if quest is solved

    until blOkay = True;
  end;

  // create monster
       //writeln ('Template: ' + IntToStr(a) + '/' + IntToStr(MonsterTemplates) + '(name: '+name+')');
       //writeln ('Monster:  ' + IntToStr(n));
  Monster[n] := MonTe[a];

       //writeln(Monster[n].strName+' created (MonsterTemplates: '+IntToStr(MonsterTemplates)+')');

  // set initial monster stats
  Monster[n].longGold := MonTe[a].longGold + trunc(random(MonTe[a].longGold));
  Monster[n].intHP    := Monster[n].intMaxHP;
  Monster[n].intInvis := 0;
  Monster[n].intPara  := 0;
  Monster[n].intPoison := 0;

  // if current DLV > monster default level, add difference to monster WP or GP
  if lvl > MonTe[a].intLvl then
  begin
    Inc(Monster[n].intWP, (lvl-MonTe[a].intLvl)+1);
    if Monster[n].intGP>0 then
      Inc(Monster[n].intGp, (lvl-MonTe[a].intLvl)+1);
    if DiffLevel=3 then
    begin
      Inc(Monster[n].intWP);
      if Monster[n].intGP > 0 then
        Inc(Monster[n].intGP);
      Inc(monster[n].intAP);
    end;
  end;


  // if lots of monsters killed, make them stronger

  //if GrowingMonsters = True then
  //begin
  //  if (random(400) > CONST_STRONGMONSTERS) or (DiffLevel = 3) then
  //  begin
  //    //             //writeln('Monstertyp: ' + IntToStr(Monster[n].intType));
  //    if ThePlayer.longKilled[Monster[n].intType] > 25 then
  //    begin
  //      Inc(Monster[n].intWP, 3);
  //      Inc(Monster[n].intAP, 3);
  //      Inc(Monster[n].intHP, 10);
  //      Monster[n].intMaxHP := Monster[n].intHP;
  //
  //      Inc(Monster[n].longGold, (MonTe[a].longGold div 2) + 1);
  //      Monster[n].strName := 'big ' + MonTe[a].strName;
  //    end;
  //    if ThePlayer.longKilled[Monster[n].intType] > 70 then
  //    begin
  //      Inc(Monster[n].intWP, 6);
  //      Inc(Monster[n].intAP, 3);
  //      Inc(Monster[n].intHP, 15);
  //      Monster[n].intMaxHP := Monster[n].intHP;
  //
  //      Inc(Monster[n].longGold, MonTe[a].longGold);
  //      Monster[n].strName := 'strong ' + MonTe[a].strName;
  //    end;
  //    if ThePlayer.longKilled[Monster[n].intType] > 130 then
  //    begin
  //      Inc(Monster[n].intWP, 8);
  //      Inc(Monster[n].intAP, 6);
  //      Inc(Monster[n].intHP, 30);
  //      Monster[n].intMaxHP := Monster[n].intHP;
  //
  //      Inc(Monster[n].longGold, MonTe[a].longGold);
  //      Monster[n].strName := 'mighty ' + MonTe[a].strName;
  //    end;
  //  end;
  //end;


  // set initial position

  // water monsters
  if Monster[n].blWater = True then
  begin
    repeat
      rx := trunc(random(DngMaxWidth)) + 10;
      ry := trunc(random(DngMaxHeight)) + 10;
    until (DngLvl[rx, ry].intIntegrity = 0);
    if (DngLvl[rx, ry].intFloorType <> 5) or ((ThePlayer.intX = rx) and
      (ThePlayer.intY = ry)) then
    begin
      rx := DngMaxWidth + 10;
      ry := DngMaxHeight + 10;
    end;
    //         else
    //             //writeln('Wassermonster bei '+IntToStr(rx)+'/'+IntToStr(ry));
  end
  // non-water monsters
  else
  begin
    repeat
      rx := trunc(random(DngMaxWidth)) + 10;
      ry := trunc(random(DngMaxHeight)) + 10;
    until (DngLvl[rx, ry].intIntegrity = 0);
    if (DngLvl[rx, ry].blTown = True) or (DngLvl[rx, ry].intFloorType = 5) or
      ((ThePlayer.intX = rx) and (ThePlayer.intY = ry)) then
    begin
      rx := DngMaxWidth + 10;
      ry := DngMaxHeight + 10;
    end;
    //         else
    //             //writeln('Landmonster bei '+IntToStr(rx)+'/'+IntToStr(ry));

    // process monster hives
    if (HiveX > -1) and (HiveY > -1) then
    begin
      for i := 1 to lvl do
      begin
        if CheckForMonster(HiveX - i, HiveY) = False then
        begin
          rx := HiveX - i;
          ry := HiveY;
        end;
        if CheckForMonster(HiveX + i, HiveY) = False then
        begin
          rx := HiveX + i;
          ry := HiveY;
        end;
        if CheckForMonster(HiveX, HiveY - i) = False then
        begin
          rx := HiveX;
          ry := HiveY - i;
        end;
        if CheckForMonster(HiveX, HiveY + i) = False then
        begin
          rx := HiveX;
          ry := HiveY + i;
        end;
        if CheckForMonster(HiveX - i, HiveY - i) = False then
        begin
          rx := HiveX - i;
          ry := HiveY - i;
        end;
        if CheckForMonster(HiveX + i, HiveY + i) = False then
        begin
          rx := HiveX + i;
          ry := HiveY + i;
        end;
      end;
    end;
  end;

  Monster[n].intX := rx;
  Monster[n].intY := ry;
end;

procedure CreateUniqueMonster(lvl: integer);
var
  a, i:   integer;
  blOkay: boolean;
begin

       //writeln('-- Create Unique Monster');

  a := 0;

  for i := 1 to MonsterTemplates do
  begin
    a := 0;

    // create monster only if it has not been killed
    if (MonTe[i].intLvl = lvl) and (MonTe[i].blUnique = True) and
      (ThePlayer.blUnKilled[i] = False) then
    begin

      blOkay := True;

      // if open quest needed: create only if quest is open
      if MonTe[i].intQuestG > 0 then
        if ThePlayer.intQuestState[lvl, MonTe[i].intQuestG] <> 1 then
          blOkay := False;

      // if solved quest needed: create only if quest is solved
      if MonTe[i].intQuestS > 0 then
        if ThePlayer.intQuestState[lvl, MonTe[i].intQuestS] <> 2 then
          blOkay := False;

      // if this unique is just an elite variant of a standard monster, it may not appear
      if MonTe[i].blElite = true then
        if random(1000)>400 then
          blOkay := False;


      if blOkay = True then
      begin
        a := i;

        // create monster
        Monster[510] := MonTe[a];
        Monster[510].intTemplate := a;

        // set initial monster stats
        Monster[510].longGold := MonTe[a].longGold + random(MonTe[a].longGold);
        Monster[510].intHP    := Monster[510].intMaxHP + trunc(random(20));

        // set initial position
        Monster[510].intX := UnX;
        Monster[510].intY := UnY;
      end;
    end;
  end;
end;

procedure CreateBonesMonster;
var
  a, i, n: integer;
begin

  ////writeln('-- Create Ghost');

  a := 0;
  i := 0;
  n := 0;

  // select undead, if possible
  // TODO: randomly select from all undeads!
  repeat
    Inc(n);
    i := 1 + trunc(random(MonsterTemplates));
    if (i < 1) or (i > 200) then
      //writeln('Error: Monster Template ID out of range (' + IntToStr(i) + ')');
    if MonTe[i].chLetter = chr(143) then      // ghosts have chr(143) as character
      a := i;
  until (n = 1000) or (a > 0);

  // create undead; this will remove any other undeads, of course
  if a > 0 then
  begin
    Monster[509]      := MonTe[a];
    Monster[509].intX := ThePlayer.intX + 1;
    Monster[509].intY := ThePlayer.intY;
  end;

end;

// fill dungeon with monsters
procedure FillDungeon(lvl: integer);
var
  i, j: longint;
  FreeForMonster: integer;
begin

  // get number of free "monster tiles"
  FreeForMonster := 0;
  for i := 1 to DngMaxWidth do
    for j := 1 to DngMaxHeight do
      if (DngLvl[i, j].intIntegrity = 0) then
        Inc(FreeForMonster);

  // hide all enemies
  for i := 1 to 510 do
  begin
    Monster[i].intX := DngMaxWidth + 10;
    Monster[i].intY := DngMaxHeight + 10;
  end;

  // place enemies

  MaxMonster := (CONST_PERCENTMONSTERS * FreeForMonster) div 100;

  // only the half of percentage for catacombs (should be easy) and levels with many empty space (like lost outpost or cave)
  if (lvl < 3) or ((lvl > 4) and (lvl < 8)) then
    MaxMonster := MaxMonster div 2;

  // in caves and mazes even less
  if (lvl > 7) and (lvl < 18) then
    MaxMonster := MaxMonster div 3;

  // if ice ruins of Noldalur or Outskirts of Enoa or 1st level of forgotten realm, only 1% of the half of all tiles
  if (lvl = 21) or (lvl = 22) or (lvl = 23) or (lvl = 24) then
    MaxMonster := (1 * (FreeForMonster div 2)) div 100;

  // 509 = ghost; 510 = unique
  if MaxMonster > 508 then
    MaxMonster := 508;

       //writeln('-- '+IntToStr(MaxMonster)+' monsters');
  for i := 1 to MaxMonster do
    CreateMonster(i, '-', lvl);

  //     repeat
  //         inc(i);
  //         CreateMonster(i, '-', lvl);
  //     until (i=MaxMonster);

  // try to place unique monster
       //writeln('-- unique monster');
  CreateUniqueMonster(lvl);

end;


// Initialize dungeon
procedure InitDungeon;
var
  i, j: integer;
begin

  // make dungeon empty
  for i := 1 to 200 do
  begin
    for j := 1 to 200 do
    begin
      DngLvl[i, j].intFloorType := 0;
      DngLvl[i, j].intIntegrity := 9999;
      DngLvl[i, j].intAirType := 0;
      DngLvl[i, j].intAirRange := 0;
      DngLvl[i, j].intItem  := 0;
      DngLvl[i, j].intBuilding := 0;
      DngLvl[i, j].blKnown  := False;
      DngLvl[i, j].blBlood  := False;
      DngLvl[i, j].blTown   := False;
      DngLvl[i, j].intLight := 4;
    end;
  end;

  // remove all NPCs
  for i := 1 to 9 do
  begin
    NPC[i].intX := 0;
    NPC[i].intY := 0;
  end;
end;


// load dungeon (either from predefined map or from random level)
procedure CreateDungeon(lvl: integer);
var
  i, j, k, n, t:   longint;
  rx, ry:    integer;
  dummy:     char;
  dummyline: string;
  DungeonFile: textfile;
  TownTiles, EmergencyBreak: integer;
begin

  InitDungeon;

  // predefined map?
  if fileexists(CONST_DATADIR + 'data/levels/premade/' + IntToStr(lvl) + '.txt') then
  begin
    if (ThePlayer.blCoffeeBreak = true) and (lvl=1) then
      Assign(DungeonFile, CONST_DATADIR + 'data/levels/premade/' + IntToStr(lvl) + '-cb.txt')
    else
      Assign(DungeonFile, CONST_DATADIR + 'data/levels/premade/' + IntToStr(lvl) + '.txt');
    if (lvl = 1) and (ThePlayer.longLevelVisits[1]>0) then
      for i := 1 to DngMaxWidth do
        for j := 1 to DngMaxHeight do
          DngLvl[i, j].blKnown := True;
  end
  else
    // random map
    Assign(DungeonFile, CONST_DATADIR + 'data/levels/random/' + IntToStr(lvl) + '.txt');

  Reset(DungeonFile);

  dummy     := ' ';
  dummyline := '';
  TownTiles := 0;

  i := 19;

  while EOF(DungeonFile) = False do
  begin
    Inc(i);
    ReadLn(DungeonFile, dummyline);

    for j := 1 to length(dummyline) do
    begin
      dummy := dummyline[j];
      case dummy of
        ' ':
        begin
          DngLvl[j + 10, i].intFloorType := 0;
          DngLvl[j + 10, i].intIntegrity := 9999;
        end;

        '#':
        begin // wall
          DngLvl[j + 10, i].intFloorType := 1;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        '*':
        begin // hidden door
          DngLvl[j + 10, i].intFloorType := 48;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        '(':
        begin // bookshelf
          DngLvl[j + 10, i].intFloorType := 49;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        '[':
        begin // stool
          DngLvl[j + 10, i].intFloorType := 50;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        ']':
        begin // table
          DngLvl[j + 10, i].intFloorType := 51;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        ')':
        begin // barrel
          DngLvl[j + 10, i].intFloorType := 52;
          DngLvl[j + 10, i].intIntegrity := 10 + trunc(random(10));
        end;

        'Y':
        begin // big mushroom
          DngLvl[j + 10, i].intFloorType := 53;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        'y':
        begin // small mushroom
          DngLvl[j + 10, i].intFloorType := 54;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        '}':
        begin // wood rests
          DngLvl[j + 10, i].intFloorType := 55;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        '{':
        begin // gas cylinder
          DngLvl[j + 10, i].intFloorType := 56;
          DngLvl[j + 10, i].intIntegrity := 20 + trunc(random(15));
        end;

        '$':
        begin
          DngLvl[j + 10, i].intFloorType := 25;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        '.':
        begin
          DngLvl[j + 10, i].intFloorType := 2;
          DngLvl[j + 10, i].intIntegrity := 0;
          DngLvl[j + 10, i].blTown := False;
        end;

        'O':
        begin                                  // dark room
          DngLvl[j + 10, i].intFloorType := 2;
          DngLvl[j + 10, i].intIntegrity := 0;
          DngLvl[j + 10, i].blTown      := False;
          DngLvl[j + 10, i].intAirType  := 5;
          DngLvl[j + 10, i].intAirRange := 10;
          DngLvl[j + 10, i].blKnown     := False;
        end;

        '%':
        begin                                // antbee web
          DngLvl[j + 10, i].intFloorType := 2;
          DngLvl[j + 10, i].intIntegrity := 0;
          DngLvl[j + 10, i].blTown      := False;
          DngLvl[j + 10, i].intAirType  := 6;
          DngLvl[j + 10, i].intAirRange := 10 + trunc(random(5));
        end;

        '-':
        begin
          DngLvl[j + 10, i].intFloorType := 2;
          DngLvl[j + 10, i].blTown := True;
          DngLvl[j + 10, i].intIntegrity := 0;
          Inc(TownTiles);
        end;

        '+':
        begin
          DngLvl[j + 10, i].intFloorType := 3;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        '@': // locked door
        begin
          DngLvl[j + 10, i].intFloorType := 24;
          DngLvl[j + 10, i].intIntegrity := 9999;
        end;

        'a': // locked iron gate
        begin
          DngLvl[j + 10, i].intFloorType := 64;
          DngLvl[j + 10, i].intIntegrity := 9999;
        end;

        chr(39):
        begin
          DngLvl[j + 10, i].intFloortype := 4;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;


        '=':
        begin
          DngLvl[j + 10, i].intFloorType := 5;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        '^':
        begin
          DngLvl[j + 10, i].intFloorType := 6;
          DngLvl[j + 10, i].intIntegrity := 200;
        end;

        '<':
        begin
          DngLvl[j + 10, i].intFloorType := 8;
          DngLvl[j + 10, i].intLight := 3;
          DngLvl[j + 10, i].intIntegrity := 0;
          UpX := j + 10;
          UpY := i;
        end;

        '>':
        begin
          // create steps from lvl 19 to 20 only, if player is evil or if player has killed Thanan
          if (lvl < 19) or (lvl > 20) or ((lvl = 19) and ((ThePlayer.blEvil = True) or (ThePlayer.blUnKilled[ReturnMonTeByName('Brother Thanan')]))) then
          begin
            DngLvl[j + 10, i].intFloorType := 9;
            DngLvl[j + 10, i].intLight := 3;
            DngLvl[j + 10, i].intIntegrity := 0;
            DownX := j + 10;
            DownY := i;
          end
          else
          begin
            DngLvl[j + 10, i].intFloorType := 2;
            DngLvl[j + 10, i].intIntegrity := 0;
            DngLvl[j + 10, i].blTown := False;
          end;
        end;

        // small tree
        't':
        begin
          DngLvl[j + 10, i].intFloorType := 10;
          DngLvl[j + 10, i].intLight     := 3;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;
        'T':
        begin
          DngLvl[j + 10, i].intFloorType := 10;
          DngLvl[j + 10, i].blTown   := True;
          DngLvl[j + 10, i].intLight := 3;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // big tree
        'b':
        begin
          DngLvl[j + 10, i].intFloorType := 13;
          DngLvl[j + 10, i].intLight     := 2;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;
        'B':
        begin
          DngLvl[j + 10, i].intFloorType := 13;
          DngLvl[j + 10, i].blTown   := True;
          DngLvl[j + 10, i].intLight := 2;
          DngLvl[j + 10, i].intIntegrity := 0;
          Inc(TownTiles);
        end;

        // grass
        'g':
        begin
          DngLvl[j + 10, i].intFloorType := 17;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;
        'G':
        begin
          DngLvl[j + 10, i].intFloorType := 17;
          DngLvl[j + 10, i].blTown := True;
          DngLvl[j + 10, i].intIntegrity := 0;
          Inc(TownTiles);
        end;

        // hill
        'h':
        begin
          DngLvl[j + 10, i].intFloorType := 18;
          DngLvl[j + 10, i].intLight     := 5;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;
        'H':
        begin
          DngLvl[j + 10, i].intFloorType := 18;
          DngLvl[j + 10, i].blTown   := True;
          DngLvl[j + 10, i].intLight := 5;
          DngLvl[j + 10, i].intIntegrity := 0;
          Inc(TownTiles);
        end;

        // ash
        'i':
        begin
          DngLvl[j + 10, i].intFloorType := 19;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // blue floor with star
        'w':
        begin
          DngLvl[j + 10, i].intFloorType := 30;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // snow
        'S':
        begin
          DngLvl[j + 10, i].intFloorType := 60;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // ice
        'I':
        begin
          DngLvl[j + 10, i].intFloorType := 61;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;


        // worm guano / excrements
        'c':
        begin
          DngLvl[j + 10, i].intFloorType := 11;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // machine oil
        'V':
        begin
          DngLvl[j + 10, i].intFloorType := 57;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // old machine parts
        'v':
        begin
          DngLvl[j + 10, i].intFloorType := 58;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // sand, mud
        ',':
        begin
          DngLvl[j + 10, i].intFloorType := 12;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // contaminated area
        'z':
        begin
          DngLvl[j + 10, i].intFloorType := 31;
          DngLvl[j + 10, i].intLight     := 2;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        ';':
        begin
          DngLvl[j + 10, i].intFloorType := 7;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // altar
        '|':
        begin
          DngLvl[j + 10, i].intFloorType := 15;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // blue floor
        'W':
        begin
          DngLvl[j + 10, i].intFloorType := 16;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // lava
        'l':
        begin
          DngLvl[j + 10, i].intFloorType := 20;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // crypt
        'N':
        begin
          DngLvl[j + 10, i].intFloorType := 26;
          DngLvl[j + 10, i].intIntegrity := 0;
          DngLvl[j + 10, i].intLight     := 2;
        end;

        '&':
        begin
          DngLvl[j + 10, i].intFloorType := 27;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        '?':
        begin
          DngLvl[j + 10, i].intFloorType := 32;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        // monster hive
        '!':
        begin
          DngLvl[j + 10, i].intFloorType := 34;
          DngLvl[j + 10, i].intIntegrity := 100;
        end;

        // well
        'U':
        begin
          DngLvl[j + 10, i].intFloorType := 28;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // empty well
        'u':
        begin
          DngLvl[j + 10, i].intFloorType := 29;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        'n':
        begin
          DngLvl[j + 10, i].intFloorType := 29;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // unique monster
        'X':
        begin
          UnX := j + 10;
          UnY := i;
          DngLvl[j + 10, i].intFloorType := 33;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // grass - sand 1
        'E':
        begin
          DngLvl[j + 10, i].intFloorType := 36;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // grass - sand 2
        'F':
        begin
          DngLvl[j + 10, i].intFloorType := 37;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // grass - water 1
        'A':
        begin
          DngLvl[j + 10, i].intFloorType := 38;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // grass - water 2
        'J':
        begin
          DngLvl[j + 10, i].intFloorType := 39;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // grass - water 3
        'j':
        begin
          DngLvl[j + 10, i].intFloorType := 40;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // small autumn tree
        'P':
        begin
          DngLvl[j + 10, i].intFloorType := 21;
          DngLvl[j + 10, i].intLight     := 3;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // big autumn tree
        'L':
        begin
          DngLvl[j + 10, i].intFloorType := 22;
          DngLvl[j + 10, i].intLight     := 2;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // dry grass
        'D':
        begin
          DngLvl[j + 10, i].intFloorType := 23;
          DngLvl[j + 10, i].intIntegrity := 0;
        end;

        // NPCs
        '1', '2', '3', '4', '5', '6', '7', '8', '9':
        begin
          if ThePlayer.blCoffeebreak=false then // generate NPCs only in story mode
          begin
            k:=StrToInt(dummy);
            if (Quest[lvl, k].intNeedProf=0) or (Quest[lvl,k].intNeedProf = ThePlayer.intProf) then
              if (Quest[lvl, k].intClass=0) or (Quest[lvl,k].intClass = ThePlayer.intReli) then
                if Quest[lvl, k].strNPCname <> '-' then
                begin
                  NPC[k].intX := j + 10;
                  NPC[k].intY := i;
                  DngLvl[j + 10, i].intBuilding := -(k);
                end;
            DngLvl[j + 10, i].intFloorType := 2;
            DngLvl[j + 10, i].intIntegrity := 0;
          end
          else
          begin
            DngLvl[j + 10, i].intFloorType := 2;
            DngLvl[j + 10, i].intIntegrity := 0;
            DngLvl[j + 10, i].blTown := False;
          end;
        end;

      end;
    end;
  end;

  Close(DungeonFile);


  // place portal through time to Noldarur in level 1
  if lvl=1 then
    if ThePlayer.blNold=true then
      if ThePlayer.blUnKilled[ReturnMonTeByName('Ordinator')] = False then
        DngLvl[23, 55].intFloorType := 59;

  // place portal through time back to Temple in level 21 (Noldarur)
  if lvl = 21 then
  begin
    repeat
      rx := trunc(5 + random(DngMaxWidth - 5));
      ry := trunc(5 + random(DngMaxHeight - 5));
    until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intIntegrity = 0) and (DngLvl[rx, ry].blTown = False);
    DngLvl[rx, ry].intFloorType := 59;
  end;

  // place 2nd exit to wilderness in level 2
  if (lvl = 2) and (ThePlayer.blCoffeeBreak=false) then
  begin
    repeat
      rx := trunc(5 + random(DngMaxWidth - 5));
      ry := trunc(5 + random(DngMaxHeight - 5));
    until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intIntegrity = 0) and
      (DngLvl[rx, ry].blTown = False);
    DngLvl[rx, ry].intFloorType := 62;
  end;

  // place exit from wilderness to level 2
  if lvl = 22 then
  begin
    repeat
      rx := trunc(5 + random(DngMaxWidth - 5));
      ry := trunc(5 + random(DngMaxHeight - 5));
    until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intIntegrity = 0) and
      (DngLvl[rx, ry].blTown = False);
    DngLvl[rx, ry].intFloorType := 63;
  end;

  // place ladder to spaceship in level 24
  if lvl = 24 then
  begin
    repeat
      rx := trunc(5 + random(DngMaxWidth - 5));
      ry := trunc(5 + random(DngMaxHeight - 5));
    until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intIntegrity = 0) and
      (DngLvl[rx, ry].blTown = False);
    DngLvl[rx, ry].intFloorType := 67;
  end;

  // place ladder back to forgotten realm in level 26
  if lvl = 26 then
  begin
     //writeln ('- ladder to realm');
    repeat
      rx := trunc(5 + random(DngMaxWidth - 5));
      ry := trunc(5 + random(DngMaxHeight - 5));
    until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intIntegrity = 0) and
      (DngLvl[rx, ry].blTown = False);
    DngLvl[rx, ry].intFloorType := 66;
  end;

  // place traders
  if (TownTiles > 12) and ((lvl = 1) or (lvl = 5) or (lvl = 10) or (lvl = 15)) then
  begin
             //writeln('- traders');
    for i := 1 to 8 do    // 8 is the number of trader types
    begin
      repeat
        rx := trunc(1 + random(DngMaxWidth));
        ry := trunc(1 + random(DngMaxHeight));
      until (DngLvl[rx, ry].intFloorType = 2) and
        (DngLvl[rx, ry].blTown = True) and (DngLvl[rx, ry].intIntegrity = 0) and
        (DngLvl[rx, ry].intBuilding = 0);

      // reposition library trader in DLV 1
      if (DungeonLevel = 1) and (i = 4) and (ThePlayer.blCoffeebreak=false) then
      begin
        rx := 56;
        ry := 37;
      end;

      DngLvl[rx, ry].intBuilding := i;
      MyShop[i].intType := i;
    end;
  end;


  // place treasure chests
       //writeln('- treasure chests');
  if ((lvl > 1) and (ThePlayer.longLevelVisits[lvl] < 1) and (lvl <> 13) and
    (lvl <> 21) and (lvl <> 22) and (lvl <> 23) and (lvl <> 24) and
    (lvl <> 25) and (lvl <> 26) and (lvl <> 27)) or (lvl = 13) then
  begin
    for i := 1 to lvl + trunc(random(6)) do
    begin
      EmergencyBreak := 0;
      repeat
        rx := trunc(1 + random(DngMaxWidth));
        ry := trunc(1 + random(DngMaxHeight));
        Inc(EmergencyBreak);
      until (EmergencyBreak = 1000) or ((CheckForNPC(rx, ry) = False) and
          (DngLvl[rx, ry].intFloorType = 2));

      // lvl 13 is special: only crypts
      if lvl = 13 then
        DngLvl[rx, ry].intFloorType := 26
      else
        DngLvl[rx, ry].intFloorType := 7;
    end;
  end;

  // place altars
       //writeln('- altars');
  if (lvl = 3) or (lvl = 7) or (lvl = 11) then
    for i := 1 to 2 + trunc(random(3)) do
    begin
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intFloorType = 2);
      DngLvl[rx, ry].intFloorType := 15;
    end;

  // place traps (traps are airtype 7 and 8)
       //writeln('- traps');

  if (lvl>1) and (lvl<21) then
  begin

    t:=0;
    case lvl of
      2, 4: t:=1;
      3, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18: t:=2;
      5: t:=4;
      19: t:=8;
      20: t:=20;
    end;

    for i := 1 to t do
    begin
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until DngLvl[rx, ry].intIntegrity = 0;

      DngLvl[rx, ry].intAirType := 7;

      // select effect
      n := trunc(random(7));
      case n of
        0:
          DngLvl[rx, ry].intAirRange := 16;
        1:
          DngLvl[rx, ry].intAirRange := 21;
        2:
          DngLvl[rx, ry].intAirRange := 23;
        3:
          DngLvl[rx, ry].intAirRange := 24;
        4:
          DngLvl[rx, ry].intAirRange := 34;
        5:
          DngLvl[rx, ry].intAirRange := 44;
        6:
          DngLvl[rx, ry].intAirRange := 45;
      end;
    end;
  end;


  // place monster hives
  HiveX := -1;
  HiveY := -1;
       //writeln('- hives');
  if (lvl = 2) or (lvl = 5) or (lvl = 9) or (lvl = 15) or (lvl = 19) then
    // only if intNoHivesAnymore = 0
    if intNoHivesAnymore[lvl] = 0 then
    begin
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intIntegrity = 0) and
        (DngLvl[rx, ry].blTown = False);
      DngLvl[rx, ry].intFloorType := 34;
      DngLvl[rx, ry].intIntegrity := lvl * 250;
      HiveX := rx;
      HiveY := ry;
    end;

  // place crypts
       //writeln('- crypts');
  if (lvl = 3) or (lvl = 9) or (lvl = 13) or (lvl = 16) or (lvl = 20) then
    for i := 1 to 4 do
    begin
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intFloorType = 2);
      DngLvl[rx, ry].intFloorType := 26;
    end;

  // place wells
       //writeln('- wells');
  if (lvl < 19) and (lvl <> 1) and (lvl <> 5) and (lvl <> 26) and (lvl <> 27) then
    for i := 1 to 3 do
    begin
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intFloorType = 2);
      DngLvl[rx, ry].intFloorType := 28;
    end;

  // place items, if first visit of this level
       //writeln('- Items');

  //     //writeln ('level visited ' + IntToStr(ThePlayer.longLevelVisits[lvl]) + ' times.');
  if (ThePlayer.longLevelVisits[lvl] < 1) and (lvl > 1) and (lvl <> 18) and
    (lvl <> 22) and (lvl <> 23) and (lvl <> 24) and (lvl <> 25) and
    (lvl <> 26) and (lvl <> 27) then
  begin
    //         //writeln('creating items.');
    for i := 1 to CONST_MIN_ITEMS do
    begin
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intItem = 0) and (DngLvl[rx, ry].intIntegrity = 0) and (DngLvl[rx, ry].intFloorType<>20);

      repeat
        n := trunc(1 + random(ItemCount));
      until (Thing[n].intMinLvl <= DungeonLevel) and (Thing[n].intMinLvl >= DungeonLevel - 3) and
        (Thing[n].blUnique = False) and (Thing[n].blRare = False) and
        (Thing[n].blShopOnly = False) and (Thing[n].intWP = 0) and
        (Thing[n].intAP = 0) and (Thing[n].intGP = 0);
      DngLvl[rx, ry].intItem := n;
    end;
  end;

  // place Santa's items in DungeonLevel 18
  if (lvl=18) and (ThePlayer.blCoffeeBreak=false) then
  begin
    if ThePlayer.intQuestState[2,4]=1 then
    begin

      // coat
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intItem = 0) and (DngLvl[rx, ry].intIntegrity = 0) and (DngLvl[rx, ry].intFloorType<>20);
      DngLvl[rx, ry].intItem := ReturnItemByName('Santa''s Coat');
      DngLvl[rx, ry].intFloorType := 6;
      DngLvl[rx, ry].intIntegrity := 100;

      // cap
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intItem = 0) and (DngLvl[rx, ry].intIntegrity = 0) and (DngLvl[rx, ry].intFloorType<>20);
      DngLvl[rx, ry].intItem := ReturnItemByName('Santa''s Cap');
      DngLvl[rx, ry].intFloorType := 6;
      DngLvl[rx, ry].intIntegrity := 100;

      // rod
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intItem = 0) and (DngLvl[rx, ry].intIntegrity = 0) and (DngLvl[rx, ry].intFloorType<>20);
      DngLvl[rx, ry].intItem := ReturnItemByName('Santa''s Rod');
      DngLvl[rx, ry].intFloorType := 6;
      DngLvl[rx, ry].intIntegrity := 100;

      // bag
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intItem = 0) and (DngLvl[rx, ry].intIntegrity = 0) and (DngLvl[rx, ry].intFloorType<>20);
      DngLvl[rx, ry].intItem := ReturnItemByName('Santa''s Bag');
      DngLvl[rx, ry].intFloorType := 6;
      DngLvl[rx, ry].intIntegrity := 100;

      // boots
      repeat
        rx := trunc(5 + random(DngMaxWidth - 5));
        ry := trunc(5 + random(DngMaxHeight - 5));
      until (CheckForNPC(rx, ry) = False) and (DngLvl[rx, ry].intItem = 0) and (DngLvl[rx, ry].intIntegrity = 0) and (DngLvl[rx, ry].intFloorType<>20);
      DngLvl[rx, ry].intItem := ReturnItemByName('Santa''s Boots');
      DngLvl[rx, ry].intFloorType := 6;
      DngLvl[rx, ry].intIntegrity := 100;

    end;


  // enemies
   //writeln('- Create life');
  end;

  FillDungeon(lvl);

  ThePlayer.intX := rx;
  ThePlayer.intY := ry;
end;


procedure PlacePlayer(f, FromLevel: integer);
begin
  //writeln('- place player ' + IntToStr(f));

  // ensure that player can return to prev. level even without Eris' Key
  if (DungeonLevel = 19) and (FromLevel = 20) and
    (PlayerHasItem('Eris' + chr(39) + ' Key') = -1) then
    f := -1;

  if f = -1 then
  begin
    repeat
      ThePlayer.intX := trunc(5 + random(DngMaxWidth - 5));
      ThePlayer.intY := trunc(5 + random(DngMaxHeight - 5));
    until DngLvl[ThePlayer.intX, ThePlayer.intY].intIntegrity = 0;
  end
  else
  begin
    repeat
      ThePlayer.intX := trunc(1 + random(DngMaxWidth));
      ThePlayer.intY := trunc(1 + random(DngMaxHeight));
      //             //writeln(IntToStr(DngLvl[ThePlayer.intX,ThePlayer.intY].intFloorType));
    until DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = f;
  end;

  // prevent player of being stuck in antbee webs directly after entering
  if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 6 then
  begin
    DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType  := 0;
    DngLvl[ThePlayer.intX, ThePlayer.intY].intAirRange := 0;
  end;

  // correct placement in static first level
  if (DungeonLevel = 1) and (FromLevel = 0) and (ThePlayer.blCoffeebreak=false) then
  begin
    ThePlayer.intX := 38;
    ThePlayer.intY := 38;
    DngLvl[36, 37].intItem := ReturnItemByName('The Temple of Enoa');
  end;

       //writeln ('- player placed.');

end;


procedure Earthquake;
var
  rx, ry, i, j, n: integer;
begin
  // scatter rubble
  n := 50 + trunc(random(200));
  for i := 1 to n do
  begin
    repeat
      rx := trunc(5 + random(DngMaxWidth - 5));
      ry := trunc(5 + random(DngMaxHeight - 5));
    until (DngLvl[rx, ry].intIntegrity = 0);

    // hurt player
    if (rx = ThePlayer.intX) and (ry = ThePlayer.intY) then
    begin
      Dec(ThePlayer.intHP);
    end;

    // hurt monsters
    for j := 1 to 510 do
      if (rx = Monster[j].intX) and (ry = Monster[j].intY) then
      begin

        Dec(Monster[j].intHP);

        // unique monsters won't be killed completly
        if (Monster[j].blUnique = True) and (Monster[j].intHP < 10) then
          Inc(Monster[j].intHP);

        if Monster[j].intHP < 1 then
        begin
          // blood
          CreateBlood(Monster[j].intX, Monster[j].intY);

          // hide monster object by moving out of the dungeon
          Monster[j].intX := DngMaxWidth + 10;
          Monster[j].intY := DngMaxHeight + 10;
        end;
      end;

    // destroy items
    DngLvl[rx, ry].intItem := ReturnItemByName('Rubble');

  end;
end;

end.
