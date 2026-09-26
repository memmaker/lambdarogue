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

unit FileIO;


interface

uses
  Constants, ExternMusic, ExternSFX, Crt, Keyboard, Video, Input, Dungeon, MessageLog,
  SysUtils, RandomArea, CollectData, Player, Chants, Items, Quests, BaseOutput;

procedure SaveConfig;
procedure InitKeys(b: boolean);
function BoolString(b: boolean; m: integer): string;
function BoolToggle(b: boolean): boolean;
procedure CharacterDump(reason: string);
procedure SaveGame(charname: string; lvl: integer);
procedure LoadGame(charname: string);
procedure SaveItemTables;
procedure SaveMonsterTables;
procedure SaveChantTables;

implementation

// returns "true"/"false" or "yes"/"no" as String
function BoolString(b: boolean; m: integer): string;
begin
  if m = 0 then
  begin
    if b = True then
      BoolString := 'True'
    else
      BoolString := 'False';
  end
  else
  begin
    if b = True then
      BoolString := 'Yes'
    else
      BoolString := 'No';
  end;
end;


// swaps the true/false string of the given boolean
function BoolToggle(b: boolean): boolean;
begin
  BoolToggle := not (b);
end;


procedure SaveConfig;
var
  KeyFile: TextFile;
begin
  Assign(KeyFile, CONST_DATADIR + 'lambdarogue.cfg');
  Rewrite(KeyFile);

  Writeln(KeyFile, '# LambdaRogue Configuration File');
  Writeln(KeyFile, '# created by LambdaRogue ' + strVersion);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, '# Visual Options');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'UseSDL');
  Writeln(KeyFile, '= ' + BoolString(UseSDL, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'SmallTiles');
  Writeln(KeyFile, '= ' + BoolString(UseSmallTiles, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'OldSmallTiles');
  Writeln(KeyFile, '= ' + BoolString(UseOldSmallTiles, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, '1024x768');
  Writeln(KeyFile, '= ' + BoolString(UseHiRes, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ForceFullScreen');
  Writeln(KeyFile, '= ' + BoolString(UseFullScreen, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ShowBlood');
  Writeln(KeyFile, '= ' + BoolString(ShowBlood, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, '# Gameplay Options');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveAfterKill');
  Writeln(KeyFile, '= ' + BoolString(AutoMoveToTile, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, '# Music Options');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'PlayMusic');
  Writeln(KeyFile, '= ' + BoolString(blUseExternPlayer, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'PlaySoundFX');
  Writeln(KeyFile, '= ' + BoolString(blUseExternPlayerTwo, 0));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'VolumeMusic:');
  Writeln(KeyFile, IntToStr(intVolumeMusic));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'VolumeSoundFX:');
  Writeln(KeyFile, IntToStr(intVolumeSFX));
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, '# Keybindings');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveNorth:');
  Writeln(KeyFile, KeyNorth);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveSouth:');
  Writeln(KeyFile, KeySouth);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveEast:');
  Writeln(KeyFile, KeyEast);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveWest:');
  Writeln(KeyFile, KeyWest);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveNorthEast:');
  Writeln(KeyFile, KeyNorthEast);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveNorthWest:');
  Writeln(KeyFile, KeyNorthWest);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveSouthEast:');
  Writeln(KeyFile, KeySouthEast);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'MoveSouthWest:');
  Writeln(KeyFile, KeySouthWest);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'GeneralAction:');
  Writeln(KeyFile, KeyEnter);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'TalkAndTrade:');
  Writeln(KeyFile, KeyTrade);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'CloseDoor:');
  Writeln(KeyFile, KeyCloseDoor);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Dig:');
  Writeln(KeyFile, KeyTunnel);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Take:');
  Writeln(KeyFile, KeyTake);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'SearchAndSteal:');
  Writeln(KeyFile, KeySearchSteal);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Pray:');
  Writeln(KeyFile, KeyPray);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ShootWeapon:');
  Writeln(KeyFile, KeyShoot);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Throw:');
  Writeln(KeyFile, KeyThrow);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Tactics:');
  Writeln(KeyFile, KeyTactics);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Songbook:');
  Writeln(KeyFile, KeyChant);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ChantLastSong:');
  Writeln(KeyFile, KeyChantLast);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'RestOneTurn:');
  Writeln(KeyFile, KeyShortRest);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Rest:');
  Writeln(KeyFile, KeyRest);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ShowStatus:');
  Writeln(KeyFile, KeyStatus);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ShowQuestlog:');
  Writeln(KeyFile, KeyQuestlog);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ShowInventory:');
  Writeln(KeyFile, KeyInventory);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'SetQuickKeys:');
  Writeln(KeyFile, KeySetQuickKeys);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'ShowHelp:');
  Writeln(KeyFile, KeyHelp);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'Map:');
  Writeln(KeyFile, KeyBigMap);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'IdentifyTile:');
  Writeln(KeyFile, KeyLook);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'GameMenu:');
  Writeln(KeyFile, KeyQuit);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'SpecialAbility:');
  Writeln(KeyFile, KeySpecial);
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, ' ');
  Writeln(KeyFile, 'DivineRage:');
  Writeln(KeyFile, KeySpecialDiv);
  Writeln(KeyFile, ' ');

  Close(KeyFile);
end;


procedure InitKeys(b: boolean);
var
  KeyFile, DebugFile: TextFile;
  strKey, strValue: string;
