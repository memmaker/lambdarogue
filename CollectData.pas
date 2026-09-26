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

unit CollectData;

interface

uses
  Constants, Classes, SysUtils, RandomArea, Player, Items;

function ReturnStatusIncRate(intE: integer): integer;
function MaximizedWeaponSkill: boolean;
function CollectTP: integer;
function CollectGunTP: integer;
function CollectThrowTP (t: integer): integer;
function CollectDP: integer;
function CollectBuyPrice(n: integer): integer;
function CollectSellPrice(n: integer): integer;
function CollectLight(sx, sy: integer): integer;
function CollectFight: integer;
function CollectHit: integer;
function CollectMove: integer;
function CollectHumility: integer;
function CollectChant: integer;
function CollectSword: integer;
function CollectGun: integer;
function CollectAxe: integer;
function CollectWhip: integer;

implementation

// returns the total Fight value (base + rank + bonus)
function CollectFight: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intFight); // base fight
  if ReturnStatusIncRate(64)>0 then  // equipment bonus
    inc (t, ReturnStatusIncRate(64));
  if ThePlayer.intTempResist[64]>0 then   // temporary bonus
    inc (t);

  // Set Items
  if CheckForItemSet(3)=true then
    inc (t);
  if CheckForItemSet(4)=true then
    inc (t);

  CollectFight:=t;
end;

// returns the total Fire-arm value (base + rank + bonus)
function CollectGun: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intGun); // base chant

  // if ReturnStatusIncRate(64)>0 then  // equipment bonus
  //  inc (t, ReturnStatusIncRate(64));
  // if ThePlayer.intTempResist[64]>0 then   // temporary bonus
  //  inc (t);

  // Set Items
  if CheckForItemSet(2)=true then
    inc (t);

  CollectGun:=t;
end;

// returns the total Axe value (base + rank + bonus)
function CollectAxe: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intAxe); // base chant

  // if ReturnStatusIncRate(64)>0 then  // equipment bonus
  //  inc (t, ReturnStatusIncRate(64));
  // if ThePlayer.intTempResist[64]>0 then   // temporary bonus
  //  inc (t);

  // Set Items
  //if CheckForItemSet(3)=true then
  //  inc (t);

  CollectAxe:=t;
end;


// returns the total Lance (Whip) value (base + rank + bonus)
function CollectWhip: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intWhip); // base chant

  // if ReturnStatusIncRate(64)>0 then  // equipment bonus
  //  inc (t, ReturnStatusIncRate(64));
  // if ThePlayer.intTempResist[64]>0 then   // temporary bonus
  //  inc (t);

  // Set Items
  //if CheckForItemSet(3)=true then
  //  inc (t);

  CollectWhip:=t;
end;

// returns the total Sword value (base + rank + bonus)
function CollectSword: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intSword); // base chant

  // if ReturnStatusIncRate(64)>0 then  // equipment bonus
  //  inc (t, ReturnStatusIncRate(64));
  // if ThePlayer.intTempResist[64]>0 then   // temporary bonus
  //  inc (t);

  // Set Items
  if CheckForItemSet(3)=true then
    inc (t);

  CollectSword:=t;
end;

// returns the total Chant value (base + rank + bonus)
function CollectChant: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intChant); // base chant

  // if ReturnStatusIncRate(64)>0 then  // equipment bonus
  //  inc (t, ReturnStatusIncRate(64));
  // if ThePlayer.intTempResist[64]>0 then   // temporary bonus
  //  inc (t);

  // Set Items
  if CheckForItemSet(5)=true then
    inc (t);

  CollectChant:=t;
end;

// returns the total Hit value (base + rank + bonus)
function CollectHit: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intView); // base hit
  if ThePlayer.intDipl[17]=1 then  // marksman rank
    inc (t);
  if ReturnStatusIncRate(62)>0 then  // equipment bonus
    inc (t, ReturnStatusIncRate(62));
  if ThePlayer.intTempResist[62]>0 then   // temporary bonus
    inc (t);

  // Set Items
  if CheckForItemSet(2)=true then
    inc (t);
  if CheckForItemSet(5)=true then
    inc (t);

  CollectHit:=t;
end;

// returns the total Hit value (base + rank + bonus)
function CollectMove: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intMove); // base move
  if ThePlayer.intDipl[3]=1 then  // princeps rank
    inc (t);
  if ReturnStatusIncRate(25)>0 then  // equipment bonus
    inc (t, ReturnStatusIncRate(25));
  if ThePlayer.intTempResist[25]>0 then   // temporary bonus
    inc (t);
  if (CheckEffect(54) = True) or (DungeonLevel = ThePlayer.intBirthLevel) then   // familiar terrain
    Inc(t, CONST_FAMILIARTERRAINBONUS);
  CollectMove := t;
