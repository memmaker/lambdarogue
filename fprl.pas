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

program fprl;

{$IFDEF DARWIN}
{$PASCALMAINNAME SDL_main}
{$linklib SDLmain}

{$linkframework Cocoa}
{$linkframework SDL}
{$linkframework OpenGL}

{$linkframework SDL_image}
{$linkframework SDL_mixer}
{$ENDIF}

uses
  Constants, WebBE, VidUtil, SysUtils, StrUtils,
  Player, Items, Quests, Chants, RandomArea, LineOfSight, Dungeon, Plot, Input,
  FileIO, CollectData, BaseOutput, UserInterface, DrawDungeon, MessageLog, GFX,
  PuzzleMap, ExternMusic, ExternSFX, InventoryScreen, Effects, logger, Rvip;


var
  i, j, vx, vy, k, Door: integer;
  chKey: char;
  msg1, FunKey, dummy: string;
  intCenterX, intCenterY: integer;
  TitleSelection: integer;
  Knoepfe, KX, KY: longint;
  TempAnsi: ansistring;

  CONST_MONSTERRECDIST, CONST_MONSTERFIRERATE, CONST_SPAWN: integer;


  procedure SelectGameMode;
  var
    dummy: string;
  begin
    ClearScreenSDL;

    if UseSDL = True then
    begin
      TempAnsi := 'graphics/decobg.jpg';
      LoadImage_Title('graphics/decobg.jpg');
    end;

    if UseSDL = True then
      BlitImage_Title
    else
      StatusDeco;

    TransTextXY(1, 1, 'SELECT GAME MODE');

    TransTextXY(4, 5, 'Story mode includes all quests, encounters and story sequences that create');
    TransTextXY(4, 6, 'the complete LambdaRogue experience. You have to accept and follow many');
    TransTextXY(4, 7, 'quest objectives in order to win the game, and for gaining profession');
    TransTextXY(4, 8, 'ranks. In story mode, LambdaRogue plays more like a role playing game.');

    TransTextXY(4, 10, 'Coffeebreak mode is simpler: You have to go down to the 20th dungeon level');
    TransTextXY(4, 11, 'and kill Eris, the evil deity. This mode lacks many elements of story');
    TransTextXY(4, 12, 'mode, incl. some unique monsters and special quest rewards. Profession');
    TransTextXY(4, 13, 'ranks are gained automatically every 4 character levels. In coffeebreak');
    TransTextXY(4, 14, 'mode, LambdaRogue plays more like a traditional roguelike.');

    dummy:='-';
    repeat
      dummy := GetKeyInput('[s]tory mode  [c]offeebreak mode', false);
    until (dummy='s') or (dummy='c');

    if dummy='s' then
      ThePlayer.blCoffeebreak:=false
    else
      ThePlayer.blCoffeebreak:=true;
  end;

  procedure IncreaseDistress;
  begin
    if ThePlayer.intLimit < 100 then
    begin
      // only if humility talent is greater than 0
      if CollectHumility > 0 then
      begin
        // basic increase depending on humility talent
        if CollectHumility <= 3 then
          Inc(ThePlayer.intLimit);
        if (CollectHumility > 3) and (CollectHumility <= 6) then
          Inc(ThePlayer.intLimit, 2);
        if (CollectHumility > 6) and (CollectHumility <= 9) then
          Inc(ThePlayer.intLimit, 3);
        if (CollectHumility > 9) then Inc(ThePlayer.intLimit, 4);

        // items with influence on divine range generation
        Inc(ThePlayer.intLimit, ReturnStatusIncRate(49));

        // ensure that humility is never more than 100%
        if ThePlayer.intLimit > 100 then
          ThePlayer.intLimit := 100;
      end;
    end;
  end;


  function ShowSavegames: string;
  var
    Info: TSearchRec;
    x, y, n, sn: integer;
    strCharaName, dummy, tmp: string;
    stop: boolean;
    strFileList: array[97..162] of string;
    ch: char;
  begin
    ClearScreenSDL;

    for i := 97 to 162 do
      strFileList[i] := '-';

    if UseSDL = True then
    begin
      TempAnsi := 'graphics/decobg.jpg';
      LoadImage_Title('graphics/decobg.jpg');
    end;

    dummy := '-';
    tmp := '-';
    ch := '-';

    repeat

      if UseSDL = True then
        BlitImage_Title
      else
        StatusDeco;

      TransTextXY(1, 1, 'CREATE/CONTINUE GAME');

      y := 3;
      x := 1;
      n := 0;
      stop := False;

      if FindFirst(CONST_DATADIR + 'saves/*.lambdarogue', faAnyFile and faDirectory, Info) = 0 then
      begin
        repeat
          Inc(y);
          Inc(n);
          strCharaName := ExtractFileName(Info.Name);
          strCharaName :=
            LeftStr(strCharaName, NPos('.lambdarogue', strCharaName, 1) - 1);

          TransTextXY(x, y, chr(96 + n) + '  ' + strCharaName);
          strFileList[96 + n] := strCharaName;
          if y = 20 then
          begin
            y := 3;
            case x of
              1:
                x := 16;
              16:
                x := 32;
              26:
                stop := true;
              32:
                x := 48;
              48:
                x := 64;
              64:
                stop := True;
            end;
          end;
        until (stop = True) or (FindNext(info) <> 0);
      end;
      FindClose(Info);

      if (x = 1) and (y = 3) then
      begin
        TransTextXY(1, 4, 'There are no saved games to continue.');
        dummy := GetKeyInput('[SPACE] Create new game    [ESC] Cancel', False);
      end
      else
        dummy := GetKeyInput('[' + chr(97) + '] to [' + chr(96+n)+'] Continue saved game    [SPACE] Create new game    [ESC] Cancel', False);

      ch := dummy[1];

      if (dummy = 'SPACE') then
      begin
        tmp := '-';
        repeat
          tmp := GetTextInput('Enter your name:', 12)
        until (tmp <> 'ESC') and (tmp <> '-');
      end
      else
      begin
        if (dummy <> 'ESC') and (Ord(ch) > 96) and (Ord(ch) <= 96 + n) then
        begin
          sn := Ord(ch);
          tmp := strFileList[sn];
        end
        else
          tmp := 'ESC';
      end;
    until tmp <> '-';

    ShowSavegames := tmp;

  end;



  // this procedure is just for debugging
  procedure CheatCodes;
  var
    strCommandline: string;
    strCmd: string;
    strCmdPara1, strCmdPara2: string;
    i, j, FreeMonsterID: integer;
    longCmdPara1, longCmdPara2: longint;
  begin
    strCommandline := GetTextInput(strVersion + '#' + IntToStr(longTotalTurns) + '>', 60);
    strCommandline := strCommandline + ' ';

    strCmd := '';
    strCmdPara1 := '';
    strCmdPara2 := '';
    longCmdPara1 := 0;
    longCmdPara2 := 0;

    // Get command
    i := 0;
    repeat
      Inc(i);
      strCmd := strCmd + strCommandline[i];
    until (strCommandline[i] = ' ') or (i = length(strCommandline));
    strCmd := trim(uppercase(strCmd));

    // if commandline not entirely processed, there might be parameters
    if i<length(strCommandline) then
    begin
      repeat
        inc(i);
        strCmdPara1 := strCmdPara1 + strCommandline[i];
      until (strCommandline[i] = ' ') or (i = length(strCommandline));
      strCmdPara1 := trim(uppercase(strCmdPara1));
      val(strCmdPara1, longCmdPara1);

      // if there are still characters left, there might be a 2nd parameter
      if i<length(strCommandLine) then
      begin
        repeat
          inc(i);
          strCmdPara2 := strCmdPara2 + strCommandline[i];
        until i = length(strCommandline);
        strCmdPara2 := trim(uppercase(strCmdPara2));
        val(strCmdPara2, longCmdPara2);
      end;
    end;

    writeln(strCmd + ' ' + strCmdPara1 + ' ' + strCmdPara2);

    // sets different status values
    if strCmd = 'ME.SET' then
      if strCmdPara1 = 'HP' then
        ThePlayer.intHP := longCmdPara2
      else
      if strCmdPara1 = 'MAXHP' then
        ThePlayer.intMaxHP := longCmdPara2
      else
      if strCmdPara1 = 'PP' then
        ThePlayer.intPP := longCmdPara2
      else
      if strCmdPara1 = 'MAXPP' then
        ThePlayer.intMaxPP := longCmdPara2
      else
      if strCmdPara1 = 'STR' then
        ThePlayer.intStrength := longCmdPara2
      else
      if strCmdPara1 = 'DST' then
        ThePlayer.intLimit := longCmdPara2
      else
      if strCmdPara1 = 'EXP' then
        ThePlayer.longEXP := longCmdPara2
      else
      if strCmdPara1 = 'LEVEL' then
        ThePlayer.intLvl := longCmdPara2
      else
      if strCmdPara1 = 'FOOD' then
        ThePlayer.longFood := longCmdPara2
      else
      if strCmdPara1 = 'GOLD' then
        ThePlayer.longGold := longCmdPara2
      else
      if strCmdPara1 = 'FIGHT' then
        ThePlayer.intFight := longCmdPara2
      else
      if strCmdPara1 = 'HIT' then
        ThePlayer.intView := longCmdPara2
      else
      if strCmdPara1 = 'MOVE' then
        ThePlayer.intMove := longCmdPara2
      else
      if strCmdPara1 = 'CHANT' then
        ThePlayer.intChant := longCmdPara2
      else
      if strCmdPara1 = 'STEAL' then
        ThePlayer.intBurgle := longCmdPara2
      else
      if strCmdPara1 = 'TRADE' then
        ThePlayer.intTrade := longCmdPara2
      else
      if strCmdPara1 = 'HUMILITY' then
        ThePlayer.intHumility := longCmdPara2
      else
      if strCmdPara1 = 'SWORD' then
        ThePlayer.intSword := longCmdPara2
      else
      if strCmdPara1 = 'AXE' then
        ThePlayer.intAxe := longCmdPara2
      else
      if strCmdPara1 = 'LANCE' then
        ThePlayer.intWhip := longCmdPara2
      else
      if strCmdPara1 = 'FIGHT' then
        ThePlayer.intFight := longCmdPara2
      else
      if strCmdPara1 = 'GUN' then
        ThePlayer.intGun := longCmdPara2
      else
      if strCmdPara1 = 'TOOL' then
        ThePlayer.intTool := longCmdPara2;

    // sets a rank
    if strCmd = 'ME.RANK' then
      ThePlayer.intDipl[longCmdPara1] := longCmdPara2;

    // shows map and sets status values to extreme powerful
    if strCmd = 'ME.GOD' then
    begin
      ThePlayer.intHP := 9999;
      ThePlayer.intMaxHP := 9999;
      ThePlayer.intPP := 9999;
      ThePlayer.intMaxPP := 9999;
      ThePlayer.intFight := 15;
      ThePlayer.intMove := 15;
      ThePlayer.longFood := 9999;
      ThePlayer.longGold := 9999;
      for i := 1 to DngMaxWidth do
        for j := 1 to DngMaxHeight do
          DngLvl[i, j].blKnown := True;
    end;


    // re-reads data files
    if strCmd = 'REALITY.INIT' then
    begin
      MonsterInit;
      BonesInit;
      ClassInit;
      ChantInit;
      ItemInit;
      WeaponVariants;
      CraftingReceipts;
      QuestInit;
    end;

    // earthquake
    if strCmd = 'MAP.QUAKE' then
    begin
      ShowTransMessage('An earthquake! The whole cave is trembling!', False);
      PlaySFX('quake.ogg');
      TrembleScreen;
      EarthQuake;
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // commits suicide
    if strCmd = 'ME.SUICIDE' then
      ThePlayer.intHP := 0;

    // heals HP and PP
    if strCmd = 'ME.HEAL' then
    begin
      ThePlayer.intHP := ThePlayer.intMaxHP;
      ThePlayer.intPP := ThePlayer.intMaxPP;
    end;

    // uncurses
    if strCmd = 'ME.UNCURSE' then
      ThePlayer.blCursed := False;

    // blesses
    if strCmd = 'ME.BLESS' then
      ThePlayer.blBlessed := True;

    // unblesses
    if strCmd = 'ME.UNBLESS' then
      ThePlayer.blBlessed := False;

    // curses
    if strCmd = 'ME.CURSE' then
      ThePlayer.blCursed := True;

    // quests
    if strCmd = 'QUESTS.OPENALL' then
      for i := 1 to WinLevel do
        for j := 1 to 9 do
          if Quest[i, j].strDescri <> '-' then
            ThePlayer.intQuestState[i, j] := 1;

    if strCmd = 'QUESTS.SOLVEALL' then
      for i := 1 to WinLevel do
        for j := 1 to 9 do
          if Quest[i, j].strDescri <> '-' then
            ThePlayer.intQuestState[i, j] := 2;

    if strCmd = 'QUESTS.RESETALL' then
      for i := 1 to WinLevel do
        for j := 1 to 9 do
          if Quest[i, j].strDescri <> '-' then
            ThePlayer.intQuestState[i, j] := 0;

    if strCmd = 'QUESTS.SOLVE' then
      ThePlayer.intQuestState[longCmdPara1, longCmdPara2] := 2;

    if strCmd = 'QUESTS.OPEN' then
      ThePlayer.intQuestState[longCmdPara1, longCmdPara2] := 1;

    if strCmd = 'QUESTS.RESET' then
      ThePlayer.intQuestState[longCmdPara1, longCmdPara2] := 0;

    // puts certain items on certain positions in inventory
    if strCmd = 'INVENTORY.SETITEM' then
    begin
      for i := 1 to ItemCount do
        if uppercase(Thing[i].strRealName) = uppercase(strCmdPara2) then
        begin
          Inventory[longCmdPara1].intType := i;
          Inventory[longCmdPara1].longNumber := 1;
        end;

    end;
    // sets number of items of an inventory type
    if strCmd = 'INVENTORY.SETAMOUNT' then
      Inventory[longCmdPara1].longNumber := longCmdPara2;

    // summons a monster by name
    if strCmd = 'MAP.SUMMON' then
    begin
      FreeMonsterID := GetFirstFreeMonsterID;
      if FreeMonsterID > -1 then
      begin
        strCmdPara1 := GetTextInput('Monster Name (case-sensitive):', 50);
        if ReturnMonTeByName(strCmdPara1)>0 then
        begin
          CreateMonster(FreeMonsterID, strCmdPara1, 0);
          Monster[FreeMonsterID].intX := ThePlayer.intX;
          Monster[FreeMonsterID].intY := ThePlayer.intY;
        end;
      end;
    end;

    // create barrier around player
    if strCmd = 'ME.PROTECT' then
      ThePlayer.intWall := longCmdPara1;

    // makes map known
    if strCmd = 'MAP.SHOW' then
      for i := 1 to DngMaxWidth do
        for j := 1 to DngMaxHeight do
          DngLvl[i, j].blKnown := True;

    // creates portal down
    if strCmd = 'MAP.DOWNSTAIRS' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 9;

    // creates portal up
    if strCmd = 'MAP.UPSTAIRS' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 8;

    // creates rare item
    if strCmd = 'MAP.RAREITEM' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ReturnRareItem;

    // shows plot scene
    if strCmd = 'PLOT.SHOW' then
    begin
      ThePlayer.blStory[longCmdPara1]:=false;
      ShowPlot(longCmdPara1);
    end;

    // shows text file
    if strCmd = 'TEXT.SHOW' then
      ShowText(strCmdPara1);

    // wins
    if strCmd = 'WIN' then
    begin
      WinGame;
      blWon:=true;
    end;

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);

  end;

  // distant attack by monster
  procedure MonsterShoot(MonsterID: integer);
  var
    DistanceX, DistanceY, i, intDP, intMTP: integer;
    vx, vy, GunX, GunY, GunBX, GunBY: integer;
    strMsg: string;
  begin
    DistanceX := abs(ThePlayer.intX - Monster[MonsterID].intX);
    DistanceY := abs(ThePlayer.intY - Monster[MonsterID].intY);

    vx := 0;
    vy := 0;

    if ((DistanceX <= CONST_MONSTERRECDIST) and (DistanceY <= CONST_MONSTERRECDIST)) and
      ((DistanceX > 2) or (DistanceY > 2)) then
    begin
      // monster in the same row as player
      if Monster[MonsterID].intY = ThePlayer.intY then
      begin
        // monster is left from player
        if Monster[MonsterID].intX < ThePlayer.intX then
        begin
          for i := Monster[MonsterID].intX to ThePlayer.intX do
            if (DngLvl[i, Monster[MonsterID].intY].intIntegrity > 0) or
              (DngLvl[i, Monster[MonsterID].intY].intFloorType = 13) or
              (DngLvl[i, Monster[MonsterID].intY].intFloorType = 22) then
              break;
          if i = ThePlayer.intX then
            vx := 1;
        end;

        // monster is right from player
        if Monster[MonsterID].intX > ThePlayer.intX then
        begin
          for i := Monster[MonsterID].intX downto ThePlayer.intX do
            if (DngLvl[i, Monster[MonsterID].intY].intIntegrity > 0) or
              (DngLvl[i, Monster[MonsterID].intY].intFloorType = 13) or
              (DngLvl[i, Monster[MonsterID].intY].intFloorType = 22) then
              break;
          if i = ThePlayer.intX then
            vx := -1;
        end;
      end;

      // monster in the same column as player
      if (Monster[MonsterID].intX = ThePlayer.intX) then
      begin

        // monster is beyond player
        if Monster[MonsterID].intY < ThePlayer.intY then
        begin
          for i := Monster[MonsterID].intY to ThePlayer.intY do
            if (DngLvl[Monster[MonsterID].intX, i].intIntegrity > 0) or
              (DngLvl[Monster[MonsterID].intX, i].intFloorType = 13) or
              (DngLvl[Monster[MonsterID].intX, i].intFloorType = 22) then
              break;
          if i = ThePlayer.intY then
            vy := 1;
        end;

        // monster is below player
        if Monster[MonsterID].intY > ThePlayer.intY then
        begin
          for i := Monster[MonsterID].intY downto ThePlayer.intY do
            if (DngLvl[Monster[MonsterID].intX, i].intIntegrity > 0) or
              (DngLvl[Monster[MonsterID].intX, i].intFloorType = 13) or
              (DngLvl[Monster[MonsterID].intX, i].intFloorType = 22) then
              break;
          if i = ThePlayer.intY then
            vy := -1;
        end;
      end;
    end;

    // if a vector (vx or vy) is set, the monster really shoots
    if (vx <> 0) or (vy <> 0) then
    begin

      // starting position of monster's bullet
      GunX := Monster[MonsterID].intX;
      GunY := Monster[MonsterID].intY;

      GunBX := ThePlayer.intBX;

      if UseSDL = True then
        GunBY := ThePlayer.intBY + 1
      else
        GunBY := ThePlayer.intBY;

      if Monster[MonsterID].intX > ThePlayer.intX then
        Inc(GunBX, DistanceX)
      else
        Dec(GunBX, DistanceX);

      if Monster[MonsterID].intY > ThePlayer.intY then
        Inc(GunBY, DistanceY)
      else
        Dec(GunBY, DistanceY);

      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

      if (Ord(Monster[MonsterID].chBulletLetter) <> 129) and
        (Ord(Monster[MonsterID].chBulletLetter) <> 160) then
        PlaySFX('magic-combat.ogg');

      // let the bullet fly
      repeat
        Inc(GunX, vx);
        Inc(GunY, vy);

        Inc(GunBX, vx);
        Inc(GunBY, vy);

        // show bullet
        if (GunBX > 1) and (GunBX < ThePlayer.intBX * 2) and
          (GunBY > 1) and (GunBY < ThePlayer.intBY * 2) then
        begin
          AnyCharXY(GunBX, GunBY, Monster[MonsterID].chBulletLetter, 0);
          if UseSDL = True then
            SDL_UPDATERECT(screen, 0, 0, 0, 0)
          else
            UpdateScreen(True);
          delay(50);
          if UseSDL = True then
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        end;

      until (GunX = ThePlayer.intX) and (GunY = ThePlayer.intY);

      // calculate effects of battle
      intDP := CollectDP;
      intMTP := Monster[MonsterID].intGP - intDP;
      if intMTP <= 1 then
        intMTP := 0;

      // barrier?
      if ThePlayer.intWall > 0 then
        intMTP := 0;

      // fire attack, but fire resistant?
      if (Monster[MonsterID].chBulletLetter = chr(145)) and (CheckEffect(13)) then
        intMTP := 0;

      // ice attack, but ice resistant?
      if (Monster[MonsterID].chBulletLetter = chr(132)) and (CheckEffect(14)) then
        intMTP := 0;

      // water attack, but water resistant?
      if (Monster[MonsterID].chBulletLetter = chr(147)) and (CheckEffect(35)) then
        intMTP := 0;

      // electricity attack, but electricity resistant?
      if (Monster[MonsterID].chBulletLetter = chr(36)) and (CheckEffect(55)) then
        intMTP := 0;

      // set item that decreases damage by 25%?
      if CheckForItemSet(6)=true then
      begin
        dec(intMTP, (25*intMTP) div 100);
        if intMTP<1 then
          intMTP:=0;
      end;

      if random(400) > Monster[MonsterID].intHitRate then
      begin
        if intMTP > 0 then
        begin
          ShowTransMessage('The ' + Monster[MonsterID].strName + ' ' + Monster[MonsterID].strShootVerb + ' [-' + IntToStr(intMTP) + ' HP].', False);
          if Monster[MonsterID].chBulletLetter = chr(145) then
            BurnInventoryItem;
        end
        else
        begin
          if ThePlayer.intWall > 0 then
            ShowTransMessage('The attack bounces off your barrier.', False)
          else
            ShowTransMessage('The ' + Monster[MonsterID].strName +
              ' ' + Monster[MonsterID].strShootVerb + ', but does no damage.', False);
        end;
      end
      else
      begin
        ShowTransMessage('The ' + Monster[MonsterID].strName +
          ' ' + Monster[MonsterID].strShootVerb + ', but the shot misses.', False);
        intMTP := 0;
      end;

      ThePlayer.intHP := ThePlayer.intHP - intMTP;
      if ThePlayer.intHP < 1 then
      begin
        if Monster[i].intInvis > 0 then
          GameOver('Shot by ... something')
        else
        begin
          strMsg := lowercase(LeftStr(Monster[MonsterID].strName, 1));
          if (strMsg = 'a') or (strMsg = 'e') or (strMsg = 'u') or
            (strMsg = 'o') or (strMsg = 'i') then
            GameOver('Shot by an ' + Monster[MonsterID].strName)
          else
            GameOver('Shot by a ' + Monster[MonsterID].strName);
        end;
      end;
    end;
  end;

  // This function returns, if a player or a monster hits or misses the enemy
  function HitOrMiss(MonsterID: integer): boolean;
  var
    CompareMoveMonster, CompareMovePlayer: integer;
  begin
    HitOrMiss := True;

    // player base is Move-skill incl. all bonuses
    CompareMovePlayer := CollectMove;

    // monster base is Move-skill; if not available, player skill +/-
    if Monster[MonsterID].intMove = 0 then
    begin
      CompareMoveMonster := CompareMovePlayer;
      if random(400) > CONST_MONSTERISFASTER then
        Inc(CompareMoveMonster, 1 + trunc(random(6)))
      else
        Dec(CompareMoveMonster, 1 + trunc(random(6)));
    end
    else
      CompareMoveMonster := Monster[MonsterID].intMove;

    // items with influence on move-skill
    Inc(CompareMovePlayer, ReturnStatusIncRate(25));

    // negative influences on player
    // -- a little bit hunger
    if ThePlayer.longFood < 300 then
      Dec(CompareMovePlayer);

    // -- hunger
    if ThePlayer.longFood < 200 then
      Dec(CompareMovePlayer);

    // -- fainting
    if ThePlayer.longFood < 61 then
      Dec(CompareMovePlayer);

    // -- starving
    if ThePlayer.longFood < 21 then
      Dec(CompareMovePlayer);

    // -- confusion
    if ThePlayer.intConfusion > 0 then
      CompareMovePlayer := CompareMovePlayer div 2;

    // -- blindness
    if ThePlayer.intBlind > 0 then
      CompareMovePlayer := 0;

    // -- paralization or curse
    if (ThePlayer.intPara > 0) or (ThePlayer.blCursed = True) then
      CompareMovePlayer := 0;

    // -- bad luck
    if random(400) > CONST_BADHITLUCK then
      CompareMovePlayer := 0;



    // negative influences on monster
    // -- player is blessed
    if ThePlayer.blBlessed = True then
      CompareMoveMonster := CompareMoveMonster div 2;

    // -- bad luck
    if random(400) > CONST_BADHITLUCK then
      CompareMoveMonster := 0;


    // both have the same Move-skill -> mostly the player hits
    if CompareMoveMonster = CompareMovePlayer then
      if random(400) > 350 then
        Inc(CompareMoveMonster)
      else
        Dec(CompareMoveMonster);


    if CompareMoveMonster > CompareMovePlayer then
      HitOrMiss := True
    else
      HitOrMiss := False;
  end;


  // Move Monsters
  function MoveMonsters(): string;
  var
    i, j, k, intDP, intMTP, oldx, oldy, t, s: integer;
    strMsg: string;
    DistanceX, DistanceY: integer;
    blDone, intact: boolean;
    TransRange: integer;
    FreeSpaceLeft, FreeSpaceRight, FreeSpaceTop, FreeSpaceDown, ShoutX, ShoutY, ShoutVX, ShoutVY: integer;

  begin
    MoveMonsters := '';

    intDP := CollectDP;

    for i := 1 to 510 do
    begin


      intact:=false;

      // ** special abilities like tremble, shout, transform, which are always done
      //    independently from melee combat **

      // 1. check distance to player -- special happens only if player is max. 2 tiles away
      if (abs(ThePlayer.intX - Monster[i].intX) < 3) and (abs(ThePlayer.intY - Monster[i].intY) < 3) then
      begin
        // 2. check if monster is hostile
        if Monster[i].blHuman = false then
        begin
          // 3. check if monster has PP to use
          if Monster[i].intPP > 0 then
          begin

            // dig: create rock (or any other tile type) around monster
            if (intact=false) and (Monster[i].blDig=true) then
            begin
              if random(1000)>950 then
              begin
                ShowTransMessage(Monster[i].strTransformText, false);

                ShoutX:=Monster[i].intX;
                ShoutY:=Monster[i].intY;

                if DngLvl[ShoutX-1,ShoutY-1].intIntegrity=0 then
                begin
                  DngLvl[ShoutX-1,ShoutY-1].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX-1,ShoutY-1].intIntegrity:=Monster[i].intTransformInteg;
                end;

                if DngLvl[ShoutX,ShoutY-1].intIntegrity=0 then
                begin
                  DngLvl[ShoutX,ShoutY-1].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX,ShoutY-1].intIntegrity:=Monster[i].intTransformInteg;
                end;

                if DngLvl[ShoutX+1,ShoutY-1].intIntegrity=0 then
                begin
                  DngLvl[ShoutX+1,ShoutY-1].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX+1,ShoutY-1].intIntegrity:=Monster[i].intTransformInteg;
                end;

                if DngLvl[ShoutX+1,ShoutY].intIntegrity=0 then
                begin
                  DngLvl[ShoutX+1,ShoutY].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX+1,ShoutY].intIntegrity:=Monster[i].intTransformInteg;
                end;

                if DngLvl[ShoutX+1,ShoutY+1].intIntegrity=0 then
                begin
                  DngLvl[ShoutX+1,ShoutY+1].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX+1,ShoutY+1].intIntegrity:=Monster[i].intTransformInteg;
                end;

                if DngLvl[ShoutX,ShoutY+1].intIntegrity=0 then
                begin
                  DngLvl[ShoutX,ShoutY+1].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX,ShoutY+1].intIntegrity:=Monster[i].intTransformInteg;
                end;

                if DngLvl[ShoutX-1,ShoutY+1].intIntegrity=0 then
                begin
                  DngLvl[ShoutX-1,ShoutY+1].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX-1,ShoutY+1].intIntegrity:=Monster[i].intTransformInteg;
                end;

                if DngLvl[ShoutX-1,ShoutY].intIntegrity=0 then
                begin
                  DngLvl[ShoutX-1,ShoutY].intFloorType:=Monster[i].intTransformType;
                  DngLvl[ShoutX-1,ShoutY].intIntegrity:=Monster[i].intTransformInteg;
                end;

                dec(Monster[i].intPP);

                intact:=true;

              end;
            end;


            // transform: change surrounding dungeon tiles to something else
            if (intact=false) and (Monster[i].blTransform=true) then
            begin
              if random(1000)>950 then
              begin

                ShowTransMessage(Monster[i].strTransformText, false);

                // blockades reach 1 tile, all other transform reach distance to player + 1
                if Monster[i].intTransformInteg=0 then
                  TransRange:=abs(ThePlayer.intX - Monster[i].intX) + 1
                else
                  TransRange:=1;


                if TransRange>1 then
                begin // fill surroundings with new floortype
                  for j:=Monster[i].intX-Transrange to Monster[i].intX+Transrange do
                    for k:=Monster[i].intY-Transrange to Monster[i].intY+Transrange do
                    begin
                      if DngLvl[j,k].intIntegrity=0 then
                      begin
                        DngLvl[j,k].intFloorType:=Monster[i].intTransformType;
                        DngLvl[j,k].intIntegrity:=Monster[i].intTransformInteg;
                      end;
                    end;
                end
                else
                begin  // only blockade 1 tile in direction to player
                  // player is right from monster; blockade
                  if ThePlayer.intX-Monster[i].intX>1 then
                  begin
                    if DngLvl[Monster[i].intX+1, Monster[i].intY].intIntegrity=0 then
                    begin
                      DngLvl[Monster[i].intX+1, Monster[i].intY].intFloorType := Monster[i].intTransformType;
                      DngLvl[Monster[i].intX+1, Monster[i].intY].intIntegrity := Monster[i].intTransformInteg;
                    end;
                  end;

                  // player is left from monster; blockade
                  if ThePlayer.intX-Monster[i].intX<-1 then
                  begin
                    if DngLvl[Monster[i].intX-1, Monster[i].intY].intIntegrity=0 then
                    begin
                      DngLvl[Monster[i].intX-1, Monster[i].intY].intFloorType := Monster[i].intTransformType;
                      DngLvl[Monster[i].intX-1, Monster[i].intY].intIntegrity := Monster[i].intTransformInteg;
                    end;
                  end;

                  // player is above monster; blockade
                  if ThePlayer.intY-Monster[i].intY<-1 then
                  begin
                    if DngLvl[Monster[i].intX, Monster[i].intY-1].intIntegrity=0 then
                    begin
                      DngLvl[Monster[i].intX, Monster[i].intY-1].intFloorType := Monster[i].intTransformType;
                      DngLvl[Monster[i].intX, Monster[i].intY-1].intIntegrity := Monster[i].intTransformInteg;
                    end;
                  end;

                  // player is below monster; blockade
                  if ThePlayer.intY-Monster[i].intY>1 then
                  begin
                    if DngLvl[Monster[i].intX, Monster[i].intY+1].intIntegrity=0 then
                    begin
                      DngLvl[Monster[i].intX, Monster[i].intY+1].intFloorType := Monster[i].intTransformType;
                      DngLvl[Monster[i].intX, Monster[i].intY+1].intIntegrity := Monster[i].intTransformInteg;
                    end;
                  end;

                end;

                dec(Monster[i].intPP);

                intact:=true;
              end;
            end;

            // tremble: create earthquake and damage player
            if (intact=false) and (Monster[i].blTremble=true) then
            begin
              if random(1000)>950 then
              begin
                ShowTransMessage('The '+Monster[i].strName+' invokes an earthquake!', false);

                TrembleScreen;
                EarthQuake;

                dec(ThePlayer.intHP, Monster[i].intTrembleDmg);
                IncreaseDistress;

                if ThePlayer.intHP < 1 then
                begin
                  strMsg := lowercase(LeftStr(Monster[i].strName, 1));
                  if (strMsg = 'a') or (strMsg = 'e') or
                    (strMsg = 'u') or (strMsg = 'o') or (strMsg = 'i') then
                    GameOver('Killed by an earthquake invoked by an ' + Monster[i].strName)
                  else
                    GameOver('Killed by an earthquake invoked by a ' + Monster[i].strName);
                end;

                dec(Monster[i].intPP);

                intact:=true;
              end;
            end;

            // shout: push away the player as far as possible
            if (intact=false) and (Monster[i].blShout=true) then
            begin
              if random(1000)>950 then
              begin

                // 1. Calculate
                FreeSpaceLeft:=0;
                FreeSpaceRight:=0;
                FreeSpaceTop:=0;
                FreeSpaceDown:=0;

                // Left from player
                ShoutX := ThePlayer.intX;
                ShoutY := ThePlayer.intY;
                repeat
                  Dec(ShoutX);
                  if DngLvl[ShoutX,ShoutY].intIntegrity=0 then
                    inc(FreeSpaceLeft);
                until DngLvl[ShoutX, ShoutY].intIntegrity>0;

                // Right from player
                ShoutX := ThePlayer.intX;
                ShoutY := ThePlayer.intY;
                repeat
                  Inc(ShoutX);
                  if DngLvl[ShoutX,ShoutY].intIntegrity=0 then
                    inc(FreeSpaceRight);
                until DngLvl[ShoutX, ShoutY].intIntegrity>0;

                // Top from player
                ShoutX := ThePlayer.intX;
                ShoutY := ThePlayer.intY;
                repeat
                  Dec(ShoutY);
                  if DngLvl[ShoutX,ShoutY].intIntegrity=0 then
                    inc(FreeSpaceTop);
                until DngLvl[ShoutX, ShoutY].intIntegrity>0;

                // Down from player
                ShoutX := ThePlayer.intX;
                ShoutY := ThePlayer.intY;
                repeat
                  Inc(ShoutY);
                  if DngLvl[ShoutX,ShoutY].intIntegrity=0 then
                    inc(FreeSpaceDown);
                until DngLvl[ShoutX, ShoutY].intIntegrity>0;

                // 2. Decide in which direction to push the player
                if FreeSpaceLeft > FreeSpaceRight then
                  ShoutVX := -1*FreeSpaceLeft
                else
                  ShoutVX := 1*FreeSpaceRight;

                if FreeSpaceTop > FreeSpaceDown then
                  ShoutVY := -1*FreeSpaceTop
                else
                  ShoutVY := 1*FreeSpaceDown;

                if abs(FreeSpaceLeft-FreeSpaceRight) > abs(FreeSpaceTop-FreeSpaceDown) then
                  ShoutVY := 0
                else
                  ShoutVX := 0;


                // 3. Set new player position
                ThePlayer.intX := ThePlayer.intX + ShoutVX;
                ThePlayer.intY := ThePlayer.intY + ShoutVY;

                ShowTransMessage('You are pushed back by the '+Monster[i].strName + chr(39)+'s shout!', false);

                dec(ThePlayer.intHP, Monster[i].intShoutDmg);
                IncreaseDistress;

                if ThePlayer.intHP < 1 then
                begin
                  strMsg := lowercase(LeftStr(Monster[i].strName, 1));
                  if (strMsg = 'a') or (strMsg = 'e') or
                    (strMsg = 'u') or (strMsg = 'o') or (strMsg = 'i') then
                    GameOver('Killed by the shout of an ' + Monster[i].strName)
                  else
                    GameOver('Killed by the shout of a ' + Monster[i].strName);
                end;

                dec(Monster[i].intPP);

                intact:=true;
              end;
            end;

          end;
        end;
      end;



      // ** decrease endurance of existing effects **

      if Monster[i].intInvis > 0 then
        Dec(Monster[i].intInvis);

      if Monster[i].intPara > 0 then
        Dec(Monster[i].intPara);

      if Monster[i].intPoison > 0 then
      begin
        if Monster[i].intHP>0 then
        begin
          Dec(Monster[i].intHP);
          ShowTransMessage('The '+ Monster[i].strName + ' suffers from poison. [HP: '+IntToStr(Monster[i].intHP)+']', false);
        end;
        Dec(Monster[i].intPoison);
      end;


      // ** effects of current dungeon tile on monster **

      // force field -- affect robots in level 26 and 27
      if DngLvl[Monster[i].intX, Monster[i].intY].intFloorType = 3 then
        if (DungeonLevel = 26) or (DungeonLevel = 27) then
        begin
          // halven robots HP
          Monster[i].intHP := Monster[i].intHP div 2;
          if Monster[i].intHP = 0 then
            Monster[i].intHP := 1;
          // paralyze monster
          Inc(Monster[i].intPara, 3 + trunc(random(3)));
          ShowTransMessage('An EMP pulse paralyzes the ' + Monster[i].strName + '.', False);
        end;


      // lava
      if DngLvl[Monster[i].intX, Monster[i].intY].intFloorType = 20 then
      begin
        if (Monster[i].blFire = False) or (Monster[i].strName <> 'Eris') then
        begin
          Dec(Monster[i].intHP, 1 + trunc(random(3)));
          if Monster[i].intHP < 1 then
            Monster[i].intHP := 1;
        end;
      end;

      // items
      t := DngLvl[Monster[i].intX, Monster[i].intY].intItem;

      // - banana peel: reduce HP
      if t = ReturnItemByName('Banana Peel') then
      begin
        s := trunc(Monster[i].intMaxHP / 4);
        Dec(Monster[i].intHP, s);
        if Monster[i].intHP <= 0 then
          Monster[i].intHP := 1;
        ShowTransMessage('The ' + Monster[i].strName + ' slips on a banana peel [-' + IntToStr(s) + ' HP]', False);
        DngLvl[Monster[i].intX, Monster[i].intY].intItem := 0;
      end;


      // air effects
      // - fire (1)
      if DngLvl[Monster[i].intX, Monster[i].intY].intAirType = 1 then
      begin
        if Monster[i].blFire = True then
        begin
          Inc(Monster[i].intHP, DngLvl[Monster[i].intX, Monster[i].intY].intAirRange);
          ShowTransMessage('The ' + Monster[i].strName + ' feels comfortable in the warm air.', False);
        end
        else
        begin
          Dec(Monster[i].intHP,
            DngLvl[Monster[i].intX, Monster[i].intY].intAirRange);
          if Monster[i].intHP < 1 then
            IsMonsterDead(i);
        end;
      end;

      // - ice (2)
      if DngLvl[Monster[i].intX, Monster[i].intY].intAirType = 2 then
      begin
        if Monster[i].blIce = True then
        begin
          Inc(Monster[i].intHP, DngLvl[Monster[i].intX, Monster[i].intY].intAirRange div 2);
          ShowTransMessage('The ' + Monster[i].strName + ' enjoys the refreshing cold air.', False);
        end
        else
        begin
          Dec(Monster[i].intHP,
            DngLvl[Monster[i].intX, Monster[i].intY].intAirRange div 2);

          // all monsters except Eris freeze if not immune to ice
          if Monster[i].strName<>'Eris' then
          begin
            Inc(Monster[i].intPara, 3 + trunc(random(3)));
            ShowTransMessage('The ' + Monster[i].strName + ' is frozen.', False);
          end;

          if Monster[i].intHP < 1 then
            IsMonsterDead(i);
        end;
      end;

      // - water (3)
      if DngLvl[Monster[i].intX, Monster[i].intY].intAirType = 3 then
      begin
        if Monster[i].blWater = True then
        begin
          Inc(Monster[i].intHP, DngLvl[Monster[i].intX, Monster[i].intY].intAirRange div 3);
          ShowTransMessage('The ' + Monster[i].strName + ' relaxes happily in the water.', False);
        end
        else
        begin
          Dec(Monster[i].intHP,
            DngLvl[Monster[i].intX, Monster[i].intY].intAirRange div 3);
          if Monster[i].intHP < 1 then
            IsMonsterDead(i);
        end;
      end;

      // - heal aura (4)
      if DngLvl[Monster[i].intX, Monster[i].intY].intAirType = 4 then
      begin
        if Monster[i].intHP < Monster[i].intMaxHP then
        begin
          Inc(Monster[i].intHP, DngLvl[Monster[i].intX, Monster[i].intY].intAirRange);
          if Monster[i].intHP > Monster[i].intMaxHP then
            Monster[i].intHP := Monster[i].intMaxHP;
          ShowTransMessage('The ' + Monster[i].strName + ' regenerates.', False);
        end;
      end;

      // - poisonous gas (5)
      // - ... (6)
      // - ... (7)

      // actions done only by intelligent monsters
      if Monster[i].blIntelligent=true then
      begin

        // ** Use poisonous item to increase poison range?
        if (intact=false) and (t>0) then
          if Thing[t].intEffect=45 then
            if (Thing[t].blEat=true) or (Thing[t].blDrink=true) then
            begin
              if Monster[i].blPoison=true then
              begin
                inc(Monster[i].intPP);
                inc(Monster[i].intMaxPP);
                ShowTransMessage('The ' + Monster[i].strName + ' becomes even more poisonous.', false);
                DngLvl[Monster[i].intX, Monster[i].intY].intItem := 0;
                intact:=true;
              end;
            end;


        // ** Use item for restoring PP
        if (Monster[i].strName <> 'model X robot') and (Monster[i].strName <> 'model Y robot') and (Monster[i].strName <> 'Abandoned Android') then
        begin
          // - cola or coffee: increase PP
          if (intact=false) and ((t = ReturnItemByName('Cola')) or (t = ReturnItemByName('Caffeine'))) then
          begin
            if Monster[i].intPP < trunc(Monster[i].intMaxPP / 2) then
            begin
              s := thing[t].intRange;
              Inc(Monster[i].intPP, s);

              if Monster[i].intPP > Monster[i].intMaxPP then
                Monster[i].intPP := Monster[i].intMaxPP;
              ShowTransMessage('The ' + Monster[i].strName + ' uses ' + thing[t].strRealName + ' [PP restored].', False);
              DngLvl[Monster[i].intX, Monster[i].intY].intItem := 0;
              intact:=true;
            end;
          end;

          // ** Use item for restoring HP
          if (intact=false) and ((t = ReturnItemByName('Water')) or (t = ReturnItemByName('Aspirin')) or (t = ReturnItemByName('Penicillin'))) then
          begin
            if Monster[i].intHP < trunc(Monster[i].intMaxHP / 2) then
            begin
              s := thing[t].intRange;
              Inc(Monster[i].intHP, s);

              if Monster[i].intHP > Monster[i].intMaxHP then
                Monster[i].intHP := Monster[i].intMaxHP;
              ShowTransMessage('The ' + Monster[i].strName + ' uses ' + thing[t].strRealName + ' [HP restored].', False);
              DngLvl[Monster[i].intX, Monster[i].intY].intItem := 0;
              intact:=true;
            end;
          end;
        end;

        // ** Open a door?

        // x-1, y
        if (intact=false) and (ThePlayer.intX<=Monster[i].intX-1) and (ThePlayer.intY=Monster[i].intY) and (DngLvl[Monster[i].intX-1, Monster[i].intY].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX-1, Monster[i].intY].intFloorType:=4;
          DngLvl[Monster[i].intX-1, Monster[i].intY].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

        // x-1, y-1
        if (intact=false) and (ThePlayer.intX<=Monster[i].intX-1) and (ThePlayer.intY<=Monster[i].intY-1) and (DngLvl[Monster[i].intX-1, Monster[i].intY-1].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX-1, Monster[i].intY-1].intFloorType:=4;
          DngLvl[Monster[i].intX-1, Monster[i].intY-1].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

        // x, y-1
        if (intact=false) and (ThePlayer.intX=Monster[i].intX) and (ThePlayer.intY<=Monster[i].intY-1) and (DngLvl[Monster[i].intX, Monster[i].intY-1].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX, Monster[i].intY-1].intFloorType:=4;
          DngLvl[Monster[i].intX, Monster[i].intY-1].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

        // x+1, y-1
        if (intact=false) and (ThePlayer.intX>=Monster[i].intX+1) and (ThePlayer.intY<=Monster[i].intY-1) and (DngLvl[Monster[i].intX+1, Monster[i].intY-1].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX+1, Monster[i].intY-1].intFloorType:=4;
          DngLvl[Monster[i].intX+1, Monster[i].intY-1].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

        // x+1, y
        if (intact=false) and (ThePlayer.intX>=Monster[i].intX+1) and (ThePlayer.intY=Monster[i].intY) and (DngLvl[Monster[i].intX+1, Monster[i].intY].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX+1, Monster[i].intY].intFloorType:=4;
          DngLvl[Monster[i].intX+1, Monster[i].intY].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

        // x+1, y+1
        if (intact=false) and (ThePlayer.intX>=Monster[i].intX+1) and (ThePlayer.intY>=Monster[i].intY+1) and (DngLvl[Monster[i].intX+1, Monster[i].intY+1].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX+1, Monster[i].intY+1].intFloorType:=4;
          DngLvl[Monster[i].intX+1, Monster[i].intY+1].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

        // x, y+1
        if (intact=false) and (ThePlayer.intX=Monster[i].intX) and (ThePlayer.intY<=Monster[i].intY+1) and (DngLvl[Monster[i].intX, Monster[i].intY+1].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX, Monster[i].intY+1].intFloorType:=4;
          DngLvl[Monster[i].intX, Monster[i].intY+1].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

        // x-1, y+1
        if (intact=false) and (ThePlayer.intX<=Monster[i].intX-1) and (ThePlayer.intY>=Monster[i].intY+1) and (DngLvl[Monster[i].intX-1, Monster[i].intY+1].intFloorType=3) then
        begin
          PlaySFX('door-open.ogg');
          DngLvl[Monster[i].intX-1, Monster[i].intY+1].intFloorType:=4;
          DngLvl[Monster[i].intX-1, Monster[i].intY+1].intIntegrity:=0;
          ShowTransMessage('The ' + Monster[i].strName + ' opens the door.', False);
          intact:=true;
        end;

      end;


      // long range attacks
      if intact=false then
        if (Monster[i].intGP > 0) and (random(400) > CONST_MONSTERFIRERATE) then
          if Monster[i].blHuman = False then
            if ThePlayer.intInvis < 1 then
              if Monster[i].intPara < 1 then
              begin
                MonsterShoot(i);
                intact:=true;
              end;


      // movement and melee attacks
      if intact=false then
      begin

          oldx := Monster[i].intX;
          oldy := Monster[i].intY;

          // run away, if: 1. not frozen/paralyzed, 2. not trapped, 3a. low hp & near to player, 3b. invisible, 3c. at rand.
          if (Monster[i].intPara < 1) and (DngLvl[Monster[i].intX, Monster[i].intY].intFloorType <> 35) and
            ((Monster[i].intHP < 5) or (Monster[i].intInvis > 0) or (random(1000)>950)) then
          begin
            // run away
            if ((abs(ThePlayer.intX - Monster[i].intX) < 7) and
              (abs(ThePlayer.intX - Monster[i].intX) >= 1)) or
              ((abs(ThePlayer.intY - Monster[i].intY) < 7) and
              (abs(ThePlayer.intY - Monster[i].intY) >= 1)) then
            begin
              if (random(500) > 120) and (IsInvisible = False) then
              begin
                if (Monster[i].intX < ThePlayer.intX) and
                  (DngLvl[Monster[i].intX - 1, Monster[i].intY].intIntegrity = 0) and
                  (CheckForMonster(Monster[i].intX - 1, Monster[i].intY) = False) then
                  Dec(Monster[i].intX)
                else
                if (Monster[i].intX > ThePlayer.intX) and
                  (DngLvl[Monster[i].intX + 1, Monster[i].intY].intIntegrity = 0) and
                  (CheckForMonster(Monster[i].intX + 1, Monster[i].intY) = False) then
                  Inc(Monster[i].intX);

                if (Monster[i].intY < ThePlayer.intY) and
                  (DngLvl[Monster[i].intX, Monster[i].intY - 1].intIntegrity = 0) and
                  (CheckForMonster(Monster[i].intX, Monster[i].intY - 1) = False) then
                  Dec(Monster[i].intY)
                else
                if (Monster[i].intY > ThePlayer.intY) and
                  (DngLvl[Monster[i].intX, Monster[i].intY + 1].intIntegrity = 0) and
                  (CheckForMonster(Monster[i].intX, Monster[i].intY + 1) = False) then
                  Inc(Monster[i].intY);
              end;
            end;
          end
          else
          begin
            if Monster[i].blHuman = False then
            begin
              // next to player?
              if (DngLvl[Monster[i].intX, Monster[i].intY].intAirType <> 2) and
                (DngLvl[Monster[i].intX, Monster[i].intY].intAirType <> 6) and
                ((abs(ThePlayer.intX - Monster[i].intX) < 2) and
                (abs(ThePlayer.intY - Monster[i].intY) < 2)) then
              begin
                if (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType <> 26) and
                  (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType <> 27) then
                begin
                  if (random(500) > 420) and (IsInvisible = False) then
                  begin
                    if HitOrMiss(i) = False then
                    begin

                      intMTP := Monster[i].intWP - intDP;

                      // set item that decreases damage by 25%?
                      if CheckForItemSet(6)=true then
                        dec(intMTP, (25*intMTP) div 100);

                      if intMTP < 1 then
                        intMTP := 0;

                      if intMTP > 0 then
                        MoveMonsters :=
                          'The ' + Monster[i].strName + ' ' + Monster[i].strVerb +
                          ' [-' + IntToStr(intMTP) + 'HP].'
                      else
                        MoveMonsters :=
                          'The ' + Monster[i].strName + ' ' + Monster[i].strVerb +
                          ', but does no damage.';

                      if ThePlayer.intWall > 0 then
                      begin
                        intMTP := 0;
                        MoveMonsters :=
                          'The ' + Monster[i].strName + ' ' + Monster[i].strVerb +
                          ', but your barrier blocks the attack.';
                      end;

                      ThePlayer.intHP := ThePlayer.intHP - intMTP;

                      IncreaseDistress;

                      if ThePlayer.intHP < 1 then
                      begin
                        strMsg := lowercase(LeftStr(Monster[i].strName, 1));
                        if (strMsg = 'a') or (strMsg = 'e') or
                          (strMsg = 'u') or (strMsg = 'o') or (strMsg = 'i') then
                          GameOver('Killed by an ' + Monster[i].strName)
                        else
                          GameOver('Killed by a ' + Monster[i].strName);
                      end;
                    end
                    else
                      MoveMonsters :=
                        'The ' + Monster[i].strName + ' tries to attack you, but misses.';
                  end;
                end;
              end
              else
              begin
                // move to player
                if (DngLvl[Monster[i].intX, Monster[i].intY].intAirType <> 2) and ((Monster[i].strName='antbee') or (DngLvl[Monster[i].intX, Monster[i].intY].intAirType <> 6)) and (random(500) > 220) and (IsInvisible = False) then
                begin
                  DistanceX := abs(ThePlayer.intX - Monster[i].intX);
                  DistanceY := abs(ThePlayer.intY - Monster[i].intY);

                  if ((DistanceX <= CONST_MONSTERRECDIST) and
                    (DistanceY <= CONST_MONSTERRECDIST)) and
                    ((DistanceX > 0) or (DistanceY > 0)) then
                  begin

                    blDone := False;

                    if (Monster[i].intY < ThePlayer.intY) and
                      (Monster[i].intX < ThePlayer.intX) and
                      (DngLvl[Monster[i].intX + 1, Monster[i].intY + 1].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX + 1, Monster[i].intY + 1) =
                      False) then
                      if blDone = False then
                      begin
                        Inc(Monster[i].intX); // to SE
                        Inc(Monster[i].intY);
                        blDone := True;
                      end;

                    if (Monster[i].intY < ThePlayer.intY) and
                      (Monster[i].intX > ThePlayer.intX) and
                      (DngLvl[Monster[i].intX - 1, Monster[i].intY + 1].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX - 1, Monster[i].intY + 1) =
                      False) then
                      if blDone = False then
                      begin
                        Dec(Monster[i].intX); // to SW
                        Inc(Monster[i].intY);
                        blDone := True;
                      end;

                    if (Monster[i].intY > ThePlayer.intY) and
                      (Monster[i].intX < ThePlayer.intX) and
                      (DngLvl[Monster[i].intX + 1, Monster[i].intY - 1].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX + 1, Monster[i].intY - 1) =
                      False) then
                      if blDone = False then
                      begin
                        Inc(Monster[i].intX); // to NE
                        Dec(Monster[i].intY);
                        blDone := True;
                      end;

                    if (Monster[i].intY > ThePlayer.intY) and
                      (Monster[i].intX > ThePlayer.intX) and
                      (DngLvl[Monster[i].intX - 1, Monster[i].intY - 1].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX - 1, Monster[i].intY - 1) =
                      False) then
                      if blDone = False then
                      begin
                        Dec(Monster[i].intX); // to NW
                        Dec(Monster[i].intY);
                        blDone := True;
                      end;

                    if (Monster[i].intX < ThePlayer.intX) and
                      (DngLvl[Monster[i].intX + 1, Monster[i].intY].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX + 1, Monster[i].intY) = False) then
                      if blDone = False then
                      begin
                        Inc(Monster[i].intX);  // W to E
                        blDone := True;
                      end;

                    if (Monster[i].intX > ThePlayer.intX) and
                      (DngLvl[Monster[i].intX - 1, Monster[i].intY].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX - 1, Monster[i].intY) = False) then
                      if blDone = False then
                      begin
                        Dec(Monster[i].intX); // E to W
                        blDone := True;
                      end;

                    if (Monster[i].intY < ThePlayer.intY) and
                      (DngLvl[Monster[i].intX, Monster[i].intY + 1].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX, Monster[i].intY + 1) = False) then
                      if blDone = False then
                      begin
                        Inc(Monster[i].intY);  // N to S
                        blDone := True;
                      end;

                    if (Monster[i].intY > ThePlayer.intY) and
                      (DngLvl[Monster[i].intX, Monster[i].intY - 1].intIntegrity = 0) and
                      (CheckForMonster(Monster[i].intX, Monster[i].intY - 1) = False) then
                      if blDone = False then
                      begin
                        Dec(Monster[i].intY); // S to N
                        blDone := True;
                      end;
                  end;
                end;
              end;
            end
            else
            begin
              // randomly move humans and non-hostile enemies
              j := trunc(random(10));
              if (j = 0) and (DngLvl[Monster[i].intX, Monster[i].intY + 1].intIntegrity =
                0) and (CheckForMonster(Monster[i].intX, Monster[i].intY + 1) = False) then
                Inc(Monster[i].intY);
              if (j = 1) and (DngLvl[Monster[i].intX, Monster[i].intY - 1].intIntegrity =
                0) and (CheckForMonster(Monster[i].intX, Monster[i].intY - 1) = False) then
                Dec(Monster[i].intY);
              if (j = 2) and (DngLvl[Monster[i].intX + 1, Monster[i].intY].intIntegrity =
                0) and (CheckForMonster(Monster[i].intX + 1, Monster[i].intY) = False) then
                Inc(Monster[i].intX);
              if (j = 3) and (DngLvl[Monster[i].intX - 1, Monster[i].intY].intIntegrity =
                0) and (CheckForMonster(Monster[i].intX - 1, Monster[i].intY) = False) then
                Dec(Monster[i].intX);
            end;
          end;

          // water monsters only on water
          if (DngLvl[Monster[i].intX, Monster[i].intY].intFloorType <> 5) and
            (Monster[i].blWater = True) then
          begin
            Monster[i].intX := oldx;
            Monster[i].intY := oldy;
          end;

          // non-water monsters only on land
          if (DngLvl[Monster[i].intX, Monster[i].intY].intFloorType = 5) and
            (Monster[i].blWater = False) then
          begin
            Monster[i].intX := oldx;
            Monster[i].intY := oldy;
          end;

          // antbees may weave a web
          if Monster[i].strName='antbee' then
          begin
            if random(500)>450 then
            begin
              if (DngLvl[Monster[i].intX, Monster[i].intY].intAirType=0) and (DngLvl[Monster[i].intX, Monster[i].intY].intFloorType=2) then
              begin
                if DngLvl[Monster[i].intX, Monster[i].intY].intAirRange<12 then
                begin
                  DngLvl[Monster[i].intX, Monster[i].intY].intAirType:=6;
                  DngLvl[Monster[i].intX, Monster[i].intY].intAirRange:=10 + trunc(random(5));
                  //Writeln('The antbee at '+ IntToStr(Monster[i].intX) + '/' + IntToStr(Monster[i].intY) +' weaves a sticky web.');
                end;
              end;
            end;
          end;

      end;
    end;
  end;


  // Here all special effects (confusion, poison, curse etc.) are ticking
  procedure EffectTicker;
  begin

    // freeze time
    if ThePlayer.intFreeze > 0 then
      Dec(ThePlayer.intFreeze);


    if ThePlayer.intFreeze = 0 then
    begin

      // confusion
      if ThePlayer.intConfusion > 0 then
        Dec(ThePlayer.intConfusion);


      // poison
      if ThePlayer.intPoison > 0 then
      begin
        Dec(ThePlayer.intPoison);
      end;


      // paralyze
      if ThePlayer.intPara > 0 then
        Dec(ThePlayer.intPara);


      // calm
      if ThePlayer.intCalm > 0 then
        Dec(ThePlayer.intCalm);


      // invisibility
      if ThePlayer.intInvis > 0 then
        Dec(ThePlayer.intInvis);


      // blindness
      if ThePlayer.intBlind > 0 then
        Dec(ThePlayer.intBlind);


      // wall
      if ThePlayer.intWall > 0 then
        Dec(ThePlayer.intWall);

      // strength drug addiction symptoms
      if ThePlayer.intNextVitari > 0 then
      begin
        Inc(ThePlayer.intNeedVitari);
        if ThePlayer.intNeedVitari >= ThePlayer.intNextVitari then
        begin
          if (random(100) > 50) and (ThePlayer.intPP > 0) then
            Dec(ThePlayer.intPP);
          if random(100) > 50 then
          begin
            Dec(ThePlayer.intHP);
          end;
          if random(100) > 50 then
            Inc(ThePlayer.intStrength);
        end;
      end;

    end;
  end;



  // actions of gods (depending on number of prayers, humility skill and number of turns)
  procedure GodAction;
  begin

    if ThePlayer.blEvil = False then
    begin
      if longTotalTurns > 100 then
      begin

        // curse player
        if (longTotalTurns > CONST_MINTURNFORCURSE) and
          (ThePlayer.longPrayers = 0) then
        begin

          ShowDialog(uppercase(ThePlayer.strReli),
            ThePlayer.strName +
            ', have your forgotten Us? For many days We''ve been calling your',
            'name, yet you keep quiet. None of your thoughts are directed towards Us.',
            'Tell Us, human, don''t you remember that We created you? All your skills',
            'depend on Our favor! Your ignorance fills Our heart with sadness and Our eyes',
            'with tears. ' + ThePlayer.strName +
            ', can''t you feel Our suffering...?', True);

          ShowTransMessage('You never honored your deity; now ' +
            ThePlayer.strReli + ' is angry with you!', False);
          Inc(ThePlayer.longPrayers, 1);
          // increase prayers to avoid repetition of this action
          Dec(ThePlayer.intHumility, 3);
          if CollectHumility < 1 then
          begin
            ThePlayer.blCurse := True;
            ThePlayer.blBlessed := False;
          end;
        end;

        // TODO: don't hardcode this; instead use the "AffectedStatus" / "AffectedSkill" properties of the class

        // give player bonus 1
        if (ThePlayer.longPrayers > 10) and (CollectHumility > 4) and
          (CollectHumility < 7) then
        begin

          ShowDialog(uppercase(ThePlayer.strReli),
            ThePlayer.strName +
            ', your constant faithfulness is a bright glow of hope in',
            'mankind''s agonizing world. Our heart is enthralled, by the joy of liste-',
            'ning to your prayers and of watching your growing humility. Thus, We offer',
            'you a gift to further deepen our relationship, and to help you in your',
            'noble task. ' + ThePlayer.strName +
            ', may all people follow your example...', True);

          case ThePlayer.intReli of
            1:
            begin   // Aphrodite
              Inc(ThePlayer.intMaxPP, CollectHumility + trunc(random(CollectHumility)));
              ThePlayer.intPP := ThePlayer.intMaxPP;
            end;
            2:
            begin   // Hermes
              Inc(ThePlayer.longExp, CollectHumility * 30);
              Inc(ThePlayer.longThisLevelEXP, CollectHumility * 30);
            end;
            3:
            begin   // Apoll
              Inc(ThePlayer.longGold, CollectHumility * 30);
            end;
            4:
            begin   // Dionysa
              Inc(ThePlayer.longFood, CollectHumility * 50);
            end;
            5:
            begin   // Ares
              Inc(ThePlayer.intMaxHP, CollectHumility + trunc(random(CollectHumility)));
              ThePlayer.intHP := ThePlayer.intMaxHP;
            end;
          end;

          ThePlayer.intHumility := 7;
          ShowTransMessage('Your relation to ' + ThePlayer.strReli + ' improves.', False);
        end;

        // give player bonus 2
        if (ThePlayer.longPrayers > 500) and (CollectHumility > 12) and (CollectHumility < 15) then
        begin

          ShowDialog(uppercase(ThePlayer.strReli),
            ThePlayer.strName +
            '! Again you have proven to be one of a few of your kind',
            'who indeed show real faith in Our actions. You have sacrificed time and goods',
            'to strengthen our relationship. Instead of spending all your time with use-',
            'less training of skills or personal abilities, you''re exercising yourself in',
            'humility. This shall not go unrewarded. Take again Our gift!',
            True);

          case ThePlayer.intReli of
            1:
            begin   // Aphrodite
              Inc(ThePlayer.intChant, 2);
            end;
            2:
            begin   // Hermes
              Inc(ThePlayer.intBurgle, 2);
            end;
            3:
            begin   // Apoll
              Inc(ThePlayer.intView, 2);
            end;
            4:
            begin   // Dionysa
              Inc(ThePlayer.intMove, 2);
            end;
            5:
            begin   // Ares
              Inc(ThePlayer.intFight, 2);
            end;
          end;

          ThePlayer.intHumility := 15;
          ShowTransMessage('Your relation to ' + ThePlayer.strReli + ' improves again.', False);
        end;

      end;
    end;
  end;



  // here the next turn after a player action is calculated
  function NextTurn(): boolean;
  var
    n, i, j: integer;
    TraderTypeOK: boolean;
    dummy: string;
  begin

    //writeln('Next turn processing ...');

    NextTurn := False;        // true if player is dead
    dummy := '';
    Inc(longTotalTurns);
    // the total number of turns the game is lasting is increased by 1

    // make current map position known to player
    if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType <> 5 then
      DngLvl[ThePlayer.intX, ThePlayer.intY].blKnown := True;

    // do the following only if time is not frozen
    if ThePlayer.intFreeze = 0 then
    begin
      // effects (like poison, barrier, confusion...)
      // temporary resistances are processed further below
      EffectTicker;

      // if player has low humility and is not yet evil, make him so
      if CollectHumility < -5 then
        ThePlayer.blEvil := True
      else
        ThePlayer.blEvil := false;

      If ThePlayer.longPrayers<0 then
        ThePlayer.longPrayers:=0;

      // move monsters
      dummy := MoveMonsters;

      // if paper item stands within fire or on lava, destroy it
      for i:=1 to DngMaxWidth do
        for j:=1 to DngMaxHeight do
        begin
            // item in fire aura
            if DngLvl[i,j].intAirType=1 then
            begin
              if DngLvl[i,j].intItem>0 then
              begin
                if Thing[DngLvl[i,j].intItem].chLetter = chr(193) then
                begin
                  ShowTransMessage('The '+Thing[DngLvl[i,j].intItem].strName+' is destroyed in the fire aura.', false);
                  DngLvl[i,j].intItem:=0;
                end;

                if Thing[DngLvl[i,j].intItem].chLetter = chr(37) then
                begin
                  ShowTransMessage('The ' + Thing[DngLvl[i,j].intItem].strName +' is roasted.', false);
                  DngLvl[i,j].intItem:=ReturnItemByName('Meat');
                end;
              end;
            end;

            // item on lava
            if DngLvl[i,j].intFloorType=20 then
            begin
              if DngLvl[i,j].intItem>0 then
              begin
                if Thing[DngLvl[i,j].intItem].chLetter = chr(193) then
                begin
                  ShowTransMessage('The lava burns the '+Thing[DngLvl[i,j].intItem].strName+'.', false);
                  DngLvl[i,j].intItem:=0;
                end;

                if Thing[DngLvl[i,j].intItem].chLetter = chr(37) then
                begin
                  ShowTransMessage('The ' + Thing[DngLvl[i,j].intItem].strName +' is roasted in the lava.', false);
                  DngLvl[i,j].intItem:=ReturnItemByName('Meat');
                end;
              end;
            end;
         end;

      // if monster hive stands within fire aura, decrease its integrity
      if (HiveX > -1) and (HiveY > -1) then
        if DngLvl[HiveX, HiveY].intAirType = 1 then
          if DngLvl[HiveX, HiveY].intIntegrity > 0 then
          begin
            Dec(DngLvl[HiveX, HiveY].intIntegrity,
              DngLvl[HiveX, HiveY].intAirRange);
            if DngLvl[HiveX, HiveY].intIntegrity < 1 then
            begin
              DngLvl[HiveX, HiveY].intFloorType := 2;
              HiveDestroyed;
            end;
          end;

      // regain HP, if item with HP regeneration (.intEffect=4) is worn
      if dummy = '' then
        if CheckEffect(4) = True then
          if ThePlayer.intHP < ThePlayer.intMaxHP then
            Inc(ThePlayer.intHP);

      // regain PP, if item with PP regeneration (.intEffect=3) is worn
      if dummy = '' then
        if CheckEffect(3) = True then
          if ThePlayer.intPP < ThePlayer.intMaxPP then
            Inc(ThePlayer.intPP);

      // regain HP and PP, if item with HP/PP regeneration (.intEffect=53) is worn
      if dummy = '' then
        if CheckEffect(53) = True then
        begin
          if ThePlayer.intHP < ThePlayer.intMaxHP then
            Inc(ThePlayer.intHP);
          if ThePlayer.intPP < ThePlayer.intMaxPP then
            Inc(ThePlayer.intPP);
        end;

      // regain PP, if sitting on a stool
      if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 50 then
        if ThePlayer.intPP < ThePlayer.intMaxPP then
          Inc(ThePlayer.intPP);

      // reduce temporary resistances
      for i := 1 to 100 do
        if ThePlayer.intTempResist[i] > 0 then
          Dec(ThePlayer.intTempResist[i]);

      // refresh chants
      for i := 1 to 12 do
        if spellbook[i].intType > 0 then
          if spellbook[i].intRefresh < spell[spellbook[i].intType].intRefresh then
            Inc(spellbook[i].intRefresh);

      // decrease food

      // set boni
      if CheckForItemSet(7) = false then
        Dec(ThePlayer.longFood);

      // if food is below 200, decrease strength until it is 0
      if (ThePlayer.longFood < 200) and (ThePlayer.intStrength > 0) then
        Dec(ThePlayer.intStrength);

      // if food is greater than 199 and strength is less then 100, increase strength
      if (ThePlayer.longFood > 199) and (ThePlayer.intStrength < 100) then
        Inc(ThePlayer.intStrength);

      // if strength is less than the minimum needed strength for the current weapon, unequip the weapon
      if ThePlayer.intWeapon > 0 then
        if (ThePlayer.intStrength < Thing[ThePlayer.intWeapon].intStrength) then
        begin
          DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ThePlayer.intWeapon;
          ThePlayer.intWeapon := 0;
          ThePlayer.intWeaponMod := 0;
          GetKeyInput('You are too weak to carry your weapon.', True);
        end;

      // gods
      GodAction;

      // if food < 1 then let the player die from starving
      if ThePlayer.longFood < 1 then
      begin
        GetKeyInput('You die from starvation.', True);
        ThePlayer.intHP := 0;
        GameOver('Died from starvation');
      end;

      // if the player is poisoned, decrease HP by current poison value
      if ThePlayer.intPoison > 0 then
      begin
        Dec(ThePlayer.intHP, ThePlayer.intPoison);
        if ThePlayer.intHP < 1 then
        begin
          GetKeyInput('You die from poison.', True);
          GameOver('Poisoned to death');
        end;
      end;

      // if strength is greater than 100, a strength drug is used
      if ThePlayer.intStrength > 100 then
      begin
        // do negative effects on HP, if drug is used to extensivly
        if trunc(random(ThePlayer.intStrength - 100)) > trunc(
          random(ThePlayer.intStrength)) then
          Dec(ThePlayer.intHP, 1 + trunc(random(3)));
        Dec(ThePlayer.intStrength);
      end;

      // if player is walking on lava, decrease player's HP
      if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 20 then
        if ThePlayer.blEvil = False then
          if CheckEffect(13) = False then
          begin
            BurnInventoryItem;
            Dec(ThePlayer.intHP, 2);
            if ThePlayer.intHP < 1 then
            begin
              GetKeyInput('The lava hurts you to death.', True);
              GameOver('Died while walking through lava');
            end;
          end;

      // if the player is walking through heal aura air, increase his HP
      if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 4 then
        if ThePlayer.blEvil = False then
        begin
          Inc(ThePlayer.intHP, DngLvl[ThePlayer.intX, ThePlayer.intY].intAirRange);
          if ThePlayer.intHP > ThePlayer.intMaxHP then
            ThePlayer.intHP := ThePlayer.intMaxHP;
        end;

      // if the player is on a trap, do something and reveal trap
      if (DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 7) or (DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 8) then
      begin
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 7 then
          DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType := 8;
        DoEffect(DngLvl[ThePlayer.intX, ThePlayer.intY].intAirRange, ThePlayer.intHP div 4, 'You step on a trap!');
      end;


      if ThePlayer.intHP < 1 then
        NextTurn := True;

      // if air is affected by auras (except darkness), reduce the amount (1 per turn, until it's cleaned)
      for i := 1 to DngMaxWidth do
        for j := 1 to DngMaxHeight do
          if DngLvl[i, j].intAirRange > 0 then
            if (DngLvl[i, j].intAirType <> 5) and (DngLvl[i, j].intAirType <> 7) and (DngLvl[i, j].intAirType <> 8) then
            begin
              Dec(DngLvl[i, j].intAirRange);
              if DngLvl[i, j].intAirRange < 1 then
                DngLvl[i, j].intAirType := 0;
            end;


      // refill shops (1-4)
      if (longTotalTurns = 1) or (random(500) > 480) then
        for i := 1 to 4 do     // shop number ...
          for j := 1 to 16 do  // shop items
          begin
            TraderTypeOK := False;
            repeat

              repeat
                n := trunc(random(ItemCount) + 1);
                //                             writeln('Item '+IntToStr(n));
              until (Thing[n].intMinLvl <= DungeonLevel) and (Thing[n].blRare=false) and (Thing[n].blUnique=false);

              //if n = 0 then
              //  n := ItemCount;

              // add items to shop depending on the current shop number (which is the trader type)


              // food
              if (i = 1) and (Thing[n].blRing = False) and
                (Thing[n].blWield = False) and (Thing[n].blWear = False) and
                (Thing[n].blHat = False) and ((Thing[n].blEat = True) or
                (Thing[n].blBarricade = True) or (Thing[n].blDrink = True)) then
                TraderTypeOK := True;

              // weapons and tools
              if (i = 2) and (TraderTypeOK = False) and
                (Thing[n].blEat = False) and (Thing[n].blDrink = False) and
                (Thing[n].blWear = False) and (Thing[n].blHat = False) and
                ((Thing[n].blWield = True) or (Thing[n].blRing = True) or
                (Thing[n].intIsAmmu > 0) or (Thing[n].chLetter = chr(191))) then
                TraderTypeOK := True;

              // armour
              if (i = 3) and (TraderTypeOK = False) and
                (Thing[n].blEat = False) and (Thing[n].blDrink = False) and
                (Thing[n].blWield = False) and
                ((Thing[n].blWear = True) or (Thing[n].blShoes = True) or
                (Thing[n].blHat = True) or (Thing[n].blExtra = True)) then
                TraderTypeOK := True;

              // magic and books
              if (i = 4) and (TraderTypeOK = False) and
                ((Thing[n].chLetter = chr(161)) or (Thing[n].chLetter = chr(193))) then
                TraderTypeOK := True;
            until TraderTypeOK = True;

            // make sure that we only put non-unique and non-rare items in the shop
            if (Thing[n].blUnique = False) and (Thing[n].blRare = False) then
              MyShop[i].Inventory[j].intType := n
            else
              MyShop[i].Inventory[j].intType := 0;
          end;

      // calculate time, day and year
      if intDayTime < 250 then
        Inc(intDayTime);

      if intDayTime = 250 then
      begin
        if intDay < 21 then
          Inc(intDay);
        intDayTime := 1;
      end;

      if intDay = 21 then
      begin
        Inc(longYear);
        intDay := 1;
      end;

      // respawn monsters
      if DungeonLevel > 1 then
        if (GetTotalMonsters < MaxMonster) and (GetFirstFreeMonsterID > -1) and
          (random(500) > CONST_SPAWN) then
          CreateMonster(GetFirstFreeMonsterID, '-', DungeonLevel);

    end;

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    ShowTransMessage(dummy, False);

  end;


  // rest
  procedure Rest;
  var
    i, n: integer;
  begin
    Val(GetTextInput('How long do you want to rest?', 4), n);

    i := 1;

    while (i <= n) and (ThePlayer.intHP>0) do
    begin
      ShowTransMessage('Resting (turn ' + IntToStr(i) + ' of ' +
        IntToStr(n) + ') ...', False);
      NextTurn;
      Inc(i);
    end;
  end;


  // identify tile
  procedure IdentifyTile;
  var
    chDir: char;
    lookX, lookY, i: integer;
    strDir: string;
  begin
    chDir := GetDirection(0);

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

    if chDir = KeyNorth then
    begin
      lookX := ThePlayer.intX;
      lookY := ThePlayer.intY - 1;
      strDir := 'north';
    end;

    if chDir = KeySouth then
    begin
      lookX := ThePlayer.intX;
      lookY := ThePlayer.intY + 1;
      strDir := 'south';
    end;

    if chDir = KeyEast then
    begin
      lookX := ThePlayer.intX + 1;
      lookY := ThePlayer.intY;
      strDir := 'east';
    end;

    if chDir = KeyWest then
    begin
      lookX := ThePlayer.intX - 1;
      lookY := ThePlayer.intY;
      strDir := 'west';
    end;

    if chDir = KeyNorthEast then
    begin
      lookX := ThePlayer.intX + 1;
      lookY := ThePlayer.intY - 1;
      strDir := 'northeast';
    end;

    if chDir = KeySouthEast then
    begin
      lookX := ThePlayer.intX + 1;
      lookY := ThePlayer.intY + 1;
      strDir := 'southeast';
    end;

    if chDir = KeyNorthWest then
    begin
      lookX := ThePlayer.intX - 1;
      lookY := ThePlayer.intY - 1;
      strDir := 'northwest';
    end;

    if chDir = KeySouthWest then
    begin
      lookX := ThePlayer.intX - 1;
      lookY := ThePlayer.intY + 1;
      strDir := 'southwest';
    end;

    case DngLvl[lookX, lookY].intFloorType of
      1:
        msg1 := 'a wall';
      2:
        msg1 := 'plain floor';
      3:
      begin
        if (DungeonLevel = 26) or (DungeonLevel = 27) then
          msg1 := 'an active force field'
        else
          msg1 := 'a closed door';
      end;
      4:
      begin
        if (DungeonLevel = 26) or (DungeonLevel = 27) then
          msg1 := 'an inactive force field generator'
        else
          msg1 := 'an open door';
      end;
      5:
        msg1 := 'water';
      6:
      begin
        if DungeonLevel = 1 then
          msg1 := 'a mountain'
        else
          msg1 := 'solid rock';
      end;
      7:
        msg1 := 'a closed treasure chest';
      8:
        msg1 := 'a staircase to the previous dungeon level';
      9:
        msg1 := 'a staircase to a deeper dungeon level';
      10:
        msg1 := 'a small tree';
      11:
        msg1 := 'worm excrements';
      12:
        msg1 := 'mud or sand';
      13:
        msg1 := 'a big tree';
      14:
        msg1 := 'an open treasure chest';
      15:
        msg1 := 'an altar';
      16:
        msg1 := 'plain floor';
      17:
        msg1 := 'grass';
      18:
        msg1 := 'a hill';
      19:
        msg1 := 'ash';
      20:
        msg1 := 'lava';
      21:
        msg1 := 'a small dry tree';
      22:
        msg1 := 'a big dry tree';
      23:
        msg1 := 'dry grass';
      24:
      begin
        if (DungeonLevel <> 6) and (DungeonLevel <> 7) then
          msg1 := 'a locked door'
        else
          msg1 := 'a closed iron gate';
      end;
      25:
        msg1 := 'a wall';
      26:
        msg1 := 'a crypt';
      27:
        msg1 := 'a wall';
      28:
        msg1 := 'an enchanted well';
      29:
        msg1 := 'a terminal';
      30:
        msg1 := 'plain floor';
      31:
        msg1 := 'contaminated ground';
      32:
        msg1 := 'a wall';
      33:
        msg1 := 'a crypt';
      34:
        msg1 := 'a monster' + chr(39) + 's hive [Integrity: ' +
          IntToStr(DngLvl[lookX, lookY].intIntegrity) + ']';
      35:
        msg1 := 'one of your traps';
      36:
        msg1 := 'sand';
      37:
        msg1 := 'sand';
      38:
        msg1 := 'shore';
      39:
        msg1 := 'shore';
      40:
        msg1 := 'shallow water';
      41:
        msg1 := 'sand';
      42:
        msg1 := 'sand';
      48:
        msg1 := 'just a wall';
      49:
        msg1 := 'a bookshelf';
      50:
        msg1 := 'a stool';
      51:
        msg1 := 'a table';
      52:
        msg1 := 'a barrel';
      53:
        msg1 := 'a big mushroom';
      54:
        msg1 := 'a small mushroom';
      55:
        msg1 := 'wooden garbage';
      56:
        msg1 := 'a gas cylinder';
      57:
        msg1 := 'machine oil';
      58:
        msg1 := 'old metal parts';
      59:
        msg1 := 'a magical portal';
      60:
        msg1 := 'snow';
      61:
        msg1 := 'ice';
      62:
        msg1 := 'an old staircase';
      63:
        msg1 := 'an old staircase';
      64:
        msg1 := 'a closed iron gate';
      65:
        msg1 := 'an open iron gate';
      66:
        msg1 := 'a ladder';
      67:
        msg1 := 'a ladder';
    end;

    if DngLvl[lookX, lookY].intAirType=8 then
      msg1 := 'a trap';

    ShowTransMessage('In the ' + strDir + ', you see ' + msg1 + '.', False);

    for i:=1 to 510 do
    begin
      if (Monster[i].intX=lookX) and (Monster[i].intY=lookY) then
      begin
        ShowTransMessage('There is a '+Monster[i].strName+' in the ' + strDir + '. ' + '[HP/PP: '+ IntToStr(Monster[i].intHP) + '/' + IntToStr(Monster[i].intPP) + '   WP/GP/AP: ' + IntToStr(Monster[i].intWP) + '/' + IntToStr(Monster[i].intGP) + '/' + IntToStr(Monster[i].intAP)+']', false);
      end;
    end;

  end;


  // select which item to steal
  procedure StealSelection(intID: integer);
  var
    i, t: integer;
    n, p: longint;
    ch, dummy, equi: string;
    blRemItem, blCloseSteal: boolean;
  begin

    blCloseSteal := False;
    repeat
      DecoIcon.w := 80;
      DecoIcon.y := 80;
      DecoIcon.h := 80;

      case intID of
        1:
          DecoIcon.x := 360;
        2:
          DecoIcon.x := 280;
        3:
        begin
          DecoIcon.x := 220;
          DecoIcon.w := 60;
        end;
        4:
          DecoIcon.x := 0;
      end;

      DecoIconS.x := 711 + HiResOffsetX;
      DecoIconS.y := 400 + HiResOffsetY;
      DecoIconS.w := 72;
      DecoIconS.h := 72;

      ClearScreenSDL;

      if UseSDL = True then
      begin
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        DarkenScreen;
        LoadImage_Title('graphics/invbg.jpg');
      end;

      repeat
        if UseSDL = True then
        begin
          BlitImage_Title;
          SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
        end
        else
        begin
          DialogWin;
          StatusDeco;
        end;


        TransTextXY(1, 1, 'STEAL FROM ' + uppercase(Shops[MyShop[intID].intType]));

        for i := 1 to 16 do
        begin
          if MyShop[intID].Inventory[i].intType > 0 then
          begin

            p := CollectBuyPrice(MyShop[intID].Inventory[i].intType);

            TransTextXY(6, 4 + i, IntToStr(i));

            SetItemNameColor (thing[MyShop[intID].Inventory[i].intType].strRealName); // item name color
            TransTextXY(10, 4 + i, thing[MyShop[intID].Inventory[i].intType].chLetter +
              ' ' + thing[MyShop[intID].Inventory[i].intType].strRealName);

            GlobalFontColor := FONTCOLOR_WHITE;
            GlobalConColor := -1;


            TransTextXY(40, 4 + i, '$' + IntToStr(p));

            equi := '';

            // mark items with + - =
            if ThePlayer.intArmour > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intAP > 0 then
                if thing[MyShop[intID].Inventory[i].intType].blWear = True then
                begin
                  if thing[MyShop[intID].Inventory[i].intType].intAP >
                    thing[ThePlayer.intArmour].intAP then
                    equi := ' ' + chr(214);
                  if thing[MyShop[intID].Inventory[i].intType].intAP <
                    thing[ThePlayer.intArmour].intAP then
                    equi := ' ' + chr(215);
                  if thing[MyShop[intID].Inventory[i].intType].intAP =
                    thing[ThePlayer.intArmour].intAP then
                    equi := ' ' + chr(216);
                end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified =
                False then
                if thing[MyShop[intID].Inventory[i].intType].blWear = True then
                  equi := ' ' + chr(217);
            end;

            if ThePlayer.intHat > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intAP > 0 then
                if thing[MyShop[intID].Inventory[i].intType].blHat = True then
                begin
                  if thing[MyShop[intID].Inventory[i].intType].intAP >
                    thing[ThePlayer.intHat].intAP then
                    equi := ' ' + chr(214);
                  if thing[MyShop[intID].Inventory[i].intType].intAP <
                    thing[ThePlayer.intHat].intAP then
                    equi := ' ' + chr(215);
                  if thing[MyShop[intID].Inventory[i].intType].intAP =
                    thing[ThePlayer.intHat].intAP then
                    equi := ' ' + chr(216);
                end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified =
                False then
                if thing[MyShop[intID].Inventory[i].intType].blHat = True then
                  equi := ' ' + chr(217);
            end;

            if ThePlayer.intWeapon > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intWP > 0 then
                if thing[ThePlayer.intWeapon].intWP > 0 then
                  if thing[MyShop[intID].Inventory[i].intType].blWield =
                    True then
                  begin
                    if thing[MyShop[intID].Inventory[i].intType].intWP >
                      thing[ThePlayer.intWeapon].intWP then
                      equi := ' ' + chr(214);
                    if thing[MyShop[intID].Inventory[i].intType].intWP <
                      thing[ThePlayer.intWeapon].intWP then
                      equi := ' ' + chr(215);
                    if thing[MyShop[intID].Inventory[i].intType].intWP =
                      thing[ThePlayer.intWeapon].intWP then
                      equi := ' ' + chr(216);
                  end;

              if thing[MyShop[intID].Inventory[i].intType].intGP > 0 then
                if thing[ThePlayer.intWeapon].intGP > 0 then
                  if thing[MyShop[intID].Inventory[i].intType].blWield =
                    True then
                  begin
                    if thing[MyShop[intID].Inventory[i].intType].intGP >
                      thing[ThePlayer.intWeapon].intGP then
                      equi := ' ' + chr(214);
                    if thing[MyShop[intID].Inventory[i].intType].intGP <
                      thing[ThePlayer.intWeapon].intGP then
                      equi := ' ' + chr(215);
                    if thing[MyShop[intID].Inventory[i].intType].intGP =
                      thing[ThePlayer.intWeapon].intGP then
                      equi := ' ' + chr(216);
                  end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified =
                False then
                if thing[MyShop[intID].Inventory[i].intType].blWield = True then
                  equi := ' ' + chr(217);
            end;

            // mark items with a higher clvl
            if ThePlayer.intLvl < Thing[MyShop[intID].Inventory[i].intType].intCharLvl then
              equi := ' ' + chr(218);

            TransTextXY(45, 4 + i, equi);

            // mark items with a higher skill
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(156)) then
              if ThePlayer.intSword <
                Thing[MyShop[intID].Inventory[i].intType].intWP then
                TransTextXY(52, 4 + i, 'Skill!');
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(159)) then
              if ThePlayer.intAxe <
                Thing[MyShop[intID].Inventory[i].intType].intWP then
                TransTextXY(52, 4 + i, 'Skill!');
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(164)) then
              if ThePlayer.intWhip <
                Thing[MyShop[intID].Inventory[i].intType].intWP then
                TransTextXY(52, 4 + i, 'Skill!');
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(158)) then
              if ThePlayer.intGun <
                Thing[MyShop[intID].Inventory[i].intType].intGP then
                TransTextXY(52, 4 + i, 'Skill!');

            // mark useless items
            if (ThePlayer.intProf <>
              Thing[MyShop[intID].Inventory[i].intType].intProf) and
              (Thing[MyShop[intID].Inventory[i].intType].intProf > 0) then
            begin
              case Thing[MyShop[intID].Inventory[i].intType].intProf of
                //1:
                //  TransTextXY(59, 4 + i, 'Constructor!');
                2:
                  TransTextXY(59, 4 + i, 'Enchanter!');
                3:
                  TransTextXY(59, 4 + i, 'Thief!');
                4:
                  TransTextXY(59, 4 + i, 'Archer!');
                5:
                  TransTextXY(59, 4 + i, 'Soldier!');
              end;
            end;

          end;
        end;

        n := -1;

        dummy := GetKeyInput(
          '[s]teal item  [i]nfo about item  [I]nventory', False);

      until (dummy = 's') or (dummy = 'i') or (dummy = 'I') or (dummy = 'ESC');

      ch := dummy;

      if dummy = 'ESC' then
      begin
        ch := '-';
        blCloseSteal := true;
      end;

      if ch = 'i' then
      begin
        if (UseSDL = False) or (UseMouseToMove = False) then
          repeat
            Val(GetTextInput(
              'Enter the number of the item you wish to see [ENTER to cancel]:', 2), n);
          until (n = 0) or ((n > 0) and (n < 17) and
              (MyShop[intID].Inventory[n].intType > 0));

        if n > 0 then
          ItemInfo(MyShop[intID].Inventory[n].intType);
      end;

      if ch = 'I' then
        ShowInventory;

      if ch = 's' then
      begin
        if (UseSDL = False) or (UseMouseToMove = False) then
          repeat
            Val(GetTextInput(
              'Enter the number of the item you wish to steal [ENTER to cancel]:', 2), n);
          until (n = 0) or ((n > 0) and (n < 17) and
              (MyShop[intID].Inventory[n].intType > 0));

        if n > 0 then
        begin

          t := MyShop[intID].Inventory[n].intType;

          blRemItem := False;

          // check if player already has one item of this type
          for i := 1 to 16 do
            if inventory[i].intType = t then
            begin
              Inc(inventory[i].longNumber, Thing[Inventory[i].intType].intAmount);
              blRemItem := True;
              break;
            end;

          // if item not bought, check if free space available
          if blRemItem = False then
            for i := 1 to 16 do
              if (inventory[i].intType = 0) and (blRemItem = False) then
              begin
                inventory[i].intType := t;
                inventory[i].longNumber := Thing[Inventory[i].intType].intAmount;

                if ThePlayer.intDipl[14]=1 then
                  inc(inventory[i].longNumber);

                blRemItem := True;
                break;
              end;

          // if item taken, identify item type and remove item from store
          if blRemItem then
          begin
            Thing[MyShop[intID].Inventory[n].intType].blIdentified := True;
            Thing[MyShop[intID].Inventory[n].intType].strName :=
              Thing[MyShop[intID].Inventory[n].intType].strRealName;
            MyShop[intID].Inventory[n].intType := 0;
            blTodayStolenTrader := True;
            GetKeyInput('You steal the ' + Thing[t].strName + '.', True);
            blCloseSteal := True;
          end
          else
            GetKeyInput('You want to steal the ' + Thing[t].strName +
              ', but your inventory is full.', True);

        end;
      end;
    until blCloseSteal = True;

    ClearScreenSDL;
  end;


  procedure TrainSkill(points: integer);
  var
    dummy: string;
    ch: char;
  begin

    if UseSDL = True then
    begin
      TempAnsi := 'graphics/invbg.jpg';
      LoadImage_Title('graphics/invbg.jpg');
    end;

    while points > 0 do
    begin

      repeat
        if UseSDL = True then
          BlitImage_Title
        else
        begin
          ClearScreenSDL;
          DialogWin;
          StatusDeco;
        end;

        TransTextXY(1, 1, 'SKILL TRAINING');
        TransTextXY(8, 7, IntToStr(points) + ' skill point(s) left.');

        TransTextXY(8, 9,
          'a  Fight     influences your general skills in combat      [' +
          IntToStr(ThePlayer.intFight) + ']');
        TransTextXY(8, 10,
          'b  Hit       determines if long-range attacks hit or miss  [' +
          IntToStr(ThePlayer.intView) + ']');
        TransTextXY(8, 11,
          'c  Chant     determines the success of casting a chant     [' +
          IntToStr(ThePlayer.intChant) + ']');
        TransTextXY(8, 12,
          'd  Move      influences your ability to evade attacks      [' +
          IntToStr(ThePlayer.intMove) + ']');
        TransTextXY(8, 13,
          'e  Steal     allows stealing without being caught          [' +
          IntToStr(ThePlayer.intBurgle) + ']');
        TransTextXY(8, 14,
          'f  Sword     determines your ability to use sword          [' +
          IntToStr(ThePlayer.intSword) + ']');
        TransTextXY(8, 15,
          'g  Axe       determines your ability to use axes           [' +
          IntToStr(ThePlayer.intAxe) + ']');
        TransTextXY(8, 16,
          'h  Lance     determines your ability to use lances         [' +
          IntToStr(ThePlayer.intWhip) + ']');
        TransTextXY(8, 17,
          'i  Fire-arm  determines your ability to use bows           [' +
          IntToStr(ThePlayer.intGun) + ']');
        TransTextXY(8, 18,
          'j  Tool      determines your ability to use spades         [' +
          IntToStr(ThePlayer.intTool) + ']');
        TransTextXY(8, 19,
          'k  Humility  affects the DST cost of divine rage           [' +
          IntToStr(ThePlayer.intHumility) + ']');
        TransTextXY(8, 20,
          'l  Trade     gives you advantages when buying or selling   [' +
          IntToStr(ThePlayer.intTrade) + ']');

        ch := ' ';
        dummy := GetKeyInput(
          'Select the skill to train by pressing the related button.', False);
      until (dummy = 'a') or (dummy = 'b') or (dummy = 'c') or
        (dummy = 'd') or (dummy = 'e') or (dummy = 'f') or (dummy = 'g') or
        (dummy = 'h') or (dummy = 'i') or (dummy = 'j') or (dummy = 'k') or
        (dummy = 'l');
      ch := dummy[1];

      case ch of
        'a':
          Inc(ThePlayer.intFight, 1);
        'b':
          Inc(ThePlayer.intView, 1);
        'c':
        begin
          Inc(ThePlayer.intChant, 1);
          if ThePlayer.intChant=1 then
          begin
            ThePlayer.blQuiet:=false;
            ThePlayer.intMaxPP:=20;
            ThePlayer.intPP:=20;
            GetKeyInput('Finally, the curse of your youth is removed -- you can chant!', false);
            StoreAchievement('Removed the quietness curse');
          end;
        end;
        'd':
          Inc(ThePlayer.intMove, 1);
        'e':
          Inc(ThePlayer.intBurgle, 1);
        'f':
          Inc(ThePlayer.intSword, 1);
        'g':
          Inc(ThePlayer.intAxe, 1);
        'h':
          Inc(ThePlayer.intWhip, 1);
        'i':
          Inc(ThePlayer.intGun, 1);
        'j':
          Inc(ThePlayer.intTool, 1);
        'k':
        begin
          Inc(ThePlayer.intHumility, 1);
          Inc(ThePlayer.longPrayers, ThePlayer.intHumility);
        end;
        'l':
          Inc(ThePlayer.intTrade, 1);
      end;

      Dec(points);

    end;

    StoreAchievement('Trained some skills.');

    // Check for promotions; ranks not listed here are gained by solving quests

    // can centurio become hastatus?
    if ThePlayer.intDipl[1] = 1 then  // ok, is centurio
      if ThePlayer.intWhip > 8 then  // ok, minimum lance requirement is met
        if ThePlayer.intDipl[2] = 0 then  // ok, not yet promoted to Hastatus
        begin
          ThePlayer.intDipl[2] := 1;
          ShowTransMessage('You have been promoted to the rank "Hastatus".', True);
          StoreAchievement('Promoted to the rank "Hastatus".');
        end;

    // can princeps become pilus?
    if ThePlayer.intDipl[3] = 1 then  // ok, is princeps
      if (ThePlayer.intSword > 14) and (ThePlayer.intAxe > 14) and
        (ThePlayer.intWhip > 14) then     // ok, minimum lance requirement is met
        if ThePlayer.intDipl[4] = 0 then  // ok, not yet promoted to Pilus
        begin
          ThePlayer.intDipl[4] := 1;
          ShowTransMessage('You have been promoted to the rank "Pilus".', True);
          StoreAchievement('Promoted to the rank "Pilus".');
        end;

    // can monk become holy warrior?
    if ThePlayer.intDipl[9] = 1 then  // ok, is monk
      if ThePlayer.intChant > 15 then  // ok, minimum gun requirement is met
        if ThePlayer.intDipl[10] = 0 then  // ok, not yet promoted to holy warrior
        begin
          ThePlayer.intDipl[10] := 1;
          ShowTransMessage(
            'You have been promoted to the rank "Holy Warrior".', True);
          StoreAchievement('Promoted to the rank "Holy Warrior".');
        end;

    // can archer become marksman?
    if ThePlayer.intProf = 4 then  // ok, is archer
      if ThePlayer.intView > 10 then  // ok, minimum view requirement is met
        if ThePlayer.intDipl[17] = 0 then  // ok, not yet promoted to ranger
        begin
          ThePlayer.intDipl[17] := 1;
          ShowTransMessage('You have been promoted to the rank "Marksman".', True);
          StoreAchievement('Promoted to the rank "Marksman".');
        end;

    // can master thief become guild leader?
    if ThePlayer.intDipl[13] = 1 then  // ok, is master thief
      if ThePlayer.intBurgle > 14 then  // ok, minimum steal requirement is met
        if ThePlayer.intDipl[14] = 0 then  // ok, not yet promoted to Guild leader
        begin
          ThePlayer.intDipl[14] := 1;
          ShowTransMessage(
            'You have been promoted to the rank "Guild Leader".', True);
          StoreAchievement('Promoted to the rank "Guild Leader".');
        end;

    // can assassin become agent?
    if ThePlayer.intDipl[11] = 1 then  // ok, is assassin
      if (ThePlayer.intFight > 14) and (ThePlayer.intTrade >= 10) then
        // ok, minimum requirements are met
        if ThePlayer.intDipl[12] = 0 then  // ok, not yet promoted to Agent
        begin
          ThePlayer.intDipl[12] := 1;
          ShowTransMessage('You have been promoted to the rank "Agent".', True);
          StoreAchievement('Promoted to the rank "Agent".');
        end;
  end;


  // search for secrets, study bookshelves, steal from shops (item) and npcs (money)
  procedure SearchAndSteal;
  var
    vx, vy, i, m: integer;
    intShop: integer;
    blHasStolen: boolean;
  begin

    // search for secret

    ShowTransMessage('You glance around attentively.', False);

    for i := 1 to 8 do
    begin
      case i of
        1:
        begin
          vx := 0;
          vy := -1;
        end;
        2:
        begin
          vx := 0;
          vy := 1;
        end;
        3:
        begin
          vx := 1;
          vy := 0;
        end;
        4:
        begin
          vx := -1;
          vy := 0;
        end;
        5:
        begin
          vx := 1;
          vy := -1;
        end;
        6:
        begin
          vx := -1;
          vy := -1;
        end;
        7:
        begin
          vx := 1;
          vy := 1;
        end;
        8:
        begin
          vx := -1;
          vy := 1;
        end;
      end;

      // hidden door
      if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 48 then
        if random(500) > CONST_SECRETSEARCH then
        begin
          DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 3;
          ShowTransMessage('You reveal a hidden door.', False);
        end;

      // bookshelf to study
      if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 49 then
        if ThePlayer.longSkillPoints > 0 then
        begin
          GetKeyInput('Your eyes are caught by of the books in the shelf ...', True);
          TrainSkill(ThePlayer.longSkillPoints);
          ThePlayer.longSkillPoints := 0;
        end;
    end;


    blHasStolen := False;

    // if thief, steal something
    if ThePlayer.intProf = 3 then
    begin
      intShop := DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding;

      // in front of a trader?
      if intShop > 0 then
      begin
        if blTodayStolenTrader = False then
        begin
          if intShop < 5 then
          begin
            StealSelection(intShop);
            if blTodayStolenTrader = True then
            begin
              blShopStolen[intShop] := True;
              blHasStolen := True;
            end;
          end
          else
            ShowTransMessage(
              'This trader has nothing interesting to steal.', False);
        end
        else
          ShowTransMessage('You have already robbed a trader today.', False);
      end
      else
      // simple NPC?
      if CheckForNPC(ThePlayer.intX, ThePlayer.intY) = True then
      begin
        if blTodayStolenNPC = False then
        begin
          ShowTransMessage('You steal some money ...', False);
          Inc(ThePlayer.longGold, ThePlayer.intBurgle);

          if ThePlayer.intDipl[13]=1 then
            Inc (ThePlayer.longGold, ThePlayer.intBurgle);
          blTodayStolenNPC := True;
          blHasStolen := True;
        end
        else
          ShowTransMessage('You have already robbed a peaceful citizen today.', False);
      end;

      // create guard?
      if blHasStolen = True then
        if ThePlayer.intBurgle < (DungeonLevel * 2) + trunc(random(4)) then
        begin
          ShowTransMessage('You have alarmed the guards!', False);
          m := GetFirstFreeMonsterID;
          if m > -1 then
          begin
            CreateMonster(m, 'guard', 0);
            Monster[m].intX := ThePlayer.intX + 1;
            Monster[m].intY := ThePlayer.intY;
          end;
        end;

    end;

  end;


  // dig through walls
  procedure Dig;
  var
    chDir: char;
    intShovel: integer;
    i, n, vx, vy: integer;
  begin
    intShovel := ThePlayer.intTool;
    if ThePlayer.intWeapon > 0 then
      Inc(intShovel, Thing[ThePlayer.intWeapon].intSP);

    chDir := GetDirection(0);

    vx := 0;
    vy := 0;
    if chDir = KeyNorth then
    begin
      vx := 0;
      vy := -1;
    end;
    if chDir = KeySouth then
    begin
      vx := 0;
      vy := 1;
    end;
    if chDir = KeyEast then
    begin
      vx := 1;
      vy := 0;
    end;
    if chDir = KeyWest then
    begin
      vx := -1;
      vy := 0;
    end;
    if chDir = KeyNorthEast then
    begin
      vx := 1;
      vy := -1;
    end;
    if chDir = KeyNorthWest then
    begin
      vx := -1;
      vy := -1;
    end;
    if chDir = KeySouthEast then
    begin
      vx := 1;
      vy := 1;
    end;
    if chDir = KeySouthWest then
    begin
      vx := -1;
      vy := 1;
    end;

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

    if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intAirType = 8 then
    begin
      ShowTransMessage('You disarm a trap!', false);
      Inc(ThePlayer.longEXP, 10);
      Inc(ThePlayer.longThisLevelEXP, 10);
      Inc(ThePlayer.longScore, 10);
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intAirType := 0;
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intAirRange := 0;
      n := 1;
    end
    else
    begin
      Val(GetTextInput('How many turns do you want to work?', 4), n);
      if n>0 then
      begin
        i:=0;
        repeat
          Inc(i);
          ShowTransMessage('Working; turn ' + IntToStr(i) + '  Integrity: ' + IntToStr(DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity), False);

          if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 6 then
          begin
            Dec(DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity, intShovel);
            if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity < 1 then
            begin
              DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 2;
              DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intLight := 4;
              DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity := 0;

              // item found?
              if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intItem = 0 then
                if random(1000) > CONST_BEATTHISFORITEM then
                  DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intItem := ReturnRareItem
                else
                  DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intItem := ReturnItemByName('Rubble');
            end
          end
          else
          begin
            ShowTransMessage('You can only dig through rock!', False);
            i := n;
          end;

          NextTurn;
        until (ThePlayer.intHP < 1) or (i = n) or (DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity < 1);
      end;
    end;

  end;


  // throw an item
  procedure Throw;
  var
    chDir, chBullet: char;
    GunX, GunY, GunBY, GunBX, GunBYborder, vx, vy, i, n: integer;
    intTP, intMDP, intItemType: integer;
    blMonsterHit, DestroyItem: boolean;
  begin

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/invbg.jpg');
      BlitImage_Title;
    end
    else
    begin
      ClearScreenSDL;
      DialogWin;
      StatusDeco;
    end;

    TransTextXY(1, 1, 'SELECT ITEM TO THROW');

    //for i := 1 to 16 do
    //begin
    //  if inventory[i].intType > 0 then
    //  begin
    //    TransTextXY(6, 4 + i, IntToStr(i));
    //    TransTextXY(10, 4 + i, thing[inventory[i].intType].chLetter +
    //      ' ' + thing[inventory[i].intType].strName);
    //    TransTextXY(44, 4 + i, 'x' + IntToStr(inventory[i].longNumber));
    //  end;
    //end;

    ListAllItems;

    repeat
      Val(GetTextInput('Selection?', 2), n);
    until (n = 0) or ((n > 0) and (n < 17));

    if n > 0 then
      if Inventory[n].longNumber > 0 then
      begin

        intItemType := inventory[n].intType;
        chBullet := Thing[intItemType].chLetter;
        Dec(Inventory[n].longNumber);

        // how much damage will this inflict?
        intTP := CollectThrowTP(intItemType);

        // exceptions for potions and food with certain effects
        if (chBullet = chr(155)) or (chBullet = chr(168)) then
        begin
          case Thing[intItemType].intEffect of
            1, 2, 12, 16, 18, 3, 4, 14, 27,
            35, 13, 9, 39, 38, 40, 8, 22, 45, 24: intTP := 0;
          end;
        end;


        // if item was the last item of that type, clear the slot
        // and ensure that it does not count as equipped anymore
        if Inventory[n].longNumber = 0 then
          Inventory[n].intType := 0;


        DestroyItem:=false;

        // direction
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        chDir := GetDirection(0);
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

        if chDir = KeyNorth then
        begin
          vx := 0;
          vy := -1;
        end;

        if chDir = KeySouth then
        begin
          vx := 0;
          vy := 1;
        end;

        if chDir = KeyNorthEast then
        begin
          vx := 1;
          vy := -1;
        end;

        if chDir = KeySouthEast then
        begin
          vx := 1;
          vy := 1;
        end;

        if chDir = KeyNorthWest then
        begin
          vx := -1;
          vy := -1;
        end;

        if chDir = KeySouthWest then
        begin
          vx := -1;
          vy := 1;
        end;

        if chDir = KeyWest then
        begin
          vx := -1;
          vy := 0;
        end;

        if chDir = KeyEast then
        begin
          vx := 1;
          vy := 0;
        end;

        GunX := ThePlayer.intX;
        GunY := ThePlayer.intY;

        //writeln ('PlayerBX: ' + inttostr(ThePlayer.intBX) + '  PlayerBY: ' + Inttostr(ThePlayer.intBY));
        GunBX := ThePlayer.intBX;

        if UseSDL = True then
          GunBY := ThePlayer.intBY + 1
        else
          GunBY := ThePlayer.intBY;

        if (UseSmallTiles = True) or (UseSDL = False) then
          GunBYborder := 1
        else
          GunBYborder := 0;

        // as long as there is no wall etc. let the ammu fly.
        blMonsterHit := False;
        while (DngLvl[GunX, GunY].intIntegrity = 0) and
          (DngLvl[GunX, GunY].blLOS = True) and (blMonsterHit = False) do
        begin

          Inc(GunX, vx);
          Inc(GunY, vy);

          Inc(GunBX, vx);
          Inc(GunBY, vy);

          // show ammu
          //writeln ('GunBX: ' + inttostr(GunBX) + '  GunBY: ' + Inttostr(GunBY));
          if (GunBX > 1) and (GunBX < ThePlayer.intBX * 2) and
            (GunBY > GunBYborder) and (GunBY < ThePlayer.intBY * 2) then
          begin
            AnyCharXY(GunBX, GunBY, chBullet, 0);
            if UseSDL = True then
              SDL_UPDATERECT(screen, 0, 0, 0, 0)
            else
              UpdateScreen(True);
            delay(50);
            if UseSDL = True then
              ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
          end;

          // was a monster hit?
          for i := 1 to 510 do
          begin
            if (Monster[i].intX = GunX) and (Monster[i].intY = GunY) then
            begin

              // monster will be hurt, make it angry and process the hit as normal
              if intTP > 0 then
              begin
                // even men and peaceful monsters will now be angry
                Monster[i].blHuman := False;
                Monster[i].blAttacked := True;  // set attacked flag

                // check if the monster was hit
                if random(CONST_LONGRANGE_HITRATE) > CollectHit then
                  ShowTransMessage('Your throw misses the ' + Monster[i].strName + ' [HP: ' + IntToStr(Monster[i].intHP) + '].', False)
                else
                begin
                  blMonsterHit := True;

                  intMDP := Monster[i].intAP;

                  intTP := intTP - intMDP;
                  if intTP < 1 then
                    intTP := trunc(random(2));

                  ShowTransMessage('Your throw hits the ' + Monster[i].strName + ' [HP: ' + IntToStr(Monster[i].intHP) + '].', False);

                  Monster[i].intHP := Monster[i].intHP - intTP;
                  if Monster[i].intHP < 0 then
                    Monster[i].intHP := 0;
                end;

              end
              else
              begin
                // check if the monster was hit
                if random(CONST_LONGRANGE_HITRATE) > ThePlayer.intView then
                  ShowTransMessage('Your throw misses the ' + Monster[i].strName + ' [HP: ' + IntToStr(Monster[i].intHP) + '].', False)
                else
                begin

                  blMonsterHit := True;

                  // effects of some food and potions
                  case Thing[intItemType].intEffect of
                    1:
                    begin  // DecHunger  -->  makes enemy peaceful
                      ShowTransMessage('You feed the ' + Monster[i].strName + ', making the ' + Monster[i].strName + ' peaceful.', False);
                      Monster[i].blAttacked := False;
                      Monster[i].blHuman := True;
                      DestroyItem:=true;
                    end;
                    2:
                    begin  // DecPoison  -->  removes poison ability from enemy
                      if Monster[i].blPoison = True then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' is healed from poison.', False);
                        Monster[i].blPoison := False;
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;

                    12:
                    begin // DecConfusion
                      if Monster[i].blConfusion = True then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' looks less confusing now.', False);
                        Monster[i].blConfusion := False;
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    27:
                    begin // DecPara
                      if Monster[i].blPara = True then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' watches you intensively.', False);
                        Monster[i].blPara := False;
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    45:
                    begin // IncPoison
                      if Monster[i].blPoison = False then
                      begin
                        ShowTransMessage('You poison the ' + Monster[i].strName + '.', False);
                        inc(Monster[i].intPoison, Thing[intItemType].intRange);
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('The ' + Monster[i].strName + ' is immune to poison.', False);
                    end;
                    16:
                    begin // IncSTR
                      if Monster[i].blWeaken = True then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' feels strong enough now.', False);
                        Monster[i].blWeaken := False;
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    18:
                    begin // DecBlindness
                      if Monster[i].blPoison = True then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' won''t hide anymore in darkness.', False);
                        Monster[i].blPoison := False;
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    3:
                    begin // IncPP
                      if Monster[i].intPP < Monster[i].intMaxPP then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' regenerated psychic power.', False);
                        Monster[i].intPP := Monster[i].intMaxPP;
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    24:
                    begin // DecPP
                      if Monster[i].intPP > 0 then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' looses psychic power.', False);
                        dec(Monster[i].intPP);
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    4:
                    begin // IncHP
                      if Monster[i].intHP < Monster[i].intMaxHP then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' is fully healed.', False);
                        Monster[i].intHP := Monster[i].intMaxHP;
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    14, 9, 39:
                    begin // ResistIce, IceAura, Ice
                      if Monster[i].blIce = False then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' learned an Ice chant.', False);
                        Monster[i].blIce := True;
                        Inc(Monster[i].intMaxPP, 2);
                        Inc(Monster[i].intPP, 2);
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    35, 22, 40:
                    begin // ResistWater, WaterAura, Water
                      if Monster[i].blWaterC = False then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + 'learned a Water chant.', False);
                        Monster[i].blWaterC := True;
                        Inc(Monster[i].intMaxPP, 2);
                        Inc(Monster[i].intPP, 2);
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                    13, 8, 38:
                    begin // ResistFire, FireAura, Fire
                      if Monster[i].blFire = False then
                      begin
                        ShowTransMessage('The ' + Monster[i].strName + ' learned a Fire chant.', False);
                        Monster[i].blFire := True;
                        Inc(Monster[i].intMaxPP, 2);
                        Inc(Monster[i].intPP, 2);
                        DestroyItem:=true;
                      end
                      else
                        ShowTransMessage('Nothing happens to the ' + Monster[i].strName + ' after consuming the ' + Thing[intItemType].strName + '.', False);
                    end;
                  end;
                end;
                IsMonsterDead(i);
              end;

            end;
          end;

        end;

        // if dungeon tile is not occupied by an item, and a walkable tile, and item is not from a package,
        // place it on the ground, otherwise destroy it
        if (DngLvl[GunX, GunY].intItem = 0) and (DngLvl[GunX, GunY].intIntegrity = 0) and (Thing[intItemType].intAmount = 1) and (DestroyItem=false) then
          DngLvl[GunX, GunY].intItem := intItemType
        else
          ShowTransMessage('You hear a cracking -- the item was destroyed.', False);

      end;

  end;

  // shoot with weapon
  procedure Shoot;
  var
    chDir, chBullet: char;
    GunX, GunY, GunBY, GunBX, GunBYborder, vx, vy, i, n: integer;
    intTP, intMDP: integer;
    blMonsterHit: boolean;
  begin

    intTP := CollectGunTP;

    // check if player has wielded a long range weapon
    if ThePlayer.intWeapon > 0 then
    begin

      if Thing[ThePlayer.intWeapon].intGP > 0 then
      begin
        // check if there is enough ammu for the weapon in the player's inventory
        n := 0;
        for i := 1 to 16 do
          if Inventory[i].intType > 0 then
            if Thing[Inventory[i].intType].intIsAmmu = Thing[ThePlayer.intWeapon].intNeedsAmmu then
              n := i;

        // if we have ammu, process the shoot
        if n > 0 then
        begin
          chBullet := Thing[Inventory[n].intType].chLetter;

          // add ammu-wp to total tp
          Inc(intTP, Thing[Inventory[n].intType].intWP);

          Dec(Inventory[n].longNumber);
          // decrease total number of bullets of this type in inventory
          if Inventory[n].longNumber = 0 then
            Inventory[n].intType := 0;
          // if number of bullets=0, delete this item from inventory

          // magic?
          if (Thing[ThePlayer.intWeapon].intEffect = 19) or
            (Thing[ThePlayer.intWeapon].intEffect = 38) or
            (Thing[ThePlayer.intWeapon].intEffect = 39) or
            (Thing[ThePlayer.intWeapon].intEffect = 40) or
            (Thing[ThePlayer.intWeapon].intEffect = 45) or
            (Thing[ThePlayer.intWeapon].intEffect = 56) then
          begin
            case Thing[ThePlayer.intWeapon].intEffect of
              38:
                DoEffectOnMonster(Thing[ThePlayer.intWeapon].intRange, 1);         // fire
              39:
                DoEffectOnMonster(Thing[ThePlayer.intWeapon].intRange, 2);         // ice
              40:
                DoEffectOnMonster(Thing[ThePlayer.intWeapon].intRange, 3);         // water
              19:
                DoEffectOnMonster(Thing[ThePlayer.intWeapon].intRange, 19);        // force
              45:
                DoEffectOnMonster(Thing[ThePlayer.intWeapon].intRange, 45);        // poison
              56:
                DoEffectOnMonster(Thing[ThePlayer.intWeapon].intRange, 56);        // electricity
            end;
          end
          else
          begin
            // direction
            chDir := GetDirection(0);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

            if chDir = KeyNorth then
            begin
              vx := 0;
              vy := -1;
            end;

            if chDir = KeySouth then
            begin
              vx := 0;
              vy := 1;
            end;

            if chDir = KeyNorthEast then
            begin
              vx := 1;
              vy := -1;
            end;

            if chDir = KeySouthEast then
            begin
              vx := 1;
              vy := 1;
            end;

            if chDir = KeyNorthWest then
            begin
              vx := -1;
              vy := -1;
            end;

            if chDir = KeySouthWest then
            begin
              vx := -1;
              vy := 1;
            end;

            if chDir = KeyWest then
            begin
              vx := -1;
              vy := 0;
            end;

            if chDir = KeyEast then
            begin
              vx := 1;
              vy := 0;
            end;

            GunX := ThePlayer.intX;
            GunY := ThePlayer.intY;

            //writeln ('PlayerBX: ' + inttostr(ThePlayer.intBX) + '  PlayerBY: ' + Inttostr(ThePlayer.intBY));
            GunBX := ThePlayer.intBX;

            if UseSDL = True then
              GunBY := ThePlayer.intBY + 1
            else
              GunBY := ThePlayer.intBY;

            if (UseSmallTiles = True) or (UseSDL = False) then
              GunBYborder := 1
            else
              GunBYborder := 0;

            //if SFXPlaying=false then
            if random(500) > 250 then
              PlaySFX('hit-arrow.ogg')
            else
              PlaySFX('hit-arrow-2.ogg');

            // as long as there is no wall etc. let the ammu fly. At least for ThePlayer.intView+2 tiles
            blMonsterHit := False;
            while (DngLvl[GunX, GunY].intIntegrity = 0) and
              (DngLvl[GunX, GunY].blLOS = True) and (blMonsterHit = False) do
            begin
              Inc(GunX, vx);
              Inc(GunY, vy);

              Inc(GunBX, vx);
              Inc(GunBY, vy);

              // show ammu
              //writeln ('GunBX: ' + inttostr(GunBX) + '  GunBY: ' + Inttostr(GunBY));
              if (GunBX > 1) and (GunBX < ThePlayer.intBX * 2) and
                (GunBY > GunBYborder) and (GunBY < ThePlayer.intBY * 2) then
              begin
                AnyCharXY(GunBX, GunBY, chBullet, 0);
                if UseSDL = True then
                  SDL_UPDATERECT(screen, 0, 0, 0, 0)
                else
                  UpdateScreen(True);
                delay(50);
                if UseSDL = True then
                  ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
              end;

              // was a monster hit?
              for i := 1 to 510 do
              begin
                if (Monster[i].intX = GunX) and (Monster[i].intY = GunY) then
                begin

                  Monster[i].blHuman := False;
                  // even men and peaceful monsters will now be angry
                  Monster[i].blAttacked := True;  // set attacked flag

                  // check if the monster was hit
                  if random(CONST_LONGRANGE_HITRATE) > CollectHit then
                    ShowTransMessage('You miss the ' + Monster[i].strName + ' [HP: ' + IntToStr(Monster[i].intHP) + '].', False)
                  else
                  begin
                    blMonsterHit := True;

                    intMDP := Monster[i].intAP;

                    // total damage is (weapon + ammu) - defence
                    intTP := (Thing[inventory[n].intType].intWP + intTP) - intMDP;

                    if intTP < 1 then
                      intTP := trunc(random(2));

                    ShowTransMessage('You shoot the ' +
                      Monster[i].strName + ' [HP: ' + IntToStr(Monster[i].intHP) +
                      '].', False);

                    Monster[i].intHP := Monster[i].intHP - intTP;
                    if Monster[i].intHP < 0 then
                      Monster[i].intHP := 0;
                  end;

                  IsMonsterDead(i);
                end;
              end;
            end;
          end;
        end
        else
          GetKeyInput('You need the proper ammunition to use the ' +
            Thing[ThePlayer.intWeapon].strName + '.', True);
      end
      else
        GetKeyInput('Your current weapon is no long-range weapon.', True);
    end
    else
      GetKeyInput('You need to wield a long-range weapon in order to shoot.', True);
  end;


  function OpenDoor(chDir: char): integer;
  var
    vx, vy: integer;
  begin
    if chDir = '-' then
      chDir := GetDirection(0);

    //     ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

    vx := 0;
    vy := 0;
    if chDir = KeyNorth then
    begin
      vx := 0;
      vy := -1;
    end;
    if chDir = KeySouth then
    begin
      vx := 0;
      vy := 1;
    end;
    if chDir = KeyEast then
    begin
      vx := 1;
      vy := 0;
    end;
    if chDir = KeyWest then
    begin
      vx := -1;
      vy := 0;
    end;
    if chDir = KeyNorthEast then
    begin
      vx := 1;
      vy := -1;
    end;
    if chDir = KeyNorthWest then
    begin
      vx := -1;
      vy := -1;
    end;
    if chDir = KeySouthEast then
    begin
      vx := 1;
      vy := 1;
    end;
    if chDir = KeySouthWest then
    begin
      vx := -1;
      vy := 1;
    end;

    OpenDoor := -1;

    // standard door
    if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 3 then
    begin
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 4;
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity := 0;
      OpenDoor := 1;
    end;

    // locked gate which needs a key to open
    if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 64 then
    begin
      if ((PlayerHasKey > 0) and (PlayerHasKey < 17)) or (PlayerHasKey = 22) then
      begin

        PlaySFX('gate-openclose.ogg');

        if PlayerHasKey < 22 then
        begin
          Dec(Inventory[PlayerHasKey].longNumber);
          if Inventory[PlayerHasKey].longNumber < 1 then
            Inventory[PlayerHasKey].intType := 0;
        end;
        DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 65;
        DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity := 0;
        OpenDoor := 4;
      end
      else
        OpenDoor := 5;
    end;

    // locked door which needs a key to open
    if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 24 then
    begin
      if ((PlayerHasKey > 0) and (PlayerHasKey < 17)) or (PlayerHasKey = 22) then
      begin

        PlaySFX('door-unlock.ogg');

        if PlayerHasKey < 22 then
        begin
          Dec(Inventory[PlayerHasKey].longNumber);
          if Inventory[PlayerHasKey].longNumber < 1 then
            Inventory[PlayerHasKey].intType := 0;
        end;
        DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 4;
        DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity := 0;
        OpenDoor := 2;
      end
      else
        OpenDoor := 3;
    end;
  end;

  procedure CloseDoor;
  var
    chDir: char;
    vx, vy: integer;
  begin

    chDir := GetDirection(0);
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

    vx := 0;
    vy := 0;
    if chDir = KeyNorth then
    begin
      vx := 0;
      vy := -1;
    end;
    if chDir = KeySouth then
    begin
      vx := 0;
      vy := 1;
    end;
    if chDir = KeyEast then
    begin
      vx := 1;
      vy := 0;
    end;
    if chDir = KeyWest then
    begin
      vx := -1;
      vy := 0;
    end;
    if chDir = KeyNorthEast then
    begin
      vx := 1;
      vy := -1;
    end;
    if chDir = KeyNorthWest then
    begin
      vx := -1;
      vy := -1;
    end;
    if chDir = KeySouthEast then
    begin
      vx := 1;
      vy := 1;
    end;
    if chDir = KeySouthWest then
    begin
      vx := -1;
      vy := 1;
    end;

    // close gate
    if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 65 then
    begin
      PlaySFX('gate-openclose.ogg');
      ShowTransMessage('You close the gate.', False);
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 64;
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity := 100;
    end;

    // close door
    if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 4 then
    begin
      if (DungeonLevel = 26) or (DungeonLevel = 27) then
      begin
        PlaySFX('force-on.ogg');
        ShowTransMessage('You activate a force field.', False);
      end
      else
      begin
        PlaySFX('door-close.ogg');
        ShowTransMessage('You close the door.', False);
      end;
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 3;
      DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity := 100;
    end;
  end;

  // returns: 1 = New or Load Game ; 2 = Quickstart; 3 = Options; 4 = Keys; 5 = Quit
  function TitleScreen(): integer;
  var
    dummy: string;
    BlitRect: SDL_RECT;
  begin

    ClearScreenSDL;

    dummy := '-';
    repeat

      if UseSDL = True then
      begin
        BlendTitleSurface(True);
      end
      else
      begin

        GlobalConColor := yellow;
        TextXY(28, 4, 'L a m b d a R o g u e');

        GlobalConColor := lightred;
        TextXY(30, 6, 'The Book of Stars');

        GlobalConColor := lightgray;
        TextXY(21, 16, 'Copyright (c) Mario Donick 2006-2011.');

        TextXY(7, 17, 'This program can be copied, modified and distributed under the');
        TextXY(11, 18, 'terms of the GNU General Public License, version 2.x.');

        GlobalConColor := cyan;
        TextXY(18, 20, 'Please ensure that NumLock is switched ON.');

        GlobalConColor := -1;

        TextXY(25, 8,  '1 Create / Continue Game');
        TextXY(25, 9,  '2 Quickstart');
        TextXY(25, 11, '3 Options');
        TextXY(25, 12, '4 Keybindings');
        TextXY(25, 14, '5 Quit');

      end;

      if UseSDL = True then
        SmallTextXY(1, 1, strVersion, False, False)
      else
        TransTextXY(79 - length(strVersion) - 2, 1, strVersion);

      if UseSDL = False then
        dummy := GetKeyInput('Please select an option.', False)
      else
        dummy := GetKeyInput('', False);

    until (dummy = '1') or (dummy = '2') or (dummy = '3') or (dummy = '4') or (dummy = '5');

    BottomBar;
    TitleScreen := StrToInt(dummy);
  end;

  procedure SetKeyConfig;
  var
    dummy: string;
    ch: char;
  begin

    if UseSDL = True then
    begin
      TempAnsi := 'graphics/decobg.jpg';
      LoadImage_Title('graphics/decobg.jpg');
    end;

    repeat
      ClearScreenSDL;

      if UseSDL = True then
        BlitImage_Title
      else
        StatusDeco;

      TransTextXY(1, 1, 'KEYBINDINGS');

      TransTextXY(2, 4, 'Movement keys (N,S,E,W,NE,NW,SE,SW): ' +
        KeyNorth + KeySouth + KeyEast + KeyWest + KeyNorthEast +
        KeyNorthWest + KeySouthEast + KeySouthWest);
      TransTextXY(2, 6, '[' + KeyEnter + '] (General action)');

      TransTextXY(2, 7,
        '  open chest                        (in front of a treasure chest)');
      TransTextXY(2, 8, '  sacrifice money                   (in front of an altar)');
      TransTextXY(2, 9, '  enter staircase                   (in front of a staircase)');
      TransTextXY(2, 10, '  drink from well                   (in front of a well)');
      TransTextXY(2, 11, '  examine crypt                     (in front of a crypt)');

      TransTextXY(2, 12, '[' + KeyTake + '] pick up item                    [' +
        KeyInventory + '] show inventory');
      TransTextXY(2, 13, '[' + KeyChant + '] show songbook (spells)          [' +
        KeyChantLast + '] chant last spell again');
      TransTextXY(2, 14, '[' + KeyTrade + '] talk to NPC or trader           [' +
        KeyShoot + '] fire long-range weapon');
      TransTextXY(2, 15, '[' + KeyTunnel + '] dig / disarm trap               [' +
        KeyPray + '] pray to your god');
      TransTextXY(2, 16, '[' + KeyStatus + '] show status screen              [' +
        KeyQuestlog + '] show questlog');
      TransTextXY(2, 17, '[' + KeyShortRest + '] rest one turn                   [' +
        KeyRest + '] rest certain number of turns');
      TransTextXY(2, 18, '[' + KeyLook + '] identify tile                   [' +
        KeyQuit + '] show game menu');
      TransTextXY(2, 19, '[' + KeySearchSteal + '] search/steal                    [' +
        KeySetQuickKeys + '] show and reset quick keys');
      TransTextXY(2, 20, '[' + KeyCloseDoor + '] close door                      [' +
        KeyBigMap + '] show big minimap (SDL only)');
      TransTextXY(2, 21, '[' + KeyThrow   + '] throw an item                   [' +
        KeyTactics + '] switch tactics');
      TransTextXY(2, 22, '[' + KeySpecial + '] use talent                      ['+ KeySpecialDiv+'] divine rage');

      dummy := GetKeyInput(
        'Press a key to change it. Press [Enter] to accept, [ESC] to cancel.', False);
      ch := dummy[1];
      if (dummy = 'ESC') or (dummy = 'ENTER') then
        ch := chr(254);

      if ch = KeyNorth then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in northern direction (current: ' +
          KeyNorth + ')', False);
        KeyNorth := dummy[1];
      end;

      if ch = KeySouth then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in southern direction (current: ' +
          KeySouth + ')', False);
        KeySouth := dummy[1];
      end;

      if ch = KeySouth then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in eastern direction (current: ' +
          KeyEast + ')', False);
        KeyEast := dummy[1];
      end;

      if ch = KeyWest then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in western direction (current: ' +
          KeyWest + ')', False);
        KeyWest := dummy[1];
      end;

      if ch = KeyNorthEast then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in north-eastern direction (current: ' +
          KeyNorthEast + ')', False);
        KeyNorthEast := dummy[1];
      end;

      if ch = KeySouthEast then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in south-eastern direction (current: ' +
          KeySouthEast + ')', False);
        KeySouthEast := dummy[1];
      end;

      if ch = KeyNorthWest then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in north-western direction (current: ' +
          KeyNorthWest + ')', False);
        KeyNorthWest := dummy[1];
      end;

      if ch = KeySouthWest then
      begin
        BottomBar;
        dummy := GetKeyInput('Movement in south-western direction (current: ' +
          KeySouthWest + ')', False);
        KeySouthWest := dummy[1];
      end;

      if ch = KeyEnter then
      begin
        BottomBar;
        dummy := GetKeyInput('General action / use (current: ' +
          KeyEnter + ')', False);
        KeyEnter := dummy[1];
      end;

      if ch = KeyTake then
      begin
        BottomBar;
        dummy := GetKeyInput('Pickup item (current: ' + KeyTake + ')', False);
        KeyTake := dummy[1];
      end;

      if ch = KeySearchSteal then
      begin
        BottomBar;
        dummy := GetKeyInput('Search / steal (current: ' + KeySearchSteal + ')', False);
        KeySearchSteal := dummy[1];
      end;

      if ch = KeyTrade then
      begin
        BottomBar;
        dummy := GetKeyInput('Talk and trade (current: ' + KeyTrade + ')', False);
        KeyTrade := dummy[1];
      end;

      if ch = KeyCloseDoor then
      begin
        BottomBar;
        dummy := GetKeyInput('Close door (current: ' + KeyCloseDoor + ')', False);
        KeyCloseDoor := dummy[1];
      end;

      if ch = KeyTunnel then
      begin
        BottomBar;
        dummy := GetKeyInput('Dig through stone (current: ' +
          KeyTunnel + ')', False);
        KeyTunnel := dummy[1];
      end;

      if ch = KeyPray then
      begin
        BottomBar;
        dummy := GetKeyInput('Pray to your god (current: ' + KeyPray + ')', False);
        KeyPray := dummy[1];
      end;

      if ch = KeyShoot then
      begin
        BottomBar;
        dummy := GetKeyInput('Shoot with equipped fire-arm (current: ' +
          KeyShoot + ')', False);
        KeyShoot := dummy[1];
      end;

      if ch = KeyThrow then
      begin
        BottomBar;
        dummy := GetKeyInput('Throw an item at a creature (current: ' +
          KeyThrow + ')', False);
        KeyThrow := dummy[1];
      end;

      if ch = KeyTactics then
      begin
        BottomBar;
        dummy := GetKeyInput(
          'Switch between offensive and defensive tactics (current: ' +
          KeyTactics + ')', False);
        KeyTactics := dummy[1];
      end;

      if ch = KeyChant then
      begin
        BottomBar;
        dummy := GetKeyInput('Show songbook with magical songs (current: ' +
          KeyChant + ')', False);
        KeyChant := dummy[1];
      end;

      if ch = KeyChantLast then
      begin
        BottomBar;
        dummy := GetKeyInput('Chant last magical song again (current: ' +
          KeyChantLast + ')', False);
        KeyChantLast := dummy[1];
      end;

      if ch = KeyShortRest then
      begin
        BottomBar;
        dummy := GetKeyInput('Rest for one turn (current: ' + KeyShortRest + ')', False);
        KeyShortRest := dummy[1];
      end;

      if ch = KeyRest then
      begin
        BottomBar;
        dummy := GetKeyInput('Rest (current: ' + KeyRest + ')', False);
        KeyRest := dummy[1];
      end;

      if ch = KeyStatus then
      begin
        BottomBar;
        dummy := GetKeyInput('Show status screen (current: ' +
          KeyStatus + ')', False);
        KeyStatus := dummy[1];
      end;

      if ch = KeyQuestlog then
      begin
        BottomBar;
        dummy := GetKeyInput('Show questlog (current: ' + KeyQuestlog + ')', False);
        KeyQuestlog := dummy[1];
      end;

      if ch = KeyInventory then
      begin
        BottomBar;
        dummy := GetKeyInput('Show inventory (current: ' + KeyInventory + ')', False);
        KeyInventory := dummy[1];
      end;

      if ch = KeyHelp then
      begin
        BottomBar;
        dummy := GetKeyInput('Show help screen (current: ' + KeyHelp + ')', False);
        KeyHelp := dummy[1];
      end;

      if ch = KeyLook then
      begin
        BottomBar;
        dummy := GetKeyInput('Identify tile (current: ' + KeyLook + ')', False);
        KeyLook := dummy[1];
      end;

      if ch = KeyQuit then
      begin
        BottomBar;
        dummy := GetKeyInput('Show game menu (current: ' + KeyQuit + ')', False);
        KeyQuit := dummy[1];
      end;

      if ch = KeySetQuickKeys then
      begin
        BottomBar;
        dummy := GetKeyInput('Set quick keys (current: ' + KeySetQuickKeys + ')', False);
        KeySetQuickKeys := dummy[1];
      end;

      if ch = KeyBigMap then
      begin
        BottomBar;
        dummy := GetKeyInput('Show big minimap (current: ' + KeyBigMap + ')', False);
        KeyBigMap := dummy[1];
      end;

      if ch = KeySpecial then
      begin
        BottomBar;
        dummy := GetKeyInput('Use talent (current: ' + KeySpecial + ')', False);
        KeySpecial := dummy[1];
      end;

      if ch = KeySpecialDiv then
      begin
        BottomBar;
        dummy := GetKeyInput('Divine rage (current: ' + KeySpecialDiv + ')', False);
        KeySpecialDiv := dummy[1];
      end;

    until (dummy = 'ESC') or (dummy = 'ENTER');

    //writeln(dummy);

    if dummy = 'ENTER' then
    begin
      ClearScreenSDL;
      SaveConfig;
      //        GetKeyInput('Keybindings saved.', true);
    end;

    if dummy = 'ESC' then
    begin
      ClearScreenSDL;
      InitKeys(False);
      //        GetKeyInput('Keybindings restored from existing config file.', true);
    end;
  end;

  procedure SetOptions;
  var
    dummy: string;
    ch: char;
    Fullscreenflag: longword;
  begin

    if UseSDL = True then
    begin
      TempAnsi := 'graphics/invbg.jpg';
      LoadImage_Title('graphics/invbg.jpg');
    end;

    if UseFullScreen=true then
      FullscreenFlag := SDL_FULLSCREEN
    else
      FullscreenFlag := 0;   // SDL_FULLSCREEN
    {$ifdef Darwin}
    FullScreenFlag := 0;
    {$endif}

    ch := '-';

    repeat
      ClearScreenSDL;

      if UseSDL = True then
        BlitImage_Title
      else
      begin
        DialogWin;
        StatusDeco;
      end;

      TransTextXY(1, 1, 'GENERAL OPTIONS');
      TransTextXY(8, 7, 'a  Use graphical output? ' + BoolString(UseSDL, 1) +
        '. (requires restart)');

      if UseSDL=true then
      begin
        TransTextXY(8, 8, 'b  Use small tile size (20x40)? ' + BoolString(UseSmallTiles, 1) + '.');

        if UseSmallTiles=true then
          TransTextXY(8, 9, 'c    Use old tileset for small tiles? ' + BoolString(UseOldSmallTiles, 1) + '.');

        TransTextXY(8, 10, 'd  Use high resolution (1024x768)? ' + BoolString(UseHiRes, 1) + '.');

        TransTextXY(8, 12, 'e  Show blood? ' + BoolString(ShowBlood, 1) + '.');
      end;

      TransTextXY(8, 14, 'f  Move after victory? ' + BoolString(AutoMoveToTile, 1) + '.');

      TransTextXY(8, 16, '[+] and [-] to adjust music volume: ' + IntToStr(intVolumeMusic) + '/128');
      TransTextXY(8, 17, '[*] and [/] to adjust sound volume: ' + IntToStr(intVolumeSFX) + '/128');

      dummy := GetKeyInput('Select an option or press [Enter] to close and save settings.', False);
      ch := dummy[1];

      case ch of

        '+':
        begin
          if intVolumeMusic<128 then
            inc(intVolumeMusic);
          Mix_VolumeMusic(intVolumeMusic);
          blUseExternPlayer := true;
        end;

        '-':
        begin
          if intVolumeMusic>0 then
          begin
            dec(intVolumeMusic);
            Mix_VolumeMusic(intVolumeMusic);
          end;
          if intVolumeMusic=0 then
            blUseExternPlayer := false;
        end;

        '*':
        begin
          if intVolumeSFX<128 then
            inc(intVolumeSFX);
          blUseExternPlayerTwo := true;
        end;

        '/':
        begin
          if intVolumeSFX>0 then
            dec(intVolumeSFX);
          if intVolumeSFX=0 then
            blUseExternPlayerTwo := false;
        end;

        {$IFNDEF WEB}  // RVIP: no console mode in the browser
        'a':
        begin
          GetKeyInput('LambdaRogue will now save and close. Restart it afterwards.', True);
          SaveGame(ThePlayer.strName, DungeonLevel);
          StopGraphics;
          StopMusic;
          FreeMusic;
          UseSDL := BoolToggle(UseSDL);
          SaveConfig;
          if UseSDL = True then
            writeln('LambdaRogue will run in graphical mode when restarted.')
          else
            writeln('LambdaRogue will run in console mode when restarted.');
          halt;
        end;
        {$ENDIF}

        'b':
        begin
          if UseSDL=true then
          begin
            UseSmallTiles := BoolToggle(UseSmallTiles);
            LoadImage_Tiles(ThePlayer.intProf, ThePlayer.intSex);
            if UseSmallTiles = True then
            begin
              if UseHiRes = False then
              begin
                intCenterX := 40 div 2;
                intCenterY := 12 div 2;
              end
              else
              begin
                intCenterX := 51 div 2;
                intCenterY := (19 div 2) - 1;
              end;
            end
            else
            begin
              if UseHiRes = False then
              begin
                intCenterX := 20 div 2;
                intCenterY := 6 div 2;
              end
              else
              begin
                intCenterX := 25 div 2;
                intCenterY := (9 div 2) - 1;
              end;
            end;
            ThePlayer.intBX := intCenterX;
            ThePlayer.intBY := intCenterY;
            SaveConfig;
          end;
        end;

        'c':
        begin
          if UseSDL=true then
          begin
            if UseSmallTiles = true then
            begin
              UseOldSmallTiles := BoolToggle(UseOldSmallTiles);
              LoadImage_Tiles(ThePlayer.intProf, ThePlayer.intSex);
              SaveConfig;
            end;
          end;
        end;

        'd':
        begin
          if UseSDL=true then
          begin
            UseHiRes := BoolToggle(UseHiRes);
            SaveConfig;

            SDL_FREESURFACE(screen);

            if UseFullScreen=true then
              FullscreenFlag := SDL_FULLSCREEN
            else
              FullscreenFlag := 0;
            {$ifdef Darwin}
            FullScreenFlag := 0;
            {$endif}

            delay(50);

            if UseHiRes = False then
            begin
              screen := SDL_SETVIDEOMODE(800, 600, 24, SDL_HWSURFACE + FullscreenFlag);
              HiResOffsetX := 0;
              HiResOffsetY := 0;
              HiResTextOffsetX := 0;
              HiResTextOffsetY := 0;
              ChantBarX := 254;
              ChantBarY := 540;
              LoadImage_Back('graphics/bg-800.png');
            end
            else
            begin
              screen := SDL_SETVIDEOMODE(1024, 768, 24, SDL_HWSURFACE + FullscreenFlag);

              HiResOffsetX := 110;
              HiResTextOffsetX := -12;
              ChantBarX := 239;
              ChantBarY := 708;
              LoadImage_Back('graphics/bg-1024.png');

              HiResOffsetY := 80;
              HiResTextOffsetY := 3;
            end;

            if UseSmallTiles = True then
            begin
              if UseHiRes = False then
              begin
                intCenterX := 40 div 2;
                intCenterY := 12 div 2;
              end
              else
              begin
                intCenterX := 51 div 2;
                intCenterY := (19 div 2) - 1;
              end;
            end
            else
            begin
              if UseHiRes = False then
              begin
                intCenterX := 20 div 2;
                intCenterY := 6 div 2;
              end
              else
              begin
                intCenterX := 25 div 2;
                intCenterY := (9 div 2) - 1;
              end;
            end;

            ThePlayer.intBX := intCenterX;
            ThePlayer.intBY := intCenterY;
          end;
        end;
        'e':
          if UseSDL=true then
          begin
            ShowBlood := BoolToggle(ShowBlood);
          end;
        'f':
          AutoMoveToTile := BoolToggle(AutoMoveToTile);
      end;

    until dummy = 'ENTER';

    if dummy = 'ENTER' then
    begin
      ClearScreenSDL;
      SaveConfig;
    end;

    if blUseExternPlayer = False then
      StopMusic;

  end;


  // returns true, if the player selected to quit the game
  function GameMenu: boolean;
  var
    ch: char;
    dummy: string;
  begin
    GameMenu := False;

    repeat
      ClearScreenSDL;

      if UseSDL = True then
        LoadImage_Title('graphics/menubg.jpg');

      repeat
        if UseSDL = True then
        begin
          BlitImage_Title;
        end
        else
        begin
          TextXY(31, 10, '1  General Options');
          TextXY(31, 11, '2  Keybindings');
          TextXY(31, 12, '3  Save and Quit');
        end;

        dummy := GetKeyInput(
          '', False);
      until (dummy = '1') or (dummy = '2') or (dummy = '3') or (dummy = 'ESC');
      ch := dummy[1];

      case ch of
        '1':
          SetOptions;
        '2':
          SetKeyConfig;
        '3':
          GameMenu := True;
      end;

    until (dummy = 'ESC') or (GameMenu = True);

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  end;

  // shows a bigger minimap
  procedure BigMap;
  var
    i, j, k, x, y: integer;
    dummy: string;
  begin

    PlaySFX('page-turn.ogg');

    DarkenScreen;

    LoadImage_Title('graphics/mapbg.jpg');

    dummy := '-';

    repeat

      BlitImage_Title;

      SmallTextXY(0, 2, '[SPACE or Enter to close]', False, True);
      SmallTextXY(0, 5, 'LEGEND:', False, True);

      SmallTextXY(0, 7, '  @  ' + ThePlayer.strName, False, True);
      SmallTextXY(0, 8, '  1  NPC', False, True);


      SmallTextXY(0, 10, '  .  floor', False, True);
      SmallTextXY(0, 11, '  #  wall', False, True);
      SmallTextXY(0, 12, '  T  tree; high grass', False, True);
      SmallTextXY(0, 13, '  =  water; lava', False, True);
      SmallTextXY(0, 14, '  ^  rock; mountain', False, True);
      SmallTextXY(0, 15, '  ~  hill', False, True);
      SmallTextXY(0, 16, '  ,  sand; dry grass', False, True);

      SmallTextXY(0, 18, '  |  altar', False, True);
      SmallTextXY(0, 19, '  U  enchanted well', False, True);


      SmallTextXY(0, 21, '  >  staircase/ladder down', False, True);
      SmallTextXY(0, 22, '  <  staircase/ladder up', False, True);


      if UseHiRes = True then
        x := 37
      else
        x := 20;

      for i := 1 to DngMaxWidth - 1 do
      begin
        Inc(x);

        if (UseHiRes = True) and (Netbook = False) then
          y := 5
        else if (UseHiRes = True) and (Netbook = True) then
          y := -2
        else if (UseHiRes = False) then
          y := -2;

        for j := 19 to DngMaxHeight - 1 do
        begin
          Inc(y);
          if DngLvl[i, j].blKnown = True then
          begin

            // walls
            if (DngLvl[i, j].intFloorType = 1) or (DngLvl[i, j].intFloorType = 24) or
              (DngLvl[i, j].intFloorType = 48) then
              SmallCharXY(x, y, '#', True);

            // rock
            if (DngLvl[i, j].intFloorType = 6) then
              SmallCharXY(x, y, '^', True);

            // floor
            if (DngLvl[i, j].intFloorType = 2) or
              (DngLvl[i, j].intFloorType = 31) or (DngLvl[i, j].intFloorType = 60) or
              (DngLvl[i, j].intFloorType = 61) then
              SmallCharXY(x, y, '.', True);

            // trees
            if (DngLvl[i, j].intFloorType = 10) or
              (DngLvl[i, j].intFloorType = 13) or (DngLvl[i, j].intFloorType = 17) then
              SmallCharXY(x, y, 'T', True);

            // sand
            if (DngLvl[i, j].intFloorType = 12) or
              (DngLvl[i, j].intFloorType = 21) or (DngLvl[i, j].intFloorType = 22) or
              (DngLvl[i, j].intFloorType = 23) then
              SmallCharXY(x, y, ',', True);

            // water
            if (DngLvl[i, j].intFloorType = 5) or
              (DngLvl[i, j].intFloorType = 38) or (DngLvl[i, j].intFloorType = 39) or
              (DngLvl[i, j].intFloorType = 20) then
              SmallCharXY(x, y, '=', True);

            // hills
            if DngLvl[i, j].intFloorType = 18 then
              SmallCharXY(x, y, '~', True);

            // altars
            if DngLvl[i, j].intFloorType = 15 then
              SmallCharXY(x, y, '|', False);

            // wells
            if DngLvl[i, j].intFloorType = 28 then
              SmallCharXY(x, y, 'U', False);


            // staircases
            if (DngLvl[i, j].intFloorType = 9) or (DngLvl[i, j].intFloorType = 63) or (DngLvl[i, j].intFloorType = 67) then
              // runter
              SmallCharXY(x, y, '>', False);
            if (DngLvl[i, j].intFloorType = 8) or (DngLvl[i, j].intFloorType = 62) or (DngLvl[i, j].intFloorType = 66) then
              // hoch
              SmallCharXY(x, y, '<', False);
            if (DngLvl[i, j].intFloorType = 25) or (DngLvl[i, j].intFloorType = 3) then
              SmallCharXY(x, y, '+', True);

          end;
        end;
      end;

      // Player

      if UseHiRes = True then
        x := 37
      else
        x := 20;

      for i := 1 to DngMaxWidth - 1 do
      begin
        Inc(x);

        if (UseHiRes = True) and (Netbook = False) then
          y := 5
        else if (UseHiRes = True) and (Netbook = True) then
          y := -2
        else if (UseHiRes = False) then
          y := -2;

        for j := 19 to DngMaxHeight - 1 do
        begin
          Inc(y);

          // Discovered NPCs
          for k := 1 to 9 do
            if (i = NPC[k].intX) and (j = NPC[k].intY) then
              if not ((i = ThePlayer.intX) and (j = ThePlayer.intY)) then
                SmallCharXY(x, y, IntToStr(k)[1], False);

          // Player
          if (i = ThePlayer.intX) and (j = ThePlayer.intY) then
            SmallCharXY(x, y, '@', False);
        end;
      end;

      dummy := GetKeyInput(' ', False);

    until (dummy = 'ESC') or (dummy = 'ENTER') or (dummy = ' ');

  end;

  procedure ShowStatusMessagelog;
  var
    i: integer;
    dummy: string;
  begin

    dummy := '-';

    if UseSDL = True then
    begin
      TempAnsi := 'graphics/txtbg.jpg';
      LoadImage_Title('graphics/txtbg.jpg');
    end
    else
      ClearScreenSDL;

    repeat
      if UseSDL = True then
        BlitImage_Title
      else
      begin
        ClearScreenSDL;
        StatusDeco;
      end;

      TransTextXY(1, 1, 'MESSAGELOG (last 20 messages)');

      for i := 1 to 20 do
        if strMessageLog[i] <> '-' then
          TransTextXY(1, 2 + i, strMessageLog[i]);

      dummy := GetKeyInput('[ESC] Resume game', False);
    until (dummy = 'ESC');
  end;

  procedure ShowStatusQuestlog;
  var
    i, j, y, intViewPage: integer;
    dummy, colon: string;
    ch: char;
    strComplete: array[1..128] of string;
    // this array contains the complete list and is made
    // made visible in steps of 16
  begin

    if ThePlayer.blCoffeeBreak = true then
    begin
      DarkenScreen;
      GetKeyInput('In coffeebreak mode, no quests are available.', true);
    end
    else
    begin
      PlaySFX('page-turn.ogg');

      for i := 1 to 128 do
        strComplete[i] := '';

      // First, fill the array
      y := 1;
      for j := 1 to WinLevel do
        for i := 1 to 9 do
          if (ThePlayer.intQuestState[j, i] = 1) or
            (ThePlayer.intQuestState[j, i] = 2) then
          begin
            if j < 10 then // this for aligning numbers correctly.
              colon := '  '
            else
              colon := ' ';

            if ThePlayer.intQuestState[j, i] = 2 then
              colon := colon + ' :)  '
            else
              colon := colon + '     ';

            strComplete[y] := IntToStr(j) + '/' + IntToStr(i) + colon +
              Quest[j, i].strDescri;
            Inc(y);
          end;


      // Then, display the array pages
      ch := '-';
      dummy := '-';
      intViewPage := 1;

      if UseSDL = True then
      begin
        TempAnsi := 'graphics/decobg.jpg';
        LoadImage_Title('graphics/decobg.jpg');
      end
      else
        ClearScreenSDL;

      repeat

        if intViewPage < 1 then
          intViewPage := 1;

        if intViewPage > 8 then
          intViewPage := 8;

        repeat
          if UseSDL = True then
            BlitImage_Title
          else
          begin
            ClearScreenSDL;
            StatusDeco;
          end;

          TransTextXY(1, 1, 'QUESTLOG (Page ' + IntToStr(intViewPage) + '/8)');

          if intViewPage = 1 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[i]);

          if intViewPage = 2 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[16 + i]);

          if intViewPage = 3 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[32 + i]);

          if intViewPage = 4 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[48 + i]);

          if intViewPage = 5 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[64 + i]);

          if intViewPage = 6 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[80 + i]);

          if intViewPage = 7 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[96 + i]);

          if intViewPage = 8 then
            for i := 1 to 16 do
              TransTextXY(1, 4 + i, strComplete[112 + i]);

          dummy := GetKeyInput(
            '[+] or [PgDn] Next Page    [-] or [PgUp] Previous Page    [ESC] close',
            False);
        until (dummy = '+') or (dummy = '-') or (dummy = 'ESC');
        ch := dummy[1];

        case ch of
          '+':
            Inc(intViewPage);
          '-':
            Dec(intViewPage);
        end;

      until dummy = 'ESC';
    end;
  end;

  // Collected diplomas; view diplomas and their effects
  procedure DiplomaInfo;
  var
    dummy: string;
    Rankpin: array[1..30] of string;
    c: integer;
  begin

    c:=0;

    if UseSDL = True then
    begin
      TempAnsi := 'graphics/txtbg.jpg';
      LoadImage_Title('graphics/txtbg.jpg');
    end
    else
      ClearScreenSDL;

    if UseSDL = True then
    begin
      Rankpin[1] := chr(229) + '  ';
      Rankpin[2] := chr(229) + chr(229) + ' ';
      Rankpin[3] := chr(231) + '  ';
      Rankpin[4] := chr(231) + chr(231) + ' ';
      Rankpin[5] := chr(229) + chr(231) + chr(230);

      Rankpin[6] := chr(232) + '  ';
      Rankpin[7] := chr(232) + chr(232) + ' ';
      Rankpin[8] := chr(234) + '  ';
      Rankpin[9] := chr(234) + chr(234) + ' ';
      Rankpin[10] := chr(229) + chr(233) + chr(230);

      Rankpin[11] := chr(235) + chr(231) + chr(235);  // Assassin
      Rankpin[12] := chr(229) + chr(235) + chr(230); // Chief of Agents
      Rankpin[13] := chr(235) + '  ';  // Master Thief
      Rankpin[14] := chr(235) + chr(235) + ' '; // Chief of Thiefs

      Rankpin[15] := chr(236) + '  ';
      Rankpin[16] := chr(236) + chr(236) + ' ';
      Rankpin[17] := chr(236) + chr(231) + chr(236);
      Rankpin[18] := chr(229) + chr(236) + chr(230);
    end
    else
    begin
      Rankpin[1] := '<  ';
      Rankpin[2] := '<< ';
      Rankpin[3] := '^  ';
      Rankpin[4] := '^^ ';
      Rankpin[5] := '<^>';

      Rankpin[6] := '*  ';
      Rankpin[7] := '** ';
      Rankpin[8] := '|  ';
      Rankpin[9] := '|| ';
      Rankpin[10] := '<|>';

      Rankpin[11] := '/^/';  // Assassin
      Rankpin[12] := '</>';  // Chief of Agents
      Rankpin[13] := '/  ';  // Master Thief
      Rankpin[14] := '// ';  // Chief of Thiefs

      Rankpin[15] := '!  ';  // Ranger
      Rankpin[16] := '!! ';  // hunter
      Rankpin[17] := '!^!';  // marksman
      Rankpin[18] := '<!>';  // lieutenant
    end;



    repeat

      if UseSDL = True then
        BlitImage_Title
      else
        BottomBar;

      TransTextXY(3, 4, 'RANK                                                                  DST');

      if UseSDL=false then
        TransTextXY(3, 5, '-------------------------------------------------------------------------');

      if UseSDL=false then
        TransTextXY(41, 4, 'POWERS (cumulated)')
      else
        TransTextXY(36, 4, 'POWERS (cumulated)');

      // profession-dependant dipls
      case ThePlayer.intProf of
        2:   // enchanter
        begin

          if UseSDL=true then
          begin
            DrawEffectIcon(58, 370, 110, 1);
            DrawEffectIcon(9, 370, 150, ThePlayer.intDipl[6]);
            DrawEffectIcon(15, 370, 190, ThePlayer.intDipl[7]);
            DrawEffectIcon(3, 370, 230, ThePlayer.intDipl[8]);
            DrawEffectIcon(3, 370, 270, ThePlayer.intDipl[9]);
            DrawEffectIcon(20, 370, 310, ThePlayer.intDipl[10]);
          end;

          TransTextXY(3, 6, 'Enchanter');

          TransTextXY(3, 7, '|');

          if ThePlayer.intDipl[6] = 1 then // Mage
            TransTextXY(3, 8, '+--Mage ' + Rankpin[6])
          else
            TransTextXY(3, 8, '+--(Mage)');

          TransTextXY(3, 9, '|  |');

          if ThePlayer.intDipl[7] = 1 then // Battlemage
            TransTextXY(3, 10, '|  +--Battlemage ' + Rankpin[7])
          else
            TransTextXY(3, 10, '|  +--(Battlemage)');

          TransTextXY(3, 11, '|');

          if ThePlayer.intDipl[8] = 1 then // Monk
            TransTextXY(3, 12, '+--Believer ' + Rankpin[8])
          else
            TransTextXY(3, 12, '+--(Believer)');

          TransTextXY(3, 13, '   |');

          if ThePlayer.intDipl[9] = 1 then // Monk
            TransTextXY(3, 14, '   +--Monk ' + Rankpin[9])
          else
            TransTextXY(3, 14, '   +--(Monk)');

          TransTextXY(3, 15, '      |');

          if ThePlayer.intDipl[10] = 1 then // Holy Warrior
            TransTextXY(3, 16, '      +--Holy Warrior ' + Rankpin[10])
          else
            TransTextXY(3, 16, '      +--(Holy Warrior)');

          TransTextXY(41, 6,  'Poet          CLV+5 area dmg.    10');
          TransTextXY(41, 8,  'Sopranist     CLV ice aura       10');
          TransTextXY(41, 10, 'Heldentenor   CLV barrier        20');
          TransTextXY(41, 12, 'Psalm         CLV*2 PP reg.      20');
          TransTextXY(41, 14, 'Gradual       CLV*4 PP reg.      30');
          TransTextXY(41, 16, 'Hymn          CLV purify         10');

        end;

        3:   // thief
        begin

          if UseSDL=true then
          begin
            DrawEffectIcon(39, 370, 110, 1);
            DrawEffectIcon(5, 370, 150, ThePlayer.intDipl[11]);
            DrawEffectIcon(5, 370, 190, ThePlayer.intDipl[12]);
            //DrawEffectIcon(3, 370, 230, ThePlayer.intDipl[13]);
            //DrawEffectIcon(3, 370, 270, ThePlayer.intDipl[14]);
          end;

          TransTextXY(3, 6, 'Thief');

          TransTextXY(3, 7, '|');

          if ThePlayer.intDipl[11] = 1 then // Assassin
            TransTextXY(3, 8, '+--Assassin ' + Rankpin[11])
          else
            TransTextXY(3, 8, '+--(Assassin)');

          TransTextXY(3, 9, '|  |');

          if ThePlayer.intDipl[12] = 1 then // Chief of Agents
            TransTextXY(3, 10, '|  +--Agent ' + Rankpin[12])
          else
            TransTextXY(3, 10, '|  +--(Agent)');


          TransTextXY(3, 11, '|');

          if ThePlayer.intDipl[13] = 1 then // Master Thief
            TransTextXY(3, 12, '+--Master Thief ' + Rankpin[13])
          else
            TransTextXY(3, 12, '+--(Master Thief)');

          TransTextXY(3, 13, '   |');

          if ThePlayer.intDipl[14] = 1 then // Guild Leader
            TransTextXY(3, 14, '   +--Guild Leader ' + Rankpin[14])
          else
            TransTextXY(3, 14, '   +--(Guild Leader)');

          TransTextXY(41, 6,  'Cold Blood   GP ice dmg.          5');
          TransTextXY(41, 8,  'Typhoon      5 Invis.            20');
          TransTextXY(41, 10, 'Akula        CLV+5 Invis.        20');
          TransTextXY(41, 12, 'Tax Payer*   steal 2x Credits    20');
          TransTextXY(41, 14, 'On Sale*     steal 2 items       35');

        end;

        4:   // archer
        begin

          if UseSDL=true then
          begin
            DrawEffectIcon(38, 370, 110, 1);
            //DrawEffectIcon(5, 370, 150, ThePlayer.intDipl[15]);
            DrawEffectIcon(45, 370, 190, ThePlayer.intDipl[16]);
            //DrawEffectIcon(3, 370, 230, ThePlayer.intDipl[17]);
            DrawEffectIcon(56, 370, 270, ThePlayer.intDipl[18]);
          end;

          TransTextXY(3, 6, 'Archer');

          TransTextXY(3, 7, '|');

          if ThePlayer.intDipl[15] = 1 then // Hunter
            TransTextXY(3, 8, '+--Hunter ' + Rankpin[15])
          else
            TransTextXY(3, 8, '+--(Hunter)');

          TransTextXY(3, 9, '|  |');

          if ThePlayer.intDipl[16] = 1 then // Ranger
            TransTextXY(3, 10, '|  +--Ranger ' + Rankpin[16])
          else
            TransTextXY(3, 10, '|  +--(Ranger)');

          TransTextXY(3, 11, '|');

          if ThePlayer.intDipl[17] = 1 then // Marksman
            TransTextXY(3, 12, '+--Marksman ' + Rankpin[17])
          else
            TransTextXY(3, 12, '+--(Marksman)');

          TransTextXY(3, 13, '   |');

          if ThePlayer.intDipl[18] = 1 then // Lieutenant
            TransTextXY(3, 14, '   +--Lieutenant ' + Rankpin[18])
          else
            TransTextXY(3, 14, '   +--(Lieutenant)');

          TransTextXY(41, 6,  'Shooting Star  GP fire dmg.      10');
          TransTextXY(41, 8,  'Mighty Bow*    +1 GP             10');
          TransTextXY(41, 10, 'Herbalism      GP poison dmg.    35');
          TransTextXY(41, 12, 'Eagle Eye*     +1 Hit            15');
          TransTextXY(41, 14, 'Taser          GP elec. dmg.     30');

        end;


        5:   // soldier
        begin

          if UseSDL=true then
          begin
            DrawEffectIcon(58, 370, 110, 1);
            //DrawEffectIcon(5, 370, 150, ThePlayer.intDipl[1]);
            DrawEffectIcon(58, 370, 190, ThePlayer.intDipl[2]);
            //DrawEffectIcon(3, 370, 230, ThePlayer.intDipl[3]);
            DrawEffectIcon(58, 370, 270, ThePlayer.intDipl[4]);
            // 5
          end;

          TransTextXY(3, 6, 'Soldier');

          TransTextXY(3, 7, '|');

          if ThePlayer.intDipl[1] = 1 then // Centurio
            TransTextXY(3, 8, '+--Centurio ' + Rankpin[1])
          else
            TransTextXY(3, 8, '+--(Centurio)');

          TransTextXY(3, 9, '   |');

          if ThePlayer.intDipl[2] = 1 then // Hastatus
            TransTextXY(3, 10, '   +--Hastatus ' + Rankpin[2])
          else
            TransTextXY(3, 10, '   +--(Hastatus)');

          TransTextXY(3, 11, '      |');

          if ThePlayer.intDipl[3] = 1 then // Princeps
            TransTextXY(3, 12, '      +--Princeps ' + Rankpin[3])
          else
            TransTextXY(3, 12, '      +--(Princeps)');

          TransTextXY(3, 13, '         |');

          if ThePlayer.intDipl[4] = 1 then // Pilus
            TransTextXY(3, 14, '         +--Pilus ' + Rankpin[4])
          else
            TransTextXY(3, 14, '         +--(Pilus)');

          TransTextXY(3, 15, '            |');

          if ThePlayer.intDipl[5] = 1 then // Primus Pilus
            TransTextXY(3, 16, '            +--Primus Pilus ' + Rankpin[5])
          else
            TransTextXY(3, 16, '            +--(Primus Pilus)');

          TransTextXY(41, 6,  'Turbulence     5 area dmg.        5');
          TransTextXY(41, 8,  'Hard Attack*   +1 WP             10');
          TransTextXY(41, 10, 'Vortex         CLV+5 area dmg.   15');
          TransTextXY(41, 12, 'Speedrun*      +1 Move           20');
          TransTextXY(41, 14, 'Maelstrom      CLV+10 area dmg.  25');
          TransTextXY(41, 16, 'Steady State*  +1 AP             25');

        end;

      end;

      TransTextXY(1, 1, 'YOUR RANKS, POWERS AND DIVINE RAGE');

      if UseSDL=false then
        TransTextXY(3, 18, 'Bracketed ranks haven''t been gained.                            *passive')
      else
        TransTextXY(3, 18, '                                                                 *passive');

      TransTextXY(1, 21, 'DIVINE RAGE:');

      c := 100 - (CollectHumility*5);
      if c>100 then
        c:=100;
      if c<50 then
        c:=50;

      if ThePlayer.intReli=1 then
        TransTextXY(14, 21, 'Aphrodite''s Passion (restore HP; DST: '+IntToStr(c)+')');
      if ThePlayer.intReli=2 then
        TransTextXY(14, 21, 'Hermes'' Inspiration (restore PP; DST: '+IntToStr(c)+')');
      if ThePlayer.intReli=3 then
        TransTextXY(14, 21, 'Apolls'' Arrow (Move +'+IntToStr(CollectHumility)+'; DST: '+IntToStr(c)+')');
      if ThePlayer.intReli=4 then
        TransTextXY(14, 21, 'Dionysa''s Fine Wine (STR +'+IntToStr(CollectHumility)+'; DST: '+IntToStr(c)+')');
      if ThePlayer.intReli=5 then
        TransTextXY(14, 21, 'Warhammer of Ares ('+ IntToStr(ThePlayer.intLvl+(CollectHumility*2))+' area dmg.; DST: '+IntToStr(c)+')');

      dummy := GetKeyInput('[ESC] close', False);
    until (dummy = 'ESC');
  end;

  // Tidy status screen
  procedure TidyPlayerStatus;
  var
    strSex, strProf, strDiff, dummy: string;
    ToNextLevel: longint;
    ch: char;
    blCloseScreen: boolean;
  begin

    DarkenScreen;

    blCloseScreen := False;

    repeat

      if UseSDL = True then
      begin
        if ThePlayer.intSex = 1 then
          TempAnsi := 'graphics/' + IntToStr(ThePlayer.intProf) + '-m.jpg'
        else
          TempAnsi := 'graphics/' + IntToStr(ThePlayer.intProf) + '-f.jpg';
        LoadImage_Title(TempAnsi);
      end
      else
        ClearScreenSDL;


      repeat

        if UseSDL = True then
          BlitImage_Title
        else
          BottomBar;

        case ThePlayer.intSex of
          1:
            strSex := 'male';
          2:
            strSex := 'female';
        end;

        case ThePlayer.intProf of
          1:
            strProf := 'constructor';
          2:
            strProf := 'enchanter';
          3:
            strProf := 'thief';
          4:
            strProf := 'archer';
          5:
            strProf := 'soldier';
        end;

        case DiffLevel of
          1:
            strDiff := 'Bronze';
          2:
            strDiff := 'Silver';
          3:
            strDiff := 'Gold';
        end;

        if ThePlayer.blEvil = True then
          TransTextXY(1, 1, uppercase(ThePlayer.strName + ', DEVOTED TO DEATH'))
        else
          TransTextXY(1, 1, uppercase(ThePlayer.strName + ', ' +
            strSex + ' ' + strProf));


        ToNextLevel := (ThePlayer.intLvl * CONST_LVL_MULTI) *
          (ThePlayer.intLvl * CONST_LVL_MULTI) * ThePlayer.intLvl;

        TransTextXY(1, 4, 'HP  : ' + IntToStr(ThePlayer.intHP) + '/' +
          IntToStr(ThePlayer.intMaxHP));
        TransTextXY(1, 5, 'PP  : ' + IntToStr(ThePlayer.intPP) + '/' +
          IntToStr(ThePlayer.intMaxPP));
        TransTextXY(1, 7, 'STR : ' + IntToStr(ThePlayer.intStrength) + '%/100%');
        TransTextXY(1, 8, 'DST : ' + IntToStr(ThePlayer.intLimit) + '%/100%');

        if ThePlayer.intLvl < CONST_MAXCLV then
          TransTextXY(1, 10, 'EXP : ' + IntToStr(ThePlayer.longEXP) +
            ' (Next: ' + IntToStr(ToNextLevel) + ')')
        else
          TransTextXY(1, 10, 'EXP : ' + IntToStr(ThePlayer.longEXP));

        TransTextXY(1, 11, 'CLV : ' + IntToStr(ThePlayer.intLvl) + ' (' + strDiff + ')');

        if DungeonLevel < 20 then
          TransTextXY(1, 13, 'DLV : ' + IntToStr(DungeonLevel));
        if (DungeonLevel = 20) or (DungeonLevel = 21) then
          TransTextXY(1, 13, 'DLV : ?');
        if DungeonLevel > 21 then
          TransTextXY(1, 13, 'DLV : ' + IntToStr(DungeonLevel - 21));

        // abilities

        if CollectFight > ThePlayer.intFight then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 4, 'Fight    : ' + IntToStr(ThePlayer.intFight) + '+' + IntToStr(CollectFight-ThePlayer.intFight));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 4, 'Fight    : ' + IntToStr(ThePlayer.intFight));

        if CollectHit > ThePlayer.intView then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 5, 'Hit      : ' + IntToStr(ThePlayer.intView) + '+' + IntToStr(CollectHit-ThePlayer.intView));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 5, 'Hit      : ' + IntToStr(ThePlayer.intView));

        if CollectChant > ThePlayer.intChant then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 6, 'Chant    : ' + IntToStr(ThePlayer.intChant) + '+' + IntToStr(CollectChant-ThePlayer.intChant));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 6, 'Chant    : ' + IntToStr(ThePlayer.intChant));

        if CollectMove > ThePlayer.intMove then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 7, 'Move     : ' + IntToStr(ThePlayer.intMove) + '+' + IntToStr(CollectMove-ThePlayer.intMove));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 7, 'Move     : ' + IntToStr(ThePlayer.intMove));

        TransTextXY(30, 8, 'Steal    : ' + IntToStr(ThePlayer.intBurgle));

        // skills
        if CollectSword > ThePlayer.intSword then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 10, 'Sword    : ' + IntToStr(ThePlayer.intSword) + '+' + IntToStr(CollectSword-ThePlayer.intSword));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 10, 'Sword    : ' + IntToStr(ThePlayer.intSword));

        if CollectAxe > ThePlayer.intAxe then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 11, 'Axe      : ' + IntToStr(ThePlayer.intAxe) + '+' + IntToStr(CollectAxe-ThePlayer.intAxe));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 11, 'Axe      : ' + IntToStr(ThePlayer.intAxe));

        if CollectWhip > ThePlayer.intWhip then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 12, 'Lance    : ' + IntToStr(ThePlayer.intWhip) + '+' + IntToStr(CollectWhip-ThePlayer.intWhip));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 12, 'Lance    : ' + IntToStr(ThePlayer.intWhip));

        if CollectGun > ThePlayer.intGun then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 13, 'Fire-arm : ' + IntToStr(ThePlayer.intGun) + '+' + IntToStr(CollectGun-ThePlayer.intGun));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 13, 'Fire-arm : ' + IntToStr(ThePlayer.intGun));


        TransTextXY(30, 14, 'Tool     : ' + IntToStr(ThePlayer.intTool));

        // talents
        if CollectHumility > ThePlayer.intHumility then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := lightgreen;
          TransTextXY(30, 16, 'Humility : ' + IntToStr(ThePlayer.intHumility) + '+' + IntToStr(CollectHumility-ThePlayer.intHumility));
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;
        end
        else
          TransTextXY(30, 16, 'Humility : ' + IntToStr(ThePlayer.intHumility));


        TransTextXY(30, 17, 'Trade    : ' + IntToStr(ThePlayer.intTrade));


        TransTextXY(53, 4, 'Melee        : ' + IntToStr(CollectTP));
        TransTextXY(53, 5, 'Long-range   : ' + IntToStr(CollectGunTP));
        TransTextXY(53, 6, 'Defense      : ' + IntToStr(CollectDP));

        if ThePlayer.blOffensive = True then
          TransTextXY(53, 8, 'Tactics      : offensive')
        else
          TransTextXY(53, 8, 'Tactics      : defensive');

        TransTextXY(53, 11, 'Skill Points : ' + IntToStr(ThePlayer.longSkillPoints));

        TransTextXY(1, 20, ThePlayer.strName + ' is active since ' +
          IntToStr(longTotalTurns) + ' turn(s) and has achieved a score of ' +
          IntToStr(ThePlayer.longScore) + '.');
        TransTextXY(1, 21, ThePlayer.strName + ' has prayed to ' +
          ThePlayer.strReli + ' ' + IntToStr(ThePlayer.longPrayers) + ' time(s).');

        dummy := GetKeyInput('[q]uests  [p]owers/ranks  [m]essages  [e]quipment summary   [ESC] Resume game', False);
      until (dummy = 'q') or (dummy = 'm') or (dummy = 'e') or
        (dummy = 'p') or (dummy = 'ESC');

      if dummy <> 'ESC' then
      begin
        ch := dummy[1];

        case ch of
          'q':
            ShowStatusQuestlog;
          'm':
            ShowStatusMessagelog;
          'e':
            EquipmentInfo;
          'p':
            DiplomaInfo;
        end;
      end
      else
        blCloseScreen := True;

    until blCloseScreen = True;

  end;


  // clears all values for new players
  procedure ClearPlayer;
  begin
    DungeonLevel := 1;
    ThePlayer.intLvl := 1;

    ThePlayer.longExp := 0;
    ThePlayer.longThisLevelEXP := 0;
    ThePlayer.longGold := 0;

    ThePlayer.longSkillPoints := 0;
    ThePlayer.longScore := 0;

    ThePlayer.blNold := false;

    ThePlayer.longPrayers := 0;

    ThePlayer.blDead := False;
    ThePlayer.blQuiet := False;

    ThePlayer.intMaxHP := 55;
    ThePlayer.intMaxPP := 10;
    ThePlayer.intStrength := 100;

    ThePlayer.intTotalVitari := 0;
    ThePlayer.intNextVitari := 0;
    ThePlayer.intNeedVitari := 0;

    ThePlayer.intFight := 3 + trunc(random(4));
    ThePlayer.intMove := 1 + trunc(random(3));

    ThePlayer.intChant := 1 + trunc(random(3));

    ThePlayer.intBurgle := 1 + trunc(random(3));

    ThePlayer.intView := 1 + trunc(random(4));

    ThePlayer.intHumility := 1 + trunc(random(3));


    ThePlayer.intSword := 3 + trunc(random(3));

    ThePlayer.intAxe := 3 + trunc(random(3));

    ThePlayer.intWhip := 3 + trunc(random(3));

    ThePlayer.intGun := 3 + trunc(random(3));

    ThePlayer.intTool := 1 + trunc(random(3));

    ThePlayer.intTrade := 1 + trunc(random(3));

    ThePlayer.intBirthLevel := 1;  // as default, all were born in the temple
    ThePlayer.intRelParents := 1;  // as default, all have good relation to parents
    ThePlayer.intEventLevel := 22;
    // as default, the important event in childhood took place in outskirts

    ThePlayer.longFood := 1500;
    ThePlayer.longGold := 150 + trunc(random(150));

    Storage.longWood := 0;
    Storage.longMetal := 0;
    Storage.longStone := 0;
    Storage.longLeather := 0;
    Storage.longPlastics := 0;
    Storage.longPaper := 0;

    ThePlayer.longContCleared := 0;
    ThePlayer.longScore := 0;

    // empty inventory and spellbook
    for i := 1 to 16 do
    begin
      inventory[i].intType := 0;
      inventory[i].longNumber := 0;
      spellbook[i].intType := 0;
      spellbook[i].blKnown := False;
      spellbook[i].intKnown := 0;
      spellbook[i].intRefresh := 0;
    end;

    // clear diplomas and hive status
    for i := 1 to 30 do
    begin
      ThePlayer.intDipl[i] := 0;
      intNoHivesAnymore[i] := 0;
    end;

    // set effects to zero
    ThePlayer.intPoison := 0;
    ThePlayer.intConfusion := 0;
    ThePlayer.intBlind := 0;
    ThePlayer.intSleep := 0;
    ThePlayer.intWall := 0;
    ThePlayer.intPara := 0;
    ThePlayer.intCalm := 0;
    ThePlayer.intFreeze := 0;
    ThePlayer.intInvis := 0;
    ThePlayer.blCursed := False;
    ThePlayer.blBlessed := False;
    ThePlayer.blEvil := False;
    ThePlayer.intLastSong := 0;

    for i := 1 to 100 do
      ThePlayer.intTempResist[i] := 0;

    for i := 1 to 200 do
      ThePlayer.blUnKilled[i] := False;

    for i := 1 to 200 do
      ThePlayer.longKilled[i] := 0;

    // no quests at startup
    for i := 1 to WinLevel do
      for j := 1 to 9 do
        ThePlayer.intQuestState[i, j] := 0;

    // no story files
    for i := 1 to 80 do
      ThePlayer.blStory[i] := False;

    // all visits to 0
    for i := 1 to WinLevel do
      ThePlayer.longLevelVisits[i] := 0;

    longTotalTurns := 0;
    ThePlayer.longLifeIns := 0;

    ThePlayer.intLimit := 0;

    // empty messagelog
    for i := 1 to 20 do
      strMessageLog[i] := '-';

  end;


  // final player inits
  procedure FinalizePlayer(blGiveWeapon: boolean);
  var
    i: integer;
  begin
    ThePlayer.intHP := ThePlayer.intMaxHP;
    ThePlayer.intPP := ThePlayer.intMaxPP;


    // initialize time and day
    intDay := trunc(random(16)) + 1;
    intDayTime := trunc(random(240) + 1);
    longYear := 1715;

    // give start weapon (depending on highest weapon skill)
    if blGiveWeapon = True then
    begin
      ThePlayer.intWeapon := -1;

      // - sword
      if (ThePlayer.intSword > ThePlayer.intAxe) and
        (ThePlayer.intSword > ThePlayer.intWhip) and
        (ThePlayer.intSword > ThePlayer.intGun) then
      begin
        ThePlayer.intWeapon := ReturnItemByName('Dagger');
      end;

      // - axe
      if (ThePlayer.intAxe > ThePlayer.intSword) and
        (ThePlayer.intAxe > ThePlayer.intWhip) and
        (ThePlayer.intAxe > ThePlayer.intGun) then
      begin
        ThePlayer.intWeapon := ReturnItemByName('Axe');
      end;

      // - lance
      if (ThePlayer.intWhip > ThePlayer.intAxe) and
        (ThePlayer.intWhip > ThePlayer.intSword) and
        (ThePlayer.intWhip > ThePlayer.intGun) then
      begin
        ThePlayer.intWeapon := ReturnItemByName('Lance');
      end;

      // - bow
      if (ThePlayer.intGun > ThePlayer.intSword) and
        (ThePlayer.intGun > ThePlayer.intWhip) and
        (ThePlayer.intGun > ThePlayer.intAxe) then
      begin
        ThePlayer.intWeapon := ReturnItemByName('Bow');
        Inventory[3].intType := ReturnItemByName('Small Arrows');
        Inventory[3].longNumber := 200;
      end;

      // no weapon set?
      if ThePlayer.intWeapon = -1 then
      begin
        ThePlayer.intWeapon := ReturnItemByName('Dagger');
      end;

    end;

    intAchieved := 0;
    StoreAchievement('Begins a new journey.');

  end;


  // create: Difficulty
  procedure CreateDifficulty;
  var
    dummy: string;
  begin
    // Difficulty
    ClearScreenSDL;

    repeat
      if UseSDL = True then
        BlitImage_Title
      else
      begin
        DialogWin;
        StatusDeco;
      end;

      TransTextXY(1, 1, 'STARTING A NEW JOURNEY');
      TransTextXY(8, 7, 'Which difficulty level do you desire?');
      TransTextXY(8, 9, 'Key   Level');
      TransTextXY(8, 11, ' 1    Bronze       (easier)');
      TransTextXY(8, 12, ' 2    Silver       (standard)');
      TransTextXY(8, 13, ' 3    Gold         (harder)');

      dummy := GetKeyInput('Press the according key to select a difficulty level.',
        False);
    until (dummy = '1') or (dummy = '2') or (dummy = '3');

    DiffLevel := StrToInt(dummy);
  end;


  procedure CreateBiography(blShowBio: boolean);
  var
    i, nn, intVitaBonus: integer;
    strVitaRelationship, strVitaFather, strVitaMother1, strVitaMother2, strVitaEyes, strVitaHair1, strVitaHair2: string;
  begin
    // 0. biography
    strVitaRelationship := '';
    i := trunc(random(10));
    case i of
      0:
        strVitaRelationship := 'loved';
      1:
        strVitaRelationship := 'grown';
      2:
        strVitaRelationship := 'hated';
      3:
        strVitaRelationship := 'pampered';
      4:
        strVitaRelationship := 'watched carefully';
      5:
        strVitaRelationship := 'denied';
      6:
        strVitaRelationship := 'admired';
      7:
        strVitaRelationship := 'seen sceptically';
      8:
        strVitaRelationship := 'forced to work';
      9:
        strVitaRelationship := 'abandoned';
    end;

    intVitaBonus := 0;

    // very good relationship
    if (i = 0) or (i = 6) then
    begin
      intVitaBonus := 3;
      ThePlayer.intRelParents := 1;
    end;

    // bad relationship
    if (i = 2) or (i = 5) or (i = 9) then
    begin
      intVitaBonus := -2;
      ThePlayer.intRelParents := 2;
    end;

    // good relationship
    if (i = 1) or (i = 3) or (i = 4) or (i = 7) or (i = 8) then
    begin
      intVitaBonus := 0;
      ThePlayer.intRelParents := 3;
    end;

    nn := i;

    strVitaFather := '';
    i := 1 + trunc(random(4));
    case i of
      //0:
      //begin
      //strVitaFather:='a constructor';
      //inc(ThePlayer.intTool,intVitaBonus); // tool
      //end;
      1:
      begin
        strVitaFather := 'an enchanter';
        Inc(ThePlayer.intChant, intVitaBonus); // chant
      end;
      2:
      begin
        strVitaFather := 'a thief';
        Inc(ThePlayer.intBurgle, intVitaBonus); // burgle
      end;
      3:
      begin
        strVitaFather := 'an archer';
        Inc(ThePlayer.intGun, intVitaBonus); // fire-arm
      end;
      4:
      begin
        strVitaFather := 'a soldier';
        Inc(ThePlayer.intFight, intVitaBonus); // fight
      end;
    end;

    strVitaMother1 := '';
    i := trunc(random(11));
    case i of
      0:
        strVitaMother1 := 'beautiful';
      1:
        strVitaMother1 := 'young';
      2:
        strVitaMother1 := 'old';
      3:
        strVitaMother1 := 'lovely';
      4:
        strVitaMother1 := 'sad';
      5:
        strVitaMother1 := 'small';
      6:
        strVitaMother1 := 'impressive';
      7:
        strVitaMother1 := 'creative';
      8:
        strVitaMother1 := 'loving';
      9:
        strVitaMother1 := 'caring';
      10:
        strVitaMother1 := 'depressive';
    end;

    strVitaMother2 := '';
    i := trunc(random(5));
    case i of
      0:
        strVitaMother2 := 'wife';
      1:
        strVitaMother2 := 'friend';
      2:
        strVitaMother2 := 'lover';
      3:
        strVitaMother2 := 'concubine';
      4:
        strVitaMother2 := 'cousin';
    end;

    strVitaEyes := '';
    i := trunc(random(7));
    case i of
      0:
        strVitaEyes := 'blue';
      1:
        strVitaEyes := 'blue-gray';
      2:
        strVitaEyes := 'gray';
      3:
        strVitaEyes := 'black';
      4:
        strVitaEyes := 'brown';
      5:
        strVitaEyes := 'green';
      6:
        strVitaEyes := 'silver';
    end;

    strVitaHair1 := '';
    i := trunc(random(4));
    case i of
      0:
        strVitaHair1 := 'short';
      1:
        strVitaHair1 := 'long';
      2:
        strVitaHair1 := 'thin';
      3:
        strVitaHair1 := 'dense';
    end;

    strVitaHair2 := '';
    i := trunc(random(6));
    case i of
      0:
        strVitaHair2 := 'brown';
      1:
        strVitaHair2 := 'blonde';
      2:
        strVitaHair2 := 'black';
      3:
        strVitaHair2 := 'red';
      4:
        strVitaHair2 := 'white';
      5:
        strVitaHair2 := 'light brown';
    end;

    ThePlayer.strVita := ThePlayer.strName + ' was the child of ' +
      strVitaFather + ' and his ' + strVitaMother1 + ' ' + strVitaMother2 + '.';
    ThePlayer.strDescription :=
      ThePlayer.strName + chr(39) + 's eyes were ' + strVitaEyes +
      ' and the ' + strVitaHair1 + ' hair was ' + strVitaHair2 + '.';

    // place of birth
    ThePlayer.intBirthLevel := 1 + trunc(random(5));
    if ThePlayer.intBirthLevel = 6 then
      ThePlayer.intBirthLevel := 22;

    // can't use magic?
    if random(500)>450 then ThePlayer.blQuiet := true;

    // place of event in youth
    ThePlayer.intEventLevel := ThePlayer.intBirthLevel;
    repeat
      ThePlayer.intEventLevel := 2 + trunc(random(10));
    until ThePlayer.intEventLevel <> ThePlayer.intBirthLevel;

    if blShowBio = True then
    begin
      ClearScreenSDL;

      if UseSDL = True then
        BlitImage_Title
      else
      begin
        DialogWin;
        StatusDeco;
      end;

      TransTextXY(1, 1, 'BIOGRAPHY OF ' + uppercase(ThePlayer.strName));

      TransTextXY(8, 9, ThePlayer.strName + ', you were born in ' +
        ReturnLevelName(ThePlayer.intBirthLevel) + '.');

      TransTextXY(8, 10, 'Your father was ' + strVitaFather + '.');
      TransTextXY(8, 11, 'With his ' + strVitaMother1 + ' ' +
        strVitaMother2 + ', he gave you life.');
      TransTextXY(8, 12, 'You were ' + strVitaRelationship + ' by your parents.');

      if (nn = 0) or (nn = 6) then
      begin
        TransTextXY(8, 13, 'Watching your father at work gave you some deeper');
        TransTextXY(8, 14, 'knowledge about being ' + strVitaFather + '.');
      end;

      if (nn = 2) or (nn = 5) or (nn = 9) then
      begin
        TransTextXY(8, 13, 'Because of the bad relationship to your father in');
        TransTextXY(8, 14, 'your youth, you decided to refuse all his knowledge.');
      end;

      if (nn = 1) or (nn = 3) or (nn = 4) or (nn = 7) or (nn = 8) then
      begin
        TransTextXY(8, 13, 'Although you loved your father, his profession as');
        TransTextXY(8, 14, strVitaFather + ' made no strong impression to you.');
      end;

      if ThePlayer.blQuiet=true then
      begin
        TransTextXY(8, 15, 'Due to a curse by a jealous enchanter, you are not');
        TransTextXY(8, 16, 'able to chant magical songs.');
        ThePlayer.intPP:=0;
        ThePlayer.intMaxPP:=0;
      end;

      TransTextXY(8, 18, 'Your eyes are ' + strVitaEyes + ' and your ' +
        strVitaHair1 + ' hair is ' + strVitaHair2 + '.');

      GetKeyInput('[Press any key to continue]', False);
    end;
  end;

  // quick-create player
  procedure CreatePlayerFast;
  var
    i: integer;
    dummy: string;
  begin

    ClearPlayer;

    // CreateDifficulty;
    DiffLevel := 2;
    CreateBiography(False);

    // selection
    ClearScreenSDL;

    DialogWin;
    StatusDeco;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/invbg.jpg');
    end;

    dummy := '-';
    repeat

      if UseSDL = True then
        BlitImage_Title
      else
      begin
        DialogWin;
        BottomBar;
      end;

      TransTextXY(1, 1, 'SELECT A PREDEFINED EDUCATION');
      TransTextXY(8, 7, 'How do you want to start?');
      TransTextXY(8, 9, 'Key   Start as');
      TransTextXY(8, 11, ' 1    male soldier, believer in Ares           (easy)');
      TransTextXY(8, 12, ' 2    female archer, believer in Aphrodite     (moderate)');
      TransTextXY(8, 13, ' 3    male enchanter, believer in Hermes       (very easy)');
      TransTextXY(8, 14, ' 4    female thief, believer in Apoll          (challenging)');
      TransTextXY(8, 16, 'Note that the beginning of the game is much easier with one of');
      TransTextXY(8, 17, 'these presets than it would be by starting from scratch, be-');
      TransTextXY(8, 18, 'cause you will start with better equipment and higher skills.');

      dummy := GetKeyInput('Press the according key to select a preset.', False);
    until (dummy = '1') or (dummy = '2') or (dummy = '3') or (dummy = '4');

    i := StrToInt(dummy);

    // male soldier
    if i = 1 then
    begin
      ThePlayer.intReli := 5;
      ThePlayer.strReli := 'Ares';

      ThePlayer.intSex := 1;
      Inc(ThePlayer.intMaxHP, 3 + trunc(random(4)));

      ThePlayer.intProf := 5;
      Inc(ThePlayer.intMove, 3);

      ThePlayer.intFight := 7;
      ThePlayer.intSword := 8;
      ThePlayer.intWhip := 5;

      ThePlayer.intWeapon := ReturnItemByName('Sword');
      ThePlayer.intArmour := ReturnItemByName('Leather Suit');
      ThePlayer.intExtra := ReturnItemByName('Wooden Shield');
      ThePlayer.intFeet := ReturnItemByName('Walking Shoes');

      inventory[1].intType := ReturnItemByName('Aspirin');
      inventory[1].longNumber := 20;
      strQuickKey[1] := 'Aspirin';

      inventory[2].intType := ReturnItemByName('Meat');
      inventory[2].longNumber := 1;

    end;

    // female archer
    if i = 2 then
    begin
      ThePlayer.intReli := 1;
      ThePlayer.strReli := 'Aphrodite';
      Inc(ThePlayer.intMove, 2);

      ThePlayer.intSex := 2;
      Inc(ThePlayer.intMove);

      ThePlayer.intProf := 4;
      Inc(ThePlayer.intView, 4);
      Inc(ThePlayer.longGold, 50);

      ThePlayer.intGun := 11;
      ThePlayer.intWeapon := ReturnItemByName('Longbow');
      ThePlayer.intArmour := ReturnItemByName('Leather Suit');
      ThePlayer.intFeet := ReturnItemByName('Walking Shoes');

      inventory[1].intType := ReturnItemByName('Long Arrows');
      inventory[1].longNumber := 300;
      inventory[2].intType := ReturnItemByName('Aspirin');
      inventory[2].longNumber := 20;
      strQuickKey[1] := 'Aspirin';
      inventory[3].intType := ReturnItemByName('Meat');
      inventory[3].longNumber := 1;
    end;

    // male enchanter
    if i = 3 then
    begin
      ThePlayer.intReli := 2;
      ThePlayer.strReli := 'Hermes';
      Inc(ThePlayer.intWhip, 2);

      ThePlayer.intSex := 1;
      Inc(ThePlayer.intMaxHP, 3 + trunc(random(4)));

      ThePlayer.intProf := 2;
      Inc(ThePlayer.intMaxPP, 50);
      Inc(ThePlayer.intView, 4);

      ThePlayer.intFight := 7;
      ThePlayer.intChant := 10;
      ThePlayer.intSword := 8;

      ThePlayer.intWeapon := ReturnItemByName('Sword');
      ThePlayer.intArmour := ReturnItemByName('Leather Suit');
      ThePlayer.intFeet := ReturnItemByName('Walking Shoes');

      inventory[1].intType := ReturnItemByName('Cola');
      inventory[1].longNumber := 10;
      Thing[ReturnItemByName('Cola')].blIdentified := True;
      Thing[ReturnItemByName('Cola')].strName :=
        Thing[ReturnItemByName('Cola')].strRealName;
      strQuickKey[12] := 'Cola';

      spellbook[1].intType := ReturnSpellByName('Flame');
      spellbook[1].intKnown := 1;
      spellbook[1].intRefresh := spell[spellbook[1].intType].intRefresh;
      strQuickKey[1] := 'Flame';

      spellbook[2].intType := ReturnSpellByName('Cold');
      spellbook[2].intKnown := 1;
      spellbook[2].intRefresh := spell[spellbook[2].intType].intRefresh;
      strQuickKey[2] := 'Cold';

      inventory[2].intType := ReturnItemByName('Meat');
      inventory[2].longNumber := 1;

    end;

    // female thief
    if i = 4 then
    begin
      ThePlayer.intReli := 3;
      ThePlayer.strReli := 'Apoll';
      Inc(ThePlayer.intBurgle, 7);

      ThePlayer.intSex := 2;
      Inc(ThePlayer.intMove);

      ThePlayer.intProf := 3;

      ThePlayer.intSword := 6;

      ThePlayer.intWeapon := ReturnItemByName('Rusty Dagger');
      ThePlayer.intFeet := ReturnItemByName('Walking Shoes');

      inventory[1].intType := ReturnItemByName('Aspirin');
      inventory[1].longNumber := 20;
      strQuickKey[1] := 'Aspirin';

      inventory[2].intType := ReturnItemByName('Picklock');
      inventory[2].longNumber := 1;

    end;

    FinalizePlayer(False);
  end;


// choose profession, religion and sex
procedure ChoosePlayerBasics;
var
  dummy: string;
  ps, rs, ss: integer;
begin
  ClearScreenSDL;
  if UseSDL = True then
  begin
    LoadImage_Title('graphics/invbg.jpg');
  end;

  ps := 1;
  ss := 1;
  rs := 1;

  dummy:='-';
  repeat
    if UseSDL = True then
      BlitImage_Title
    else
    begin
      DialogWin;
      StatusDeco;
    end;

    //TransTextXY(1, 1, 'CHARACTER GENERATION');

    TransTextXY(1, 4, 'CHOOSE YOUR PROFESSION');
    TransTextXY(1, 6, '1  Enchanter');
    TransTextXY(1, 7, '2  Thief');
    TransTextXY(1, 8, '3  Archer');
    TransTextXY(1, 9, '4  Soldier');

    TransTextXY(50, 4,  'CHOOSE YOUR RELIGION');
    TransTextXY(50, 6,  'a  Aphrodite');
    TransTextXY(50, 7,  'b  Hermes');
    TransTextXY(50, 8,  'c  Apoll');
    TransTextXY(50, 9,  'd  Dionysa');
    TransTextXY(50, 10, 'e  Ares');

    if rs=1 then
    begin
      SmallTextXY(71, 30, 'Aphrodite is the goddess of love, health', false, true);
      SmallTextXY(71, 31, 'and family.', false, true);
      SmallTextXY(71, 33, 'Starting Stats: Move +2', false, true);
      SmallTextXY(71, 34, 'Divine Rage   : Restore HP', false, true);
    end;

    if rs=2 then
    begin
      SmallTextXY(71, 30, 'Hermes is the god of magic. He''s also the', false, true);
      SmallTextXY(71, 31, 'messenger of the divines.', false, true);
      SmallTextXY(71, 33, 'Starting Stats: Lance +2', false, true);
      SmallTextXY(71, 34, 'Divine Rage   : Restore PP', false, true);
    end;

    if rs=3 then
    begin
      SmallTextXY(71, 30, 'Apoll is the god of wiliness, agility,', false, true);
      SmallTextXY(71, 31, 'and material wealth.', false, true);
      SmallTextXY(71, 33, 'Starting Stats: Steal +2', false, true);
      SmallTextXY(71, 34, 'Divine Rage   : Move +Humility', false, true);
    end;

    if rs=4 then
    begin
      SmallTextXY(71, 30, 'Dionysa is the goddess of wine, food,', false, true);
      SmallTextXY(71, 31, 'and pleasure.', false, true);
      SmallTextXY(71, 33, 'Modifiers  : reduced food consume', false, true);
      SmallTextXY(71, 34, 'Divine Rage: STR +Humility', false, true);
    end;

    if rs=5 then
    begin
      SmallTextXY(71, 30, 'Ares is the god of honor & peace in war.', false, true);
      SmallTextXY(71, 33, 'Starting Stats: Sword +3 / Axe +3', false, true);
      SmallTextXY(71, 34, 'Divine Rage   : CLV+(Humility*2) area dm.', false, true);
    end;


    if ps=1 then
    begin
      SmallTextXY(1, 30, 'Enchanters study enchanted crystals to', false, true);
      SmallTextXY(1, 31, 'learn new magical songs. They rely on', false, true);
      SmallTextXY(1, 32, 'their psychic power (PP) to cast magic.', false, true);
      SmallTextXY(1, 34, 'Starting Stats: PP +50 / Hit +3 / Chant +6', false, true);
    end;

    if ps=2 then
    begin
      SmallTextXY(1, 30, 'Thieves steal money and items from others', false, true);
      SmallTextXY(1, 31, 'and use stealth powers to evade enemies.', false, true);
      SmallTextXY(1, 32, 'They are able to fight and use magic as well.', false, true);
      SmallTextXY(1, 34, 'Starting Stats: Steal +6', false, true);
    end;

    if ps=3 then
    begin
      SmallTextXY(1, 30, 'Archers use bows and crossbows to attack', false, true);
      SmallTextXY(1, 31, 'enemies from the distance. They need lots of', false, true);
      SmallTextXY(1, 32, 'ammunition and are not that good in melee.', false, true);
      SmallTextXY(1, 34, 'Starting Stats: Fire-arm +6 / Hit +3', false, true);
    end;

    if ps=4 then
    begin
      SmallTextXY(1, 30, 'Soldiers prefer melee battle and are able to', false, true);
      SmallTextXY(1, 31, 'use all types of swords, axes, and lances. They', false, true);
      SmallTextXY(1, 32, 'are not that good in magic or archery, though.', false, true);
      SmallTextXY(1, 34, 'Starting Stats: Fight +5 / Move +3', false, true);
    end;

    dummy := GetKeyInput('[1] to [4] select profession    [a] to [e] select god    [ENTER] Continue', False);

    case dummy[1] of
      '1': ps:=1;
      '2': ps:=2;
      '3': ps:=3;
      '4': ps:=4;
      'a', 'A': rs:=1;
      'b', 'B': rs:=2;
      'c', 'C': rs:=3;
      'd', 'D': rs:=4;
      'e', 'E': rs:=5;
    end;

  until (dummy = 'ENTER');

  halt;

end;


  // create new player from scratch
  procedure CreatePlayer;
  var
    dummy: string;
    menu, RandomItem: integer;
  begin

    ClearScreenSDL;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/invbg.jpg');
    end;

    repeat
      if UseSDL = True then
        BlitImage_Title
      else
      begin
        DialogWin;
        StatusDeco;
      end;

      TransTextXY(1, 1, 'CHARACTER GENERATION');
      TransTextXY(8, 7,
        'You are about to create an individual character. This allows you');
      TransTextXY(8, 8,
        'to determine the sex, profession and religion of your character.');
      TransTextXY(8, 9,
        'You will also select the difficulty of the game, and you have to');
      TransTextXY(8, 10, 'distribute initial skill points.');
      TransTextXY(8, 12,
        'Beware that you are totally free in combining these factors, but');
      TransTextXY(8, 13, 'not every combination will lead to an easy or balanced game.');
      TransTextXY(8, 15, 'However, this can be seen as an additional challenge for more');
      TransTextXY(8, 16, 'experienced players, so you may continue.');
      TransTextXY(8, 18, 'Do you want to proceed?');

      dummy := GetKeyInput('Press [y] to continue or [n] to select a quickstart preset.',
        False);
    until (dummy = 'y') or (dummy = 'Y') or (dummy = 'n') or (dummy = 'N');

    if (dummy = 'n') or (dummy = 'N') then
      CreatePlayerFast
    else
    begin
      ClearPlayer;

      repeat
        RandomItem := ReturnRandomItem;
      until (thing[RandomItem].intCharLvl = 1) and
        (thing[RandomItem].blWield = False) and
        (thing[RandomItem].blEat = False) and
        (thing[RandomItem].blDrink = False) and
        (NPos('Credits', thing[RandomItem].strName, 1) = 0) and
        (NPos('Arrows', thing[RandomItem].strName, 1) = 0) and (NPos('Bolts', thing[RandomItem].strName, 1) = 0);
      inventory[1].intType := RandomItem;
      inventory[1].longNumber := 1;

      inventory[2].intType := ReturnItemByName('Aspirin');
      inventory[2].longNumber := 20;
      strQuickKey[1] := 'Aspirin';

      CreateDifficulty;
      CreateBiography(True);


      // 1. Sex; determines initial HP
      ClearScreenSDL;

      //ChoosePlayerBasics;

      repeat

        if UseSDL = True then
          BlitImage_Title
        else
        begin
          DialogWin;
          StatusDeco;
        end;

        TransTextXY(1, 1, 'CHARACTER GENERATION');
        TransTextXY(8, 7, 'Tell me, ' + ThePlayer.strName +
          ', are you male or female?');
        TransTextXY(8, 9, 'Key   Sex                    Bonus/Malus');
        TransTextXY(8, 11, ' 1    Male                   HP +(3 to 6)');
        TransTextXY(8, 12, ' 2    Female                 Move +1');

        dummy := GetKeyInput('Press the according key to determine your sex.', False);
      until (dummy = '1') or (dummy = '2');

      menu := StrToInt(dummy);
      case menu of
        1:
          Inc(ThePlayer.intMaxHP, 3 + trunc(random(4)));
        2:
          Inc(ThePlayer.intMove);
      end;

      ThePlayer.intSex := menu;


      // 2. Profession; determines initial skills
      ClearScreenSDL;

      repeat

        if UseSDL = True then
          BlitImage_Title
        else
        begin
          DialogWin;
          StatusDeco;
        end;

        TransTextXY(1, 1, 'CHARACTER GENERATION');
        TransTextXY(8, 7, 'What is your profession?');

        TransTextXY(8, 9,    'Key   Profession          Bonus/Malus');

        if ThePlayer.blQuiet=false then
          TransTextXY(8, 11, ' 1    Enchanter           PP +50 / Hit +3 / Chant +6')
        else
          TransTextXY(8, 11, ' 1    Quiet Enchanter     PP = 0 / Hit +3 / Chant = -10');
        // internal: 2

        TransTextXY(8, 12,   ' 2    Thief               Steal +6');
        // internal: 3

        TransTextXY(8, 13,   ' 3    Archer              Fire-arm +6 / Hit +3');
        // internal: 4

        TransTextXY(8, 14,   ' 4    Soldier             Fight +5 / Move +3');
        // internal: 5

        dummy := GetKeyInput(
          'Press the according key to select your profession.', False);

      until (dummy = '1') or (dummy = '2') or (dummy = '3') or (dummy = '4');
      // or (dummy='5');


      menu := StrToInt(dummy);
      case menu of
        //1:
        //begin
        //inc(ThePlayer.intTool, 6);
        //Inventory[3].intType:=ReturnItemByName('Dagger');
        //Inventory[3].longNumber:=1;
        //ThePlayer.intWeapon:=ReturnItemByName('Dagger');
        //Inventory[4].intType:=ReturnItemByName('Spade');
        //Inventory[4].longNumber:=1;
        //end;
        1:
        begin

          if thePlayer.blQuiet=false then
          begin
            Inc(ThePlayer.intChant, 6);
            Inc(ThePlayer.intMaxPP, 50);

            Thing[ReturnItemByName('Cola')].blIdentified := True;
            Thing[ReturnItemByName('Cola')].strName :=
              Thing[ReturnItemByName('Cola')].strRealName;

            spellbook[1].intType := ReturnSpellByName('Heal');
            spellbook[1].intKnown := 1;
            spellbook[1].intRefresh := spell[spellbook[1].intType].intRefresh;
            strQuickKey[1] := 'Heal';

            spellbook[2].intType := ReturnSpellByName('Stream');
            spellbook[2].intKnown := 1;
            spellbook[2].intRefresh := spell[spellbook[2].intType].intRefresh;
            strQuickKey[7] := 'Stream';

            Inventory[5].intType := ReturnItemByName('Cola');
            Inventory[5].longNumber := 6;
            strQuickKey[2] := 'Cola';
          end
          else
          begin
            ThePlayer.intPP := 0;
            ThePlayer.intMaxPP := 0;
            ThePlayer.intChant:=-10;
          end;
          Inc(ThePlayer.intView, 3);
        end;
        2:
        begin
          Inc(ThePlayer.intBurgle, 6);
          Inventory[5].intType := ReturnItemByName('Dungeon Key');
          Inventory[5].longNumber := 4;
        end;
        3:
        begin
          Inc(ThePlayer.intGun, 6);
          Inc(ThePlayer.intView, 3);
          Inc(ThePlayer.longGold, 100);
        end;
        4:
        begin
          Inc(ThePlayer.intMove, 3);
          Inc(ThePlayer.intFight, 5);
          Inventory[5].intType := ReturnItemByName('Meat');
          Inventory[5].longNumber := 1;
        end;
      end;

      ThePlayer.intProf := menu + 1;


      // 3. Religion
      ClearScreenSDL;

      repeat

        if UseSDL = True then
          BlitImage_Title
        else
        begin
          DialogWin;
          StatusDeco;
        end;

        TransTextXY(1, 1, 'CHARACTER GENERATION');
        TransTextXY(8, 7, 'Tell me, ' + ThePlayer.strName +
          ', in which god do you believe?');

        TransTextXY(8, 9,  'Key   Deity       Bonus/Malus         Divine Rage');
        TransTextXY(8, 11, ' 1    Aphrodite   Move +2             Restore HP');
        TransTextXY(8, 12, ' 2    Hermes      Lance +2            Restore PP');
        TransTextXY(8, 13, ' 3    Apoll       Steal +2            Move +Humility');
        TransTextXY(8, 14, ' 4    Dionysa     needs less food     STR  +Humility');
        TransTextXY(8, 15, ' 5    Ares        Sword +3 / Axe +3   CLV+(Humility*2) area dmg.');
        dummy := GetKeyInput('Press the according key to select your belief.', False);
      until (dummy = '1') or (dummy = '2') or (dummy = '3') or (dummy = '4') or (dummy = '5');



      menu := StrToInt(dummy);
      case menu of
        1:
          Inc(ThePlayer.intMove, 2);
        2:
          Inc(ThePlayer.intWhip, 2);
        3:
          Inc(ThePlayer.intBurgle, 2);
        4:
          Inc(ThePlayer.longFood, 1500);
        5:
        begin
            Inc(ThePlayer.intSword, 3);
            Inc(ThePlayer.intAxe, 3);
        end;
      end;

      ThePlayer.strReli := PlayClass[menu].strName;
      ThePlayer.intReli := StrToInt(dummy);


      // 4. Distribute skill points
      ClearScreenSDL;
      TextXY(2, 2, 'Finally, you have the possibility to train some of your skills.');
      case DiffLevel of
        1:
          TrainSkill(6);
        2:
          TrainSkill(5);
        3:
          TrainSkill(4);
      end;

      FinalizePlayer(True);
    end;
  end;

  // teleports an enemy
  procedure Teleport(n: integer);
  var
    CurX, CurY, rx, ry, i, Distance: integer;
  begin
    CurX := Monster[n].intX;
    CurY := Monster[n].intY;
    Distance := Monster[n].intTeleport;
    i := 0;
    repeat
      Inc(i);
      rx := trunc(random(DngMaxWidth - 12)) + 1;
      ry := trunc(random(DngMaxHeight - 12)) + 1;
    until (i > 1000) or ((DngLvl[rx, ry].intIntegrity = 0) and
        (abs(rx - CurX) < Distance) and (abs(ry - CurY) < Distance));
    Monster[n].intX := rx;
    Monster[n].intY := ry;
  end;


  // splits an enemy
  procedure SplitMonster(n: integer; summon: boolean);
  var
    FreeMonsterID, SumX, SumY, CurX, CurY: integer;
  begin
    // if we forgot to name a monster to be summ. in data files, exit
    if (Monster[n].strSplitInto = '') or (Monster[n].strSplitInto = ' ') then
      exit;

    // if "summon" = false, then remove
    if summon = False then
    begin
      FreeMonsterID := GetFirstFreeMonsterID;
      if FreeMonsterID > -1 then
      begin
        CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
        Monster[FreeMonsterID].intX := Monster[n].intX;
        Monster[FreeMonsterID].intY := Monster[n].intY;
      end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX + 1, Monster[n].intY].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX + 1;
          Monster[FreeMonsterID].intY := Monster[n].intY;
        end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX - 1, Monster[n].intY].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX - 1;
          Monster[FreeMonsterID].intY := Monster[n].intY;
        end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX + 1, Monster[n].intY - 1].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX + 1;
          Monster[FreeMonsterID].intY := Monster[n].intY - 1;
        end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX + 1, Monster[n].intY + 1].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX + 1;
          Monster[FreeMonsterID].intY := Monster[n].intY + 1;
        end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX - 1, Monster[n].intY - 1].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX - 1;
          Monster[FreeMonsterID].intY := Monster[n].intY - 1;
        end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX - 1, Monster[n].intY - 1].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX - 1;
          Monster[FreeMonsterID].intY := Monster[n].intY + 1;
        end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX, Monster[n].intY + 1].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX;
          Monster[FreeMonsterID].intY := Monster[n].intY + 1;
        end;

      FreeMonsterID := GetFirstFreeMonsterID;
      if DngLvl[Monster[n].intX, Monster[n].intY - 1].intIntegrity = 0 then
        if FreeMonsterID > -1 then
        begin
          CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
          Monster[FreeMonsterID].intX := Monster[n].intX;
          Monster[FreeMonsterID].intY := Monster[n].intY - 1;
        end;

      // draw blood...
      CreateBlood(Monster[n].intX, Monster[n].intY);
      Monster[n].intX := DngMaxWidth + 10;
      Monster[n].intY := DngMaxHeight + 10;
    end
    else
    begin
      FreeMonsterID := GetFirstFreeMonsterID;
      if FreeMonsterID > -1 then
      begin
        CurX := Monster[n].intX;
        CurY := Monster[n].intY;

        SumX := CurX;
        SumY := CurY;

        if CheckForMonster(CurX + 1, CurY) = False then
        begin
          SumX := CurX + 1;
          SumY := CurY;
        end;

        if CheckForMonster(CurX - 1, CurY) = False then
        begin
          SumX := CurX - 1;
          SumY := CurY;
        end;

        if CheckForMonster(CurX + 1, CurY + 1) = False then
        begin
          SumX := CurX + 1;
          SumY := CurY + 1;
        end;

        if CheckForMonster(CurX + 1, CurY - 1) = False then
        begin
          SumX := CurX + 1;
          SumY := CurY - 1;
        end;

        if CheckForMonster(CurX - 1, CurY + 1) = False then
        begin
          SumX := CurX - 1;
          SumY := CurY + 1;
        end;

        if CheckForMonster(CurX - 1, CurY - 1) = False then
        begin
          SumX := CurX - 1;
          SumY := CurY - 1;
        end;

        if CheckForMonster(CurX, CurY + 1) = False then
        begin
          SumX := CurX;
          SumY := CurY + 1;
        end;

        if CheckForMonster(CurX, CurY - 1) = False then
        begin
          SumX := CurX;
          SumY := CurY - 1;
        end;

        if ((SumX <> CurX) or (SumY <> CurY)) then
          if not ((SumX = ThePlayer.intX) and (SumY = ThePlayer.intY)) then
          begin
            CreateMonster(FreeMonsterID, Monster[n].strSplitInto, 0);
            Monster[FreeMonsterID].intX := SumX;
            Monster[FreeMonsterID].intY := SumY;
          end;
      end;
    end;
  end;


  // process normal (melee) fights with monsters
  function FightMonster(x: integer; y: integer): boolean;
  var
    i, s: integer;
    intTP, intDP, intMDP, intMTP, AttackType, SecAt: integer;
    strMsg1, strMsg2: string;
    blReallyAttack: boolean;
  begin
    FightMonster := True;

    intTP := CollectTP;
    intDP := CollectDP;
    intMTP := 0;

    for i := 1 to 510 do
    begin

      // process every monster that is on the given x/y-position
      if (Monster[i].intX = x) and (Monster[i].intY = y) then
      begin

        blReallyAttack := True;
        KeyRepeatIst := KeyRepeatSoll;

        // if the attack shall really be processed, continue ...
        if blReallyAttack = True then
        begin
          Monster[i].blHuman := False;
          // even men and peaceful monsters will now be angry
          Monster[i].blAttacked := True;  // set attacked flag
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

          // attack hits the enemy
          if (HitOrMiss(i) = False) or (random(400) > 200) then
          begin
            intMDP := Monster[i].intAP;
            intTP := intTP - intMDP;

            if ThePlayer.intWeapon > 0 then
            begin
              if Thing[ThePlayer.intWeapon].intGP > 0 then
                PlaySFX('hit-stub.ogg')
              else
              begin
                if random(500) > 250 then
                  PlaySFX('hit-sword.ogg')
                else
                  PlaySFX('hit-sword-2.ogg');
              end;

              if Monster[i].intInvis > 0 then
                ShowTransMessage('You attack something.', False)
              else
                ShowTransMessage('You attack the ' + Monster[i].strName + '.', False);
            end
            else
            begin
              PlaySFX('hit-stub.ogg');
              if Monster[i].intInvis > 0 then
                ShowTransMessage('You attack something with your bare hands.', False)
              else
                ShowTransMessage('You attack the ' + Monster[i].strName +
                  ' with your bare hands.', False);
            end;

            // if melee weapon has magic effect, process it
            if ThePlayer.intWeapon > 0 then
            begin
              if (random(500) > 300) and
                (Thing[ThePlayer.intWeapon].intGP = 0) then
              begin
                if (MaximizedWeaponSkill = True) or ((ThePlayer.intWeaponMod=19) or (ThePlayer.intWeaponMod=38) or (ThePlayer.intWeaponMod=39) or (ThePlayer.intWeaponMod=40) or (ThePlayer.intWeaponMod=45) or (ThePlayer.intWeaponMod=56)) then
                begin
                  // weapon with fire effect
                  if (thing[ThePlayer.intWeapon].intEffect = 38) or (ThePlayer.intWeaponMod=38) then
                  begin
                    BlendMagic(15);
                    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                    if Monster[i].blFire = False then
                    begin
                      Inc(intTP, thing[ThePlayer.intWeapon].intRange);
                      if ThePlayer.intWeaponMod=38 then
                      begin
                        ShowTransMessage('Your greased ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(ThePlayer.intWeaponModRange) + ' fire damage.', False);
                        ThePlayer.intWeaponMod:=0;
                        ThePlayer.intWeaponModRange:=0;
                      end
                      else
                        ShowTransMessage('Your ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(thing[ThePlayer.intWeapon].intRange) + ' fire damage.', False);
                    end
                    else
                      ShowTransMessage('Your enemy resists the fire damage of your ' +
                        thing[ThePlayer.intWeapon].strName + '.', False);
                  end;

                  // weapon with force effect
                  if (thing[ThePlayer.intWeapon].intEffect = 19) or (ThePlayer.intWeaponMod=19) then
                  begin
                    BlendMagic(13);
                    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

                    Inc(intTP, thing[ThePlayer.intWeapon].intRange);
                    if ThePlayer.intWeaponMod=19 then
                    begin
                      ShowTransMessage('Your greased ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(ThePlayer.intWeaponModRange) + ' force damage.', False);
                      ThePlayer.intWeaponMod:=0;
                      ThePlayer.intWeaponModRange:=0;
                    end
                    else
                      ShowTransMessage('Your ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(thing[ThePlayer.intWeapon].intRange) + ' force damage.', False);
                  end;

                  // weapon with ice effect
                  if (thing[ThePlayer.intWeapon].intEffect = 39) or (ThePlayer.intWeaponMod=39) then
                  begin
                    BlendMagic(16);
                    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                    if Monster[i].blIce = False then
                    begin
                      Inc(intTP, thing[ThePlayer.intWeapon].intRange);
                      if ThePlayer.intWeaponMod=39 then
                      begin
                        ShowTransMessage('Your greased ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(ThePlayer.intWeaponModRange) + ' ice damage.', False);
                        ThePlayer.intWeaponMod:=0;
                        ThePlayer.intWeaponModRange:=0;
                      end
                      else
                        ShowTransMessage('Your ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(thing[ThePlayer.intWeapon].intRange) + ' ice damage.', False);
                    end
                    else
                      ShowTransMessage('Your enemy resists the ice damage of your ' +
                        thing[ThePlayer.intWeapon].strName + '.', False);

                    // freeze air
                    DngLvl[Monster[i].intX, Monster[i].intY].intAirType := 2;
                    DngLvl[Monster[i].intX, Monster[i].intY].intAirRange := 5 + trunc(random(10));
                  end;

                  // weapon with poison effect
                  if (thing[ThePlayer.intWeapon].intEffect = 45) or (ThePlayer.intWeaponMod=45) then
                  begin
                    BlendMagic(24);
                    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                    if Monster[i].blPoison = False then
                    begin
                      Inc(Monster[i].intPoison, thing[ThePlayer.intWeapon].intRange);
                      if ThePlayer.intWeaponMod=45 then
                      begin
                        ShowTransMessage('Your greased ' + thing[ThePlayer.intWeapon].strName + ' poisons the ' + Monster[i].strName + '.', False);
                        ThePlayer.intWeaponMod:=0;
                        ThePlayer.intWeaponModRange:=0;
                      end
                      else
                        ShowTransMessage('Your ' + thing[ThePlayer.intWeapon].strName + ' poisons the ' + Monster[i].strName + '.', False);
                    end
                    else
                      ShowTransMessage('Your enemy resists the poison of your ' + thing[ThePlayer.intWeapon].strName + '.', False);
                  end;

                  // weapon with water effect
                  if (thing[ThePlayer.intWeapon].intEffect = 40) or (ThePlayer.intWeaponMod=40) then
                  begin
                    BlendMagic(17);
                    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                    if (Monster[i].blWaterC = False) and (Monster[i].blWater = False) then
                    begin
                      Inc(intTP, thing[ThePlayer.intWeapon].intRange);
                      if ThePlayer.intWeaponMod=40 then
                      begin
                        ShowTransMessage('Your greased' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(thing[ThePlayer.intWeapon].intRange) + ' water damage.', False);
                        ThePlayer.intWeaponMod:=0;
                        ThePlayer.intWeaponModRange:=0;
                      end
                      else
                        ShowTransMessage('Your ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(thing[ThePlayer.intWeapon].intRange) + ' water damage.', False);
                    end
                    else
                      ShowTransMessage('Your enemy resists the water damage of your ' + thing[ThePlayer.intWeapon].strName + '.', False);
                  end;

                  // weapon with electricity effect
                  if (thing[ThePlayer.intWeapon].intEffect = 56) or (ThePlayer.intWeaponMod=56) then
                  begin
                    BlendMagic(23);
                    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                    if Monster[i].blFire = False then
                    begin
                      Inc(intTP, thing[ThePlayer.intWeapon].intRange);

                      if ThePlayer.intWeaponMod=56 then
                      begin
                        ShowTransMessage('Your greased' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(thing[ThePlayer.intWeapon].intRange) + ' electricity damage.', False);
                        ThePlayer.intWeaponMod:=0;
                        ThePlayer.intWeaponModRange:=0;
                      end
                      else
                        ShowTransMessage('Your ' + thing[ThePlayer.intWeapon].strName + ' inflicts ' + IntToStr(thing[ThePlayer.intWeapon].intRange) + ' electricity damage.', False);
                    end
                    else
                      ShowTransMessage('Your enemy resists the electricity of your ' +
                        thing[ThePlayer.intWeapon].strName + '.', False);
                  end;

                end;

              end;
            end;

            if (intTP < 1) and ((ThePlayer.intLimit < 100) or
              ((ThePlayer.intLimit = 100) and (CollectHumility < 1))) then
            begin
              intTP := 0;
              if Monster[i].intInvis > 0 then
                strMsg1 := 'You hit something, but it resists.'
              else
                strMsg1 := 'The ' + Monster[i].strName + ' resists your attack.';
            end
            else
            begin // attack hits the enemy

              //writeln('TP: '+IntToStr(intTP));

              if Monster[i].intInvis > 0 then
                strMsg1 := 'You hit something'
              else
                strMsg1 := 'You hit the ' + Monster[i].strName;

              // a really good hit?
              if random(400) > CONST_CHANCE_FOR_GOOD_HIT then
                if MaximizedWeaponSkill = True then
                begin
                  intTP := CollectTP;
                  if Monster[i].intInvis > 0 then
                    strMsg1 := 'You do critical damage'
                  else
                    strMsg1 :=
                      'The ' + Monster[i].strName + ' suffers critical damage';
                end;

            end;
          end
          else
          begin // attack does not hit the enemy
            Monster[i].blAttacked := True;  // set attacked flag
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            intTP := 0;
            if Monster[i].intInvis > 0 then
              strMsg1 := 'You try to hit something, but you fail.'
            else
              strMsg1 := 'You try to hit the ' + Monster[i].strName +
                ', but you fail.';
          end;

          // if the player isn't invisible and if the player isn't frozen, process monster's counter-attack
          if (IsInvisible = False) and (ThePlayer.intFreeze = 0) then
          begin
            // randomly select monster's attack type
            AttackType := trunc(random(500));
            if AttackType > 400 then
              AttackType := 1   // secondary action (special or wait)
            else
              AttackType := 0;  // primary action (attack)

            // if monster's PP <= 0 then select standard attack
            if Monster[i].intPP <= 0 then
              AttackType := 0;

            // if the monster is in frozen air, select type 1 (which makes monster not to attack)
            if DngLvl[Monster[i].intX, Monster[i].intY].intAirType = 2 then
              AttackType := 1;

            //                     writeln (IntToStr(DngLvl[Monster[i].intX,Monster[i].intY].intAirType));

            case AttackType of
              0:
              begin
                // standard attack
                if HitOrMiss(i) = True then
                begin
                  intMTP := Monster[i].intWP - intDP;
                  if intMTP < 1 then
                    intMTP := 0;
                  if intMTP > 0 then
                  begin
                    if Monster[i].intInvis > 0 then
                      strMsg2 :=
                        'Something ' + Monster[i].strVerb + ' [-' +
                        IntToStr(intMTP) + '].'
                    else
                      strMsg2 :=
                        'The ' + Monster[i].strName + ' ' + Monster[i].strVerb +
                        ' [-' + IntToStr(intMTP) + '].';
                  end
                  else
                  begin
                    if Monster[i].intInvis > 0 then
                      strMsg2 :=
                        'Something ' + Monster[i].strVerb + ', but does no damage.'
                    else
                      strMsg2 :=
                        'The ' + Monster[i].strName + ' ' + Monster[i].strVerb +
                        ', but does no damage.';
                  end;

                  if (ThePlayer.intWall > 0) then
                  begin
                    intMTP := 0;
                    strMsg2 := 'Your barrier blocks the attack.';
                  end;

                  // if damage suffered increase divine range
                  if intMTP > 0 then
                  begin
                       IncreaseDistress;
                  end;
                end
                else
                begin
                  if Monster[i].intInvis > 0 then
                    strMsg2 := 'Something tries to hit, but misses.'
                  else
                    strMsg2 := 'The ' + Monster[i].strName + ' misses.';
                  intMTP := 0;
                end;
              end;

              1:
              begin
                // Select special attack
                SecAt := 0;
                s := 0;
                repeat
                  if (Monster[i].blPoison = True) and (random(1000) > 500) then
                    SecAt := 1;
                  if (Monster[i].blFire = True) and (random(1000) > 500) then
                    SecAt := 2;
                  if (Monster[i].blIce = True) and (random(1000) > 500) then
                    SecAt := 3;
                  if (Monster[i].blConfusion = True) and
                    (random(1000) > 500) then
                    SecAt := 4;
                  if (Monster[i].blBlindness = True) and
                    (random(1000) > 500) then
                    SecAt := 5;
                  if (Monster[i].blInvis = True) and (random(1000) > 500) then
                    SecAt := 6;
                  if (Monster[i].blPara = True) and (random(1000) > 500) then
                    SecAt := 7;
                  if (Monster[i].blCalm = True) and (random(1000) > 500) then
                    SecAt := 8;
                  if (Monster[i].blCurse = True) and (random(1000) > 500) then
                    SecAt := 9;
                  if (Monster[i].blWaterC = True) and (random(1000) > 500) then
                    SecAt := 10;
                  if (Monster[i].blDestWeapon = True) and
                    (random(1000) > 500) and (ThePlayer.intWeapon > 0) then
                    SecAt := 11;
                  if (Monster[i].blDestArmour = True) and
                    (random(1000) > 500) and (ThePlayer.intArmour > 0) then
                    SecAt := 12;
                  if (Monster[i].blHitsHard = True) and
                    (random(1000) > 500) then
                    SecAt := 13;
                  if (Monster[i].blTeleport = True) and
                    (random(1000) > 500) then
                    SecAt := 14;
                  if (Monster[i].blSplit = True) and (random(1000) > 500) then
                    SecAt := 15;
                  if (Monster[i].blSummon = True) and (random(1000) > 500) then
                    SecAt := 16;
                  if (Monster[i].blSelfHeal = True) and
                    (random(1000) > 500) then
                    SecAt := 17;
                  if (Monster[i].blDrainSTR = True) and
                    (random(1000) > 500) then
                    SecAt := 18;
                  if (Monster[i].blDrainPP = True) and
                    (random(1000) > 500) then
                    SecAt := 19;
                  if (Monster[i].blElect = True) and (random(1000) > 500) then
                    SecAt := 20;
                  if (Monster[i].blBreakDefence = True) and (random(1000) > 500) then
                    SecAt := 21;
                  Inc(s);
                until (s = 1000) or (SecAt > 0);

                // is monster frozen?
                if DngLvl[Monster[i].intX, Monster[i].intY].intAirType = 2 then
                  SecAt := 99;

                case SecAt of
                  0:
                  begin
                    // for this monster, there's no special available, so just block attack
                    if Monster[i].intInvis = 0 then
                      strMsg2 :=
                        'The ' + Monster[i].strName + ' blocks your attack.';
                    intTP := 0;
                  end;

                  1:
                  begin  // poison
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' poisons you.';
                    intMTP := 0;
                    if CheckEffect(10) = True then
                    begin
                      strMsg2 := strMsg2 + ' You resist the poison.';
                    end
                    else
                    begin
                      PlaySFX('magic-bad.ogg');
                      BlendMagic(4);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      ThePlayer.intPoison :=
                        Monster[i].intLvl + trunc(random(6));
                      if ThePlayer.intPoison > ThePlayer.intHP - 1 then
                        ThePlayer.intPoison := 1;
                    end;
                  end;

                  2:
                  begin  // fireball
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' chants a fire song';
                    if CheckEffect(8) = True then
                    begin
                      strMsg2 := strMsg2 + ', but it does no harm.';
                    end
                    else
                    begin
                      strMsg2 := strMsg2 + '. The flames hurt you.';
                      PlaySFX('magic-combat.ogg');
                      BlendMagic(1);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      ShowMonsterSpell(1, ThePlayer.intX, ThePlayer.intY);
                      intMTP := 7 * (trunc(random(DungeonLevel)) + 1);
                      BurnInventoryItem;
                    end;
                  end;

                  3:
                  begin  // ice
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' chants an ice song';
                    if CheckEffect(14) = True then
                    begin
                      strMsg2 := strMsg2 + ', but you resist.';
                    end
                    else
                    begin
                      strMsg2 :=
                        strMsg2 + '. Icy cold stops your attack.';
                      PlaySFX('magic-combat.ogg');
                      BlendMagic(2);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      ShowMonsterSpell(2, ThePlayer.intX, ThePlayer.intY);
                      intMTP := 6 * (trunc(random(DungeonLevel)) + 1);
                      intTP := 0;
                    end;
                  end;

                  4:
                  begin  // confusion
                    Dec(Monster[i].intPP);
                    strMsg2 := 'You are confused';
                    intMTP := 0;
                    if CheckEffect(11) = True then
                    begin
                      strMsg2 :=
                        strMsg2 + ', but finally you manage to concentrate.';
                    end
                    else
                    begin
                      PlaySFX('magic-bad.ogg');
                      BlendMagic(10);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      strMsg2 := strMsg2 + ' and feel helpless.';
                      ThePlayer.intConfusion :=
                        Monster[i].intLvl + trunc(random(6));
                    end;
                  end;

                  5:
                  begin  // blindness
                    Dec(Monster[i].intPP);
                    strMsg2 := 'You are blind.';
                    intMTP := 0;
                    if CheckEffect(17) = True then
                    begin
                      strMsg2 := strMsg2 + ' You can see again.';
                    end
                    else
                    begin
                      PlaySFX('magic-bad.ogg');
                      BlendMagic(11);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      strMsg2 := strMsg2 + ' Everything is so dark ...';
                      ThePlayer.intBlind :=
                        Monster[i].intLvl + trunc(random(6));
                      ShowDungeon(ThePlayer.intX,
                        ThePlayer.intY, 80, 25, 0);
                    end;
                  end;
                  6:
                  begin // monster gets invisible
                    Dec(Monster[i].intPP);
                    //PlaySFX('magic-time.ogg');
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' becomes invisible!';
                    Monster[i].intInvis := DungeonLevel + trunc(random(3));
                    intMTP := 0;
                  end;
                  7:
                  begin  // paralization
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' tries to paralyze you';
                    intMTP := 0;
                    if CheckEffect(26) = True then
                    begin
                      strMsg2 := strMsg2 + ', but you break the chains.';
                    end
                    else
                    begin
                      PlaySFX('magic-bad.ogg');
                      BlendMagic(12);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      strMsg2 := strMsg2 + '. You feel helpless.';
                      ThePlayer.intPara :=
                        Monster[i].intLvl + trunc(random(6));
                    end;
                  end;

                  8:
                  begin  // calm (player now can't use spells)
                    Dec(Monster[i].intPP);
                    strMsg2 := 'You can' + chr(39) + 't chant.';
                    intMTP := 0;
                    if (ThePlayer.blBlessed = True) or
                      (CheckEffect(28) = True) then
                    begin
                      strMsg2 :=
                        strMsg2 + ' You resist the effects of Calm.';
                    end
                    else
                    begin
                      PlaySFX('magic-bad.ogg');
                      strMsg2 := strMsg2 + ' You feel quiet.';
                      ThePlayer.intCalm :=
                        Monster[i].intLvl + trunc(random(6));
                    end;
                  end;

                  9:
                  begin  // curse (the most terrible spell in this game ...)
                    Dec(Monster[i].intPP);
                    if ThePlayer.blEvil = False then
                    begin
                      strMsg2 := 'An evil shadow penetrates your mind';
                      intMTP := 0;
                      if (CheckEffect(31) = True) or (CollectHumility >= 15) then
                      begin
                        strMsg2 := strMsg2 + ', but you resist it.';
                      end
                      else
                      begin
                        PlaySFX('magic-bad.ogg');
                        BlendMagic(8);
                        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                        strMsg2 := strMsg2 + '. You feel very sad.';
                        ThePlayer.blCursed := True;
                        ThePlayer.blBlessed := False;
                      end;
                    end;
                  end;

                  10:
                  begin  // water
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' summons the powers of water.';
                    if CheckEffect(35) = True then
                    begin
                      strMsg2 := strMsg2 + ' You resist.';
                    end
                    else
                    begin
                      strMsg2 := strMsg2 + ' Hard waves hit you.';
                      PlaySFX('magic-combat.ogg');
                      BlendMagic(3);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      ShowMonsterSpell(3, ThePlayer.intX, ThePlayer.intY);
                      intMTP := 5 * (trunc(random(DungeonLevel)) + 1);
                    end;
                  end;

                  11:
                  begin   // lose weapon
                    Dec(Monster[i].intPP);
                    strMsg2 := 'Your weapon vibrates';
                    if ThePlayer.intWeapon > 0 then
                    begin
                      PlaySFX('magic-bad.ogg');
                      intMTP := 0;
                      if Thing[ThePlayer.intWeapon].intEffect = 36 then
                        strMsg2 := strMsg2 + ', but nothing happens.'
                      else
                      begin
                        strMsg2 := strMsg2 + ' and you lose it.';
                        ThePlayer.intWeapon := 0;
                      end;
                    end;
                  end;

                  12:
                  begin  // lose armour
                    Dec(Monster[i].intPP);
                    strMsg2 := 'Your armour vibrates';
                    if ThePlayer.intArmour > 0 then
                    begin
                      PlaySFX('magic-bad.ogg');
                      intMTP := 0;
                      if Thing[ThePlayer.intArmour].intEffect = 36 then
                        strMsg2 := strMsg2 + ', but nothing happens.'
                      else
                      begin
                        strMsg2 := strMsg2 + ' and you lose it.';
                        ThePlayer.intArmour := 0;
                      end;
                    end;
                  end;

                  13:
                  begin // mighty hit
                    strMsg2 := 'You suffer a mighty hit. [HP reduced to 1!]';
                    if ThePlayer.blOffensive = True then
                      intMTP := ThePlayer.intHP - 1
                    else
                      intMTP := (ThePlayer.intHP div 2);
                  end;

                  14:
                  begin // teleport
                    Dec(Monster[i].intPP);
                    PlaySFX('magic-time.ogg');
                    strMsg2 := 'The ' + Monster[i].strName + ' disappears.';
                    Teleport(i);
                  end;

                  15:
                  begin // split
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' bears children.';
                    SplitMonster(i, False);
                  end;

                  16:
                  begin // summon
                    Dec(Monster[i].intPP);
                    PlaySFX('magic-time.ogg');
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' summons a monster.';
                    SplitMonster(i, True);
                  end;

                  17:
                  begin // heal (1/4 of max. HP)
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' glows slightly. [' +
                      Monster[i].strName + chr(39) + 's HP inc. by ' +
                      IntToStr(Monster[i].intMaxHP div 4) + ']';
                    Inc(Monster[i].intHP, Monster[i].intMaxHP div 4);
                    if Monster[i].intHP > Monster[i].intMaxHP then
                      Monster[i].intHP := Monster[i].intMaxHP;
                  end;

                  18:
                  begin // decrease player strength
                    Dec(Monster[i].intPP);
                    if CheckEffect(52) = False then
                    begin
                      PlaySFX('magic-bad.ogg');
                      strMsg2 := 'You feel weaker.';
                      intMTP :=
                        trunc(random(Monster[i].intDrainSTR) + 1);
                      Dec(ThePlayer.intStrength, intMTP);
                      if ThePlayer.intStrength < 0 then
                        ThePlayer.intStrength := 0;
                      Inc(Monster[i].intHP, intMTP);
                      if Monster[i].intHP > Monster[i].intMaxHP then
                        Monster[i].intHP := Monster[i].intMaxHP;
                      strMsg2 :=
                        strMsg2 + ' [' + Monster[i].strName + chr(39) +
                        's HP increased by ' + IntToStr(intMTP) + ']';
                    end
                    else
                      strMsg2 :=
                        'For a moment, you feel weak, but you pull yourself together.';
                    intMTP := 0;
                  end;

                  19:
                  begin // drain player PP (and add it to monster PP)
                    Dec(Monster[i].intPP);
                    if CheckEffect(51) = False then
                    begin
                      PlaySFX('magic-bad.ogg');
                      intMTP := trunc(random(Monster[i].intDrainPP) + 1);
                      strMsg2 :=
                        'Your head seems to burst. [' + Monster[i].strName +
                        chr(39) + ' PP inc. by ' + IntToStr(intMTP) + ']';
                      Inc(Monster[i].intPP, intMTP);
                    end
                    else
                      strMsg2 := 'You feel dizzy for a second.';
                  end;

                  20:
                  begin  // electricity
                    Dec(Monster[i].intPP);
                    strMsg2 :=
                      'The ' + Monster[i].strName + ' attacks with electricity';
                    if CheckEffect(55) = True then
                    begin
                      strMsg2 := strMsg2 + ', but you resist.';
                    end
                    else
                    begin
                      strMsg2 :=
                        strMsg2 + '. You are stunned.';
                      PlaySFX('force-on.ogg');
                      BlendMagic(22);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                      ShowMonsterSpell(4, ThePlayer.intX, ThePlayer.intY);
                      intMTP := 6 * (trunc(random(DungeonLevel)) + 1);

                      if CheckEffect(26) = False then
                        Inc(ThePlayer.intPara, 4);

                      if (CheckEffect(28) = False) and (ThePlayer.blBlessed = False) then
                        Inc(ThePlayer.intCalm, 4);

                      intTP := 0;
                    end;
                  end;

                  21:
                  begin  // break defence
                    if ThePlayer.blOffensive = False then
                    begin
                      strMsg2 := 'The ' + Monster[i].strName + ' breaks your defence.';
                      // TODO: If Checkeffect(x) ...
                      PlaySFX('magic-bad.ogg');
                      ThePlayer.blOffensive := True;
                    end;
                  end;


                  99:
                  begin // monster is frozen and can't do anything
                    strMsg2 := 'The enemy is frozen.';
                    intMTP := 0;
                  end;
                end;
                ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
              end;
            end;

            // decrease player HP
            //Writeln('Hit by '+ IntToStr(intMTP));

            ThePlayer.intHP := ThePlayer.intHP - intMTP;
            if IsPlayerDead = True then // check for player's death
            begin
              if Monster[i].intInvis > 0 then
                GameOver('Killed by ... something')
              else
              begin
                strMsg2 := lowercase(LeftStr(Monster[i].strName, 1));
                if (strMsg2 = 'a') or (strMsg2 = 'e') or
                  (strMsg2 = 'u') or (strMsg2 = 'o') or (strMsg2 = 'i') then
                  GameOver('Killed by an ' + Monster[i].strName)
                else
                  GameOver('Killed by a ' + Monster[i].strName);
              end;
            end;

          end
          else // player is invisble or time is frozen
          if IsInvisible = True then
            strMsg2 := 'The enemy can' + chr(39) + 't see you.'
          else
            strMsg2 := 'Time is frozen.';

          // decrease monster's HP
          Monster[i].intHP := Monster[i].intHP - intTP;
          if Monster[i].intHP < 0 then
            Monster[i].intHP := 0;

          if Monster[i].intInvis = 0 then
            strMsg1 := strMsg1 + ' [HP/PP: ' + IntToStr(Monster[i].intHP) +
              '/' + IntToStr(Monster[i].intPP) + '].'
          else
            strMsg1 := strMsg1 + ' [HP/PP: ?/?].';

          //TextXY(1, 26, '                                                                            ');
          //                TransTextXY(1, 26, strMsg1);

          // ShowStatus;
          ShowTransMessage(strMsg1, False);
          ShowTransMessage(strMsg2, False);

          // currently don't really know why this is here. has something to do with the
          // config option to enter a formerly occupied tile directly after monster's death
          if AutoMoveToTile = True then
            if Monster[i].intHP > 0 then
              FightMonster := False
            else
              IsMonsterDead(i)
          else
          begin
            FightMonster := False;
            IsMonsterDead(i);
          end;

          // do effects
          EffectTicker;

        end;
      end;
    end;

  end;


  // TODO: use functions provided by InventoryScreen unit to determine slots
  procedure TakeItem(x: integer; y: integer);
  var
    i, t: integer;
    blRemItem: boolean;
  begin
    blRemItem := False;
    t := DngLvl[x, y].intItem;

    if Thing[t].chLetter = chr(167) then
    begin
      Inc(ThePlayer.longGold, Thing[t].intPrice);
      DngLvl[x, y].intItem := 0;
      ShowTransMessage('You pick up the item: ' + Thing[t].strName + '.', False);
    end
    else
    begin
      // check if player already has one item of this type
      for i := 1 to 16 do
        if inventory[i].intType = t then
        begin
          Inc(inventory[i].longNumber, Thing[Inventory[i].intType].intAmount);
          blRemItem := True;
        end;

      // if item not taken, check if free space available
      if blRemItem = False then
        for i := 1 to 16 do
          if (inventory[i].intType = 0) and (blRemItem = False) then
          begin
            inventory[i].intType := t;
            inventory[i].longNumber := Thing[Inventory[i].intType].intAmount;
            ;
            blRemItem := True;
          end;

      // if item taken, remove item from map
      if blRemItem then
      begin
        DngLvl[x, y].intItem := 0;
        ShowTransMessage('You pick up an item: ' + Thing[t].strName + '.', False);
      end
      else
        ShowTransMessage('You want to pick up an item, but your inventory is full.',
          False);
    end;

    //      ClearScreenSDL;
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);
  end;


  procedure SpellInfo(id: integer; n: integer);
  var
    dummy: string;
    IconRect, IconRectS: SDL_RECT;
    d: integer;
  begin

    IconRect.x := 38 * (Spell[id].intEffect - 1);
    IconRect.y := 415;
    IconRect.w := 38;
    IconRect.h := 38;

    IconRectS.x := 735 + HiResOffsetX;
    IconRectS.y := 10 + HiResOffsetY;
    IconRectS.w := 38;
    IconRectS.h := 38;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/invbg.jpg');
    end;

    dummy := '-';
    repeat

      if UseSDL = True then
      begin
        BlitImage_Title;
        SDL_BLITSURFACE(extratiles, @IconRect, screen, @IconRectS);
      end
      else
      begin
        DialogWin;
        BottomBar;
      end;

      if Spell[id].strName <> '-' then
      begin

        TransTextXY(1, 1, '"' + uppercase(Spell[id].strName) + '"');

        if Spell[id].strDescri <> '-' then
          TransTextXY(8, 7, Spell[id].strDescri + '.');

        TransTextXY(8, 10, 'Minimum level: ' + IntToStr(Spell[id].intCharLvl));

        TransTextXY(8, 12, 'Current spell level: ' + IntToStr(SpellBook[n].intKnown));

        if CheckEffect(37) = True then
          TransTextXY(8, 13, 'Current efficiency : ' + IntToStr(2 * (Spell[id].intRange + (Spellbook[n].intKnown * Spellbook[n].intKnown))) + ' ' + GetEffectDescription(Spell[id].intEffect) + ' (maximized)')
        else
          TransTextXY(8, 13, 'Current efficiency : ' + IntToStr(Spell[id].intRange + (Spellbook[n].intKnown * Spellbook[n].intKnown)) + ' ' + GetEffectDescription(Spell[id].intEffect));


        d := Spell[id].intPP + (2 * SpellBook[n].intKnown);
        if CheckEffect(57) = true then
          d := d - (d div 4);

        TransTextXY(8, 14, 'Current PP cost    : ' + IntToStr(d));
        TransTextXY(8, 16, 'Wait for refresh   : ' +
          IntToStr(Spell[id].intRefresh) + ' turns');


        dummy := GetKeyInput('[ESC] close', False);
      end;
    until dummy = 'ESC';

  end;


  procedure Hospital;
  var
    blHasInsurance, blRemItem: boolean;
    intPrice, intCardPrice, i, t: integer;
    ch, dummy: string;
    strHospitalName: string;
  begin
    strHospitalName := 'the hospital';
    case DungeonLevel of
      1:
        strHospitalName := 'the Healing Lodge';
      5:
        strHospitalName := 'the sick bay';
      10:
        strHospitalName := 'a healer''s hut';
      15:
        strHospitalName := 'a quacksalver''s tent';
    end;

    DecoIcon.x := 520;
    DecoIcon.y := 80;
    DecoIcon.w := 60;
    DecoIcon.h := 80;

    DecoIconS.x := 717 + HiResOffsetX;
    DecoIconS.y := 400 + HiResOffsetY;
    DecoIconS.w := 72;
    DecoIconS.h := 72;

    ClearScreenSDL;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/invbg.jpg');
    end;

    repeat

      if UseSDL = True then
      begin
        BlitImage_Title;
        SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
      end
      else
      begin
        DialogWin;
        StatusDeco;
      end;


      TransTextXY(1, 1, uppercase(strHospitalName));
      TransTextXY(62, 1, 'Credits: ' + IntToStr(ThePlayer.longGold));

      if ThePlayer.intHP < ThePlayer.intMaxHP then
      begin
        intPrice := ThePlayer.intMaxHP - ThePlayer.intHP;
        TransTextXY(8, 7, 'Treatment without health insurance will cost ' +
          IntToStr(intPrice) + ' Credits.');
      end
      else
        TransTextXY(8, 8, 'You need no healing at the moment.');

      blHasInsurance := False;
      intCardPrice := 1000 * DiffLevel;

      if (PlayerHasItem('Insurance Card') > 0) or (PlayerHasItem('V.I.P. Card') > 0) then
        blHasInsurance := True;

      if blHasInsurance = False then
        TransTextXY(8, 9, 'A lifetime health insurance card is available for ' +
          IntToStr(intCardPrice) + ' Credits.')
      else
        TransTextXY(8, 9, 'You have a health insurance card.');

      if ThePlayer.blCoffeeBreak=false then
        TransTextXY(8, 10, 'We also offer a single life insurance for ' +  IntToStr(200 * (ThePlayer.longLifeIns + 1)) + ' Credits.');
      if ThePlayer.intTotalVitari > 0 then
        TransTextXY(8, 11, 'A withdrawal treatment is available for ' +
          IntToStr(130 * ThePlayer.intTotalVitari) + ' Credits.');

      if ThePlayer.blCoffeeBreak=false then
        dummy := GetKeyInput('[h]eal  [i]nsurance cd.  [w]ithdrawal t.   [l]ife insur.', False)
      else
        dummy := GetKeyInput('[h]eal  [i]nsurance cd.  [w]ithdrawal t.', False);

    until (dummy = 'h') or (dummy = 'i') or (dummy = 'l') or (dummy = 'w') or
      (dummy = 'ESC');
    ch := dummy;

    if ch = 'i' then
    begin
      if blHasInsurance = False then
      begin
        if ThePlayer.longGold > intCardPrice then
        begin
          // get ID of insurance card
          t := ReturnItemByName('Insurance Card');

          // check if inventory has space for card
          blRemItem := False;
          for i := 1 to 16 do
            if (inventory[i].intType = 0) and (blRemItem = False) then
            begin
              inventory[i].intType := t;
              Thing[t].blIdentified := True;
              // as the card is technically a rune, make it identified ...
              Thing[t].strName := Thing[t].strRealName;
              // ... and give it its real name
              Inc(inventory[i].longNumber);
              blRemItem := True;
              break;
            end;

          if blRemItem = True then
          begin
            Dec(ThePlayer.longGold, intCardPrice);
            ShowTransMessage(
              'You have bought a health insurance card. Now healing will be for free.',
              False);
          end
          else
            GetKeyInput(
              'You do not have enough space in inventory to store an insurance card.',
              True);

        end
        else
          GetKeyInput('Unfortunately you can' + chr(39) +
            't afford a health insurance now.', True);
      end
      else
        GetKeyInput('You already have a health insurance card.', True);
    end;

    if ch = 'h' then
      if ThePlayer.intHP < ThePlayer.intMaxHP then
      begin
        if blHasInsurance = False then
        begin
          if ThePlayer.longGold >= intPrice then
          begin
            ThePlayer.intHP := ThePlayer.intMaxHP;
            Dec(ThePlayer.longGold, intPrice);
            ShowTransMessage('You have been healed for ' +
              IntToStr(intPrice) + ' Credits.', False);
          end
          else
            GetKeyInput('We are sorry, but you can' + chr(39) +
              't afford a treatment now.', True);
        end
        else
        begin
          ThePlayer.intHP := ThePlayer.intMaxHP;
          ShowTransMessage(
            'You have been healed for free in the hospital.', False);
        end;
      end
      else
        GetKeyInput('You are healthy and need no treatment.', True);

    if (ch = 'l') and (ThePlayer.blCoffeeBreak=false) then
      if ThePlayer.longGold >= 200 * (ThePlayer.longLifeIns + 1) then
      begin
        ShowTransMessage('You bought a life insurance for ' +
          IntToStr(200 * (ThePlayer.longLifeIns + 1)) + ' Credits.', False);
        Dec(ThePlayer.longGold, 200 * (ThePlayer.longLifeIns + 1));
        Inc(ThePlayer.longLifeIns, 1);
        StoreAchievement('Bought a life insurance.');
        SaveGame(ThePlayer.strName, DungeonLevel);
      end
      else
        GetKeyInput('You can' + chr(39) + 't afford a life insurance.', True);

    if ch = 'w' then
      if ThePlayer.intTotalVitari > 0 then
      begin
        if ThePlayer.longGold >= 130 * ThePlayer.intTotalVitari then
        begin
          ShowTransMessage('You made a withdrawal treatment for ' +
            IntToStr(130 * ThePlayer.intTotalVitari) + ' Credits.', False);
          Dec(ThePlayer.longGold, 130 * ThePlayer.intTotalVitari);
          ThePlayer.intTotalVitari := 0;
          ThePlayer.intNextVitari := 0;
          ThePlayer.intNeedVitari := 0;
        end
        else
          GetKeyInput('You can' + chr(39) +
            't afford a withdrawal treatment. Pray to your god instead.', True);
      end
      else
        GetKeyInput('You don' + chr(39) + 't need a withdrawal treatment.', True);
  end;


  procedure Restaurant;
  var
    i: integer;
    ch: string;
    strRestaurantName: string;
    strMenues: array[1..5] of string;
    intMenues: array[1..5] of integer;
  begin

    intMenues[1] := 400;     // small
    intMenues[2] := 800;     // normal
    intMenues[3] := 1200;    // bigger
    intMenues[4] := 1600;    // very big
    intMenues[5] := 2000;    // SuperSizeMe

    case DungeonLevel of
      1:
        strRestaurantName := 'Clive' + chr(39) + 's Pub';
      5:
        strRestaurantName := 'Chez Luc';
      10:
        strRestaurantName := 'Akpir Catering';
      15:
        strRestaurantName := 'Czerwone Jabluszko';
    end;

    if strRestaurantName = 'Clive' + chr(39) + 's Pub' then
    begin
      strMenues[1] := 'Chocolate Cake with Custard';
      strMenues[2] := 'Baked Beans on Toast';
      strMenues[3] := 'Sunday Roast with Pudding';
      strMenues[4] := 'Scrambled Egg and Bacon';
      strMenues[5] := 'Fish and Chips';
    end
    else
    if strRestaurantName = 'Chez Luc' then
    begin
      strMenues[1] := 'Quiche Lorraine';
      strMenues[2] := 'Tarte Tatin';
      strMenues[3] := 'Canard a l' + chr(39) + 'orange';
      strMenues[4] := 'Ratatouille';
      strMenues[5] := 'Bouillabaisse';
    end
    else
    if strRestaurantName = 'Akpir Catering' then
    begin
      strMenues[1] := 'Soljanka';
      strMenues[2] := 'Nudeln mit Kaesesauce';
      strMenues[3] := 'Haehnchenpfanne';
      strMenues[4] := 'Ueberbackener Fisch';
      strMenues[5] := 'Bratkartoffeln mit Ei';
    end
    else
    if strRestaurantName = 'Czerwone Jabluszko' then
    begin
      strMenues[1] := 'Barszcz';
      strMenues[2] := 'Pierogi';
      strMenues[3] := 'Kielbasa';
      strMenues[4] := 'Bigos';
      strMenues[5] := 'Schabowy';
    end;

    DecoIcon.x := 360;
    DecoIcon.y := 80;
    DecoIcon.w := 80;
    DecoIcon.h := 80;


    DecoIconS.x := 711 + HiResOffsetX;
    DecoIconS.y := 400 + HiResOffsetY;
    DecoIconS.w := 72;
    DecoIconS.h := 72;

    ClearScreenSDL;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/invbg.jpg');
    end;

    repeat

      if UseSDL = True then
      begin
        BlitImage_Title;
        SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
      end
      else
      begin
        DialogWin;
        StatusDeco;
      end;

      TransTextXY(1, 1, uppercase(strRestaurantName));
      TransTextXY(62, 1, 'Credits: ' + IntToStr(ThePlayer.longGold));

      TransTextXY(8, 7, 'What would you like to eat today?');

      TransTextXY(8, 9, 'Key   Name of dish');

      for i := 1 to 5 do
      begin
        TransTextXY(8, 10 + i, ' ' + IntToStr(i) + '    ' + strMenues[i]);
        TransTextXY(52, 10 + i, '$' + IntToStr((8 * intMenues[i]) div 100));
      end;

      ch := GetKeyInput('[1] to [5]  select a dish', False);
    until (ch = '1') or (ch = '2') or (ch = '3') or (ch = '4') or
      (ch = '5') or (ch = 'ESC');


    if ch <> 'ESC' then
      if ThePlayer.longGold > ((8 * intMenues[StrToInt(ch)]) div 100) - 1 then
      begin
        Inc(ThePlayer.longFood, intMenues[StrToInt(ch)]);
        Dec(ThePlayer.longGold, (8 * intMenues[StrToInt(ch)]) div 100);
        ShowTransMessage('You eat the ' + strMenues[StrToInt(ch)] + '.', False);
      end
      else
        GetKeyInput('You need more Credits to order the selected dish.', True);

  end;




  procedure ResourceWorkshop;
  var
    dummy, tstr: string;
    ch: char;
    n, longValue: longint;
    blCloseWorkshop: boolean;
    z, i, tid, slot, intCraftOK: integer;
  begin

    blCloseWorkshop := False;

    repeat

      if UseSDL = True then
      begin
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        DarkenScreen;
        LoadImage_Title('graphics/invbg.jpg');
      end;

      DecoIcon.x := 580;
      DecoIcon.y := 80;
      DecoIcon.w := 75;
      DecoIcon.h := 80;

      DecoIconS.x := 711 + HiResOffsetX;
      DecoIconS.y := 400 + HiResOffsetY;
      DecoIconS.w := 72;
      DecoIconS.h := 72;

      repeat
        if UseSDL = True then
        begin
          BlitImage_Title;
          SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
        end
        else
        begin
          ClearScreenSDL;
          StatusDeco;
        end;

        TransTextXY(1, 1, 'RESOURCE WORKSHOP');
        TransTextXY(62, 1, 'Credits: ' + IntToStr(ThePlayer.longGold));

        // Table Headers
        TransTextXY(34, 3, 'Wood');
        TransTextXY(39, 3, 'Metal');
        TransTextXY(45, 3, 'Stone');
        TransTextXY(51, 3, 'Leather');
        TransTextXY(59, 3, 'Req. Item');

        // display the receipts for different items and their cost in resources

        z := 1;
        for i := 1 to 5 do
        begin
          TransTextXY(1, 4 + z, IntToStr(i));
          CharXY(4, 4 + z, ItemReceipt[DungeonLevel, i].chLetter, 0, True);

          SetItemNameColor(ItemReceipt[DungeonLevel, i].strName);
          TransTextXY(6, 4 + z, ItemReceipt[DungeonLevel, i].strName);
          GlobalFontColor := FONTCOLOR_WHITE;
          GlobalConColor := -1;

          TransTextXY(34, 4 + z, IntToStr(ItemReceipt[DungeonLevel, i].longWood));
          TransTextXY(39, 4 + z, IntToStr(ItemReceipt[DungeonLevel, i].longMetal));
          TransTextXY(45, 4 + z, IntToStr(ItemReceipt[DungeonLevel, i].longStone));
          TransTextXY(51, 4 + z, IntToStr(ItemReceipt[DungeonLevel, i].longLeather));


          if length(ItemReceipt[DungeonLevel, i].strItem)>=10 then
          begin
            if LeftStr(ItemReceipt[DungeonLevel, i].strItem, 10)='Crystal of' then
            begin
              TransTextXY(59, 4 + z, 'Crystal of');
              TransTextXY(59, 4 + z +1, RightStr(ItemReceipt[DungeonLevel, i].strItem, length(ItemReceipt[DungeonLevel, i].strItem)-11));
            end
            else
              TransTextXY(59, 4 + z, ItemReceipt[DungeonLevel, i].strItem);
          end
          else
            TransTextXY(59, 4 + z, ItemReceipt[DungeonLevel, i].strItem);



          Inc(z);

          // - get numeric ID of item
          tid := ReturnItemByName(ItemReceipt[DungeonLevel, i].strName);

          // - display data of item

          tstr := '';

          if (Thing[tid].intWP > 0) and (Thing[tid].chLetter <> chr(160)) and (Thing[tid].chLetter <> chr(171)) then
            if Thing[tid].blWield = True then
              tstr := tstr + 'WP: ' + IntToStr(Thing[tid].intWP) + '  ';

          if Thing[tid].intGP > 0 then
            if Thing[tid].blWield = True then
              tstr := tstr + 'GP: ' + IntToStr(Thing[tid].intGP) + '  ';

          if Thing[tid].intAP > 0 then
            if (Thing[tid].blWear = True) or (Thing[tid].blHat = True) or (Thing[tid].blShoes = True) or (Thing[tid].chLetter = chr(246)) then
              tstr := tstr + 'AP: ' + IntToStr(Thing[tid].intAP) + '  ';

          if Thing[tid].intEffect > 0 then
            tstr := tstr + GetEffectDescription(Thing[tid].intEffect);

          TransTextXY(6, 4 + z, tstr);


          Inc(z);
          TransTextXY(1, 4 + z, '---------------------------------------------------------------------------');

          Inc(z);
        end;

        Inc(z);

        TransTextXY(1, 4 + z, 'Wood: ' + IntToStr(Storage.longWood));
        TransTextXY(12, 4 + z, 'Metal: ' + IntToStr(Storage.longMetal));
        TransTextXY(24, 4 + z, 'Stone: ' + IntToStr(Storage.longStone));
        TransTextXY(36, 4 + z, 'Leather: ' + IntToStr(Storage.longLeather));
        //        TransTextXY(50, 4+z, 'Plastics: ' + IntToStr(Storage.longPlastics));
        TransTextXY(50, 4 + z, 'Paper: ' + IntToStr(Storage.longPaper));

        longValue := 0;
        Inc(longValue, Storage.longWood * CONST_GOLDWOOD);
        Inc(longValue, Storage.longMetal * CONST_GOLDMETAL);
        Inc(longValue, Storage.longStone * CONST_GOLDSTONE);
        Inc(longValue, Storage.longLeather * CONST_GOLDLEATHER);
        //        Inc(longValue, Storage.longPlastics * CONST_GOLDPLASTICS);
        Inc(longValue, Storage.longPaper * CONST_GOLDPAPER);


        dummy := GetKeyInput('[c]raft item   [i]nfo   [s]ell resource  [I]nventory', False);

      until (dummy = 's') or (dummy = 'c') or (dummy = 'i') or (dummy = 'I') or (dummy = 'ESC');

      ch := dummy[1];

      if dummy = 'ESC' then
        blCloseWorkshop := True;

      if ch = 'I' then
        ShowInventory;

      // info
      if ch = 'i' then
      begin
        repeat
          BottomBar;
          Val(GetKeyInput('Selection?', False), n);
        until (n = 0) or ((n > 0) and (n < 6));
        if n > 0 then
          ItemInfo(ReturnItemByName(ItemReceipt[DungeonLevel, n].strName));
      end;

      // craft item
      if ch = 'c' then
      begin

        // 2. select the item to craft
        repeat
          BottomBar;
          Val(GetKeyInput('Selection?', False), n);
        until (n = 0) or ((n > 0) and (n < 6));

        if n > 0 then
        begin

          // 3. check for resources
          intCraftOK := 0;
          if Storage.longWood < ItemReceipt[DungeonLevel, n].longWood then
            intCraftOK := 1;
          if Storage.longMetal < ItemReceipt[DungeonLevel, n].longMetal then
            intCraftOK := 1;
          if Storage.longStone < ItemReceipt[DungeonLevel, n].longStone then
            intCraftOK := 1;
          if Storage.longLeather < ItemReceipt[DungeonLevel, n].longLeather then
            intCraftOK := 1;

          if ItemReceipt[DungeonLevel, n].strItem <> '-' then
            if PlayerHasItem(ItemReceipt[DungeonLevel, n].strItem) = -1 then
              intCraftOK := 2;


          if intCraftOK = 0 then
          begin
            // 4. try to put item in inventory
            slot := ReturnSameItemInventorySlot(ReturnItemByName(ItemReceipt[DungeonLevel, n].strName));
            if slot > -1 then  // already a stack of this item type?
            begin
              Inc(inventory[slot].longNumber);
            end
            else
            begin // okay, no stack, so ...
              slot := ReturnFreeInventorySlot;
              if slot > -1 then  // ... a free slot?
              begin
                inventory[slot].intType := ReturnItemByName(ItemReceipt[DungeonLevel, n].strName);
                inventory[slot].longNumber := 1;
              end
              else // well, no space.
                GetKeyInput('You have no free space in your inventory.', True);
            end;

            // 5. reduce resources, if successful
            if slot > -1 then
            begin
              Thing[inventory[slot].intType].blIdentified := True;
              Dec(storage.longWood, ItemReceipt[DungeonLevel, n].longWood);
              Dec(storage.longMetal, ItemReceipt[DungeonLevel, n].longMetal);
              Dec(storage.longStone, ItemReceipt[DungeonLevel, n].longStone);
              Dec(storage.longLeather, ItemReceipt[DungeonLevel, n].longLeather);

              if ItemReceipt[DungeonLevel, n].strItem <> '-' then
              begin
                Dec(Inventory[PlayerHasItem(ItemReceipt[DungeonLevel, n].strItem)].longNumber);
                if Inventory[PlayerHasItem(ItemReceipt[DungeonLevel, n].strItem)].longNumber = 0 then
                  Inventory[PlayerHasItem(ItemReceipt[DungeonLevel, n].strItem)].intType := 0;
              end;
              GetKeyInput('You have crafted an item: ' + ItemReceipt[DungeonLevel, n].strName, True);
              StoreAchievement('Crafted an item: ' + ItemReceipt[DungeonLevel, n].strName);
            end;
          end
          else
          begin
            if intCraftOK = 1 then
              GetKeyInput('You don' + chr(39) + 't have enough resources to craft the ' + ItemReceipt[DungeonLevel, n].strName + '.', True)
            else
              GetKeyInput('You don' + chr(39) + 't have a required item to craft the ' + ItemReceipt[DungeonLevel, n].strName + '.', True);
          end;
        end;
      end;

      // sell resource
      if ch = 's' then
      begin
        BottomBar;
        repeat
          dummy := GetKeyInput('Sell [w]ood, [m]etal, [s]tone, [l]eather or [p]aper?', False);
        until (dummy = 'w') or (dummy = 'm') or (dummy = 's') or
          (dummy = 'l') or (dummy = 'p') or (dummy = 'ESC');
        ch := dummy[1];

        if ch <> 'E' then
          case ch of
            'w':
            begin
              if Storage.longWood > 0 then
              begin
                Val(GetTextInput('How many of your ' + IntToStr(
                  Storage.longWood) + ' units of wood do you want to sell?', 8), n);
                if (n > 0) and (n <= Storage.longWood) then
                begin
                  Dec(Storage.longWood, n);
                  Inc(ThePlayer.longGold, CONST_GOLDWOOD * n);
                  ShowTransMessage('You have sold ' + IntToStr(
                    n) + ' units of wood for ' + IntToStr(CONST_GOLDWOOD * n) +
                    ' Credits.', False);
                  n := 0;
                end;

                if (n > 0) and (n > Storage.longWood) then
                begin
                  GetKeyInput('You do not have that much wood.', True);
                  n := 0;
                end;

                if (n < 0) then
                begin
                  GetKeyInput('You can' + chr(39) +
                    't sell negative amounts of wood.', True);
                  n := 0;
                end;
              end
              else
                GetKeyInput('You don' + chr(39) + 't have any wood to sell.', True);
            end;

            'm':
            begin
              if Storage.longMetal > 0 then
              begin
                Val(GetTextInput('How many of your ' + IntToStr(
                  Storage.longMetal) + ' units of metal do you want to sell?', 8), n);
                if (n > 0) and (n <= Storage.longMetal) then
                begin
                  Dec(Storage.longMetal, n);
                  Inc(ThePlayer.longGold, CONST_GOLDMETAL * n);
                  ShowTransMessage('You have sold ' + IntToStr(
                    n) + ' units of metal for ' + IntToStr(CONST_GOLDMETAL * n) +
                    ' Credits.', False);
                  n := 0;
                end;

                if (n > 0) and (n > Storage.longMetal) then
                begin
                  GetKeyInput('You do not have that much metal.', True);
                  n := 0;
                end;

                if (n < 0) then
                begin
                  GetKeyInput('You can' + chr(39) +
                    't sell negative amounts of metal.', True);
                  n := 0;
                end;
              end
              else
                GetKeyInput('You don' + chr(39) + 't have any metal to sell.', True);
            end;

            's':
            begin
              if Storage.longStone > 0 then
              begin
                Val(GetTextInput('How many of your ' + IntToStr(
                  Storage.longStone) + ' units of stone do you want to sell?', 8), n);
                if (n > 0) and (n <= Storage.longStone) then
                begin
                  Dec(Storage.longStone, n);
                  Inc(ThePlayer.longGold, CONST_GOLDSTONE * n);
                  ShowTransMessage('You have sold ' + IntToStr(
                    n) + ' units of stone for ' + IntToStr(CONST_GOLDSTONE * n) +
                    ' Credits.', False);
                  n := 0;
                end;

                if (n > 0) and (n > Storage.longStone) then
                begin
                  GetKeyInput('You do not have that much stone.', True);
                  n := 0;
                end;

                if (n < 0) then
                begin
                  GetKeyInput('You can' + chr(39) +
                    't sell negative amounts of stone.', True);
                  n := 0;
                end;
              end
              else
                GetKeyInput('You don' + chr(39) + 't have any stone to sell.', True);
            end;

            'l':
            begin
              if Storage.longLeather > 0 then
              begin
                Val(GetTextInput('How many of your ' + IntToStr(
                  Storage.longLeather) + ' units of leather do you want to sell?', 8), n);
                if (n > 0) and (n <= Storage.longLeather) then
                begin
                  Dec(Storage.longLeather, n);
                  Inc(ThePlayer.longGold, CONST_GOLDLEATHER * n);
                  ShowTransMessage('You have sold ' + IntToStr(
                    n) + ' units of leather for ' + IntToStr(CONST_GOLDLEATHER * n) +
                    ' Credits.', False);
                  n := 0;
                end;

                if (n > 0) and (n > Storage.longLeather) then
                begin
                  GetKeyInput('You do not have that much leather.', True);
                  n := 0;
                end;

                if (n < 0) then
                begin
                  GetKeyInput('You can' + chr(39) +
                    't sell negative amounts of leather.', True);
                  n := 0;
                end;
              end
              else
                GetKeyInput('You don' + chr(39) +
                  't have any leather to sell.', True);
            end;


            //'p':
            //begin
            //  if Storage.longPlastics > 0 then
            //  begin
            //    Val(GetTextInput('How many of your ' + IntToStr(
            //      Storage.longPlastics) +
            //      ' units of plastics do you want to sell?', 8), n);
            //    if (n > 0) and (n <= Storage.longPlastics) then
            //    begin
            //      Dec(Storage.longPlastics, n);
            //      Inc(ThePlayer.longGold, CONST_GOLDPLASTICS * n);
            //      ShowTransMessage('You have sold ' + IntToStr(
            //        n) + ' units of plastics for ' + IntToStr(CONST_GOLDPLASTICS * n) +
            //        ' Credits.', False);
            //      n := 0;
            //    end;

            //    if (n > 0) and (n > Storage.longPlastics) then
            //    begin
            //      GetKeyInput('You do not have that much plastics.', True);
            //      n := 0;
            //    end;

            //    if (n < 0) then
            //    begin
            //      GetKeyInput('You can' + chr(39) +
            //        't sell negative amounts of plastics.', True);
            //      n := 0;
            //    end;
            //  end
            //  else
            //    GetKeyInput('You don' + chr(39) +
            //      't have any plastics to sell.', True);
            //end;


            'p':
            begin
              if Storage.longPaper > 0 then
              begin
                Val(GetTextInput('How many of your ' + IntToStr(
                  Storage.longPaper) + ' units of paper do you want to sell?', 8), n);
                if (n > 0) and (n <= Storage.longPaper) then
                begin
                  Dec(Storage.longPaper, n);
                  Inc(ThePlayer.longGold, CONST_GOLDPAPER * n);
                  ShowTransMessage('You have sold ' + IntToStr(
                    n) + ' units of paper for ' + IntToStr(CONST_GOLDPAPER * n) +
                    ' Credits.', False);
                  n := 0;
                end;

                if (n > 0) and (n > Storage.longPaper) then
                begin
                  GetKeyInput('You do not have that much paper.', True);
                  n := 0;
                end;

                if (n < 0) then
                begin
                  GetKeyInput('You can' + chr(39) +
                    't sell negative amounts of paper.', True);
                  n := 0;
                end;
              end
              else
                GetKeyInput('You don' + chr(39) + 't have any paper to sell.', True);
            end;

          end;
      end;

    until blCloseWorkshop = True;

    ClearScreenSDL;
  end;


  procedure Academy;
  var
    ch, dummy: string;
    intPrice: integer;
  begin
    DecoIcon.x := 160;
    DecoIcon.y := 80;
    DecoIcon.w := 60;
    DecoIcon.h := 80;

    DecoIconS.x := 711 + HiResOffsetX;
    DecoIconS.y := 400 + HiResOffsetY;
    DecoIconS.w := 72;
    DecoIconS.h := 72;

    ClearScreenSDL;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/invbg.jpg');
    end;

    repeat

      if UseSDL = True then
      begin
        BlitImage_Title;
        SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
      end
      else
      begin
        DialogWin;
        StatusDeco;
      end;

      TransTextXY(1, 1, 'PUBLIC ACADEMY');
      TransTextXY(62, 1, 'Credits: ' + IntToStr(ThePlayer.longGold));

      TransTextXY(8, 5, 'You can spend ' + IntToStr(ThePlayer.longSkillPoints) + ' skill points.');

      intPrice := 300 * DiffLevel;

      if PlayerHasItem('V.I.P. Card') > 0 then
        Dec(intPrice, abs(ThePlayer.intTrade) * 2);
      TransTextXY(8, 7, 'A preparation course to gain one skill point is for ' +
        IntToStr(intPrice) + ' Credits.');
      TransTextXY(8, 8, 'Improving one skill in a regular course costs one skill point.');

      dummy := GetKeyInput(
        '[p]reparation course   [r]egular course', False);

    until (dummy = 'p') or (dummy = 'r') or (dummy = 'ESC');

    ch := dummy;

    if ch <> 'ESC' then
    begin

      if ch = 'p' then
        if ThePlayer.longGold >= intPrice then
        begin
          Inc(ThePlayer.longSkillPoints);
          Dec(ThePlayer.longGold, intPrice);
          StoreAchievement('Took part in a preparation course at the academy.');
          GetKeyInput('You took part in a preparation course and gained one skill point.', True);
        end
        else
          GetKeyInput('You don' + chr(39) +
            't have enough money for the course.', True);

      if ch = 'r' then
        if ThePlayer.longSkillPoints > 0 then
        begin
          ClearScreenSDL;
          TrainSkill(ThePlayer.longSkillPoints);
          ThePlayer.longSkillPoints := 0;
        end
        else
          GetKeyInput('You don' + chr(39) +
            't meet the requirements to absolve a regular course.', True);
    end;

    ClearScreenSDL;

  end;



  procedure ShowShop(intID: integer);
  var
    i, t: integer;
    n, p: longint;
    ch, dummy: string;
    equi: char;
    blRemItem, blCloseShop: boolean;
  begin

    blCloseShop := False;

    repeat

      DecoIcon.w := 80;
      DecoIcon.y := 80;
      DecoIcon.h := 80;

      case intID of
        1:
          DecoIcon.x := 360;
        2:
          DecoIcon.x := 280;
        3:
        begin
          DecoIcon.x := 220;
          DecoIcon.w := 60;
        end;
        4:
          DecoIcon.x := 0;
      end;

      DecoIconS.x := 711 + HiResOffsetX;
      DecoIconS.y := 400 + HiResOffsetY;
      DecoIconS.w := 72;
      DecoIconS.h := 72;

      if UseSDL = True then
      begin
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        DarkenScreen;
        LoadImage_Title('graphics/invbg.jpg');
      end;

      repeat

        if UseSDL = True then
        begin
          BlitImage_Title;
          SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
        end
        else
        begin
          DialogWin;
          StatusDeco;
        end;


        TransTextXY(1, 1, uppercase(Shops[MyShop[intID].intType]));
        TransTextXY(62, 1, 'Credits: ' + IntToStr(ThePlayer.longGold));

        for i := 1 to 16 do
        begin
          if MyShop[intID].Inventory[i].intType > 0 then
          begin
            p := CollectBuyPrice(MyShop[intID].Inventory[i].intType);

            TransTextXY(6, 4 + i, IntToStr(i)); // slot
            CharXY(11, 4 + i, thing[MyShop[intID].Inventory[i].intType].chLetter, 0, True); // icon


            SetItemNameColor (thing[MyShop[intID].Inventory[i].intType].strRealName); // item name color

            if thing[MyShop[intID].Inventory[i].intType].intAmount>1 then // if item package, show number of items in package
              TransTextXY(12, 4 + i, thing[MyShop[intID].Inventory[i].intType].strRealName + ' (x'+IntToStr(thing[MyShop[intID].Inventory[i].intType].intAmount)+')') // name + amount in package
            else
              TransTextXY(12, 4 + i, thing[MyShop[intID].Inventory[i].intType].strRealName); // name

            GlobalFontColor := FONTCOLOR_WHITE;
            GlobalConColor := -1;
            TransTextXY(40, 4 + i, '$' + IntToStr(p)); // price

            equi := chr(32);

            // mark items with + - =
            if ThePlayer.intArmour > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intAP > 0 then
                if thing[MyShop[intID].Inventory[i].intType].blWear = True then
                begin
                  if thing[MyShop[intID].Inventory[i].intType].intAP >
                    thing[ThePlayer.intArmour].intAP then
                    equi := chr(214);
                  if thing[MyShop[intID].Inventory[i].intType].intAP <
                    thing[ThePlayer.intArmour].intAP then
                    equi := chr(215);
                  if thing[MyShop[intID].Inventory[i].intType].intAP =
                    thing[ThePlayer.intArmour].intAP then
                    equi := chr(216);
                end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified = False then
                if thing[MyShop[intID].Inventory[i].intType].blWear = True then
                  equi := chr(217);
            end;

            if ThePlayer.intHat > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intAP > 0 then
                if thing[MyShop[intID].Inventory[i].intType].blHat = True then
                begin
                  if thing[MyShop[intID].Inventory[i].intType].intAP >
                    thing[ThePlayer.intHat].intAP then
                    equi := chr(214);
                  if thing[MyShop[intID].Inventory[i].intType].intAP <
                    thing[ThePlayer.intHat].intAP then
                    equi := chr(215);
                  if thing[MyShop[intID].Inventory[i].intType].intAP =
                    thing[ThePlayer.intHat].intAP then
                    equi := chr(216);
                end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified =
                False then
                if thing[MyShop[intID].Inventory[i].intType].blHat = True then
                  equi := chr(217);
            end;

            if ThePlayer.intFeet > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intAP > 0 then
                if thing[MyShop[intID].Inventory[i].intType].blShoes = True then
                begin
                  if thing[MyShop[intID].Inventory[i].intType].intAP >
                    thing[ThePlayer.intFeet].intAP then
                    equi := chr(214);
                  if thing[MyShop[intID].Inventory[i].intType].intAP <
                    thing[ThePlayer.intFeet].intAP then
                    equi := chr(215);
                  if thing[MyShop[intID].Inventory[i].intType].intAP =
                    thing[ThePlayer.intFeet].intAP then
                    equi := chr(216);
                end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified =
                False then
                if thing[MyShop[intID].Inventory[i].intType].blShoes = True then
                  equi := chr(217);
            end;

            if ThePlayer.intExtra > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intAP > 0 then
                if thing[MyShop[intID].Inventory[i].intType].blExtra = True then
                begin
                  if thing[MyShop[intID].Inventory[i].intType].intAP >
                    thing[ThePlayer.intExtra].intAP then
                    equi := chr(214);
                  if thing[MyShop[intID].Inventory[i].intType].intAP <
                    thing[ThePlayer.intExtra].intAP then
                    equi := chr(215);
                  if thing[MyShop[intID].Inventory[i].intType].intAP =
                    thing[ThePlayer.intExtra].intAP then
                    equi := chr(216);
                end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified =
                False then
                if thing[MyShop[intID].Inventory[i].intType].blExtra = True then
                  equi := chr(217);
            end;


            if ThePlayer.intWeapon > 0 then
            begin
              if thing[MyShop[intID].Inventory[i].intType].intWP > 0 then
                if thing[ThePlayer.intWeapon].intWP > 0 then
                  if thing[MyShop[intID].Inventory[i].intType].blWield =
                    True then
                  begin
                    if thing[MyShop[intID].Inventory[i].intType].intWP >
                      thing[ThePlayer.intWeapon].intWP then
                      equi := chr(214);
                    if thing[MyShop[intID].Inventory[i].intType].intWP <
                      thing[ThePlayer.intWeapon].intWP then
                      equi := chr(215);
                    if thing[MyShop[intID].Inventory[i].intType].intWP =
                      thing[ThePlayer.intWeapon].intWP then
                      equi := chr(216);
                  end;

              if thing[MyShop[intID].Inventory[i].intType].intGP > 0 then
                if thing[ThePlayer.intWeapon].intGP > 0 then
                  if thing[MyShop[intID].Inventory[i].intType].blWield =
                    True then
                  begin
                    if thing[MyShop[intID].Inventory[i].intType].intGP >
                      thing[ThePlayer.intWeapon].intGP then
                      equi := chr(214);
                    if thing[MyShop[intID].Inventory[i].intType].intGP <
                      thing[ThePlayer.intWeapon].intGP then
                      equi := chr(215);
                    if thing[MyShop[intID].Inventory[i].intType].intGP =
                      thing[ThePlayer.intWeapon].intGP then
                      equi := chr(216);
                  end;

              if thing[MyShop[intID].Inventory[i].intType].blIdentified =
                False then
                if thing[MyShop[intID].Inventory[i].intType].blWield = True then
                  equi := chr(217);
            end;

            // mark items with a higher clvl
            if ThePlayer.intLvl <
              Thing[MyShop[intID].Inventory[i].intType].intCharLvl then
              equi := chr(218);

            if equi <> chr(32) then
              CharXY(47, 4 + i, equi, 0, True);

            // mark items with a higher skill
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(156)) then
              if ThePlayer.intSword <
                Thing[MyShop[intID].Inventory[i].intType].intWP then
                TransTextXY(52, 4 + i, 'Skill!');
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(159)) then
              if ThePlayer.intAxe <
                Thing[MyShop[intID].Inventory[i].intType].intWP then
                TransTextXY(52, 4 + i, 'Skill!');
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(164)) then
              if ThePlayer.intWhip <
                Thing[MyShop[intID].Inventory[i].intType].intWP then
                TransTextXY(52, 4 + i, 'Skill!');
            if (Thing[MyShop[intID].Inventory[i].intType].chLetter = chr(158)) then
              if ThePlayer.intGun <
                Thing[MyShop[intID].Inventory[i].intType].intGP then
                TransTextXY(52, 4 + i, 'Skill!');

            // mark useless items
            if (ThePlayer.intProf <>
              Thing[MyShop[intID].Inventory[i].intType].intProf) and
              (Thing[MyShop[intID].Inventory[i].intType].intProf > 0) then
            begin
              case Thing[MyShop[intID].Inventory[i].intType].intProf of
                1:
                  TransTextXY(59, 4 + i, 'Constructor!');
                // obsolete since LR 1.4
                2:
                  TransTextXY(59, 4 + i, 'Enchanter!');
                3:
                  TransTextXY(59, 4 + i, 'Thief!');
                4:
                  TransTextXY(59, 4 + i, 'Archer!');
                5:
                  TransTextXY(59, 4 + i, 'Soldier!');
              end;
            end;
          end;
        end;

        n := -1;


        dummy := GetKeyInput('[g]et item  [i]nfo about item  [I]nventory', False);
      until (dummy = 'g') or (dummy = 'i') or (dummy = 'I') or (dummy = 'ESC');
      ch := dummy;

      if ch = 'ESC' then
        blCloseShop := True;

      if ch = 'I' then
        ShowInventory;

      if ch = 'i' then
      begin
        if (UseSDL = False) or (UseMouseToMove = False) then
          repeat
            Val(GetTextInput(
              'Enter the number of the item you wish to see [ENTER to cancel]:', 2), n);
          until (n = 0) or ((n > 0) and (n < 17) and
              (MyShop[intID].Inventory[n].intType > 0));

        if n > 0 then
          ItemInfo(MyShop[intID].Inventory[n].intType);
      end;

      if ch = 'g' then
      begin
        if (UseSDL = False) or (UseMouseToMove = False) then
          repeat
            Val(GetTextInput(
              'Enter the number of the item you wish to buy [ENTER to cancel]:', 2), n);
          until (n = 0) or ((n > 0) and (n < 17) and
              (MyShop[intID].Inventory[n].intType > 0));

        if n > 0 then
        begin

          t := MyShop[intID].Inventory[n].intType;
          p := CollectBuyPrice(t);

          blRemItem := False;

          // has player enough money?
          if ThePlayer.longGold >= p then
          begin
            // check if player already has one item of this type
            for i := 1 to 16 do
              if inventory[i].intType = t then
              begin
                Inc(inventory[i].longNumber,
                  Thing[Inventory[i].intType].intAmount);
                blRemItem := True;
                break;
              end;

            // if item not bought, check if free space available
            if blRemItem = False then
              for i := 1 to 16 do
                if (inventory[i].intType = 0) and (blRemItem = False) then
                begin
                  inventory[i].intType := t;
                  inventory[i].longNumber :=
                    Thing[Inventory[i].intType].intAmount;
                  blRemItem := True;
                  break;
                end;

            // if item taken, identify item type and remove item from store
            if blRemItem then
            begin
              PlaySFX('coins.ogg');
              Thing[MyShop[intID].Inventory[n].intType].blIdentified := True;
              Thing[MyShop[intID].Inventory[n].intType].strName :=
                Thing[MyShop[intID].Inventory[n].intType].strRealName;

              MyShop[intID].Inventory[n].intType := 0;

              Dec(ThePlayer.longGold, p);
              ShowTransMessage('You buy the ' + Thing[t].strName + '.', False);
            end
            else
              GetKeyInput('You want to buy the ' + Thing[t].strName +
                ', but your inventory is full.', True);
          end
          else
            GetKeyInput('You need more Credits to buy this.', True);

        end;
      end;

    until blCloseShop = True;

    ClearScreenSDL;
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  end;


  // bind F-key to Spell
  procedure BindQuickKey_Spell(n: integer);
  var
    id: integer;
  begin
    id := -1;
    repeat
      Val(GetTextInput('Which chant do you want to bind to quickkey F' +
        IntToStr(n) + '?', 2), id);
    until (id = 0) or ((id > 0) and (id < 13) and (Spellbook[id].intType > 0));

    if id > 0 then
      strQuickKey[n] := Spell[spellbook[id].intType].strName;
  end;



  // show binding of F-keys to spells or items
  procedure SetQuickKeys;
  var
    dummy, ch: string;
  begin
    // display a list of quick keys
    if UseSDL = True then
      LoadImage_Title('graphics/invbg.jpg')
    else
      ClearScreenSDL;

    repeat
      if UseSDL = True then
      begin
        BlitImage_Title;
      end
      else
      begin
        DialogWin;
        StatusDeco;
      end;

      TransTextXY(1, 1, 'QUICKKEY BINDINGS');

      for i := 1 to 12 do
      begin
        TransTextXY(6, 4 + i, 'F' + IntToStr(i));
        if strQuickKey[i] <> '-' then
          TransTextXY(10, 4 + i, strQuickKey[i]);
      end;

      TransTextXY(6, 18,
        'To bind an item or chant to a quickkey, go to inventory or songbook');
      TransTextXY(6, 19, 'and press one of the function keys (F1 to F12).');

      dummy := GetKeyInput(
        '[F1] to [F12] delete binding   [r]eset bar position',
        False);
    until (dummy = 'ESC') or (dummy = 'r') or (dummy = 'F1') or
      (dummy = 'F2') or (dummy = 'F3') or (dummy = 'F4') or (dummy = 'F5') or
      (dummy = 'F6') or (dummy = 'F7') or (dummy = 'F8') or (dummy = 'F9') or
      (dummy = 'F10') or (dummy = 'F11') or (dummy = 'F12');

    ch := dummy;

    if ch = 'r' then
      if UseHiRes = True then
      begin
        ChantBarX := 239;
        ChantBarY := 708;
      end
      else
      begin
        ChantBarX := 254;
        ChantBarY := 540;
      end;

    if ch = 'F1' then
      strQuickKey[1] := '-';

    if ch = 'F2' then
      strQuickKey[2] := '-';

    if ch = 'F3' then
      strQuickKey[3] := '-';

    if ch = 'F4' then
      strQuickKey[4] := '-';

    if ch = 'F5' then
      strQuickKey[5] := '-';

    if ch = 'F6' then
      strQuickKey[6] := '-';

    if ch = 'F7' then
      strQuickKey[7] := '-';

    if ch = 'F8' then
      strQuickKey[8] := '-';

    if ch = 'F9' then
      strQuickKey[9] := '-';

    if ch = 'F10' then
      strQuickKey[10] := '-';

    if ch = 'F11' then
      strQuickKey[11] := '-';

    if ch = 'F12' then
      strQuickKey[12] := '-';

  end;


  // chant song number n from songbook
  procedure ChantSong(n: integer);
  var
    t, e, c, d: integer;
  begin

    t := spellbook[n].intType;

    if t > 0 then
    begin
      if (ThePlayer.blCursed = True) or (ThePlayer.intCalm > 0) or
        ((DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 11) and
        (ThePlayer.blBlessed = False)) then
        ShowTransMessage(
          'Your magic skills are blocked; you cannot chant songs right now.', False)
      else
      begin
        if ThePlayer.intPP >= Spell[t].intPP + spellbook[n].intKnown then
        begin
          if Spellbook[n].intRefresh = Spell[t].intRefresh then
          begin

            // song efficiency
            if CheckEffect(37) = True then
              e := 2 * (Spell[t].intRange + (Spellbook[n].intKnown * Spellbook[n].intKnown))   // maximized magic
            else
              e := Spell[t].intRange + (Spellbook[n].intKnown * Spellbook[n].intKnown);

            // song costs
            c := Spell[t].intPP + (2 * spellbook[n].intKnown);
            if CheckEffect(57) = True then  // Reduced PP Costs
              d := d - (d div 4);

            Dec(ThePlayer.intPP, c);
            // always reduce the PP, even if spell fails!

            if (random(CollectChant * 1500) > CONST_SPELLRATE) or (ThePlayer.blBlessed = True) then
            begin
              LastSong := n;
              ShowTransMessage('You chant the song "' + Spell[t].strName + '".', False);
              DoEffect(Spell[t].intEffect, e, Spell[t].strEfText);
              spellbook[n].intRefresh := 0;
            end
            else
            begin
              PlaySFX('magic-fail.ogg');
              ShowTransMessage('You failed to chant the song correctly.', False);
            end;
          end
          else
            ShowTransMessage('This song has not yet recovered.', False);
        end
        else
          ShowTransMessage('You need more PP to chant this song.', False);

      end;
    end;
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  end;


  // This procedure takes the number of the pressed F-key and then decides whether to drink/eat an item or to call ChantSong
  procedure QuickKeys(n: integer);
  var
    i, id, invID: integer;
    blIsSpell: boolean;
  begin
    blIsSpell := False;
    id := -1;
    invID := -1;

    // okay ... we got the number of the function key, now scan all items and spells
    // if there is a matching name to the name in the function key array
    for i := 1 to ChantCount do
      if Spell[i].strName = strQuickKey[n] then
      begin
        id := i;
        blIsSpell := True;
      end;

    if blIsSpell = False then
      for i := 1 to ItemCount do
        if Thing[i].strRealName = strQuickKey[n] then
          id := i;


    // Spell or Item found?
    if id > -1 then
      if blIsSpell = True then
      begin
        // get ID of Spell in Songbook
        for i := 1 to 12 do
          if SpellBook[i].intType = id then
            invID := i;
        ChantSong(invID);  // execute Spell
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

        if UseSDL = True then
          SDL_UPDATERECT(screen, 0, 0, 0, 0)
        else
          UpdateScreen(True);
      end
      else
      begin
        // get ID of Item in Inventory
        for i := 1 to 16 do
          if Inventory[i].intType = id then
            invID := i;

        // only use item if we have a real item invID
        if invID > -1 then
          if inventory[invID].longNumber > 0 then
            // invID only guarantees that there is an item referenced in invslot, but this ID can also be less than 1
          begin
            // although only identified items can be bound to quick keys, make sure to identify item ...
            Thing[inventory[invID].intType].blIdentified := True;
            Thing[inventory[invID].intType].strName :=
              Thing[inventory[invID].intType].strRealName;

            // execute item effect
            DoEffect(thing[inventory[invID].intType].intEffect,
              thing[inventory[invID].intType].intRange,
              thing[inventory[invID].intType].strEfText);

            // decrease amount of item in inventory
            Dec(inventory[invID].longNumber);
            if inventory[invID].longNumber = 0 then
              inventory[invID].intType := 0;

            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            if UseSDL = True then
              SDL_UPDATERECT(screen, 0, 0, 0, 0)
            else
              UpdateScreen(True);
          end;
      end;
  end;



  // This is the spellbook
  procedure ShowSpellbook;
  var
    i, d: integer;
    n: longint;
    ch, dummy: string;
    blCloseBook: boolean;
  begin

    PlaySFX('page-turn.ogg');

    DecoIcon.x := 0;
    DecoIcon.y := 80;
    DecoIcon.w := 80;
    DecoIcon.h := 80;

    DecoIconS.x := 711 + HiResOffsetX;
    DecoIconS.y := 400 + HiResOffsetY;
    DecoIconS.w := 72;
    DecoIconS.h := 72;

    blCloseBook := False;
    repeat

      if UseSDL = True then
      begin
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        DarkenScreen;
        LoadImage_Title('graphics/invbg.jpg');
      end
      else
        ClearScreenSDL;


      repeat

        if UseSDL = True then
        begin
          BlitImage_Title;
          SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
        end
        else
        begin
          DialogWin;
          StatusDeco;
        end;

        TransTextXY(1, 1, 'SONGBOOK OF ' + uppercase(ThePlayer.strName));
        TransTextXY(67, 1, 'PP ' + IntToStr(ThePlayer.intPP) + '/' +
          IntToStr(ThePlayer.intMaxPP));

        for i := 1 to 12 do
          if spellbook[i].intKnown > 0 then
          begin
            TransTextXY(6, 4 + i, IntToStr(i));
            TransTextXY(10, 4 + i, '"' + Spell[spellbook[i].intType].strName + '", level ' + IntToStr(spellbook[i].intKnown));

            d := Spell[spellbook[i].intType].intPP + (2 * spellbook[i].intKnown);
            if CheckEffect(57) = True then
              d := d - (d div 4);
            TransTextXY(35, 4 + i, 'PP: -' + IntToStr(d));

            if spellbook[i].intRefresh < Spell[spellbook[i].intType].intRefresh then
              TransTextXY(45, 4 + i, ' ' + IntToStr(Spell[spellbook[i].intType].intRefresh - spellbook[i].intRefresh) + ' turn(s) for refresh');
          end;

        n := -1;

        dummy := GetKeyInput('[c]hant song   [i]nfo about song', False);

      until (dummy = 'c') or (dummy = 'i') or (dummy = 'ESC') or
        (dummy = 'F1') or (dummy = 'F2') or (dummy = 'F3') or (dummy = 'F4') or
        (dummy = 'F5') or (dummy = 'F6') or (dummy = 'F7') or (dummy = 'F8') or
        (dummy = 'F9') or (dummy = 'F10') or (dummy = 'F11') or (dummy = 'F12');

      ch := dummy;

      if ch = 'ESC' then
        blCloseBook := True;

      // define quick keys
      if ch = 'F1' then
        BindQuickKey_Spell(1);

      if ch = 'F2' then
        BindQuickKey_Spell(2);

      if ch = 'F3' then
        BindQuickKey_Spell(3);

      if ch = 'F4' then
        BindQuickKey_Spell(4);

      if ch = 'F5' then
        BindQuickKey_Spell(5);

      if ch = 'F6' then
        BindQuickKey_Spell(6);

      if ch = 'F7' then
        BindQuickKey_Spell(7);

      if ch = 'F8' then
        BindQuickKey_Spell(8);

      if ch = 'F9' then
        BindQuickKey_Spell(9);

      if ch = 'F10' then
        BindQuickKey_Spell(10);

      if ch = 'F11' then
        BindQuickKey_Spell(11);

      if ch = 'F12' then
        BindQuickKey_Spell(12);

      if ch = 'c' then
      begin

        if (ThePlayer.blCursed = True) or (ThePlayer.intCalm > 0) or
          ((DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 11) and
          (ThePlayer.blBlessed = False)) then
          ShowTransMessage(
            'Your magic skills are blocked; you cannot chant songs right now.', False)
        else
        begin
          if (UseSDL = False) or (UseMouseToMove = False) then
            repeat
              Val(GetTextInput(
                'Enter the number of the magical song to chant [ENTER to cancel]:', 2), n);
            until (n = 0) or ((n > 0) and (n < 13) and (Spellbook[n].intKnown > 0));

          if n > 0 then
          begin
            if Spellbook[n].intType > 0 then
            begin
              ChantSong(n);
              blCloseBook := True;
            end
            else
              GetKeyInput('You need at least level ' +
                IntToStr(Spell[spellbook[n].intType].intCharLvl) +
                ' to chant this song.', True);
          end;
        end;
      end;

      if ch = 'i' then
      begin
        if (UseSDL = False) or (UseMouseToMove = False) then
          repeat
            Val(GetTextInput('Select a magical song:', 2), n);
          until (n = 0) or ((n > 0) and (n < 13) and (Spellbook[n].intKnown > 0));

        if n > 0 then
          if Spellbook[n].intType > 0 then
            SpellInfo(spellbook[n].intType, n);
      end;
    until blCloseBook = True;



    ClearScreenSDL;
  end;


  // chants the last song
  procedure ChantLastSong;
  begin
    if LastSong > 0 then
      ChantSong(LastSong)
    else
      ShowSpellbook;
  end;


  procedure DivineDialogue;
  var
    strWish, strAnswer: string;
    i, n, FreeMonsterID: integer;
  begin

    if random(500)>485 then
    begin
      ShowDialog(uppercase(ThePlayer.strReli),
        ThePlayer.strName +
        ', tell me in one word: What is your request?',
        '',
        '',
        '',
        '', False);

      strWish := trim(lowercase(GetTextInput('', 40)));

      strAnswer := 'This, humble human, is not for you.';

      if (strWish='healing') or (strWish='heal') or (strWish='health') or (strWish='cure') or (strWish='hp') or (strWish='hit points') then
      begin
        if ThePlayer.intHP<ThePlayer.intMaxHP then
        begin
          PlaySFX('magic-holy.ogg');
          ThePlayer.intHP := ThePlayer.intMaxHP;
          strAnswer:='I grant you health.';
        end
        else
          strAnswer:='You need no healing at the moment.';
      end;

      if (strWish='psychic power') or (strWish='pp') or (strWish='psychic points') or (strWish='mana') or (strWish='mp') or (strWish='magicka') then
      begin
        if ThePlayer.intPP<ThePlayer.intMaxPP then
        begin
          PlaySFX('magic-holy.ogg');
          ThePlayer.intPP := ThePlayer.intMaxPP;
          strAnswer:='I grant you clarity.';
        end
        else
          strAnswer:='Your mind seems focused enough.';
      end;

      if (strWish='strength') or (strWish='power') or (strWish='str') then
      begin
        if ThePlayer.intStrength<200 then
        begin
          PlaySFX('magic-holy.ogg');
          inc(ThePlayer.intStrength, CollectHumility);
          if ThePlayer.intStrength>200 then
            ThePlayer.intStrength:=200;
          strAnswer:='Use your power wisely.';
        end
        else
          strAnswer:='You are strong enough.';
      end;

      if (strWish='gold') or (strWish='money') or (strWish='credits') or (strWish='cr') then
      begin
        PlaySFX('magic-holy.ogg');
        inc(ThePlayer.longGold, CollectHumility);
        strAnswer:='You should spend money for the divines.';
      end;


      // nach Monster gefragt?
      n:=0;
      for i := 1 to MonsterTemplates do
        if lowercase(MonTe[i].strName) = strWish then
          if MonTe[i].blUnique=false then
            n := i;

      if n>0 then // Monster identifiziert
      begin
        FreeMonsterID := GetFirstFreeMonsterID;
        if FreeMonsterID > -1 then
        begin
          strAnswer:='As you wish.';
          CreateMonster(FreeMonsterID, MonTe[n].strName, 0);
          Monster[FreeMonsterID].intX := ThePlayer.intX;
          Monster[FreeMonsterID].intY := ThePlayer.intY;
        end;
      end;



      // nach item gefragt?
      n:=0;
      for i := 1 to ItemCount do
        if lowercase(Thing[i].strRealName) = strWish then
           n := i;

      if n>0 then   // Item identifiziert
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem=0 then
        begin // Platz fuer Item?
          if random(500)>250 then // DAS item, oder ein anderes geben?
          begin
            if Thing[n].blUnique=false then // keine uniques
              if Thing[n].blRare=false then // keine rares
                if Thing[n].intCharLvl<=ThePlayer.intLvl then // nur <= Spielerlevel
                begin
                  PlaySFX('magic-holy.ogg');
                  DngLvl[ThePlayer.intX, ThePlayer.intY].intItem:=n;
                  strAnswer:='I grant you the requested item.';
                end;
          end
          else
          begin
            PlaySFX('magic-holy.ogg');
            DngLvl[ThePlayer.intX, ThePlayer.intY].intItem:=ReturnRandomItem;
            strAnswer:='I grant you a different thing as a generous gift.';
          end;
        end
        else
          strAnswer:='One thing after another, tiny human.';

      ShowTransMessage(ThePlayer.strReli + ' answers: "'+strAnswer+'"', false);

      // requests reduce prayers
      ThePlayer.longPrayers:=ThePlayer.longPrayers div 2;

    end;
   end;

  procedure Pray;
  var
    intGift: integer;
  begin

    if ThePlayer.blEvil = False then
    begin

      ShowTransMessage('You pray to your god.', False);
      Inc(ThePlayer.longPrayers);

      intGift := 0;

      if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType=15 then
      begin
        if (CollectHumility>7) and (ThePlayer.longPrayers>(ThePlayer.intLvl*100)*ThePlayer.intLvl) then
          DivineDialogue;
      end
      else
      begin
        if ThePlayer.blCursed = True then
          if random(500) > 450 then
          begin
            ThePlayer.blCursed := False;
            ShowTransMessage(
              'Your god has removed the curse from your soul.', False);
          end;

        if (ThePlayer.intTotalVitari > 0) and (ThePlayer.intNeedVitari >=
          ThePlayer.intNextVitari) then
          if random(500) > 480 then
          begin
            ThePlayer.intTotalVitari := 0;
            ThePlayer.intNextVitari := 0;
            ThePlayer.intNeedVitari := 0;
            ShowTransMessage(
              'Your god has healed you from your drug addiction.', False);
          end;

        if (DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 6) then
          if random(500) > 480 then
            DoEffect(21, 0, 'Your god lifts you up ...');

      end;
    end;

  end;


  procedure DrinkFromWell;
  begin
    DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 29;
    if DungeonLevel > 1 then
    begin
      DoEffect(-1, 10, 'You drink from the well, hoping that it is water ...');
    end
    else
      DoEffect(4, 10, 'You drink from the fresh water.');
  end;


  procedure ExamineCrypt;
  var
    msg1: string;
  begin

    if random(500) > 250 then
      CreateBonesMonster;

    msg1 := 'The crypt is empty';

    if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem = 0 then
    begin
      if random(CONST_CHESTISEMPTY) > 240 then
      begin
        DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ReturnRareItem;
        msg1 := 'You find something in the crypt';
      end;
    end;

    ShowTransMessage(msg1 + '.', False);

    // make crypt visited
    DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 33;
  end;


  procedure Sacrifice;
  var
    cr, percent: integer;
    mes1: string;
  begin

    if ThePlayer.blEvil = False then
    begin
      if UseSDL = False then
        for i := 22 to 25 do
          TextXY(0, i,
            '                                                                                ');

      repeat
        Val(trim(GetTextInput('How many of your ' + IntToStr(
          ThePlayer.longGold) + ' credits do you want to sacrifice?', 5)), cr);
      until (cr > -1) and (cr < ThePlayer.longGold + 1);

      if ThePlayer.longGold > 0 then
      begin

        percent := (100 * cr) div ThePlayer.longGold;

        if percent < 5 then
        begin
          mes1 := 'Do you want to fool us, unthankful human, with this "generous offer"?';
          if CollectHumility < 3 then
          begin
            BlendMagic(8);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            ThePlayer.blCursed := True;
            ThePlayer.blBlessed := False;
            mes1 := mes1 + ' Sadness creeps in your mind.';
          end;
        end;

        if percent > 5 then
          mes1 := 'Although very small, your offer is taken';
        if percent > 10 then
          mes1 := 'Your offer is taken';
        if percent > 30 then
          mes1 := 'Your offer is appreciated';
        if percent > 50 then
          mes1 := 'Your remarkable offer is very appreciated';
        if percent > 80 then
          mes1 := 'We are thankful for your great offer';
        if percent > 95 then
          mes1 := 'We feel enthusiastic about your worship';

        Dec(ThePlayer.longGold, cr);
        Inc(ThePlayer.longPrayers, CollectHumility * (percent div 3));

        ShowDialog(uppercase(ThePlayer.strReli),
          mes1 + '.',
          '',
          '',
          '',
          '', True);

        // enchanter becomes believer if more than 50% of Credits, but min. 1000, are offered
        if ThePlayer.intProf = 2 then      // enchanter
          if ThePlayer.intDipl[8] = 0 then // not believer yet
            if (cr >= 1000) and (percent > 50) then
            begin
              ThePlayer.intDipl[8] := 1;

              ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
              ShowDialog(uppercase(ThePlayer.strReli),
                'Your humility and generosity honor Us, ' + ThePlayer.strName + '. Thus, you may call',
                'yourself "Believer" now. Wander in peace, friend, and spread Our Word.', '', '', '', True);

              ShowTransMessage('You have been promoted to the rank "Believer".', True);
              StoreAchievement('Promoted to the rank "Believer".');
            end;

        if (ThePlayer.longPrayers > CONST_PRAYERSNEEDEDFORBLESS) and
          (ThePlayer.blCursed = False) then
        begin
          BlendMagic(5);
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
          ThePlayer.blBlessed := True;
          if ThePlayer.intTotalVitari > 0 then
          begin
            ThePlayer.intTotalVitari := 0;
            ThePlayer.intNextVitari := 0;
            ThePlayer.intNeedVitari := 0;
            ShowTransMessage(ThePlayer.strReli + ' blessed you and healed your from your drug addiction.', False);
          end
          else
            ShowTransMessage('You feel blessed by the spirit of ' + ThePlayer.strReli + '.', False);
        end;
      end;
    end
    else
      ShowTransMessage(ThePlayer.strReli + ' is not interested in offers from you.', False);
  end;


  // open treasure chests
  procedure LootChest;
  var
    i, j, n, t: integer;
    msg1: string;
  begin
    DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 14;
    msg1 := 'It is empty';

    n := 240;

    if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem = 0 then
    begin
      if random(CONST_CHESTISEMPTY) > n then
      begin
        i := 0;
        repeat
          Inc(i);
          j := trunc(1 + random(ItemCount));
          if (Thing[j].blUnique = False) and (Thing[j].blRare = False) and (Thing[j].blShopOnly = False) and (Thing[j].intMinLvl <= DungeonLevel) and (Thing[j].intMinLvl >= DungeonLevel - 3)then
          begin
            DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := j;
            msg1 := 'You find something';
          end;
        until (i = 2000) or (msg1 = 'You find something');
      end;
    end;

    PlaySFX('open-chest.ogg');
    ShowTransMessage('You open a treasure chest. ' + msg1 + '.', False);

    if random(500) > 440 then
    begin
      if (ThePlayer.intBurgle > 15) or (CheckEffect(41) = True) then
      begin
        // Trap prevented
        ShowTransMessage('You discovered a trap and disarmed it.', False);
      end
      else
      begin
        ShowTrapEffect(ThePlayer.intBX, ThePlayer.intBY);
        t := trunc(1 + random(6));
        Dec(ThePlayer.intHP, t);
        ShowTransMessage('You were hurt by a trap!', False);
        if IsPlayerDead = True then
          GameOver('Killed by a trap');
      end;
    end;
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  end;

  // returns true, if the given NPC on the given level is TargetID of any quest
  function IsTargetNPC(lvl, npcID: integer): boolean;
  var
    i: integer;
  begin
    IsTargetNPC := False;

    // check every quest in the level
    for i := 1 to 9 do
      if (Quest[lvl, i].intTargetID = npcID) and
        (ThePlayer.intQuestState[lvl, i] = 1) then
      begin
        IsTargetNPC := True;
        ThePlayer.intQuestState[lvl, i] := 3;
      end;
  end;

  // talk with an NPC (new)
  procedure TalkNPC(lvl, npcID: integer);
  var
    i, FreeMonsterID: integer;
    strAccQuest, strAnswer: string;
  begin

    // Check if player is evil; if yes, they won't talk to him
    if ThePlayer.blEvil = False then
    begin
      // Check if this is a NPC chosen as target in another quest
      if IsTargetNPC(lvl, npcID) = True then
      begin
        ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
          'Thanks for the delivery. Don''t forget to get your loan from your client.',
          '', '', '', '', True);

        ShowTransMessage(
          'You did the delivery [return to your client to get your loan].',
          False);
        exit;
      end;


      // Select NPC behavior depending on quest state
      // ThePlayer.intQuestState[lvl,npcID]:  0=still unvisited; 1=offered; 2=solved; 3=solved (but has to be confirmed)

      // First visit ever; offer quest
      if ThePlayer.intQuestState[lvl, npcID] = 0 then
      begin

        // first, we check all conditions the quest might depend on

        // check if player's religion is okay for quest's religion condition
        if (Quest[lvl, npcID].intClass = 0) or
          (Quest[lvl, npcID].intClass = ThePlayer.intReli) then
        begin
          // check if player's level is okay for quest's level condition
          if ThePlayer.intLvl >= Quest[lvl, npcID].intCharLvl then
          begin
            // check if the plot-condition for the quest is met
            if (Quest[lvl, npcID].intNeedPlot = 0) or
              ((Quest[lvl, npcID].intNeedPlot > 0) and
              (ThePlayer.blStory[Quest[lvl, npcID].intNeedPlot] = True)) then
            begin
              // check if the quest-condition for the quest is met
              if (Quest[lvl, npcID].intNeedQuest = 0) or
                ((Quest[lvl, npcID].intNeedQuest > 0) and
                (ThePlayer.intQuestState[lvl, Quest[lvl, npcID].intNeedQuest] = 2)) then
              begin
                // check if player's profession is okay for quest's profession condition
                if (Quest[lvl, npcID].intNeedProf = 0) or
                  (Quest[lvl, npcID].intNeedProf = ThePlayer.intProf) then
                begin
                  // check if player has needed diploma
                  if (Quest[lvl, npcID].intNeedDipl = 0) or
                    (ThePlayer.intDipl[Quest[lvl, npcID].intNeedDipl] = 1) then
                  begin
                    // show plot text, if strIntroPlot is set
                    if Quest[lvl, npcID].strIntroPlot <> '-' then
                    begin
                      DarkenScreen;
                      ShowPlot(StrToInt(Quest[lvl, npcID].strIntroPlot));
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                    end;

                    // show intro book or scroll, if strIntroText is set
                    if Quest[lvl, npcID].strIntroBook <> '-' then
                    begin
                      DarkenScreen;
                      ShowText(Quest[lvl, npcID].strIntroBook);
                      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
                    end;

                    // show NPC dialog
                    ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
                      Quest[lvl, npcID].strText1,
                      Quest[lvl, npcID].strText2,
                      Quest[lvl, npcID].strText3,
                      Quest[lvl, npcID].strText4,
                      Quest[lvl, npcID].strText5, False);

                    // Is the "quest" only an info text?
                    if Quest[lvl, npcID].intType = 6 then
                    begin
                      if UseSDL = False then
                        GetKeyInput('Press any key to continue.', False)
                      else
                      begin
                        TransTextXY(1, 28, 'Press any key to continue.');
                        GetKeyInput(' ', False);
                      end;
                      ThePlayer.intQuestState[lvl, npcID] := 3;
                    end
                    else
                    begin
                      // TransTextXY(1, 10, 'Quest: ' + Quest[lvl, npcID].strDescri);

                      // It is indeed a real quest. Offer the player to accept it.
                      if UseSDL = False then
                        strAccQuest :=
                          GetKeyInput('Press [' + KeyEnter +
                          '] to accept this quest, another key to cancel.', False)
                      else
                      begin
                        TransTextXY(1, 28, 'Press [' + KeyEnter +
                          '] to accept this quest, another key to cancel.');
                        strAccQuest := GetKeyInput(' ', False);
                      end;
                      if strAccQuest = KeyEnter then
                      begin
                        ThePlayer.intQuestState[lvl, npcID] := 1;
                        ShowTransMessage(
                          'Quest: ' + Quest[lvl, npcID].strDescri, False);
                        StoreAchievement(
                          'Accepted a quest by ' + Quest[lvl, npcID].strNPCname + '.');
                        Inc(ThePlayer.longScore, 50);
                        CreateUniqueMonster(lvl);
                      end;
                    end;
                  end
                  else
                    ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
                      'You have to be ' + strDiplomaList[Quest[lvl, npcID].intNeedDipl] +
                      ' to work for me.',
                      '',
                      '',
                      '',
                      '', True);
                end
                else
                  ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
                    'Sorry, but you have the wrong profession for the job I offer.',
                    '',
                    '',
                    '',
                    '', True);
              end
              else
                ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
                  'I am busy. Perhaps we can talk later.',
                  '',
                  '',
                  '',
                  '', True);
            end
            else
              ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
                'At the moment, I have no work for you. Try again later.',
                '',
                '',
                '',
                '', True);
          end
          else
            ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
              'I think you need a higher level for the job I offer.',
              '',
              '',
              '',
              '', True);
        end
        else
          ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
            'I have no work for anybody of your religious order.',
            '',
            '',
            '',
            '', True);

        if Quest[lvl, npcID].intType <> 6 then
          exit;
      end;


      // Not the first visit; a quest is already given
      if (ThePlayer.intQuestState[lvl, npcID] = 1) or
        (ThePlayer.intQuestState[lvl, npcID] = 3) then
      begin

        // first, we check all quests which need return to the client for being solved
        //         writeln('Type: '+IntToStr(Quest[lvl,npcID].intType));

        // 1: get item quest?
        if Quest[lvl, npcID].intType = 1 then
          for i := 1 to 16 do
            if inventory[i].intType > 0 then
              if Thing[inventory[i].intType].strName =
                Quest[lvl, npcID].strGetItem then
              begin
                ThePlayer.intQuestState[lvl, npcID] := 2;
                GetKeyInput('You give the ' +
                  Thing[inventory[i].intType].strName + ' to ' +
                  Quest[lvl, npcID].strNPCname + '.', True);
                Dec(inventory[i].longNumber,
                  Thing[inventory[i].intType].intAmount);
                if inventory[i].longNumber < 1 then
                  inventory[i].intType := 0;
              end;

        // 2: Delivery quest?
        if Quest[lvl, npcID].intType = 2 then
          if ThePlayer.intQuestState[lvl, npcID] = 3 then
          begin
            ThePlayer.intQuestState[lvl, npcID] := 2;
            GetKeyInput('You return to your client and tell him about the delivery.',
              True);
          end;

        // 4: hunt quest?
        if Quest[lvl, npcID].intType = 4 then
          //         begin
          //             Writeln(IntToStr(ThePlayer.intQuestHunt[lvl,npcID])+' from '+IntToStr(Quest[lvl,npcID].intHuntAmount));
          if ThePlayer.intQuestHunt[lvl, npcID] >= Quest[lvl, npcID].intHuntAmount then
          begin
            ThePlayer.intQuestState[lvl, npcID] := 2;
            GetKeyInput('You return to ' + Quest[lvl, npcID].strNPCname +
              ' and report your success.', True);
          end;
        //         end;

        // 6: just information
        if Quest[lvl, npcID].intType = 6 then
          ThePlayer.intQuestState[lvl, npcID] := 2;

        // 5: collect itemset quest?
        if Quest[lvl, npcID].intType = 5 then
          if CheckNeededItems(Quest[lvl, npcID].strGetItem, True) = True then
          begin
            ThePlayer.intQuestState[lvl, npcID] := 2;
            GetKeyInput('You give all needed items to ' +
              Quest[lvl, npcID].strNPCname + '.', True);
          end;

        // 7: get gold quest?
        if Quest[lvl, npcID].intType = 7 then
          if ThePlayer.longGold >= Quest[lvl, npcID].intGetGold then
          begin
            ThePlayer.intQuestState[lvl, npcID] := 2;
            Dec(ThePlayer.longGold, Quest[lvl, npcID].intGetGold);
            GetKeyInput('You pay the ' + IntToStr(
              Quest[lvl, npcID].intGetGold) + ' to ' +
              Quest[lvl, npcID].strNPCname + '.', True);
          end;

        // 8: correct answer
        if Quest[lvl, npcID].intType = 8 then
        begin
          strAnswer := trim(uppercase(
            GetTextInput('Tell me the correct answer: ', 20)));
          if strAnswer = trim(uppercase(Quest[lvl, npcID].strTargetName)) then
          begin
            ThePlayer.intQuestState[lvl, npcID] := 2;
            ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
              'You are right, ' + ThePlayer.strName + '; this was the correct answer.',
              '',
              '',
              '',
              '', True);
          end
          else
            ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
              'No. This was not the correct answer.',
              '',
              '',
              '',
              '', True);
        end;


        // 9: collect resources quest?
        if Quest[lvl, npcID].intType = 9 then
        begin
          //GetKeyInput(Quest[lvl,npcID].strGetResources, true);
          if CheckNeededResources(Quest[lvl, npcID].strGetResources) then
          begin
            ThePlayer.intQuestState[lvl, npcID] := 2;
            ReduceResources(Quest[lvl, npcID].strGetResources);
            GetKeyInput('You give the resources to ' +
              Quest[lvl, npcID].strNPCname + '.', True);
          end;
        end;

        // 10: destroy hive?
        if Quest[lvl, npcID].intType = 10 then
          if intNoHivesAnymore[Quest[lvl, npcID].intTargetHive] = 1 then
          begin
            ThePlayer.intQuestState[lvl, npcID] := 2;
            GetKeyInput('You return to ' + Quest[lvl, npcID].strNPCname +
              ' and report your success.', True);
          end;


        // if the quest is solved, give reward
        if (ThePlayer.intQuestState[lvl, npcID] = 2) or
          (ThePlayer.intQuestState[lvl, npcID] = 3) then
        begin

          if Quest[lvl, npcID].strTextSolved <> '-' then
            ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
              Quest[lvl, npcID].strTextSolved,
              '',
              '',
              '',
              '', True);

          StoreAchievement('Solved ' + Quest[lvl, npcID].strNPCname +
            chr(39) + 's quest.');

          // give reward to player
          case Quest[lvl, npcID].intRewardType of
            1:  // gold
            begin
              ShowTransMessage('You gain ' + IntToStr(
                Quest[lvl, npcID].longRewardAmount) + ' Credits.', False);
              Inc(ThePlayer.longGold, Quest[lvl, npcID].longRewardAmount);
            end;
            2:  // exp
            begin
              ShowTransMessage('You gain ' + IntToStr(
                Quest[lvl, npcID].longRewardAmount) + ' EXP.', False);
              Inc(ThePlayer.longEXP, Quest[lvl, npcID].longRewardAmount);
              Inc(ThePlayer.longThisLevelEXP, Quest[lvl, npcID].longRewardAmount);
              LevelUp;
            end;
            3:  // item
            begin
              ShowTransMessage(Quest[lvl, npcID].strNPCname +
                ' drops an item.', False);
              DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
                ReturnItemByName(Quest[lvl, npcID].strRewardItem);
            end;
            4:  // plot
            begin
              ShowPlot(Quest[lvl, npcID].longRewardAmount);
            end;
            5:  // bless
            begin
              ThePlayer.blBlessed := True;
              ShowTransMessage('You feel blessed by the spirit of ' +
                ThePlayer.strReli + '.', False);
            end;
            6:  // win
            begin
              WinGame;
              blWon := true;
              //StopGraphics;
              //StopMusic;
              //FreeMusic;
              //StopSFX;
              //FreeSFX;
              //Halt;

            end;
            7:  // training
            begin
              ShowTransMessage('You can train ' +
                IntToStr(Quest[lvl, npcID].longRewardAmount) + ' skills now.', False);
              TrainSkill(Quest[lvl, npcID].longRewardAmount);
            end;
            8:  // levelup
            begin
              LevelUp;
            end;
            9:  // heal for free
            begin
              ThePlayer.intHP := ThePlayer.intMaxHP;
              ThePlayer.intPP := ThePlayer.intMaxPP;
              ShowTransMessage('You are healed completely.', False);
            end;
            10: // no reward
            begin
              ShowTransMessage(
                'You leave ' + Quest[lvl, npcID].strNPCname +
                ' without any reward.', False);
            end;
            11: // magic portal
            begin
              DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 59;
              ShowTransMessage(
                'Suddenly a magical portal appears in front of you.', False);
            end;
            12: // promotion
            begin
              ThePlayer.intDipl[Quest[lvl, npcID].longRewardAmount] := 1;
              ShowTransMessage('Congratulations, ' + ThePlayer.strName +
                '! You have been promoted to ' +
                strDiplomaList[Quest[lvl, npcID].longRewardAmount] + '.', False);
              StoreAchievement(
                'Promoted to the rank "' +
                strDiplomaList[Quest[lvl, npcID].longRewardAmount] + '".');
            end;
            13: // summon monster (in fact, this is a "fake" reward by an evil NPC
            begin
              FreeMonsterID := GetFirstFreeMonsterID;
              if FreeMonsterID > -1 then
              begin
                ShowTransMessage(Quest[lvl, npcID].strNPCname + ' summons a monster!', False);
                CreateMonster(FreeMonsterID, Quest[lvl, npcID].strRewardMonster, 0);
                Monster[FreeMonsterID].intX := ThePlayer.intX;
                Monster[FreeMonsterID].intY := ThePlayer.intY;
              end;
            end;
          end;

          // show extro plot text, if strExtroPlot is set
          if Quest[lvl, npcID].strExtroPlot <> '-' then
            ShowPlot(StrToInt(Quest[lvl, npcID].strExtroPlot));

          // show extro book or scroll, if strExtroText is set
          if Quest[lvl, npcID].strExtroBook <> '-' then
            ShowText(Quest[lvl, npcID].strExtroBook);


          // extra EXP for class 1
          if (ThePlayer.intReli = 1) and (CollectHumility > 0) then
          begin
            ShowTransMessage(ThePlayer.strReli + ' gives you ' +
              IntToStr(ThePlayer.intLvl * 2) + ' additional EXP.', False);
            Inc(ThePlayer.longEXP, ThePlayer.intLvl * 2);
            Inc(ThePlayer.longThisLevelEXP, ThePlayer.intLvl * 2);
            LevelUp;
          end;

          // score
          Inc(ThePlayer.longScore, 100);

        end
        else
          ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
            Quest[lvl, npcID].strTextProgress,
            '',
            '',
            '',
            '', True);

        exit;
      end;

      // Is this a NPC whom we already helped?
      if ThePlayer.intQuestState[lvl, npcID] = 2 then
      begin
        ShowDialog(uppercase(Quest[lvl, npcID].strNPCname),
          Quest[lvl, npcID].strTextFinalVisit,
          '',
          '',
          '',
          '', True);
        exit;
      end;
    end
    else
      GetKeyInput(Quest[lvl, npcID].strNPCname + ' trembles at the aura of death surrounding you.', True);
  end;


  // help
  procedure HelpScreenKeys;
  begin
    ClearScreenSDL;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/txtbg.jpg');
    end;

    if UseSDL = True then
      BlitImage_Title
    else
      StatusDeco;

    TransTextXY(2, 1, 'KEYS USED TO PERFORM ACTIONS');

    TransTextXY(2, 3, 'Default movement: arrow keys or NumPad (switch Numlock ON!)');
    TransTextXY(2, 4, 'Movement keys from config file (N,S,E,W,NE,NW,SE,SW): ' +
      KeyNorth + KeySouth + KeyEast + KeyWest + KeyNorthEast +
      KeyNorthWest + KeySouthEast + KeySouthWest);
    TransTextXY(2, 6, '[ENTER] or [' + KeyEnter + ']');


    TransTextXY(2, 7, '  open chest                        (in front of a treasure chest)');
    TransTextXY(2, 8, '  sacrifice money                   (in front of an altar)');
    TransTextXY(2, 9, '  enter staircase                   (in front of a staircase)');
    TransTextXY(2, 10, '  drink from well                   (in front of a well)');
    TransTextXY(2, 11, '  examine crypt                     (in front of a crypt)');

    TransTextXY(2, 12, '[' + KeyTake + '] pick up item                    [' +
      KeyInventory + '] show inventory');
    TransTextXY(2, 13, '[' + KeyChant + '] show songbook (spells)          [' +
      KeyChantLast + '] chant last spell again');
    TransTextXY(2, 14, '[' + KeyTrade + '] talk to NPC or trader           [' +
      KeyShoot + '] fire long-range weapon');
    TransTextXY(2, 15, '[' + KeyTunnel + '] dig / disarm trap               [' +
      KeyPray + '] pray to your god');
    TransTextXY(2, 16, '[' + KeyStatus + '] show status screen              [' +
      KeyQuestlog + '] show questlog');
    TransTextXY(2, 17, '[' + KeyShortRest + '] rest one turn                   [' +
      KeyRest + '] rest certain number of turns');
    TransTextXY(2, 18, '[' + KeyLook + '] identify tile                   [' +
      KeyQuit + '] show game menu; also: [ESC]');
    TransTextXY(2, 19, '[' + KeySearchSteal + '] search/steal                    [' +
      KeySetQuickKeys + '] show and reset quick keys');
    TransTextXY(2, 20, '[' + KeyCloseDoor + '] close door                      [' +
      KeyBigMap + '] show big minimap (SDL only)');
    TransTextXY(2, 21, '[' + KeyThrow + '] throw an item                   [' +
      KeyTactics + '] switch tactics');
    TransTextXY(2, 22, '[' + KeySpecial + '] use talent                      ['+ KeySpecialDiv+'] divine rage');
    TransTextXY(2, 23, '[z] explore (any key stops)        [<] [>] walk to known stairs, take them');

    GetKeyInput('Press any key to return to help menu.', False);
  end;

  procedure HelpScreenYou;
  var
    i, l: integer;
  begin
    ClearScreenSDL;

    if UseSDL = True then
    begin
      LoadImage_Title('graphics/decobg.jpg');
    end;

    if UseSDL = True then
      BlitImage_Title
    else
      StatusDeco;

    TransTextXY(2, 1, 'SOME HINTS BASED ON YOUR CURRENT STATS');

    l := 4;

    // HP
    if ThePlayer.intHP <= (ThePlayer.intMaxHP div 4) then
    begin
      TransTextXY(2, l,
        'Use a healing item (e.g. Aspirin) or chant a healing spell immediately!');
      Inc(l);
    end;
    if (ThePlayer.intHP > (ThePlayer.intMaxHP div 4)) and
      (ThePlayer.intHP <= (ThePlayer.intMaxHP div 2)) then
    begin
      TransTextXY(2, l, 'Watch your health (HP)! It is rather low!');
      Inc(l);
    end;

    // PP
    if ThePlayer.intMaxPP >= 15 then
    begin
      if ThePlayer.intPP <= (ThePlayer.intMaxPP div 4) then
      begin
        TransTextXY(2, l,
          'You should regenerate your psychic points (PP), e.g. by drinking a Cola.');
        Inc(l);
      end;
      if (ThePlayer.intPP > (ThePlayer.intMaxPP div 4)) and
        (ThePlayer.intPP <= (ThePlayer.intMaxPP div 2)) then
      begin
        TransTextXY(2, l, 'Watch your psychic points (PP). They are rather low.');
        Inc(l);
      end;
    end;

    // STR
    if ThePlayer.intStrength < 100 then
    begin
      TransTextXY(2, l,
        'Your strength is lower than normal. You should take a rest to regenerate.');
      Inc(l);
    end;

    // TP / GunTP?
    if (ThePlayer.intWeapon > 0) then
    begin
      if Thing[ThePlayer.intWeapon].intGP = 0 then
      begin
        if CollectTP < 6 then
        begin
          TransTextXY(2, l,
            'You are not suited for melee combat. Try to avoid enemies.');
          Inc(l);
        end;
      end
      else
      begin
        if CollectGunTP < 6 then
        begin
          TransTextXY(2, l,
            'If you used bows or crossbows, it would be a waste of ammo.');
          Inc(l);
        end;
      end;

      // Humility low?
      if CollectHumility<5 then
      begin
        TransTextXY(2, l, 'You Humility is very low. Divine rage wont''t be very effective.');
        Inc(l);
      end;

      // Sword wielded with low Sword-skill?
      if (Thing[ThePlayer.intWeapon].chLetter = chr(156)) and
        (ThePlayer.intSword < Thing[ThePlayer.intWeapon].intWP) then
      begin
        TransTextXY(2, l, 'Train your Sword-skill to take full advantage of your ' +
          Thing[ThePlayer.intWeapon].strName + '.');
        Inc(l);
      end;

      // Axe wielded with low Axe-skill?
      if (Thing[ThePlayer.intWeapon].chLetter = chr(159)) and
        (ThePlayer.intAxe < Thing[ThePlayer.intWeapon].intWP) then
      begin
        TransTextXY(2, l, 'Train your Axe-skill to take full advantage of your ' +
          Thing[ThePlayer.intWeapon].strName + '.');
        Inc(l);
      end;

      // Lance wielded with low Lance-skill?
      if (Thing[ThePlayer.intWeapon].chLetter = chr(164)) and
        (ThePlayer.intWhip < Thing[ThePlayer.intWeapon].intWP) then
      begin
        TransTextXY(2, l, 'Train your Lance-skill to take full advantage of your ' +
          Thing[ThePlayer.intWeapon].strName + '.');
        Inc(l);
      end;

      // Gun wielded with low Gun-skill?
      if (Thing[ThePlayer.intWeapon].intGP > 0) and
        (ThePlayer.intGun < Thing[ThePlayer.intWeapon].intGP) then
      begin
        TransTextXY(2, l, 'Train your Firearm-skill to take full advantage of your ' +
          Thing[ThePlayer.intWeapon].strName + '.');
        Inc(l);
      end;

      // weapon with effect wielded without maximized skill?
      if (Thing[ThePlayer.intWeapon].intEffect = 38) or
        (Thing[ThePlayer.intWeapon].intEffect = 39) or
        (Thing[ThePlayer.intWeapon].intEffect = 40) then
        if MaximizedWeaponSkill = False then
        begin
          TransTextXY(2, l,
            'Your weapon skill is too low to use the magical bonus of your weapon.');
          Inc(l);
        end;

    end;


    // Move-Skill
    if ThePlayer.intMove < 5 then
    begin
      TransTextXY(2, l,
        'Train your Move-skill to become better in evading enemy attacks.');
      Inc(l);
    end;


    // View-Skill
    if ThePlayer.intView < 5 then
    begin
      TransTextXY(2, l,
        'If you plan to use bows or magic, you should train your Hit skill.');
      Inc(l);
    end;


    // Trade-Skill
    if ThePlayer.intTrade < 5 then
    begin
      TransTextXY(2, l,
        'You could save lots of money if your Trade-skill was trained better.');
      Inc(l);
    end;

    // Ahna?
    if (ThePlayer.blCoffeebreak=false) and (ThePlayer.intQuestState[1, 1] = 0) then
    begin
      TransTextXY(2, l,
        'You did not talk to Ahna (DLV 1) yet. Do it to begin your quest.');
      Inc(l);
    end;

    // Book of Stars
    if PlayerHasItem('Book of Stars') > -1 then
    begin
      TransTextXY(2, l, 'Deliver the Book of Stars to Ahna to solve your quest.');
      Inc(l);
    end;

    // Useless picklock?
    if (PlayerHasItem('Picklock') > -1) and (ThePlayer.intProf <> 3) then
    begin
      TransTextXY(2, l,
        'Only thieves can use picklocks; you can''t.');
      Inc(l);
    end;

    // Addicted?
    if ThePlayer.intTotalVitari > 0 then
    begin
      TransTextXY(2, l,
        'You are addicted to Vitari--hospitals offer withdrawal treatments.');
      Inc(l);
    end;

    // Poisoned?
    if (ThePlayer.intPoison > 0) and (PlayerHasItem('Antidot') > -1) then
    begin
      TransTextXY(2, l,
        'You are poisoned. Consume the antidot which is in your inventory.');
      Inc(l);
    end;


    // skill points to distribute?
    if ThePlayer.longSkillPoints > 0 then
    begin
      TransTextXY(2, l, 'You can train some skills. Go to an academy to do that.');
      Inc(l);
    end;

    // cursed
    if ThePlayer.blCursed = True then
    begin
      TransTextXY(2, l, 'You are cursed. Be humble and pray.');
      Inc(l);
    end;

    // unknown potion in inventory?
    if PlayerHasItem('unknown potion') > -1 then
    begin
      TransTextXY(2, l,
        'To see the effects of unknown potions, identify or consume them.');
      Inc(l);
    end;

    // unknown weapons?
    if (PlayerHasItem('unknown sword') > -1) or (PlayerHasItem('unknown axe') > -1) or
      (PlayerHasItem('unknown lance') > -1) or
      (PlayerHasItem('unknown firearm') > -1) then
    begin
      TransTextXY(2, l, 'Identify the unknown weapons in your inventory.');
      Inc(l);
    end;

    // unknown armour / clothes?
    if (PlayerHasItem('unknown armour') > -1) or
      (PlayerHasItem('unknown helmet') > -1) or
      (PlayerHasItem('unknown clothes') > -1) or
      (PlayerHasItem('unknown ring') > -1) then
    begin
      TransTextXY(2, l, 'Before wearing any unknown item, you have to identify it.');
      Inc(l);
    end;

    // never prayed?
    if ThePlayer.longPrayers = 0 then
    begin
      TransTextXY(2, l, 'You never prayed to your god. ' +
        ThePlayer.strReli + ' might get angry about this.');
      Inc(l);
    end;

    // trapped in a antbee's web?
    if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 6 then
    begin
      TransTextXY(2, l, 'Antbee webs disappear after 10 to 15 turns.');
      Inc(l);
    end;

    GetKeyInput('Press any key to return to help menu.', False);
  end;



  procedure HelpScreen;
  var
    dummy: string;
    ch: char;
  begin
    ch := '-';

    repeat
      ClearScreenSDL;

      if UseSDL = True then
      begin
        LoadImage_Title('graphics/decobg.jpg');
        BlitImage_Title;
      end
      else
        StatusDeco;

      TransTextXY(2, 1, 'HELP');

      TransTextXY(4, 4, 'a   Goal of the game');
      TransTextXY(4, 5, 'b   How to contact the developer');
      TransTextXY(4, 6, 'c   Credits and "thank you"');

      TransTextXY(4, 8, 'd   Keys used to perform movement and actions in the game');
      TransTextXY(4, 9, 'e   Configuring the quickbar');

      TransTextXY(4, 11, 'f   Some notes on basic status values (HP, PP, EXP, CLV)');
      TransTextXY(4, 12, 'g   Skills and abilities');
      TransTextXY(4, 13, 'h   Talents, divine rage, and distress (DST)');
      TransTextXY(4, 14, 'i   Item values (WP, GP, AP) and their influence on battle');
      TransTextXY(4, 15, 'j   Fighting monsters in melee- and long-range battle');
      TransTextXY(4, 16, 'k   The basics of using magic (i.e. chanting spells)');
      TransTextXY(4, 17, 'l   Magic in combat situations');
      TransTextXY(4, 18, 'm   How quests work and how quests are solved');
      TransTextXY(4, 19, 'n   The resource workshop and its uses');

      TransTextXY(4, 21, 'o   Some general hints');
      TransTextXY(4, 22, 'p   A context-sensitive help page, based on your current stats');


      dummy := GetKeyInput('Press the according key to make a selection. Press [ESC] to exit.', False);
      ch := dummy[1];

      case ch of
        'a':
          OutputPlot('help_about');
        'b':
          OutputPlot('help_contact');
        'c':
          OutputPlot('help_credits');
        'd':
          HelpScreenKeys;
        'e':
          OutputPlot('help_quickbar');
        'f':
          OutputPlot('help_status');
        'g':
          OutputPlot('help_skills');
        'h':
          OutputPlot('help_talents');
        'i':
          OutputPlot('help_statusitems');
        'j':
          OutputPlot('help_fighting');
        'k':
          OutputPlot('help_basicmagic');
        'l':
          OutputPlot('help_combatmagic');
        'm':
          OutputPlot('help_quests');
        'n':
          OutputPlot('help_resources');
        'o':
          OutputPlot('help_winning');
        'p':
          HelpScreenYou;
      end;

    until dummy = 'ESC';
  end;


  // returns true if the unique monster of the given level is still alive
  function UniqueAlive(lvl: integer): boolean;
  var
    a, i: integer;
  begin
    a := 0;
    for i := 1 to MonsterTemplates do
      if (MonTe[i].intLvl = lvl) and (MonTe[i].blUnique = True) then
        a := i;

    if a > 0 then
      if ThePlayer.blUnKilled[a] = False then
        UniqueAlive := True
      else
        UniqueAlive := False;
  end;

  // show more detailed memories, depending on character's personal background
  procedure RememberSomething;
  var
    strTemp: string;
  begin

    // eventlevel: here something bad happened
    if DungeonLevel = ThePlayer.intEventLevel then
      if ThePlayer.longLevelVisits[DungeonLevel] < 2 then
      begin
        strTemp := MonTe[ReturnRandomMonster(DungeonLevel)].strName;

        // good relationship
        if ThePlayer.intRelParents = 1 then
          ShowDialog('-',
            'It was here where you and your father were attacked by a pack of ' +
            strTemp + 's.',
            'You were frightened, but you knew your father would protect you.',
            '', '', '', True);

        // bad relationship
        if ThePlayer.intRelParents = 2 then
          ShowDialog('-',
            'It was here where your father left you alone with the ' + strTemp + 's.',
            'You were scared to death, and you have never forgiven him this fault.',
            '', '', '', True);
      end;

    // the Core entered
    if DungeonLevel = 20 then
      if ThePlayer.longLevelVisits[DungeonLevel] < 2 then
        ShowDialog('ERIS',
          ThePlayer.strName +
          ' What a NICE surprise! You have found Me? You''ve taken all that',
          'suffering upon you, to come to My place? Oh, I''m SO flattered, indeed. We''ll',
          'have lots of fun, you and me, and, well, some of these minor creatures over',
          'there :-D Oh, I have been waiting SUCH a long time for you. Now COME TO ME,',
          'my humble human---to chase Me, to fight Me, and to learn to adore Me!',
          True);

  end;


  // religion's special ability
  procedure UseReligionAbility;
  var
    c, p: integer; // dvr cost of religion ability
  begin

    c:=0;
    p:=0;

    if CollectHumility>0 then
    begin

      case ThePlayer.intReli of
        1:
        begin
          // Aphrodite's Passion -> restore HP
          c := 100 - (CollectHumility*5);
          if c>100 then
            c:=100;
          if c<50 then
            c:=50;

          if ThePlayer.intLimit >= c then
          begin
            ShowTransMessage('Aphrodite''s Passion heals you.', false);
            ThePlayer.intHP := ThePlayer.intMaxHP;
            dec(ThePlayer.intLimit, c);
          end
          else
          begin
            PlaySFX('magic-fail.ogg');
            ShowTransMessage('Not enough distress for invoking divine rage!', false);
          end;
        end;

        2:
        begin
          // Hermes' Inspiration --> restore PP
          if ThePlayer.intMaxPP>0 then
          begin
            c := 100 - (CollectHumility*5);
            if c>100 then
              c:=100;
            if c<1 then
              c:=0;

            if ThePlayer.intLimit >= c then
            begin
              ShowTransMessage('Hermes'' Inspiration restores your psychic power.', false);
              ThePlayer.intPP := ThePlayer.intMaxPP;
              dec(ThePlayer.intLimit, c);
            end
            else
            begin
              PlaySFX('magic-fail.ogg');
              ShowTransMessage('Not enough distress for invoking divine rage!', false);
            end;

          end
          else
          begin
            ShowTransMessage('Hermes'' Inspiration does not impress you much.', false);
            c:=0;
          end;
        end;

        3:
        begin
          // Apoll's Arrow --> IncMove
          c := 100 - (CollectHumility*5);
           if c>100 then
            c:=100;
          if c<1 then
            c:=0;

          if ThePlayer.intLimit >= c then
          begin
            inc(ThePlayer.intTempResist[25], CollectHumility);
            if CheckEffect(49)=true then
              inc(ThePlayer.intTempResist[25], CollectHumility);

            ShowTransMessage('Apoll''s Arrow hits your heart.', false);
            dec(ThePlayer.intLimit, c);
          end
          else
          begin
            PlaySFX('magic-fail.ogg');
            ShowTransMessage('Not enough distress for invoking divine rage!', false);
          end;
        end;

        4:
        begin
          // Dionysa's Fine Wine -> increase STR without addiction
          c := 100 - (CollectHumility*5);
           if c>100 then
            c:=100;
          if c<1 then
            c:=0;

          if ThePlayer.intLimit >= c then
          begin
            ShowTransMessage('Dionysa''s Fine Wine strengthens you.', false);
            inc(ThePlayer.intStrength, CollectHumility);
            if CheckEffect(49)=true then
              inc(ThePlayer.intStrength, CollectHumility);
            if ThePlayer.intStrength>200 then
              ThePlayer.intStrength:=200;
            dec(ThePlayer.intLimit, c);
          end
          else
          begin
            PlaySFX('magic-fail.ogg');
            ShowTransMessage('Not enough distress for invoking divine rage!', false);
          end;

        end;

        5:
        begin
          // Warhammer of Ares -> deal area damage
          c := 100 - (CollectHumility*5);
           if c>100 then
            c:=100;
          if c<1 then
            c:=0;

          if ThePlayer.intLimit >= c then
          begin


            if CheckEffect(49)=true then
            begin
              AreaDamage(2*(ThePlayer.intLvl+(CollectHumility*2)));
              ShowTransMessage('The Warhammer of Ares inflicts ' + IntToStr(2*(ThePlayer.intLvl+(CollectHumility*2))) +' area damage.', false);
            end
            else
            begin
              AreaDamage(ThePlayer.intLvl+(CollectHumility*2));
              ShowTransMessage('The Warhammer of Ares inflicts ' + IntToStr(ThePlayer.intLvl+(CollectHumility*2)) +' area damage.', false);
            end;

            dec(ThePlayer.intLimit, c);
          end
          else
          begin
            PlaySFX('magic-fail.ogg');
            ShowTransMessage('Not enough distress for invoking divine rage!', false);
          end;
        end;

      end;

      //if c>0 then
      //  Writeln ('DST cost: '+IntToStr(c));

    end
    else
      ShowTransMessage('You try to invoke divine rage, but to no avail.', false);

  end;

  // profession's special ability
  procedure UseProfessionAbility;
  var
    b, c: integer; // dvr cost of profession ability
  begin

    // B    1     2     3     4     5
    // 5 -> 10 -> 15 -> 20 -> 25 -> 25   = 100
    // 5 -> 15 -> 20 -> 25 -> 35         = 100

    c:=0;

    case ThePlayer.intProf of
      2: c:=10+(ThePlayer.intDipl[6]*10) + (ThePlayer.intDipl[7]*20) + (ThePlayer.intDipl[8]*20) + (ThePlayer.intDipl[9]*30) + (ThePlayer.intDipl[10]*10);
      3: c:=5+(ThePlayer.intDipl[11]*20) + (ThePlayer.intDipl[12]*20) + (ThePlayer.intDipl[13]*20) + (ThePlayer.intDipl[14]*35);
      4: c:=10+(ThePlayer.intDipl[15]*10) + (ThePlayer.intDipl[16]*35) + (ThePlayer.intDipl[17]*15) + (ThePlayer.intDipl[18]*30);
      5: c:=5+(ThePlayer.intDipl[1]*10) + (ThePlayer.intDipl[2]*15) + (ThePlayer.intDipl[3]*20) + (ThePlayer.intDipl[4]*25) + (ThePlayer.intDipl[5]*25);
    end;

    if ThePlayer.intLimit >= c then
    begin

      //writeln('DST cost: '+IntToStr(c));
      dec(ThePlayer.intLimit, c);

      // bonus "+Talent"
      if checkeffect(66)=true then
        b:=1
      else
        b:=0;

      // enchanter specials
      if ThePlayer.intProf = 2 then
      begin

        // enchanter: clv+5 area damage
        AreaDamage(ThePlayer.intLvl+5+b);
        ShowTransMessage('The poet inflicts ' + IntToStr(ThePlayer.intLvl+5+b) + ' area damage.', false);

        // mage --> sopranist: CLV ice aura
        if ThePlayer.intDipl[6]=1 then
          if CheckEffect(49)=true then
            DoEffect(9, (b+ThePlayer.intLvl)*2, 'The Sopranist creates an ice aura')
          else
            DoEffect(9, b+ThePlayer.intLvl, 'The Sopranist creates an ice aura');

        // battlemage --> heldentenor: barrier
        if ThePlayer.intDipl[7]=1 then
          if CheckEffect(49)=true then
            DoEffect(15, (b+ThePlayer.intLvl)*2, 'The Heldentenor protects you with a barrier')
          else
            DoEffect(15, b+ThePlayer.intLvl, 'The Heldentenor protects you with a barrier');

        // believer --> psalm: 2*clv PP reg.
        if ThePlayer.intDipl[8]=1 then
        begin
          inc(ThePlayer.intPP, (b+ThePlayer.intLvl)*2);

          if CheckEffect(49)=true then
            inc(ThePlayer.intPP, (b+ThePlayer.intLvl)*2);

          if ThePlayer.intPP > ThePlayer.intMaxPP then
            ThePlayer.intPP := ThePlayer.intMaxPP;
          ShowTransMessage('You feel refreshed after reading the psalm.', false);
        end;

        // monk --> gradual: 4*clv PP reg.
        if ThePlayer.intDipl[9]=1 then
        begin
          inc(ThePlayer.intPP, (b+ThePlayer.intLvl)*4);

          if CheckEffect(49)=true then
            inc(ThePlayer.intPP, (b+ThePlayer.intLvl)*4);

          if ThePlayer.intPP > ThePlayer.intMaxPP then
            ThePlayer.intPP := ThePlayer.intMaxPP;
          ShowTransMessage('You feel relieved after chanting the gradual.', false);
        end;

        // holy warrior --> hmyn: purify area
        if ThePlayer.intDipl[10]=1 then
        begin
          if CheckEffect(49)=true then
            DoEffect(20, (b+ThePlayer.intLvl)*2, 'You purify the area')
          else
            DoEffect(20, b+ThePlayer.intLvl, 'You purify the area');
        end;
      end;



      // thief specials
      if ThePlayer.intProf=3 then
      begin

        // thief --> cold blood
        DoEffectOnMonster(CollectGunTP, 2);

        // assassin --> typhoon
        if ThePlayer.intDipl[11]=1 then
        begin
          if CheckEffect(49)=true then
            DoEffect(5, 10+b, 'You move so quietly that you seem invisible to others')
          else
            DoEffect(5, 5+b, 'You move so quietly that you seem invisible to others')
        end;

        // agent --> akula
        if ThePlayer.intDipl[12]=1 then
        begin
          if CheckEffect(49)=true then
            DoEffect(5, ThePlayer.intLvl+5+b, 'Nobody can see you')
          else
            DoEffect(5, 2*(ThePlayer.intLvl+5+b), 'Nobody can see you');
        end;

        // master thief --> (passive)

        // guild leader --> (passive)
      end;


      // archer specials
      if ThePlayer.intProf=4 then
      begin

        // archer --> shooting star
        if CheckEffect(49)=true then
          DoEffectOnMonster((b+CollectGunTP)*2, 1)
        else
          DoEffectOnMonster(b+CollectGunTP, 1);

        // hunter --> (passive)

        // ranger --> herbalism
        if ThePlayer.intDipl[16]=1 then
        begin
          if CheckEffect(49)=true then
            DoEffectOnMonster((b+CollectGunTP)*2, 45)
          else
            DoEffectOnMonster(b+CollectGunTP, 45);
        end;

        // marksman --> (passive)

        // lieutenant --> taser
        if ThePlayer.intDipl[18]=1 then
        begin
          if CheckEffect(49)=true then
            DoEffectOnMonster((b+CollectGunTP)*2, 4)
          else
            DoEffectOnMonster(b+CollectGunTP, 4);
        end;

      end;


      // soldier special
      if ThePlayer.intProf=5 then
      begin

        // soldier --> Turbulence
        if CheckEffect(49)=true then
          AreaDamage(10+b)
        else
          AreaDamage(5+b);

        if CheckEffect(49)=true then
          ShowTransMessage('The Turbulence deals '+IntToStr(10+b)+' area damage.', false)
        else
          ShowTransMessage('The Turbulence deals '+IntToStr(5+b)+' area damage.', false);

        // centurio --> (passive)

        // hastatus --> vortex
        if ThePlayer.intDipl[2]=1 then
        begin
          if CheckEffect(49)=true then
          begin
            AreaDamage(2*(ThePlayer.intLvl+5+b));
            ShowTransMessage('The Vortex deals '+IntToStr(2*(ThePlayer.intLvl+5+b))+' area damage.', false);
          end
          else
          begin
            AreaDamage(ThePlayer.intLvl+5+b);
            ShowTransMessage('The Vortex deals '+IntToStr(ThePlayer.intLvl+5+b)+' area damage.', false);
          end;
        end;

        // princeps --> (passive)

        // pilus --> maelstrom
        if ThePlayer.intDipl[4]=1 then
        begin
          if CheckEffect(49)=true then
          begin
            AreaDamage(2*(ThePlayer.intLvl+10+b));
            ShowTransMessage('The Maelstrom deals '+IntToStr(2*(ThePlayer.intLvl+10+b))+' area damage.', false);
          end
          else
          begin
            AreaDamage(ThePlayer.intLvl+10+b);
            ShowTransMessage('The Maelstrom deals '+IntToStr(ThePlayer.intLvl+10+b)+' area damage.', false);
          end;
        end;

        // primus pilus --> (passive)

      end;


    end
    else
    begin
      PlaySFX('magic-fail.ogg');
      ShowTransMessage('Not enough distress for using your professional talent!', false);
    end;
  end;

  procedure LevelFeeling;
  var
    EnterVerb, feeling, levelname: string;
  begin
    feeling := '-';
    levelname := 'another boring level';

    if DungeonLevel = 1 then
      if UniqueAlive(1) = True then
        feeling := 'The spirit of this place seems soiled.'
      else
        feeling := 'You feel safe.';

    if (DungeonLevel = 1) and (ThePlayer.blCoffeeBreak=true) then
      feeling := 'Only some traders are still here ...';

    if DungeonLevel = 3 then
      if UniqueAlive(3) = True then
        feeling := 'You hear somebody reciting poems.'
      else
        feeling := 'You see many empty bookshelves here.';

    if (DungeonLevel = 5) and (UniqueAlive(5) = True) then
      feeling := 'You hear a blacksmith' + chr(39) + 's hammer.';

    if (DungeonLevel = 9) and (UniqueAlive(9) = True) then
      feeling := 'You hear a voice of beauty and sadness.';

    if (DungeonLevel = 15) and (UniqueAlive(15) = True) then
      feeling := 'You hear a deep groaning of agony.';

    if (DungeonLevel = 27) and (UniqueAlive(27) = True) then
      feeling := 'Your hear buzzing sounds, like from electricity.';

    if DungeonLevel = 19 then
      if UniqueAlive(19) = True then
        feeling := 'You sense death.'
      else
        feeling := 'Ornaments everywhere, showing legendary battles.';

    if (DungeonLevel = 20) and (UniqueAlive(20) = True) then
      feeling := 'You hear an old woman crying blue murder.';

    if DungeonLevel = 21 then
      feeling := 'It is stormy and cold.';

    if DungeonLevel = 22 then
      feeling := 'You admire the wideness of the wilderness.';

    if DungeonLevel = 23 then
      feeling := 'You feel observed.';

    if DungeonLevel = 24 then
      feeling := 'It smells like death.';

    if DungeonLevel = 25 then
      feeling := 'You are curious.';

    if DungeonLevel = 26 then
      feeling := 'The air is dry and smells like ozone.';

    if DungeonLevel = 27 then
      feeling := 'You feel a tingling sensation on your skin.';


    if (DungeonLevel = 23) or (DungeonLevel = 24) then
      if (ThePlayer.blUnKilled[ReturnMonTeByName('Undying King')] = True) or
        (ThePlayer.blUnKilled[ReturnMonTeByName('Eris')] = True) then
        feeling := 'You feel very safe.';



    if (DungeonLevel > 2) and (ThePlayer.intLvl > DungeonLevel) then
      if feeling = '-' then
        feeling := 'You feel confident.';

    if DungeonLevel = ThePlayer.intBirthLevel then
      if feeling = '-' then
        feeling := 'You know this place -- you were born here.';

    if feeling = '-' then
      if (DungeonLevel > 2) and (ThePlayer.intLvl < DungeonLevel) then
      begin
        if DungeonLevel - ThePlayer.intLvl > 1 then
          feeling := 'You feel brave.';
        if DungeonLevel - ThePlayer.intLvl > 3 then
          feeling := 'You feel nervous.';
        if DungeonLevel - ThePlayer.intLvl > 5 then
          feeling := 'You are afraid.';
        if DungeonLevel - ThePlayer.intLvl > 10 then
          feeling := 'You are scared to death.';
      end;

    levelname := ReturnLevelName(DungeonLevel);

    if ThePlayer.longLevelVisits[DungeonLevel] < 2 then
    begin
      EnterVerb := 'Discovering';
      StoreAchievement('Discovers ' + levelname + '.');

      inc(ThePlayer.longScore, DungeonLevel);

      inc(ThePlayer.longExp, DungeonLevel);
      inc(ThePlayer.longThisLevelExp, DungeonLevel);
      LevelUp;

      // if a detailed "first visit" text exists, show it.
      if ThePlayer.blCoffeeBreak=false then
        if fileexists('data/story/books/levels/level-' + IntToStr(DungeonLevel) + '.txt') = True then
          ShowText('levels/level-' + IntToStr(DungeonLevel));

      // rememberings?
      RememberSomething;

    end
    else
      EnterVerb := 'Returning to';

    if feeling <> '-' then
      ShowTransMessage(EnterVerb + ' ' + levelname + '. ' + feeling, False)
    else
      ShowTransMessage(EnterVerb + ' ' + levelname + '. ', False);
  end;


  procedure Difficulty;
  begin
    //     writeln ('Difficulty: '+IntToStr(DiffLevel));

    // bronze
    if DiffLevel = 1 then
    begin
      CONST_MONSTERRECDIST := 4;
      CONST_MONSTERFIRERATE := 300;
      CONST_PERCENTMONSTERS := 6;
      CONST_MIN_ITEMS := 15;
      CONST_SPAWN := 490;
    end;

    // silver
    if DiffLevel = 2 then
    begin
      CONST_MONSTERRECDIST := 6;
      CONST_MONSTERFIRERATE := 250;
      CONST_PERCENTMONSTERS := 7;
      CONST_MIN_ITEMS := 12;
      CONST_SPAWN := 470;
    end;

    // gold
    if DiffLevel = 3 then
    begin
      CONST_MONSTERRECDIST := 8;
      CONST_MONSTERFIRERATE := 200;
      CONST_PERCENTMONSTERS := 9;
      CONST_MIN_ITEMS := 10;
      CONST_SPAWN := 430;
    end;
  end;


  procedure TipOfTheDay;
  var
    t: integer;
    tip: string;
  begin
    t := 1 + trunc(random(24));
    case t of
      1: tip := 'Sell old stuff frequently, to gain money for better items';
      2: tip := 'Dipping items into a well may lead to interesting results';
      3: tip := 'Try sacrificing items at altars';
      4: tip := 'Keep your rage level as high as possible to use special abilities';
      5: tip := 'Collect and sell resources at resource workshops for money';
      6: tip := 'If you are trapped in an antbee web, just wait some turns';
      7: tip := 'Think tactically. Use the dungeon layout to your advantage';
      8: tip := 'Be patient. Do not just rush -- think about your actions';
      9: tip := 'Train your skills at an academy or using a book shelf';
      10: tip := 'Dig your way through rock in caves to find rare items';
      11: tip := 'To regain psychic power, just sit down for a while';
      12: tip := 'If you feel trapped, try searching for hidden doors';
      13: tip := 'If you are chased, run away and shut the doors behind you';
      14: tip := 'If peaceful Caveworms block your way, wait some turns';
      15: tip := 'You can buy a life insurance at hospitals';
      16: tip := 'Items will be destroyed when hitting a wall';
      17: tip := 'You can throw one tile farther than you can see';
      18: tip := 'You can shoot one tile farther than you can see';
      19: tip := 'Dropping one item onto another may be interesting';
      20: tip := 'You can select offensive and defensive tactics by pressing [' +
          KeyTactics + ']';
      21: tip := 'In defense mode, suffered and inflicted damage are halved';
      22: tip := 'You can improve your special ability by obtaining diplomas';
      23: tip := 'To use weapon special effects, you need a weapon skill >= the weapon''s WP';
      24: tip := 'You can grease your current weapon to add special effects';
    end;
    ShowTransMessage('Tip: ' + tip + '.', False);
  end;




// MAIN LOOP


{$IFNDEF WEB}{$R *.res}{$ENDIF}

begin

  randomize;

  //Writeln ('Current directory: ' + GetCurrentDir);
  //SetCurrentDir('/Applications/LambdaRogue.app/Contents/MacOS');
  //Writeln ('Changed directory to: ' + GetCurrentDir);

  //Writeln ('Looking for resources in ' + CONST_DATADIR + '*');

  SetDataDirPath;

  // check for important dirs and files



  if DirectoryExists(CONST_DATADIR + 'data/levels/random') = False then
    CreateDir(CONST_DATADIR + 'data/levels/random');

  if DirectoryExists(CONST_DATADIR + 'saves') = False then
    CreateDir(CONST_DATADIR + 'saves');

  if FileExists(CONST_DATADIR + 'lambdarogue.cfg') = False then
  begin
    Writeln('Error: configuration file "lambdarogue.cfg" is missing.');
    halt;
  end;

  if FileExists(CONST_DATADIR + 'data/monsters.txt') = False then
  begin
    Writeln('Error: data file "data/monsters.txt" is missing.');
    halt;
  end;

  if FileExists(CONST_DATADIR + 'data/items.txt') = False then
  begin
    Writeln('Error: data file "data/items.txt" is missing.');
    halt;
  end;

  if FileExists(CONST_DATADIR + 'data/chants.txt') = False then
  begin
    Writeln('Error: data file "data/chants.txt" is missing.');
    halt;
  end;

  if FileExists(CONST_DATADIR + 'data/quests.txt') = False then
  begin
    Writeln('Error: data file "data/quests.txt" is missing.');
    halt;
  end;

  if FileExists(CONST_DATADIR + 'data/classes.txt') = False then
  begin
    Writeln('Error: data file "data/classes.txt" is missing.');
    halt;
  end;



  InitMusic;
  InitSFX;

  InitKeys(True);

  SaveConfig;


  InitGraphics(True);

  ThePlayer.intTileset := 1;

  blQuit := False;



  // --- MAINLOOP ---
  blHalt := false;
  repeat

    ClearPlayer;

    blWon:=false;

    // empty messagelog
    for i := 1 to 20 do
      strMessageLog[i] := '-';

    // empty quick keys
    for i := 1 to 12 do
      strQuickKey[i] := '-';

    // diplomas
    for i := 1 to 30 do
      strDiplomaList[i] := 'unassigned diploma';

    intAchieved := 0;
    for i := 1 to 500 do
      Achievements[i] := '-';

    ThePlayer.blCoffeebreak := false;


    strDiplomaList[1] := 'Centurio';
    strDiplomaList[2] := 'Hastatus';
    strDiplomaList[3] := 'Princeps';
    strDiplomaList[4] := 'Pilus';
    strDiplomaList[5] := 'Primus Pilus';
    strDiplomaList[6] := 'Mage';
    strDiplomaList[7] := 'Battlemage';
    strDiplomaList[8] := 'Believer';
    strDiplomaList[9] := 'Monk';
    strDiplomaList[10] := 'Holy Warrior';

    strDiplomaList[11] := 'Assassin';
    strDiplomaList[12] := 'Agent';
    strDiplomaList[13] := 'Master Thief';
    strDiplomaList[14] := 'Guild Leader';
    strDiplomaList[15] := 'Hunter';
    strDiplomaList[16] := 'Ranger';
    strDiplomaList[17] := 'Marksman';
    strDiplomaList[18] := 'Lieutenant';

    MonsterInit;
    BonesInit;
    ClassInit;
    ChantInit;
    ItemInit;
    WeaponVariants;
    CraftingReceipts;
    QuestInit;

    //Writeln('Itemcount: ' + IntToStr(ItemCount));

    //// save tables for debugging and balancing
    //SaveItemTables;
    //SaveMonsterTables;
    //SaveChantTables;


    // create random maps for situations in which we don't have a predef map
    for i := 1 to WinLevel do
      CreatePuzzleLandscape(i);

    LastSong := 0;

    blStartGame := False;
    PlayMusic('title.ogg');
    repeat
      TitleSelection := TitleScreen();
      ClearScreenSDL;

      if UseSDL = True then
      begin
        LoadImage_Title('graphics/plotbg.jpg');
        BlitImage_Title;
      end;

      if TitleSelection = 1 then
      begin

        ThePlayer.strName := ShowSavegames;
        if length(ThePlayer.strName) < 1 then ThePlayer.strName := ThePlayer.strName + '_';

        if ThePlayer.strName <> 'ESC' then
        begin
          if fileexists(CONST_DATADIR + 'saves/' + ThePlayer.strName + '.lambdarogue') then
          begin
            InitDungeon;
            LoadGame(ThePlayer.strName);
            Difficulty;
            // DeleteFile('saves/' + ThePlayer.strName + '.lambdarogue');
            FillDungeon(DungeonLevel);
            blStartGame := True;
          end
          else
          begin
            SelectGameMode;
            if ThePlayer.blCoffeeBreak=false then
              ShowIntro;
            CreatePlayer;
            blStartGame := True;
          end;
        end
        else
        begin
          if UseSDL = True then
          begin
            if UseHiRes = True then
              LoadImage_Title('graphics/title-1024.jpg')
            else
              LoadImage_Title('graphics/title-800.jpg');
          end;
        end;
      end;

      if TitleSelection = 2 then
      begin
        SelectGameMode;
        CreatePlayerFast;
        blStartGame := True;
      end;


      // options
      if TitleSelection = 3 then
      begin
        ThePlayer.intProf := 5;   // necessary for tile switching in options menu working correctly
        ThePlayer.intSex := 1;
        SetOptions;
        PlayMusic('title.ogg');
        if UseSDL = True then
        begin
          if UseHiRes = True then
            LoadImage_Title('graphics/title-1024.jpg')
          else
            LoadImage_Title('graphics/title-800.jpg');
        end;
      end;

      // keybindings
      if TitleSelection = 4 then
      begin
        SetKeyConfig;
        if UseSDL = True then
        begin
          if UseHiRes = True then
            LoadImage_Title('graphics/title-1024.jpg')
          else
            LoadImage_Title('graphics/title-800.jpg');
        end;
      end;

      // Quit
      if TitleSelection = 5 then
      begin
        StopMusic;
        FreeMusic;
        StopSFX;
        FreeSFX;
        StopGraphics;
        halt;
      end;
    until blStartGame = True;


    if UseSDL = True then
      LoadImage_Tiles(ThePlayer.intProf, ThePlayer.intSex);

    // set tactics to offensive (default)
    ThePlayer.blOffensive := True;


    // initialization of new characters
    if ((TitleSelection = 1) and (fileexists(CONST_DATADIR + 'saves/' + ThePlayer.strName + '.lambdarogue') = false)) or (TitleSelection = 2) then
    begin
      Difficulty;

      // Quickstart always starts in DLV 2
      if TitleSelection = 2 then
      begin

        dummy := '-';
        repeat
          dummy := GetTextInput('Enter your name: ', 12);
        until (dummy<>'ESC') and (dummy<>'-') and (fileexists(CONST_DATADIR + 'saves/' + dummy + '.lambdarogue') = false);

        ThePlayer.strName := dummy;

        if ThePlayer.blCoffeebreak=false then
          blPlayPrologue := False
        else
          blPlayPrologue := True;
      end;


      if TitleSelection = 1 then
      begin

        if ThePlayer.blCoffeebreak=false then
        begin
          dummy := '-';
          repeat
            ClearScreenSDL;
            if UseSDL = True then
              BlitImage_Title
            else
            begin
              DialogWin;
              StatusDeco;
            end;
            TransTextXY(1, 1, 'YOUR JOURNEY BEGINS.');

            TransTextXY(7, 6,
              'Ahna, the priestess of the Temple of Enoa, sends you out to find');
            TransTextXY(7, 7, 'the Book of Stars, written long ago and lost somewhere in the');
            TransTextXY(7, 8,
              'depths of the dungeons beneath the Temple. She told you to visit');
            TransTextXY(7, 9,
              'the assistant of the librarian, living in the sewers. Perhaps he');
            TransTextXY(7, 10, 'can help you ...');

            TransTextXY(7, 16,
              'Hint: You can skip the Temple of Enoa and start your journey in');
            TransTextXY(7, 17,
              'the Catacombs of Enoa. However, there are many traders and people');
            TransTextXY(7, 18,
              'living in the Temple, so you should visit it at some time. If you');
            TransTextXY(7, 19,
              'decide not to skip the temple level, do not forget to talk to Ahna');
            TransTextXY(7, 20, 'before going down to the Catacombs.');

            dummy := GetKeyInput('Do you want to skip the temple level and go directly to the dungeon [y/n]?',
              False);
          until (dummy = 'y') or (dummy = 'Y') or (dummy = 'n') or (dummy = 'N');
          if (dummy = 'y') or (dummy = 'Y') then
            blPlayPrologue := False
          else
            blPlayPrologue := True;
        end
        else
          blPlayPrologue := True;
      end;


      if blPlayPrologue = True then
      begin // start at the Temple of Enoa
        DungeonLevel := 1;
        CreateDungeon(DungeonLevel);

        if ThePlayer.blCoffeeBreak=false then
        begin
          PlaySFX('page-turn.ogg');
          ShowText('chapter-0');
          ShowPlot(1);
        end;
        PlacePlayer(-1, 0);
      end
      else
      begin // start at the Catacombs of Enoa
        DungeonLevel := 2;
        CreateDungeon(DungeonLevel);
        PlaySFX('page-turn.ogg');
        ShowText('chapter-1');
        ThePlayer.longLevelVisits[2] := 1;
        PlacePlayer(2, 1); // place player on plain floor
        ThePlayer.intQuestState[1, 1] := 1; // activate Ahna's quest
      end;

      NextTurn();

      if blPlayPrologue = False then
        ShowTransMessage('The library assistant in the sewers might help you find the Book of Stars.', False);
    end;

    if UseSDL = False then
    begin
      intCenterX := 80 div 2;
      intCenterY := 25 div 2;
    end
    else
    begin
      if UseSmallTiles = True then
      begin
        if UseHiRes = False then
        begin
          intCenterX := 40 div 2;
          intCenterY := 12 div 2;
        end
        else
        begin
          intCenterX := 51 div 2;
          intCenterY := (19 div 2) - 1;
        end;
      end
      else
      begin
        if UseHiRes = False then
        begin
          intCenterX := 20 div 2;
          intCenterY := 6 div 2;
        end
        else
        begin
          intCenterX := 25 div 2;
          intCenterY := (9 div 2) - 1;
        end;
      end;
    end;


    // --- INIT ACTUAL GAME

    ThePlayer.intBX := intCenterX;
    ThePlayer.intBY := intCenterY;

    ClearScreenSDL;

    PlayMusic(IntToStr(trunc(random(8) + 1)) + '.ogg');

    if ThePlayer.longLevelVisits[1] = 0 then
      ThePlayer.longLevelVisits[1] := 1;

    blTodayStolenTrader := False;
    blTodayStolenNPC := False;

    for i := 1 to 8 do
      blShopStolen[i] := False;

    if ThePlayer.blEvil = False then
    begin
      if ThePlayer.strReli = 'Ares' then
        ShowTransMessage(ThePlayer.strReli + ' salutes you, ' +
          ThePlayer.strName + '!', False);
      if ThePlayer.strReli = 'Aphrodite' then
        ShowTransMessage(ThePlayer.strReli + ' sends her love to you, ' +
          ThePlayer.strName + '!', False);
      if ThePlayer.strReli = 'Dionysa' then
        ShowTransMessage(ThePlayer.strReli + ' raises her glass, ' +
          ThePlayer.strName + '!', False);
      if ThePlayer.strReli = 'Hermes' then
        ShowTransMessage(ThePlayer.strReli + ' greets you, ' +
          ThePlayer.strName + '!', False);
      if ThePlayer.strReli = 'Apoll' then
        ShowTransMessage(ThePlayer.strReli + ' welcomes you, ' +
          ThePlayer.strName + '!', False);
      TipOfTheDay;
    end
    else
      ShowTransMessage('Nobody welcomes you, ' + ThePlayer.strName + '!', False);

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);

    // set mouse hover flags to false
    blInsideBar := False;
    blInsideStatus := False;

    blWon:=false;

    // --- BEGIN GAME LOOP ---
    repeat
      chKey := ' ';
      KeyRepeatSoll := 1;
      KeyRepeatIst := 0;

      repeat
        //             Writeln(IntToStr(ThePlayer.intX)+'/'+IntToStr(ThePlayer.intY));

        k := 0;
        FunKey := '-';
        KX := 0;
        KY := 0;

        if ThePlayer.blEvil = True then
        begin
          DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType := 2;
          DngLvl[ThePlayer.intX, ThePlayer.intY].intAirRange := 6;
        end;

        // wait for pressed key (KEYLOOP)
        k := RvipAuto;  // RVIP: next step of an explore / stair walk, 0 = read a key
        if k = 0 then
        if UseSDL = True then
        begin

          if SDL_POLLEVENT(@MyEvent) > 0 then
          begin
            KX := MyEvent.motion.x;
            KY := MyEvent.motion.y;


            // Mouse Clicks
            Knoepfe := SDL_GetMouseState(KX, KY);

            // Mouse Overs
            if Knoepfe = 0 then
              MouseOvers(KX, KY);


            if (Knoepfe and SDL_BUTTON(SDL_BUTTON_LEFT)) <> 0 then
            begin
              if UseHiRes = True then
              begin
                if (KX >= 1001) and (KY >= 81) and (KX <= 1013) and (KY <= 95) then
                  k := Ord(KeyBigMap);  // big minimap in 1024x768
              end
              else
              begin
                if (KX >= 783) and (KY >= 81) and (KX <= 795) and (KY <= 95) then
                  k := Ord(KeyBigMap);  // big minimap in 800x600
              end;

              if (KX >= 0) and (KX <= 208) and (KY >= 0) and (KY <= 96) and
                (blInsideBar = False) then
                k := Ord(KeyStatus); // status windows

              if QuickBarID > -1 then
                FunKey := 'F' + IntToStr(QuickBarID);

            end;

            if (Knoepfe and SDL_BUTTON(SDL_BUTTON_RIGHT)) <> 0 then
            begin
              ChantBarX := KX - 42;
              ChantBarY := KY;
              ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
              ShowStatus;
            end;

            if (k = 0) and (MyEvent.type_ = SDL_KEYDOWN) then
              k := cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
          end;
        end
        else
          k := ConsoleInput();

        case k of
          SDLK_ESCAPE:
            k := Ord(KeyQuit);
          13:
            k := Ord(KeyEnter);
          SDLK_UP:
            k := Ord(KeyNorth);
          SDLK_KP8:
            k := Ord(KeyNorth);
          SDLK_DOWN:
            k := Ord(KeySouth);
          SDLK_KP2:
            k := Ord(KeySouth);
          SDLK_LEFT:
            k := Ord(KeyWest);
          SDLK_KP4:
            k := Ord(KeyWest);
          SDLK_RIGHT:
            k := Ord(KeyEast);
          SDLK_KP6:
            k := Ord(KeyEast);
          SDLK_KP9:
            k := Ord(KeyNorthEast);
          SDLK_KP7:
            k := Ord(KeyNorthWest);
          SDLK_KP3:
            k := Ord(KeySouthEast);
          SDLK_KP1:
            k := Ord(KeySouthWest);
          Ord('1'):
            k := Ord(KeySouthWest);
          Ord('2'):
            k := Ord(KeySouth);
          Ord('3'):
            k := Ord(KeySouthEast);
          Ord('4'):
            k := Ord(KeyWest);
          Ord('6'):
            k := Ord(KeyEast);
          Ord('7'):
            k := Ord(KeyNorthWest);
          Ord('8'):
            k := Ord(KeyNorth);
          Ord('9'):
            k := Ord(KeyNorthEast);
          SDLK_F1:
            FunKey := 'F1';
          SDLK_F2:
            FunKey := 'F2';
          SDLK_F3:
            FunKey := 'F3';
          SDLK_F4:
            FunKey := 'F4';
          SDLK_F5:
            FunKey := 'F5';
          SDLK_F6:
            FunKey := 'F6';
          SDLK_F7:
            FunKey := 'F7';
          SDLK_F8:
            FunKey := 'F8';
          SDLK_F9:
            FunKey := 'F9';
          SDLK_F10:
            FunKey := 'F10';
          SDLK_F11:
            FunKey := 'F11';
          SDLK_F12:
            FunKey := 'F12';
        end;
        delay(10);
      until ((k > 31) and (k < 127)) or (FunKey <> '-');
      web_at_cmd := false;

      // RVIP: auto-explore and stair walking
      if (k = Ord('z')) or (k = Ord('<')) or (k = Ord('>')) then
      begin
        RvipStart(chr(k));
        k := RvipAuto;
        web_at_cmd := false;
      end;

      //         writeln(chr(k));

      // evaluate pressed key (except the F1 - F12 keys)
      if k = Ord(KeyNorth) then
        chKey := KeyNorth
      else
      if k = Ord(KeySouth) then
        chKey := KeySouth
      else
      if k = Ord(KeyEast) then
        chKey := KeyEast
      else
      if k = Ord(KeyWest) then
        chKey := KeyWest
      else
      if k = Ord(KeyNorthEast) then
        chKey := KeyNorthEast
      else
      if k = Ord(KeyNorthWest) then
        chKey := KeyNorthWest
      else
      if k = Ord(KeySouthEast) then
        chKey := KeySouthEast
      else
      if k = Ord(KeySouthWest) then
        chKey := KeySouthWest;

      if k = Ord(KeyQuit) then
        chKey := KeyQuit;


      // cheat
      //if k = Ord('B') then
        //chKey := 'B';

      if k = Ord(KeyTunnel) then
        chKey := KeyTunnel
      else
      if k = Ord(KeySetQuickKeys) then
        chKey := KeySetQuickKeys
      else
      if k = Ord(KeyEnter) then
        chKey := KeyEnter
      else
      if k = Ord(KeyInventory) then
        chKey := KeyInventory
      else
      if k = Ord(KeyTake) then
        chKey := KeyTake
      else
      if k = Ord(KeyHelp) then
        chKey := KeyHelp
      else
      if k = Ord(KeyCloseDoor) then
        chKey := KeyCloseDoor
      else
      if k = Ord(KeyQuestlog) then
        chKey := KeyQuestlog;

      if k = Ord(KeyPray) then
        chKey := KeyPray
      else
      if k = Ord(KeyLook) then
        chKey := KeyLook
      else
      if k = Ord(KeyStatus) then
        chKey := KeyStatus
      else
      if k = Ord(KeyTrade) then
        chKey := KeyTrade
      else
      if k = Ord(KeyShoot) then
        chKey := KeyShoot
      else
      if k = Ord(KeyThrow) then
        chKey := KeyThrow
      else
      if k = Ord(KeyTactics) then
        chKey := KeyTactics
      else
      if k = Ord(KeyChant) then
        chKey := KeyChant
      else
      if k = Ord(KeySpecial) then
        chKey := KeySpecial
      else
      if k = Ord(KeySpecialDiv) then
        chKey := KeySpecialDiv;

      if k = Ord(KeyRest) then
        chKey := KeyRest
      else
      if k = Ord(KeyShortRest) then
        chKey := KeyShortRest
      else
      if k = Ord(KeyChantLast) then
        chKey := KeyChantLast
      else
      if k = Ord(KeySearchSteal) then
        chKey := KeySearchSteal
      else
      if k = Ord(KeyBigMap) then
        chKey := KeyBigMap;


      // confusion?
      if ThePlayer.intConfusion > 0 then
        if chKey = KeyNorth then
          chKey := KeySouth
        else
        if chKey = KeySouth then
          chKey := KeyNorth
        else
        if chKey = KeyEast then
          chKey := KeyWest
        else
        if chKey = KeyWest then
          chKey := KeyEast
        else
        if chKey = KeyNorthEast then
          chKey := KeySouthWest
        else
        if chKey = KeyNorthWest then
          chKey := KeySouthEast
        else
        if chKey = KeySouthEast then
          chKey := KeyNorthWest
        else
        if chKey = KeySouthWest then
          chKey := KeyNorthEast;


      // cheat
      //if chKey = 'B' then
        //CheatCodes;


      // function keys
      if FunKey = 'F1' then
        QuickKeys(1);
      if FunKey = 'F2' then
        QuickKeys(2);
      if FunKey = 'F3' then
        QuickKeys(3);
      if FunKey = 'F4' then
        QuickKeys(4);
      if FunKey = 'F5' then
        QuickKeys(5);
      if FunKey = 'F6' then
        QuickKeys(6);
      if FunKey = 'F7' then
        QuickKeys(7);
      if FunKey = 'F8' then
        QuickKeys(8);
      if FunKey = 'F9' then
        QuickKeys(9);
      if FunKey = 'F10' then
        QuickKeys(10);
      if FunKey = 'F11' then
        QuickKeys(11);
      if FunKey = 'F12' then
        QuickKeys(12);


      if chKey = KeyTake then
      begin
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem > 0 then
          TakeItem(ThePlayer.intX, ThePlayer.intY)
        else
        begin
          // small mushrooms
          if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 54 then
          begin
            DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 12;
            DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
              ReturnItemByName('Small mushroom');
            ShowTransMessage('You harvest a small mushroom.', False);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            if UseSDL = True then
              SDL_UPDATERECT(screen, 0, 0, 0, 0)
            else
              UpdateScreen(True);
          end;

          // big mushrooms
          if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 53 then
          begin
            DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 12;
            DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
              ReturnItemByName('Big mushroom');
            ShowTransMessage('You harvest a big mushroom.', False);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            if UseSDL = True then
              SDL_UPDATERECT(screen, 0, 0, 0, 0)
            else
              UpdateScreen(True);
          end;

          // wooden garbage
          if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 55 then
          begin
            DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 2;
            Inc(Storage.longWood, 4 + trunc(random(6)));
            ShowTransMessage('You put some wooden garbage in your resource storage.',
              False);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            if UseSDL = True then
              SDL_UPDATERECT(screen, 0, 0, 0, 0)
            else
              UpdateScreen(True);
          end;

          // old machine parts
          if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 58 then
          begin
            DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 2;
            Inc(Storage.longMetal, 6 + trunc(random(9)));
            ShowTransMessage(
              'You transfer metal from the floor to your resource storage.', False);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            if UseSDL = True then
              SDL_UPDATERECT(screen, 0, 0, 0, 0)
            else
              UpdateScreen(True);
          end;
        end;
        blQuit := NextTurn();
      end;

      if chKey = KeyHelp then
      begin
        HelpScreen;
        blQuit := NextTurn();
      end;

      if chKey = KeyBigMap then
      begin
        if UseSDL = True then
        begin
          BigMap;
          blQuit := NextTurn();
        end;
      end;

      if chKey = KeySetQuickKeys then
      begin
        SetQuickKeys;
        blQuit := NextTurn();
      end;

      if chKey = KeySpecial then
      begin
        UseProfessionAbility;
        blQuit := NextTurn();
      end;

      if chKey = KeySpecialDiv then
      begin
        UseReligionAbility;
        blQuit := NextTurn();
      end;

      if chKey = KeyStatus then
      begin
        TidyPlayerStatus;
        blQuit := NextTurn();
      end;

      if chKey = KeyQuestlog then
      begin
        ShowStatusQuestlog;
        blQuit := NextTurn();
      end;


      // movement keys
      vx := 0;
      vy := 0;
      if (chKey = KeyNorth) and (ThePlayer.intY > 1) then
      begin
        vx := 0;
        vy := -1;
      end;
      if (chKey = KeySouth) and (ThePlayer.intY < DngMaxHeight) then
      begin
        vx := 0;
        vy := 1;
      end;
      if (chKey = KeyEast) and (ThePlayer.intX < DngMaxWidth) then
      begin
        vx := 1;
        vy := 0;
      end;
      if (chKey = KeyWest) and (ThePlayer.intX > 1) then
      begin
        vx := -1;
        vy := 0;
      end;
      if (chKey = KeyNorthEast) and (ThePlayer.intY > 1) and
        (ThePlayer.intX < DngMaxWidth) then
      begin
        vx := 1;
        vy := -1;
      end;
      if (chKey = KeyNorthWest) and (ThePlayer.intY > 1) and (ThePlayer.intX > 1) then
      begin
        vx := -1;
        vy := -1;
      end;
      if (chKey = KeySouthEast) and (ThePlayer.intY < DngMaxHeight) and
        (ThePlayer.intX < DngMaxWidth) then
      begin
        vx := 1;
        vy := 1;
      end;
      if (chKey = KeySouthWest) and (ThePlayer.intY < DngMaxHeight) and
        (ThePlayer.intX > 1) then
      begin
        vx := -1;
        vy := 1;
      end;

      // move
      if (ThePlayer.intPara = 0) and
        (DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType <> 6) then
      begin
        if (chKey = KeyNorth) or (chKey = KeySouth) or (chKey = KeyEast) or
          (chKey = KeyWest) or (chKey = KeyNorthEast) or (chKey = KeySouthEast) or
          (chKey = KeyNorthWest) or (chKey = KeySouthWest) then
        begin
          repeat
            // check for and open door
            Door := OpenDoor(chKey);
            case Door of
              1: if (DungeonLevel = 26) or (DungeonLevel = 27) then
                begin
                  PlaySFX('force-off.ogg');
                  ShowTransMessage('You deactivate a force field.', False);
                end
                else
                begin
                  PlaySFX('door-open.ogg');
                  ShowTransMessage('You open a door.', False);
                end;
              2: ShowTransMessage('You unlock a door.', False);
              3: ShowTransMessage('You fail to open a door; it' + chr(
                  39) + 's locked.', False);
              4: ShowTransMessage('You unlock a gate.', False);
              5: ShowTransMessage('You fail to open a gate; it' + chr(
                  39) + 's locked.', False);
            end;
            if Door > -1 then
            begin
              ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
              if UseSDL = True then
                SDL_UPDATERECT(screen, 0, 0, 0, 0)
              else
                UpdateScreen(True);
            end;
            // if free tile, move into that direction
            if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity = 0 then
            begin
              if FightMonster(ThePlayer.intX + vx, ThePlayer.intY + vy) then
              begin
                if ThePlayer.intPara = 0 then
                begin
                  Inc(ThePlayer.intX, vx);
                  Inc(ThePlayer.intY, vy);
                  blQuit := NextTurn();
                end;
              end
              else
                blQuit := NextTurn();
            end;

            // kick barrel
            if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 52 then
            begin
              ShowTransMessage('You kick the barrel. [Integrity: ' +
                IntToStr(DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity) +
                ']', False);
              if ThePlayer.intWeapon > 0 then
                Dec(DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                  vy].intIntegrity, Thing[ThePlayer.intWeapon].intWP)
              else
                Dec(DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                  vy].intIntegrity, 1);
              if DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                vy].intIntegrity < 1 then
              begin
                DngLvl[ThePlayer.intX + vx,
                  ThePlayer.intY + vy].intFloorType := 55;
                BarrelDestroyed(ThePlayer.intX + vx, ThePlayer.intY + vy);
              end;
              blQuit := NextTurn();
            end;

            // kick gas cylinder
            if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 56 then
            begin
              ShowTransMessage(
                'You kick the gas cylinder. [Integrity: ' + IntToStr(
                DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity) +
                ']', False);
              if ThePlayer.intWeapon > 0 then
                Dec(DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                  vy].intIntegrity, Thing[ThePlayer.intWeapon].intWP)
              else
                Dec(DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                  vy].intIntegrity, 1);
              if DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                vy].intIntegrity < 1 then
              begin
                DngLvl[ThePlayer.intX + vx,
                  ThePlayer.intY + vy].intFloorType := 55;
                CylinderDestroyed(ThePlayer.intX + vx, ThePlayer.intY + vy);

                if ThePlayer.blOffensive = True then
                  ThePlayer.intHP := ThePlayer.intHP div 2;
              end;
              blQuit := NextTurn();
            end;

            // attack monster's hive
            if DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType = 34 then
            begin
              KeyRepeatIst := KeyRepeatSoll;
              ShowTransMessage('You attack the monster' + chr(39) +
                's hive. [Integrity: ' + IntToStr(
                DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intIntegrity) +
                ']', False);
              if ThePlayer.intWeapon > 0 then
                Dec(DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                  vy].intIntegrity, Thing[ThePlayer.intWeapon].intWP)
              else
                Dec(DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                  vy].intIntegrity, 1);
              if DngLvl[ThePlayer.intX + vx, ThePlayer.intY +
                vy].intIntegrity < 1 then
              begin
                DngLvl[ThePlayer.intX + vx, ThePlayer.intY + vy].intFloorType := 2;
                HiveDestroyed;
              end;
              blQuit := NextTurn();
            end;

            Inc(KeyRepeatIst);

          until (KeyRepeatIst >= KeyRepeatSoll) or (blQuit = True);
        end;
      end
      else
      begin
        //ShowMessage('You can'+chr(39)+'t move.', false);
        blQuit := NextTurn();
      end;

      if chKey = KeyQuit then
      begin
        if GameMenu = True then
          blQuit := True;
      end;

      if chKey = KeyTunnel then
      begin
        Dig;
        blQuit := NextTurn();
      end;

      if chKey = KeyRest then
      begin
        Rest;
        if ThePlayer.intHP < 1 then
          blQuit := true;
      end;

      if chKey = KeyShortRest then
      begin
        NextTurn();
        if ThePlayer.intHP < 1 then
          blQuit := true;
      end;

      if chKey = KeyShoot then
      begin
        Shoot;
        blQuit := NextTurn();
      end;

      if chKey = KeyThrow then
      begin
        Throw;
        blQuit := NextTurn();
      end;

      if chKey = KeyTactics then
      begin
        ThePlayer.blOffensive := BoolToggle(ThePlayer.blOffensive);
        if ThePlayer.blOffensive = True then
          ShowTransMessage('Switched to offensive tactics.', False)
        else
          ShowTransMessage('Switched to defensive tactics.', False);
        blQuit := NextTurn();
      end;

      if chKey = KeyChant then
      begin
        ShowSpellbook;
        blQuit := NextTurn();
      end;

      if chKey = KeyChantLast then
      begin
        ChantLastSong;
        blQuit := NextTurn();
      end;

      if chKey = KeyLook then
      begin
        IdentifyTile;
        blQuit := NextTurn();
      end;

      if chKey = KeyPray then
      begin
        Pray;
        blQuit := NextTurn();
      end;

      if chKey = KeyEnter then
      begin
        // treasure chest
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 7 then
          LootChest
        else
        // next level
        if (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 9) then
        begin
          Inc(DungeonLevel);

          if fileexists('data/levels/' + IntToStr(DungeonLevel) + '.txt') = False then
            CreatePuzzleLandscape(DungeonLevel);

          // show chapter screen: Chapter 1 -- The Search
          if DungeonLevel = 2 then
            if ThePlayer.longLevelVisits[2] < 1 then
            begin
              if ThePlayer.blCoffeebreak=false then
              begin
                PlaySFX('page-turn.ogg');
                ShowText('chapter-1');
              end;
            end;

          // show chapter screen: Interlude -- The Forgotten Realm
          if DungeonLevel = 23 then
            if ThePlayer.longLevelVisits[23] < 1 then
              if (ThePlayer.blUnKilled[ReturnMonTeByName('Undying King')] =
                False) and (ThePlayer.blUnKilled[ReturnMonTeByName('Eris')] = False) then
              begin
                PlaySFX('page-turn.ogg');
                ShowText('interlude-c');
                ShowPlot(28);
              end;

          if DungeonLevel = 24 then
            if ThePlayer.intQuestState[1,3]=2 then
              ShowPlot(37);

          if DungeonLevel = 16 then
            if ThePlayer.intQuestState[24,1]=2 then
              ShowPlot(38);

          // show 2nd forgotten realm plot
          if DungeonLevel = 25 then
            if ThePlayer.longLevelVisits[25] < 1 then
              if (ThePlayer.blUnKilled[ReturnMonTeByName('Undying King')] =
                False) and (ThePlayer.blUnKilled[ReturnMonTeByName('Eris')] = False) then
                ShowPlot(29);

          // show screens for space ship
          if DungeonLevel = 26 then
            if ThePlayer.LongLevelVisits[26] < 1 then
              ShowPlot(34);

          if DungeonLevel = 27 then
            if ThePlayer.LongLevelVisits[27] < 1 then
              ShowPlot(36);


          PlaySFX('steps.ogg');

          //if DungeonLevel <= WinLevel then
          //begin
          CreateDungeon(DungeonLevel);
          PlacePlayer(8, DungeonLevel - 1);
          Inc(ThePlayer.longLevelVisits[DungeonLevel]);

          // corpse of Lassa Kana found (for Northdoom Quest)
          if DungeonLevel = 13 then
            if ThePlayer.intQuestState[5, 4] = 1 then
              if ThePlayer.blStory[16] = False then
              begin
                ShowPlot(16);
                DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ReturnItemByName('Crystal of "Revenge"');
              end;

          NextTurn;
          LevelFeeling;
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
          //end;
        end
        else
        // prev. level
        if (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 8) and (DungeonLevel > 1) then
        begin
          if fileexists('data/levels/' + IntToStr(DungeonLevel) + '.txt') =
            False then
            CreatePuzzleLandscape(DungeonLevel);

          Dec(DungeonLevel);

          if DungeonLevel=1 then
          begin
            // show morning star conspiracy plot
            if (ThePlayer.intQuestState[16,5]=2) and (ThePlayer.blUnKilled[ReturnMonTeByName('Astaroth')] = true) then
              ShowPlot(43); // Apostle HAS Northdoom, and Astaroth is dead
          end;


          PlaySFX('steps.ogg');
          CreateDungeon(DungeonLevel);
          PlacePlayer(9, DungeonLevel + 1);
          Inc(ThePlayer.longLevelVisits[DungeonLevel]);
          NextTurn;
          LevelFeeling;
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        end
        else
        // ladder in lvl 24 to spaceship (lvl 26)
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 67 then
        begin
          if PlayerHasItem('Fuel Cube') > 0 then
          begin
            ShowTransMessage('You switch off the force field protecting the ladder.', False);
            PlaySFX('steps.ogg');
            DungeonLevel := 26;
            if fileexists('data/levels/' + IntToStr(DungeonLevel) + '.txt') = False then
              CreatePuzzleLandscape(DungeonLevel);
            CreateDungeon(DungeonLevel);
            PlacePlayer(66, DungeonLevel + 1);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
            if ThePlayer.longLevelVisits[26] < 1 then
              ShowPlot(34);
            Inc(ThePlayer.longLevelVisits[DungeonLevel]);
            NextTurn;
            LevelFeeling;
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
          end
          else
          begin
            ShowTransMessage('Some strange force field is preventing you from going down.', False);
            ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
          end;
        end
        else
        // stairs in lvl 26 to forgotten realm (lvl 24)
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 66 then
        begin
          PlaySFX('steps.ogg');
          DungeonLevel := 24;
          CreateDungeon(DungeonLevel);
          PlacePlayer(67, DungeonLevel + 1);
          Inc(ThePlayer.longLevelVisits[DungeonLevel]);
          NextTurn;
          LevelFeeling;
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        end
        else
        // stairs in lvl 2 to wilderness (lvl 22)
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 62 then
        begin
          PlaySFX('steps.ogg');
          DungeonLevel := 22;
          if fileexists('data/levels/' + IntToStr(DungeonLevel) + '.txt') =
            False then
            CreatePuzzleLandscape(DungeonLevel);
          CreateDungeon(DungeonLevel);
          PlacePlayer(-1, DungeonLevel + 1);
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
          if ThePlayer.longLevelVisits[22] < 1 then
            ShowPlot(31);
          Inc(ThePlayer.longLevelVisits[DungeonLevel]);
          NextTurn;
          LevelFeeling;
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        end
        else
        // stairs in wilderness (lvl 22) to lvl 2
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 63 then
        begin
          PlaySFX('steps.ogg');
          DungeonLevel := 2;
          CreateDungeon(DungeonLevel);
          PlacePlayer(62, DungeonLevel + 1);
          // 2nd parameter is "from level", we make placeplayer believe we come from 3
          Inc(ThePlayer.longLevelVisits[DungeonLevel]);
          NextTurn;
          LevelFeeling;
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        end
        else
        // portal through time to Noldarur
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 59 then
        begin
          PlaySFX('swoosh.ogg');
          if DungeonLevel = 1 then
          begin
            DungeonLevel := 21;
            if fileexists('data/levels/' + IntToStr(DungeonLevel) +
              '.txt') = False then
              CreatePuzzleLandscape(DungeonLevel);
            CreateDungeon(DungeonLevel);
            PlacePlayer(-1, DungeonLevel + 1);
          end
          else
          begin
            DungeonLevel := 1;
            CreateDungeon(DungeonLevel);
            PlacePlayer(1, 0);
          end;

          Inc(ThePlayer.longLevelVisits[DungeonLevel]);
          NextTurn;
          LevelFeeling;
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        end
        else
        // drink from well
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 28 then
        begin
          DrinkFromWell;
          blQuit := NextTurn();
        end
        else
        // activate force field
        if ((DungeonLevel = 26) or (DungeonLevel = 27)) and (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 4) then
        begin
          PlaySFX('force-on.ogg');
          BlendMagic(22);
          DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 3;

          if CheckEffect(55) = False then
          begin
            ShowTransMessage('You activate the force field -- it hurts!', False);
            ThePlayer.intHP := ThePlayer.intHP div 2;
            if ThePlayer.intHP < 1 then
              ThePlayer.intHP := 1;
            if CheckEffect(26) = False then
              Inc(ThePlayer.intPara, 4);

            if (CheckEffect(28) = False) and (ThePlayer.blBlessed = False) then
              Inc(ThePlayer.intCalm, 4);
          end
          else
            ShowTransMessage('You activate the force field.', False);

          blQuit := NextTurn();
        end
        else
        // deactivate force field
        if ((DungeonLevel = 26) or (DungeonLevel = 27)) and (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 3) then
        begin
          PlaySFX('force-off.ogg');
          DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 4;
          ShowTransMessage('You deactivate the force field.', False);
          blQuit := NextTurn();
        end
        else
        // sacrifice
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 15 then
        begin
          Sacrifice;
          blQuit := NextTurn();
        end
        else
        // examine crypt
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 26 then
        begin
          ExamineCrypt;
          blQuit := NextTurn();
        end;

      end;

      // search for hidden door; steal money or items (thief only)
      if chKey = KeySearchSteal then
      begin
        SearchAndSteal;
        blQuit := NextTurn();
      end;

      if chKey = KeyTrade then
      begin
        // trader
        if (DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding > 0) and
          (DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding < 5) then
        begin
          if blShopStolen[DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding] =
            False then
            ShowShop(DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding)
          else
            ShowTransMessage(
              'Due to your criminal record, you are temporarly banned from this trader.',
              False);
          blQuit := NextTurn();
        end
        else
        // hospital
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding = 5 then
        begin
          Hospital;
          blQuit := NextTurn();
        end
        else
        // restaurant
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding = 6 then
        begin
          Restaurant;
          blQuit := NextTurn();
        end
        else
        // academy
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding = 7 then
        begin
          Academy;
          blQuit := NextTurn();
        end
        else
        // resource workshop
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding = 8 then
        begin
          ResourceWorkshop;
          blQuit := NextTurn();
        end
        else
        // NPC
        if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding < 0 then
        begin
          TalkNPC(DungeonLevel,
            abs(DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding));
          blQuit := NextTurn();
        end;
      end;

      if chKey = KeyCloseDoor then
      begin
        CloseDoor;
        blQuit := NextTurn();
      end;

      if chKey = KeyInventory then
      begin
        ShowInventory;
        blQuit := NextTurn();
      end;

      // trapdoor?

      if (chKey = KeyNorth) or (chKey = KeySouth) or (chKey = KeyEast) or
        (chKey = KeyWest) or (chKey = KeyNorthEast) or (chKey = KeyNorthWest) or
        (chKey = KeySouthEast) or (chKey = KeySouthWest) then
      begin
        if ((DungeonLevel = 4) or (DungeonLevel = 9) or (DungeonLevel = 14)) and
          (random(9999) > CONST_BEATTHISFORTRAPDOOR) then
        begin
          if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 2 then
          begin
            if (ThePlayer.intProf <> 3) and (CheckEffect(41) = False) then
            begin
              GetKeyInput('Suddenly a hole opens in the floor and you fall down ...',
                True);
              if fileexists('data/levels/' + IntToStr(DungeonLevel) +
                '.txt') = False then
                CreatePuzzleLandscape(DungeonLevel);
              Inc(DungeonLevel);
              CreateDungeon(DungeonLevel);
              PlacePlayer(-1, 0);
              Inc(ThePlayer.longLevelVisits[DungeonLevel]);
              NextTurn;
              ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
              LevelFeeling;
            end
            else
              ShowTransMessage('You avoid a trapdoor.', False);
          end;
        end;
      end;


      // earthquake

      if (chKey = KeyNorth) or (chKey = KeySouth) or (chKey = KeyEast) or
        (chKey = KeyWest) or (chKey = KeyNorthEast) or (chKey = KeyNorthWest) or
        (chKey = KeySouthEast) or (chKey = KeySouthWest) then
      begin
        if (DungeonLevel > 7) and (DungeonLevel < 12) and
          (random(9999) > CONST_BEATTHISFORQUAKE) then
        begin
          ShowTransMessage('An earthquake! The whole cave is trembling!', False);
          PlaySFX('quake.ogg');
          TrembleScreen;
          EarthQuake;
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

          if ThePlayer.intHP < 1 then
            GameOver('You have been killed by the earthquake.');
        end;
      end;

      if IsPlayerDead = True then
        blQuit := True;

      if MusicPlaying = False then
        PlayMusic(IntToStr(trunc(random(8) + 1)) + '.ogg');

      if UseSDL = False then
        UpdateScreen(True);

      // win in coffeebreak mode?
      if ThePlayer.blCoffeeBreak=true then
        if ThePlayer.longKilled[ReturnMonTeByName('Eris')]>0 then
        begin
          WinGame;
          blWon:=true;
        end;


      if blWon=true then
        blQuit:=true;


    until blQuit = True;

    // --- END OF GAME LOOP ---

    if ThePlayer.intHP > 0 then
      SaveGame(ThePlayer.strName, DungeonLevel);

    if UseSDL = True then
    begin
      if UseHiRes = True then
        LoadImage_Title('graphics/title-1024.jpg')
      else
        LoadImage_Title('graphics/title-800.jpg');
    end;

  until blHalt = true;


  StopGraphics;
  StopMusic;
  FreeMusic;
  StopSFX;
  FreeSFX;

end.