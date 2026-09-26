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

unit Items;


interface

uses
  Constants, BaseOutput, WebBE, RandomArea, Player, Chants, SysUtils;

const
  MaxItem   = 1000;
  MaxUnItem = 1000;
  MaxShops  = 20;

  CONST_MINIMUMITEMSTRENGTH = 35;
// minimum strength level of items that don't have their own

type
  Receipt = record
    strName: string;
    longWood: longint;
    longMetal: longint;
    longLeather: longint;
    longStone: longint;
    strItem: string;
    chLetter: char;
  end;


type
  Item = record
    strName, strRealName, strGenericName, strTextfile: string;
    blWield, blWear, blDrink, blEat, blThrow, blShoot: boolean;
    intPrice, intAmount, intSpellID: integer;
    blCursed, blRing, blHat, blShoes, blExtra, blBarricade, blTrap,
    blIdentified: boolean;
    intWP, intAP, intGP, intLight: integer;
    intEffect, intRange, intSP, intRuneSet: integer;
    strDescri, strEfText, strLearnChant: string;
    chLetter:     char;
    intMinLvl, intNeedsAmmu, intIsAmmu, intStrength, intProf, intSex: integer;
    blUnique, blRare, blShopOnly, blSacrifice, blTwoHands: boolean;
    intCharLvl:   longint;
  end;

type
  ResPack = record
    longWood:     longint;
    longMetal:    longint;
    longStone:    longint;
    longLeather:  longint;
    longPlastics: longint;
    longPaper:    longint;
  end;


type
  InvEntry = record
    intType:    integer;
    longNumber: integer;
  end;

type
  Shop = record
    Inventory: array[1..16] of InvEntry;
    intType:   integer;
  end;

var
  Thing:      array[1..MaxItem] of Item;
  Inventory:  array[1..16] of InvEntry;    // default inventory
  MyShop:     array[1..MaxShops] of Shop;  // shops
  Shops:      array[1..MaxShops] of string;
  chBuilding: array[1..MaxShops] of char;
  Storage:    ResPack;
  ItemCount:  longint;
  UnItem:     array[1..MaxUnItem] of integer;
  ItemReceipt: array[1..WinLevel, 1..5] of Receipt;  // pro Level 5 Receipts, aber praktisch werden nur lvl 1, 5, 10, 15 genutzt

function CheckForItemSet(s: integer): boolean;
function CheckEffect(e: integer): boolean;
function IsInvisible: boolean;
procedure ItemInit;
function RuneSet(Rune1, Rune2, Rune3, Rune4, Rune5: string; RemoveRunes: boolean): boolean;
function PlayerHasKey(): integer;
function PlayerHasItem(strName: string): integer;
function PlayerHasUnknownItem(strName: string): integer;
function CheckNeededItems(strItems: string; RemoveItems: boolean): boolean;
function CheckNeededResources(strResources: string): boolean;
procedure ReduceResources(strResources: string);
function ReturnItemByName(s: string): integer;
function ReturnRandomItem: integer;
function ReturnRareItem: integer;
function ReturnUniqueItem: integer;
function ReturnSetItem: integer;
procedure DisassembleItem(n: integer);
procedure CraftingReceipts;
function GetEffectDescription(eid: integer): string;
procedure SetItemNameColor (itemname: string);
procedure WeaponVariants;

implementation


// checks if a given itemset is equipped
function CheckForItemSet(s: integer): boolean;
var
  n: integer;
  c: boolean;
begin
  n:=0;
  c:=false;

  If ThePlayer.intWeapon>0 then
    if thing[ThePlayer.intWeapon].intRuneSet = s then
      inc(n);

  If ThePlayer.intArmour>0 then
    if thing[ThePlayer.intArmour].intRuneSet = s then
      inc(n);

  If ThePlayer.intHat>0 then
    if thing[ThePlayer.intHat].intRuneSet = s then
      inc(n);

  If ThePlayer.intFeet>0 then
    if thing[ThePlayer.intFeet].intRuneSet = s then
      inc(n);

  If ThePlayer.intRingLeft>0 then
    if thing[ThePlayer.intRingLeft].intRuneSet = s then
      inc(n);

  If ThePlayer.intRingRight>0 then
    if thing[ThePlayer.intRingRight].intRuneSet = s then
      inc(n);

  If ThePlayer.intExtra>0 then
    if thing[ThePlayer.intExtra].intRuneSet = s then
      inc(n);

  // testen, ob Anzahl gefundener Setitems der Anzahl des Sets entspricht
  case s of
    1: if n=3 then c:=true;
    2: if n=3 then c:=true;
    3: if n=4 then c:=true;
    4: if n=3 then c:=true;
    5: if n=3 then c:=true;
    6: if n=3 then c:=true;     // Waffe (Schwert oder Bogen), Ruestung, Kopfbedeckung (Pfeile nicht)
    7: if n=5 then c:=true;
    8: if n=2 then c:=true;
  end;

  //if c=true then
    //writeln ('Set ' + IntToStr(s) + ' gefunden.');

  CheckForItemSet := c;


end;

// sets the color of the item name, based on rarity (white=normal; green=special; yellow=rare; purple=unique)
procedure SetItemNameColor (itemname: string);
var
  n: integer;
begin

  // writeln ('Set Item Color for: ' + itemname);

  GlobalFontColor := FONTCOLOR_WHITE;
  GlobalConColor := -1;

  n:=ReturnItemByName(itemname);

  if n>0 then
  begin
    if thing[n].blRare = true then
    begin
      GlobalFontColor := FONTCOLOR_YELLOW;
      GlobalConColor := Yellow;
    end;

    if (thing[n].blUnique = true) or (thing[n].intRuneSet>0) then
    begin
      GlobalFontColor := FONTCOLOR_PURPLE;
      GlobalConColor := Magenta;
    end;

    if GlobalFontColor = FONTCOLOR_WHITE then
      if (thing[n].intEffect > 0) or (thing[n].blRing = true) then
        if (thing[n].blEat = false) and (thing[n].blDrink = false) then
        begin
          GlobalFontColor := FONTCOLOR_GREEN;
          GlobalConColor := Lightgreen;
        end;
  end;

end;

// returns a textual effect description of an item
function GetEffectDescription(eid: integer): string;
var
  effect: string;
begin
  GetEffectDescription:='-';
  case eid of
    0:
      effect := '-';
    1:
      effect := 'Dec. Hunger';
    2:
      effect := 'Dec. Poison';
    3:
      effect := 'Regen. PP';
    4:
      effect := 'Regen. HP';
    5:
      effect := 'Invisible';
    6:
      effect := 'Max. EXP';
    7:
      effect := 'Max. Credits';
    8:
      effect := 'Aura: Fire';
    9:
      effect := 'Aura: Ice';
    10:
      effect := 'Res. Poison';
    11:
      effect := 'Res. Confusion';
    12:
      effect := 'Dec. Confusion';
    13:
      effect := 'Res. Fire';
    14:
      effect := 'Res. Ice';
    15:
      effect := 'Barrier';
    16:
      effect := 'Inc. STR';
    17:
      effect := 'Res. Blindness';
    18:
      effect := 'Dec. Blindness';
    19:
      effect := 'Force Damage';
    20:
      effect := 'Aura: Healing';
    21:
      effect := 'Teleport';
    22:
      effect := 'Aura: Water';
    23:
      effect := 'Dec. HP';
    24:
      effect := 'Dec. PP';
    25:
      effect := 'Max. Move';
    26:
      effect := 'Res. Paralization';
    27:
      effect := 'Dec. Paralization';
    28:
      effect := 'Res. Calm';
    29:
      effect := 'Dec. Calm';
    30:
      effect := 'Freeze Time';
    31:
      effect := 'Res. Curse';
    32:
      effect := 'Remove Curse';
    33:
      effect := 'Bless';
    34:
      effect := 'Curse';
    35:
      effect := 'Res. Water';
    36:
      effect := 'Sticky';
    37:
      effect := 'Max. Magic';
    38:
      effect := 'Fire Damage';
    39:
      effect := 'Ice Damage';
    40:
      effect := 'Water Damage';
    41:
      effect := 'Res. Traps';
    42:
      effect := 'Duplicate Item';
    43:
      effect := 'Compass';
    44:
      effect := 'Inc. Confusion';
    45:
      effect := 'Inc. Poison';
    46:
      effect := 'Meteor';
    47:
      effect := 'Identify';
    48:
      effect := 'Light';
    49:
      effect := 'Max. Distress';
    50:
      effect := 'Wipe';
    51:
      effect := 'Res. PP Drain';
    52:
      effect := 'Res. STR Drain';
    53:
      effect := 'Regen. HP and PP';
    54:
      effect := 'Fam. Terrain';
    55:
      effect := 'Res. Electricity';
    56:
      effect := 'Electric Damage';
    57:
      effect := 'Red. PP Costs';
    58:
      effect := 'Area Damage';
    62:
      effect := 'Max. Hit';
    64:
      effect := 'Max. Fight';
    65:
      effect := 'Max. Humility';
    66:
      effect := 'Max. Talent';
  end;

  Result := effect;

