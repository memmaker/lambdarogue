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

unit UserInterface;

interface

uses
  WebBE, SysUtils, Constants, RandomArea, Player, BaseOutput, MessageLog, Items, Quests, Chants;

procedure TopFrame;
procedure BottomBar;
procedure DialogWin;
procedure StatusDeco;
procedure ShowStatus;
procedure DrawEffectIcon(n: integer; x: integer; y: integer; m: integer);


implementation


// topbar
procedure TopFrame;
var
  i: integer;
begin
  // top bar
  for i := 0 to 2 do
    TextXY(0, i, chr(211) +
      '                                                                            ' +
      chr(212));

  TextXY(0, 0, chr(205) +
    '                                                                            ' +
    chr(206));
  TextXY(0, 2, chr(207) +
    '                                                                            ' +
    chr(208));

  for i := 1 to 76 do
  begin
    TextXY(i, 0, chr(209));
    TextXY(i, 2, chr(210));
  end;
end;


// bottom bar (mostly for input boxes)
procedure BottomBar;
var
  i: integer;
begin
  if UseSDL = True then
  begin
    for i := 26 to 29 do
      TextXY(0, i, chr(211) +
        '                                                                            ' +
        chr(212));

    TextXY(0, 26, chr(205) +
      '                                                                            ' +
      chr(206));

    for i := 1 to 76 do
      TextXY(i, 26, chr(209));
  end
  else
    for i := 22 to 25 do
      TextXY(0, i,
        '                                                                                ');
end;

// dialog frame decoration
procedure DialogWin;
var
  i: integer;
begin
  if UseSDL = True then
  begin
    for i := 4 to 21 do
      TextXY(4, i, chr(211) +
        '                                                                    ' +
        chr(212));

    TextXY(4, 4, chr(205) +
      '                                                                    ' + chr(206));
    TextXY(4, 21, chr(207) +
      '                                                                    ' + chr(208));

    for i := 5 to 72 do
    begin
      TextXY(i, 4, chr(209));
      TextXY(i, 21, chr(210));
    end;
  end
  else
  begin
    ClearScreenSDL;
    for i := 4 to 21 do
      TextXY(4, i,
        '|                                                                    |');
    TextXY(4, 4,
      '+--------------------------------------------------------------------+');
    TextXY(4, 21,
      '+--------------------------------------------------------------------+');
  end;
end;


// statusbar decoration
procedure StatusDeco;
begin
  if UseSDL = True then
  begin
    TopFrame;
    BottomBar;
  end;
end;


// shows the minimap of the dungeon
procedure MiniMap;
var
  i, j, k: integer;