begin

  if b = True then
  begin
    UseSDL      := False;
    UseHiRes    := False;
    Netbook     := False;
    UseOldSmallTiles := False;
    UseFullScreen := False;
    UseMouseToMove := False;
    GrowingMonsters := True;
    MoveOneTilePerClick := False;
    blUseExternPlayer := False;
    blUseExternPlayerTwo := False;
    intVolumeMusic := 0;
    intVolumeSFX := 0;
    AutoMoveToTile := False;
    UseSmallTiles := False;
    KeyNorth    := 'k';
    KeySouth    := 'j';
    KeyEast     := 'l';
    KeyWest     := 'h';
    KeyNorthEast := 'u';
    KeySouthEast := 'n';
    KeyNorthWest := 'y';
    KeySouthWest := 'b';
    KeyEnter    := 'a';
    KeyTrade    := 't';
    KeyTake     := 'g';
    KeyCloseDoor := 'D';
    KeyTunnel   := 'd';
    KeyPray     := 'p';
    KeyShoot    := 'f';
    KeyThrow    := 'T';
    KeyChant    := 'm';
    KeyShortRest := '.';
    KeyRest     := 'r';
    KeyStatus   := 's';
    KeySearchSteal := 'S';
    KeyQuestlog := 'L';
    KeyInventory := 'i';
    KeyHelp     := '?';
    KeyLook     := 'I';
    KeyQuit     := 'Q';
    KeyChantLast := 'c';
    KeySetQuickKeys := 'C';
    KeyBigMap   := 'M';
    KeyTactics := '-';
    KeySpecial := 'x';
    KeySpecialDiv := 'X';
  end;


  // WriteLn ('reading config file ...');
  
  Assign(KeyFile, CONST_DATADIR + 'lambdarogue.cfg');
  Reset(KeyFile);

  while EOF(KeyFile) = False do
  begin
    repeat
      ReadLn(KeyFile, strKey);
      strKey := trim(lowercase(strKey));
    until ((strKey <> '') and (strKey[1] <> '#')) or (EOF(KeyFile));

    ReadLn(KeyFile, strValue);
    strValue := trim(strValue);

    //         strValue:=lowercase(strValue);

    //         WriteLn('read '+strKey+' '+strValue);

    // movement
    if strKey = 'movenorth:' then
      KeyNorth := strValue[1];
    if strKey = 'movesouth:' then
      KeySouth := strValue[1];
    if strKey = 'moveeast:' then
      KeyEast := strValue[1];
    if strKey = 'movewest:' then
      KeyWest := strValue[1];
    if strKey = 'movenortheast:' then
      KeyNorthEast := strValue[1];
    if strKey = 'movesoutheast:' then
      KeySouthEast := strValue[1];
    if strKey = 'movenorthwest:' then
      KeyNorthWest := strValue[1];
    if strKey = 'movesouthwest:' then
      KeySouthWest := strValue[1];

    // interaction
    if strKey = 'generalaction:' then
      KeyEnter := strValue[1];

    if strKey = 'talkandtrade:' then
      KeyTrade := strValue[1];
    if strKey = 'searchandsteal:' then
      KeySearchSteal := strValue[1];
    if strKey = 'closedoor:' then
      KeyCloseDoor := strValue[1];
    if strKey = 'dig:' then
      KeyTunnel := strValue[1];
    if strKey = 'take:' then
      KeyTake := strValue[1];
    if strKey = 'setquickkeys:' then
      KeySetQuickKeys := strValue[1];

    if strKey = 'pray:' then
      KeyPray := strValue[1];
    if strKey = 'shootweapon:' then
      KeyShoot := strValue[1];
    if strKey = 'throw:' then
      KeyThrow := strValue[1];

    if strKey = 'tactics:' then
      KeyTactics := strValue[1];

    if strKey = 'songbook:' then
      KeyChant := strValue[1];
    if strKey = 'chantlastsong:' then
      KeyChantLast := strValue[1];
    if strKey = 'restoneturn:' then
      KeyShortRest := strValue[1];
    if strKey = 'rest:' then
      KeyRest := strValue[1];

    if strKey = 'showstatus:' then
      KeyStatus := strValue[1];
    if strKey = 'showquestlog:' then
      KeyQuestlog := strValue[1];
    if strKey = 'showinventory:' then
      KeyInventory := strValue[1];

    if strKey = 'showhelp:' then
      KeyHelp := strValue[1];
    if strKey = 'map:' then
      KeyBigMap := strValue[1];
    if strKey = 'identifytile:' then
      KeyLook := strValue[1];

    if strKey = 'gamemenu:' then
      KeyQuit := strValue[1];

    if strKey = 'specialability:' then
      KeySpecial := strValue[1];

    if strKey = 'divinerage:' then
      KeySpecialDiv := strValue[1];

    if strKey = 'volumemusic:' then
      intVolumeMusic := StrToInt(strValue);

    if strKey = 'volumesoundfx:' then
      intVolumeSFX := StrToInt(strValue);

    // also read options
    if b = True then
    begin
      if (strKey = 'usesdl') and (lowercase(strValue) = '= true') then
        UseSDL := True;
      if (strKey = 'usesdl') and (lowercase(strValue) = '= false') then
        UseSDL := False;

      if (strKey = '1024x768') and (lowercase(strValue) = '= true') then
        UseHiRes := True;
      if (strKey = '1024x768') and (lowercase(strValue) = '= false') then
        UseHiRes := False;

      if (strKey = 'forcefullscreen') and (lowercase(strValue) = '= true') then
        UseFullScreen := True;
      if (strKey = 'forcefullscreen') and (lowercase(strValue) = '= false') then
        UseFullScreen := False;

      if (strKey = 'smalltiles') and (lowercase(strValue) = '= true') then
        UseSmallTiles := True;
      if (strKey = 'smalltiles') and (lowercase(strValue) = '= false') then
        UseSmallTiles := False;

      if (strKey = 'oldsmalltiles') and (lowercase(strValue) = '= true') then
        UseOldSmallTiles:= True;
      if (strKey = 'oldsmalltiles') and (lowercase(strValue) = '= false') then
        UseOldSmallTiles := False;

      if (strKey = 'showblood') and (lowercase(strValue) = '= true') then
        ShowBlood := True;
      if (strKey = 'showblood') and (lowercase(strValue) = '= false') then
        ShowBlood := False;

      //if (strKey='usemouse') and (lowercase(strValue)='= true') then
      //UseMouseToMove := true;
      //if (strKey='usemouse') and (lowercase(strValue)='= false') then
      //UseMouseToMove := false;
      UseMouseToMove := False;

      if (strKey = 'growingmonsters') and (lowercase(strValue) = '= true') then
        GrowingMonsters := True;
      if (strKey = 'growingmonsters') and (lowercase(strValue) = '= false') then
        GrowingMonsters := False;

      if (strKey = 'moveafterkill') and (lowercase(strValue) = '= true') then
        AutoMoveToTile := True;
      if (strKey = 'moveafterkill') and (lowercase(strValue) = '= false') then
        AutoMoveToTile := False;

      if (strKey = 'moveonetileperclick') and (lowercase(strValue) = '= true') then
        MoveOneTilePerClick := True;
      if (strKey = 'moveonetileperclick') and (lowercase(strValue) = '= false') then
        MoveOneTilePerClick := False;

      if (strKey = 'playmusic') and (lowercase(strValue) = '= true') then
        blUseExternPlayer := True;
      if (strKey = 'playmusic') and (lowercase(strValue) = '= false') then
        blUseExternPlayer := False;

      if (strKey = 'playsoundfx') and (lowercase(strValue) = '= true') then
        blUseExternPlayerTwo := True;
      if (strKey = 'playsoundfx') and (lowercase(strValue) = '= false') then
        blUseExternPlayerTwo := False;

      if strKey = 'mediaplayer:' then
        strExternPlayer := strValue;
    end;
  end;

  Close(KeyFile);

  // don't use Netbook mode
  Netbook:=false;

end;


procedure CharacterDump(reason: string);
var
  dumpfile:     Textfile;
  i, j, solved: integer;
  equi, strSex, strProf, levelname: string;
