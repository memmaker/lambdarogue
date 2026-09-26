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

unit Input;


interface

uses
  WebBE,
  SysUtils, Constants, RandomArea, Player, Items, Chants, BaseOutput, UserInterface, DrawDungeon;

var
  MyEvent: TSDL_EVENT;
  xMouse, yMouse, QuickBarID: integer;
  KeyRepeatSoll, KeyRepeatIst: integer;
  blInsideBar, blInsideStatus: boolean;

procedure MouseOvers(KX, KY: integer);
function GetDirection(mode: integer): char;
function GetRepeat(mode: integer): integer;
function GetTextInput(message: string; MaxLength: integer): string;
function GetKeyInput(message: string; pressanykey: boolean): string;

function cookKey(unicode, sdlkey: integer): integer;
function ConsoleInput(): integer;

implementation


// in SDL mode, show popups if mouse hovers certain screen areas
procedure MouseOvers(KX, KY: integer);
var
  i, id, yoffset, xoffset, d: integer;
  blIsSpell:   boolean;
  InfoBGRect, ScreenRect: SDL_RECT;
  ToNextLevel: longint;
  TempHunger: string;
begin

  // position of popup window
  InfoBGRect.x := 1500;     // 1500
  InfoBGRect.y := 0;
  InfoBGRect.w := 180;
  InfoBGRect.h := 140;

  if UseHiRes=true then
  begin
    if KY<=600 then
    begin
      ScreenRect.y := KY+20;
      xoffset := -(16 - (KX div 7));
      yoffset := -(4 - (KY div 12));
    end
    else
    begin
      ScreenRect.y := KY-150;
      xoffset := -(16 - (KX div 7));
      yoffset := -(16 - (KY div 12));
    end;
  end
  else
  begin
    if KY<=400 then
    begin
      ScreenRect.y := KY+20;
      xoffset := -(1 - (KX div 7));
      yoffset := 3+(KY div 12);
    end
    else
    begin
      ScreenRect.y := KY-150;
      xoffset := -(6 - (KX div 7));
      yoffset := -(9 - (KY div 12));
    end;
  end;

  if ScreenRect.y<0 then
    ScreenRect.y:=0;

  ScreenRect.x := KX;

  ScreenRect.w := 180;
  ScreenRect.h := 140;

  // ** Quickbar **
  QuickBarID := -1;
  if (KX - 40 >= ChantBarX) and (KY >= ChantBarY) and (KX - 40 <= ChantBarX + 480) and
    (KY <= ChantBarY + 40) then
  begin
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

    // get number of current hovered quickbar icon
    if KX - 40 < ChantBarX + 40 then
      QuickBarID := 1;

    if (KX - 40 > ChantBarX + 40) and (KX - 40 < ChantBarX + 80) then
      QuickBarID := 2;

    if (KX - 40 > ChantBarX + 80) and (KX - 40 < ChantBarX + 120) then
      QuickBarID := 3;

    if (KX - 40 > ChantBarX + 120) and (KX - 40 < ChantBarX + 160) then
      QuickBarID := 4;

    if (KX - 40 > ChantBarX + 160) and (KX - 40 < ChantBarX + 200) then
      QuickBarID := 5;

    if (KX - 40 > ChantBarX + 200) and (KX - 40 < ChantBarX + 240) then
      QuickBarID := 6;

    if (KX - 40 > ChantBarX + 240) and (KX - 40 < ChantBarX + 280) then
      QuickBarID := 7;

    if (KX - 40 > ChantBarX + 280) and (KX - 40 < ChantBarX + 320) then
      QuickBarID := 8;

    if (KX - 40 > ChantBarX + 320) and (KX - 40 < ChantBarX + 360) then
      QuickBarID := 9;

    if (KX - 40 > ChantBarX + 360) and (KX - 40 < ChantBarX + 400) then
      QuickBarID := 10;

    if (KX - 40 > ChantBarX + 400) and (KX - 40 < ChantBarX + 440) then
      QuickBarID := 11;

    if (KX - 40 > ChantBarX + 440) and (KX - 40 < ChantBarX + 480) then
      QuickBarID := 12;

    // ist es spell oder item?

    if QuickBarID > -1 then
    begin
      blIsSpell := False;

      id := -1;
      for i := 1 to ChantCount do
        if Spell[i].strName = strQuickKey[QuickBarID] then
        begin
          id := i;
          blIsSpell := True;
        end;

      if blIsSpell = False then
        for i := 1 to ItemCount do
          if Thing[i].strRealName = strQuickKey[QuickBarID] then
            id := i;


      // show info about selected quickbar item
      if id > -1 then
        if blIsSpell = True then // spell
        begin
          //SDL_BLITSURFACE(extratiles, @InfoBGRect, screen, @ScreenRect);
          SmallTextXY(0 + xoffset, 1 + yoffset, uppercase(Spell[id].strName), True, True);
          SmallTextXY(0 + xoffset, 3 + yoffset, Spell[id].strDescri, True, True);
          SmallTextXY(0 + xoffset, 5 + yoffset, 'Level     : ' + IntToStr(spellbook[PlayerHasSpell(Spell[id].strName)].intKnown),
            True, True);
          SmallTextXY(0 + xoffset, 6 + yoffset, 'Efficiency: ' + IntToStr(Spell[id].intRange + (Spellbook[PlayerHasSpell(Spell[id].strName)].intKnown * Spellbook[PlayerHasSpell(Spell[id].strName)].intKnown)),
            True, True);

          d := Spell[id].intPP + (2 * spellbook[PlayerHasSpell(Spell[id].strName)].intKnown);
          if CheckEffect(57) = True then
            d := d - (d div 4);
          SmallTextXY(0 + xoffset, 7 + yoffset, 'PP        : ' + IntToStr(d), True, True);

          if spellbook[PlayerHasSpell(Spell[id].strName)].intRefresh < Spell[spellbook[PlayerHasSpell(Spell[id].strName)].intType].intRefresh then
            SmallTextXY(0 + xoffset, 8 + yoffset, 'Refresh   : ' + IntToStr(Spell[spellbook[PlayerHasSpell(Spell[id].strName)].intType].intRefresh - spellbook[PlayerHasSpell(Spell[id].strName)].intRefresh) + ' turn(s) for refresh', True, True);

        end
        else // item
        begin
          //SDL_BLITSURFACE(extratiles, @InfoBGRect, screen, @ScreenRect);
          SmallTextXY(0 + xoffset, 1 + yoffset, uppercase(Thing[id].strName), True, True);

          if Thing[id].strDescri='-' then
            SmallTextXY(0 + xoffset, 3 + yoffset, GetEffectDescription(Thing[id].intEffect), True, True)
          else
            SmallTextXY(0 + xoffset, 3 + yoffset, Thing[id].strDescri, True, True);

          SmallTextXY(0 + xoffset, 5 + yoffset, 'Efficiency: ' + IntToStr(Thing[id].intRange),
            True, True);

          if PlayerHasItem(Thing[id].strName) > 0 then
            SmallTextXY(0 + xoffset, 6 + yoffset,
              'Amount    : ' + IntToStr(Inventory[PlayerHasItem(Thing[id].strName)].longNumber),
              True, True)
          else
            SmallTextXY(0 + xoffset, 6 + yoffset, 'Amount    : 0', True, True);
        end;
    end;

    blInsideBar := True;
  end;


  // ** Status Area **
  if (KX >= 0) and (KX <= 208) and (KY >= 0) and (KY <= 96) and (blInsideBar = False) then
  begin

    ToNextLevel := (ThePlayer.intLvl * CONST_LVL_MULTI) *
      (ThePlayer.intLvl * CONST_LVL_MULTI) * ThePlayer.intLvl;

    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

    //SDL_BLITSURFACE(extratiles, @InfoBGRect, screen, @ScreenRect);
    SmallTextXY(0 + xoffset, 1 + yoffset, uppercase(ThePlayer.strName), True, True);
    SmallTextXY(0 + xoffset, 3 + yoffset, 'HP : ' + IntToStr(ThePlayer.intHP) +
      '/' + IntToStr(ThePlayer.intMaxHP), True, True);
    SmallTextXY(0 + xoffset, 4 + yoffset, 'PP : ' + IntToStr(ThePlayer.intPP) +
      '/' + IntToStr(ThePlayer.intMaxPP), True, True);
    SmallTextXY(0 + xoffset, 5 + yoffset, 'STR: ' + IntToStr(ThePlayer.intStrength) +
      '/100%', True, True);
    SmallTextXY(0 + xoffset, 6 + yoffset, 'DST: ' + IntToStr(ThePlayer.intLimit) +
      '/100%', True, True);

    SmallTextXY(0 + xoffset, 8 + yoffset, 'CLV: ' + IntToStr(ThePlayer.intLvl), True, True);
    SmallTextXY(0 + xoffset, 9 + yoffset, 'EXP: ' + IntToStr(ThePlayer.longEXP) +
      ' (Next: ' + IntToStr(ToNextLevel) + ')', True, True);

    i := 10 + yoffset;


    TempHunger:='-';
    if (ThePlayer.longFood > 60) and (ThePlayer.longFood < 200) then
      TempHunger:='Hungry';
    if (ThePlayer.longFood > 20) and (ThePlayer.longFood < 61) then
      TempHunger:='Fainting';
    if (ThePlayer.longFood > 0) and (ThePlayer.longFood < 21) then
      TempHunger:='Starving';
    if TempHunger<>'-' then
    begin
      SmallTextXY(0 + xoffset, i, TempHunger, True, True);
      Inc(i);
    end;


    if ThePlayer.intPoison > 0 then
    begin
      SmallTextXY(0 + xoffset, i, 'Poisoned ('+IntToStr(ThePlayer.intPoison)+')', True, True);
      Inc(i);
    end;

    if ThePlayer.intConfusion > 0 then
    begin
      SmallTextXY(0 + xoffset, i, 'Confused ('+IntToStr(ThePlayer.intConfusion)+')', True, True);
      Inc(i);
    end;

    if ThePlayer.intPara > 0 then
    begin
      SmallTextXY(0 + xoffset, i, 'Paralized ('+IntToStr(ThePlayer.intPara)+')', True, True);
      Inc(i);
    end;

    if ThePlayer.intInvis > 0 then
    begin
      SmallTextXY(0 + xoffset, i, 'Invisible ('+IntToStr(ThePlayer.intInvis)+')', True, True);
      Inc(i);
    end;

    if (ThePlayer.intCalm > 0) or
      (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 11) then
    begin
      SmallTextXY(0 + xoffset, i, 'Calm', True, True);
      Inc(i);
    end;

    if ThePlayer.blCursed = True then
    begin
      SmallTextXY(0 + xoffset, i, 'Cursed', True, True);
      Inc(i);
    end;

    if (ThePlayer.intTotalVitari > 0) and (ThePlayer.intNeedVitari >=
      ThePlayer.intNextVitari) then
    begin
      SmallTextXY(0 + xoffset, i, 'Craving', True, True);
      Inc(i);
    end;

    if ThePlayer.blBlessed = True then
    begin
      SmallTextXY(0 + xoffset, i, 'Blessed', True, True);
      Inc(i);
    end;

    if ThePlayer.intBlind > 0 then
    begin
      SmallTextXY(0 + xoffset, i, 'Blind ('+IntToStr(ThePlayer.intBlind)+')', True, True);
      Inc(i);
    end;

    if ThePlayer.intWall > 0 then
    begin
      SmallTextXY(0 + xoffset, i, 'Barrier ('+IntToStr(ThePlayer.intWall)+')', True, True);
      Inc(i);
    end;


    if CheckEffect(37) = True then   // maximize magic
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Magic', True, True);
      Inc(i);
    end;

    if CheckEffect(7) = True then   // extra gold
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Credits', True, True);
      Inc(i);
    end;

    if CheckEffect(6) = True then   // extra EXP
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Experience', True, True);
      Inc(i);
    end;

    if CheckEffect(25) = True then   // max. move
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Move', True, True);
      Inc(i);
    end;

    if CheckEffect(64) = True then   // max. fight
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Fight', True, True);
      Inc(i);
    end;

    if CheckEffect(62) = True then   // max. hit
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Hit', True, True);
      Inc(i);
    end;

    if CheckEffect(65) = True then   // max. humility
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Humility', True, True);
      Inc(i);
    end;

    if CheckEffect(66) = True then   // max. talent
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Talent', True, True);
      Inc(i);
    end;

    if CheckEffect(10) = True then   // resist poison
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Poison', True, True);
      Inc(i);
    end;

    if CheckEffect(49) = True then   // divine rage bonus
    begin
      SmallTextXY(0 + xoffset, i, 'Maximized Distress', True, True);
      Inc(i);
    end;

    if CheckEffect(55) = True then   // resist electricity
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Electricity', True, True);
      Inc(i);
    end;

    if CheckEffect(13) = True then   // resist fire
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Fire', True, True);
      Inc(i);
    end;

    if CheckEffect(14) = True then   // resist ice
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Ice', True, True);
      Inc(i);
    end;

    if CheckEffect(17) = True then   // resist blindness
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Blindness', True, True);
      Inc(i);
    end;

    if CheckEffect(26) = True then   // resist paralization
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Paralization', True, True);
      Inc(i);
    end;

    if CheckEffect(28) = True then   // resist calm
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Calm', True, True);
      Inc(i);
    end;

    if CheckEffect(31) = True then   // resist curses
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Curse', True, True);
      Inc(i);
    end;

    if CheckEffect(35) = True then   // resist water
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Water', True, True);
      Inc(i);
    end;

    if CheckEffect(51) = True then   // resist DrainPP
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Psychic Drain', True, True);
      Inc(i);
    end;

    if CheckEffect(52) = True then   // resist DrainSTR
    begin
      SmallTextXY(0 + xoffset, i, 'Resists Strength Drain', True, True);
      Inc(i);
    end;

    if (CheckEffect(54) = True) or (DungeonLevel = ThePlayer.intBirthLevel) then   // familiar terrain
    begin
      SmallTextXY(0 + xoffset, i, 'Familiar Terrain', True, True);
      Inc(i);
    end;

    if CheckEffect(57) = True then   // reduced PP costs
    begin
      SmallTextXY(0 + xoffset, i, 'Red. PP Costs', True, True);
      Inc(i);
    end;

    blInsideStatus := True;
  end;


  // If mouse left Quickbar, remove info
  if (blInsideBar = True) and ((KX - 42 < ChantBarX) or (KX - 42 > ChantBarX + 504) or
    (KY < ChantBarY) or (KY > ChantBarY + 40)) then
  begin
    blInsideBar := False;
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  end;

  // If mouse left Status Area, remove info
  if (blInsideStatus = True) and ((KX > 207) or (KY > 96)) then
  begin
    blInsideStatus := False;
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  end;

  if (blInsideBar = true) or (blInsideStatus = true) then
    SDL_UPDATERECT(screen, 0, 0, 0, 0);

