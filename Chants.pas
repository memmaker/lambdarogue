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

unit Chants;


interface

uses
  Constants, SysUtils;

const
  MaxChant = 100;



type
  Chant = record
    strName:    string;
    intEffect, intRange, intPP, intRefresh, intIcon: integer;
    strDescri, strEfText: string;
    intCharLvl: longint;
  end;

type
  ChantEntry = record
    intType:    integer;
    blKnown:    boolean;
    intKnown:   integer;
    intRefresh: integer;
  end;

var
  Spell:      array[1..MaxChant] of Chant;
  SpellBook:  array[1..16] of ChantEntry;
  ChantCount: longint;


procedure ChantInit;
function ReturnSpellByName(s: string): integer;
function PlayerHasSpell(strName: string): integer;

implementation


// return number of chant in spellbook
function PlayerHasSpell(strName: string): integer;
var
  i: integer;
begin
  PlayerHasSpell := -1;
  for i := 1 to 12 do
    if Spellbook[i].intType > 0 then
      if Spell[Spellbook[i].intType].strName = strName then
        PlayerHasSpell := i;
end;

// return spell id by item name
function ReturnSpellByName(s: string): integer;
var
  i: integer;
begin
  i := 0;
  repeat
    Inc(i);
  until (i = ChantCount) or (spell[i].strName = s);
  ReturnSpellByName := i;
end;



procedure ChantInit;
var
  ChantFile: textfile;
  i: integer;
  strKey, strValue: string;
begin

  for i := 1 to MaxChant do
  begin
    with Spell[i] do
    begin
      intPP      := 0;
      strDescri  := '';
      intEffect  := 0;
      strEfText  := '';
      intRange   := 0;
      intCharLvl := 1;
      intIcon    := 18;
      intRefresh := 3;
    end;
  end;

  strKey   := '';
  strValue := '';

  Assign(ChantFile, CONST_DATADIR + 'data/chants.txt');
  Reset(ChantFile);

  i := 0;

  while EOF(ChantFile) = False do
  begin
    repeat
      ReadLn(ChantFile, strKey);
    until ((strKey <> '') and (strKey[1] <> '#')) or (EOF(ChantFile));

    ReadLn(ChantFile, strValue);

    if strKey = 'NewChant:' then
      Inc(i);

    if i > 0 then
    begin
      if strKey = 'NewChant:' then
        Spell[i].strName := strValue;

      if strKey = 'Icon:' then
        Spell[i].intIcon := StrToInt(strValue);

      if strKey = 'Description:' then
        Spell[i].strDescri := strValue;

      if strKey = 'EffectText:' then
        Spell[i].strEfText := strValue;

      if strKey = 'EffectType' then
      begin
        if strValue = '= DecHunger' then
          Spell[i].intEffect := 1;
        if strValue = '= DecPoison' then
          Spell[i].intEffect := 2;
        if strValue = '= IncPoison' then
          Spell[i].intEffect := 45;
        if strValue = '= IncHP' then
          Spell[i].intEffect := 4;
        if strValue = '= BecomeInvisible' then
          Spell[i].intEffect := 5;
        if strValue = '= FireAura' then
          Spell[i].intEffect := 8;
        if strValue = '= IceAura' then
          Spell[i].intEffect := 9;
        if strValue = '= DecConfusion' then
          Spell[i].intEffect := 12;
        if strValue = '= ResistFire' then
          Spell[i].intEffect := 13;
        if strValue = '= ResistIce' then
          Spell[i].intEffect := 14;
        if strValue = '= MagicWall' then
          Spell[i].intEffect := 15;
        if strValue = '= Pain' then
          Spell[i].intEffect := 16;
        if strValue = '= ResistBlindness' then
          Spell[i].intEffect := 17;
        if strValue = '= DecBlindness' then
          Spell[i].intEffect := 18;
        if strValue = '= Force' then
          Spell[i].intEffect := 19;
        if strValue = '= HealAura' then
          Spell[i].intEffect := 20;
        if strValue = '= Teleport' then
          Spell[i].intEffect := 21;
        if strValue = '= WaterAura' then
          Spell[i].intEffect := 22;
        if strValue = '= DecHP' then
          Spell[i].intEffect := 23;
        if strValue = '= DecPP' then
          Spell[i].intEffect := 24;
        if strValue = '= ResistParalyze' then
          Spell[i].intEffect := 26;
        if strValue = '= DecPara' then
          Spell[i].intEffect := 27;
        if strValue = '= FreezeTime' then
          Spell[i].intEffect := 30;
        if strValue = '= Uncurse' then
          Spell[i].intEffect := 32;
        if strValue = '= Bless' then
          Spell[i].intEffect := 33;
        if strValue = '= Fire' then
          Spell[i].intEffect := 38;
        if strValue = '= Ice' then
          Spell[i].intEffect := 39;
        if strValue = '= Water' then
          Spell[i].intEffect := 40;
        if strValue = '= Identify' then
          Spell[i].intEffect := 47;
        if strValue = '= Lichtbringer' then
          Spell[i].intEffect := 48;
        if strValue = '= FamiliarTerrain' then
          Spell[i].intEffect := 54;
        if strValue = '= ResistElectricity' then
          Spell[i].intEffect := 55;
        if strValue = '= Electricity' then
          Spell[i].intEffect := 56;
        if strValue = '= AreaDamage' then
          Spell[i].intEffect := 58;
      end;

      if strKey = 'EffectRange:' then
        Spell[i].intRange := StrToInt(strValue);

      // calculate refresh rate
      Spell[i].intRefresh := Spell[i].intRange;
      if Spell[i].intRefresh > 40 then
        Spell[i].intRefresh := 40;

      if Spell[i].intRefresh < 10 then
        Spell[i].intRefresh := 10;

      // calculate PP cost
      Spell[i].intPP := Spell[i].intRange + Spell[i].intRefresh;
      if Spell[i].intPP > 100 then
        Spell [i].intPP := 100;

      // special spell rates
      if (Spell[i].strName='Blitzeis') or (Spell[i].strName='Fastflame') then
      begin
        Spell[i].intRefresh := 1;
        inc (Spell[i].intPP, Spell[i].intRange);
      end;


      if strKey = 'CharLvl:' then
        Spell[i].intCharLvl := StrToInt(strValue);
    end;
  end;

  Close(ChantFile);

  ChantCount := i;
end;

end.
