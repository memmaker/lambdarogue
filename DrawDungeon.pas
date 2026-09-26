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

unit DrawDungeon;

interface

uses
  SDL, Crt, Video, SysUtils, BaseOutput, Constants, RandomArea, LineOfSight;


procedure ShowDungeon(sx: integer; sy: integer; w: integer; h: integer; mode: integer);

implementation

uses
  Items, Quests, Player, UserInterface;

// This function returns the appropriate character of a given floor type
function ReturnDngChar(n: integer): char;
begin
  ReturnDngChar := ' ';
  case n of
    0:
      ReturnDngChar := ' ';
    1:
    begin // wall
      ReturnDngChar := chr(180);
      if (UseSDL = True) and (DungeonLevel = 2) then
        ReturnDngChar := chr(214);
      if DungeonLevel = 21 then
        ReturnDngChar := chr(237);
      if (DungeonLevel = 23) or (DungeonLevel = 25) then
        ReturnDngChar := chr(244);
      if (DungeonLevel = 26) or (DungeonLevel = 27) then
        ReturnDngChar := chr(253);
    end;
    2:
    begin // floor
      ReturnDngChar := chr(150);
      if (UseSDL = True) and ((DungeonLevel = 6) or (DungeonLevel = 7)) then
        ReturnDngChar := chr(138);
      if (UseSDL = True) and (DungeonLevel >= 12) then
        ReturnDngChar := chr(142);
      if DungeonLevel = 21 then
        ReturnDngChar := chr(236);
      if (DungeonLevel = 26) or (DungeonLevel = 27) then
        ReturnDngChar := chr(254);
    end;
    3:
    begin // door
      ReturnDngChar := chr(151);
      if (UseSDL=True) and ((DungeonLevel = 26) or (DungeonLevel = 27)) then
        ReturnDngChar := chr(33);
    end;
    4:
    begin // open door
      ReturnDngChar := chr(152);
      if (UseSDL=True) and ((DungeonLevel = 26) or (DungeonLevel = 27)) then
        ReturnDngChar := chr(34);
    end;
    5:
      ReturnDngChar := chr(177);
    6:
    begin // mountain, rock
      if (DungeonLevel <> 10) and (DungeonLevel <> 11) then
        ReturnDngChar := chr(178)
      else
        ReturnDngChar := chr(206);
      if (DungeonLevel = 21) then
        ReturnDngChar := chr(235);
    end;
    7:
      ReturnDngChar := chr(153);
    8:
      ReturnDngChar := chr(175);
    9:
      ReturnDngChar := chr(176);
    10:
      ReturnDngChar := chr(134);
    11:
      ReturnDngChar := chr(135);
    12:
      if DungeonLevel = 21 then
        ReturnDngChar := chr(240)
      else
        ReturnDngChar := chr(136);
    13:
      ReturnDngChar := chr(137);
    14:
      ReturnDngChar := chr(154);
    15:
      ReturnDngChar := chr(170);
    16:
      if DungeonLevel < 23 then
        ReturnDngChar := chr(173)
      else
        ReturnDngChar := chr(245);
    17:
      ReturnDngChar := chr(148);
    18:
      ReturnDngChar := chr(149);
    19:
      ReturnDngChar := chr(174);
    20:
      ReturnDngChar := chr(183);
    21:
      if DungeonLevel = 21 then
        ReturnDngChar := chr(238)
      else
        ReturnDngChar := chr(181);
    22:
      if DungeonLevel = 21 then
        ReturnDngChar := chr(239)
      else
        ReturnDngChar := chr(182);
    23:
      ReturnDngChar := chr(184);
    24:
    begin  // locked door
      ReturnDngChar := chr(185);
    end;
    25:
    begin  // special walls
      if DungeonLevel < 17 then
        ReturnDngChar := chr(186)
      else
        ReturnDngChar := chr(199);
      if DungeonLevel > 22 then
        ReturnDngChar := chr(244);
    end;
    26:
      if DungeonLevel = 21 then
        ReturnDngChar := chr(241)
      else
        ReturnDngChar := chr(188);
    27:
      ReturnDngChar := chr(190);
    28:
      ReturnDngChar := chr(189);
    29:
      ReturnDngChar := chr(196);
    30:
      ReturnDngChar := chr(194);
    31:
      ReturnDngChar := chr(203);
    32:
      ReturnDngChar := chr(192);
    33:
      if DungeonLevel = 21 then
        ReturnDngChar := chr(241)
      else
        ReturnDngChar := chr(188);
    34:
      ReturnDngChar := chr(198);
    35:
      ReturnDngChar := chr(205);
    36:
      ReturnDngChar := chr(209);
    37:
      ReturnDngChar := chr(210);
    38:
      ReturnDngChar := chr(211);
    39:
      ReturnDngChar := chr(212);
    40:
      ReturnDngChar := chr(213);
    48:
    begin // hidden door
      if (DungeonLevel = 12) or (DungeonLevel = 13) then
        ReturnDngChar := chr(178)
      else
        ReturnDngChar := chr(180);
      if (UseSDL = True) and (DungeonLevel = 2) then
        ReturnDngChar := chr(214);
    end;
    49:
      ReturnDngChar := chr(225); // bookshelf
    50:
      ReturnDngChar := chr(224); // stool
    51:
      ReturnDngChar := chr(223); // table
    52:
      ReturnDngChar := chr(222); // barrel
    53:
      ReturnDngChar := chr(226); // big mushroom
    54:
      ReturnDngChar := chr(227); // small mushroom
    55:
      ReturnDngChar := chr(228); // wood rests
    56:
      ReturnDngChar := chr(229); // gas cylinder
    57:
      ReturnDngChar := chr(230); // machine oil
    58:
      ReturnDngChar := chr(231); // old machine
    59:
      ReturnDngChar := chr(232); // portal through time
    60:
      ReturnDngChar := chr(233); // snow
    61:
      ReturnDngChar := chr(234); // ice
    62:
      ReturnDngChar := chr(242); // old stairs up
    63:
      ReturnDngChar := chr(243); // old stairs down
    64:
      ReturnDngChar := chr(249); // closed iron gate
    65:
      ReturnDngChar := chr(250); // open iron gate
    66:
      ReturnDngChar := chr(251); // spaceship ladder up
    67:
      ReturnDngChar := chr(252); // spaceship ladder down
  end;
