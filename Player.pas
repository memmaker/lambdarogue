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


// contains types, variables and procedures to initialize player and monsters
unit Player;


interface

uses
  SysUtils, StrUtils, RandomArea, BaseOutput, GFX, MessageLog, WebBE;

type
  CharaClass = record
    strName:   string;            // name of class (e.g. "Ares")
    intFight:  integer;           // main ability "fight"
    intMove:   integer;           // main ability "move"
    intChant:  integer;           // main ability "chant"
    intView:   integer;           // main ability "view"
    intBurgle: integer;           // main ability "code"
    intTool:   integer;           // main ability "tool"
    afSkill:   string;            // the related skill
    afStat:    string;            // the related status value
  end;


type
  Creature = record            // prototype to store information about player and monsters
    strName: string;

    blCoffeeBreak: boolean;    // in coffeebreak mode (true), no quests and NPCs are available and
                               // the game is won by killing Eris in the 20th dungeon level

    // player and monster-relevant
    intHP:      integer;            // current health
    intMaxHP:   integer;        // max. health
    intPP:      integer;            // current psychic power
    intMaxPP:   integer;        // max. psychic power
    longExp, longThisLevelEXP:    longint;
    // player: experience. monster: how many exp. is a kill worth?
    intLvl:     longint;
    // player: character level. monster: dungeonlevel on which monster first appears
    longGold:   longint;
    // player: credits. monster: how many credits is a kill worth?
    intX, intY: integer;        // position in dungeon
    intStrength: integer;        // strength
    longScore:  longint;        // total score
    intMove:    integer;        // main ability "move"

    blOffensive: boolean;
    // true: normal; false: defensive (less damage taken, less damage dealt)

    // only player-relevant
    blQuiet: boolean; // player will never be able to cast magic
    blDead:  boolean; // game over screen already shown
    blEvil:  boolean;
    // player is very bad; happens when Sword "Northdoom" equipped or humility < -5
    intDipl: array[1..30] of integer; // diplomas; 1: gained
    intQuestState: array[1..27, 1..9] of integer;  // quest state (dlvl, npc)
    intQuestHunt: array[1..27, 1..9] of integer;

    intBirthLevel: integer;
    intRelParents: integer;
    intEventLevel: integer;

    blNold : boolean; // Portal through Noldarur created

    // amount of creatures to hunt for all level)
    longSkillPoints: longint;    // collected:skill points
    intSex:      integer;        // male, female or neuter
    longFood:    longint;        // food of player (0: death)
    intBX, intBY: integer;        // screen position of player (80x25 grid)
    strReli:     string;        // name of player's religion
    intReli:     integer;        // ID of player's religion
    intProf:     integer;        // ID of player's profession
    strVita:     string;        // short vita
    strDescription: string;        // appearance
    strDiploma:  string;        // additional diplomas
    longLifeIns: longint;        // number of life insurances (= saves)

    intFight:    integer;        // main ability "fight"
    intChant:    integer;        // main ability "chant"
    intView:     integer;        // main ability "view"
    intBurgle:   integer;        // main ability "steal"
    intSword:    integer;        // sec. ability "sword"
    intAxe:      integer;        // sec. ability "axe"
    intWhip:     integer;        // sec. ability "lance"
    intGun:      integer;        // sec. ability "gun"
    intTool:     integer;        // sec. ability "tool"
    intHumility: integer;        // sec. ability "humility"
    intTrade:    integer;        // sec. ability "trade"


    intWeapon:   integer;         // item used as weapon
    intWeaponMod: integer;        // one-time modifier for current weapon; reset to 0 when weapon removed
    intWeaponModRange: integer;

    intArmour:   integer;         // item used as armour
    intHat:      integer;         // item used as hat
    intRingLeft: integer;         // item used as ring on left hand
    intRingRight: integer;        // item used as ring on right hand
    intExtra:    integer;         // shield or candle
    intFeet:     integer;         // shoes etc.

    intSpecialRefresh: integer;   // number of turns until special ability works again

    intPoison:    integer;        // strongness of poison
    intConfusion: integer;        // strongness of Confusion
    intInvis:     integer;        // strongness of Invisibility
    intBlind:     integer;        // strongness of Blindness
    intSleep:     integer;        // strongness of sleep
    intWall:      integer;        // strongness of wall
    longPrayers:  longint;        // how many times prayed to god
    intPara:      integer;        // strongness of paralyze
    intCalm:      integer;        // strongness of quietness
    intFreeze:    integer;        // strongness of frozen time
    blCursed:     boolean;        // cursed or not cursed?
    blBlessed:    boolean;        // blessed or not?

    intTempResist: array [1..100] of integer;
    // every element is one resistance; the number is equivalent to the effectnumbers used elsewhere;
    // the value are the remaining turns (i think normal integer should be enough ...)

    intLimit: integer;

    intTotalVitari, intNextVitari, intNeedVitari: integer;
    // addiction to Vitari (strength drung)

    blUnKilled: array [1..200] of boolean;
    // array of all unique monsters killed by the player
    longKilled: array[1..200] of longint;
    // array that stores the total number of all killed

    blStory: array [1..80] of boolean; // storys already told story parts
    longLevelVisits: array [1..30] of longint;
    // the number of visits of a dungeon level
    longContCleared: longint;    // number of cleared decontaminated tiles

    intTileset:  integer;        // tileset
    intLastSong: integer;        // the last song selected in quick songbook

    // only monster relevant
    blAttacked: boolean;
    // true: monster has been attacked at least once by the player
    intQuestS:  integer;
    // Quest that has to be solved before the monster appears
    // (the Quest level taken for this is the same as the min. DLV of the monster)
    intQuestG:  integer;      // Quest that has to be open before the monster appears
    // (the Quest level taken for this is the same as the min. DLV of the monster)

    blIntelligent: boolean;         // true: monster opens doors etc.

    blSelfHeal: boolean;            // true: Monster can heal itself
    blWeaken:   boolean;            // true: monster absorbs "str" from player
    blElect:     boolean;           // true: monster can cast electricity
    blFire:     boolean;            // true: monster can cast fire
    blIce:      boolean;            // true: monster can cast ice
    blWaterC:   boolean;            // true: monster can cast water
    blPoison:   boolean;            // true: monster can poison the player
    blConfusion: boolean;           // true: monster can confuse the player
    blBlindness: boolean;           // true: monster can make player blind
    blPara:     boolean;            // true: monster can paralyze player
    blInvis:    boolean;            // true: monster can make itself invisible
    blHitsHard: boolean;            // true: monster has a real hard attack
    blBreakDefence: boolean;        // true: monster destroys defensive mode
    blCalm:     boolean;            // true: monster can make player quit (unable to chant)
    blSummon:   boolean;            // true: monster can summon one monster
    blSplit:    boolean;            // true: monster can split itself into smaller creatures
    strSplitInto: string;           // name of monster that appears after splitting
    blTeleport: boolean;            // true: monster can teleport itself to a distant position
    intTeleport: integer;        // distance a monster teleports
    blDrainPP:  boolean;          // true: monster can drain player's PP
    intDrainPP: integer;         // max. amount PP drained by the monster
    blDrainSTR: boolean;          // true: monster can drain player's STR
    intDrainSTR: integer;         // max. amount STR drained by the monster

    blDig, blTransform: boolean;         // true: monster can transform surrounding dungeon tiles
    intTransformType: integer;    // to which dungeon type can monster transform dungeon tiles?
    intTransformInteg: integer;   // new integrity of the transformed dungeon tile
    strTransformText: string;     // text shown during transformation of the dungeon tile

    blTremble: boolean;           // true: monster can create earthquakes that damage the player
    intTrembleDmg: integer;       // damage taken by the player during earthquake

    blShout: boolean;             // true: monster can throw away player by shouting at him
    intShoutDmg: integer;         // damage taken by the player during shouting

    blUnique:   boolean;         // true: unique monster (extra strong, only 1 per level)
    blElite: boolean;            // true: unique monster is just an elite variant of standard monster

    blLastEnemy: boolean;        // true: monster is last enemy; after it's dead the game is won
    strVerb:    string;        // verb shown while attacking (e.g. "bites", "hits" etc.)
    strShootVerb: string;        // verb shown for long-range attacks
    chLetter:   char;            // ASCII-character used to represent monster on map
    chBulletLetter: char;        // ASCII-character used to represent bullet on map
    intWP:      integer;            // weapon points
    intAP:      integer;            // armour points
    intGP:      integer;         // gun points (set to 0 if monster does not use long-range combat)
    intTemplate: integer;        // used to store the number of used template
    blWater:    boolean;        // monster can move on water
    blCurse:    boolean;        // monster can curse player
    blDestWeapon: boolean;        // monster can destroy player's weapon
    blDestArmour: boolean;        // monster can destroy player's armour
    intType:    integer;        // ID
    blHuman:    boolean;        // true: monster normally does not attack; once the player attacks, it gets false
    intHitRate: integer;        // hit rate of shots (0: every shot hits, 400: nothing hits)
    intKillPlot: integer;       // plot that is shown after the monster has been killed the first time
  end;