end;


// ' returns the distance between two points
function Distance(x0, y0, x1, y1: real): integer;
var
  xd, yd: real;
  d:      real;
begin
  //     writeln(x0);
  //     writeln(x1);
  //     writeln(y0);
  //     writeln(y1);

  xd := (x1 - x0) * (x1 - x0);
  yd := (y1 - y0) * (y1 - y0);
  d  := abs(xd + yd);
  //     writeln(d);
  if d = 0 then
    Distance := 0
  else
  begin
    d := sqrt(d);
    Distance := abs(trunc(d));
  end;
end;


function cookKey(unicode, sdlkey: integer): integer;
begin
  if (unicode > 31) and (unicode < 128) then
    cookKey := unicode
  else
  begin
    case sdlkey of
      SDLK_KP1:
        cookKey := SDLK_KP1;
      SDLK_KP2:
        cookKey := SDLK_KP2;
      SDLK_KP3:
        cookKey := SDLK_KP3;
      SDLK_KP4:
        cookKey := SDLK_KP4;
      SDLK_KP6:
        cookKey := SDLK_KP6;
      SDLK_KP7:
        cookKey := SDLK_KP7;
      SDLK_KP8:
        cookKey := SDLK_KP8;
      SDLK_KP9:
        cookKey := SDLK_KP9;
      SDLK_UP:
        cookKey := SDLK_UP;
      SDLK_DOWN:
        cookKey := SDLK_DOWN;
      SDLK_PAGEUP:
        cookKey := SDLK_PAGEUP;
      SDLK_PAGEDOWN:
        cookKey := SDLK_PAGEDOWN;
      SDLK_LEFT:
        cookKey := SDLK_LEFT;
      SDLK_RIGHT:
        cookKey := SDLK_RIGHT;
      SDLK_KP0:
        cookKey := SDLK_INSERT;
      13:
        cookKey := 13;
      SDLK_KP_ENTER:
        cookKey := 13;
      8:
        cookKey := 8;
      SDLK_ESCAPE:
        cookKey := SDLK_ESCAPE;
      SDLK_F1:
        cookKey := SDLK_F1;
      SDLK_F2:
        cookKey := SDLK_F2;
      SDLK_F3:
        cookKey := SDLK_F3;
      SDLK_F4:
        cookKey := SDLK_F4;
      SDLK_F5:
        cookKey := SDLK_F5;
      SDLK_F6:
        cookKey := SDLK_F6;
      SDLK_F7:
        cookKey := SDLK_F7;
      SDLK_F8:
        cookKey := SDLK_F8;
      SDLK_F9:
        cookKey := SDLK_F9;
      SDLK_F10:
        cookKey := SDLK_F10;
      SDLK_F11:
        cookKey := SDLK_F11;
      SDLK_F12:
        cookKey := SDLK_F12;
    end;
  end;
