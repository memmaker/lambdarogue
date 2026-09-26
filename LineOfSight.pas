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

unit LineOfSight;


interface

uses
  Constants, RandomArea, Crt, SysUtils, CollectData;

procedure SetVisible;


implementation

uses
  Player;

function GetSlopeStd(x1, y1, x2, y2: single): single;
begin
  GetSlopeStd := (x1 - x2) / (y1 - y2);
end;

function GetSlopeInv(x1, y1, x2, y2: single): single;
begin
  GetSlopeInv := (y1 - y2) / (x1 - x2);
end;

function GetVisDistance(x1, y1, x2, y2: integer): integer;
begin
  GetVisDistance := (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
end;


procedure RecursiveVisibility(xpos1, ypos1: integer; oct, depth: integer;
  slopeA, slopeB: single);
var
  x, y:   integer;
  mv, mw: integer;
begin

  case oct of
    1:
    begin
      y  := ypos1 - depth;
      { initialize y }
      x  := round(xpos1 - slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeStd(x, y, xpos1, ypos1) >= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if (DngLvl[x, y].intIntegrity > 0) then
          begin             { if obstruction }
            if (DngLvl[x - 1, y].intIntegrity = 0) then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 1,
                depth + 1, slopeA, GetSlopeStd(x - 0.5, y + 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if (DngLvl[x - 1, y].intIntegrity > 0) then
            begin       { if prior obstruction }
              slopeA := GetSlopeStd(x - 0.5, y - 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                           { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Inc(x);
      end;
      Dec(x);
    end;
    2:
    begin
      y  := ypos1 - depth;
      { initialize y }
      x  := round(xpos1 - slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeStd(x, y, xpos1, ypos1) <= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if DngLvl[x, y].intIntegrity > 0 then
          begin             { if obstruction }
            if DngLvl[x + 1, y].intIntegrity = 0 then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 2,
                depth + 1, slopeA, GetSlopeStd(x + 0.5, y + 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if DngLvl[x + 1, y].intIntegrity > 0 then
            begin       { if prior obstruction }
              slopeA := GetSlopeStd(x + 0.5, y - 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                         { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Dec(x);
      end;
      Inc(x);
    end;
    3:
    begin
      x  := xpos1 + depth;
      { initialize y }
      y  := round(ypos1 + slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeInv(x, y, xpos1, ypos1) <= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if DngLvl[x, y].intIntegrity > 0 then
          begin             { if obstruction }
            if DngLvl[x, y - 1].intIntegrity = 0 then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 3,
                depth + 1, slopeA, GetSlopeInv(x - 0.5, y - 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if DngLvl[x, y - 1].intIntegrity > 0 then
            begin       { if prior obstruction }
              slopeA := GetSlopeInv(x + 0.5, y - 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                             { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Inc(y);
      end;
      Dec(y);
    end;
    4:
    begin
      x  := xpos1 + depth;
      { initialize y }
      y  := round(ypos1 + slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeInv(x, y, xpos1, ypos1) >= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if DngLvl[x, y].intIntegrity > 0 then
          begin             { if obstruction }
            if DngLvl[x, y + 1].intIntegrity = 0 then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 4,
                depth + 1, slopeA, GetSlopeInv(x - 0.5, y + 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if DngLvl[x, y + 1].intIntegrity > 0 then
            begin       { if prior obstruction }
              slopeA := GetSlopeInv(x + 0.5, y + 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                            { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Dec(y);
      end;
      Inc(y);
    end;
    5:
    begin
      y  := ypos1 + depth;
      { initialize y }
      x  := round(xpos1 + slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeStd(x, y, xpos1, ypos1) >= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if DngLvl[x, y].intIntegrity > 0 then
          begin             { if obstruction }
            if DngLvl[x + 1, y].intIntegrity = 0 then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 5,
                depth + 1, slopeA, GetSlopeStd(x + 0.5, y - 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if DngLvl[x + 1, y].intIntegrity > 0 then
            begin       { if prior obstruction }
              slopeA := GetSlopeStd(x + 0.5, y + 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                            { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Dec(x);
      end;
      Inc(x);
    end;
    6:
    begin
      y  := ypos1 + depth;
      { initialize y }
      x  := round(xpos1 + slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeStd(x, y, xpos1, ypos1) <= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if DngLvl[x, y].intIntegrity > 0 then
          begin             { if obstruction }
            if DngLvl[x - 1, y].intIntegrity = 0 then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 6,
                depth + 1, slopeA, GetSlopeStd(x - 0.5, y - 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if DngLvl[x - 1, y].intIntegrity > 0 then
            begin       { if prior obstruction }
              slopeA := GetSlopeStd(x - 0.5, y + 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                              { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Inc(x);
      end;
      Dec(x);
    end;
    7:
    begin
      x  := xpos1 - depth;
      { initialize y }
      y  := round(ypos1 - slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeInv(x, y, xpos1, ypos1) <= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if DngLvl[x, y].intIntegrity > 0 then
          begin             { if obstruction }
            if DngLvl[x, y + 1].intIntegrity = 0 then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 7,
                depth + 1, slopeA, GetSlopeInv(x + 0.5, y + 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if DngLvl[x, y + 1].intIntegrity > 0 then
            begin       { if prior obstruction }
              slopeA := GetSlopeInv(x - 0.5, y + 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                              { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Dec(y);
      end;
      Inc(y);
    end;
    8:
    begin
      x  := xpos1 - depth;
      { initialize y }
      y  := round(ypos1 - slopeA * depth);
      { initialize z }
      mv := CollectLight(x, y);
      mw := mv * mv;

      while GetSlopeInv(x, y, xpos1, ypos1) >= slopeB do
      begin            { while in octant }
        if GetVisDistance(x, y, xpos1, ypos1) <= mw then
        begin            { if within max visual range }
          if DngLvl[x, y].intIntegrity > 0 then
          begin             { if obstruction }
            if DngLvl[x, y - 1].intIntegrity = 0 then
            begin   { if no prior obstruction }
              RecursiveVisibility(xpos1, ypos1, 8,
                depth + 1, slopeA, GetSlopeInv(x + 0.5, y - 0.5, xpos1, ypos1));
            end; { ^create recursive scan }
          end
          else
          begin                                                { no obstruction }
            if DngLvl[x, y - 1].intIntegrity > 0 then
            begin       { if prior obstruction }
              slopeA := GetSlopeInv(x - 0.5, y - 0.5, xpos1, ypos1);
              { adjust slope for later recursion }
            end;
          end;
          //          Visible[x, y] := 1;                              { set block visible }
          DngLvl[x, y].blLOS   := True;
          DngLvl[x, y].blKnown := True;
        end;
        Inc(y);
      end;
      Dec(y);
    end;
  end;

  if (depth < mv) and (DngLvl[x, y].intIntegrity = 0) then
  begin   { break/continue }
    RecursiveVisibility(xpos1, ypos1, oct, depth + 1, slopeA, slopeB);
  end;
end;



// Sets what the player can and cannot see
procedure SetVisible;
var
  xpos, ypos, i, j: integer;
begin

  xpos := ThePlayer.intX;
  ypos := ThePlayer.intY;

  for i := 1 to DngMaxWidth do
    for j := 1 to DngMaxHeight do
      DngLvl[i, j].blLOS := False;

  // Now work out what should be visible, one octant at a time.
  RecursiveVisibility(xpos, ypos, 1, 1, 1, 0);
  RecursiveVisibility(xpos, ypos, 6, 1, -1, 0);
  RecursiveVisibility(xpos, ypos, 8, 1, 1, 0);
  RecursiveVisibility(xpos, ypos, 7, 1, -1, 0);
  RecursiveVisibility(xpos, ypos, 2, 1, -1, 0);
  RecursiveVisibility(xpos, ypos, 5, 1, 1, 0);
  RecursiveVisibility(xpos, ypos, 3, 1, -1, 0);
  RecursiveVisibility(xpos, ypos, 4, 1, 1, 0);

  DngLvl[xpos, ypos].blLOS   := True;
  DngLvl[xpos, ypos].blKnown := True;
end;

end.
