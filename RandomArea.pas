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

unit RandomArea;


interface

uses
  WebBE, SysUtils;

type
  DngTile = record
    intFloorType: shortint;    // free space, water, wall etc.
    intAirType: shortint;
    intAirRange: integer;
    intIntegrity: integer;
    // for walls, rocks etc: 100 = solid, 0 = destroyed; reduced through digging etc.
    intLight: integer;
    intItem: integer;    // treasure
    intBuilding: shortint;
    blKnown: boolean;
    blBlood: boolean;
    blTown: boolean;
    blLOS:  boolean;
  end;

var

  TilesetASCII, TilesetGraph, extratiles: pSDL_SURFACE;
  title, screen, backgroundASCII, backgroundGraph, dialogbg, graytrans: pSDL_SURFACE;


  DngLvl:      array[1..200, 1..200] of DngTile;
  DungeonLevel, HiResOffsetX, HiResOffsetY, HiResTextOffsetX,
  HiResTextOffsetY: integer;
  UnX, UnY: integer;
  intDay, intDayTime, ChantBarX, ChantBarY: integer;
  longYear, longTotalTurns: longint;
  UseSDL, UseOldSmallTiles, UseNewInventory, GrowingMonsters, AutoMoveToTile,
  UseSmallTiles, UseFullScreen, UseHiRes: boolean;
  KeyLook, KeyHelp, KeyRest, KeyShortRest, KeyPray, KeyShoot,
  KeyGammaPlus, KeyBigMap, KeyThrow, KeyTactics: char;
  KeyEnter, KeyTrade, KeyCloseDoor, KeyTunnel, KeyTake, KeySearchSteal,
  KeySetQuickKeys: char;
  KeyInventory, KeyChant, KeyStatus, KeyNorth, KeySouth, KeyEast,
  KeyWest, KeyChantLast: char;
  KeyNorthEast, KeySouthEast, KeyNorthWest, KeySouthWest, KeyQuit,
  KeyNewInventory, KeyQuestlog, KeySpecial, KeySpecialDiv: char;
  ShowBlood, UseMouseToMove, MoveOneTilePerClick, blTodayStolenTrader,
  blTodayStolenNPC, Netbook: boolean;
  HiveX, HiveY, DownX, DownY, UpX, UpY, Difflevel, LastSong, GlobalConColor: integer;
  LastMessage: string;

  blQuit, blWon, blHalt, blStartGame, blPlayPrologue: boolean;

  blShopStolen:   array[1..8] of boolean;
  strQuickKey:    array[1..12] of string;
  strDiplomaList: array[1..30] of string;
  intNoHivesAnymore: array[1..30] of shortint;

  PixelWhiteRect, PixelGreyRect, PixelRedRect, PixelBlueRect, PaperPos,
  StairPos, TraderPos: SDL_Rect;
  PixelOrangeRect, PixelGreenRect, PixelBrownRect, PlotRect,
  PlayerRect, NPCPos, PlayerPos: SDL_Rect;




implementation



end.