end;

// returns the total Hit value (base + rank + bonus)
function CollectHumility: integer;
var
  t: integer;
begin
  t := 0;
  inc(t, ThePlayer.intHumility); // base move
  if ReturnStatusIncRate(65)>0 then  // equipment bonus
    inc (t, ReturnStatusIncRate(65));
  if ThePlayer.intTempResist[65]>0 then   // temporary bonus
    inc (t);

  // Set Items
  if CheckForItemSet(4)=true then
    inc (t);

  CollectHumility := t;
end;


// returns the bonus value of an equipped item
function ReturnStatusIncRate(intE: integer): integer;
var
  t: integer;
begin
  t := 0;
  if ThePlayer.intWeapon > 0 then
    if Thing[ThePlayer.intWeapon].intEffect = intE then
      Inc(t, Thing[ThePlayer.intWeapon].intRange);

  if ThePlayer.intArmour > 0 then
    if Thing[ThePlayer.intArmour].intEffect = intE then
      Inc(t, Thing[ThePlayer.intArmour].intRange);

  if ThePlayer.intHat > 0 then
    if Thing[ThePlayer.intHat].intEffect = intE then
      Inc(t, Thing[ThePlayer.intHat].intRange);

  if ThePlayer.intRingLeft > 0 then
    if Thing[ThePlayer.intRingLeft].intEffect = intE then
      Inc(t, Thing[ThePlayer.intRingLeft].intRange);

  if ThePlayer.intRingRight > 0 then
    if Thing[ThePlayer.intRingRight].intEffect = intE then
      Inc(t, Thing[ThePlayer.intRingRight].intRange);

  if ThePlayer.intFeet > 0 then
    if Thing[ThePlayer.intFeet].intEffect = intE then
      Inc(t, Thing[ThePlayer.intFeet].intRange);

  if ThePlayer.intExtra > 0 then
    if Thing[ThePlayer.intExtra].intEffect = intE then
      Inc(t, Thing[ThePlayer.intExtra].intRange);

  ReturnStatusIncRate := t;
end;


// calculate total DP
function CollectDP: integer;
var
  intDP: integer;
begin
  intDP := ThePlayer.intFight div 4;

  if ThePlayer.intArmour > 0 then
    Inc(intDP, Thing[ThePlayer.intArmour].intAP);

  if ThePlayer.intWeapon > 0 then
    Inc(intDP, Thing[ThePlayer.intWeapon].intAP);

  if ThePlayer.intHat > 0 then
    Inc(intDP, Thing[ThePlayer.intHat].intAP);

  if ThePlayer.intRingLeft > 0 then
    Inc(intDP, Thing[ThePlayer.intRingLeft].intAP);

  if ThePlayer.intRingRight > 0 then
    Inc(intDP, Thing[ThePlayer.intRingRight].intAP);

  if ThePlayer.intFeet > 0 then
    Inc(intDP, Thing[ThePlayer.intFeet].intAP);

  if ThePlayer.intExtra > 0 then
    Inc(intDP, Thing[ThePlayer.intExtra].intAP);

  if ThePlayer.blBlessed = True then
    Inc(intDP);

  if ThePlayer.intDipl[5]=1 then
    if CheckEffect(49)=true then
      Inc(intDP,2)
    else
      Inc(intDP);

  if ThePlayer.blOffensive = false then
    intDP := intDP * 2;

  CollectDP := intDP;
end;

 // returns true if the player's weapon skill is the same or higher than the
 // WP (or GP in case of a firearm) of his current weapon
function MaximizedWeaponSkill: boolean;
var
  blTmp: boolean;
begin
  blTmp := True;

  if ThePlayer.intWeapon > 0 then
  begin
    if Thing[ThePlayer.intWeapon].chLetter = chr(156) then
      if ThePlayer.intSword < Thing[ThePlayer.intWeapon].intWP then
        blTmp := False;

    if Thing[ThePlayer.intWeapon].chLetter = chr(159) then
      if ThePlayer.intAxe < Thing[ThePlayer.intWeapon].intWP then
        blTmp := False;

    if Thing[ThePlayer.intWeapon].chLetter = chr(164) then
      if ThePlayer.intWhip < Thing[ThePlayer.intWeapon].intWP then
        blTmp := False;

    if Thing[ThePlayer.intWeapon].chLetter = chr(158) then
      if ThePlayer.intGun < Thing[ThePlayer.intWeapon].intGP then
        blTmp := False;
  end
  else
    blTmp := False;

  MaximizedWeaponSkill := blTmp;