var
  ThePlayer:    Creature;            // The player
  Monster:      array[1..550] of Creature;    // every monster
  MaxMonster:   longint;             // maximum number of monsters
  MonsterCount: longint;             // current number of monsters

  MonsterTemplates: integer;
  // number of available monstertemplates (for monster creation)
  MonTe: array[1..200] of Creature;    // max. 200 monster templates

  PlayClass: array[1..5] of CharaClass;
  PlayProf:  array[1..9] of string;

  Achievements: array[1..800] of string;
  // achievements like level up, new dungeon level explored, rank gained etc.
  intAchieved:  integer;  // achievement counter


procedure StoreAchievement(s: string);
function ReturnMonTeByName(s: string): integer;
function ReturnRandomMonster(n: integer): integer;
function IsPlayerDead(): boolean;
procedure IsMonsterDead(i: integer);
procedure MonsterInit;
procedure BonesInit;
procedure SaveBones;
procedure ClassInit;
procedure GameOver(reason: string);
procedure WinGame;
procedure LevelUp;


implementation

uses
  Constants, Items, Quests, Dungeon, Plot, ExternSFX, ExternMusic, DrawDungeon, Input, FileIO;

// returns a string containing lvl and id, if the given monster name is object of assassination in any quest
function IsTargetMonster(MonsterName: string): string;
var
  i, j: integer;
begin
  IsTargetMonster := 'false';
  for i := 1 to WinLevel do
    for j := 1 to 9 do
      if Quest[i, j].strTargetName = MonsterName then
        if ThePlayer.intQuestState[i, j] = 1 then
          IsTargetMonster := IntToStr(i) + ',' + IntToStr(j);
end;

procedure StoreAchievement(s: string);
begin
  if intAchieved < 800 then
  begin
    Inc(intAchieved);
    Achievements[intAchieved] :=
      IntToStr(intDayTime) + '-' + IntToStr(intDay) + '-' + IntToStr(longYear) +
      ' (turn ' + IntToStr(longTotalTurns) + '):' + chr(9) + chr(9) + s;
  end;
end;

// returns the ID of a monster template based on its name
function ReturnMonTeByName(s: string): integer;
var
  i, n: integer;
begin
  n := 0;
  i := 0;
  for i := 1 to MonsterTemplates do
    if MonTe[i].strName = s then
      n:=i;

  ReturnMonTeByName := n;
end;

