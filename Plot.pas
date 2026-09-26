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

unit Plot;


interface

uses
  Constants, SDL, Crt, SysUtils, StrUtils, RandomArea, Player, BaseOutput, GFX, UserInterface, DrawDungeon, Input;

procedure OutputPlot(strPlotfile: string);
procedure ShowDialog (name, a, b, c, d, e: string; wait: boolean);
procedure ShowPlot(part: integer);
procedure ShowText(strTextfile: string);
procedure ShowIntro;
procedure ShowEnding(blEvilEnding: boolean);

implementation


procedure OutputPlot(strPlotfile: string);
var
  PlotFile: Textfile;
  z, k:     integer;
  zeile, s: string;
begin

  if (ThePlayer.blCoffeeBreak=true) and (LeftStr(strPlotFile, 5)<> 'help_') then
    exit;


  if UseSDL = True then
  begin
    LoadImage_Title('graphics/txtbg.jpg');
    BlitImage_Title;
  end
  else
    ClearScreenSDL;

  if fileexists(CONST_DATADIR + 'data/story/' + strPlotfile + '.txt') = True then
  begin
    Assign(PlotFile, CONST_DATADIR + 'data/story/' + strPlotfile + '.txt');
    Reset(PlotFile);

    z     := 0;
    zeile := '';
    while EOF(PlotFile) = False do
    begin
      Inc(z);
      ReadLn(PlotFile, zeile);
      TransTextXY(1, z, zeile);
    end;
    Close(PlotFile);
  end
  else
  begin
    TransTextXY(1, 1, '[Warning: File '+CONST_DATADIR + 'data/story/' + strPlotfile + '.txt" not found!]');
  end;

  if UseSDL = False then
    GlobalConColor := darkgray;

  if UseSDL=True then
  begin
    TransTextXY(1, 28, '[SPACE] or [Enter] to continue');
    SDL_UPDATERECT(screen, 0, 0, 0, 0);
    k := 0;
    repeat
        if SDL_POLLEVENT(@MyEvent) > 0 then
          case MyEvent.type_ of
            SDL_KEYDOWN:
              k := cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);

          end;
    until (k = 13) or (k = 32);
  end
  else
  repeat
    s:=GetKeyInput('[SPACE] or [Enter] to continue', false);
  until (s='ENTER') or (s='SPACE');

  LastMessage := '-';
  if UseSDL = False then
    GlobalConColor := white;
end;


procedure ShowPlot(part: integer);
begin
  if ThePlayer.blStory[part] = False then
  begin
    OutputPlot(IntToStr(part));
    ThePlayer.blStory[part] := True;
    ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
  end;
end;


procedure ShowDialog (name, a, b, c, d, e: string; wait: boolean);
var
  s: string;
  k: integer;
begin
  if UseSDL=true then
  begin

    DarkenScreen;

    if fileexists(CONST_DATADIR + 'graphics/portraits/'+ name + '.png') then
      LoadImage_Title('graphics/portraits/'+ name + '.png')
    else
      LoadImage_Title('graphics/portraits/empty.png');

    BlitImage_Title;

    if name<>'-' then
    begin
      if (name<>'ARES') and (name<>'DIONYSA') and (name<>'HERMES') and (name<>'APOLL') and (name<>'ERIS') and (name<>'APHRODITE') then
        TransTextXY(1, 20, 'TALKING TO ' + name)
      else
        TransTextXY(1, 20, 'RECEIVING A VISION FROM ' + name);
    end;

    TransTextXY(1, 22, a);
    TransTextXY(1, 23, b);
    TransTextXY(1, 24, c);
    TransTextXY(1, 25, d);
    TransTextXY(1, 26, e);

    s:='-';
    if wait=true then
    begin
      TransTextXY(1, 28, '[SPACE] or [Enter] to continue');
      SDL_UPDATERECT(screen, 0, 0, 0, 0);
      k := 0;
      repeat
        if SDL_POLLEVENT(@MyEvent) > 0 then
          case MyEvent.type_ of
            SDL_KEYDOWN:
              k :=
                cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
          end
      until (k = 13) or (k = 32);
    end;
  end
  else
  begin
    ClearScreenSDL;
    StatusDeco;

    if name<>'-' then
    begin
      if (name<>'ARES') and (name<>'DIONYSA') and (name<>'HERMES') and (name<>'APOLL') and (name<>'ERIS') and (name<>'APHRODITE') then
        TransTextXY(1, 1, 'TALKING TO ' + name)
      else
        TransTextXY(1, 1, 'RECEIVING A VISION FROM ' + name);
    end;

    TransTextXY(1, 3, a);
    TransTextXY(1, 4, b);
    TransTextXY(1, 5, c);
    TransTextXY(1, 6, d);
    TransTextXY(1, 7, e);

    s:='-';
    if wait=true then
    repeat
      s:=GetKeyInput('[SPACE] or [Enter] to continue', false);
    until (s='ENTER') or (s='SPACE');
  end;