end;


// Items can be disassemled
procedure DisassembleItem(n: integer);
var
  strItemName:     string;
  intChar, intDLV:      integer;
  intPlusMetal, intPlusWood, intPlusStone, intPlusLeather, intPlusPaper: integer;
  //intPlusPlastics: integer;
begin
  intChar   := ord(Thing[n].chLetter);
  intDLV := Thing[n].intMinLvl;

  intPlusMetal    := 0;
  intPlusWood     := 0;
  intPlusStone    := 0;
  intPlusLeather  := 0;
  intPlusPaper    := 0;
  //intPlusPlastics := 0;

  //    - Holz aus Axt, Schwert, Lanze, Schusswaffe, Spaten, Schild, Munition
  if (intChar=156) or (intChar=162) or (intChar=159) or (intChar=164) or (intChar=158) or (intChar=246) then
  begin
    inc (intPlusWood, 8);  // alle
    if intChar=246 then  // Schild
      inc (intPluswood, 10);
  end;


  //    - Metall aus Axt, Schwert, Lanze, Schusswaffe, Ring, Ruestung, Schild, Munition, Helm, Schluessel, Spaten
  if (intChar=159) or (intChar=156) or (intChar=164) or (intChar=158) or (intChar=166) or (intChar=157) or (intChar=246) or (intChar=160) or (intChar=165) or (intChar=191) or (intChar=162) then
  begin
    inc (intPlusMetal, 6);  // alle
    if intChar=156 then  // Schwert
      inc (intPlusMetal, 20);
    if intChar=246 then  // Schild
      inc (intPlusMetal, 10);
  end;

  //    - Stein aus Axt, Schwert, Lanze, Ring, Schild, Rune, Munition, Fels
  if (intChar=159) or (intChar=156) or (intChar=164) or (intChar=166) or (intChar=246) or (intChar=169) or (intChar=160) or (intChar=171) then
  begin
    inc (intPlusStone, 6);
    if intChar=171 then  // Fels
      inc(intPlusStone, 5);
  end;

  //    - Leder aus Ruestung, Schuhen, Kleidung, Helm
  if (intChar=157) or (intChar=247) or (intChar=163) or (intChar=165) then
  begin
    inc (intPlusLeather, 8);
    if (intChar=157) or (intChar=163) then  // Ruestung und Kleidung
      inc(intPlusLeather, 18);
  end;

  //   - Papier aus Seite
  if intChar=193 then
    inc (intPlusPaper, 3);


  Inc(Storage.longWood, intPlusWood);
  Inc(Storage.longMetal, intPlusMetal);
  Inc(Storage.longStone, intPlusStone);
  Inc(Storage.longLeather, intPlusLeather);
//  Inc(Storage.longPlastics, intPlusPlastics);
  Inc(Storage.longPaper, intPlusPaper);
end;


 // this function returns true, if a player has equipped an item with the given effect
 // it also returns true if the temporary resistance with that effectno. is > 0
function CheckEffect(e: integer): boolean;
begin
  CheckEffect := False;

  if ThePlayer.intWeapon > 0 then
  begin
    if Thing[ThePlayer.intWeapon].intEffect = e then
      CheckEffect := True;

    if ThePlayer.intWeaponMod = e then
      CheckEffect := True;
  end;

  if ThePlayer.intArmour > 0 then
    if Thing[ThePlayer.intArmour].intEffect = e then
      CheckEffect := True;

  if ThePlayer.intHat > 0 then
    if Thing[ThePlayer.intHat].intEffect = e then
      CheckEffect := True;

  if ThePlayer.intRingLeft > 0 then
    if Thing[ThePlayer.intRingLeft].intEffect = e then
      CheckEffect := True;

  if ThePlayer.intRingRight > 0 then
    if Thing[ThePlayer.intRingRight].intEffect = e then
      CheckEffect := True;

  if ThePlayer.intExtra > 0 then
    if Thing[ThePlayer.intExtra].intEffect = e then
      CheckEffect := True;

  if ThePlayer.intFeet > 0 then
    if Thing[ThePlayer.intFeet].intEffect = e then
      CheckEffect := True;

  if ThePlayer.intTempResist[e] > 0 then
    CheckEffect := True;
end;

// returns true, if the player is invisible
function IsInvisible: boolean;
begin
  IsInvisible := False;
  if CheckEffect(5) = True then
    IsInvisible := True;
  if ThePlayer.intInvis > 0 then
    IsInvisible := True;
end;

// split a items-string into its components and return true if all needed items exist
function CheckNeededItems(strItems: string; RemoveItems: boolean): boolean;
var
  position: integer;
  dummy, Item1, Item2, Item3, Item4, Item5: string;
begin
  CheckNeededItems := False;
  position := 0;

  // item 1
  dummy := '';
  repeat
    Inc(position);
    if strItems[position] <> ',' then
      dummy := dummy + strItems[position];
  until strItems[position] = ',';
  Item1 := dummy;
  //   writeln(dummy);

  // item 2
  dummy := '';
  repeat
    Inc(position);
    if strItems[position] <> ',' then
      dummy := dummy + strItems[position];
  until strItems[position] = ',';
  Item2 := dummy;
  //   writeln(dummy);

  // item 3
  dummy := '';
  repeat
    Inc(position);
    if strItems[position] <> ',' then
      dummy := dummy + strItems[position];
  until strItems[position] = ',';
  Item3 := dummy;
  //   writeln(dummy);

  // item 4
  dummy := '';
  repeat
    Inc(position);
    if strItems[position] <> ',' then
      dummy := dummy + strItems[position];
  until strItems[position] = ',';
  Item4 := dummy;
  //   writeln(dummy);

  // item 5
  dummy := '';
  repeat
    Inc(position);
    if position <= length(strItems) then
      dummy := dummy + strItems[position];
  until position = length(strItems);
  Item5 := dummy;
  //   writeln(dummy);

  CheckNeededItems := RuneSet(Item1, Item2, Item3, Item4, Item5, RemoveItems);
end;

// split a resource-string into its components and return true if all needed resources exist
function CheckNeededResources(strResources: string): boolean;
var
  longNeedWood, longNeedMetal, longNeedStone, longNeedLeather: longint;
  longNeedPlastics, longNeedPaper: longint;
  position: integer;
  dummy:    string;
begin
  // strResources contains the number of needed resources (e.g. for quests or for
  // building something in the form wood,metal,stone,leather,plastics,paper). These
  // values have to be split into numbers and then checked against the storage room
  // of the character.

  CheckNeededResources := False;
  position := 0;

  // wood
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedWood);
  writeln(dummy);

  // metal
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedMetal);
  writeln(dummy);

  // stone
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedStone);
  writeln(dummy);

  // leather
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedLeather);
  writeln(dummy);

  // plastics
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedPlastics);
  writeln(dummy);

  // paper
  dummy := '';
  repeat
    Inc(position);
    if position <= length(strResources) then
      dummy := dummy + strResources[position];
  until position = length(strResources);
  val(dummy, longNeedPaper);
  writeln(dummy);

  // now check if all needed resources are in storage
  if (Storage.longWood >= longNeedWood) and (Storage.longMetal >= longNeedMetal) and
    (Storage.longStone >= longNeedStone) and (Storage.longLeather >= longNeedLeather) and
    (Storage.longPlastics >= longNeedPlastics) and
    (Storage.longPaper >= longNeedPaper) then
    CheckNeededResources := True;

end;


// reduce player's resources by the number given in a resource-string
procedure ReduceResources(strResources: string);
var
  longNeedWood, longNeedMetal, longNeedStone, longNeedLeather: longint;
  longNeedPlastics, longNeedPaper: longint;
  position: integer;
  dummy:    string;