// returns an ID of a monster template, chosen randomly based on its level
function ReturnRandomMonster(n: integer): integer;
var
  i: integer;
begin
  i := 0;
  repeat
    i := 1 + trunc(random(MonsterTemplates));
  until (MonTe[i].intLvl = n) and (MonTe[i].blUnique = False);
  ReturnRandomMonster := i;
end;

procedure WinGame;
var
  dummy: string;
begin

  if ThePlayer.blCoffeebreak = false then
  begin
    if ThePlayer.blEvil=true then
    begin
      PlayMusic('death.ogg');
      ShowEnding(true);
    end
    else
    begin
      PlayMusic('win.ogg');
      ShowEnding(false);
    end;

    StoreAchievement('Completed the quest for redemption successfully.');

    Inc(ThePlayer.longScore, 2000);
  end
  else
  begin
    PlayMusic('win.ogg');
    StoreAchievement('Completed the coffeebreak successfully.');
    Inc(ThePlayer.longScore, 1000);
  end;

  // DeleteFile(CONST_DATADIR + 'saves/' + ThePlayer.strName + '.lambdarogue');

  ClearScreenSDL;

  if UseSDL = True then
    LoadImage_Title('graphics/decobg.jpg');


  repeat
    if UseSDL = True then
      BlitImage_Title;

    TransTextXY(1, 1, 'CONGRATULATIONS!');

    TransTextXY(1, 4, 'Your final score is ' + IntToStr(ThePlayer.longScore) + '.');

    dummy := GetKeyInput('[d] to create a character dump, [q] to quit.', False);
  until (dummy = 'd') or (dummy = 'q') or (dummy = 'D') or (dummy = 'Q');

  if (dummy = 'd') or (dummy = 'D') then
    CharacterDump(ThePlayer.strName + ' has retired after a successful life');

end;

procedure GameOver(reason: string);
var
  dummy: string;
  i:     integer;
begin

  if ThePlayer.blDead = False then
  begin

    ThePlayer.blDead := True;

    StoreAchievement('Died before the journey could be completed.');

    PlayMusic('death.ogg');

    ClearScreenSDL;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/txtbg.jpg');
      BlitImage_Title;
    end;

    TransTextXY(1, 1, uppercase(reason) + '.');

    for i := 2 to 20 do
      if strMessageLog[i] <> '-' then
        TransTextXY(1, 1 + i, strMessageLog[i]);

    if (ThePlayer.longLifeIns = 0) or
      (fileexists(CONST_DATADIR + 'saves/' + ThePlayer.strName + '.lambdarogue') = False) then
    begin
      if fileexists(CONST_DATADIR + 'saves/' + ThePlayer.strName + '.lambdarogue') then
        DeleteFile(CONST_DATADIR + 'saves/' + ThePlayer.strName + '.lambdarogue');
      SaveBones;

      repeat

        if UseSDL = True then
          BlitImage_Title;

        TransTextXY(1, 1, uppercase(reason) + '.');

        for i := 2 to 20 do
          if strMessageLog[i] <> '-' then
            TransTextXY(1, 1 + i, strMessageLog[i]);

        dummy := GetKeyInput(
          '[d] to create a character dump, [q] to quit.', False);
      until (dummy = 'd') or (dummy = 'q') or (dummy = 'D') or (dummy = 'Q');

      if (dummy = 'd') or (dummy = 'D') then
        CharacterDump(reason);

    end
    else
      GetKeyInput('You have been knocked out, but will awake at hospital after restarting.', False);

  end;
end;


// player gained a level
procedure LevelUp;
begin
  if ThePlayer.intHP > 0 then
    if ThePlayer.intLvl < CONST_MAXCLV then
      if ThePlayer.longExp > (ThePlayer.intLvl * CONST_LVL_MULTI) * (ThePlayer.intLvl * CONST_LVL_MULTI) * ThePlayer.intLvl then
      begin
        PlaySFX('levelup.ogg');
        Inc(ThePlayer.intLvl);
        Inc(ThePlayer.intMaxHP, 1 + ((CONST_HP_MULTI * ThePlayer.intMaxHP) div 100));
        ThePlayer.intHP := ThePlayer.intMaxHP;

        if ThePlayer.blQuiet=false then
        begin
          Inc(ThePlayer.intMaxPP, 1 + ((CONST_PP_MULTI * ThePlayer.intMaxPP) div 100));
          ThePlayer.intPP := ThePlayer.intMaxPP;
        end;
        Inc(ThePlayer.longSkillPoints);
        Inc(ThePlayer.longScore, 200);
        ThePlayer.longThisLevelEXP:=0;
        ShowTransMessage('Welcome to level ' + IntToStr(ThePlayer.intLvl) + ', ' + ThePlayer.strName + '. You' + chr(39) +
          've earned 1 skill point.', False);
        StoreAchievement('Gained a character level (Now: ' + IntToStr(ThePlayer.intLvl) + ')');
        if ThePlayer.intLvl = CONST_MAXCLV then
          ShowTransMessage('You have reached the highest possible level.', False);

        // Coffeebreak Ranks
        if ThePlayer.blCoffeeBreak=true then
        begin
          if (ThePlayer.intLvl=4) or (ThePlayer.intLvl=8) or (ThePlayer.intLvl=12) or (ThePlayer.intLvl=16) or (ThePlayer.intLvl=20) then
          begin
            case ThePlayer.intProf of
              2:  // enchanter
              begin
                if ThePlayer.intLvl=4 then ThePlayer.intDipl[6]:=1;  // mage
                if ThePlayer.intLvl=8 then ThePlayer.intDipl[8]:=1;  // monk
                if ThePlayer.intLvl=12 then ThePlayer.intDipl[7]:=1; // battlemage
                if ThePlayer.intLvl=16 then ThePlayer.intDipl[9]:=1; // believer
                if ThePlayer.intLvl=20 then ThePlayer.intDipl[10]:=1; // holy warrior
                ShowTransMessage('You have been promoted.', false);
              end;
              3:  // thief
              begin
                if ThePlayer.intLvl=4 then ThePlayer.intDipl[11]:=1;  // assassin
                if ThePlayer.intLvl=8 then ThePlayer.intDipl[13]:=1;  // master thief
                if ThePlayer.intLvl=12 then ThePlayer.intDipl[12]:=1; // agent
                if ThePlayer.intLvl=16 then ThePlayer.intDipl[14]:=1; // guild leader
                if ThePlayer.intLvl<=16 then ShowTransMessage('You have been promoted.', false);
              end;
              4:  // archer
              begin
                if ThePlayer.intLvl=4 then ThePlayer.intDipl[15]:=1;  // hunter
                if ThePlayer.intLvl=8 then ThePlayer.intDipl[17]:=1;  // marksman
                if ThePlayer.intLvl=12 then ThePlayer.intDipl[16]:=1; // ranger
                if ThePlayer.intLvl=16 then ThePlayer.intDipl[18]:=1; // lieutenant
                if ThePlayer.intLvl<=16 then ShowTransMessage('You have been promoted.', false);
              end;
              5:  // soldier
              begin
                if ThePlayer.intLvl=4 then ThePlayer.intDipl[1]:=1;  // centurio
                if ThePlayer.intLvl=8 then ThePlayer.intDipl[2]:=1;  // hastatus
                if ThePlayer.intLvl=12 then ThePlayer.intDipl[3]:=1; // princeps
                if ThePlayer.intLvl=16 then ThePlayer.intDipl[4]:=1; // pilus
                if ThePlayer.intLvl=20 then ThePlayer.intDipl[5]:=1; // primus pilus
                ShowTransMessage('You have been promoted.', false);
              end;
            end;
          end;
        end;

      end;