begin
  ClearScreenSDL;

  Assign(DumpFile, CONST_DATADIR + 'saves/' + ThePlayer.strName + '-dump.txt');
  Rewrite(DumpFile);

  case ThePlayer.intSex of
    1:
      strSex := 'male';
    2:
      strSex := 'female';
  end;

  case ThePlayer.intProf of
    1:
      strProf := 'Constructor';
    2:
      strProf := 'Enchanter';
    3:
      strProf := 'Thief';
    4:
      strProf := 'Archer';
    5:
      strProf := 'Soldier';
  end;


  if ThePlayer.blEvil = True then
    WriteLn(DumpFile, ThePlayer.strName, ', ' + strSex + ', devoted to death')
  else
    WriteLn(DumpFile, ThePlayer.strName, ', ' + strSex + ', believer in ' +
      ThePlayer.strReli);


  WriteLn(DumpFile,
    '----------------------------------------------------------------------');
  WriteLn(DumpFile, ' ');

  WriteLn(DumpFile, 'LambdaRogue version: ' + strVersion);
  WriteLn(DumpFile, ' ');

  if ThePlayer.blCoffeeBreak=true then
    WriteLn(DumpFile, 'Game mode: Coffeebreak')
  else
    WriteLn(DumpFile, 'Game mode: Story mode');

  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, 'HP: ' + IntToStr(ThePlayer.intHP) + '/' +
    IntToStr(ThePlayer.intMaxHP));
  WriteLn(DumpFile, 'PP: ' + IntToStr(ThePlayer.intPP) + '/' +
    IntToStr(ThePlayer.intMaxPP));
  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, 'Strength: ' + IntToStr(ThePlayer.intStrength) + '%/100%');
  WriteLn(DumpFile, 'Distress: ' + IntToStr(ThePlayer.intLimit) + '%/100%');
  WriteLn(DumpFile, ' ');

  levelName := ReturnLevelName(DungeonLevel);

  if DungeonLevel < 20 then
    WriteLn(DumpFile, reason + ' on dungeon level ' + IntToStr(DungeonLevel) +
      ' (' + levelname + ').');
  if (DungeonLevel = 20) or (DungeonLevel = 21) then
    WriteLn(DumpFile, reason + ' on dungeon level ? (' + levelname + ').');
  if DungeonLevel > 21 then
    WriteLn(DumpFile, reason + ' on dungeon level ' + IntToStr(DungeonLevel - 21) +
      ' (' + levelname + ').');

  WriteLn(DumpFile, 'Date: ' + IntToStr(intDayTime) + '-' +
    IntToStr(intDay) + '-' + IntToStr(longYear));
  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, ThePlayer.strName + ' was active for ' + IntToStr(
    longTotalTurns) + ' turns.');
  WriteLn(DumpFile, 'In this time, ' + ThePlayer.strName +
    ' achieved a score of ' + IntToStr(ThePlayer.longScore) + ' points.');
  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, 'Abilities');
  WriteLn(DumpFile, '  Fight       : ' + IntToStr(ThePlayer.intFight));
  WriteLn(DumpFile, '  Hit         : ' + IntToStr(ThePlayer.intView));
  WriteLn(DumpFile, '  Chant       : ' + IntToStr(ThePlayer.intChant));
  WriteLn(DumpFile, '  Move        : ' + IntToStr(ThePlayer.intMove));
  WriteLn(DumpFile, '  Steal       : ' + IntToStr(ThePlayer.intBurgle));
  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, 'Skills');
  WriteLn(DumpFile, '  Sword       : ' + IntToStr(ThePlayer.intSword));
  WriteLn(DumpFile, '  Axe         : ' + IntToStr(ThePlayer.intAxe));
  WriteLn(DumpFile, '  Lance       : ' + IntToStr(ThePlayer.intWhip));
  WriteLn(DumpFile, '  Fire-arm    : ' + IntToStr(ThePlayer.intGun));
  WriteLn(DumpFile, '  Tool        : ' + IntToStr(ThePlayer.intTool));
  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, 'Talents');
  WriteLn(DumpFile, '  Humility    : ' + IntToStr(ThePlayer.intHumility));
  WriteLn(DumpFile, '  Trade       : ' + IntToStr(ThePlayer.intTrade));
  WriteLn(DumpFile, ' ');

  Writeln(DumpFile, 'Melee/Long-range/Defense: ' + IntToStr(CollectTP) +
    '/' + IntToStr(CollectGunTP) + '/' + IntToStr(CollectDP));

  WriteLn(DumpFile, ' ');

  WriteLn(DumpFile, 'Experience    : ' + IntToStr(ThePlayer.longEXP));
  WriteLn(DumpFile, 'Character Lvl.: ' + IntToStr(ThePlayer.intLvl));

  WriteLn(DumpFile, ' ');

  WriteLn(DumpFile, 'Profession: ' + strProf);

  if ThePlayer.intDipl[1] = 1 then
    WriteLn(DumpFile, '- Centurio');
  if ThePlayer.intDipl[2] = 1 then
    WriteLn(DumpFile, '  +- Hastatus');
  if ThePlayer.intDipl[3] = 1 then
    WriteLn(DumpFile, '     +- Princeps');
  if ThePlayer.intDipl[4] = 1 then
    WriteLn(DumpFile, '        +- Pilus');
  if ThePlayer.intDipl[5] = 1 then
    WriteLn(DumpFile, '           +- Primus Pilus');

  if ThePlayer.intDipl[6] = 1 then
    WriteLn(DumpFile, '- Mage');
  if ThePlayer.intDipl[7] = 1 then
    WriteLn(DumpFile, '  +- Battlemage');
  if ThePlayer.intDipl[8] = 1 then
    WriteLn(DumpFile, '- Believer');
  if ThePlayer.intDipl[9] = 1 then
    WriteLn(DumpFile, '  +- Monk');
  if ThePlayer.intDipl[10] = 1 then
    WriteLn(DumpFile, '     +- Holy Warrior');

  if ThePlayer.intDipl[11] = 1 then
    WriteLn(DumpFile, '- Assassin');
  if ThePlayer.intDipl[12] = 1 then
    WriteLn(DumpFile, '  +- Agent');
  if ThePlayer.intDipl[13] = 1 then
    WriteLn(DumpFile, '- Master Thief');
  if ThePlayer.intDipl[14] = 1 then
    WriteLn(DumpFile, '  +- Guild Leader');

  if ThePlayer.intDipl[15] = 1 then
    WriteLn(DumpFile, '- Hunter');
  if ThePlayer.intDipl[16] = 1 then
    WriteLn(DumpFile, '  +- Ranger');
  if ThePlayer.intDipl[17] = 1 then
    WriteLn(DumpFile, '- Marksman');
  if ThePlayer.intDipl[18] = 1 then
    WriteLn(DumpFile, '  +- Lieutenant');


  if ThePlayer.blCoffeeBreak=false then
  begin
    WriteLn(DumpFile, ' ');
    solved := 0;
    for i := 1 to WinLevel do
      for j := 1 to 9 do
        if (ThePlayer.intQuestState[i, j] = 2) and (Quest[i, j].strDescri <> '-') then
          Inc(solved);

    WriteLn(DumpFile, ThePlayer.strName + ' has solved ' + IntToStr(solved) +
      ' quest(s).');

    if solved > 0 then
    begin
      WriteLn(DumpFile, 'Solved quests:');
      for i := 1 to WinLevel do
        for j := 1 to 9 do
          if (ThePlayer.intQuestState[i, j] = 2) and (Quest[i, j].strDescri <> '-') then
            WriteLn(DumpFile, '    ' + Quest[i, j].strDescri);
      WriteLn(DumpFile, ' ');
    end;
  end;


  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, ' ');

  if ThePlayer.longContCleared > 0 then
  begin
    WriteLn(DumpFile, ThePlayer.strName + ' cleared ' +
      IntToStr(ThePlayer.longContCleared) + ' contaminated areas.');
    WriteLn(DumpFile, ' ');
  end;

  if ThePlayer.intTotalVitari > 0 then
    WriteLn(DumpFile, ThePlayer.strName + ' was addicted to drugs.');

  if ThePlayer.longPrayers > 0 then
  begin
    if ThePlayer.longLifeIns > 0 then
      WriteLn(DumpFile, ThePlayer.strName + ' prayed ' + IntToStr(ThePlayer.longPrayers) + ' and saved ' + IntToStr(ThePlayer.longLifeIns) + ' time(s), ')
    else
      WriteLn(DumpFile, ThePlayer.strName + ' prayed ' + IntToStr(ThePlayer.longPrayers) + ' time(s)');
    WriteLn(DumpFile, ' ');
  end
  else
  if ThePlayer.longLifeIns > 0 then
  begin
    WriteLn(DumpFile, 'Although ' + ThePlayer.strName + ' saved ' +
      IntToStr(ThePlayer.longLifeIns) + ' time(s), ' + ThePlayer.strName + ' is dead.');
    WriteLn(DumpFile, ' ');
  end;

  Writeln(DumpFile, ' ');
  Writeln(DumpFile, 'Equipment:');
  Writeln(DumpFile, '----------');
  if ThePlayer.intWeapon > 0 then
    Writeln(DumpFile, 'Weapon      : ' + Thing[ThePlayer.intWeapon].strName + chr(9) + 'WP/GP/AP: ' + IntToStr(Thing[ThePlayer.intWeapon].intWP) + '/' + IntToStr(Thing[ThePlayer.intWeapon].intGP) + '/' + IntToStr(Thing[ThePlayer.intWeapon].intAP));
  if ThePlayer.intArmour > 0 then
    Writeln(DumpFile, 'Armour      : ' + Thing[ThePlayer.intArmour].strName + chr(9) + 'WP/GP/AP: ' + IntToStr(Thing[ThePlayer.intArmour].intWP) + '/' + IntToStr(Thing[ThePlayer.intArmour].intGP) + '/' + IntToStr(Thing[ThePlayer.intArmour].intAP));
  if ThePlayer.intHat > 0 then
    Writeln(DumpFile, 'Head        : ' + Thing[ThePlayer.intHat].strName + chr(9) + 'WP/GP/AP: ' + IntToStr(Thing[ThePlayer.intHat].intWP) + '/' + IntToStr(Thing[ThePlayer.intHat].intGP) + '/' + IntToStr(Thing[ThePlayer.intHat].intAP));
  if ThePlayer.intExtra > 0 then
    Writeln(DumpFile, 'Shield/Extra: ' + Thing[ThePlayer.intExtra].strName + chr(9) + 'WP/GP/AP: ' + IntToStr(Thing[ThePlayer.intExtra].intWP) + '/' + IntToStr(Thing[ThePlayer.intExtra].intGP) + '/' + IntToStr(Thing[ThePlayer.intExtra].intAP));
  if ThePlayer.intFeet > 0 then
    Writeln(DumpFile, 'Shoes       : ' + Thing[ThePlayer.intFeet].strName + chr(9) + 'WP/GP/AP: ' + IntToStr(Thing[ThePlayer.intFeet].intWP) + '/' + IntToStr(Thing[ThePlayer.intFeet].intGP) + '/' + IntToStr(Thing[ThePlayer.intFeet].intAP));
  if ThePlayer.intRingLeft > 0 then
    Writeln(DumpFile, 'Ring (left) : ' + Thing[ThePlayer.intRingLeft].strName + chr(9) + 'WP/GP/AP: ' + IntToStr(Thing[ThePlayer.intRingLeft].intWP) + '/' + IntToStr(Thing[ThePlayer.intRingLeft].intGP) + '/' + IntToStr(Thing[ThePlayer.intRingLeft].intAP));
  if ThePlayer.intRingRight > 0 then
    Writeln(DumpFile, 'Ring (right): ' + Thing[ThePlayer.intRingRight].strName + chr(9) + 'WP/GP/AP: ' + IntToStr(Thing[ThePlayer.intRingRight].intWP) + '/' + IntToStr(Thing[ThePlayer.intRingRight].intGP) + '/' + IntToStr(Thing[ThePlayer.intRingRight].intAP));



  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, 'Inventory:');
  WriteLn(DumpFile, '----------');

  WriteLn(DumpFile, 'Credits: ' + IntToStr(ThePlayer.longGold));
  WriteLn(DumpFile, ' ');
  for i := 1 to 16 do
  begin
    equi := '';
    if inventory[i].intType > 0 then
    begin
      WriteLn(DumpFile, Thing[inventory[i].intType].strRealName +
        ' x' + IntToStr(Inventory[i].longNumber));
    end;
  end;

  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, ' ');

  WriteLn(DumpFile, 'Monsters killed:');
  WriteLn(DumpFile, '----------------');
  WriteLn(DumpFile, ' ');
  for i := 1 to MonsterTemplates do
    if ThePlayer.longKilled[i] > 0 then
      WriteLn(DumpFile, IntToStr(ThePlayer.longKilled[i]) + ' ' +
        MonTe[i].strName + '(s)');

  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, ' ');

  WriteLn(DumpFile, 'Last Messages:');
  WriteLn(DumpFile, '--------------');
  WriteLn(DumpFile, ' ');
  for i := 1 to 20 do
    if strMessageLog[i] <> '-' then
      WriteLn(DumpFile, strMessageLog[i]);

  WriteLn(DumpFile, ' ');
  WriteLn(DumpFile, ' ');

  WriteLn(DumpFile, 'Achievements:');
  WriteLn(DumpFile, '-------------');
  WriteLn(DumpFile, ' ');
  for i := 1 to intAchieved do
    if Achievements[i] <> '-' then
      WriteLn(DumpFile, Achievements[i]);


  Close(DumpFile);

  GetKeyInput('A character dump has been created as /saves/' +
    ThePlayer.strName + '-dump.txt.', True);