begin
  position := 0;

  // wood
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedWood);

  // metal
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedMetal);

  // stone
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedStone);

  // leather
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedLeather);

  // plastics
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until strResources[position] = ',';
  val(dummy, longNeedPlastics);

  // paper
  dummy := '';
  repeat
    Inc(position);
    if strResources[position] <> ',' then
      dummy := dummy + strResources[position];
  until position = length(strResources);
  val(dummy, longNeedPaper);

  Dec(Storage.longWood, longNeedWood);
  Dec(Storage.longMetal, longNeedMetal);
  Dec(Storage.longStone, longNeedStone);
  Dec(Storage.longLeather, longNeedLeather);
  Dec(Storage.longPlastics, longNeedPlastics);
  Dec(Storage.longPaper, longNeedPaper);
end;


// check if the player has a dungeon key or a picklock; returns -1 if not available
function PlayerHasKey(): integer;
begin
  PlayerHasKey := -1;

  // Dungeon key for single use
  PlayerHasKey := PlayerHasItem('Dungeon Key');

  // Picklock for multiple uses
  if (PlayerHasItem('Picklock') > 0) and (ThePlayer.intProf = 3) then
    PlayerHasKey := 22;
end;


// check if the player has a specific item
function PlayerHasItem(strName: string): integer;
var
  i: integer;
begin
  PlayerHasItem := -1;
  for i := 1 to 16 do
    if Inventory[i].intType > 0 then
      if Thing[Inventory[i].intType].strName = strName then
        PlayerHasItem := i;
end;

// check if the player has a specific, but not yet identified item
function PlayerHasUnknownItem(strName: string): integer;
var
  i: integer;
begin
  PlayerHasUnknownItem := -1;
  for i := 1 to 16 do
    if Inventory[i].intType > 0 then
      if Thing[Inventory[i].intType].strRealName = strName then
        PlayerHasUnknownItem := i;
end;

// return item id by item name
function ReturnItemByName(s: string): integer;
var
  i, n: integer;
begin
  //writeln('searching for item ' + s);
  n := 0;

  for i:=1 to ItemCount do
    if thing[i].strRealName = s then
    begin
      n := i;
      ReturnItemByName := n;
      break;
    end;

  //if n>0 then
  //  writeln ('i = '+IntToStr(i)+' // Item: '+thing[i].strRealName);

  ReturnItemByName := n;
end;

// returns a random rare item
function ReturnRareItem: integer;
var
  i: integer;
begin
  repeat
    i := trunc(1 + random(ItemCount));
  until (thing[i].intMinLvl <= DungeonLevel) and (thing[i].blRare = True);
  ReturnRareItem := i;
end;

// returns a setitem
function ReturnSetItem: integer;
var
  i, n: integer;
begin
  i:=-1;
  n:=0;
  repeat
    i := trunc(1 + random(ItemCount));
    inc(n);
  until (n>2000) or ((thing[i].intMinLvl <= DungeonLevel) and (thing[i].intRuneSet>0));

  // fallback if no set items exist for the given conditions
  if thing[i].intRuneSet=0 then
    i:=ReturnRareItem;

  ReturnSetItem := i;
end;

// returns a random unique items
function ReturnUniqueItem: integer;
var
  i, j: integer;
begin
  j := 0;
  i := -1;
  repeat
    i := trunc(1 + random(ItemCount));
    Inc(j);
  until (j = 2000) or ((thing[i].intMinLvl = DungeonLevel) and
      (thing[i].blUnique = True));

  if i = -1 then
    i := 1;

  // if Player is evil and has killed Eris, drop Book of Stars
  //if ThePlayer.blEvil = True then
  //  if DungeonLevel = 20 then
  //    i := ReturnItemByName('Book of Stars');

  ReturnUniqueItem := i;
end;

// returs a random item
function ReturnRandomItem: integer;
var
  i: integer;
begin
  repeat
    i := trunc(1 + random(ItemCount));
  until (thing[i].intMinLvl <= DungeonLevel) and (Thing[i].intMinLvl >= DungeonLevel - 3) and (thing[i].blUnique = False) and
    (thing[i].blRare = False) and (thing[i].blShopOnly = False);
  ReturnRandomItem := i;
end;



// check for the existence of complete set items (and runes)
function RuneSet(Rune1, Rune2, Rune3, Rune4, Rune5: string;
  RemoveRunes: boolean): boolean;
var
  Runes, i, RunePos1, RunePos2, RunePos3, RunePos4, RunePos5: integer;
begin
  RunePos1 := 0;
  RunePos2 := 0;
  RunePos3 := 0;
  RunePos4 := 0;
  RunePos5 := 0;

  Runes   := 0;
  RuneSet := False;

  for i := 1 to 16 do
    if Inventory[i].intType > 0 then
    begin
      if Thing[Inventory[i].intType].strName = Rune1 then
      begin
        Inc(Runes);
        RunePos1 := i;
        Rune1    := '[n/a]';
      end;

      if Thing[Inventory[i].intType].strName = Rune2 then
      begin
        Inc(Runes);
        RunePos2 := i;
        Rune2    := '[n/a]';
      end;

      if Thing[Inventory[i].intType].strName = Rune3 then
      begin
        Inc(Runes);
        RunePos3 := i;
        Rune3    := '[n/a]';
      end;

      if Thing[Inventory[i].intType].strName = Rune4 then
      begin
        Inc(Runes);
        RunePos4 := i;
        Rune4    := '[n/a]';
      end;

      if Thing[Inventory[i].intType].strName = Rune5 then
      begin
        Inc(Runes);
        RunePos5 := i;
        Rune5    := '[n/a]';
      end;
    end;

  if Runes = 5 then
  begin
    RuneSet := True;

    // remove all runes?
    if RemoveRunes = True then
    begin
      Dec(Inventory[RunePos1].longNumber);
      if Inventory[RunePos1].longNumber = 0 then
        Inventory[RunePos1].intType := 0;

      Dec(Inventory[RunePos2].longNumber);
      if Inventory[RunePos2].longNumber = 0 then
        Inventory[RunePos2].intType := 0;

      Dec(Inventory[RunePos3].longNumber);
      if Inventory[RunePos3].longNumber = 0 then
        Inventory[RunePos3].intType := 0;

      Dec(Inventory[RunePos4].longNumber);
      if Inventory[RunePos4].longNumber = 0 then
        Inventory[RunePos4].intType := 0;

      Dec(Inventory[RunePos5].longNumber);
      if Inventory[RunePos5].longNumber = 0 then
        Inventory[RunePos5].intType := 0;
    end;
  end;
end;


procedure ItemInit;
var
  ItemFile: textfile;
  i, u:     integer;
  strKey, strValue: string;