end;

// check if the player is dead
function IsPlayerDead(): boolean;
var
  blAllRunes: boolean;
begin
  IsPlayerDead := False;
  if ThePlayer.intHP < 1 then
  begin
    ThePlayer.intHP := 0;
    IsPlayerDead    := True;
  end;
end;

// check if a monster is dead (after battle)
procedure IsMonsterDead(i: integer);
var
  longAddEXP, longAddGold: longint;
  strBaseMonsterName, dummy: string;
  lvl, npcid: integer;
begin
  if Monster[i].intHP < 1 then
  begin

    // remove blessed state, except for ares
    if (ThePlayer.intReli <> 5) and (ThePlayer.blBlessed = True) then
    begin
      ThePlayer.blBlessed := False;
      ShowTransMessage('Due to the killing, you are not longer blessed.', False);
    end;

    // draw blood...
    CreateBlood(Monster[i].intX, Monster[i].intY);

    // draw corpse
    if random(500)>480 then
      if DngLvl[Monster[i].intX, Monster[i].intY].intItem=0 then
        DngLvl[Monster[i].intX, Monster[i].intY].intItem := ReturnItemByName(Monster[i].strName + ' corpse');

    // monster loses item when enough space in dungeon and not killed SO often
    // writeln('MonTE ID: '+IntToStr(ReturnMonTeByName(Monster[i].strName))+': '+MonTe[ReturnMonTeByName(Monster[i].strName)].strName);


    // make sure that also big, strong and mighty variants of the monsters can be processed
    strBaseMonsterName := Monster[i].strName;
    if GrowingMonsters = True then
    begin
      if LeftStr(strBaseMonsterName, 4) = 'big ' then
        strBaseMonsterName :=
          RightStr(strBaseMonsterName, length(strBaseMonsterName) - 4);

      if LeftStr(strBaseMonsterName, 7) = 'strong ' then
        strBaseMonsterName :=
          RightStr(strBaseMonsterName, length(strBaseMonsterName) - 7);

      if LeftStr(strBaseMonsterName, 7) = 'mighty ' then
        strBaseMonsterName :=
          RightStr(strBaseMonsterName, length(strBaseMonsterName) - 7);
    end;

    // increase killed counter
    Inc(ThePlayer.longKilled[Monster[i].intType]);

    //writeln(MonTe[ReturnMonTeByName(strBaseMonsterName)].strName + ' killed ...');
    //writeln(IntToStr(ThePlayer.longKilled[ReturnMonTeByName(strBaseMonsterName)]) + ' times.');

    if ThePlayer.longKilled[ReturnMonTeByName(strBaseMonsterName)] < CONST_MAXKILLEDFORDROP then
      if DngLvl[Monster[i].intX, Monster[i].intY].intItem = 0 then
        if random(500) > CONST_MONSTERDROPSITEM then
          if random(500) > 150 then
            DngLvl[Monster[i].intX, Monster[i].intY].intItem := ReturnRandomItem;

    // unique monster: Items, Score and Disappear
    if Monster[i].blUnique = True then
    begin
      Inc(ThePlayer.longScore, DungeonLevel * 10);
      DngLvl[Monster[i].intX, Monster[i].intY].intItem := ReturnUniqueItem;

      //writeln ('Trying to flag monster '+IntToStr(Monster[i].intTemplate)+' as unique kill');
      ThePlayer.blUnKilled[Monster[i].intTemplate]     := True;

      StoreAchievement('Defeated ' + Monster[i].strName + '.');

      // immediatly remove all monsters if Undying King is dead
      if Monster[i].strName = 'Undying King' then
        KillAllMonsters;

      // this line allows for winning the game without need of a quest
      // however, it's more elegant to use a quest and give WinGame as reward
      //if Monster[i].blLastEnemy = True then
      //  WinGame(False);
    end;

    ShowTransMessage('You kill the ' + Monster[i].strName + '.', False);

    // hide monster object by moving out of the dungeon
    Monster[i].intX := DngMaxWidth + 10;
    Monster[i].intY := DngMaxHeight + 10;

    // show killplot file
    if Monster[i].intKillPlot > 0 then
      ShowPlot(Monster[i].intKillPlot);


    // make sure that ares characters don't get experience for killing caveworms
    if ((strBaseMonsterName = 'caveworm') or (strBaseMonsterName = 'worm mother')) and
      (ThePlayer.intReli = 5) then
    begin

      // 1st time?
      if ThePlayer.longKilled[ReturnMonTeByName('caveworm')] +
      ThePlayer.longKilled[ReturnMonTeByName('worm mother')] = 1 then
      begin

        ShowDialog('ARES',
          ThePlayer.strName +
          '! Our mind refuses to believe what Our eyes have seen. Tell Us,',
          'earthbound mortal, have you forgotten all the lessons that We have taught you?',
          'Don''t you remember Our rules, which you have sworn obedience to? Tell Us,',
          'human, is killing peaceful animals, these weak creates you call "worms",',
          'an honorable action? ' + ThePlayer.strName + ', Our heart is ashamed of you!', True);
      end;
      ShowTransMessage('Your code of conduct forbids you to kill caveworms!', False);
      longAddEXP := 0;
      ThePlayer.blBlessed := False;
    end
    else
    begin
      longAddEXP := 0;

      // make sure that characters of class 1 get less experience (how much is determined by CONST_BATTLEEXP_REDUCED)
      if ThePlayer.intReli = 1 then
        longAddEXP := ((CONST_BATTLEEXP_REDUCED * MonTe[Monster[i].intType].intHP) div 100) + Monster[i].longExp
      else
      begin
        longAddEXP := ((CONST_BATTLEEXP * MonTe[Monster[i].intType].intHP) div 100) + Monster[i].longExp;
        if CheckEffect(6) = True then
          Inc(longAddEXP, Monster[i].longExp * 2);

        // double EXP in coffeebreak
        if ThePlayer.blCoffeeBreak=true then
          longAddEXP:=longAddEXP*2;

        // reduce EXP if already many monsters killed of this type
        if ThePlayer.longKilled[ReturnMonTeByName(strBaseMonsterName)] > 25 then
          longAddEXP := (75 * longAddEXP) div 100;

        if ThePlayer.longKilled[ReturnMonTeByName(strBaseMonsterName)] > 40 then
          longAddEXP := (50 * longAddEXP) div 100;

        if ThePlayer.longKilled[ReturnMonTeByName(strBaseMonsterName)] > 50 then
          longAddEXP := (30 * longAddEXP) div 100;

        if ThePlayer.longKilled[ReturnMonTeByName(strBaseMonsterName)] > 60 then
          longAddEXP := 0;

      end;

      longAddGold := Monster[i].longGold;
      if CheckEffect(7) = True then
        Inc(longAddGold, (Monster[i].longGold div 2) + 1);

      Inc(ThePlayer.longExp, longAddEXP);
      Inc(ThePlayer.longThisLevelExp, longAddEXP);
      Inc(ThePlayer.longGold, Monster[i].longGold);
      ShowTransMessage('You get ' + IntToStr(longAddGold) + ' Credits and ' + IntToStr(longAddEXP) + ' EXP.', False);

      // has player gained a level?
      LevelUp;
    end;

    // is the killed enemy a monster that should be killed in one of the player's quests?
    dummy := IsTargetMonster(strBaseMonsterName);
    //         writeln(strBaseMonsterName+': '+dummy);
    if dummy <> 'false' then
    begin
      lvl   := StrToInt(LeftStr(dummy, NPos(',', dummy, 1) - 1));
      //npcID:=StrToInt(RightStr(dummy, NPos(',', dummy, 1)-1));
      npcID := StrToInt(RightStr(dummy, NPos(',', dummy, 1) -
        strlen(PChar(IntToStr(lvl)))));

      //             writeln('level: '+IntToStr(lvl));
      //             writeln('npcID: '+IntToStr(npcID));

      Inc(ThePlayer.intQuestHunt[lvl, npcID]);
      // increase counter of killed monsters for quest

      // show message if monsters of this type still need to be killed
      if ThePlayer.intQuestHunt[lvl, npcID] < Quest[lvl, npcID].intHuntAmount then
        ShowTransMessage('Kill ' + IntToStr(
          Quest[lvl, npcID].intHuntAmount - ThePlayer.intQuestHunt[lvl, npcID]) +
          ' more ' + strBaseMonsterName + '(s) to solve quest ' +
          IntToStr(lvl) + '/' + IntToStr(npcID) + '.', False);

      // show message if enough monsters of this type have been killed
      if ThePlayer.intQuestHunt[lvl, npcID] = Quest[lvl, npcID].intHuntAmount then
        ShowTransMessage('You have killed enough ' + strBaseMonsterName +
          's to solve quest ' + IntToStr(lvl) + '/' + IntToStr(npcID) + '.', False);
    end;

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);

  end;