end;

procedure LoadGame(charname: string);
var
  SaveFile: Textfile;
  i, j, icc:  integer;
  n: longint;
  savever:  string;
begin

  Assign(SaveFile, CONST_DATADIR + 'saves/' + charname + '.lambdarogue');
  Reset(SaveFile);

  // load dungeon
  ReadLn(SaveFile, savever);

  // display mode
  ReadLn(SaveFile, ThePlayer.intTileset);

  // game mode
  ReadLn(SaveFile, n);
  if n = 1 then
    ThePlayer.blCoffeebreak := True
  else
    ThePlayer.blCoffeeBreak := False;

  // number of saves
  ReadLn(SaveFile, ThePlayer.longLifeIns);

  ReadLn(SaveFile, DungeonLevel);
  for i := 1 to 100 do
  begin
    for j := 1 to 100 do
    begin
      with DngLvl[i, j] do
      begin
        ReadLn(SaveFile, intFloorType);
        ReadLn(SaveFile, intAirType);
        ReadLn(SaveFile, intAirRange);
        ReadLn(SaveFile, intIntegrity);
        ReadLn(SaveFile, intLight);
        ReadLn(SaveFile, intItem);
        ReadLn(SaveFile, intBuilding);
        ReadLn(SaveFile, n);
        if n = 1 then
          blKnown := True
        else
          blKnown := False;
        ReadLn(SaveFile, n);
        if n = 1 then
          blTown := True
        else
          blTown := False;
      end;
    end;
  end;

  // load traders
  for i := 1 to 8 do
  begin
    ReadLn(SaveFile, MyShop[i].intType);
    for j := 1 to 16 do
      ReadLn(SaveFile, MyShop[i].Inventory[j].intType);
  end;


  // load NPCs
  for i := 1 to 9 do
  begin
    ReadLn(SaveFile, NPC[i].intX);
    ReadLn(SaveFile, NPC[i].intY);
  end;

  // load hive status
  for i := 1 to 30 do
    ReadLn(SaveFile, intNoHivesAnymore[i]);

  // load achievements
  ReadLn(SaveFile, intAchieved);
  for i := 1 to 500 do
    ReadLn(SaveFile, Achievements[i]);

  // load quest info
  for i := 1 to WinLevel do
    for j := 1 to 9 do
    begin
      ReadLn(SaveFile, ThePlayer.intQuestState[i, j]);
      ReadLn(SaveFile, ThePlayer.intQuestHunt[i, j]);
    end;

  // load plot info
  for i := 1 to 80 do
  begin
    ReadLn(SaveFile, n);
    if n = 1 then
      ThePlayer.blStory[i] := True
    else
      ThePlayer.blStory[i] := False;
  end;

  // load diplomas
  for i := 1 to 30 do
    ReadLn(SaveFile, ThePlayer.intDipl[i]);

  // load temporary resistances
  for i := 1 to 100 do
    ReadLn(SaveFile, ThePlayer.intTempResist[i]);

  // load resources
  Readln(SaveFile, Storage.longWood);
  Readln(SaveFile, Storage.longMetal);
  Readln(SaveFile, Storage.longStone);
  Readln(SaveFile, Storage.longLeather);
  Readln(SaveFile, Storage.longPlastics);
  Readln(SaveFile, Storage.longPaper);


  // load time and day
  ReadLn(SaveFile, intDayTime);
  ReadLn(SaveFile, intDay);
  ReadLn(SaveFile, longYear);

  // quickbar position
  ReadLn(SaveFile, ChantBarX);
  ReadLn(SaveFile, ChantBarY);

  // load player
  with ThePlayer do
  begin
    ReadLn(SaveFile, strName);
    ReadLn(SaveFile, strVita);
    ReadLn(SaveFile, strDescription);
    ReadLn(SaveFile, longTotalTurns);
    ReadLn(SaveFile, longSkillPoints);
    ReadLn(SaveFile, intMaxHP);
    ReadLn(SaveFile, intHP);
    ReadLn(SaveFile, intMaxHP);
    ReadLn(SaveFile, intStrength);
    ReadLn(SaveFile, intLastSong);
    ReadLn(SaveFile, longExp);
    ReadLn(SaveFile, longThisLevelExp);
    ReadLn(SaveFile, intLvl);
    ReadLn(SaveFile, longGold);
    ReadLn(SaveFile, longScore);
    ReadLn(SaveFile, intX);
    ReadLn(SaveFile, intY);
    ReadLn(SaveFile, intSex);
    ReadLn(SaveFile, intPP);
    ReadLn(SaveFile, intMaxPP);
    ReadLn(SaveFile, longFood);
    ReadLn(SaveFile, intBX);
    ReadLn(SaveFile, intBY);
    ReadLn(SaveFile, strReli);
    ReadLn(SaveFile, UnX);
    ReadLn(SaveFile, UnY);
    ReadLn(SaveFile, intReli);
    ReadLn(SaveFile, intProf);
    ReadLn(SaveFile, intFight);
    ReadLn(SaveFile, intMove);
    ReadLn(SaveFile, intChant);
    ReadLn(SaveFile, intView);
    ReadLn(SaveFile, intBurgle);
    ReadLn(SaveFile, intSword);
    ReadLn(SaveFile, intAxe);
    ReadLn(SaveFile, intWhip);
    ReadLn(SaveFile, intGun);
    ReadLn(SaveFile, intTool);
    ReadLn(SaveFile, intHumility);
    ReadLn(SaveFile, intTrade);
    ReadLn(SaveFile, intWeapon);
    ReadLn(SaveFile, intArmour);
    ReadLn(SaveFile, intHat);
    ReadLn(SaveFile, intFeet);
    ReadLn(SaveFile, intExtra);
    ReadLn(SaveFile, intRingLeft);
    ReadLn(SaveFile, intRingRight);
    ReadLn(SaveFile, intPoison);
    ReadLn(SaveFile, intConfusion);
    ReadLn(SaveFile, intInvis);
    ReadLn(SaveFile, intBlind);
    ReadLn(SaveFile, intSleep);
    ReadLn(SaveFile, intWall);
    ReadLn(SaveFile, longPrayers);
    ReadLn(SaveFile, intPara);
    ReadLn(SaveFile, intCalm);
    ReadLn(SaveFile, longContCleared);
    ReadLn(SaveFile, intTotalVitari);
    ReadLn(SaveFile, intNextVitari);
    ReadLn(SaveFile, intNeedVitari);
    ReadLn(SaveFile, DownX);
    ReadLn(SaveFile, DownY);
    ReadLn(SaveFile, UpX);
    ReadLn(SaveFile, UpY);
    ReadLn(SaveFile, HiveX);
    ReadLn(SaveFile, HiveY);
    ReadLn(SaveFile, DiffLevel);
    ReadLn(SaveFile, LastSong);
    ReadLn(SaveFile, intLimit);
    ReadLn(SaveFile, n);
    if n = 0 then
      blCursed := False
    else
      blCursed := True;
    ReadLn(SaveFile, n);
    if n = 0 then
      blBlessed := False
    else
      blBlessed := True;
    ReadLn(SaveFile, n);
    if n = 0 then
      blEvil := False
    else
      blEvil := True;
  end;

  // load killed monsters
  for i := 1 to 200 do
    ReadLn(SaveFile, ThePlayer.longKilled[i]);

  // load level visits
  for i := 1 to WinLevel do
    ReadLn(SaveFile, ThePlayer.longLevelVisits[i]);

  // load inventory
  for i := 1 to 16 do
    with inventory[i] do
    begin
      ReadLn(SaveFile, intType);
      ReadLn(SaveFile, longNumber);
    end;

  // load songbook
  for i := 1 to 12 do
  begin
    with spellbook[i] do
    begin
      ReadLn(SaveFile, intType);
      ReadLn(SaveFile, intKnown);
      ReadLn(SaveFile, intRefresh);
    end;
    ReadLn(SaveFile, strQuickKey[i]);
  end;


  // load memory of killed unique monsters
  for i := 1 to 200 do
  begin
    ReadLn(SaveFile, n);
    if n = 0 then
      ThePlayer.blUnKilled[i] := False
    else
      ThePlayer.blUnKilled[i] := True;
  end;

  // load memory of identified items
  //writeln('save version: ' + savever);
  if (savever = '1.6.1') then
  begin
    icc:=391;  // all items of 1.6.1 minus the 5 that were added in 1.6.1-X
  end
  else
    ReadLn(SaveFile, icc);

  for i := 1 to icc do
  begin
    ReadLn(SaveFile, n);
    if n = 0 then
      Thing[i].blIdentified := False
    else
    begin
      Thing[i].blIdentified := True;
      Thing[i].strName      := Thing[i].strRealName;
    end;
  end;

  // load level of birth
  ReadLn(SaveFile, ThePlayer.intBirthLevel);  // dungeon level of birth --> move-bonus
  ReadLn(SaveFile, ThePlayer.intRelParents);  // 1: good; 2 : bad
  ReadLn(SaveFile, ThePlayer.intEventLevel);  // dungeon level of important event of childhood (depending on RelParents)

  // load crafting items  (das ueberschreibt die am Spielstart erstellten Crafting-Items)
  for i:=ItemCount-20 to ItemCount do
  begin
    with Thing[i] do
    begin
      ReadLn(SaveFile, n);
      if n=0 then
        blWear:=false
      else
        blWear:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blWield:=false
      else
        blWield:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blEat:=false
      else
        blEat:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blDrink:=false
      else
        blDrink:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blThrow:=false
      else
        blThrow:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blShoot:=false
      else
        blShoot:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blUnique:=false
      else
        blUnique:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blRare:=false
      else
        blRare:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blShopOnly:=false
      else
        blShopOnly:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blSacrifice:=false
      else
        blSacrifice:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blHat:=false
      else
        blHat:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blRing:=false
      else
        blRing:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blTwoHands:=false
      else
        blTwoHands:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blExtra:=false
      else
        blExtra:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blShoes:=false
      else
        blShoes:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blBarricade:=false
      else
        blBarricade:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blTrap:=false
      else
        blTrap:=true;

      ReadLn(SaveFile, n);
      if n=0 then
        blIdentified:=false
      else
        blIdentified:=true;


      ReadLn(SaveFile, intNeedsAmmu);
      ReadLn(SaveFile, intIsAmmu);
      ReadLn(SaveFile, intSP);
      ReadLn(SaveFile, intWP);
      ReadLn(SaveFile, intGP);
      ReadLn(SaveFile, intWP);
      ReadLn(SaveFile, intAP);
      ReadLn(SaveFile, intProf);
      ReadLn(SaveFile, intSex);
      ReadLn(SaveFile, intAmount);
      ReadLn(SaveFile, strDescri);

      ReadLn(SaveFile, n);
      chLetter := chr(n);

      ReadLn(SaveFile, strLearnChant);
      ReadLn(SaveFile, strTextFile);
      ReadLn(SaveFile, intEffect);
      ReadLn(SaveFile, strEfText);

      ReadLn(SaveFile, strName);
      ReadLn(SaveFile, strGenericName);
      ReadLn(SaveFile, strRealName);

      ReadLn(SaveFile, intRange);
      ReadLn(SaveFile, intMinLvl);
      ReadLn(SaveFile, intCharLvl);
      ReadLn(SaveFile, intPrice);
      ReadLn(SaveFile, intSpellID);

      ReadLn(SaveFile, intRuneSet);
      ReadLn(SaveFile, intStrength);
    end;
  end;
  //writeln('Crafting item loading done.');


  // load item recipes
  for i:=1 to WinLevel do
    if (i=1) or (i=5) or (i=10) or (i=15) then
    begin
      for j:=1 to 5 do
      begin
        ReadLn(SaveFile, ItemReceipt[i,j].strName);

        ReadLn(SaveFile, n);
        ItemReceipt[i,j].chLetter := chr(n);

        ReadLn(SaveFile, n);
        ItemReceipt[i,j].longWood := n;

        ReadLn(SaveFile, n);
        ItemReceipt[i,j].longMetal := n;

        ReadLn(SaveFile, n);
        ItemReceipt[i,j].longStone := n;

        ReadLn(SaveFile, n);
        ItemReceipt[i,j].longLeather := n;

        ReadLn(SaveFile, ItemReceipt[i,j].strItem);
      end;
    end;
    
    
  // load data available in saves >= 1.6.1
  if (savever='1.6.1') or (savever='1.6.2') or (savever='1.6.3') or (savever='1.6.4') or (savever='1.6.5') then
  begin
    ReadLn(SaveFile, n);
    if n=0 then
      ThePlayer.blQuiet:=false
    else
      ThePlayer.blQuiet:=true;

    ReadLn(SaveFile, ThePlayer.intSpecialRefresh);
    ReadLn(SaveFile, ThePlayer.intWeaponMod);
    ReadLn(SaveFile, ThePlayer.intWeaponModRange);
  end;
  
  // load data available in saves >= 1.6.2
  if (savever='1.6.2') or (savever='1.6.3') or (savever='1.6.4') or (savever='1.6.5') then
  begin
  end;
  
  // load data available in saves >= 1.6.3
  if (savever='1.6.3') or (savever='1.6.4') or (savever='1.6.5') then
  begin
    ReadLn(SaveFile, n);
    if n=0 then
      ThePlayer.blNold:=false
    else
      ThePlayer.blNold:=true;
  end;
  
  // load data available in saves >= 1.6.4
  if (savever='1.6.4') or (savever='1.6.5') then
  begin
  end;
  
  // load data available in saves >= 1.6.5
  if (savever='1.6.5') then
  begin
  end;  

  Close(SaveFile);

  ClearScreenSDL;

  if UseSDL = True then
    BlitImage_Title;

  if savever<> strVersion then
    GetKeyInput ('The loaded save is from version '+savever+'; it will be converted to '+strVersion+'.', false);