begin

  // as the first level is static and always known, the minimap is useless (and ugly)
  //if (DungeonLevel=1) or (DungeonLevel=22) then
  //  exit;

  // player marker
  PlayerPos.x := 300;
  PlayerPos.y := 232;
  PlayerPos.w := 5;
  PlayerPos.h := 5;

  // NPC marker
  NPCPos.x := 310;
  NPCPos.y := 232;
  NPCPos.w := 5;
  NPCPos.h := 5;

  // stairs marker
  StairPos.x := 320;
  StairPos.y := 232;
  StairPos.w := 5;
  StairPos.h := 5;

  // trader marker
  TraderPos.x := 330;
  TraderPos.y := 232;
  TraderPos.w := 5;
  TraderPos.h := 5;

  // background of map
  PaperPos.x := 370;
  PaperPos.y := 158;
  PaperPos.w := 118;
  PaperPos.h := 89;

  PlotRect.x := 693 + (HiResOffsetX * 2);
  PlotRect.y := 7;
  PlotRect.h := 89;
  PlotRect.w := 118;

  SDL_BLITSURFACE(extratiles, @PaperPos, screen, @PlotRect);

  PlotRect.x := 715 + (HiResOffsetX * 2);   // 670
  PlotRect.y := 11;
  PlotRect.w := 1;
  PlotRect.h := 1;

  // if not in Temple or Outskirts, show also dungeon structure
  if (DungeonLevel <> 1) and (DungeonLevel <> 22) and (DungeonLevel <> 25) then
    for i := 1 to DngMaxWidth - 1 do
    begin
      Inc(PlotRect.x);
      PlotRect.y := 25;    // 12
      for j := 19 to DngMaxHeight - 1 do
      begin
        Inc(PlotRect.y);
        if DngLvl[i, j].blKnown = True then
        begin
          if DngLvl[i, j].intIntegrity > 0 then
            SDL_BLITSURFACE(extratiles, @PixelWhiteRect, screen, @PlotRect);
          if (DngLvl[i, j].intFloorType = 2) or
            (DngLvl[i, j].intFloorType = 60) or (DngLvl[i, j].intFloorType = 61) then
            SDL_BLITSURFACE(extratiles, @PixelGreyRect, screen, @PlotRect);
          if (DngLvl[i, j].intFloorType = 10) or
            (DngLvl[i, j].intFloorType = 13) or (DngLvl[i, j].intFloorType = 17) or
            (DngLvl[i, j].intFloorType = 18) then
            SDL_BLITSURFACE(extratiles, @PixelGreenRect, screen, @PlotRect);
          if (DngLvl[i, j].intFloorType = 12) or
            (DngLvl[i, j].intFloorType = 21) or (DngLvl[i, j].intFloorType = 22) or
            (DngLvl[i, j].intFloorType = 23) then
            SDL_BLITSURFACE(extratiles, @PixelBrownRect, screen, @PlotRect);
          if DngLvl[i, j].intFloorType = 5 then
            SDL_BLITSURFACE(extratiles, @PixelBlueRect, screen, @PlotRect);
          if DngLvl[i, j].intFloorType = 20 then
            SDL_BLITSURFACE(extratiles, @PixelRedRect, screen, @PlotRect);
          if DngLvl[i, j].intFloorType = 31 then
            SDL_BLITSURFACE(extratiles, @PixelOrangeRect, screen, @PlotRect);
        end;
      end;
    end;

  // NPCs, stairs etc.
  PlotRect.x := 715 + (HiResOffsetX * 2);
  PlotRect.y := 25;
  PlotRect.w := 1;
  PlotRect.h := 1;
  for i := 1 to DngMaxWidth - 1 do
  begin
    Inc(PlotRect.x);
    PlotRect.y := 24;
    for j := 19 to DngMaxHeight - 1 do
    begin
      Inc(PlotRect.y);

      // Discovered NPCs
      for k := 1 to 9 do
        if (i = NPC[k].intX) and (j = NPC[k].intY) then
        begin
          PlayerRect.x := PlotRect.x;
          PlayerRect.y := PlotRect.y;
          Dec(PlayerRect.x, 2);
          Dec(PlayerRect.y, 2);
          SDL_BLITSURFACE(extratiles, @NPCPos, screen, @PlayerRect);
        end;

      // Trader
      if DngLvl[i, j].intBuilding > 0 then
      begin
        PlayerRect.x := PlotRect.x;
        PlayerRect.y := PlotRect.y;
        Dec(PlayerRect.x, 2);
        Dec(PlayerRect.y, 2);
        SDL_BLITSURFACE(extratiles, @TraderPos, screen, @PlayerRect);
      end;

      // Staircases up
      if (DngLvl[i, j].intFloorType = 8) or (DngLvl[i, j].intFloorType = 62) or
        (DngLvl[i, j].intFloorType = 63) or (DngLvl[i, j].intFloorType = 66) then
      begin
        PlayerRect.x := PlotRect.x;
        PlayerRect.y := PlotRect.y;
        Dec(PlayerRect.x, 2);
        Dec(PlayerRect.y, 2);
        SDL_BLITSURFACE(extratiles, @StairPos, screen, @PlayerRect);
      end;

      // Staircases down
      if ((DngLvl[i, j].intFloorType = 9) or (DngLvl[i,j].intFloorType = 67) ) and
        ((ThePlayer.longLevelVisits[DungeonLevel + 1] > 0) or
        (DngLvl[i, j].blKnown = True)) then
      begin
        PlayerRect.x := PlotRect.x;
        PlayerRect.y := PlotRect.y;
        Dec(PlayerRect.x, 2);
        Dec(PlayerRect.y, 2);
        SDL_BLITSURFACE(extratiles, @StairPos, screen, @PlayerRect);
      end;

    end;
  end;

  // Player
  PlotRect.x := 715 + (HiResOffsetX * 2);
  PlotRect.y := 25;
  PlotRect.w := 1;
  PlotRect.h := 1;
  for i := 1 to DngMaxWidth - 1 do
  begin
    Inc(PlotRect.x);
    PlotRect.y := 24;
    for j := 19 to DngMaxHeight - 1 do
    begin
      Inc(PlotRect.y);

      // Player
      if (i = ThePlayer.intX) and (j = ThePlayer.intY) then
      begin
        PlayerRect.x := PlotRect.x;
        PlayerRect.y := PlotRect.y;
        Dec(PlayerRect.x, 2);
        Dec(PlayerRect.y, 2);
        SDL_BLITSURFACE(extratiles, @PlayerPos, screen, @PlayerRect);
      end;

    end;
  end;
end;


// zeichnet einzelnes aktives Effekticon
procedure DrawEffectIcon(n: integer; x: integer; y: integer; m: integer);
var
  IconRect, IconRectS: SDL_RECT;