end;


procedure ShowDungeon(sx: integer; sy: integer; w: integer; h: integer; mode: integer);
var
  i, j, k, l, m, intMonPer, intBorder: integer;
  chDngChar, chItemChar, chMonHealthChar, chMonsterChar: char;
  dummy: string;
begin

  if UseSDL = True then
    SDL_BLITSURFACE(backgroundGraph, nil, screen, nil)
  else
  begin
    LockScreenUpdate;
    ClearScreenSDL;
  end;

  if UseSDL = True then
  begin
    intBorder := 0;
    if UseSmallTiles = True then
    begin
      if UseHiRes = False then
      begin
        w := 40;
        h := 14;
      end
      else
      begin
        w := 51;
        h := 19;
      end;
    end
    else
    begin
      if UseHiRes = False then
      begin
        w := 20;
        h := 8;
      end
      else
      begin
        w := 25;
        h := 9;
      end;
    end;
  end
  else
    intBorder := 1;

  if ThePlayer.intBlind = 0 then
  begin
    // initialize LOS
    SetVisible;

    // upper left
    k := 0;
    l := 0;

    for i := (w div 2) downto intBorder do
    begin
      for j := (h div 2) downto intBorder do
      begin

        //                 Writeln('D: '+IntToStr(sx-k)+'/'+IntToStr(sy-l));
        if (sx - k < 1) or (sy - l < 1) then
          break;

        chDngChar      := ReturnDngChar(DngLvl[sx - k, sy - l].intFloorType);
        chItemChar     := '^';
        chMonHealthChar := '^';
        chMonsterChar  := '^';
        GlobalConColor := -1;

        if DngLvl[sx - k, sy - l].blLOS = True then
        begin
          if (sx - k > 0) and (sx - k < DngMaxWidth + 1) and (sy - l > 1) and
            (sy - l < DngMaxHeight) then
          begin

            // select auras to draw
            case DngLvl[sx - k, sy - l].intAirType of
              1:
                chItemChar := chr(131);
              2:
                chItemChar := chr(133);
              3:
                chItemChar := chr(147);
              4:
                chItemChar := chr(208);
              5:
                if CheckEffect(48) = False then
                  DngLvl[sx - k, sy - l].blKnown := False;
              6:
                chItemChar := chr(221);
              //7:
                // hidden trap
              8:
                chItemChar := chr(205); // discovered trap
            end;

            // if tile is unknown, select nothing to draw
            if DngLvl[sx - k, sy - l].blKnown = False then
              chDngChar := ' ';

            // if graphics is selected, draw it on screen
            if chDngChar <> ' ' then
              AnyCharXY(i, j, chDngChar, 0);

            // if tile is bloody, select blood to draw
            if (UseSDL = True) and (ShowBlood = True) and
              (DngLvl[sx - k, sy - l].blBlood) then
              if (DungeonLevel=26) or (DungeonLevel=27) then  // oil instead of blood
              begin
                if DngLvl[sx - k, sy - l].intAirType<>1 then // only if not emblazed
                  chItemChar := chr(35);
              end
              else
                chItemChar := chr(128);

            // select NPCs to draw
            for m := 1 to 9 do
              if (NPC[m].intX = sx - k) and (NPC[m].intY = sy - l) then
              begin
                dummy      := IntToStr(m);
                chItemChar := dummy[1];
              end;

            // select shops to draw
            if DngLvl[sx - k, sy - l].intBuilding > 0 then
              chItemChar := chBuilding[DngLvl[sx - k, sy - l].intBuilding];

            // if tile has an item, select item to draw
            if (DngLvl[sx - k, sy - l].intItem > 0) and
              (DngLvl[sx - k, sy - l].blKnown = True) then
              chItemChar := Thing[DngLvl[sx - k, sy - l].intItem].chLetter;

            // select monsters to draw
            for m := 1 to 510 do
              if (Monster[m].intX = sx - k) and
                (Monster[m].intY = sy - l) and
                (DngLvl[sx - k, sy - l].blKnown = True) and
                (Monster[m].intInvis = 0) then
              begin
                chMonsterChar := Monster[m].chLetter;

                // display monster health for attacked monsters
                if Monster[m].blAttacked = True then
                begin

                  intMonPer :=
                    (100 * Monster[m].intHP) div Monster[m].intMaxHP;
                  if intMonPer > 0 then
                  begin
                    chMonHealthChar := chr(219);  // rest
                    GlobalConColor  := red;
                  end;

                  if intMonPer > 12 then
                  begin
                    chMonHealthChar := chr(218);  // 25%
                    GlobalConColor  := brown;
                  end;

                  if intMonPer > 25 then
                  begin
                    chMonHealthChar := chr(217);  // 50%
                    GlobalConColor  := yellow;
                  end;

                  if intMonPer > 50 then
                  begin
                    chMonHealthChar := chr(216);  // 75%
                    GlobalConColor  := lightgreen;
                  end;

                  if intMonPer > 75 then
                  begin
                    chMonHealthChar := chr(215);  // 100%
                    GlobalConColor  := green;
                  end;
                end
                else
                  chMonHealthChar := '^';
              end;

            if DngLvl[sx - k, sy - l].blKnown = False then
            begin
              chItemChar    := '^';
              chMonsterChar := '^';
            end;

            if chItemChar <> '^' then
              AnyCharXY(i, j, chItemChar, mode);

            if chMonsterChar <> '^' then
            begin
              AnyCharXY(i, j, chMonsterChar, mode);
              if (UseSDL = True) and (chMonHealthChar <> '^') then
                AnyCharXY(i, j, chMonHealthChar, mode);
            end;
          end;
        end
        else
        begin
          if DngLvl[sx - k, sy - l].blKnown = False then
          begin
            chDngChar     := ' ';
            chMonsterChar := '^';
          end;

          if chDngChar <> ' ' then
            AnyCharXY(i, j, chDngChar, 1);
        end;

        Inc(l);

      end;

      l := 0;
      Inc(k);
    end;

    // upper right
    k := 0;
    l := 0;

    for i := (w div 2) to w - intBorder do
    begin

      for j := (h div 2) downto intBorder do
      begin

        //                 Writeln('D: '+IntToStr(sx+k)+'/'+IntToStr(sy-l));
        if (sx + k < 1) or (sy - l < 1) then
          break;

        chDngChar      := ReturnDngChar(DngLvl[sx + k, sy - l].intFloorType);
        chItemChar     := '^';
        chMonHealthChar := '^';
        chMonsterChar  := '^';
        GlobalConColor := -1;

        if DngLvl[sx + k, sy - l].blLOS = True then
        begin
          if (sx + k > 0) and (sx + k < DngMaxWidth + 1) and (sy - l > 1) and
            (sy - l < DngMaxHeight) then
          begin

            case DngLvl[sx + k, sy - l].intAirType of
              1:
                chItemChar := chr(131);
              2:
                chItemChar := chr(133);
              3:
                chItemChar := chr(147);
              4:
                chItemChar := chr(208);
              5:
                if CheckEffect(48) = False then
                  DngLvl[sx + k, sy - l].blKnown := False;
              6:
                chItemChar := chr(221);
              //7:
                // hidden trap
              8:
                chItemChar := chr(205); // discovered trap
            end;

            if DngLvl[sx + k, sy - l].blKnown = False then
              chDngChar := ' ';

            if chDngChar <> ' ' then
              AnyCharXY(i, j, chDngChar, 0);

            if (UseSDL = True) and (ShowBlood = True) and
              (DngLvl[sx + k, sy - l].blBlood) then
              if (DungeonLevel=26) or (DungeonLevel=27) then  // oil instead of blood
              begin
                if DngLvl[sx + k, sy - l].intAirType<>1 then // only if not emblazed
                  chItemChar := chr(35);
              end
              else
                chItemChar := chr(128);

            for m := 1 to 9 do
              if (NPC[m].intX = sx + k) and (NPC[m].intY = sy - l) then
              begin
                dummy      := IntToStr(m);
                chItemChar := dummy[1];
              end;

            if DngLvl[sx + k, sy - l].intBuilding > 0 then
              chItemChar := chBuilding[DngLvl[sx + k, sy - l].intBuilding];

            if (DngLvl[sx + k, sy - l].intItem > 0) and
              (DngLvl[sx + k, sy - l].blKnown = True) then
              chItemChar := Thing[DngLvl[sx + k, sy - l].intItem].chLetter;

            for m := 1 to 510 do
              if (Monster[m].intX = sx + k) and
                (Monster[m].intY = sy - l) and
                (DngLvl[sx + k, sy - l].blKnown = True) and
                (Monster[m].intInvis = 0) then
              begin
                chMonsterChar := Monster[m].chLetter;

                // display monster health for attacked monsters
                if Monster[m].blAttacked = True then
                begin
                  intMonPer :=
                    (100 * Monster[m].intHP) div Monster[m].intMaxHP;
                  if intMonPer > 0 then
                  begin
                    chMonHealthChar := chr(219);  // rest
                    GlobalConColor  := red;
                  end;

                  if intMonPer > 12 then
                  begin
                    chMonHealthChar := chr(218);  // 25%
                    GlobalConColor  := brown;
                  end;

                  if intMonPer > 25 then
                  begin
                    chMonHealthChar := chr(217);  // 50%
                    GlobalConColor  := yellow;
                  end;

                  if intMonPer > 50 then
                  begin
                    chMonHealthChar := chr(216);  // 75%
                    GlobalConColor  := lightgreen;
                  end;

                  if intMonPer > 75 then
                  begin
                    chMonHealthChar := chr(215);  // 100%
                    GlobalConColor  := green;
                  end;
                end
                else
                  chMonHealthChar := '^';
              end;

            if DngLvl[sx + k, sy - l].blKnown = False then
            begin
              chItemChar    := '^';
              chMonsterChar := '^';
            end;

            if chItemChar <> '^' then
              AnyCharXY(i, j, chItemChar, mode);
            if chMonsterChar <> '^' then
            begin
              AnyCharXY(i, j, chMonsterChar, mode);
              if (UseSDL = True) and (chMonHealthChar <> '^') then
                AnyCharXY(i, j, chMonHealthChar, mode);
            end;
          end;
        end
        else
        begin
          if DngLvl[sx + k, sy - l].blKnown = False then
          begin
            chDngChar     := ' ';
            chMonsterChar := '^';
          end;
          if chDngChar <> ' ' then
            AnyCharXY(i, j, chDngChar, 1);
        end;

        Inc(l);

      end;

      l := 0;
      Inc(k);
    end;


    // lower left
    k := 0;
    l := 0;

    for i := (w div 2) downto intBorder do
    begin

      for j := (h div 2) to h - intBorder do
      begin
        //                 Writeln('D: '+IntToStr(sx-k)+'/'+IntToStr(sy+l));
        if (sx - k < 1) or (sy + l < 1) then
          break;

        chDngChar      := ReturnDngChar(DngLvl[sx - k, sy + l].intFloorType);
        chItemChar     := '^';
        chMonHealthChar := '^';
        chMonsterChar  := '^';
        GlobalConColor := -1;

        if DngLvl[sx - k, sy + l].blLOS = True then
        begin
          if (sx - k > 0) and (sx - k < DngMaxWidth + 1) and (sy + l > 1) and
            (sy + l < DngMaxHeight) then
          begin

            case DngLvl[sx - k, sy + l].intAirType of
              1:
                chItemChar := chr(131);
              2:
                chItemChar := chr(133);
              3:
                chItemChar := chr(147);
              4:
                chItemChar := chr(208);
              5:
                if CheckEffect(48) = False then
                  DngLvl[sx - k, sy + l].blKnown := False;
              6:
                chItemChar := chr(221);
              //7:
                // hidden trap
              8:
                chItemChar := chr(205); // discovered trap
            end;

            if DngLvl[sx - k, sy + l].blKnown = False then
              chDngChar := ' ';

            if chDngChar <> ' ' then
              AnyCharXY(i, j, chDngChar, 0);

            if (UseSDL = True) and (ShowBlood = True) and
              (DngLvl[sx - k, sy + l].blBlood) then
              if (DungeonLevel=26) or (DungeonLevel=27) then  // oil instead of blood
              begin
                if DngLvl[sx - k, sy + l].intAirType<>1 then // only if not emblazed
                  chItemChar := chr(35);
              end
              else
                chItemChar := chr(128);

            for m := 1 to 9 do
              if (NPC[m].intX = sx - k) and (NPC[m].intY = sy + l) then
              begin
                dummy      := IntToStr(m);
                chItemChar := dummy[1];
              end;

            if DngLvl[sx - k, sy + l].intBuilding > 0 then
              chItemChar := chBuilding[DngLvl[sx - k, sy + l].intBuilding];

            if (DngLvl[sx - k, sy + l].intItem > 0) and
              (DngLvl[sx - k, sy + l].blKnown = True) then
              chItemChar := Thing[DngLvl[sx - k, sy + l].intItem].chLetter;

            for m := 1 to 510 do
              if (Monster[m].intX = sx - k) and
                (Monster[m].intY = sy + l) and
                (DngLvl[sx - k, sy + l].blKnown = True) and
                (Monster[m].intInvis = 0) then
              begin
                chMonsterChar := Monster[m].chLetter;

                // display monster health for attacked monsters
                if Monster[m].blAttacked = True then
                begin
                  intMonPer :=
                    (100 * Monster[m].intHP) div Monster[m].intMaxHP;
                  if intMonPer > 0 then
                  begin
                    chMonHealthChar := chr(219);  // rest
                    GlobalConColor  := red;
                  end;

                  if intMonPer > 12 then
                  begin
                    chMonHealthChar := chr(218);  // 25%
                    GlobalConColor  := brown;
                  end;

                  if intMonPer > 25 then
                  begin
                    chMonHealthChar := chr(217);  // 50%
                    GlobalConColor  := yellow;
                  end;

                  if intMonPer > 50 then
                  begin
                    chMonHealthChar := chr(216);  // 75%
                    GlobalConColor  := lightgreen;
                  end;

                  if intMonPer > 75 then
                  begin
                    chMonHealthChar := chr(215);  // 100%
                    GlobalConColor  := green;
                  end;
                end
                else
                  chMonHealthChar := '^';

              end;

            if DngLvl[sx - k, sy + l].blKnown = False then
            begin
              chItemChar    := '^';
              chMonsterChar := '^';
            end;

            if chItemChar <> '^' then
              AnyCharXY(i, j, chItemChar, mode);
            if chMonsterChar <> '^' then
            begin
              AnyCharXY(i, j, chMonsterChar, mode);
              if (UseSDL = True) and (chMonHealthChar <> '^') then
                AnyCharXY(i, j, chMonHealthChar, mode);
            end;
          end;
        end
        else
        begin
          if DngLvl[sx - k, sy + l].blKnown = False then
          begin
            chDngChar     := ' ';
            chMonsterChar := '^';
          end;
          if chDngChar <> ' ' then
            AnyCharXY(i, j, chDngChar, 1);
        end;

        Inc(l);

      end;

      l := 0;
      Inc(k);
    end;


    // lower right

    k := 0;
    l := 0;

    for i := (w div 2) to w - intBorder do
    begin

      for j := (h div 2) to h - intBorder do
      begin

        //                 Writeln('D: '+IntToStr(sx+k)+'/'+IntToStr(sy+l));
        if (sx + k < 1) or (sy + l < 1) then
          break;

        chDngChar      := ReturnDngChar(DngLvl[sx + k, sy + l].intFloorType);
        chItemChar     := '^';
        chMonHealthChar := '^';
        chMonsterChar  := '^';
        GlobalConColor := -1;

        if DngLvl[sx + k, sy + l].blLOS = True then
        begin
          if (sx + k > 0) and (sx + k < DngMaxWidth + 1) and (sy + l > 1) and
            (sy + l < DngMaxHeight) then
          begin

            case DngLvl[sx + k, sy + l].intAirType of
              1:
                chItemChar := chr(131);
              2:
                chItemChar := chr(133);
              3:
                chItemChar := chr(147);
              4:
                chItemChar := chr(208);
              5:
                if CheckEffect(48) = False then
                  DngLvl[sx + k, sy + l].blKnown := False;
              6:
                chItemChar := chr(221);
              //7:
                // hidden trap
              8:
                chItemChar := chr(205); // discovered trap
            end;

            if DngLvl[sx + k, sy + l].blKnown = False then
              chDngChar := ' ';

            if chDngChar <> ' ' then
              AnyCharXY(i, j, chDngChar, 0);

            if (UseSDL = True) and (ShowBlood = True) and
              (DngLvl[sx + k, sy + l].blBlood) then
              if (DungeonLevel=26) or (DungeonLevel=27) then  // oil instead of blood
              begin
                if DngLvl[sx + k, sy + l].intAirType<>1 then // only if not emblazed
                  chItemChar := chr(35);
              end
              else
                chItemChar := chr(128);

            for m := 1 to 9 do
              if (NPC[m].intX = sx + k) and (NPC[m].intY = sy + l) then
              begin
                dummy      := IntToStr(m);
                chItemChar := dummy[1];
              end;

            if DngLvl[sx + k, sy + l].intBuilding > 0 then
              chItemChar := chBuilding[DngLvl[sx + k, sy + l].intBuilding];

            if (DngLvl[sx + k, sy + l].intItem > 0) and
              (DngLvl[sx + k, sy + l].blKnown = True) then
              chItemChar := Thing[DngLvl[sx + k, sy + l].intItem].chLetter;

            for m := 1 to 510 do
              if (Monster[m].intX = sx + k) and
                (Monster[m].intY = sy + l) and
                (DngLvl[sx + k, sy + l].blKnown = True) and
                (Monster[m].intInvis = 0) then
              begin
                chMonsterChar := Monster[m].chLetter;

                // display monster health for attacked monsters
                if Monster[m].blAttacked = True then
                begin
                  intMonPer :=
                    (100 * Monster[m].intHP) div Monster[m].intMaxHP;
                  if intMonPer > 0 then
                  begin
                    chMonHealthChar := chr(219);  // rest
                    GlobalConColor  := red;
                  end;

                  if intMonPer > 12 then
                  begin
                    chMonHealthChar := chr(218);  // 25%
                    GlobalConColor  := brown;
                  end;

                  if intMonPer > 25 then
                  begin
                    chMonHealthChar := chr(217);  // 50%
                    GlobalConColor  := yellow;
                  end;

                  if intMonPer > 50 then
                  begin
                    chMonHealthChar := chr(216);  // 75%
                    GlobalConColor  := lightgreen;
                  end;

                  if intMonPer > 75 then
                  begin
                    chMonHealthChar := chr(215);  // 100%
                    GlobalConColor  := green;
                  end;
                end
                else
                  chMonHealthChar := '^';
              end;

            if DngLvl[sx + k, sy + l].blKnown = False then
            begin
              chItemChar    := '^';
              chMonsterChar := '^';
            end;

            if chItemChar <> '^' then
              AnyCharXY(i, j, chItemChar, mode);
            if chMonsterChar <> '^' then
            begin
              AnyCharXY(i, j, chMonsterChar, mode);
              if (UseSDL = True) and (chMonHealthChar <> '^') then
                AnyCharXY(i, j, chMonHealthChar, mode);
            end;
          end;
        end
        else
        begin
          if DngLvl[sx + k, sy + l].blKnown = False then
          begin
            chDngChar     := ' ';
            chMonsterChar := '^';
          end;
          if chDngChar <> ' ' then
            AnyCharXY(i, j, chDngChar, 1);
        end;

        Inc(l);
      end;

      l := 0;
      Inc(k);
    end;
  end;


  // draw player
  if IsInvisible = False then
  begin
    chDngChar := chr(179);
    if ThePlayer.intPoison > 0 then
      chDngChar := chr(187);
    if ThePlayer.intWall > 0 then
      chDngChar := chr(146);
    if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 5 then
      chDngChar := chr(220);
    if DngLvl[ThePlayer.intX, ThePlayer.intY].intAirType = 5 then
      if CheckEffect(48) = False then
        chDngChar := chr(143);

    if UseSDL = True then
      AnyCharXY(ThePlayer.intBX, ThePlayer.intBY + 1, chDngChar, 0)
    else
      AnyCharXY(ThePlayer.intBX, ThePlayer.intBY, chDngChar, 0);
  end;

  ShowStatus;

  if UseSDL = False then
    UnLockScreenUpdate;

end;

end.