end;


 // This procedure reads "data/monsters.txt" and creates monstertemplates which are
 // used by the CreateMonster-procedure in Dungeon.pp
procedure MonsterInit;
var
  MonsterFile: textfile;            // used to assign "data/monsters.txt"
  i:    integer;                // counter
  strKey, strValue: string;        // used to read key-value-pairs out of MonsterFile
  cstr: char;                // used to convert parts of string to char
begin

  for i := 1 to 200 do
  begin
    MonTe[i].blHuman   := False;
    MonTe[i].blAttacked := False;
    MonTe[i].strShootVerb := 'shoots at you';
    MonTe[i].blUnique := false;
    MonTe[i].blElite := false;
    MonTe[i].chBulletLetter := chr(160);
    MonTe[i].intHitRate := 100;    // decrease to let more shoots succeed (max. is 400)
    MonTe[i].intGP     := 0;
    MonTe[i].intMove   := 0;
    MonTe[i].intQuestS := 0;
    MonTe[i].intQuestG := 0;
    MonTe[i].intKillPlot := 0;
    MonTe[i].intMaxPP  := 4;
    MonTe[i].intPP     := MonTe[i].intMaxPP;
    MonTe[i].intPara := 0;
    MonTe[i].blIntelligent := false;
  end;

  // initialize key-value-pair
  strKey   := '';
  strValue := '';

  // open monsters.txt
  Assign(MonsterFile, CONST_DATADIR + 'data/monsters.txt');
  Reset(MonsterFile);

  // initialize counter
  i := 0;

  // as long as monsters.txt not completely read...
  while EOF(MonsterFile) = False do
  begin
    // search for key
    repeat
      ReadLn(MonsterFile, strKey);
    until ((strKey <> '') and (strKey[1] <> ' ') and (strKey[1] <> '#')) or (EOF(MonsterFile));

    // key found, now search for corresponding value
    ReadLn(MonsterFile, strValue);

    // create new monster
    if strKey = 'NewMonster:' then
      Inc(i);

    // if we have at least 1 monster, evaluate keys and values
    if i > 0 then
    begin
      if strKey = 'NewMonster:' then
      begin
        MonTe[i].strName := strValue;
        MonTe[i].intType := i;
      end;

      if (strKey = 'Unique') and (strValue = '= True') then
        MonTe[i].blUnique := True;
      if (strKey = 'Elite') and (strValue = '= True') then
        MonTe[i].blElite := True;
      if (strKey = 'Human') and (strValue = '= True') then
        MonTe[i].blHuman := True;
      if (strKey = 'LastEnemy') and (strValue = '= True') then
        MonTe[i].blLastEnemy := True;

      // specials without parameter
      if (strKey = 'Poison') and (strValue = '= True') then
        MonTe[i].blPoison := True;
      if (strKey = 'Confusion') and (strValue = '= True') then
        MonTe[i].blConfusion := True;
      if (strKey = 'CastsFire') and (strValue = '= True') then
        MonTe[i].blFire := True;
      if (strKey = 'CastsIce') and (strValue = '= True') then
        MonTe[i].blIce := True;
      if (strKey = 'CastsWater') and (strValue = '= True') then
        MonTe[i].blWaterC := True;
      if (strKey = 'CastsElectricity') and (strValue = '= True') then
        MonTe[i].blElect := True;
      if (strKey = 'BreakDefence') and (strValue = '= True') then
        MonTe[i].blBreakDefence := True;
      if (strKey = 'LoseArmour') and (strValue = '= True') then
        MonTe[i].blDestArmour := True;
      if (strKey = 'LoseWeapon') and (strValue = '= True') then
        MonTe[i].blDestWeapon := True;
      if (strKey = 'Blindness') and (strValue = '= True') then
        MonTe[i].blBlindness := True;
      if (strKey = 'Paralyze') and (strValue = '= True') then
        MonTe[i].blPara := True;
      if (strKey = 'Calm') and (strValue = '= True') then
        MonTe[i].blCalm := True;
      if (strKey = 'Curses') and (strValue = '= True') then
        MonTe[i].blCurse := True;
      if (strKey = 'MightyHit') and (strValue = '= True') then
        MonTe[i].blHitsHard := True;
      if (strKey = 'Invisible') and (strValue = '= True') then
        MonTe[i].blInvis := True;
      if (strKey = 'MoveOnWater') and (strValue = '= True') then
        MonTe[i].blWater := True;
      if (strKey = 'SelfHeal') and (strValue = '= True') then
        MonTe[i].blSelfHeal := True;

      if (strKey = 'Intelligent') and (strValue = '= True') then
        MonTe[i].blIntelligent := True;

      // specials with parameter
      if strKey = 'Teleport:' then
      begin
        MonTe[i].blTeleport  := True;
        MonTe[i].intTeleport := StrToInt(strValue);
      end;

      if strKey = 'SplitInto:' then
      begin
        MonTe[i].blSplit      := True;
        MonTe[i].strSplitInto := strValue;
      end;

      if strKey = 'Summon:' then
      begin
        MonTe[i].blSummon     := True;
        MonTe[i].strSplitInto := strValue;
      end;

      if strKey = 'DrainPP:' then
      begin
        MonTe[i].blDrainPP  := True;
        MonTe[i].intDrainPP := StrToInt(strValue);
      end;

      if strKey = 'DrainSTR:' then
      begin
        MonTe[i].blDrainSTR  := True;
        MonTe[i].intDrainSTR := StrToInt(strValue);
      end;

      // the following 3 are form transformations. can be used e.g. for blockades
      if strKey = 'TransformTileTo:' then
      begin
        MonTe[i].blTransform := True;
        MonTe[i].intTransformType:= StrToInt(strValue); // tile to which the dng. is transformed
      end;

      if strKey = 'DigIntoTile:' then  // special case of transform
      begin
        MonTe[i].blDig := True;
        MonTe[i].intTransformType:= StrToInt(strValue); // tile into which the monster digs
      end;

      if strKey = 'TransformIntegrity:' then
      begin
        MonTe[i].intTransformInteg := StrToInt(strValue);
      end;

      if strKey = 'TransformText:' then
      begin
        MonTe[i].strTransformText := strValue;  // description of the transformation
      end;


      if strKey = 'Tremble:' then  // an earthquake is created, player takes optional dmg.
      begin
        MonTe[i].blTremble := True;
        MonTe[i].intTrembleDmg := StrToInt(strValue);
      end;

      if strKey = 'Shout:' then  // player is thrown back and takes optional damage
      begin
        MonTe[i].blShout := True;
        MonTe[i].intShoutDmg := StrToInt(strValue);
      end;


      if strKey = 'Verb:' then
        MonTe[i].strVerb := strValue;
      if strKey = 'ShootVerb:' then
        MonTe[i].strShootVerb := strValue;
      if strKey = 'HitRate:' then
        MonTe[i].intHitRate := StrToInt(strValue);


      if strKey = 'Move:' then
        MonTe[i].intMove := StrToInt(strValue);

      if strKey = 'KillPlot:' then
        MonTe[i].intKillPlot := StrToInt(strValue);

      if strKey = 'Letter:' then
      begin
        cstr := strValue[1];
        MonTe[i].chLetter := cstr;
      end;

      if strKey = 'BulletLetter:' then
      begin
        cstr := strValue[1];
        MonTe[i].chBulletLetter := cstr;
      end;

      if strKey = 'OrdLetter:' then
        MonTe[i].chLetter := chr(StrToInt(strValue));
      if strKey = 'BulletOrdLetter:' then
        MonTe[i].chBulletLetter := chr(StrToInt(strValue));

      if strKey = 'WP:' then
        MonTe[i].intWP := StrToInt(strValue);
      if strKey = 'GP:' then
        MonTe[i].intGP := StrToInt(strValue);

      if strKey = 'AP:' then
        MonTe[i].intAP := StrToInt(strValue);

      if strKey = 'HP:' then
      begin
        MonTe[i].intMaxHP := StrToInt(strValue);
        MonTe[i].intHP    := MonTe[i].intMaxHP;
      end;

      if strKey = 'PP:' then
      begin
        MonTe[i].intMaxPP := StrToInt(strValue);
        MonTe[i].intPP    := MonTe[i].intMaxPP;
      end;

      if strKey = 'NeedsOpenQuest:' then
        MonTe[i].intQuestG := StrToInt(strValue);
      if strKey = 'NeedsSolvedQuest:' then
        MonTe[i].intQuestS := StrToInt(strValue);

      if strKey = 'EXP:' then
        MonTe[i].longExp := StrToInt(strValue);
      if strKey = 'Gold:' then
        MonTe[i].longGold := StrToInt(strValue);

      if strKey = 'DungeonLvl:' then
        MonTe[i].intLvl := StrToInt(strValue);

      MonTe[i].intTemplate := i;
    end;
  end;

  // close monsters.txt
  Close(MonsterFile);

  // set total number of available MonsterTemplates
  MonsterTemplates := i;