begin

  if m=1 then
    IconRect.y := 415
  else
    IconRect.y := 454 ;

  IconRect.w := 38;
  IconRect.h := 38;
  IconRect.x := 38 * (n - 1);

  IconRectS.x := x + HiResOffsetX;
  IconRectS.y := y + HiResOffsetY;
  IconRectS.w := 38;
  IconRectS.h := 38;

  SDL_BLITSURFACE(extratiles, @IconRect, screen, @IconRectS);

  // Rahmen um Icon

  if m=1 then
    IconRect.x := 160
  else
    IconRect.x := 200;
  IconRect.y := 329;
  IconRect.w := 40;
  IconRect.h := 40;

  IconRectS.x := (x + HiResOffsetX)-1;
  IconRectS.y := (y + HiResOffsetY)-1;
  IconRectS.w := 40;
  IconRectS.h := 40;

  SDL_BLITSURFACE(extratiles, @IconRect, screen, @IconRectS);

end;

// shows quick access info in SDL mode, for chants
procedure ShowChantBar;
var
  i, j, intIconID, invID, id: integer;
  IconRect, IconRectS, ItemRect, BarRect, BarRectS: SDL_RECT;
  blIsSpell: boolean;
  ToNextLevel: longint;
  percent: real;
begin

  // Icons
  IconRect.y := 415;
  IconRect.w := 38;
  IconRect.h := 38;

  ItemRect.x  := 0;
  IconRectS.y := ChantBarY + 2;
  IconRectS.w := 38;
  IconRectS.h := 38;


  // NEU; zeigt QuickKey defines an
  for i := 1 to 12 do
  begin
    blIsSpell := False;
    id := -1;

    if strQuickKey[i] <> '-' then
    begin
      // okay, wir haben einen definierten Quickkey. Wir muessen nun rauskriegen, welcher Effekttyp dahinter steckt, denn
      // der Effekttyp ist die Icon-Nummer in extratiles

      // ist es spell oder item?
      for j := 1 to ChantCount do
        if Spell[j].strName = strQuickKey[i] then
        begin
          id := j;
          blIsSpell := True;
        end;

      if blIsSpell = False then
        for j := 1 to ItemCount do
          if Thing[j].strRealName = strQuickKey[i] then
            id := j;

      if id > -1 then
      begin
        // entsprechend des Werts von blIsSpell wird nun intIconID belegt
        if blIsSpell = True then
          intIconID := Spell[id].intEffect
        else
          intIconID := Thing[id].intEffect;

        // jetzt wissen wir, welches Icon gezeichnet werden soll, das koennen wir nun also tun
        IconRect.x := 38 * (intIconID - 1);
        // Icon ist hier die Icon-Nummer (von links nach rechts) in extratiles; das -1 muessen wir mal pruefen

        // wir muessen nun die Variante des Icons (farbig oder grau/dunkel waehlen, je nachdem, ob item/spell vorhanden/refreshed ist oder nicht
        // dazu brauchen wir die Nummer im Inventory bzw. im Spellbook (invID)
        invID := -1;
        if blIsSpell = True then
        begin
          for j := 1 to 12 do
            if SpellBook[j].intType = id then
              invID := j;
        end
        else
        begin
          for j := 1 to 16 do
            if Inventory[j].intType = id then
              invID := j;
        end;


        // Variante des Icons waehlen
        if blIsSpell = True then
        begin
          if Spellbook[invID].intRefresh < Spell[id].intRefresh then
            IconRect.y := 454     // grau und dunkel
          else
            IconRect.y := 415;    // farbig und bereit zum Einsatz
        end
        else
        begin
          if invID = -1 then
            IconRect.y := 454
          else
            IconRect.y := 415;
        end;

        // nun koennen wir das Icon endlich darstellen
        IconRectS.x := ChantBarX+3 + (40 * i);          // 42*i
        SDL_BLITSURFACE(extratiles, @IconRect, screen, @IconRectS);

        // wenn es sich nicht um einen Spell handelt, muss nun ein Potion- oder Food-Icon dargestellt werden
        if blIsSpell = False then
        begin
          if Thing[id].blDrink = True then
          begin
            ItemRect.y := 0;
            ItemRect.w := 6;
            ItemRect.h := 10;
            Inc(IconRectS.x, 4);
            SDL_BLITSURFACE(extratiles, @ItemRect, screen, @IconRectS);
          end
          else
          if Thing[id].blEat = True then
          begin
            ItemRect.y := 60;
            ItemRect.w := 9;
            ItemRect.h := 10;
            Inc(IconRectS.x, 3);
            SDL_BLITSURFACE(extratiles, @ItemRect, screen, @IconRectS);
          end;
        end;
      end;
    end;
  end;


  // okay. nun muessen wir noch die Rahmen um die Symbole zeichnen
  IconRect.y := 372;
  IconRect.w := 41;
  IconRect.h := 43;

  IconRectS.y := ChantBarY-1;
  IconRectS.w := 41;
  IconRectS.h := 43;

  for i := 1 to 12 do
  begin
    IconRect.x  := 40 * (i - 1);
    IconRectS.x := ChantBarX + (42 * i);
    //SDL_BLITSURFACE(extratiles, @IconRect, screen, @IconRectS);
  end;

  // großer Rahmen
  IconRect.x := 540;
  IconRect.y := 293;
  IconRect.h := 61;
  IconRect.w := 592;

  IconRectS.x := ChantBarX - 13;
  IconRectS.y := ChantBarY;
  IconRectS.w := 592;
  IconRectS.h := 61;

  SDL_BLITSURFACE(extratiles, @IconRect, screen, @IconRectS);


  // Erfahrungspunkte-Balken

  BarRectS.y := ChantBarY+41;
  BarRectS.w := 1;
  BarRectS.h := 4;
  BarRect.w := 1;
  BarRect.h := 4;
  BarRect.y  := 272;
  BarRect.x  := 301;

  for i := 0 to 418 do
  begin
    BarRectS.x := ChantBarX + 74 + i;
    SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
  end;

  BarRect.x := 300;


  // die nötigen EXP für nächstes Level sind 100%
  ToNextLevel := ((ThePlayer.intLvl * CONST_LVL_MULTI) * (ThePlayer.intLvl * CONST_LVL_MULTI) * ThePlayer.intLvl);  // dieser Wert muss erreicht werden

  if ThePlayer.intLvl>1 then
    ToNextLevel := ToNextLevel - (ThePlayer.longEXP - ThePlayer.longThisLevelEXP);


  // von den tatsächlich nötigen EXP sind soviel % erreicht
  percent   := (ThePlayer.longThisLevelEXP * 100) div ToNextLevel;



  // Prozent auf den 418 Pixel breiten Balken abbilden

  // 418     x
  // ---   = --
  // 100%    1%

  for i := 0 to trunc(percent*4.18) do
  begin
    BarRectS.x := ChantBarX + 74 + i;
    SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
  end;



  if longTotalTurns < 4 then
    SmallTextXY(1, 12, 'Press [' + KeyHelp + '] for help. Press [ESC] or [' + KeyQuit + '] for game menu.', False, False);

  if longTotalTurns < 7 then
    SmallTextXY(1, 12, 'Press [' + KeyHelp + '] for help. Press [ESC] or [' +
      KeyQuit + '] for game menu.', True, False);