end;


function ConsoleInput(): integer;
var
  k:     TKeyEvent;
  zeichen: char;
  kette: string;
begin
  ConsoleInput := 0;

  k := GetKeyEvent;
  k := TranslateKeyEvent(k);

  if IsFunctionKey(k) = True then
  begin
    kette := KeyEventToString(k);
    if kette = 'Left' then
      ConsoleInput := SDLK_LEFT
    else
    if kette = 'Right' then
      ConsoleInput := SDLK_RIGHT
    else
    if kette = 'Up' then
      ConsoleInput := SDLK_UP
    else
    if kette = 'Down' then
      ConsoleInput := SDLK_DOWN
    else
    if kette = 'Home' then
      ConsoleInput := SDLK_KP7
    else
    if kette = 'PgUp' then
      ConsoleInput := SDLK_PAGEUP
    else
    if kette = 'End' then
      ConsoleInput := SDLK_KP1
    else
    if kette = 'PgDn' then
      ConsoleInput := SDLK_PAGEDOWN
    else
    if kette = 'Delete' then
      ConsoleInput := SDLK_DELETE
    else
    if kette = 'Insert' then
      ConsoleInput := SDLK_INSERT;
    if kette = 'F1' then
      ConsoleInput := SDLK_F1;
    if kette = 'F2' then
      ConsoleInput := SDLK_F2;
    if kette = 'F3' then
      ConsoleInput := SDLK_F3;
    if kette = 'F4' then
      ConsoleInput := SDLK_F4;
    if kette = 'F5' then
      ConsoleInput := SDLK_F5;
    if kette = 'F6' then
      ConsoleInput := SDLK_F6;
    if kette = 'F7' then
      ConsoleInput := SDLK_F7;
    if kette = 'F8' then
      ConsoleInput := SDLK_F8;
    if kette = 'F9' then
      ConsoleInput := SDLK_F9;
    if kette = 'F10' then
      ConsoleInput := SDLK_F10;
    if kette = 'F11' then
      ConsoleInput := SDLK_F11;
    if kette = 'F12' then
      ConsoleInput := SDLK_F12;

    // process keys that are not covered by KeyEventToString
    if GetKeyEventCode(K) = $011B then
      ConsoleInput := SDLK_ESCAPE;
  end
  else
  begin
    //         kette:=KeyEventToString(k);
    //         zeichen:=kette[1];

    zeichen      := GetKeyEventChar(k);
    ConsoleInput := Ord(zeichen);
  end;

  //     if (ord(zeichen)>64) and (ord(zeichen)<91) then
  //         ConsoleInput:=0;

