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

unit GFX;

interface

uses
  WebBE, BaseOutput, SysUtils, RandomArea, Constants, ExternSFX;

var
  MessageLogFile: Textfile;



procedure BlendTitleSurface(blend: boolean);
procedure SlowBlendTitleSurface;
procedure BlendMagic(n: integer);
procedure Meteor;


procedure ShowMonsterSpell(n, x, y: integer);
procedure ShowExplosion(x, y: integer);
procedure ShowTrapEffect(x, y: integer);
procedure CreateBlood(x, y: integer);
procedure DarkenScreen;
procedure TrembleScreen;




implementation

procedure BlendTitleSurface(blend: boolean);
var
  i: integer;
  BlitRect: SDL_RECT;
begin
  if UseSDL = True then
  begin
    if UseHiRes=true then
    begin
      BlitRect.w := 1024;
      BlitRect.h := 0;
      BlitRect.x := 0;
      BlitRect.y := 0;
    end
    else
    begin
      BlitRect.w := 800;
      BlitRect.h := 0;
      BlitRect.x := 0 + HiResOffsetX;
      BlitRect.y := 0 + HiResOffsetY;
    end;

    if blend = True then
    begin
      for i := 0 to 40 do
      begin
        SDL_SETALPHA(title, SDL_SRCALPHA, i);
        SDL_BLITSURFACE(title, nil, screen, @BlitRect);
        SDL_UPDATERECT(screen, 0, 0, 0, 0);
        delay(10);
      end;
    end
    else
    begin
      SDL_BLITSURFACE(title, nil, screen, @BlitRect);
      SDL_UPDATERECT(screen, 0, 0, 0, 0);
    end;
  end;
end;


procedure SlowBlendTitleSurface;
var
  i: integer;
  BlitRect: SDL_RECT;
begin
  if UseSDL = True then
  begin
    if UseHiRes=true then
    begin
      BlitRect.w := 1024;
      BlitRect.h := 0;
      BlitRect.x := 0;
      BlitRect.y := 0;
    end
    else
    begin
      BlitRect.w := 800;
      BlitRect.h := 0;
      BlitRect.x := 0 + HiResOffsetX;
      BlitRect.y := 0 + HiResOffsetY;
    end;

    for i := 0 to 40 do
    begin
      SDL_SETALPHA(title, SDL_SRCALPHA, i);
      SDL_BLITSURFACE(title, nil, screen, @BlitRect);
      SDL_UPDATERECT(screen, 0, 0, 0, 0);
      delay(30);
    end;
  end;
end;


procedure BlendMagic(n: integer);
var
  i:      integer;
  strSub: string;
begin
  if UseSDL = True then
  begin
    if UseHiRes = False then
      strSub := '/800x600/'
    else
      strSub := '/1024x768/';

    case n of
      1:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-fire.png');
      2:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-ice.png');
      3:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-water.png');
      4:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-poison.png');
      5:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-bless.png');
      6:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-heal.png');
      7:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-pp.png');
      8:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-curse.png');
      9:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-barrier.png');
      10:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-confusion.png');
      11:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-blind.png');
      12:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-para.png');
      13:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-force.png');
      14:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-healaura.png');
      15:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-fireatt.png');
      16:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-iceatt.png');
      17:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-wateratt.png');
      18:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-meteor.png');
      19:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-lichtbringer.png');
      20:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-spiderweb.png');
      21:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-copyrin.png');
      22:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-elect.png');
      23:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-electatt.png');
      24:
        LoadImage_Back('graphics/fx' + strSub + 'sfx-poisonatt.png');
    end;

    for i := 0 to 5 do
    begin
      SDL_SETALPHA(backgroundGraph, SDL_SRCALPHA, i);
      SDL_BLITSURFACE(backgroundGraph, nil, screen, nil);
      SDL_UPDATERECT(screen, 0, 0, 0, 0);
      delay(30);
    end;
    if UseHiRes = False then
      LoadImage_Back('graphics/bg-800.png')
    else
      LoadImage_Back('graphics/bg-1024.png');
  end;
end;


// Meteor
procedure Meteor;
begin
  PlaySFX('magic-time.mp3');
  BlendMagic(11);
  BlendMagic(18);
end;


// show the spell of a monster
procedure ShowMonsterSpell(n, x, y: integer);
var
  ch1, ch2: char;
  intY:     integer;