end;


// shows status bars in SDL mode
procedure ShowBars;
var
  i, percent: integer;
  DecoPos, DecoPosS, PaperPos, PaperPosS, BarRect, BarRectS: SDL_RECT;
begin

  // player portrait
  PaperPos.w := 89;
  PaperPos.h := 89;
  PaperPos.y := 158;

  // deco next to player portrait
  DecoPos.x := 760;  // 764;
  DecoPos.y := 99;  // 0
  DecoPos.w := 172;  // 161
  DecoPos.h := 48;   // 29;

  DecoPosS.x := 44;
  DecoPosS.y := 8;
  DecoPosS.w := 172; // 161;
  DecoPosS.h := 48;  // 29;

  if ThePlayer.intSex = 1 then  // male
  begin
    case ThePlayer.intProf of
      2: PaperPos.x := 678;
      3: PaperPos.x := 1100;
      4: PaperPos.x := 779;
      5: PaperPos.x := 580;
    end;
  end
  else
  begin                        // female
    case ThePlayer.intProf of
      2: PaperPos.x := 1325;
      3: PaperPos.x := 883;
      4: PaperPos.x := 992;
      5: PaperPos.x := 1210;
    end;
  end;

  BarRect.h  := 5;
  BarRect.w  := 1;
  BarRectS.h := 5;
  BarRectS.w := 1;

  PaperPosS.x := 10;
  PaperPosS.y := 6;
  PaperPosS.w := 89;
  PaperPosS.h := 89;


  // health bar
  BarRectS.y := 10;
  BarRect.y  := 250;
  BarRect.x  := 301;
  for i := 0 to 100 do
  begin
    BarRectS.x := 80 + 20 + i;
    SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
  end;

  BarRect.x := 300;
  percent   := (ThePlayer.intHP * 100) div ThePlayer.intMaxHP;
  for i := 0 to percent do
  begin
    BarRectS.x := 80 + 20 + i;
    SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
  end;

  // distress bar above healthbar
  if ThePlayer.intLimit > 0 then
  begin
    BarRect.y  := 249;
    BarRect.h  := 1;
    BarRectS.w := 1;
    BarRectS.h := 1;
    for i := 0 to ThePlayer.intLimit do
    begin
      BarRectS.x := 80 + 20 + i;
      SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
    end;

    BarRectS.h := 5;
    BarRectS.w := 1;
    BarRect.h  := 5;
  end;

  // psychic bar
  BarRectS.y := 20;
  BarRect.y  := 257;
  BarRect.x  := 301;
  for i := 0 to 100 do
  begin
    BarRectS.x := 80 + 20 + i;
    SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
  end;

  if ThePlayer.intMaxPP > 0 then
  begin
    BarRect.x := 300;
    percent   := (ThePlayer.intPP * 100) div ThePlayer.intMaxPP;
    for i := 0 to percent do
    begin
      BarRectS.x := 80 + 20 + i;
      SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
    end;
  end;

  // str bar
  BarRectS.y := 30;
  BarRect.y  := 264;
  BarRect.x  := 301;
  for i := 0 to 100 do
  begin
    BarRectS.x := 80 + 20 + i;
    SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
  end;

  BarRect.x := 300;
  percent   := ThePlayer.intStrength;
  if percent > 100 then
    percent := 100;
  for i := 0 to percent do
  begin
    BarRectS.x := 80 + 20 + i;
    SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
  end;

  if ThePlayer.intStrength > 100 then
  begin
    percent   := ThePlayer.intStrength - 100;
    BarRect.x := 302;
    for i := 0 to percent do
    begin
      BarRectS.x := 80 + 20 + i;
      SDL_BLITSURFACE(extratiles, @BarRect, screen, @BarRectS);
    end;
  end;

  SDL_BLITSURFACE(extratiles, @PaperPos, screen, @PaperPosS);
  SDL_BLITSURFACE(extratiles, @DecoPos, screen, @DecoPosS);


  // Player level and mode

  if UseHiRes = False then
  begin
    //TransTextXY(0, 4, IntToStr(ThePlayer.intLvl));
    if ThePlayer.blOffensive = False then
      TransTextXY(0, 4, chr(246));
  end
  else
  begin
    if Netbook = False then
    begin
      //TransTextXY(1 + HiResTextOffsetX, 0, IntToStr(ThePlayer.intLvl));
      if ThePlayer.blOffensive = False then
        TransTextXY(1 + HiResTextOffsetX, 0, chr(246));
    end
    else
    begin
      //TransTextXY(1 + HiResTextOffsetX, 4, IntToStr(ThePlayer.intLvl));
      if ThePlayer.blOffensive = False then
        TransTextXY(1 + HiResTextOffsetX, 4, chr(246));
    end;
  end;

  ShowChantBar;