end;

procedure SaveGame(charname: string; lvl: integer);
var
  SaveFile: Textfile;
  i, j:     integer;
begin

  Assign(SaveFile, CONST_DATADIR + 'saves/' + charname + '.lambdarogue');
  Rewrite(SaveFile);
  WriteLn(SaveFile, strVersion);

  // display mode
  WriteLn(SaveFile, IntToStr(ThePlayer.intTileset));

  // game mode
  if ThePlayer.blCoffeebreak = True then
    WriteLn(SaveFile, '1')
  else
    WriteLn(SaveFile, '0');

  // number of saves
  WriteLn(SaveFile, IntToStr(ThePlayer.longLifeIns));

  // save dungeon
  WriteLn(SaveFile, IntToStr(lvl));
  for i := 1 to 100 do
  begin
    for j := 1 to 100 do
    begin
      with DngLvl[i, j] do
      begin
        WriteLn(SaveFile, IntToStr(intFloorType));
        WriteLn(SaveFile, IntToStr(intAirType));
        WriteLn(SaveFile, IntToStr(intAirRange));
        WriteLn(SaveFile, IntToStr(intIntegrity));
        WriteLn(SaveFile, IntToStr(intLight));
        WriteLn(SaveFile, IntToStr(intItem));
        WriteLn(SaveFile, IntToStr(intBuilding));
        if blKnown = True then
          WriteLn(SaveFile, '1')
        else
          WriteLn(SaveFile, '0');
        if blTown = True then
          WriteLn(SaveFile, '1')
        else
          WriteLn(SaveFile, '0');

      end;
    end;
  end;

  // save traders
  for i := 1 to 8 do
  begin
    WriteLn(SaveFile, IntToStr(MyShop[i].intType));
    for j := 1 to 16 do
      WriteLn(SaveFile, IntToStr(MyShop[i].Inventory[j].intType));
  end;

  // save NPCs
  for i := 1 to 9 do
  begin
    WriteLn(SaveFile, IntToStr(NPC[i].intX));
    WriteLn(SaveFile, IntToStr(NPC[i].intY));
  end;

  // save hive status
  for i := 1 to 30 do
    WriteLn(SaveFile, IntToStr(intNoHivesAnymore[i]));

  // save achievements
  WriteLn(SaveFile, IntToStr(intAchieved));
  for i := 1 to 500 do
    WriteLn(SaveFile, Achievements[i]);

  // save quest info
  for i := 1 to WinLevel do
    for j := 1 to 9 do
    begin
      Writeln(SaveFile, IntToStr(ThePlayer.intQuestState[i, j]));
      Writeln(SaveFile, IntToStr(ThePlayer.intQuestHunt[i, j]));
    end;

  // save plot info
  for i := 1 to 80 do
    if ThePlayer.blStory[i] = True then
      WriteLn(SaveFile, '1')
    else
      WriteLn(SaveFile, '0');

  // save diplomas
  for i := 1 to 30 do
    WriteLn(SaveFile, IntToStr(ThePlayer.intDipl[i]));

  // save current temporary resistances
  for i := 1 to 100 do
    WriteLn(SaveFile, IntToStr(ThePlayer.intTempResist[i]));

  // save ressources
  Writeln(SaveFile, IntToStr(Storage.longWood));
  Writeln(SaveFile, IntToStr(Storage.longMetal));
  Writeln(SaveFile, IntToStr(Storage.longStone));
  Writeln(SaveFile, IntToStr(Storage.longLeather));
  Writeln(SaveFile, IntToStr(Storage.longPlastics));
  Writeln(SaveFile, IntToStr(Storage.longPaper));

  // save time and day
  WriteLn(SaveFile, IntToStr(intDayTime));
  WriteLn(SaveFile, IntToStr(intDay));
  WriteLn(SaveFile, IntToStr(longYear));

  // save quickbar position
  WriteLn(SaveFile, IntToStr(ChantBarX));
  WriteLn(SaveFile, IntToStr(ChantBarY));

  // save player
  with ThePlayer do
  begin
    WriteLn(SaveFile, strName);
    WriteLn(SaveFile, strVita);
    WriteLn(SaveFile, strDescription);
    WriteLn(SaveFile, IntToStr(longTotalTurns));
    WriteLn(SaveFile, IntToStr(longSkillPoints));
    WriteLn(SaveFile, IntToStr(intMaxHP));
    WriteLn(SaveFile, IntToStr(intHP));
    WriteLn(SaveFile, IntToStr(intMaxHP));
    WriteLn(SaveFile, IntToStr(intStrength));
    WriteLn(SaveFile, IntToStr(intLastSong));
    WriteLn(SaveFile, IntToStr(longExp));
    WriteLn(SaveFile, IntToStr(longThisLevelExp));
    WriteLn(SaveFile, IntToStr(intLvl));
    WriteLn(SaveFile, IntToStr(longGold));
    WriteLn(SaveFile, IntToStr(longScore));
    WriteLn(SaveFile, IntToStr(intX));
    WriteLn(SaveFile, IntToStr(intY));
    WriteLn(SaveFile, IntToStr(intSex));
    WriteLn(SaveFile, IntToStr(intPP));
    WriteLn(SaveFile, IntToStr(intMaxPP));
    WriteLn(SaveFile, IntToStr(longFood));
    WriteLn(SaveFile, IntToStr(intBX));
    WriteLn(SaveFile, IntToStr(intBY));
    WriteLn(SaveFile, strReli);
    WriteLn(SaveFile, IntToStr(UnX));
    WriteLn(SaveFile, IntToStr(UnY));
    WriteLn(SaveFile, IntToStr(intReli));
    WriteLn(SaveFile, IntToStr(intProf));
    WriteLn(SaveFile, IntToStr(intFight));
    WriteLn(SaveFile, IntToStr(intMove));
    WriteLn(SaveFile, IntToStr(intChant));
    WriteLn(SaveFile, IntToStr(intView));
    WriteLn(SaveFile, IntToStr(intBurgle));
    WriteLn(SaveFile, IntToStr(intSword));
    WriteLn(SaveFile, IntToStr(intAxe));
    WriteLn(SaveFile, IntToStr(intWhip));
    WriteLn(SaveFile, IntToStr(intGun));
    WriteLn(SaveFile, IntToStr(intTool));
    WriteLn(SaveFile, IntToStr(intHumility));
    WriteLn(SaveFile, IntToStr(intTrade));
    WriteLn(SaveFile, IntToStr(intWeapon));
    WriteLn(SaveFile, IntToStr(intArmour));
    WriteLn(SaveFile, IntToStr(intHat));
    WriteLn(SaveFile, IntToStr(intFeet));
    WriteLn(SaveFile, IntToStr(intExtra));
    WriteLn(SaveFile, IntToStr(intRingLeft));
    WriteLn(SaveFile, IntToStr(intRingRight));
    WriteLn(SaveFile, IntToStr(intPoison));
    WriteLn(SaveFile, IntToStr(intConfusion));
    WriteLn(SaveFile, IntToStr(intInvis));
    WriteLn(SaveFile, IntToStr(intBlind));
    WriteLn(SaveFile, IntToStr(intSleep));
    WriteLn(SaveFile, IntToStr(intWall));
    WriteLn(SaveFile, IntToStr(longPrayers));
    WriteLn(SaveFile, IntToStr(intPara));
    WriteLn(SaveFile, IntToStr(intCalm));
    WriteLn(SaveFile, IntToStr(longContCleared));
    WriteLn(SaveFile, IntToStr(intTotalVitari));
    WriteLn(SaveFile, IntToStr(intNextVitari));
    WriteLn(SaveFile, IntToStr(intNeedVitari));
    WriteLn(SaveFile, IntToStr(DownX));
    WriteLn(SaveFile, IntToStr(DownY));
    WriteLn(SaveFile, IntToStr(UpX));
    WriteLn(SaveFile, IntToStr(UpY));
    WriteLn(SaveFile, IntToStr(HiveX));
    WriteLn(SaveFile, IntToStr(HiveY));
    WriteLn(SaveFile, IntToStr(DiffLevel));
    WriteLn(SaveFile, IntToStr(LastSong));
    WriteLn(SaveFile, IntToStr(intLimit));
    if blCursed = True then
      WriteLn(SaveFile, '1')
    else
      WriteLn(SaveFile, '0');
    if blBlessed = True then
      WriteLn(SaveFile, '1')
    else
      WriteLn(SaveFile, '0');
    if blEvil = True then
      WriteLn(SaveFile, '1')
    else
      WriteLn(SaveFile, '0');
  end;

  // save killed monsters
  for i := 1 to 200 do
    WriteLn(SaveFile, IntToStr(ThePlayer.longKilled[i]));

  // save level visits
  for i := 1 to WinLevel do
    WriteLn(SaveFile, IntToStr(ThePlayer.longLevelVisits[i]));

  // save inventory
  for i := 1 to 16 do
    with inventory[i] do
    begin
      WriteLn(SaveFile, intType);
      WriteLn(SaveFile, longNumber);
    end;


  // save songbook and quickkeys
  for i := 1 to 12 do
  begin
    with spellbook[i] do
    begin
      WriteLn(SaveFile, intType);
      WriteLn(SaveFile, intKnown);
      WriteLn(SaveFile, intRefresh);
    end;
    WriteLn(SaveFile, strQuickKey[i]);
  end;

  // save memory of killed unique monsters
  for i := 1 to 200 do
    if ThePlayer.blUnKilled[i] = True then
      WriteLn(SaveFile, '1')
    else
      WriteLn(SaveFile, '0');

  // save memory of identified items

  writeln(SaveFile, ItemCount);

  for i := 1 to ItemCount do
    if Thing[i].blIdentified = True then
      WriteLn(SaveFile, '1')
    else
      WriteLn(SaveFile, '0');

  // save level of birth
  WriteLn(SaveFile, ThePlayer.intBirthLevel);
  WriteLn(SaveFile, ThePlayer.intRelParents);
  WriteLn(SaveFile, ThePlayer.intEventLevel);


  // save crafting items
  for i:=ItemCount-20 to ItemCount do
  begin
    with Thing[i] do
    begin
      if blWear = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blWield = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blEat = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blDrink = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blThrow = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blShoot = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blUnique = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blRare = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blShopOnly = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blSacrifice = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blHat = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blRing = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blTwoHands = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blExtra = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blShoes = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blBarricade = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blTrap = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      if blIdentified = True then
        WriteLn(SaveFile, '1')
      else
        WriteLn(SaveFile, '0');

      WriteLn(SaveFile, intNeedsAmmu);
      WriteLn(SaveFile, intIsAmmu);
      WriteLn(SaveFile, intSP);
      WriteLn(SaveFile, intWP);
      WriteLn(SaveFile, intGP);
      WriteLn(SaveFile, intWP);
      WriteLn(SaveFile, intAP);
      WriteLn(SaveFile, intProf);
      WriteLn(SaveFile, intSex);
      WriteLn(SaveFile, intAmount);
      WriteLn(SaveFile, strDescri);

      WriteLn(SaveFile, ord(chLetter));

      WriteLn(SaveFile, strLearnChant);
      WriteLn(SaveFile, strTextFile);
      WriteLn(SaveFile, intEffect);
      WriteLn(SaveFile, strEfText);

      WriteLn(SaveFile, strName);
      WriteLn(SaveFile, strGenericName);
      WriteLn(SaveFile, strRealName);

      WriteLn(SaveFile, intRange);
      WriteLn(SaveFile, intMinLvl);
      WriteLn(SaveFile, intCharLvl);
      WriteLn(SaveFile, intPrice);
      WriteLn(SaveFile, intSpellID);

      WriteLn(SaveFile, intRuneSet);
      WriteLn(SaveFile, intStrength);
    end;
  end;

  // save item recipes
  for i:=1 to WinLevel do
    if (i=1) or (i=5) or (i=10) or (i=15) then
    begin
      for j:=1 to 5 do
      begin
        WriteLn(SaveFile, ItemReceipt[i,j].strName);
        WriteLn(SaveFile, ord(ItemReceipt[i,j].chLetter));
        WriteLn(SaveFile, ItemReceipt[i,j].longWood);
        WriteLn(SaveFile, ItemReceipt[i,j].longMetal);
        WriteLn(SaveFile, ItemReceipt[i,j].longStone);
        WriteLn(SaveFile, ItemReceipt[i,j].longLeather);
        WriteLn(SaveFile, ItemReceipt[i,j].strItem);
      end;
    end;  
    
  // save data new in 1.6.1
  if ThePlayer.blQuiet = True then
    WriteLn(SaveFile, '1')
  else
    WriteLn(SaveFile, '0');

  WriteLn(SaveFile, ThePlayer.intSpecialRefresh);
  WriteLn(SaveFile, ThePlayer.intWeaponMod);
  WriteLn(SaveFile, ThePlayer.intWeaponModRange);

  // save data new in 1.6.2
  
  // save data new in 1.6.3

  if ThePlayer.blNold = true then
    WriteLn(SaveFile, '1')
  else
    WriteLn(SaveFile, '0');

  // save data new in 1.6.4
  
  // save data new in 1.6.5

  Close(SaveFile);