begin
  case n of
    // fire
    1:
    begin
      ch1 := chr(130);
      ch2 := chr(131);
    end;

    // ice
    2:
    begin
      ch1 := chr(132);
      ch2 := chr(133);
    end;

    // water
    3:
    begin
      ch1 := chr(195);
      ch2 := chr(133);
    end;

    // electricity
    4:
    begin
      ch1 := chr(36);
      ch2 := chr(36);
    end;
  end;

  if n < 5 then
  begin

    if UseSDL = True then
      intY := y + 1
    else
      intY := y;

    AnyCharXY(x, intY, ch1, 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);
    delay(trunc(random(80)) + 50);

    AnyCharXY(x, intY, ch2, 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);
    delay(trunc(random(80)) + 50);

    AnyCharXY(x, intY, chr(179), 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);
  end;
end;

// show explosion
procedure ShowExplosion(x, y: integer);
var
  i: integer;
begin
  for i := 1 to 6 do
  begin
    AnyCharXY(x, y, chr(130), 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);

    delay(10);

    AnyCharXY(x, y, chr(131), 0);
    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);
  end;
end;


// show trap
procedure ShowTrapEffect(x, y: integer);
begin
  if UseSDL = True then
    ShowExplosion(x, y + 1)
  else
    ShowExplosion(x, y);
end;

// randomly creates blood
procedure CreateBlood(x, y: integer);
begin
  if DngLvl[x, y].intAirType = 0 then
    DngLvl[x, y].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x - 1, y].intAirType = 0) and
    (DngLvl[x - 1, y].intFloorType <> 3) and (DngLvl[x - 1, y].intFloorType <> 4) and
    (DngLvl[x - 1, y].intIntegrity = 0) then
    DngLvl[x - 1, y].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x + 1, y].intAirType = 0) and
    (DngLvl[x + 1, y + 1].intFloorType <> 3) and
    (DngLvl[x + 1, y + 1].intFloorType <> 4) and (DngLvl[x + 1, y].intIntegrity = 0) then
    DngLvl[x + 1, y].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x, y + 1].intAirType = 0) and
    (DngLvl[x, y + 1].intFloorType <> 3) and (DngLvl[x, y + 1].intFloorType <> 4) and
    (DngLvl[x, y + 1].intIntegrity = 0) then
    DngLvl[x, y + 1].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x, y - 1].intAirType = 0) and
    (DngLvl[x, y - 1].intFloorType <> 3) and (DngLvl[x, y - 1].intFloorType <> 4) and
    (DngLvl[x, y - 1].intIntegrity = 0) then
    DngLvl[x, y - 1].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x - 1, y - 1].intAirType = 0) and
    (DngLvl[x - 1, y - 1].intFloorType <> 3) and
    (DngLvl[x - 1, y - 1].intFloorType <> 4) and
    (DngLvl[x - 1, y - 1].intIntegrity = 0) then
    DngLvl[x - 1, y - 1].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x + 1, y + 1].intAirType = 0) and
    (DngLvl[x + 1, y + 1].intFloorType <> 3) and
    (DngLvl[x + 1, y - 1].intFloorType <> 4) and
    (DngLvl[x + 1, y - 1].intIntegrity = 0) then
    DngLvl[x + 1, y - 1].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x - 1, y + 1].intAirType = 0) and
    (DngLvl[x - 1, y + 1].intFloorType <> 3) and
    (DngLvl[x - 1, y + 1].intFloorType <> 4) and
    (DngLvl[x - 1, y + 1].intIntegrity = 0) then
    DngLvl[x - 1, y + 1].blBlood := True;
  if (random(500) > CONST_BLOOD) and (DngLvl[x + 1, y - 1].intAirType = 0) and
    (DngLvl[x + 1, y - 1].intFloorType <> 3) and
    (DngLvl[x + 1, y - 1].intFloorType <> 4) and
    (DngLvl[x + 1, y - 1].intIntegrity = 0) then
    DngLvl[x + 1, y - 1].blBlood := True;
end;

procedure DarkenScreen;
var
  BlitRect: SDL_RECT;
begin
  if UseSDL=true then
  begin
    LoadImage_Title('graphics/dark.png');
    BlitRect.w := 1024;
    BlitRect.h := 0;
    BlitRect.x := 0;
    BlitRect.y := 0;
    SDL_BLITSURFACE(title, nil, screen, @BlitRect);
  end;
end;

procedure TrembleScreen;
var
  BlitRect: SDL_RECT;
  i: integer;
begin
  if UseSDL=true then
  begin
  SDL_FREESURFACE(title);
    title := screen;

    if UseHiRes = True then
    begin
      BlitRect.w := 1024;
      BlitRect.h := 768;
    end
    else
    begin
      BlitRect.w := 800;
      BlitRect.h := 600;
    end;

    for i := 1 to 10 do
    begin
      BlitRect.x := trunc(random(20));
      BlitRect.y := trunc(random(20));
      SDL_BLITSURFACE(title, nil, screen, @BlitRect);
      SDL_UPDATERECT(screen, 0, 0, 0, 0);
      delay(20);
      //ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;
  end;
end;

end.