begin

  strKey   := '';
  strValue := '';

  for i := 1 to MaxItem do
  begin
    with Thing[i] do
    begin
      blWear     := False;
      blWield    := False;
      blEat      := False;
      blDrink    := False;
      blThrow    := False;
      blShoot    := False;
      blUnique   := False;
      blRare     := False;
      blShopOnly := False;
      blSacrifice := False;
      blHat      := False;
      blRing     := False;
      blTwoHands := False;
      blExtra    := False;
      blShoes    := False;
      blBarricade := False;
      blTrap     := False;
      intNeedsAmmu := 0;
      intIsAmmu  := 0;
      intSP      := 0;
      intGP      := 0;
      intWP      := 0;
      intAP      := 0;
      intProf    := 0;
      intSex     := 0;  // 0: both; 1: male; 2: female
      intAmount  := 1;
      strDescri  := '-';
      chLetter   := '-';
      strLearnChant := '-';
      strTextfile := '-';
      intEffect  := 0;
      strEfText  := '';

      strName     := '-';
      strGenericName := 'an item';
      strRealName := '-';

      intRange     := 4;
      intMinLvl    := 1;
      intCharLvl   := 1;
      intPrice     := 1;
      intSpellID   := -1;
      blIdentified := True;
      intRuneSet   := 0;
      intStrength  := CONST_MINIMUMITEMSTRENGTH;
    end;
  end;

  for i := 1 to MaxUnItem do
    UnItem[i] := 0;

  i := 0;
  u := 0;

  Assign(ItemFile, CONST_DATADIR + 'data/items.txt');
  Reset(ItemFile);

  while EOF(ItemFile) = False do
  begin
    repeat
      ReadLn(ItemFile, strKey);
    until ((strKey <> '') and (strKey[1] <> ' ') and (strKey[1] <> '#')) or (EOF(ItemFile));

    ReadLn(ItemFile, strValue);

    //Writeln('Key: ' + strKey);

    if strKey = 'NewItem:' then
      Inc(i);

    if i > 0 then
    begin
      if strKey = 'NewItem:' then
      begin
        Thing[i].strRealName := strValue;
        //Writeln('Recognized item: ' + strValue);
      end;

      if (strKey = 'Hands') and (strValue = '= True') then
        Thing[i].blWield := True;
      if (strKey = 'Hands') and (strValue = '= False') then
        Thing[i].blWield := False;

      if (strKey = 'Body') and (strValue = '= True') then
        Thing[i].blWear := True;
      if (strKey = 'Body') and (strValue = '= False') then
        Thing[i].blWear := False;

      if (strKey = 'Finger') and (strValue = '= True') then
        Thing[i].blRing := True;
      if (strKey = 'Finger') and (strValue = '= False') then
        Thing[i].blRing := False;

      if (strKey = 'Barricade') and (strValue = '= True') then
        Thing[i].blBarricade := True;
      if (strKey = 'Barricade') and (strValue = '= False') then
        Thing[i].blBarricade := False;

      if (strKey = 'Trap') and (strValue = '= True') then
        Thing[i].blTrap := True;
      if (strKey = 'Trap') and (strValue = '= False') then
        Thing[i].blTrap := False;

      if (strKey = 'Head') and (strValue = '= True') then
        Thing[i].blHat := True;
      if (strKey = 'Head') and (strValue = '= False') then
        Thing[i].blHat := False;

      if (strKey = 'Feet') and (strValue = '= True') then
        Thing[i].blShoes := True;
      if (strKey = 'Feet') and (strValue = '= False') then
        Thing[i].blShoes := False;

      if (strKey = 'Extra') and (strValue = '= True') then
        Thing[i].blExtra := True;
      if (strKey = 'Extra') and (strValue = '= False') then
        Thing[i].blExtra := False;

      if (strKey = 'Eat') and (strValue = '= True') then
        Thing[i].blEat := True;
      if (strKey = 'Eat') and (strValue = '= False') then
        Thing[i].blEat := False;

      if (strKey = 'Drink') and (strValue = '= True') then
        Thing[i].blDrink := True;
      if (strKey = 'Drink') and (strValue = '= False') then
        Thing[i].blDrink := False;

      if (strKey = 'Throw') and (strValue = '= True') then
        Thing[i].blThrow := True;
      if (strKey = 'Throw') and (strValue = '= False') then
        Thing[i].blThrow := False;

      if (strKey = 'Shoot') and (strValue = '= True') then
        Thing[i].blShoot := True;
      if (strKey = 'Shoot') and (strValue = '= False') then
        Thing[i].blShoot := False;

      if (strKey = 'Rare') and (strValue = '= True') then
        Thing[i].blRare := True;
      if (strKey = 'Rare') and (strValue = '= False') then
        Thing[i].blRare := False;

      if (strKey = 'ShopOnly') and (strValue = '= True') then
        Thing[i].blShopOnly := True;
      if (strKey = 'ShopOnly') and (strValue = '= False') then
        Thing[i].blShopOnly := False;

      if (strKey = 'Unique') and (strValue = '= True') then
      begin
        Thing[i].blUnique := True;
        Inc(u);
        UnItem[u] := i;
      end;

      if (strKey = 'Unique') and (strValue = '= False') then
        Thing[i].blUnique := False;

      if (strKey = 'Sacrifice') and (strValue = '= True') then
        Thing[i].blSacrifice := True;
      if (strKey = 'Sacrifice') and (strValue = '= False') then
        Thing[i].blSacrifice := False;

      if (strKey = 'TwoHands') and (strValue = '= True') then
        Thing[i].blTwoHands := True;
      if (strKey = 'TwoHands') and (strValue = '= False') then
        Thing[i].blTwoHands := False;

      if strKey = 'Description:' then
        Thing[i].strDescri := strValue;
      if strKey = 'Chant:' then
        Thing[i].strLearnChant := strValue;

      if strKey = 'NeedsAmmu:' then
        Thing[i].intNeedsAmmu := StrToInt(strValue);
      if strKey = 'IsAmmu:' then
        Thing[i].intIsAmmu := StrToInt(strValue);
      if strKey = 'SpellID:' then
        Thing[i].intSpellID := StrToInt(strValue);

      if strKey = 'ItemType' then
        // this defines only the icon for the item; not its function!
      begin
        if strValue = '= Sword' then
        begin
          Thing[i].chLetter := chr(156); // '/';
          Thing[i].strGenericName := 'unknown sword';
        end;

        if strValue = '= Spade' then
        begin
          Thing[i].chLetter := chr(162); // '/';
          Thing[i].strGenericName := 'unknown tool';
        end;

        if strValue = '= Axe' then
        begin
          Thing[i].chLetter := chr(159); // '\';
          Thing[i].strGenericName := 'unknown axe';
        end;

        if strValue = '= Lance' then
        begin
          Thing[i].chLetter := chr(164); // '~';
          Thing[i].strGenericName := 'unknown lance';
        end;

        if strValue = '= Clothes' then
        begin
          Thing[i].chLetter := chr(163); //'(';
          Thing[i].strGenericName := 'unknown clothes';
        end;

        if strValue = '= Armour' then
        begin
          Thing[i].chLetter := chr(157); // '{';
          Thing[i].strGenericName := 'unknown armour';
        end;

        if strValue = '= Gun' then
        begin
          Thing[i].chLetter := chr(158); // '}';
          Thing[i].strGenericName := 'unknown firearm';
        end;

        if strValue = '= Potion' then
        begin
          Thing[i].chLetter := chr(155); // '!';
          Thing[i].strGenericName := 'unknown potion';
        end;

        if strValue = '= Scroll' then
        begin
          Thing[i].chLetter := chr(161); // '?';
          Thing[i].strGenericName := 'unknown crystal';
        end;

        if strValue = '= Food' then
        begin
          Thing[i].chLetter := chr(168); // '%';
          Thing[i].strGenericName := 'unknown food';
        end;

        if strValue = '= Torch' then
        begin
          Thing[i].chLetter := chr(172); // '&';
          Thing[i].strGenericName := 'unknown torch';
        end;

        if strValue = '= Ring' then
        begin
          Thing[i].chLetter := chr(166); //'=';
          Thing[i].strGenericName := 'unknown ring';
        end;

        if strValue = '= Shield' then
        begin
          Thing[i].chLetter := chr(246);
          //'=';    replace with unique symbol and graphics
          Thing[i].strGenericName := 'unknown shield';
        end;

        if strValue = '= Helmet' then
        begin
          Thing[i].chLetter := chr(165); // ')';
          Thing[i].strGenericName := 'unknown helmet';
        end;

        if strValue = '= Shoes' then
        begin
          Thing[i].chLetter := chr(247);
          // ')';   replace with unique symbol and graphics
          Thing[i].strGenericName := 'unknown shoes';
        end;

        if strValue = '= Rock' then
        begin
          Thing[i].chLetter := chr(171); //':';
          Thing[i].strGenericName := 'unknown rock';
        end;

        if strValue = '= Rune' then
        begin
          Thing[i].chLetter := chr(169);  // '-';
          Thing[i].strGenericName := 'unknown rune';
        end;

        if strValue = '= Ammu' then
        begin
          Thing[i].chLetter := chr(160); // '"';
          Thing[i].strGenericName := 'unknown ammunition';
        end;

        if strValue = '= Gold' then
        begin
          Thing[i].chLetter := chr(167); //'$';
          Thing[i].strGenericName := 'unknown gold';
        end;

        if strValue = '= Key' then
        begin
          Thing[i].chLetter := chr(191); //'o';
          Thing[i].strGenericName := 'unknown key';
        end;

        if strValue = '= Page' then
        begin
          Thing[i].chLetter := chr(193); // '�';
          Thing[i].strGenericName := 'unknown paper';
        end;

      end;

      if strKey = 'EffectText:' then
        Thing[i].strEfText := strValue;

      if strKey = 'EffectType' then
      begin
        // effects of food and potions
        if strValue = '= DecHunger' then
          Thing[i].intEffect := 1;    // food
        if strValue = '= DecPoison' then
          Thing[i].intEffect := 2;    // antidot
        if strValue = '= FireAura' then
          Thing[i].intEffect := 8;    // cast FireAura
        if strValue = '= IceAura' then
          Thing[i].intEffect := 9;    // cast IceAura
        if strValue = '= DecConfusion' then
          Thing[i].intEffect := 12;  // decr. confusion
        if strValue = '= MagicWall' then
          Thing[i].intEffect := 15;  // barrier
        if strValue = '= IncSTR' then
          Thing[i].intEffect := 16;    // increase STR
        if strValue = '= DecBlindness' then
          Thing[i].intEffect := 18;  // decrease blindness
        if strValue = '= Force' then
          Thing[i].intEffect := 19;    // force
        if strValue = '= HealAura' then
          Thing[i].intEffect := 20;    // heal aura
        if strValue = '= Teleport' then
          Thing[i].intEffect := 21;    // teleport
        if strValue = '= WaterAura' then
          Thing[i].intEffect := 22;  // cast WaterAura
        if strValue = '= DecHP' then
          Thing[i].intEffect := 23;    // decrease HP
        if strValue = '= DecPP' then
          Thing[i].intEffect := 24;    // decrease PP
        if strValue = '= DecPara' then
          Thing[i].intEffect := 27;    // decr. paraliz.
        if strValue = '= DecCalm' then
          Thing[i].intEffect := 29;    // decr. calm
        if strValue = '= FreezeTime' then
          Thing[i].intEffect := 30;  // freeze time
        if strValue = '= Uncurse' then
          Thing[i].intEffect := 32;    // uncurse
        if strValue = '= Bless' then
          Thing[i].intEffect := 33;    // bless
        if strValue = '= Curse' then
          Thing[i].intEffect := 34;    // curse
        if strValue = '= Random' then
          Thing[i].intEffect := -1;    // <random effect>
        if strValue = '= Fire' then
          Thing[i].intEffect := 38;    // fire spell
        if strValue = '= Ice' then
          Thing[i].intEffect := 39;    // ice spell
        if strValue = '= Water' then
          Thing[i].intEffect := 40;    // water spell
        if strValue = '= CloneItem' then
          Thing[i].intEffect := 42;  // clone item
        if strValue = '= IncConfusion' then
          Thing[i].intEffect := 44;  // incr. confusion
        if strValue = '= IncPoison' then
          Thing[i].intEffect := 45;  // incr. poison
        if strValue = '= Meteor' then
          Thing[i].intEffect := 46;    // summon meteor
        if strValue = '= Identify' then
          Thing[i].intEffect := 47;     // identify item
        if strValue = '= Wipe' then
          Thing[i].intEffect := 50;         // wipe out all monsters of current DLV
        if strValue = '= AreaDamage' then
          Thing[i].intEffect := 58;        // damage all monsters in area

        // effects of wearables
        // (these are also valid if intTempResist[n] is greater than 0! So potions and
        //  food are possible which provide temporary resistances)
        if strValue = '= IncPP' then
          Thing[i].intEffect := 3;    // regen. PP
        if strValue = '= IncHP' then
          Thing[i].intEffect := 4;    // regen. HP
        if strValue = '= IncHPandPP' then
          Thing[i].intEffect := 53;    // regen. HP
        if strValue = '= BecomeInvisible' then
          Thing[i].intEffect := 5;  // invisible (also as potion!)
        if strValue = '= ExtraEXP' then
          Thing[i].intEffect := 6;    // extra EXP
        if strValue = '= ExtraGold' then
          Thing[i].intEffect := 7;         // extra Cr
        if strValue = '= ResistIce' then
          Thing[i].intEffect := 14;  // resist ice spells
        if strValue = '= ResistWater' then
          Thing[i].intEffect := 35;  // resist water spells
        if strValue = '= ResistFire' then
          Thing[i].intEffect := 13;  // resist fire spells
        if strValue = '= ResistBlindness' then
          Thing[i].intEffect := 17;  // resist blindness
        if strValue = '= IncMove' then
          Thing[i].intEffect := 25;    // increase move skill
        if strValue = '= ResistParalization' then
          Thing[i].intEffect := 26; // resist paraliz.
        if strValue = '= ResistCalm' then
          Thing[i].intEffect := 28;  // resist calm
        if strValue = '= ResistCurse' then
          Thing[i].intEffect := 31;  // resist curse
        if strValue = '= MaxMagic' then
          Thing[i].intEffect := 37;    // doubles spell effect
        if strValue = '= Undestroyable' then
          Thing[i].intEffect := 36;  // item is undestr.
        if strValue = '= ResistPoison' then
          Thing[i].intEffect := 10;  // resist poison
        if strValue = '= ResistConfusion' then
          Thing[i].intEffect := 11;  // resist confusion
        if strValue = '= AvoidTrap' then
          Thing[i].intEffect := 41;     // prevent traps and trapdoors
        if strValue = '= Compass' then
          Thing[i].intEffect := 43;    // shows a compass rose
        if strValue = '= RemoveDarkness' then
          Thing[i].intEffect := 48;    // dark areas are enlightened
        if strValue = '= RageBonus' then
          Thing[i].intEffect := 49;    // increases divine rage
        if strValue = '= ResistDrainPP' then
          Thing[i].intEffect := 51;    // resist drain PP
        if strValue = '= ResistDrainSTR' then
          Thing[i].intEffect := 52;    // resist drain PP
        if strValue = '= FamiliarTerrain' then
          Thing[i].intEffect := 54;    // familiar terrain --> Move bonus
        if strValue = '= ResistElectricity' then
          Thing[i].intEffect := 55;  // resist electricity
        if strValue = '= Electricity' then
          Thing[i].intEffect := 56;    // electricity spell
        if strValue = '= ReducedPPCosts' then
          Thing[i].intEffect := 57;   // spells cost only 1/4 PP
        if strValue = '= IncHit' then
          Thing[i].intEffect := 62;   // increases Hit skill
        if strValue = '= IncFight' then
          Thing[i].intEffect := 64;   // increases Fight skill
        if strValue = '= IncTalent' then
          Thing[i].intEffect := 66;   // increases efficiency of talent
        if strValue = '= IncHumility' then
          Thing[i].intEffect := 65;   // increases humility
      end;

      if strKey = 'EffectRange:' then
        Thing[i].intRange := StrToInt(strValue);

      if strKey = 'Price:' then
        Thing[i].intPrice := StrToInt(strValue);
      if strKey = 'Amount:' then
        Thing[i].intAmount := StrToInt(strValue);

      if strKey = 'WP:' then
        Thing[i].intWP := StrToInt(strValue);  // weapon points
      if strKey = 'GP:' then
        Thing[i].intGP := StrToInt(strValue);  // gun points (for long range wp.)
      if strKey = 'AP:' then
        Thing[i].intAP := StrToInt(strValue);  // armour points
      if strKey = 'SP:' then
        Thing[i].intSP := StrToInt(strValue);  // shovel points (for diggings)
      if strKey = 'Light:' then
        Thing[i].intLight := StrToInt(strValue);
      if strKey = 'Strength:' then
        Thing[i].intStrength := StrToInt(strValue);

      if strKey = 'DungeonLvl:' then
        Thing[i].intMinLvl := StrToInt(strValue);
      if strKey = 'SetItem:' then
        Thing[i].intRuneSet := StrToInt(strValue);

      if strKey = 'CharLvl:' then
        Thing[i].intCharLvl := StrToInt(strValue);
      if strKey = 'Profession:' then
        Thing[i].intProf := StrToInt(strValue);
      if strKey = 'Sex:' then
        Thing[i].intSex := StrToInt(strValue);

      if strKey = 'Textfile:' then
        Thing[i].strTextfile := strValue;

    end;
  end;

  Close(ItemFile);

  ItemCount := i;
  //Writeln(IntToStr(ItemCount)+' items loaded.');

  // create a magic crystal for every chant
  for i := 1 to ChantCount do
  begin
    Inc(ItemCount);
    Thing[ItemCount].strRealName := 'Crystal of "' + Spell[i].strName + '"';
    Thing[ItemCount].strGenericName := 'unknown crystal';
    Thing[ItemCount].strLearnChant := Spell[i].strName;
    Thing[ItemCount].intSpellID := i;
    Thing[ItemCount].chLetter   := chr(161);
    Thing[ItemCount].intCharLvl := Spell[i].intCharLvl;
    Thing[ItemCount].strDescri  := 'Study this crystal to learn "' + Spell[i].strName + '"';

    // calculate price; area damage and aura attacks cost 25% more
    Thing[ItemCount].intPrice := Spell[i].intPP * 12;
    if (Spell[i].intEffect=8) or (Spell[i].intEffect=9) or (Spell[i].intEffect=22) or (Spell[i].intEffect=58) then
      inc(Thing[ItemCount].intPrice, (25 * Thing[ItemCount].intPrice) div 100);


    // all spells with PP>=20 are enchanter-only
    if Spell[i].intPP >= 20 then
      Thing[ItemCount].intProf := 2;

    // spells with a refresh rate <10 or >35 are rare items
    if (Spell[i].intRefresh < 10) or (Spell[i].intRefresh > 35) then
      Thing[ItemCount].blRare     := True
    else
      Thing[ItemCount].blShopOnly := True;

    // dungeonlevel = character level
    Thing[ItemCount].intMinLvl := Spell[i].intCharLvl
  end;


  // make rare and unique items as unidentified
  // all others get their real name
  for i := 1 to ItemCount do
  begin
    if (Thing[i].blRare = True) or (Thing[i].blUnique = True) then
      Thing[i].blIdentified := False;

    if Thing[i].blIdentified = False then
      Thing[i].strName := Thing[i].strGenericName
    else
      Thing[i].strName := Thing[i].strRealName;

    // exceptions to unknown items
    if (Thing[i].strRealName = 'Banana') or (Thing[i].strRealName = 'Banana Peel') or (Thing[i].strName = 'unknown gold') then
    begin
     Thing[i].blIdentified := True;
     Thing[i].strName := Thing[i].strRealName;
    end;
  end;



  // create a corpse for every monster template
  for i:=1 to MonsterTemplates do
  begin

    if LeftStr(MonTe[i].strName, 8)<>'ghost of' then
    begin
      Inc(ItemCount);
      Thing[ItemCount].strRealName := MonTe[i].strName + ' corpse';
      Thing[ItemCount].strGenericName := 'unknown corpse';
      Thing[ItemCount].chLetter   := chr(37);
      Thing[ItemCount].intCharLvl := 1;

      Thing[ItemCount].blUnique := False;
      Thing[ItemCount].blEat := True;
      Thing[ItemCount].intMinLvl := 99;

      Thing[ItemCount].strName := Thing[ItemCount].strRealName;
      Thing[ItemCount].blIdentified := True;

      if MonTe[i].blIntelligent=true then
      begin
        Thing[ItemCount].intEffect := 0;
        Thing[ItemCount].strDescri  := 'This is the corpse of an intelligent being';
      end
      else
      begin
        Thing[ItemCount].intEffect := 1;
        Thing[ItemCount].intRange := MonTe[i].intLvl;
        Thing[ItemCount].strDescri  := 'This is the corpse of a dead creature';
      end;

      if MonTe[i].blPoison = true then
      begin
        Thing[ItemCount].intEffect := 45;
        Thing[ItemCount].intRange := MonTe[i].intLvl;
        Thing[ItemCount].strDescri  := 'This is the poisonous corpse of a dead creature';
      end;
    end
    else
    begin
      // writeln ('Skipping corpse creation for ' + MonTe[i].strName);
    end;
  end;

  Shops[1] := 'Food & Drinks';
  Shops[2] := 'Weapons & Tools';
  Shops[3] := 'the armour smith';
  Shops[4] := 'the library';
  Shops[5] := 'the hospital';
  Shops[6] := 'the restaurant';
  Shops[7] := 'the academy';
  Shops[8] := 'resource workshop';

  chBuilding[1] := chr(144);
  chBuilding[2] := chr(139);
  chBuilding[3] := chr(140);
  chBuilding[4] := chr(141);
  chBuilding[5] := chr(197);
  chBuilding[6] := chr(201);
  chBuilding[7] := chr(200);
  chBuilding[8] := chr(202);