end;


procedure SaveItemTables;
var
  ItemFile: textfile;
  i: integer;
  tstr: string;
begin
  // save a table with all standard items
  Assign (ItemFile, CONST_DATADIR + 'docs/all-standard-items.csv');
  Rewrite (ItemFile);
  writeln(ItemFile, 'Name;Wield;Wear;Eat;Drink;WP;GP;AP;DLV;CLV;Credits;Effect;Effectrange');
  for i:=1 to ItemCount do
  begin
    tstr := Thing[i].strRealName + ';' + BoolString(Thing[i].blWield, 1) + ';' + BoolString(Thing[i].blWear, 1) + ';' + BoolString(Thing[i].blEat, 1) + ';'
      + BoolString(Thing[i].blDrink, 1) + ';' + IntToStr(Thing[i].intWP) + ';' + IntToStr(Thing[i].intGP) + ';' +
      IntToStr(Thing[i].intAP) + ';' + IntToStr(Thing[i].intMinLvl) + ';' + IntToStr(Thing[i].intCharLvl) + ';' +
      IntToStr(Thing[i].intPrice) + ';' + GetEffectDescription(Thing[i].intEffect) + ';' + IntToStr(Thing[i].intRange);

    if (Thing[i].blRare=false) and (Thing[i].blUnique=false) then
      writeln(ItemFile, tstr);
  end;
  Close (ItemFile);

  // save a table with all rare items
  Assign (ItemFile, CONST_DATADIR + 'docs/all-rare-items.csv');
  Rewrite (ItemFile);
  writeln(ItemFile, 'Name;Wield;Wear;Eat;Drink;WP;GP;AP;DLV;CLV;Credits;Effect;Effectrange');
  for i:=1 to ItemCount do
  begin
    tstr := Thing[i].strRealName + ';' + BoolString(Thing[i].blWield, 1) + ';' + BoolString(Thing[i].blWear, 1) + ';' + BoolString(Thing[i].blEat, 1) + ';'
      + BoolString(Thing[i].blDrink, 1) + ';' + IntToStr(Thing[i].intWP) + ';' + IntToStr(Thing[i].intGP) + ';' +
      IntToStr(Thing[i].intAP) + ';' + IntToStr(Thing[i].intMinLvl) + ';' + IntToStr(Thing[i].intCharLvl) + ';' +
      IntToStr(Thing[i].intPrice) + ';' + GetEffectDescription(Thing[i].intEffect) + ';' + IntToStr(Thing[i].intRange);

    if Thing[i].blRare=true then
      writeln(ItemFile, tstr);
  end;
  Close (ItemFile);

  // save a table with all unique items
  Assign (ItemFile, CONST_DATADIR + 'docs/all-unique-items.csv');
  Rewrite (ItemFile);
  writeln(ItemFile, 'Name;Wield;Wear;Eat;Drink;WP;GP;AP;DLV;CLV;Credits;Effect;Effectrange');
  for i:=1 to ItemCount do
  begin
    tstr := Thing[i].strRealName + ';' + BoolString(Thing[i].blWield, 1) + ';' + BoolString(Thing[i].blWear, 1) + ';' + BoolString(Thing[i].blEat, 1) + ';'
      + BoolString(Thing[i].blDrink, 1) + ';' + IntToStr(Thing[i].intWP) + ';' + IntToStr(Thing[i].intGP) + ';' +
      IntToStr(Thing[i].intAP) + ';' + IntToStr(Thing[i].intMinLvl) + ';' + IntToStr(Thing[i].intCharLvl) + ';' +
      IntToStr(Thing[i].intPrice) + ';' + GetEffectDescription(Thing[i].intEffect) + ';' + IntToStr(Thing[i].intRange);

    if Thing[i].blUnique=true then
      writeln(ItemFile, tstr);
  end;
  Close (ItemFile);