end;

procedure ShowText(strTextfile: string);
var
  t: ansistring;
  k: integer;
begin
  if strTextfile = '-' then
    GetKeyInput('There is nothing to read on it.', True)
  else
  begin
    ClearScreenSDL;

    // show texts beginning with "chapter" or "interlude" as graphic
    if ((UseSDL = True) and ((NPos('chapter', strTextfile, 1) = 1) or (NPos('interlude', strTextfile, 1) = 1))) then
    begin

      if UseHiRes=true then
        t := 'graphics/chapters/' + strTextFile + '-1024.jpg'
      else
        t := 'graphics/chapters/' + strTextFile + '-800.jpg';

      LoadImage_Title(t);

      BlendTitleSurface(True);
      k := 0;
      repeat
        if SDL_POLLEVENT(@MyEvent) > 0 then
          case MyEvent.type_ of
            SDL_KEYDOWN:
              k :=
                cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
          end
      until (k = 13) or (k = 32);
      if ThePlayer.intSex = 1 then
        t := 'graphics/' + IntToStr(ThePlayer.intProf) + '-m.jpg'
      else
        t := 'graphics/' + IntToStr(ThePlayer.intProf) + '-f.jpg';
      LoadImage_Title(t);
      ClearScreenSDL;
    end
    else
    begin
      OutputPlot('books/' + strTextfile);
      if UseSDL = False then
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;
  end;
end;

procedure ShowIntro;
var
  i, k: integer;
  t: ansistring;
begin

  if UseSDL=false then
  begin
    OutputPlot('intro-1');
    OutputPlot('intro-2');
  end
  else
  begin
    for i:=1 to 15 do
    begin
        if UseHiRes=true then
          t := 'graphics/chapters/intro-' + IntToStr(i) + '-1024.jpg'
        else
          t := 'graphics/chapters/intro-' + IntToStr(i) + '-800.jpg';
        LoadImage_Title(t);
        SlowBlendTitleSurface;

        TransTextXY(1 + HiResTextOffsetX, 29 + HiResTextOffsetY, '[ESC] Skip   [SPACE] Continue');
        SDL_UPDATERECT(screen, 0, 0, 0, 0);

        k := 0;
        repeat
          if SDL_POLLEVENT(@MyEvent) > 0 then
            case MyEvent.type_ of
              SDL_KEYDOWN:
                k :=
                  cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
            end
        until (k = 13) or (k = 32) or (k = 27);

        if k=27 then
          break;
    end;
  end;
end;


procedure ShowEnding(blEvilEnding: boolean);
var
  i, k: integer;
  t, e: ansistring;
begin

  if blEvilEnding=true then
    e:='evil-'
  else
    e:='good-';

  if (UseSDL=false) or (e='evil-') then
  begin
    if e= 'good' then
    begin
      OutputPlot(e + 'ending-1');
      OutputPlot(e + 'ending-2');
      OutputPlot(e + 'ending-3');
    end
    else
    begin
      OutputPlot(e + 'ending-1');
      OutputPlot(e + 'ending-2');
    end;
  end
  else
  begin
    for i:=1 to 12 do
    begin
      if UseHiRes=true then
        t := 'graphics/chapters/ending-' + e + IntToStr(i) + '-1024.jpg'
      else
        t := 'graphics/chapters/ending-' + e + IntToStr(i) + '-800.jpg';
      LoadImage_Title(t);
      SlowBlendTitleSurface;

      TransTextXY(1 + HiResTextOffsetX, 29 + HiResTextOffsetY, '[ESC] Skip   [SPACE] Continue');
      SDL_UPDATERECT(screen, 0, 0, 0, 0);

      k := 0;
      repeat
        if SDL_POLLEVENT(@MyEvent) > 0 then
          case MyEvent.type_ of
            SDL_KEYDOWN:
              k :=
                cookKey(MyEvent.key.keysym.unicode, MyEvent.key.keysym.sym);
          end
      until (k = 13) or (k = 32) or (k = 27);

      if k=27 then
        break;
    end;
  end;

end;


end.