end;



function GetDirection(mode: integer): char;
var
  chKey: char;
  n:     integer;
  kx, ky, knoepfe: longint;
begin

  BottomBar;

  if mode = 0 then
    ShowMessage('Direction?  [press the according direction key]', False)
  else
  if mode = 1 then
    //         ShowMessage('[right] and [left] to select, [down] to select, [up] to cancel');
    mode := mode;

  chKey := ' ';

  repeat

    n:=0;

    if UseSDL = True then
    begin
      if SDL_POLLEVENT(@MyEvent) > 0 then
      begin
        case MyEvent.type_ of
          SDL_KEYDOWN:
            n := cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
        end;
      end;
    end
    else
      n := ConsoleInput();

    // evaluate key
    if n = Ord(KeyNorth) then
      chKey := KeyNorth
    else
    if n = Ord(KeySouth) then
      chKey := KeySouth
    else
    if n = Ord(KeyEast) then
      chKey := KeyEast
    else
    if n = Ord(KeyWest) then
      chKey := KeyWest
    else
    if n = Ord(KeyNorthEast) then
      chKey := KeyNorthEast
    else
    if n = Ord(KeyNorthWest) then
      chKey := KeyNorthWest
    else
    if n = Ord(KeySouthEast) then
      chKey := KeySouthEast
    else
    if n = Ord(KeySouthWest) then
      chKey := KeySouthWest;

    case n of
      SDLK_UP:
        chKey := KeyNorth;
      SDLK_KP8:
        chKey := KeyNorth;
      SDLK_DOWN:
        chKey := KeySouth;
      SDLK_KP2:
        chKey := KeySouth;
      SDLK_LEFT:
        chKey := KeyWest;
      SDLK_KP4:
        chKey := KeyWest;
      SDLK_RIGHT:
        chKey := KeyEast;
      SDLK_KP6:
        chKey := KeyEast;
      SDLK_KP9:
        chKey := KeyNorthEast;
      SDLK_KP7:
        chKey := KeyNorthWest;
      SDLK_KP3:
        chKey := KeySouthEast;
      SDLK_KP1:
        chKey := KeySouthWest;
      Ord('1'):
        chKey := KeySouthWest;
      Ord('2'):
        chKey := KeySouth;
      Ord('3'):
        chKey := KeySouthEast;
      Ord('4'):
        chKey := KeyWest;
      Ord('6'):
        chKey := KeyEast;
      Ord('7'):
        chKey := KeyNorthWest;
      Ord('8'):
        chKey := KeyNorth;
      Ord('9'):
        chKey := KeyNorthEast;
    end;

    delay(10);

  until (chKey = KeyNorth) or (chKey = KeySouth) or (chKey = KeyEast) or
    (chKey = KeyWest) or (chKey = KeyNorthEast) or (chKey = KeySouthEast) or
    (chKey = KeyNorthWest) or (chKey = KeySouthWest);

  //    ShowMessage('Direction? ' + chKey);
  Delay(100);

  GetDirection := chKey;