end;


procedure SaveMonsterTables;
var
  MonsterFile: textfile;
  i: integer;
  tstr: string;
begin
  Assign (MonsterFile, CONST_DATADIR + 'docs/all-monsters.csv');
  Rewrite (MonsterFile);
  writeln(MonsterFile, 'Name;Unique;HP;PP;WP;GP;AP;DLV;EXP;Credits');
  for i:=1 to MonsterTemplates do
  begin
    tstr := MonTe[i].strName + ';' + BoolString(MonTe[i].blUnique, 1) + ';' + IntToStr(MonTe[i].intMaxHP) + ';'
      + IntToStr(MonTe[i].intMaxPP) + ';' + IntToStr(MonTe[i].intWP) + ';' + IntToStr(MonTe[i].intGP) + ';'
      + IntToStr(MonTe[i].intAP) + ';' + IntToStr(MonTe[i].intLvl) + ';' + IntToStr(MonTe[i].longEXP) + ';'
      + IntToStr(MonTe[i].longGold);
    writeln(MonsterFile, tstr);
  end;
  Close (MonsterFile);
end;


procedure SaveChantTables;
var
  ItemFile: textfile;
  i: integer;
  tstr: string;
begin
  // save a table with all chants
  Assign (ItemFile, CONST_DATADIR + 'docs/all-chants.csv');
  Rewrite (ItemFile);
  writeln(ItemFile, 'Name;PP;Effect;Range;Refresh;CLV');
  for i:=1 to ChantCount do
  begin
    tstr := Spell[i].strName + ';' + IntToStr(Spell[i].intPP) + ';' + GetEffectDescription(Spell[i].intEffect)
             + ';' + IntToStr(Spell[i].intRange) + ';' + IntToStr(Spell[i].intRefresh) + ';' + IntToStr(Spell[i].intCharLvl);
    writeln(ItemFile, tstr);
  end;
  Close (ItemFile);
end;


end.