end;

// calculate total TP (shown as "M" in "MLD")
function CollectTP: integer;
var
  intTP: integer;
begin
  intTP := CollectFight;

  // add bonuses of equipped non-weapon items
  if ThePlayer.intArmour > 0 then
    Inc(intTP, Thing[ThePlayer.intArmour].intWP);

  if ThePlayer.intHat > 0 then
    Inc(intTP, Thing[ThePlayer.intHat].intWP);

  if ThePlayer.intRingLeft > 0 then
    Inc(intTP, Thing[ThePlayer.intRingLeft].intWP);

  if ThePlayer.intRingRight > 0 then
    Inc(intTP, Thing[ThePlayer.intRingRight].intWP);

  if ThePlayer.intFeet > 0 then
    Inc(intTP, Thing[ThePlayer.intFeet].intWP);

  if ThePlayer.intExtra > 0 then
    Inc(intTP, Thing[ThePlayer.intExtra].intWP);

  // set boni
  if CheckForItemSet(1)=true then
    inc(intTP, (25*intTP) div 100);


  // add weapon WP
  if ThePlayer.intWeapon > 0 then
  begin

    Inc(intTP, Thing[ThePlayer.intWeapon].intWP);

    // if weapon-skill is lower than weapon's WP,
    // decrease TP by this difference

    if Thing[ThePlayer.intWeapon].chLetter = chr(156) then
      if ThePlayer.intSword < Thing[ThePlayer.intWeapon].intWP then
        Dec(intTP, Thing[ThePlayer.intWeapon].intWP - CollectSword);

    if Thing[ThePlayer.intWeapon].chLetter = chr(159) then
      if ThePlayer.intAxe < Thing[ThePlayer.intWeapon].intWP then
        Dec(intTP, Thing[ThePlayer.intWeapon].intWP - CollectAxe);

    if Thing[ThePlayer.intWeapon].chLetter = chr(164) then
      if ThePlayer.intWhip < Thing[ThePlayer.intWeapon].intWP then
        Dec(intTP, Thing[ThePlayer.intWeapon].intWP - CollectWhip);

    if ThePlayer.intStrength > 100 then
      Inc(intTP, ThePlayer.intStrength - 100);
  end;

  if ThePlayer.intDipl[1]=1 then
    if CheckEffect(49)=true then
      Inc(intTP,2)
    else
      Inc(intTP);

  if ThePlayer.blOffensive = false then
    intTP := intTP div 2;

  CollectTP := intTP;
end;


// calculate total TP of a long-range weapon (shown as "L" in "MLD")
function CollectGunTP: integer;
var
  intTP: integer;
begin
  intTP := CollectFight;

  // add weapon GP
  if ThePlayer.intWeapon > 0 then
  begin
    Inc(intTP, Thing[ThePlayer.intWeapon].intGP);

    // if gun-skill is lower than weapon's GP,
    // decrease TP by this difference
    if CollectGun < Thing[ThePlayer.intWeapon].intGP then
      Dec(intTP, Thing[ThePlayer.intWeapon].intGP - CollectGun);
  end;

  // add bonuses of equipped non-weapon items
  if ThePlayer.intArmour > 0 then
    Inc(intTP, Thing[ThePlayer.intArmour].intGP);

  if ThePlayer.intHat > 0 then
    Inc(intTP, Thing[ThePlayer.intHat].intGP);

  if ThePlayer.intRingLeft > 0 then
    Inc(intTP, Thing[ThePlayer.intRingLeft].intGP);

  if ThePlayer.intRingRight > 0 then
    Inc(intTP, Thing[ThePlayer.intRingRight].intGP);

  if ThePlayer.intFeet > 0 then
    Inc(intTP, Thing[ThePlayer.intFeet].intGP);

  if ThePlayer.intExtra > 0 then
    Inc(intTP, Thing[ThePlayer.intExtra].intGP);

  if ThePlayer.intDipl[15]=1 then
    if CheckEffect(49)=true then
      Inc(intTP,2)
    else
      Inc(intTP);

  // set boni
  if CheckForItemSet(1)=true then
    inc(intTP, (25*intTP) div 100);

  if ThePlayer.blOffensive = false then
  begin
    intTP := intTP - 3;
    if intTP<1 then intTP:=1;
  end;

  CollectGunTP := intTP;

  // WP of selected ammu is added on the fly during the attack, not here