end;


function GetRepeat(mode: integer): integer;
var
  k, n:     integer;
  strInput: string;
  blOK:     boolean;
  message:  string;
  chNumPad: string;
begin
  if mode = 0 then
    message := 'Repeat?'
  else
  if mode = 2 then
    message := 'Amount?'
  else
  if mode = 3 then
    message := 'Enter correct passcode: '
  else
    message := 'Selection?';

  ShowMessage(message + ' _', False);

  strInput := '';
  blOK     := False;

  repeat
    chNumPad := '';

    if UseSDL = True then
    begin
      if SDL_POLLEVENT(@MyEvent) > 0 then
        case MyEvent.type_ of
          SDL_KEYDOWN:
            k := cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
        end;
    end
    else
      k := ConsoleInput();

    case k of
      13:
        blOK := True;

      //             8:        begin
      //                         strInput := '';
      //                         ShowMessage(message + '                                                                      ', false);
      //                     end;

      8:
      begin
        strInput := copy(strInput, 1, length(strInput) - 1);
        ShowMessage(message + ' ' + strInput + '_', False);
      end;


      SDLK_LEFT:
      begin
        strInput := copy(strInput, 1, length(strInput) - 1);
        ShowMessage(message + ' ' + strInput + '_', False);
      end;

      SDLK_KP1:
        chNumPad := '1';
      SDLK_KP2:
        chNumPad := '2';
      SDLK_KP3:
        chNumPad := '3';
      SDLK_KP4:
        chNumPad := '4';
      SDLK_KP5:
        chNumPad := '5';
      SDLK_KP6:
        chNumPad := '6';
      SDLK_KP7:
        chNumPad := '7';
      SDLK_KP8:
        chNumPad := '8';
      SDLK_KP9:
        chNumPad := '9';
    end;

    if chNumPad <> '' then
      if length(strInput) < 4 then
      begin
        strInput := strInput + chNumPad;
        ShowMessage(message + ' ' + strInput + '_', False);
      end;

    if (k > 47) and (k < 58) then
      if length(strInput) < 4 then
      begin
        strInput := strInput + chr(k);
        ShowMessage(message + ' ' + strInput + '_', False);
      end;

    delay(10);

  until (blOK = True);

  Val(strInput, n);

  GetRepeat := n;