end;


procedure SaveBones;
var
  MonsterFile: textfile;
begin
  Assign(MonsterFile, CONST_DATADIR + 'data/bones.txt');

  if fileexists(CONST_DATADIR + 'data/bones.txt') then
    Append(MonsterFile)
  else
    Rewrite(MonsterFile);

  Writeln(MonsterFile, 'NewMonster:');
  Writeln(MonsterFile, ThePlayer.strName);
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'DungeonLvl:');
  Writeln(MonsterFile, IntToStr(DungeonLevel));
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'HP:');
  Writeln(MonsterFile, IntToStr(ThePlayer.intMaxHP));
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'PP:');
  Writeln(MonsterFile, IntToStr(ThePlayer.intMaxPP));
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'WP:');
  Writeln(MonsterFile, IntToStr(ThePlayer.intFight));
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'AP:');
  Writeln(MonsterFile, IntToStr(ThePlayer.intMove));
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'EXP:');
  Writeln(MonsterFile, IntToStr(ThePlayer.intLvl));
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'Gold:');
  Writeln(MonsterFile, IntToStr(ThePlayer.longGold));
  Writeln(MonsterFile, ' ');

  Writeln(MonsterFile, 'Intelligent');
  Writeln(MonsterFile, '= True');
  Writeln(MonsterFile, ' ');

  Close(MonsterFile);
