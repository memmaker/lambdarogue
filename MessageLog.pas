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

unit MessageLog;

interface

uses
  SDL, Crt, Video, SysUtils, RandomArea, BaseOutput;

var
    strMessageLog: array [1..20] of string; // contains the last 20 messages

procedure ShortMessageLog;
procedure StoreMessageInLog(strMessage: string);
procedure ShowTransMessage(strMessage: string; pressanykey: boolean);



implementation

procedure ShortMessageLog;
var
  i, s, z, l: integer;
begin

  // find last message (which is first message to display)
  for i := 1 to 20 do
  begin
    s := i;
    if strMessageLog[i] = '-' then
    begin
      s := i - 1;
      break;
    end;
  end;

  // find message two steps before last message (which is last message to display)
  if s > 2 then
    z := s - 2
  else
    z := 1;

  if UseSDL = True then
  begin

    if UseHiRes=true then
      l := 47
    else
      l := 33;

    if s <= 7 then
      z:=1
    else
      z:=s-7;

    for i := z to s do
    begin

      GlobalSmallOpac := 1;

      if ((UseHiRes=true) and (l=47)) or ((UseHiRes=false) and (l=33)) then
        GlobalSmallOpac:=5;

      if ((UseHiRes=true) and (l=48)) or ((UseHiRes=false) and (l=34)) then
        GlobalSmallOpac:=4;

      if ((UseHiRes=true) and (l=49)) or ((UseHiRes=false) and (l=35)) then
        GlobalSmallOpac:=3;

      if strMessageLog[i] <> '-' then
        SmallTextXY (1, l, strMessageLog[i], true, false);
        //TransTextXY(1 + HiResTextOffsetX, l + HiResTextOffsetY, strMessageLog[i]);

      Inc(l);
    end;
  end
  else
  begin
    l := 22;
    for i := z to s do
    begin
      if strMessageLog[i] <> '-' then
        TransTextXY(1, l, strMessageLog[i]);
      Inc(l);
    end;
  end;

  GlobalSmallOpac:=1;

end;

procedure StoreMessageInLog(strMessage: string);
var
  i: integer;
  blStored: boolean;
begin
  blStored := False;
  for i := 1 to 20 do
    if strMessageLog[i] = '-' then
      if blStored = False then
      begin
        strMessageLog[i] := strMessage;
        blStored := True;
        break;
      end;

  if blStored = False then
  begin
    for i := 1 to 19 do
      strMessageLog[i] := strMessageLog[i + 1];
    strMessageLog[20]  := strMessage;
  end;
end;

// show a transparent message (calls TransTextXY)
procedure ShowTransMessage(strMessage: string; pressanykey: boolean);
var
  intMY: integer;
begin
  if UseHiRes = False then
    intMY := 27
  else
    intMY := 27;

  //TextXY(1,27,'                                                                            ');

  // save message in message history
  if length(strMessage) > 1 then
    StoreMessageInLog(strMessage);

  //TransTextXY(1,27, strMessage);
  if pressanykey = True then
  begin
    //TextXY(1,28,'                                                                            ');
    if (UseSDL = True) and (UseMouseToMove = True) then
      TransTextXY(34, intMY + 1, ' [Right-click, SPACE or ENTER to continue]')
    else
      TransTextXY(48, intMY + 1, ' [SPACE or ENTER to continue]');

    if UseSDL = True then
      SDL_UPDATERECT(screen, 0, 0, 0, 0)
    else
      UpdateScreen(True);
  end;
  LastMessage := strMessage;

end;

end.