end;


function GetTextInput(message: string; MaxLength: integer): string;
var
  k:    integer;
  strInput: string;
  blOK: boolean;
  chNumPad: string;
begin
  web_prompt(message);  // RVIP: prompt line over the map
  BottomBar;
  ShowMessage(message + ' _', False);

  strInput := '';
  blOK     := False;

  repeat

    delay(10);

    chNumPad := '';

    k := 0;

    if UseSDL = True then
    begin
      if SDL_POLLEVENT(@MyEvent) > 0 then
        case MyEvent.type_ of
          SDL_KEYDOWN:
            k := cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
        end;
    end
    else
      k := ConsoleInput();

    case k of
      13:
        blOK := True;
      //             8:        begin
      //                         strInput := '';
      //                         ShowMessage('                                                                            ', false);
      //                         ShowMessage(message, false);
      //                     end;

      8:
      begin
        strInput := copy(strInput, 1, length(strInput) - 1);
        ShowMessage(message + ' ' + strInput + '_', False);
      end;


      SDLK_LEFT:
      begin
        strInput := copy(strInput, 1, length(strInput) - 1);
        ShowMessage(message + ' ' + strInput + '_', False);
      end;

      SDLK_KP1:
        chNumPad := '1';
      SDLK_KP2:
        chNumPad := '2';
      SDLK_KP3:
        chNumPad := '3';
      SDLK_KP4:
        chNumPad := '4';
      SDLK_KP5:
        chNumPad := '5';
      SDLK_KP6:
        chNumPad := '6';
      SDLK_KP7:
        chNumPad := '7';
      SDLK_KP8:
        chNumPad := '8';
      SDLK_KP9:
        chNumPad := '9';
    end;

    if chNumPad <> '' then
    begin
      if length(strInput) < MaxLength then
      begin
        strInput := strInput + chNumPad;
        ShowMessage(message + ' ' + strInput + '_', False);
        //                 strInput[1] := UpCase(strInput[1]);
      end;
    end;

    if (k > 31) and (k < 127) then
    begin
      if length(strInput) < MaxLength then
      begin
        strInput := strInput + chr(k);
        ShowMessage(message + ' ' + strInput + '_', False);
        //                 strInput[1] := UpCase(strInput[1]);
      end;
    end;

    delay(10);

  until (blOK = True);

  GetTextInput := strInput;
  LastMessage  := '-';