end;


procedure BonesInit;
var
  MonsterFile: textfile;            // used to assign "data/bones.txt"
  i: integer;                // counter
  strKey, strValue: string;        // used to read key-value-pairs out of MonsterFile
begin

  if fileexists(CONST_DATADIR + 'data/bones.txt') then
  begin
    // initialize key-value-pair
    strKey   := '';
    strValue := '';

    // open bones.txt
    Assign(MonsterFile, CONST_DATADIR + 'data/bones.txt');
    Reset(MonsterFile);

    // initialize counter
    i := MonsterTemplates;

    // as long as monsters.txt not completely read...
    while EOF(MonsterFile) = False do
    begin
      // search for key
      repeat
        ReadLn(MonsterFile, strKey);
      until ((strKey <> '') and (strKey[1] <> ' ') and (strKey[1] <> '#')) or (EOF(MonsterFile));

      // key found, now search for corresponding value
      ReadLn(MonsterFile, strValue);

      // create new monster
      if strKey = 'NewMonster:' then
        Inc(i);


      if strKey = 'NewMonster:' then
      begin
        MonTe[i].strName     := 'ghost of ' + strValue;
        MonTe[i].intType     := i;
        MonTe[i].chLetter    := chr(143);
        MonTe[i].strVerb     := 'attacks';
        MonTe[i].blUnique    := False;
        MonTe[i].blLastEnemy := False;
        MonTe[i].blWater     := False;
        MonTe[i].blIntelligent := true;
      end;


      if (strKey = 'Poison') and (strValue = '= True') then
        MonTe[i].blPoison := True;
      if (strKey = 'Poison') and (strValue = '= False') then
        MonTe[i].blPoison := False;

      if (strKey = 'Confusion') and (strValue = '= True') then
        MonTe[i].blConfusion := True;
      if (strKey = 'Confusion') and (strValue = '= False') then
        MonTe[i].blConfusion := False;

      if (strKey = 'CastsFire') and (strValue = '= True') then
        MonTe[i].blFire := True;
      if (strKey = 'CastsFire') and (strValue = '= False') then
        MonTe[i].blFire := False;

      if (strKey = 'CastsIce') and (strValue = '= True') then
        MonTe[i].blIce := True;
      if (strKey = 'CastsIce') and (strValue = '= False') then
        MonTe[i].blIce := False;

      if (strKey = 'CastsWater') and (strValue = '= True') then
        MonTe[i].blWaterC := True;
      if (strKey = 'CastsWater') and (strValue = '= False') then
        MonTe[i].blWaterC := False;

      if (strKey = 'DestroyArmour') and (strValue = '= True') then
        MonTe[i].blDestArmour := True;
      if (strKey = 'DestroyArmour') and (strValue = '= False') then
        MonTe[i].blDestArmour := False;

      if (strKey = 'DestroyWeapon') and (strValue = '= True') then
        MonTe[i].blDestWeapon := True;
      if (strKey = 'DestroyWeapon') and (strValue = '= False') then
        MonTe[i].blDestWeapon := False;

      if (strKey = 'Blindness') and (strValue = '= True') then
        MonTe[i].blBlindness := True;
      if (strKey = 'Blindness') and (strValue = '= False') then
        MonTe[i].blBlindness := False;

      if (strKey = 'Paralyze') and (strValue = '= True') then
        MonTe[i].blPara := True;
      if (strKey = 'Paralyze') and (strValue = '= False') then
        MonTe[i].blPara := False;

      if (strKey = 'Calm') and (strValue = '= True') then
        MonTe[i].blCalm := True;
      if (strKey = 'Calm') and (strValue = '= False') then
        MonTe[i].blCalm := False;

      if (strKey = 'Curses') and (strValue = '= True') then
        MonTe[i].blCurse := True;
      if (strKey = 'Curses') and (strValue = '= False') then
        MonTe[i].blCurse := False;

      if strKey = 'WP:' then
        MonTe[i].intWP := StrToInt(strValue) * 3;
      if strKey = 'AP:' then
        MonTe[i].intAP := StrToInt(strValue) * 3;
      if strKey = 'HP:' then
      begin
        MonTe[i].intMaxHP := StrToInt(strValue) * 2;
        MonTe[i].intHP    := MonTe[i].intMaxHP;
      end;

      if strKey = 'Gold:' then
        MonTe[i].longGold := StrToInt(strValue);
      if strKey = 'EXP:' then
        MonTe[i].longEXP := StrToInt(strValue);

      if strKey = 'DungeonLvl:' then
        MonTe[i].intLvl := StrToInt(strValue);
    end;

    // close bones.txt
    Close(MonsterFile);

    // set total number of available MonsterTemplates
    MonsterTemplates := i;
  end;
