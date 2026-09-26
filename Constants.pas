{
     Copyright (C) 2006-2009 by Mario Donick
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

unit Constants;

interface

uses
  Crt, Classes, SysUtils;

const


  strVersion = '1.6.4';

  WinLevel = 27;
  // determines how many DLVs will be generated and accessed by all other functions


  DngMaxWidth = 70;
  DngMaxHeight = 70;

  // The following constants influence some balancing issues
  CONST_MONSTERDROPSITEM = 450;    // decrease to let monsters drop items more often
  CONST_MAXKILLEDFORDROP = 50;    // increase to let monsters drop items longer

  CONST_CHESTISEMPTY = 550;        // increase to have less empty chests
  CONST_BATTLEEXP    = 30;         // EXP = 30% of HP
  CONST_BATTLEEXP_REDUCED = 20;    // EXP = 20% of HP (for class 1 characters)
  CONST_SPELLRATE    = 1480;
  // determines if a spell succeeds. increase to let more spells fail. (max. is 1498)
  CONST_LONGRANGE_HITRATE = 10;
  // if random(CONST_LONGRANGE_HITRATE)>ThePlayer.intView, then the attack misses
  // decrease to let more shoots succeed

  CONST_INSURANCE_DLV  = 16;
  // factor by which (WinLevel-DungeonLevel) is multiplied for insurance price
  CONST_INSURANCE_BASE = 3;
  // insurance price is (WINLEVEL-DUNGEONLEVEL)*INSURANCE_DLV + (GOLD/INSURANCE_BASE)

  CONST_CHANCE_FOR_GOOD_HIT = 250;  // decrease to have more good hits
  CONST_BADHITLUCK = 380;           // decrease to make more hits miss

  CONST_GOLDWOOD     = 1;        // basic price for resource "wood"
  CONST_GOLDMETAL    = 3;        // basic price for resource "metal"
  CONST_GOLDSTONE    = 1;        // basic price for resource "stone"
  CONST_GOLDLEATHER  = 2;        // basic price for resource "leather"
  CONST_GOLDPLASTICS = 1;        // basic price for resource "plastics"
  CONST_GOLDPAPER    = 2;        // basic price for resource "paper"

  CONST_PRAYERSNEEDEDFORBLESS = 5431;
  // number of times a player has to pray until he gets blessed by his god
  CONST_MINTURNFORCURSE    = 2500;
  // when in this turn the player has not prayed at least one time, the god will curse him
  CONST_MINPRAYERSFORBONUS = 1500; // min. numbers of prayers for bonus

  CONST_BEATTHISFORTRAPDOOR = 9985;
  // if this number is beaten, the player will fall down to the next lvl

  CONST_BEATTHISFORQUAKE = 9970;
  // if this number is beaten, an earthquake will occur

  CONST_BEATTHISFORITEM = 850;
  // if this number is beaten, digging reveals a rare item

  // constants affecting balancing
  CONST_STRONGMONSTERS = 200;
  // how often will normal monsters replaced by stronger variants?

  CONST_MONSTER_DLV_DIFF = 2;
  // example: when we are in DLV 8, also monsters from the
  // CONST_MONSTER_DLV_DIFF former levels may appear

  CONST_BLOOD = 450; // increase (max. 500) to reduce blood

  CONST_SECRETSEARCH = 440;  // increase to make finding secret doors harder
  CONST_SAFEBURGLE   = 1900; // increase to let more stealing attempts fail

  CONST_MONSTERISFASTER = 300;
  // has the monster a higher move value than the player? decrease for faster monsters.
  CONST_INC_MONSTERMOVE = 5;
  // how many points does a monster without individual move value gets?
  CONST_DEC_MONSTERMOVE = 3;
  // how many points does a monster without individual move value lose?

  CONST_HP_MULTI = 19;    // multiplier for HP during levelup
  CONST_PP_MULTI = 12;    // multiplier for PP during levelup

  CONST_LVL_MULTI = 4;    // multiplier for level up

  CONST_MAXCLV = 20;      // max. character level

  CONST_FAMILIARTERRAINBONUS = 2;  // bonus for familiar terrain

  CONST_ITEMBURNCHANCE = 450;  // if this number is beaten, random paper item is burned

var
  CONST_DATADIR : ansistring;

procedure SetDataDirPath;


implementation

{$IFDEF Darwin}
uses
{$ifdef ver2_2_0}
  FPCMacOSAll;
{$else}
  MacOSAll;
{$endif}
{$ENDIF}

procedure SetDataDirPath;
const
  BundleResourceFolder = '/Contents/Resources/';
var
  debugfile: textfile;
{$IFDEF Darwin}
  pathRef: CFURLRef;
  pathCFStr: CFStringRef;
  pathStr: shortstring;
{$ENDIF}

begin

  // Under Mac OS X we need to get the location of the bundle
{$IFDEF Darwin}
  pathRef := CFBundleCopyBundleURL(CFBundleGetMainBundle());
  pathCFStr := CFURLCopyFileSystemPath(pathRef, kCFURLPOSIXPathStyle);
  CFStringGetPascalString(pathCFStr, @pathStr, 255, CFStringGetSystemEncoding());
  CFRelease(pathRef);
  CFRelease(pathCFStr);
  CONST_DATADIR := pathStr + BundleResourceFolder;
{$ELSE}
  CONST_DATADIR := '';
{$ENDIF}

(*
Assign(DebugFile, 'debug.txt');
Append(DebugFile);
writeln (DebugFile, 'Pfad: ' + CONST_DATADIR);
Close(DebugFile);
*)

end;

end.