end;



function GetKeyInput(message: string; pressanykey: boolean): string;
var
  k:    integer;
  kx, ky, knoepfe: longint;
  strInput: string;
  blOK: boolean;
  chNumPad: string;
begin

  web_prompt(message);  // RVIP: prompt line over the map
  if (message <> ' ') or (pressanykey = True) then
  begin
    if pressanykey = False then
    begin
      TransTextXY(1, 27, message);
      if UseSDL = True then
        SDL_UPDATERECT(screen, 0, 0, 0, 0)
      else
        UpdateScreen(True);
    end
    else
    begin
      BottomBar;
      ShowMessage(message, True);
    end;
  end
  else
  begin
    // explicitly update screen if not updated by ShowMessage
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);
  end;

  strInput := '';
  blOK     := False;

  repeat
    chNumPad := '';

    delay(10);

    // when we set k to -1, it seems that all messages stay where they should ...
    k := -1;

    if UseSDL = True then
    begin

      if SDL_POLLEVENT(@MyEvent) > 0 then
      begin
        if UseMouseToMove = True then
        begin
          kx      := MyEvent.motion.x;
          ky      := MyEvent.motion.y;
          knoepfe := SDL_GetMouseState(kx, ky);
          if (Knoepfe and SDL_BUTTON(SDL_BUTTON_RIGHT)) <> 0 then
            k := 13;
        end;
        if MyEvent.type_ = SDL_KEYDOWN then
          k := cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
      end;
      delay(10);
    end
    else
      k := ConsoleInput();

    case k of
      13:
      begin
        strInput := 'ENTER';
        blOK     := True;
      end;
      32:
      begin
        strInput := 'SPACE';
        blOK := True;
      end;
      8:
      begin
        strInput := '';
        //if message<>' ' then
        //begin
        //  ShowMessage('                                                                            ', false);
        //ShowMessage(message, false);
        //end;
      end;

      SDLK_KP1:
        chNumPad := '1';
      SDLK_KP2:
        chNumPad := '2';
      SDLK_KP3:
        chNumPad := '3';
      SDLK_KP4:
        chNumPad := '4';
      SDLK_KP5:
        chNumPad := '5';
      SDLK_KP6:
        chNumPad := '6';
      SDLK_KP7:
        chNumPad := '7';
      SDLK_KP8:
        chNumPad := '8';
      SDLK_KP9:
        chNumPad := '9';

      SDLK_LEFT:
        chNumPad := ' ';
      SDLK_RIGHT:
        chNumPad := ' ';
      SDLK_UP:
        chNumPad := ' ';
      SDLK_DOWN:
        chNumPad := ' ';

      SDLK_PAGEUP:
      begin
        strInput := '-';
        blOK     := True;
      end;

      SDLK_PAGEDOWN:
      begin
        strInput := '+';
        blOK     := True;
      end;


      SDLK_ESCAPE:
      begin
        strInput := 'ESC';  // this ESC is totally arbitray
        blOK     := True;
      end;

      SDLK_F1:
      begin
        strInput := 'F1';
        blOK     := True;
      end;

      SDLK_F2:
      begin
        strInput := 'F2';
        blOK     := True;
      end;

      SDLK_F3:
      begin
        strInput := 'F3';
        blOK     := True;
      end;

      SDLK_F4:
      begin
        strInput := 'F4';
        blOK     := True;
      end;

      SDLK_F5:
      begin
        strInput := 'F5';
        blOK     := True;
      end;

      SDLK_F6:
      begin
        strInput := 'F6';
        blOK     := True;
      end;

      SDLK_F7:
      begin
        strInput := 'F7';
        blOK     := True;
      end;

      SDLK_F8:
      begin
        strInput := 'F8';
        blOK     := True;
      end;

      SDLK_F9:
      begin
        strInput := 'F9';
        blOK     := True;
      end;

      SDLK_F10:
      begin
        strInput := 'F10';
        blOK     := True;
      end;

      SDLK_F11:
      begin
        strInput := 'F11';
        blOK     := True;
      end;

      SDLK_F12:
      begin
        strInput := 'F12';
        blOK     := True;
      end;

    end;

    if chNumPad <> '' then
      if length(strInput) < 1 then
      begin
        strInput := strInput + chNumPad;
        //if message<>' ' then
        //ShowMessage(message, false);
        blOK     := True;
      end;

    if (k > 31) and (k < 127) then
      if length(strInput) < 1 then
      begin
        strInput := strInput + chr(k);
        //if message<>' ' then
        //ShowMessage(message, false);
        blOK     := True;
      end;

    if (pressanykey = True) and (k <> 13) and (k <> 32) then
      blOK := False;


    //         delay(10);

  until (blOK = True);

  GetKeyInput := strInput;
  LastMessage := '-';
end;


end.