end;



// This procedure shows the status of the player
procedure ShowStatus;
var
  i: integer;
  msg1: string;
  StatRect, StatRectS: SDL_RECT;
begin
  if UseSDL = False then
  begin
    BottomBar;
    TextXY(0, 1,
      '                                                                                ');
    TextXY(0, 2,
      '--------------------------------------------------------------------------------');
    TextXY(0, 21,
      '--------------------------------------------------------------------------------');
    TextXY(0, 22,
      '                                                                                ');
    TextXY(0, 23,
      '                                                                                ');
    TextXY(0, 24,
      '                                                                                ');
    TextXY(0, 25,
      '                                                                                ');
    TextXY(1, 1, 'HP ' + IntToStr(ThePlayer.intHP) + '/' +
      IntToStr(ThePlayer.intMaxHP) + '  ');
    TextXY(13, 1, 'PP ' + IntToStr(ThePlayer.intPP) + '/' +
      IntToStr(ThePlayer.intMaxPP) + '  ');
    TextXY(26, 1, 'STR ' + IntToStr(ThePlayer.intStrength) + '%');
    TextXY(39, 1, 'DST ' + IntToStr(ThePlayer.intLimit) + '%');

    if ThePlayer.blOffensive = True then
      TextXY(49, 1, 'offensive')
    else
      TextXY(49, 1, 'defensive');

    if (ThePlayer.longFood > 60) and (ThePlayer.longFood < 200) then
      TextXY(1, 3, 'Hungry');
    if (ThePlayer.longFood > 20) and (ThePlayer.longFood < 61) then
      TextXY(1, 3, 'Fainting');
    if (ThePlayer.longFood > 0) and (ThePlayer.longFood < 21) then
      TextXY(1, 3, 'Starving');


    // Effects
    i := 3;
    if ThePlayer.intPoison > 0 then
    begin
      GlobalConColor := red;
      TextXY(1, i, 'Poisoned');
      Inc(i);
    end;

    if ThePlayer.intConfusion > 0 then
    begin
      GlobalConColor := red;
      TextXY(1, i, 'Confused');
      Inc(i);
    end;

    if ThePlayer.intPara > 0 then
    begin
      GlobalConColor := red;
      TextXY(1, i, 'Paralized');
      Inc(i);
    end;

    if (ThePlayer.intCalm > 0) or
      (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 11) then
    begin
      GlobalConColor := red;
      TextXY(1, i, 'Calm');
      Inc(i);
    end;

    if ThePlayer.blCursed = True then
    begin
      GlobalConColor := red;
      TextXY(1, i, 'Cursed');
      Inc(i);
    end;

    if (ThePlayer.intTotalVitari > 0) and (ThePlayer.intNeedVitari >=
      ThePlayer.intNextVitari) then
    begin
      GlobalConColor := red;
      TextXY(1, i, 'Craving');
      Inc(i);
    end;

    if ThePlayer.blBlessed = True then
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Blessed');
      Inc(i);
    end;

    if ThePlayer.intBlind > 0 then
    begin
      GlobalConColor := red;
      TextXY(1, i, 'Blind');
      Inc(i);
    end;

    if ThePlayer.intWall > 0 then
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Barrier');
      Inc(i);
    end;

    if ThePlayer.intInvis > 0 then
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Invisible');
      Inc(i);
    end;

    if CheckEffect(37) = True then   // maximize magic
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Magic');
      Inc(i);
    end;

    if CheckEffect(64) = True then   // maximize fight
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Fight');
      Inc(i);
    end;

    if CheckEffect(62) = True then   // maximize hit
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Hit');
      Inc(i);
    end;

    if CheckEffect(65) = True then   // maximize humility
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Humility');
      Inc(i);
    end;

    if CheckEffect(66) = True then   // maximize talent
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Talent');
      Inc(i);
    end;

    if CheckEffect(49) = True then   // distress bonus
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Distress');
      Inc(i);
    end;

    if CheckEffect(7) = True then   // extra gold
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Credits');
      Inc(i);
    end;

    if CheckEffect(6) = True then   // extra EXP
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. EXP');
      Inc(i);
    end;


    if (CheckEffect(54) = True) or (DungeonLevel = ThePlayer.intBirthLevel) then // familiar terrain
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Fam. Terrain');
      Inc(i);
    end;

    if CheckEffect(25) = true then // max move
    begin
      GlobalConColor := green;
      TextXY(1, i, 'Max. Move');
      Inc(i);
    end;

    // now the resistances

    i := 3;

    if CheckEffect(10) = True then   // resist poison
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, 'Res. Poison');
      Inc(i);
    end;

    if CheckEffect(55) = True then   // resist electricity
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, 'Res. Elect.');
      Inc(i);
    end;

    if CheckEffect(13) = True then   // resist fire
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, '  Res. Fire');
      Inc(i);
    end;

    if CheckEffect(14) = True then   // resist ice
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, '   Res. Ice');
      Inc(i);
    end;

    if CheckEffect(17) = True then   // resist blindness
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, ' Res. Blind');
      Inc(i);
    end;

    if CheckEffect(26) = True then   // resist paralization
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, 'Res. Paral.');
      Inc(i);
    end;

    if CheckEffect(28) = True then   // resist calm
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, '  Res. Calm');
      Inc(i);
    end;

    if CheckEffect(31) = True then   // resist curses
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, ' Res. Curse');
      Inc(i);
    end;

    if CheckEffect(35) = True then   // resist water
    begin
      GlobalConColor := lightcyan;
      TextXY(68, i, ' Res. Water');
      Inc(i);
    end;

    if CheckEffect(51) = True then   // resist DrainPP
    begin
      GlobalConColor := lightcyan;
      TextXY(66, i, 'Res. PP Drain');
      Inc(i);
    end;

    if CheckEffect(52) = True then   // resist DrainSTR
    begin
      GlobalConColor := lightcyan;
      TextXY(65, i, 'Res. STR Drain');
      Inc(i);
    end;

    if CheckEffect(57) = True then  // reduced PP cost
    begin
      GlobalConColor := lightcyan;
      TextXY(66, i, 'Red. PP Costs');
      Inc(i);
    end;

    GlobalConColor := -1;
  end;

  // status icons in SDL mode
  if UseSDL = True then
  begin
    StatRect.y := 250;
    StatRect.w := 20;
    StatRect.h := 20;

    StatRectS.x := 100;
    StatRectS.y := 57;
    StatRectS.w := 20;
    StatRectS.h := 20;

    if (ThePlayer.longFood > 60) and (ThePlayer.longFood < 200) then
    begin
      StatRect.x := 412;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if (ThePlayer.longFood > 20) and (ThePlayer.longFood < 61) then
    begin
      StatRect.x := 433;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if (ThePlayer.longFood > 0) and (ThePlayer.longFood < 21) then
    begin
      StatRect.x := 454;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.intPoison > 0 then
    begin
      StatRect.x := 370;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.intConfusion > 0 then
    begin
      StatRect.x := 580;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.intPara > 0 then
    begin
      StatRect.x := 601;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if (ThePlayer.intCalm > 0) or
      (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 11) then
    begin
      StatRect.x := 475;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.blCursed = True then
    begin
      StatRect.x := 538;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if (ThePlayer.intTotalVitari > 0) and (ThePlayer.intNeedVitari >=
      ThePlayer.intNextVitari) then
    begin
      StatRect.x := 517;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.blBlessed = True then
    begin
      StatRect.x := 559;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.intBlind > 0 then
    begin
      StatRect.x := 496;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.intWall > 0 then
    begin
      StatRect.x := 391;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if ThePlayer.intInvis > 0 then
    begin
      StatRect.x := 1000;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    // und nun auch hier die ganzen resistances

    if CheckEffect(7) = True then   // extra gold
    begin
      StatRect.x := 811;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(6) = True then   // extra EXP
    begin
      StatRect.x := 1021;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(10) = True then   // resist poison
    begin
      StatRect.x := 622;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(55) = True then   // resist electricity
    begin
      StatRect.x := 937;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(11) = True then   // resist confusion
    begin
      StatRect.x := 896;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(13) = True then   // resist fire
    begin
      StatRect.x := 643;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(14) = True then   // resist ice
    begin
      StatRect.x := 664;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(17) = True then   // resist blindness
    begin
      StatRect.x := 685;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(25) = True then   // maximize move
    begin
      StatRect.x := 979;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(64) = True then   // maximize fight
    begin
      StatRect.x := 1042;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(62) = True then   // maximize hit
    begin
      StatRect.x := 1063;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(65) = True then   // maximize humility
    begin
      StatRect.x := 1084;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(66) = True then   // maximize talent
    begin
      StatRect.x := 1105;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(26) = True then   // resist paralization
    begin
      StatRect.x := 832;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(28) = True then   // resist calm
    begin
      StatRect.x := 769;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(31) = True then   // resist curses
    begin
      StatRect.x := 727;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(35) = True then   // resist water
    begin
      StatRect.x := 706;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(37) = True then   // maximize magic
    begin
      StatRect.x := 790;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(49) = True then   // distress bonus
    begin
      StatRect.x := 748;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(51) = True then   // resist PP drain
    begin
      StatRect.x := 854;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(52) = True then   // resist STR drain
    begin
      StatRect.x := 875;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if (CheckEffect(54) = True) or (DungeonLevel = ThePlayer.intBirthLevel) then  // familiar terrain
    begin
      StatRect.x := 916;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

    if CheckEffect(57) = True then   // reduced PP costs
    begin
      StatRect.x := 958;
      SDL_BLITSURFACE(extratiles, @StatRect, screen, @StatRectS);
      Inc(StatRectS.x, 22);
    end;

  end;

  case DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType of
    1:
      msg1 := 'on a wall';
    2:
      msg1 := 'on plain floor';
    3:
      begin
        if (DungeonLevel = 26) or (DungeonLevel = 27) then
          msg1 := 'in an active force field. Deactivate with [ENTER] or [' + KeyEnter + ']'
        else
          msg1 := 'a closed door';
      end;
    4:
      begin
        if (DungeonLevel = 26) or (DungeonLevel = 27) then
          msg1 := 'in front of an inactive force field generator. Activate with [ENTER] or [' + KeyEnter + ']'
        else
          msg1 := 'standing in an open door';
      end;
    5:
      msg1 := 'swimming in water';
    6:
      msg1 := 'on top of a mountain';
    7:
      msg1 := 'in front of a closed treasure chest. Loot with [ENTER] or [' +
        KeyEnter + ']';
    8:
      msg1 := 'in front of a staircase. Go up with [ENTER] or [' + KeyEnter + ']';
    9:
      msg1 := 'in front of a staircase. Go down with [ENTER] or [' + KeyEnter + ']';
    10:
      msg1 := 'in front of a small tree';
    11:
      msg1 := 'stumping through worm excrements';
    12:
      msg1 := 'on sand';
    13:
      msg1 := 'in front of a big tree';
    14:
      msg1 := 'in front of an open treasure chest';
    15:
      msg1 := 'in front of an altar. Sacrifice money with [ENTER] or [' + KeyEnter + ']';
    16:
      msg1 := 'on plain floor';
    17:
      msg1 := 'going through high grass';
    18:
      msg1 := 'on top of a hill';
    19:
      msg1 := 'on ash';
    20:
      msg1 := 'on lava. Hurts you and other creatures';
    21:
      msg1 := 'in front of a small dry tree';
    22:
      msg1 := 'in front of a big dry tree';
    23:
      msg1 := 'on dry grass';
    26:
      msg1 := 'looking into a crypt. Examine with [ENTER] or [' + KeyEnter + ']';
    33:
      msg1 := 'in front of an already opened crypt';
    28:
      msg1 := 'in front of an enchanted well. Drink with [ENTER] or [' + KeyEnter + ']';
    29:
      msg1 := 'in front of an empty well';
    30:
      msg1 := 'on plain floor';
    31:
    begin
      msg1 := 'on contaminated ground';
      if (ThePlayer.intProf = 1) or (ThePlayer.intProf = 4) then
        msg1 := msg1 + '. Clear it with [' + KeyTunnel + ']';
    end;
    34:
      msg1 := 'in front of a monster' + chr(39) + 's hive';
    35:
      msg1 := 'in front of one of your traps';
    36:
      msg1 := 'on sand';
    37:
      msg1 := 'on sand';
    38:
      msg1 := 'on shore';
    39:
      msg1 := 'on shore';
    40:
      msg1 := 'walking through shallow water';
    41:
      msg1 := 'on sand';
    42:
      msg1 := 'on sand';
    50:
      msg1 := 'sitting on a stool';
    51:
      msg1 := 'in front of a table';
    53:
      msg1 := 'in front of a big mushroom. Harvest with [' + KeyTake + ']';
    54:
      msg1 := 'in front of a small mushroom. Harvest with [' + KeyTake + ']';
    55:
      msg1 := 'on plain floor. You see some wooden garbage. Take it with [' +
        KeyTake + ']';
    57:
      msg1 := 'slipping on machine oil';
    58:
      msg1 := 'on plain floor. You see some metal parts. Take it with [' + KeyTake + ']';
    59:
      msg1 := 'a magical portal. Travel with [ENTER] or [' + KeyEnter + ']';
    60:
      msg1 := 'on snow';
    61:
      msg1 := 'on ice';
    62:
      msg1 := 'in front of an old staircase. Go up with [ENTER] or [' + KeyEnter + ']';
    63:
      msg1 := 'in front of an old staircase. Go down with [ENTER] or [' + KeyEnter + ']';
    65:
      msg1 := 'standing inside an iron gate';
    66:
      msg1 := 'in front of a ladder. Go up with [ENTER] or [' + KeyEnter + ']';
    67:
      msg1 := 'in front of a ladder. Go down with [ENTER] or [' + KeyEnter + ']';
  end;
  msg1 := 'You' + chr(39) + 're ' + msg1 + '.';

  if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 5 then
    if CheckEffect(48) = False then
      msg1 := 'You' + chr(39) + 're wandering through darkness.';

  if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 6 then
    msg1 := 'You' + chr(39) + 're trapped in an antbee web. [Dissolves in '+IntToStr(DngLvl[ThePlayer.intX, ThePlayer.intY].intAirRange)+' turns]';

  if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding > 0 then
    msg1 := 'There' + chr(39) + 's a trader here. Trade with [' +
      KeyTrade + ']. Drop an item here to sell it.';

  for i := 1 to 9 do
    if (NPC[i].intX = ThePlayer.intX) and (NPC[i].intY = ThePlayer.intY) then
      msg1 := 'You' + chr(39) + 're in front of ' + Quest[DungeonLevel, i].strNPCname +
        '. Talk with [' + KeyTrade + '].';

  if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem > 0 then
  begin
    if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 5 then
      msg1 := 'There' + chr(39) + 's something on the ground.'
    else
      msg1 := 'You see an item: ' +
        Thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].strName +
        '. Take it with [' + KeyTake + '].';

  end;

  LastMessage := '-';
  ShortMessageLog;

  if UseSDL=true then
  begin
    if UseHiRes = true then
      SmallTextXY(1, 56, msg1, false, false)
    else
      SmallTextXY(1, 42, msg1, false, false);
  end
  else
  begin
   GlobalConColor := darkgray;
   TransTextXY(1 + HiResTextOffsetX, 29 + HiResTextOffsetY, msg1);
   GlobalConColor := -1;
  end;

  Minimap;

  if UseSDL = True then
    ShowBars;

  if UseSDL = True then
    SDL_UPDATERECT(screen, 0, 0, 0, 0)
  else
    UpdateScreen(True);

  //writeln ('Quickbar Position x/y: ' + IntToStr(ChantBarX) + '/' + IntToStr(ChantBarY));

end;


end.