end;

// calculate total TP of thrown item
function CollectThrowTP (t: integer): integer;
var
  intTP: integer;
begin
  intTP := trunc(ThePlayer.intStrength div 10) + trunc(random(3));

  // add min. 1, max. 3, if item is a lance, axe, knife or dagger
  if (Thing[t].chLetter = chr(164)) or (Thing[t].chLetter = chr(159)) or (Pos('knife',lowercase(Thing[t].strName))>0) or (Pos('dagger',lowercase(Thing[t].strName))>0) then
    inc(intTP, 1+trunc(random(3)));

  // add min. 3, max 6, if item is a rock/stone
  if Thing[t].chLetter = chr(171) then
    inc(intTP,3+trunc(random(6)));

  // add bonuses of equipped non-weapon items
  if ThePlayer.intArmour > 0 then
    Inc(intTP, Thing[ThePlayer.intArmour].intGP);

  if ThePlayer.intHat > 0 then
    Inc(intTP, Thing[ThePlayer.intHat].intGP);

  if ThePlayer.intRingLeft > 0 then
    Inc(intTP, Thing[ThePlayer.intRingLeft].intGP);

  if ThePlayer.intRingRight > 0 then
    Inc(intTP, Thing[ThePlayer.intRingRight].intGP);

  if ThePlayer.intFeet > 0 then
    Inc(intTP, Thing[ThePlayer.intFeet].intGP);

  if ThePlayer.intExtra > 0 then
    Inc(intTP, Thing[ThePlayer.intExtra].intGP);

  if ThePlayer.intDipl[15]=1 then
    if CheckEffect(49)=true then
      Inc(intTP,2)
    else
      Inc(intTP);

  if ThePlayer.blOffensive = false then
  begin
    intTP := intTP - 1;
    if intTP<1 then intTP:=1;
  end;

  CollectThrowTP := intTP;
end;

// collect total buy price
function CollectBuyPrice(n: integer): integer;
var
  p: integer;
begin
  p := thing[n].intPrice;

  if ThePlayer.intTrade > 3 then
    Dec(p, (1 * p) div 100);
  if ThePlayer.intTrade > 6 then
    Dec(p, (3 * p) div 100);
  if ThePlayer.intTrade > 9 then
    Dec(p, (6 * p) div 100);
  if ThePlayer.intTrade > 11 then
    Dec(p, (8 * p) div 100);

  if PlayerHasItem('V.I.P. Card') > 0 then
    p := p div 2;

  if p < 1 then
    p := 1;

  CollectBuyPrice := p;
end;


// collect sell price
function CollectSellPrice(n: integer): integer;
var
  bp, tp: integer;
begin
  bp := Thing[n].intPrice;
  tp := (8 * bp) div 100;
  Inc(tp, ((5 * ThePlayer.intTrade) * bp) div 100);
  if tp > Thing[n].intPrice then
    tp := Thing[n].intPrice;
  CollectSellPrice := tp;
end;

// calculate total light source and view field of the player
function CollectLight(sx, sy: integer): integer;
var
  intLight: integer;
begin
  intLight := DngLvl[sx, sy].intLight;
  if ThePlayer.intWeapon > 0 then
    Inc(intLight, Thing[ThePlayer.intWeapon].intLight);

  if ThePlayer.intArmour > 0 then
    Inc(intLight, Thing[ThePlayer.intArmour].intLight);

  if ThePlayer.intHat > 0 then
    Inc(intLight, Thing[ThePlayer.intHat].intLight);

  if ThePlayer.intExtra > 0 then
    Inc(intLight, Thing[ThePlayer.intExtra].intLight);

  if ThePlayer.intFeet > 0 then
    Inc(intLight, Thing[ThePlayer.intFeet].intLight);

  if ThePlayer.intRingLeft > 0 then
    Inc(intLight, Thing[ThePlayer.intRingLeft].intLight);

  if ThePlayer.intRingRight > 0 then
    Inc(intLight, Thing[ThePlayer.intRingRight].intLight);

  if ThePlayer.blCursed = True then
    intLight := intLight div 4;
  if intLight < 1 then
    intLight := 1;
  if intLight > 5 then
    intLight := 5;

  CollectLight := intLight;
end;

end.