end;


// reads available classes from file
procedure ClassInit;
var
  ClassFile: textfile;             // used to assign "data/classes.txt"
  i: integer;                      // counter
  strKey, strValue: string;        // used to read key-value-pairs out of ClassFile
begin

  // initialize key-value-pair
  strKey   := '';
  strValue := '';

  // open monsters.txt
  Assign(ClassFile, CONST_DATADIR + 'data/classes.txt');
  Reset(ClassFile);

  // initialize counter
  i := 0;

  // as long as monsters.txt not completely read...
  while EOF(ClassFile) = False do
  begin
    // search for key
    repeat
      ReadLn(ClassFile, strKey);
    until ((strKey <> '')and (strKey[1] <> ' ')  and (strKey[1] <> '#')) or (EOF(ClassFile));

    // key found, now search for corresponding value
    ReadLn(ClassFile, strValue);

    // create new class
    if strKey = 'NewClass:' then
      Inc(i);

    // if we have at least 1 class, evaluate keys and values
    if i > 0 then
    begin
      if strKey = 'NewClass:' then
        PlayClass[i].strName := strValue;

      if strKey = 'Fight:' then
        PlayClass[i].intFight := StrToInt(strValue);
      if strKey = 'View:' then
        PlayClass[i].intView := StrToInt(strValue);
      if strKey = 'Move:' then
        PlayClass[i].intMove := StrToInt(strValue);
      if strKey = 'Chant:' then
        PlayClass[i].intChant := StrToInt(strValue);
      if strKey = 'Burgle:' then
        PlayClass[i].intBurgle := StrToInt(strValue);

      if (strKey = 'AffectedSkill') and (strValue = '= Fight') then
        PlayClass[i].afSkill := 'Fight';
      if (strKey = 'AffectedSkill') and (strValue = '= View') then
        PlayClass[i].afSkill := 'View';
      if (strKey = 'AffectedSkill') and (strValue = '= Move') then
        PlayClass[i].afSkill := 'Move';
      if (strKey = 'AffectedSkill') and (strValue = '= Chant') then
        PlayClass[i].afSkill := 'Chant';
      if (strKey = 'AffectedSkill') and (strValue = '= Burgle') then
        PlayClass[i].afSkill := 'Burgle';

      if (strKey = 'AffectedStatus') and (strValue = '= HP') then
        PlayClass[i].afStat := 'HP';
      if (strKey = 'AffectedStatus') and (strValue = '= PP') then
        PlayClass[i].afStat := 'PP';
      if (strKey = 'AffectedStatus') and (strValue = '= EXP') then
        PlayClass[i].afStat := 'EXP';
      if (strKey = 'AffectedStatus') and (strValue = '= Gold') then
        PlayClass[i].afStat := 'Gold';
      if (strKey = 'AffectedStatus') and (strValue = '= Hunger') then
        PlayClass[i].afStat := 'Hunger';
    end;
  end;

  // close classes.txt
  Close(ClassFile);

  PlayProf[1] := 'Constructor';
  PlayProf[2] := 'Enchanter';
  PlayProf[3] := 'Thief';
  PlayProf[4] := 'Archer';
  PlayProf[5] := 'Soldier';
end;


end.