end;


// create weapon variants for combining weapons with runes
procedure WeaponVariants;
var
  i, tid: integer;
begin
  tid := ItemCount;

  //writeln ('Items so far: ' + IntToStr(tid) + ' (last: '+Thing[tid].strRealName+')');

  for i:=1 to tid do
  begin

    if (thing[i].blWield=true) and (thing[i].intRuneSet=0) then
    begin

      // Beithe
      inc(ItemCount);
      //writeln ('Creating Beithe variant for ' + thing[i].strRealName);


      thing[ItemCount] := thing[i];
      thing[ItemCount].strRealName := 'Beithe' + chr(39) + 's '+thing[i].strRealName;
      thing[ItemCount].strName := thing[ItemCount].strRealName;

      thing[ItemCount].strDescri := 'A rune of Beithe is attached to this weapon';

      inc(thing[ItemCount].intAP);

      if (thing[ItemCount].blRare = false) and (thing[ItemCount].blUnique = false) then
        thing[ItemCount].blRare := true;

      // hUath
      inc(ItemCount);
      //writeln ('Creating hUath variant for ' + thing[i].strRealName);

      thing[ItemCount] := thing[i];
      thing[ItemCount].strRealName := 'hUath' + chr(39) + 's '+thing[i].strRealName;
      thing[ItemCount].strName := thing[ItemCount].strRealName;

      thing[ItemCount].strDescri := 'A rune of hUath is attached to this weapon';

      if thing[ItemCount].intGP > 0 then
        inc(thing[ItemCount].intGP)
      else
        inc(thing[ItemCount].intWP);

      if (thing[ItemCount].blRare = false) and (thing[ItemCount].blUnique = false) then
        thing[ItemCount].blRare := true;

      // Muin
      inc(ItemCount);
      //writeln ('Creating Muin variant for ' + thing[i].strRealName);

      thing[ItemCount] := thing[i];
      thing[ItemCount].strRealName := 'Muin' + chr(39) + 's '+thing[i].strRealName;
      thing[ItemCount].strName := thing[ItemCount].strRealName;

      thing[ItemCount].strDescri := 'A rune of Muin is attached to this weapon';

      if thing[ItemCount].intGP > 0 then
        inc(thing[ItemCount].intGP, 2)
      else
        inc(thing[ItemCount].intWP, 2);

      if (thing[ItemCount].blRare = false) and (thing[ItemCount].blUnique = false) then
        thing[ItemCount].blRare := true;

      // Ailm
      inc(ItemCount);
      //writeln ('Creating Ailm variant for ' + thing[i].strRealName);

      thing[ItemCount].strDescri := 'A rune of Ailm is attached to this weapon';

      thing[ItemCount] := thing[i];
      thing[ItemCount].strRealName := 'Ailm' + chr(39) + 's '+thing[i].strRealName;
      thing[ItemCount].strName := thing[ItemCount].strRealName;

      inc(thing[ItemCount].intAP, 2);

      if (thing[ItemCount].blRare = false) and (thing[ItemCount].blUnique = false) then
        thing[ItemCount].blRare := true;

    end;

  end;

end;


procedure CraftingReceipts;
var
  i, k, j, n, tid, ub, lb : integer;
  strAdj, strName, strOwner, strType, strReqItem: string;
  lw, lm, ll, ls: longint;
begin

  for i:=1 to WinLevel do
    for j:=1 to 5 do
    begin
      ItemReceipt[i,j].strName := '-';
      ItemReceipt[i,j].chLetter:=chr(156);
      ItemReceipt[i,j].longWood := 0;
      ItemReceipt[i,j].longMetal := 0;
      ItemReceipt[i,j].longStone := 0;
      ItemReceipt[i,j].longLeather := 0;
      ItemReceipt[i,j].strItem := '-';
    end;


  tid := ItemCount;
  // writeln ('Hardcoded Items: ' + IntToStr(tid) + ' (last: '+Thing[tid].strRealName+')');

  for i:=1 to WinLevel do
  begin
    if (i=1) or (i=5) or (i=10) or (i=15) then
    begin
      for j:=1 to 5 do
      begin

        inc(tid);

        // 1. Adjektiv und Besitzer bestimmen

        //    - Adjektiv
        n := random(31);
        case n of
          0: strAdj := 'Long';
          1: strAdj := 'Short';
          2: strAdj := 'Broad';
          3: strAdj := 'Jagged';
          4: strAdj := 'Smooth';
          5: strAdj := 'Holy';
          6: strAdj := 'Shiny';
          7: strAdj := 'Great';
          8: strAdj := 'Dark';
          9: strAdj := 'Cold';
          10: strAdj := 'Hot';
          11: strAdj := 'Abuzz';
          12: strAdj := 'Moist';
          13: strAdj := 'Frozen';
          14: strAdj := 'Glowing';
          15: strAdj := 'Agile';
          16: strAdj := 'Light';
          17: strAdj := 'Soaking';
          18: strAdj := 'Curing';
          19: strAdj := 'Awake';
          20: strAdj := 'Magic';
          21..30: strAdj := '-';
        end;


        //    - Besitzer (sorgt fuer unique items, aber nur in tieferen levels)
        if i>5 then
        begin
          n := random(31);
          case n of
            0: strOwner := 'Ajuna';
            1: strOwner := 'Thagor';
            2: strOwner := 'Krice';
            3: strOwner := 'Feera';
            4: strOwner := 'Apoll';
            5: strOwner := 'Dionysa';
            6: strOwner := 'Avi';
            7: strOwner := 'Cerno';
            8: strOwner := 'Aphrodite';
            9: strOwner := 'Yron';
            10: strOwner := 'Ahna';
            11: strOwner := 'Python';
            12: strOwner := 'Darcy';
            13: strOwner := 'Ares';
            14: strOwner := 'Hermes';
            15: strOwner := 'Brian';
            16..30: strOwner := '-';
          end;
        end
        else
          strOwner := '-';


        // 2. Namen und Typ bestimmen

        k := 1+random(5);
        if k=1 then // Waffe
        begin
          n := random(16);
          case n of
            0: begin
                 strName := 'Ono';
                 strType := 'axe';
               end;
            1: begin
                 strName := 'Kopis';
                 strType := 'sword';
               end;
            2: begin
                 strName := 'Siyah';
                 strType := 'gun';
               end;
            3: begin
                 strName := 'Pistol';
                 strType := 'gun';
               end;
            4: begin
                 strName := 'Cutlass';
                 strType := 'sword';
               end;
            5: begin
                 strName := 'Stiletto';
                 strType := 'sword';
               end;
            6: begin
                 strName := 'Valaska';
                 strType := 'axe';
               end;
            7: begin
                 strName := 'Helbard';
                 strType := 'lance';
               end;
            8: begin
                 strName := 'Arcus';
                 strType := 'gun';
               end;
            9: begin
                 strName := 'Nzappazap';
                 strType := 'axe';
               end;
           10: begin
                 strName := 'Sagaris';
                 strType := 'axe';
               end;
           11: begin
                 strName := 'Gaesum';
                 strType := 'lance';
               end;
           12: begin
                 strName := 'Aklys';
                 strType := 'lance';
               end;
           13: begin
                 strName := 'Sica';
                 strType := 'sword';
               end;
           14: begin
                 strName := 'Verutum';
                 strType := 'lance';
               end;
           15: begin
                 strName := 'Funda';
                 strType := 'gun';
               end;
          end;
        end;

        if k=2 then // Schild
        begin
          n := random(34);
          case n of
            0..4: strName := 'Scutum';
            5..9: strName := 'Parma';
            10..13: strName := 'Pavise';
            14..18: strName := 'Pelta';
            19..23: strName := 'Cetratus';
            24..29: strName := 'Caetra';
            30..33: strName := 'Clipeus';
          end;
          strType := 'shield';
        end;

        if k=3 then // Ruestung
        begin
          n := random(30);
          case n of
            0..4: strName :=  'Uniform';
            5..9: strName :=  'Jacket';
            10..13: strName := 'Livery';
            14..18: strName := 'Overalls';
            19..23: strName := 'Mail';
            24..29: strName := 'Sagum';
          end;
          strType := 'armour';
        end;

        if k=4 then // Schuhe
        begin
          n := random (3);
          case n of
            0: strName :=  'Balmoral';
            1: strName := 'Bootie';
            2: strName := 'Caliga';
          end;
          strType := 'shoes';
        end;


        if k=5 then // Ring
        begin
          n := random (4);
          case n of
            0: strName := 'Signet Ring';
            1: strName := 'Class Ring';
            2: strName := 'Glass Ring';
            3: strName := 'Thin Ring';
          end;
          strType := 'ring';
        end;


        // 3. Itemeintrag erstellen

        //    - Name
        if strOwner<>'-' then
        begin
          if strAdj<>'-' then
            Thing[tid].strName := strOwner + chr(39) + 's ' + strAdj + ' ' + strName
          else
            Thing[tid].strName := strOwner + chr(39) + 's ' + strName;
        end
        else
          if strAdj<>'-' then
            Thing[tid].strName := strAdj + ' ' + strName
          else
            Thing[tid].strName := strName;

        //    - tatsaechlicher Name
        Thing[tid].strRealName := Thing[tid].strName;


        // writeln ('On-the-fly-creation of item '+IntToStr(tid)+': ' + Thing[tid].strRealName + ' (' + strType + ')');

        //    - Symbol
        if strType='axe' then
          Thing[tid].chLetter := chr(159);

        if strType='sword' then
          Thing[tid].chLetter := chr(156);

        if strType='lance' then
          Thing[tid].chLetter := chr(164);

        if strType='gun' then
          Thing[tid].chLetter := chr(158);

        if strType='shield' then
          Thing[tid].chLetter := chr(246);

        if strType='armour' then
          Thing[tid].chLetter := chr(157);

        if strType='ring' then
          Thing[tid].chLetter := chr(166);

        if strType='shoes' then
          Thing[tid].chLetter := chr(247);


        // 4. Basiswerte festlegen

        Thing[tid].intWP:=0;
        Thing[tid].intGP:=0;
        Thing[tid].intAP:=0;
        Thing[tid].intCharLvl:=lb;
        Thing[tid].intStrength := 80;
        Thing[tid].blRare := true;
        Thing[tid].strDescri := '-';


        //    - unique items haben bonus von 1 oder 2 auf ihre Werte
        ub:=0;
        if strOwner<>'-' then
          ub := 1;

        //    - levelbonus
        lb := 0;
        case i of
          1 : lb := 8;
          5 : lb := 13;
          10: lb := 23;
          15: lb := 33;
        end;

        //    - Waffen
        if (strType='axe') or (strType='sword') or (strType='lance') or (strType='gun') then
        begin

          // Waffe tragbar machen
          Thing[tid].blWield := true;

          // Gewicht anpassen
          if (strAdj='Long') or (strAdj='Great') then
            Thing[tid].intStrength:=80;
          if (strAdj='Short') then
            Thing[tid].intStrength:=50;
          if (strAdj='Agile') or (strAdj='Light') then
            Thing[tid].intStrength:=30;

          // Schaden bestimmen
          if strType<>'gun' then
          begin
            Thing[tid].intWP := lb+random(3)+ub;
            Thing[tid].intGP := 0;

            // lange oder grosse Waffen haben doppelten Schaden
            if (strAdj='Long') or (strAdj='Great') then
              inc(Thing[tid].intWP, Thing[tid].intWP);

          end
          else
          begin
            Thing[tid].intWP := 0;
            Thing[tid].intGP := lb+random(3)+ub;

            // Munitionstyp bestimmen ...
            if strName='Siyah' then  // Boegen nutzen Pfeile oder Lange Pfeile
            begin
              if (strAdj='Long') or (strAdj='Great') then
              begin
                Thing[tid].intNeedsAmmu := 2;
                Thing[tid].strDescri := 'A longbow; uses large arrows';
              end
              else
              begin
                Thing[tid].intNeedsAmmu := 1;
                Thing[tid].strDescri := 'A medium-sized bow; uses small arrows';
              end;
            end
            else
            if strName='Funda' then  // Funda (Schleuder) nutzt Steine
            begin
              Thing[tid].intNeedsAmmu := 5;
              Thing[tid].strDescri := 'A slingshot; uses rubble as ammunition';
            end
            else
            begin  // Armbrueste nutzen Bolzen oder Lange Bolzen
              if (strAdj='Long') or (strAdj='Great') then
              begin
                Thing[tid].intNeedsAmmu := 4;
                Thing[tid].strDescri := 'A crossbow; uses long bolts';
              end
              else
              begin
                Thing[tid].intNeedsAmmu := 3;
                Thing[tid].strDescri := 'A bow; uses small bolts';
              end;
            end;
          end;

          // Lanzen haben zusaetzlich Verteidigung
          if strType='lance' then
            Thing[tid].intAP := 1+random(3)+ub;

          // Zweihandwaffen
          if (strAdj='Long') or (strAdj='Great') or (strType='lance') then
            Thing[tid].blTwoHands := true;

          // Bonus
          if random(400)>350 then
            Thing[tid].intAP := 1+random(2);

        end;


        //   - Schilde
        if strType='shield' then
        begin
          Thing[tid].blExtra := true;
          Thing[tid].intAP := (lb+ub) div 2;

          if random(400)>350 then
            Thing[tid].intWP := 1+random(3);

          if random(400)>350 then
            Thing[tid].intGP := 1+random(3);
        end;


        //   - Ruestungen, Schuhe
        if (strType='armour') or (strType='shoes') then
        begin

          if strType='armour' then
          begin
            Thing[tid].intAP := (lb+ub) div 2;
            Thing[tid].blWear := true;

            if random(400)>350 then
              Thing[tid].intWP := 1+random(3);

            if random(400)>350 then
              Thing[tid].intGP := 1+random(3);
          end;

          if strType='shoes' then
          begin
            Thing[tid].intAP := (lb+ub) div 3;
            Thing[tid].blShoes := true;

            if random(400)>350 then
              Thing[tid].intWP := 1+random(3);

            if random(400)>350 then
              Thing[tid].intGP := 1+random(3);
          end;
        end;


        //  - Ringe
        if strType='ring' then
        begin
          Thing[tid].blRing:=true;

          if random(400)>350 then
            Thing[tid].intAP := 1+random(3);

          if random(400)>350 then
            Thing[tid].intWP := 1+random(3);

          if random(400)>350 then
            Thing[tid].intGP := 1+random(3);
        end;


        // 5. Special Effects festlegen, basierend auf Adjektiv
        //    dies bestimmt dann auch strReqItem

        Thing[tid].intEffect:=0;

        strReqItem:='-';

        // - Schadensbonus fuer Waffen
        if (strAdj='Jagged') and ((strType='sword') or (strType='axe') or (strType='ring') or (strType='lance')) then
           inc(Thing[tid].intWP);

        // - Ruestungsbonus
        if (strAdj='Jagged') and ((strType='armour') or (strType='shield') or (strType='ring') or (strType='shoes')) then
           inc(Thing[tid].intAP);


        // - Curseresistenz
        if strAdj='Holy' then
        begin
           Thing[tid].intEffect:=31;
           strReqItem:='Sanctum';
        end;

        // - HP Regen.
        if strAdj='Curing' then
        begin
           Thing[tid].intEffect:=4;
           strReqItem:='Crystal of "Cure"';
        end;

        // - PP Regen.
        if strAdj='Awake' then
        begin
           Thing[tid].intEffect:=3;
           strReqItem:='Coffee';
        end;


        // - Helligkeit fuer dunkle Bereiche
        if strAdj='Shiny' then
        begin
           Thing[tid].intEffect:=48;
           strReqItem:='Lantern';
        end;


        // - Blindheitresistenz
        if strAdj='Dark' then
        begin
           Thing[tid].intEffect:=17;
           strReqItem:='Open Eye Potion';
        end;

        // - Eisschaden
        if (strAdj='Frozen') and ((strType='sword') or (strType='axe') or (strType='lance')) then
        begin
           Thing[tid].intEffect:=39;
           if i=1 then
             strReqItem:='Crystal of "Cold"';
           if i=5 then
             strReqItem:='Crystal of "Icebolt"';
           if (i=10) or (i=15) then
             strReqItem:='Crystal of "Avalanche"';
        end;

        // - Feuerschaden
        if (strAdj='Glowing') and ((strType='sword') or (strType='axe') or (strType='lance')) then
        begin
           Thing[tid].intEffect:=38;
           if i=1 then
             strReqItem:='Crystal of "Flame"';
           if i=5 then
             strReqItem:='Crystal of "Firebolt"';
           if (i=10) or (i=15) then
             strReqItem:='Crystal of "Inferno"';
        end;

        // - Elektroschaden
        if (strAdj='Abuzz') and ((strType='sword') or (strType='axe') or (strType='lance')) then
        begin
           Thing[tid].intEffect:=56;
           strReqItem:='Crystal of "Flash"';
        end;

        // - Wasserschaden
        if (strAdj='Moist') and ((strType='sword') or (strType='axe') or (strType='lance')) then
        begin
           Thing[tid].intEffect:=40;
           if i=1 then
             strReqItem:='Crystal of "Stream"';
           if i=5 then
             strReqItem:='Crystal of "Wave"';
           if (i=10) or (i=15) then
             strReqItem:='Crystal of "Tsunami"';
        end;

        // - Feuerresistenz
        if (strAdj='Cold') or ((strAdj='Moist') and ((strType='armour') or (strType='shield') or (strType='shoes') or (strType='ring'))) then
        begin
           Thing[tid].intEffect:=13;
           if i=1 then
             strReqItem:='Crystal of "Flame"';
           if i=5 then
             strReqItem:='Crystal of "Firebolt"';
           if (i=10) or (i=15) then
             strReqItem:='Crystal of "Inferno"';
        end;

        // - Eisresistenz
        if strAdj='Hot' then
        begin
           Thing[tid].intEffect:=14;
           if i=1 then
             strReqItem:='Crystal of "Cold"';
           if i=5 then
             strReqItem:='Crystal of "Icebolt"';
           if (i=10) or (i=15) then
             strReqItem:='Crystal of "Avalanche"';
        end;

        // - Wasserresistenz
        if strAdj='Soaking' then
        begin
           Thing[tid].intEffect:=35;
           strReqItem:='Dry Potion';
        end;

        // - Elektroresistenz
        if strAdj='Abuzz' then
        begin
           Thing[tid].intEffect:=55;
           strReqItem:='Crystal of "Flash"';
        end;

        // - Max. Move
        if strAdj='Agile' then
        begin
           Thing[tid].intEffect:=25;
           strReqItem:='Amphetamine';
        end;

        // - Max. Magic
        if strAdj='Magic' then
        begin
           Thing[tid].intEffect:=37;
           strReqItem:='Coffee Set';
        end;

        // Effektstaerke
        if Thing[tid].intEffect>0 then
           Thing[tid].intRange:=lb+ub;



        // 6. abschliessende Dinge:

        //    - alle Gegenstaende mit Owner unique machen
        if strOwner<>'-' then
          Thing[tid].blUnique:=true;

        //    - dafuer sorgen, dass es nicht aus Versehen gedroppt wird
        Thing[tid].intMinLvl:=99;

        //    - Preis bestimmen (fuer Verkauf)
        Thing[tid].intPrice:=25 * (Thing[tid].intWP+Thing[tid].intGP+Thing[tid].intAP);

        if Thing[tid].intEffect>0 then
           inc(Thing[tid].intPrice, 100);

        //    - Charakterlevel festlegen
        Thing[tid].intCharLvl := i+ub;



        // 7. Ressourcen festlegen, die zur Herstellung noetig sind
        lw:=0;
        lm:=0;
        ls:=0;
        ll:=0;

        //    - Holz fuer Axt, Schwert, Lanze, Schild, Bogen
        if (strType='axe') or (strType='lance') or (strType='sword') or (strType='shield') or (strType='gun') then
        begin
          inc(lw, 24*(lb+ub));
          if strType='lance' then
            inc(lw, 20);
          if strType='shield' then
            inc(lw, 35);
          inc(lw, random(30));
        end;

        //    - Metall fuer Axt, Schwert, Lanze, Ring, Ruestung, Schild
        if (strType='axe') or (strType='lance') or (strType='sword') or (strType='ring') or (strType='armour') then
        begin
          inc(lm, 34*(lb+ub));
          if strType='sword' then
            inc(lm, 20);
          if strType='shield' then
            inc(lm, 15);
          inc(lm, random(30));
          if strType='ring' then
            lm := lm div 2;
        end;

        //    - Stein, zufaellig fuer Axt, Schwert, Lanze, Ring, Schild
        if (strType='axe') or (strType='lance') or (strType='sword') or (strType='ring') or (strType='armour') or (strType='shield') then
        begin
          if random(400)>200 then
          begin
            inc(ls, 8*(lb+ub));
            if strType='ring' then
              ls := ls div 2;
          end;
        end;

        //    - Leder, fuer Ruestung und Schuhe
        if (strType='armour') or (strType='shoes') then
        begin
          inc(ll, 42*(lb+ub));
          if strType='shoes' then
            ll := ll div 2;
        end;


        // 8. Rezept fuer Workshop erstellen

        //    - Grunddaten uebertragen
        ItemReceipt[i,j].strName := Thing[tid].strRealName;
        ItemReceipt[i,j].chLetter := Thing[tid].chLetter;

        //    - Resourcen festlegen
        ItemReceipt[i,j].longWood := lw;
        ItemReceipt[i,j].longMetal := lm;
        ItemReceipt[i,j].longStone := ls;
        ItemReceipt[i,j].longLeather := ll;

        //    - Item noetig, um Item zu erstellen?
        if strReqItem<>'-' then
          ItemReceipt[i,j].strItem := strReqItem
        else
          ItemReceipt[i,j].strItem := '-';

      end;
    end;
  end;

  // Gesamtzahl der Items anpassen
  ItemCount := tid;
end;


end.
