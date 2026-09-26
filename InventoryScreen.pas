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

unit InventoryScreen;


interface

uses
  ExternSFX, Crt, Keyboard, Video, Input, Plot, Effects, Constants,
  SysUtils, SDL, RandomArea, CollectData, Player, Chants, Items,
  BaseOutput, GFX, UserInterface, MessageLog, DrawDungeon;

var
  DecoIcon, DecoIconS: SDL_RECT;

procedure EquipmentInfo;
procedure ItemInfo(id: integer);
procedure ShowInventory;
function CloneItem(): string;
function IdentifyItem(): string;
function ReturnSameItemInventorySlot(t: integer): integer;
function ReturnFreeInventorySlot: integer;
procedure BurnInventoryItem;
procedure ListAllItems;


implementation

// randomly selects an enflammable item and burns it
procedure BurnInventoryItem;
var
  i: integer;
  burned: boolean;
begin
  if CheckEffect(13)=false then
  begin
    burned:=false;
    for i:=1 to 16 do
      if inventory[i].intType>0 then
        if Thing[inventory[i].intType].chLetter = chr(193) then // only paper items
          if inventory[i].longNumber>0 then
            if (burned=false) and (random(500) > CONST_ITEMBURNCHANCE) then
            begin
              ShowTransMessage ('The '+Thing[inventory[i].intType].strName+' in your inventory burns to dust.', false);
              dec(inventory[i].longNumber);
              if inventory[i].longNumber=0 then
                inventory[i].intType:=0;
              burned:=true;
            end;
  end;
end;

// returns the first slot in inventory which holds the given item type, or -1 if none
function ReturnSameItemInventorySlot(t: integer): integer;
var
  n, i: integer;
begin
  n := -1;
  for i := 16 downto 1 do
    if (inventory[i].intType = t) then
      n := i;
  ReturnSameItemInventorySlot := n;
end;

// returns the first free slot in inventory, or -1 if none is free
function ReturnFreeInventorySlot: integer;
var
  n, i: integer;
begin
  n := -1;
  for i := 16 downto 1 do
    if inventory[i].intType = 0 then
      n := i;
  ReturnFreeInventorySlot := n;
end;

// This procedure creates the visible list of all items in inventory
procedure ListAllItems;
var
  i:    integer;
  equi: char;
begin
  // list all items
  for i := 1 to 16 do
  begin
    equi := chr(32);
    if inventory[i].intType > 0 then
    begin

      // rating icon for armour-type items
      if ThePlayer.intArmour > 0 then
      begin
        if thing[Inventory[i].intType].intAP > 0 then
          if thing[Inventory[i].intType].blWear = True then
          begin
            if thing[Inventory[i].intType].intAP >
              thing[ThePlayer.intArmour].intAP then
              equi := chr(214);
            if thing[Inventory[i].intType].intAP <
              thing[ThePlayer.intArmour].intAP then
              equi := chr(215);
            if thing[Inventory[i].intType].intAP =
              thing[ThePlayer.intArmour].intAP then
              equi := chr(216);
          end;

        if thing[Inventory[i].intType].blIdentified = False then
          if thing[Inventory[i].intType].blWear = True then
            equi := chr(217);
      end;

      // rating icon for hat-type items
      if ThePlayer.intHat > 0 then
      begin
        if thing[Inventory[i].intType].intAP > 0 then
          if thing[Inventory[i].intType].blHat = True then
          begin
            if thing[Inventory[i].intType].intAP >
              thing[ThePlayer.intHat].intAP then
              equi := chr(214);
            if thing[Inventory[i].intType].intAP <
              thing[ThePlayer.intHat].intAP then
              equi := chr(215);
            if thing[Inventory[i].intType].intAP =
              thing[ThePlayer.intHat].intAP then
              equi := chr(216);
          end;

        if thing[Inventory[i].intType].blIdentified = False then
          if thing[Inventory[i].intType].blHat = True then
            equi := chr(217);
      end;

      // rating icon for shoes-type items
      if ThePlayer.intFeet > 0 then
      begin
        if thing[Inventory[i].intType].intAP > 0 then
          if thing[Inventory[i].intType].blShoes = True then
          begin
            if thing[Inventory[i].intType].intAP >
              thing[ThePlayer.intFeet].intAP then
              equi := chr(214);
            if thing[Inventory[i].intType].intAP <
              thing[ThePlayer.intFeet].intAP then
              equi := chr(215);
            if thing[Inventory[i].intType].intAP =
              thing[ThePlayer.intFeet].intAP then
              equi := chr(216);
          end;

        if thing[Inventory[i].intType].blIdentified = False then
          if thing[Inventory[i].intType].blShoes = True then
            equi := chr(217);
      end;

      // rating icon for armour-type items
      if ThePlayer.intExtra > 0 then
      begin
        if thing[Inventory[i].intType].intAP > 0 then
          if thing[Inventory[i].intType].blExtra = True then
          begin
            if thing[Inventory[i].intType].intAP >
              thing[ThePlayer.intExtra].intAP then
              equi := chr(214);
            if thing[Inventory[i].intType].intAP <
              thing[ThePlayer.intExtra].intAP then
              equi := chr(215);
            if thing[Inventory[i].intType].intAP =
              thing[ThePlayer.intExtra].intAP then
              equi := chr(216);
          end;

        if thing[Inventory[i].intType].blIdentified = False then
          if thing[Inventory[i].intType].blExtra = True then
            equi := chr(217);
      end;

      // rating-icon for weapon-type items
      if ThePlayer.intWeapon > 0 then
      begin
        if thing[Inventory[i].intType].intWP > 0 then
          if thing[ThePlayer.intWeapon].intWP > 0 then
            if thing[Inventory[i].intType].blWield = True then
            begin
              if thing[Inventory[i].intType].intWP >
                thing[ThePlayer.intWeapon].intWP then
                equi := chr(214);
              if thing[Inventory[i].intType].intWP <
                thing[ThePlayer.intWeapon].intWP then
                equi := chr(215);
              if thing[Inventory[i].intType].intWP =
                thing[ThePlayer.intWeapon].intWP then
                equi := chr(216);
            end;

        if thing[Inventory[i].intType].intGP > 0 then
          if thing[ThePlayer.intWeapon].intGP > 0 then
            if thing[Inventory[i].intType].blWield = True then
            begin
              if thing[Inventory[i].intType].intGP >
                thing[ThePlayer.intWeapon].intGP then
                equi := chr(214);
              if thing[Inventory[i].intType].intGP <
                thing[ThePlayer.intWeapon].intGP then
                equi := chr(215);
              if thing[Inventory[i].intType].intGP =
                thing[ThePlayer.intWeapon].intGP then
                equi := chr(216);
            end;

        if thing[Inventory[i].intType].blIdentified = False then
          if thing[Inventory[i].intType].blWield = True then
            equi := chr(217);
      end;

      // icon for items with a higher clvl
      if ThePlayer.intLvl < Thing[Inventory[i].intType].intCharLvl then
        equi := chr(218);

      // output the list entry
      TransTextXY(1, 4 + i, IntToStr(i)); // slot

      // icon; corpses look like food here
      if thing[inventory[i].intType].chLetter=chr(37) then
        CharXY(5, 4 + i, chr(168), 0, true)
      else
        CharXY(5, 4 + i, thing[inventory[i].intType].chLetter, 0, true);

      // output the colored item name
      SetItemNameColor (thing[inventory[i].intType].strRealName); // item name color
      TransTextXY(6, 4 + i, thing[inventory[i].intType].strName); // name
      GlobalFontColor := FONTCOLOR_WHITE;
      GlobalConColor := -1;


      TransTextXY(38, 4 + i, 'x' + IntToStr(inventory[i].longNumber)); // amount

      if equi<>chr(32) then
        CharXY(43, 4 + i, equi, 0, true); // equipment?
    end;
  end;

end;

// this procedure creates the visible equipment list
procedure ListEquipment;
begin

  if ThePlayer.intWeapon>0 then
  begin
    CharXY(51, 12, thing[ThePlayer.intWeapon].chLetter, 0, true);
    SetItemNameColor(thing[ThePlayer.intWeapon].strName);
    TransTextXY(52, 12, thing[ThePlayer.intWeapon].strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;
  end;

  if ThePlayer.intArmour>0 then
  begin
    CharXY(57, 10, thing[ThePlayer.intArmour].chLetter, 0, true);
    SetItemNameColor(thing[ThePlayer.intArmour].strName);
    TransTextXY(58, 10, thing[ThePlayer.intArmour].strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;
  end;

  if ThePlayer.intFeet>0 then
  begin
    CharXY(57, 20, thing[ThePlayer.intFeet].chLetter, 0, true);
    SetItemNameColor(thing[ThePlayer.intFeet].strName);
    TransTextXY(58, 20, thing[ThePlayer.intFeet].strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;
  end;

  if ThePlayer.intHat>0 then
  begin
    CharXY(57, 5, thing[ThePlayer.intHat].chLetter, 0, true);
    SetItemNameColor(thing[ThePlayer.intHat].strName);
    TransTextXY(58, 5, thing[ThePlayer.intHat].strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;
  end;

  if ThePlayer.intExtra>0 then
  begin
    CharXY(58, 14, thing[ThePlayer.intExtra].chLetter, 0, true);
    SetItemNameColor(thing[ThePlayer.intExtra].strName);
    TransTextXY(59, 14, thing[ThePlayer.intExtra].strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;
  end;

  if ThePlayer.intRingLeft>0 then
  begin
    CharXY(51, 16, thing[ThePlayer.intRingLeft].chLetter, 0, true);
    SetItemNameColor(thing[ThePlayer.intRingLeft].strName);
    TransTextXY(52, 16, thing[ThePlayer.intRingLeft].strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;
  end;

  if ThePlayer.intRingRight>0 then
  begin
    CharXY(51, 17, thing[ThePlayer.intRingRight].chLetter, 0, true);
    SetItemNameColor(thing[ThePlayer.intRingRight].strName);
    TransTextXY(52, 17, thing[ThePlayer.intRingRight].strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;
  end;

end;

// shows information about a selected item
procedure ItemInfo(id: integer);
var
  strSet, effect, strProf, dummy: string;
  IconRect, IconRectS: SDL_RECT;
  TempAnsi: ansistring;
  zz: integer;

begin

  if Thing[id].intEffect > -1 then
    IconRect.x := 38 * (Thing[id].intEffect - 1)
  else
    IconRect.x := 0;

  IconRect.y := 415;
  IconRect.w := 38;
  IconRect.h := 38;

  IconRectS.x := 735 + HiResOffsetX;
  IconRectS.y := 10 + HiResOffsetY;
  IconRectS.w := 38;
  IconRectS.h := 38;

  if UseSDL = True then
  begin
    TempAnsi := 'graphics/invbg.jpg';
    LoadImage_Title('graphics/invbg.jpg');
  end;

  dummy := '-';
  repeat

    if UseSDL = True then
    begin
      BlitImage_Title;
      if Thing[id].intEffect > -1 then
        SDL_BLITSURFACE(extratiles, @IconRect, screen, @IconRectS);
    end
    else
    begin
      DialogWin;
      BottomBar;
    end;

    if Thing[id].strName <> '-' then
    begin

      // CharXY(1, 1, Thing[id].chLetter, 0, true);

      SetItemNameColor(Thing[id].strRealName);
      TransTextXY(1, 1, uppercase(Thing[id].strRealName));
      GlobalFontColor := FONTCOLOR_WHITE;
      GlobalConColor := -1;

      //  1. Beschreibung
      if Thing[id].strDescri <> '-' then
        TransTextXY(8, 4, Thing[id].strDescri + '.');


      //  2. Preis und Rarity

      //  - normal
      strSet := 'common';

      //  - special
      if ((thing[id].intEffect > 0) or (thing[id].blRing = true)) and (thing[id].blEat = false) and (thing[id].blDrink = false) then
        strSet := 'special';

      //  - rare
      if Thing[id].blRare = True then
        strSet := 'rare';

      //  - unique
      if Thing[id].blUnique = True then
        strSet := 'unique';

      // - set item
      if Thing[id].intRuneSet > 0 then
        strSet := 'set item';

      TransTextXY(8, 6, 'Standard Price: ' + IntToStr(Thing[id].intPrice));
      TransTextXY(32, 6, 'Retail Price: ' + IntToStr(CollectSellPrice(id)));
      TransTextXY(54, 6, 'Rarity: ' + strSet);



      //  3. Eigenschaften anzeigen

      TransTextXY(8, 9, 'PROPERTIES');
      zz:=11;


      if Thing[id].blWield = True then
        if Thing[id].blTwoHands = True then
        begin
          TransTextXY(8, zz, 'two-handed');
          inc(zz);
        end;


      if (Thing[id].intWP > 0) and (Thing[id].chLetter<>chr(160)) and (Thing[id].chLetter<>chr(171)) then
        if Thing[id].blWield = True then
        begin
          TransTextXY(8, zz, 'WP: ' + IntToStr(Thing[id].intWP));
          inc(zz);
        end
        else
        begin
          TransTextXY(8, zz, 'Melee bonus: ' + IntToStr(Thing[id].intWP));
          inc(zz);
        end;

      if (Thing[id].intWP > 0) and (Thing[id].chLetter=chr(160)) then
      begin
        TransTextXY(8, zz, 'Ammo damage to WP: ' + IntToStr(Thing[id].intWP));
        inc(zz);
      end;


      if Thing[id].intGP > 0 then
        if Thing[id].blWield = True then
        begin
          TransTextXY(8, zz, 'GP: ' + IntToStr(Thing[id].intGP));
          inc(zz);
        end
        else
        begin
          TransTextXY(8, zz, 'Long-range bonus: ' + IntToStr(Thing[id].intGP));
          inc(zz);
        end;


      if Thing[id].intAP > 0 then
        if (Thing[id].blWear = True) or (Thing[id].blHat = True) or (Thing[id].blShoes = True) or (Thing[id].chLetter=chr(246)) then
        begin
          TransTextXY(8, zz, 'AP: ' + IntToStr(Thing[id].intAP));
          inc(zz);
        end
        else
        begin
          TransTextXY(8, zz, 'Defense bonus: ' + IntToStr(Thing[id].intAP));
          inc(zz);
        end;


      if Thing[id].intSP > 0 then
      begin
        TransTextXY(8, zz, 'SP: ' + IntToStr(Thing[id].intSP));
        inc(zz);
      end;


      if Thing[id].intLight > 0 then
      begin
        TransTextXY(8, zz, 'Light bonus: ' + IntToStr(Thing[id].intLight));
        inc(zz);
      end;

      effect  := '-';
      if Thing[id].intEffect>0 then
        effect := GetEffectDescription(Thing[id].intEffect);

      if effect <> '-' then
      begin
        if (Thing[id].chLetter=chr(155)) or (Thing[id].chLetter=chr(168)) then
          TransTextXY(8, zz, effect + ': ' + IntToStr(Thing[id].intRange))
        else
          TransTextXY(8, zz, effect);
        inc(zz);
      end;


      //  - Set
      strSet := '-';
      if Thing[id].intRuneSet > 0 then
      begin
        strSet := 'set item';

        case Thing[id].intRuneSet of
         1: strSet := 'Set "The Leya Revelation"';
         2: strSet := 'Set "Ynnatar''s Hunt"';
         3: strSet := 'Set "Truth of Bebebe"';
         4: strSet := 'Set "Three Elements of Mineet"';
         5: strSet := 'Set "Wyth''s Wizardry"';
         6: strSet := 'Set "Combat Gear, designed by Adrian Smith"';
         7: strSet := 'Set "Santa''s Celebration Gear"';
         8: strSet := 'Set "Ido''s Finest"';
         end;
      end;

      if strset <> '-' then
      begin
        TransTextXY(8, zz+4, strset);
        case Thing[id].intRuneSet of
         1: strSet := 'Inflicted Physical Damage +25%';
         2: strSet := 'Hit +1 / Fire-arm +1';
         3: strSet := 'Fight +1 / Sword +1';
         4: strSet := 'Fight +1 / Humility +1';
         5: strSet := 'Chant +1 / Hit +1';
         6: strSet := 'Suffered Physical Damage -25%';
         7: strSet := 'Eating becomes unnecessary';
         8: strSet := 'Effect of food and potions is doubled';
        end;
        TransTextXY(8, zz+5, 'Complete Set Bonus: ' + strset);
      end;


      //  5. Anforderungen

      TransTextXY(54, 9, 'REQUIREMENTS');
      zz:=11;

      TransTextXY(54, zz, 'Minimum CLV: ' + IntToStr(Thing[id].intCharLvl));
      inc(zz);

      if Thing[id].blWield = True then
      begin
        TransTextXY(54, zz, 'Minimum STR: ' + IntToStr(Thing[id].intStrength));
        inc(zz);
      end;


      strProf := 'all';
      case Thing[id].intProf of
        2:
          strProf := 'enchanter';
        3:
          strProf := 'thief';
        4:
          strProf := 'archer';
        5:
          strProf := 'soldier';
      end;
      TransTextXY(54, zz, 'Profession: ' + strProf);
      inc(zz);

      strProf := 'all';
      case Thing[id].intSex of
        1:
          strProf := 'male';
        2:
          strProf := 'female';
      end;

      TransTextXY(54, zz, 'Sex: ' + strProf);
      inc(zz);


      dummy := GetKeyInput('[ESC] close', False);
    end;
  until (dummy = 'ESC');
end;


// duplicates a selected item
function CloneItem(): string;
var
  i, n: integer;
  equi: string;
begin

  CloneItem := 'After some thinking, you decide against duplication of an item';

  ClearScreenSDL;

  if UseSDL = True then
  begin
    LoadImage_Title('graphics/equipbg.jpg');
  end;

  repeat

    if UseSDL = True then
      BlitImage_Title
    else
    begin
      StatusDeco;
      DialogWin;
    end;

    TransTextXY(1, 1, 'WHICH ITEM SHOULD BE DUPLICATED?');

    ListAllItems;
    ListEquipment;

    Val(GetTextInput('Selection?', 2), n);

  until (n > -1) and (n < 17) and (Inventory[n].intType > 0);

  if n > 0 then
    if Inventory[n].longNumber > 0 then
      if Thing[Inventory[n].intType].strName = 'Potion of Duplication' then
      begin
        CloneItem := 'You use the potion to duplicate itself, but it does not work.';
      end
      else
      begin
        Inc(Inventory[n].longNumber);
        CloneItem := 'You duplicate the ' + Thing[Inventory[n].intType].strName;
      end;
end;


// identifies an unknown item
function IdentifyItem(): string;
var
  i, n: integer;
  equi: string;
begin

  IdentifyItem := 'You identify nothing';

  if UseSDL = True then
  begin
    LoadImage_Title('graphics/equipbg.jpg');
    BlitImage_Title;
    SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
  end
  else
  begin
    ClearScreenSDL;
    StatusDeco;
    GlobalConColor := darkgray;
    TransTextXY(50, 3,  '     ___    ');
    TransTextXY(50, 4,  '    /   \   ');
    TransTextXY(50, 5,  '    |   |   ');
    TransTextXY(50, 6,  '    \___/   ');
    TransTextXY(50, 7,  '    __|__   ');
    TransTextXY(50, 8,  '   /     \  ');
    TransTextXY(50, 9,  '  //|   |\\ ');
    TransTextXY(50, 10, ' // |   | \\');
    TransTextXY(50, 11, ' || |   | ||');
    TransTextXY(50, 12, ' \\ |___| ||');
    TransTextXY(50, 13, '  \\|/ \| ||');
    TransTextXY(50, 14, '    || ||   ');
    TransTextXY(50, 15, '    || ||   ');
    TransTextXY(50, 16, '    || ||   ');
    TransTextXY(50, 17, '    || ||   ');
    TransTextXY(50, 18, '  _/ / \ \_ ');
    TransTextXY(50, 19, ' /__/   \__\');
    GlobalConColor := -1;
  end;

  TransTextXY(1, 1, 'SELECT ITEM TO IDENTIFY');

  ListAllItems;
  ListEquipment;

  repeat
    Val(GetTextInput('Selection?', 2), n);
  until (n = 0) or ((n > 0) and (n < 17));

  if n > 0 then
    if Inventory[n].longNumber > 0 then
      if Thing[Inventory[n].intType].blIdentified = True then
      begin
        IdentifyItem := 'Identifying this already known item reveals nothing new';
      end
      else
      begin
        Thing[Inventory[n].intType].blIdentified := True;
        Thing[Inventory[n].intType].strName :=
          Thing[Inventory[n].intType].strRealName;
        IdentifyItem :=
          'You identify the item as ' + Thing[Inventory[n].intType].strName;

        // Northdoom?
        if Thing[Inventory[n].intType].strName = 'Northdoom' then
        begin
          PlaySFX('page-turn.mp3');
          ShowText('interlude');
          ShowPlot(22);
        end;
      end;
end;


// bind F-key to Item
procedure BindQuickKey_Item(n: integer);
var
  id: integer;
begin
  id := -1;
  repeat
    Val(GetTextInput('Which item do you want to bind to quickkey F' +
      IntToStr(n) + '?', 2), id);
  until (id = 0) or ((id > 0) and (id < 17) and (Inventory[id].intType > 0));

  if id > 0 then
    if (Thing[inventory[id].intType].blEat = True) or
      (Thing[inventory[id].intType].blDrink = True) then
    begin
      if Thing[inventory[id].intType].blIdentified = True then
      begin
        strQuickKey[n] := Thing[inventory[id].intType].strRealName;
      end
      else
        GetKeyInput('You can only bind identified items to quickkeys.', True);
    end
    else
      GetKeyInput('You can only bind comestibles and potions to quickkeys.', True);
end;

// equip an item
procedure EquipItem;
var
  n: integer;
  blEquipped, blCanEquip: boolean;
begin
  n := -1;

  if (UseSDL = False) or (UseMouseToMove = False) then
    repeat
      BottomBar;
      Val(GetTextInput('Which item do you want to equip?', 2), n);
    until (n = 0) or ((n > 0) and (n < 17) and (Inventory[n].intType > 0));

  if n > 0 then
  begin

    // check for identification
    if Thing[inventory[n].intType].blIdentified = False then
    begin
      GetKeyInput('You can only equip identified items.', True);
      n := 0;
    end
    else
    begin
      // check sex
      if (thing[inventory[n].intType].intSex = 0) or
        (ThePlayer.intSex = thing[inventory[n].intType].intSex) then
      begin
        // check character level
        if ThePlayer.intLvl > thing[inventory[n].intType].intCharLvl - 1 then
        begin
          // check character profession
          if (Thing[inventory[n].intType].intProf = 0) or
            (ThePlayer.intProf = Thing[inventory[n].intType].intProf) then
          begin
            // check if item is equipable
            if (thing[inventory[n].intType].blWear = False) and
              (thing[inventory[n].intType].blWield = False) and
              (thing[inventory[n].intType].blHat = False) and
              (thing[inventory[n].intType].blRing = False) and
              (thing[inventory[n].intType].blShoes = False) and
              (thing[inventory[n].intType].blExtra = False) then
            begin
              GetKeyInput('You can' + chr(39) +
                't equip this item.', True);
            end
            else
            begin

              blEquipped := False;
              blCanEquip := True;

              // ** armour, clothes **
              if thing[inventory[n].intType].blWear then
                if ThePlayer.intArmour = 0 then
                begin
                  ShowTransMessage('You wear the ' +
                    thing[inventory[n].intType].strName + '.', False);
                  ThePlayer.intArmour := inventory[n].intType;
                  blEquipped := True;
                end
                else
                  GetKeyInput('Can''t equip -- remove the ' +
                    thing[ThePlayer.intArmour].strName + ' first.', True);

              // ** weapon **
              if thing[inventory[n].intType].blWield then
                if ThePlayer.intWeapon = 0 then
                begin
                  // two hand weapons?
                  if Thing[inventory[n].intType].blTwoHands = True then
                    if ThePlayer.intExtra > 0 then
                    begin
                      GetKeyInput('Can''t equip the two-handed weapon -- remove the ' +
                        thing[ThePlayer.intExtra].strName + ' first.', True);
                      blCanEquip := False;
                    end;

                  if blCanEquip = True then
                  begin
                    ShowTransMessage('You wield the ' +
                      thing[inventory[n].intType].strName + '.', False);
                    ThePlayer.intWeapon := inventory[n].intType;

                    if Thing[inventory[n].intType].strName =
                      'Northdoom' then
                    begin
                      ThePlayer.blEvil      := True;
                      ThePlayer.intHumility := -6;
                      ThePlayer.longPrayers := 0;
                      GetKeyInput(
                        'Suddenly it becomes death-cold ...', True);
                      ShowPlot(14);
                      ShowPlot(18);
                      ShowTransMessage(
                        'You have entered a dark path and there is no way back.', False);
                    end;

                    blEquipped := True;

                  end;
                end
                else
                  GetKeyInput('Can''t equip -- remove the ' +
                    thing[ThePlayer.intWeapon].strName + ' first.', True);

              // ** hat **
              if thing[inventory[n].intType].blHat then
                if ThePlayer.intHat = 0 then
                begin
                  ShowTransMessage('You put the ' +
                    thing[inventory[n].intType].strName + ' on your head.', False);
                  ThePlayer.intHat := inventory[n].intType;
                  blEquipped := True;
                end
                else
                  GetKeyInput('Can''t equip -- remove the ' +
                    thing[ThePlayer.intHat].strName + ' first.', True);

              // ** rings **
              if thing[inventory[n].intType].blRing then
              begin
                if ThePlayer.intRingLeft = 0 then
                begin
                  ShowTransMessage('You put the ' +
                    thing[inventory[n].intType].strName +
                    ' on your left finger.', False);
                  ThePlayer.intRingLeft := inventory[n].intType;
                  blEquipped := True;
                end
                else
                if ThePlayer.intRingRight = 0 then
                begin
                  ShowTransMessage('You put the ' +
                    thing[inventory[n].intType].strName +
                    ' on your right finger.', False);
                  ThePlayer.intRingRight := inventory[n].intType;
                  blEquipped := True;
                end;
              end;

              // ** shield **
              if thing[inventory[n].intType].blExtra then
                if ThePlayer.intExtra = 0 then
                begin

                  // two hand weapon wielded?
                  if ThePlayer.intWeapon > 0 then
                    if Thing[ThePlayer.intWeapon].blTwoHands = True then
                    begin
                      GetKeyInput('Can''t equip -- remove the two-handed ' +
                        thing[ThePlayer.intWeapon].strName + ' first.', True);
                      blCanEquip := False;
                    end;

                  if blCanEquip = True then
                  begin
                    ShowTransMessage('You take the ' +
                      thing[inventory[n].intType].strName +
                      ' in your right hand.', False);
                    ThePlayer.intExtra := inventory[n].intType;
                    blEquipped := True;
                  end;
                end
                else
                  GetKeyInput('Can''t equip -- remove the ' +
                    thing[ThePlayer.intExtra].strName + ' first.', True);

              // ** shoes **
              if thing[inventory[n].intType].blShoes then
                if ThePlayer.intFeet = 0 then
                begin
                  ShowTransMessage('You put the ' +
                    thing[inventory[n].intType].strName + ' on your feet.', False);
                  ThePlayer.intFeet := inventory[n].intType;
                  blEquipped := True;
                end
                else
                  GetKeyInput('Can''t equip -- remove the ' +
                    thing[ThePlayer.intFeet].strName + ' first.', True);

              // remove the equipped item from inventory
              if blEquipped = True then
              begin
                Dec(inventory[n].longNumber);
                if inventory[n].longNumber = 0 then
                  inventory[n].intType := 0;
              end;

            end;
          end
          else
            GetKeyInput(
              'To equip that item, you have to work as ' +
              PlayProf[Thing[inventory[n].intType].intProf] + '.', True);
        end
        else
          GetKeyInput('You need at least level ' +
            IntToStr(thing[inventory[n].intType].intCharLvl) +
            ' to use this item.', True);
      end
      else
      begin
        if thing[inventory[n].intType].intSex = 1 then
          GetKeyInput('Only men are able to equip this item.', True)
        else
          GetKeyInput('Only women may equip this item.', True);
      end;
    end;
  end;

end;

// drop as sacrifice
procedure DropAltar(n: integer);
var
  corpsetype: string;
begin

  if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem > 0 then
  begin
    ShowTransMessage('You can' + chr(39) +
      't sacrifice, because the altar is not empty.', False);
  end
  else
  begin
    ShowTransMessage('You' + chr(39) + 've sacrificed the item to ' +
      ThePlayer.strReli + '.', False);

    Inc(ThePlayer.longPrayers, Thing[inventory[n].intType].intPrice div 4);

    // corpses
    if Thing[inventory[n].intType].chLetter=chr(37) then
    begin

      corpsetype:=trim(LeftStr(Thing[inventory[n].intType].strName, length(Thing[inventory[n].intType].strName)-6));
      // writeln ('corpse identified as ' + corpsetype + '.');

      if corpsetype='Eris' then
      begin

        ShowDialog(uppercase(ThePlayer.strReli),
          ThePlayer.strName + '. It is done. The holy mission We lay down deep in your mortal',
          'heart is accomplished. The evil itself--it is dead. It fills Our heart',
          'with infinite joy to accept your sacrifice. Oh, ' + ThePlayer.strName + ', although',
          'you are just a weak human, your devotion to your cause speaks of true divine',
          'inspiration. Accept Our gifts and go in peace.', True);

        ThePlayer.blBlessed:=true;
        ThePlayer.blCursed:=false;
        ThePlayer.intHP := ThePlayer.intMaxHP;
        ThePlayer.intPP := ThePlayer.intMaxPP;
        ThePlayer.intLimit := 100;
        ThePlayer.intStrength := 200;

        DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ReturnItemByName('Ring of Divinity');

      end;

    end;


    // if item "Ring of the Divine Favorite", be angry and curse
    if Thing[inventory[n].intType].strName = 'Ring of Divinity' then
    begin

      ShowDialog(uppercase(ThePlayer.strReli),
        'You dare to reject Our gift?? Unthankful mortal!! Be cursed!',
        '',
        '',
        '',
        '', True);

      ThePlayer.blBlessed:=false;
      ThePlayer.blCursed:=true;
      ThePlayer.intHumility := 0;
      ThePlayer.longPrayers := 1;
      ThePlayer.intLimit:= 0;
      ThePlayer.intStrength := 0;
      ThePlayer.intHP := 1;
      ThePlayer.intPP := 1;
    end;


    // if item "Scroll of Hope", drop "Pandora's Ring"
    if Thing[inventory[n].intType].strName = 'Scroll of Hope' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Pandora' + chr(39) + 's Ring');

    // if item "Fuel Cube", drop "Fuel Cube"
    if Thing[inventory[n].intType].strName = 'Fuel Cube' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Fuel Cube');

    // if item "Meteor", drop "Meteor"
    if Thing[inventory[n].intType].strName = 'Meteor' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Meteor');

    // if item "Rune of Muin" (DLV 12), heal HP and PP
    if Thing[inventory[n].intType].strName = 'Rune of Muin' then
    begin
      ThePlayer.intHP := ThePlayer.intMaxHP;
      ThePlayer.intPP := ThePlayer.intMaxPP;
      GetKeyInput('Suddenly, you are fully healed.', True);
    end;

    // if item "Rune of hUath" (DLV 3), drop "Cola"
    if Thing[inventory[n].intType].strName = 'Rune of hUath' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Cola');

    // if item "Rune of Beithe" (DLV 1), drop "Water"
    if Thing[inventory[n].intType].strName = 'Rune of Beithe' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Water');

    // if item "Rune of Ailm" (DLV 17), get a skill point
    if Thing[inventory[n].intType].strName = 'Rune of Ailm' then
    begin
      Inc(ThePlayer.longSkillPoints);
      ShowTransMessage('You feel wiser.', False);
    end;

    // if item "Insurance Card", get Rune of Muin
    if Thing[inventory[n].intType].strName = 'Insurance Card' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Rune of Muin');


    // if "Pandora's Ring", drop "100 Credits"
    if Thing[inventory[n].intType].strName = 'Pandora' + chr(39) + 's Ring' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('100 Credits');


    // if "Crystal of Revenge", create portal through time
    if DungeonLevel = 1 then
      // accept Crystal only if quest 5/4 is already solved (i.e. player already
      // showed the crystal to Prof. Zimmerman)
      if Thing[inventory[n].intType].strName = 'Crystal of "Revenge"' then
        if (ThePlayer.intQuestState[5,4]=2) or (ThePlayer.intQuestState[5,4]=3) then
        begin
          if ThePlayer.longLevelVisits[21] = 0 then
          begin
            PlaySFX('page-turn.mp3');
            ShowText('interlude-d');
            ShowPlot(25);
            DngLvl[23,55].intFloorType := 59;
            ThePlayer.blNold:=true;
          end
          else
          begin
            DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ReturnItemByName('Crystal of "Revenge"');
          end;
        end
        else
        begin
          DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ReturnItemByName('Crystal of "Revenge"');
          ShowTransMessage('The crystal is rejected. Perhaps you should talk to Prof. Zimmermann?', false);
        end;

    // if "Crystal of Inferno", drop "Fire Blade of Thagor"
    if Thing[inventory[n].intType].strName = 'Crystal of "Inferno"' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Fire Blade of Thagor');

    // if "Beer", drop "Book of Joy"
    if Thing[inventory[n].intType].strName = 'Beer' then
      DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
        ReturnItemByName('Book of Joy');

    Dec(inventory[n].longNumber, Thing[inventory[n].intType].intAmount);
    if inventory[n].longNumber < 1 then
    begin
      inventory[n].intType    := 0;
      inventory[n].longNumber := 0;
    end;
  end;
end;

// drop into enchanted well
procedure DropWell(n: integer);
begin
  ShowTransMessage(
    'You' + chr(39) + 've dropped the item into the well.', False);

  // if Unique Item "Tears of War" dropped, drop "Book of Tears"
  if Thing[inventory[n].intType].strName = 'Tears of War' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Book of Tears');

  // if "Ring of Wisdom" dropped, drop "Pandora's Ale"
  if Thing[inventory[n].intType].strName = 'Ring of Wisdom' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Pandora' + chr(39) + 's Ale');

  // if "Rosegarden's seductive perfume" dropped, drop "Leviathan's blood"
  if Thing[inventory[n].intType].strName = 'Rosegarden' + chr(39) +
  's seductive perfume' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Leviathan' + chr(39) + 's Blood');

  // if "Water" dropped, drop "Antidot"
  if Thing[inventory[n].intType].strName = 'Water' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Antidot');

  // if "Antidot" dropped, drop "Cola"
  if Thing[inventory[n].intType].strName = 'Antidot' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Cola');

  // if "Identificator" dropped, increase invisible counter by 5
  if Thing[inventory[n].intType].strName = 'Identificator' then
    Inc(ThePlayer.intInvis, 5);

  // if "Cola" dropped, drop "Amphetamine"
  if Thing[inventory[n].intType].strName = 'Cola' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Amphetamine');

  // if "Amphetamine" dropped, drop "Phial of Agility"
  if Thing[inventory[n].intType].strName = 'Amphetamine' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Phial of Agility');

  // if "Dragon Poison" dropped, drop "Penicillin"
  if Thing[inventory[n].intType].strName = 'Dragon Poison' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Penicillin');

  // if "Dust" dropped, drop "Coffee"
  if Thing[inventory[n].intType].strName = 'Dust' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Coffee');

  // if "Coffee" dropped, drop "Vitari"
  if Thing[inventory[n].intType].strName = 'Coffee' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Vitari');

  // if "Vitari" dropped, drop "Dust"
  if Thing[inventory[n].intType].strName = 'Vitari' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Dust');

  // if "Phial of Agility" dropped, drop "Water"
  if Thing[inventory[n].intType].strName = 'Phial of Agility' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Water');

  // if "Drink of Profanation" dropped, drop "Junoblood"
  if Thing[inventory[n].intType].strName = 'Drink of Profanation' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Junoblood');

  // if item "Fuel Cube", drop "Fuel Cube"
  if Thing[inventory[n].intType].strName = 'Fuel Cube' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Fuel Cube');

  // if item "Meteor", drop "Meteor"
  if Thing[inventory[n].intType].strName = 'Meteor' then
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
      ReturnItemByName('Meteor');

  Dec(inventory[n].longNumber, Thing[inventory[n].intType].intAmount);
  if inventory[n].longNumber < 1 then
  begin
    inventory[n].intType    := 0;
    inventory[n].longNumber := 0;
  end;
end;


// drop item on empty floor
procedure DropFloor(n: integer);
begin

  if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem = 0 then // drop
  begin
    // drop packed items...
    if Thing[inventory[n].intType].intAmount > 1 then
      // ...only if they are a complete package
      if inventory[n].longNumber >= Thing[inventory[n].intType].intAmount then
      begin
        DngLvl[ThePlayer.intX, ThePlayer.intY].intItem :=
          inventory[n].intType;
        Dec(inventory[n].longNumber,
          Thing[inventory[n].intType].intAmount);

        if inventory[n].longNumber < 1 then
        begin
          inventory[n].intType    := 0;
          inventory[n].longNumber := 0;
        end;
      end
      else
        GetKeyInput('Of this item, you can only drop a complete set.', True)
    else
    begin

      // Northdoom dropped on lava?
      if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 20 then
      begin
        if Thing[inventory[n].intType].strName = 'Northdoom' then
        begin
          TrembleScreen;
          ClearScreenSDL;
          if ThePlayer.blEvil=false then
            ShowPlot(19);
          Inc(ThePlayer.longExp, 1250);
          Inc(ThePlayer.longScore, 500);

          if ThePlayer.blEvil=true then
          begin
            ThePlayer.intHumility := 0;
            ThePlayer.blEvil:=false;
          end;
        end;
      end
      // Northdoom dropped on normal tile
      else
        DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := inventory[n].intType;


      // barricade
      if thing[inventory[n].intType].blBarricade = True then
      begin
        DngLvl[ThePlayer.intX, ThePlayer.intY].intIntegrity := 100;
        DngLvl[ThePlayer.intX, ThePlayer.intY].intItem      := 0;
        DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 6;
      end;
      // monster trap
      if thing[inventory[n].intType].blTrap = True then
      begin
        DngLvl[ThePlayer.intX, ThePlayer.intY].intIntegrity := 0;
        DngLvl[ThePlayer.intX, ThePlayer.intY].intItem      := 0;
        DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType := 16;
      end;

      Dec(inventory[n].longNumber,
        Thing[inventory[n].intType].intAmount);

      if inventory[n].longNumber < 1 then
      begin
        inventory[n].intType    := 0;
        inventory[n].longNumber := 0;
      end;
    end;
  end;
end;

// drop and combine items
procedure DropCombine(n: integer);
var
  combrand: integer;
  strCombItemA, strCombItemB, strCombItemC: string;
begin
  strCombItemA := lowercase(thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].strName);
  strCombItemB := lowercase(thing[inventory[n].intType].strName);
  strCombItemC := '-';


  // Waffen und Runen
  if (thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].blWield=true) or (thing[inventory[n].intType].blWield=true) then
  begin

    // Testen, ob es sich schon um ein kombiniertes Item handelt
    if (LeftStr(strCombItemA, 6)='beithe') or (LeftStr(strCombItemB, 6)='beithe')
      or (LeftStr(strCombItemA, 4)='muin') or (LeftStr(strCombItemB, 4)='muin')
      or (LeftStr(strCombItemA, 4)='ailm') or (LeftStr(strCombItemB, 4)='ailm')
      or (LeftStr(strCombItemA, 5)='huath') or (LeftStr(strCombItemB, 5)='huath')
      or (LeftStr(strCombItemA, 7)='unknown') or (LeftStr(strCombItemB, 7)='unknown')
      or (thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].intRuneSet>0) or (thing[inventory[n].intType].intRuneSet>0) then
    begin
      // kann nicht weiter kombiniert werden
    end
    else
    begin

      // Beithe
      if strCombItemA = 'rune of beithe' then
        strCombItemC := 'Beithe' + chr(39) +'s ' + thing[inventory[n].intType].strName;

      if strCombItemB = 'rune of beithe' then
        strCombItemC := 'Beithe' + chr(39) +'s ' + thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].strName;

      // Muin
      if strCombItemA = 'rune of muin' then
        strCombItemC := 'Muin' + chr(39) +'s ' + thing[inventory[n].intType].strName;

      if strCombItemB = 'rune of muin' then
        strCombItemC := 'Muin' + chr(39) +'s ' + thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].strName;

      // Ailm
      if strCombItemA = 'rune of ailm' then
        strCombItemC := 'Ailm' + chr(39) +'s ' + thing[inventory[n].intType].strName;

      if strCombItemB = 'rune of ailm' then
        strCombItemC := 'Ailm' + chr(39) +'s ' + thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].strName;

      // hUath
      if strCombItemA = 'rune of huath' then
        strCombItemC := 'hUath' + chr(39) +'s ' + thing[inventory[n].intType].strName;

      if strCombItemB = 'rune of huath' then
        strCombItemC := 'hUath' + chr(39) +'s ' + thing[DngLvl[ThePlayer.intX, ThePlayer.intY].intItem].strName;

    end;

  end;



  // bread + meat = sandwich
  if ((strCombItemA = 'meat') and (strCombItemB = 'bread')) or
    ((strCombItemA = 'bread') and (strCombItemB = 'meat')) then
    strCombItemC := 'Sandwich';
    
  // bread + fish = bread roll with fish
  if ((strCombItemA = 'fish') and (strCombItemB = 'bread')) or
    ((strCombItemA = 'bread') and (strCombItemB = 'fish')) then
    strCombItemC := 'Bread Roll with Fish';

  // coffee + cake = coffee set
  if ((strCombItemA = 'coffee') and (strCombItemB = 'cake')) or
    ((strCombItemA = 'cake') and (strCombItemB = 'coffee')) then
    strCombItemC := 'Coffee Set';

  // coffee + tiva's cheese cake = fine coffee set
  if ((strCombItemA = 'coffee') and (strCombItemB = 'tiva' + chr(39) +
    's cheese cake')) or ((strCombItemA = 'tiva' + chr(39) + 's cheese cake') and
    (strCombItemB = 'coffee')) then
    strCombItemC := 'Fine Coffee Set';

  // water + cola = stale cola
  if ((strCombItemA = 'water') and (strCombItemB = 'cola')) or
    ((strCombItemA = 'cola') and (strCombItemB = 'water')) then
    strCombItemC := 'Stale Cola';

  // water + beer = stale beer
  if ((strCombItemA = 'water') and (strCombItemB = 'beer')) or
    ((strCombItemA = 'beer') and (strCombItemB = 'water')) then
    strCombItemC := 'Stale Beer';

  // small mushroom + stale beer = weak poison
  if ((strCombItemA = 'small mushroom') and (strCombItemB = 'stale beer')) or
    ((strCombItemA = 'stale beer') and (strCombItemB = 'small mushroom')) then
    strCombItemC := 'Weak Poison';

  // small mushroom + stale beer = weak poison
  if ((strCombItemA = 'big mushroom') and (strCombItemB = 'stale beer')) or
    ((strCombItemA = 'stale beer') and (strCombItemB = 'big mushroom')) then
    strCombItemC := 'Poison';

  // poison + junoblood = dragon poison
  if ((strCombItemA = 'poison') and (strCombItemB = 'junoblood')) or
    ((strCombItemA = 'junoblood') and (strCombItemB = 'poison')) then
    strCombItemC := 'Dragon Poison';

  // weak poison + junoblood = poison
  if ((strCombItemA = 'weak poison') and (strCombItemB = 'junoblood')) or
    ((strCombItemA = 'junoblood') and (strCombItemB = 'weak poison')) then
    strCombItemC := 'Poison';

  // amphetamine + dust = vitari
  if ((strCombItemA = 'amphetamine') and (strCombItemB = 'dust')) or
    ((strCombItemA = 'dust') and (strCombItemB = 'amphetamine')) then
    strCombItemC := 'Vitari';

  // cola + vitari = VitaMix
  if ((strCombItemA = 'cola') and (strCombItemB = 'vitari')) or
    ((strCombItemA = 'vitari') and (strCombItemB = 'cola')) then
    strCombItemC := 'VitaMix';

  // amphetamine + vitari = Vitarin
  if ((strCombItemA = 'amphetamine') and (strCombItemB = 'vitari')) or
    ((strCombItemA = 'vitari') and (strCombItemB = 'amphetamine')) then
    strCombItemC := 'Vitarin';

  // water + vitari = dust or amphetamine
  if ((strCombItemA = 'water') and (strCombItemB = 'vitari')) or
    ((strCombItemA = 'vitari') and (strCombItemB = 'water')) then
    if 1 + trunc(random(2)) = 1 then
      strCombItemC := 'Dust'
    else
      strCombItemC := 'Amphetamine';

  // water + VitaMix = C# or Cola
  if ((strCombItemA = 'water') and (strCombItemB = 'vitamix')) or
    ((strCombItemA = 'vitamix') and (strCombItemB = 'water')) then
    if 1 + trunc(random(2)) = 1 then
      strCombItemC := 'Cola'
    else
      strCombItemC := 'C#';

  // water + vitarin = dust or amphetamine
  if ((strCombItemA = 'water') and (strCombItemB = 'vitarin')) or
    ((strCombItemA = 'vitarin') and (strCombItemB = 'water')) then
    if 1 + trunc(random(2)) = 1 then
      strCombItemC := 'Dust'
    else
      strCombItemC := 'Amphetamine';

  // aspirin + cola = copyrin
  if ((strCombItemA = 'aspirin') and (strCombItemB = 'cola')) or
    ((strCombItemA = 'cola') and (strCombItemB = 'aspirin')) then
    strCombItemC := 'Copyrin';

  // vitari + copyrin = cavetin
  if ((strCombItemA = 'vitari') and (strCombItemB = 'copyrin')) or
    ((strCombItemA = 'copyrin') and (strCombItemB = 'vitari')) then
    strCombItemC := 'Cavetin';

  // vitari + strong copyrin = cavetin
  if ((strCombItemA = 'vitari') and (strCombItemB = 'strong copyrin')) or
    ((strCombItemA = 'strong copyrin') and (strCombItemB = 'vitari')) then
    strCombItemC := 'Copyrin Overdose';

  // hard vitari + copyrin = cavetin overdose
  if ((strCombItemA = 'hard vitari') and (strCombItemB = 'copyrin')) or
    ((strCombItemA = 'copyrin') and (strCombItemB = 'hard vitari')) then
    strCombItemC := 'Cavetin Overdose';

  // hard vitari + strong copyrin = copyrin overdose
  if ((strCombItemA = 'hard vitari') and (strCombItemB = 'strong copyrin')) or
    ((strCombItemA = 'strong copyrin') and (strCombItemB = 'hard vitari')) then
    strCombItemC := 'Copyrin Overdose';

  // vitari + cavetin = cavetin overdose

  if ((strCombItemA = 'vitari') and (strCombItemB = 'cavetin')) or
    ((strCombItemA = 'cavetin') and (strCombItemB = 'vitari')) then
    strCombItemC := 'Cavetin Overdose';

  // vitarin + cavetin = cavetin overdose
  if ((strCombItemA = 'vitarin') and (strCombItemB = 'cavetin')) or
    ((strCombItemA = 'cavetin') and (strCombItemB = 'vitarin')) then
    strCombItemC := 'Cavetin Overdose';

  // vitamix + cavetin = cavetin overdose
  if ((strCombItemA = 'vitamix') and (strCombItemB = 'cavetin')) or
    ((strCombItemA = 'cavetin') and (strCombItemB = 'vitamix')) then
    strCombItemC := 'Cavetin Overdose';

  // aspirin + caffeine = strong copyrin
  if ((strCombItemA = 'aspirin') and (strCombItemB = 'caffeine')) or
    ((strCombItemA = 'caffeine') and (strCombItemB = 'aspirin')) then
    strCombItemC := 'Strong Copyrin';

  // penicillin + caffeine = copyrin overdose
  if ((strCombItemA = 'penicillin') and (strCombItemB = 'caffeine')) or
    ((strCombItemA = 'caffeine') and (strCombItemB = 'penicillin')) then
    strCombItemC := 'Copyrin Overdose';

  // inconspicious blade + ... -->  ... sword
  if (strCombItemA = 'inconspicious blade') or (strCombItemB =
    'inconspicious blade') then
  begin
    // all other crystals lead either to an enchanted or mythic sword

    if (strCombItemA = 'crystal of "poison"') or (strCombItemB =
      'crystal of "poison"') then
      strCombItemC := 'Resounding Success';

    if (Pos('crystal', strCombItemA) > 0) or (Pos('crystal', strCombItemB) > 0) then
      if strCombItemC = '-' then
      begin
        combrand := 1 + random(4);
        case combrand of
          1, 2, 3: strCombItemC := 'Enchanted Sword';
          4: strCombItemC := 'Mythic Sword';
        end;
      end;
  end;

  // meaningless lance + ... -->  electriclance
  if (strCombItemA = 'meaningless lance') or (strCombItemB =
    'meaningless lance') then
  begin

    if (strCombItemA = 'crystal of "flash"') or (strCombItemB =
      'crystal of "flash"') then
      strCombItemC := 'Electriclance';

    if (strCombItemA = 'crystal of "poison"') or (strCombItemB =
      'crystal of "poison"') then
      strCombItemC := 'Long Viper';

  end;

  // Northdoom + Crystal of Purify -->  ... Purified Northdoom
  if (strCombItemA = 'northdoom') or (strCombItemB = 'northdoom') then
  begin

    if (strCombItemA = 'crystal of "purify"') or (strCombItemB =
      'crystal of "purify"') then
      strCombItemC := 'Purified Northdoom';

    // all other crystals lead either to an enchanted or mythic sword
    if (Pos('crystal', strCombItemA) > 0) or (Pos('crystal', strCombItemB) > 0) then
      if strCombItemC = '-' then
      begin
        combrand := 1 + random(4);
        case combrand of
          1, 2, 3: strCombItemC := 'Enchanted Broadsword';
          4: strCombItemC := 'Mythic Broadsword';
        end;
      end;
  end;

  // Purified Northdoom + Crystal of Poison -->  ... Poisonous Northdoom
  if (strCombItemA = 'purified northdoom') or (strCombItemB = 'purified northdoom') then
  begin

    if (strCombItemA = 'crystal of "poison"') or (strCombItemB =
      'crystal of "poison"') then
      strCombItemC := 'Poisonous Northdoom';

  end;

  // unimpressive axe + ... -->  ... axe
  if (strCombItemA = 'unimpressive axe') or (strCombItemB = 'unimpressive axe') then
  begin

    if (strCombItemA = 'crystal of "poison"') or (strCombItemB =
      'crystal of "poison"') then
      strCombItemC := 'Unhealthy Axe';

    // all other crystals lead either to an enchanted or mythic sword
    if (Pos('crystal', strCombItemA) > 0) or (Pos('crystal', strCombItemB) > 0) then
      if strCombItemC = '-' then
      begin
        combrand := 1 + random(4);
        case combrand of
          1, 2, 3: strCombItemC := 'Magic Axe';
          4: strCombItemC := 'Epic Axe';
        end;
      end;
  end;

  // unremarkable ring + ...
  if (strCombItemA = 'unremarkable ring') or (strCombItemB = 'unremarkable ring') then
  begin

    if (strCombItemA = 'crystal of "justify"') or
      (strCombItemB = 'crystal of "justify"') then
      strCombItemC := 'Psychic Ring';

    if (strCombItemA = 'crystal of "force"') or (strCombItemB =
      'crystal of "force"') then
      strCombItemC := 'Ring of Vigor';

    if (strCombItemA = 'crystal of "redeem"') or (strCombItemB =
      'crystal of "redeem"') then
      strCombItemC := 'Holy Ring';

    if (strCombItemA = 'crystal of "viper"') or (strCombItemB =
      'crystal of "viper"') then
      strCombItemC := 'Jade Ring';

    if (strCombItemA = 'crystal of "break"') or (strCombItemB =
      'crystal of "break"') then
      strCombItemC := 'Ring of Agility';

    if (strCombItemA = 'crystal of "fastflame"') or
      (strCombItemB = 'crystal of "fastflame"') then
      strCombItemC := 'Silver Ring';

    if (strCombItemA = 'crystal of "blitzeis"') or
      (strCombItemB = 'crystal of "blitzeis"') then
      strCombItemC := 'Teflon Ring';

    if (strCombItemA = 'crystal of "shield"') or (strCombItemB =
      'crystal of "shield"') then
      strCombItemC := 'Protective Ring';

    // all other crystals lead either to a sparkling blue, yellow or purple ring
    if (Pos('crystal', strCombItemA) > 0) or (Pos('crystal', strCombItemB) > 0) then
      if strCombItemC = '-' then
      begin
        combrand := 1 + random(3);
        case combrand of
          1: strCombItemC := 'Sparkling Blue Ring';
          2: strCombItemC := 'Sparkling Yellow Ring';
          3: strCombItemC := 'Sparkling Purple Ring';
        end;
      end;
  end;

  if strCombItemC <> '-' then
  begin
    GetKeyInput('You combine both items to ' + strCombItemC + '.', True);
    Dec(inventory[n].longNumber);
    if inventory[n].longNumber < 1 then
    begin
      inventory[n].intType    := 0;
      inventory[n].longNumber := 0;
    end;
    DngLvl[ThePlayer.intX, ThePlayer.intY].intItem := ReturnItemByName(strCombItemC);
    Thing[ReturnItemByName(strCombItemC)].blIdentified := True;
    Thing[ReturnItemByName(strCombItemC)].strName := Thing[ReturnItemByName(strCombItemC)].strRealName;
  end
  else
    GetKeyInput('There is no space on the floor.', True);

end;

// drop an item
procedure DropItem;
var
  n: integer;
begin
  n := -1;

  if (UseSDL = False) or (UseMouseToMove = False) then
    repeat
      n := 0;
      Val(GetTextInput(
        'Enter the number of the item you want to drop [ENTER to cancel]:', 2), n);
    until (n = 0) or ((n > 0) and (n < 17) and (Inventory[n].intType > 0));

  if n > 0 then
  begin

    // sacrifice item to god
    if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 15 then
      DropAltar(n);

    // drop item into well
    if DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType = 28 then
      DropWell(n);


    // simply drop or combine
    if (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType <> 15) and
      (DngLvl[ThePlayer.intX, ThePlayer.intY].intFloorType <> 28) then
      if DngLvl[ThePlayer.intX, ThePlayer.intY].intItem = 0 then
        DropFloor(n) // simple drop
      else
        DropCombine(n);  // combine items
  end;

end;


// unequip an item
procedure RemoveItem;
var
  s, n:      integer;
  blRingOff: boolean;
  ch, prompt: string;
begin

  n := -1;

  // create context-sensitive prompt
  prompt := 'Remove ';
  if ThePlayer.intWeapon > 0 then
    prompt := prompt + '[w]eapon ';

  if ThePlayer.intArmour > 0 then
    prompt := prompt + '[a]rmour ';

  if ThePlayer.intHat > 0 then
    prompt := prompt + '[h]at ';

  if ThePlayer.intFeet > 0 then
    prompt := prompt + '[s]hoes ';

  if ThePlayer.intRingLeft > 0 then
    prompt := prompt + '[l]eft ring ';

  if ThePlayer.intRingRight > 0 then
    prompt := prompt + '[r]ight ring ';

  if ThePlayer.intExtra > 0 then
    prompt := prompt + '[e]xtra ';

  if prompt <> 'Remove ' then
    prompt := prompt + '?'
  else
    GetKeyInput('You haven''t equipped anything.', True);

  // if something is equipped, ask for item to remove
  if prompt <> 'Remove ' then
  begin
    ch := '-';
    repeat
      BottomBar;
      ch := GetKeyInput(prompt, False);
    until (ch = 'w') or (ch = 'a') or (ch = 'h') or (ch = 's') or
      (ch = 'l') or (ch = 'r') or (ch = 'e') or (ch = 'ESC');

    // remove weapon
    if ch = 'w' then
      if ThePlayer.intWeapon > 0 then
      begin
        s := ReturnSameItemInventorySlot(ThePlayer.intWeapon);
        if s = -1 then
          s := ReturnFreeInventorySlot;
        if s = -1 then
        begin
          BottomBar;
          GetKeyInput('You can''t remove the ' + thing[ThePlayer.intWeapon].strName +
            ' -- you have no space to store it.', True);
        end
        else
        begin
          inventory[s].intType := ThePlayer.intWeapon;
          ShowTransMessage('You remove the ' + thing[ThePlayer.intWeapon].strName +
            ' and store it in your inventory.', False);
          ThePlayer.intWeaponMod:=0;
          ThePlayer.intWeaponModRange:=0;
          Inc(inventory[s].longNumber);
          ThePlayer.intWeapon := 0;
        end;
      end;

    // remove armour
    if ch = 'a' then
      if ThePlayer.intArmour > 0 then
      begin
        s := ReturnSameItemInventorySlot(ThePlayer.intArmour);
        if s = -1 then
          s := ReturnFreeInventorySlot;
        if s = -1 then
        begin
          BottomBar;
          GetKeyInput('You can''t remove the ' + thing[ThePlayer.intArmour].strName +
            ' -- you have no space to store it.', True);
        end
        else
        begin
          inventory[s].intType := ThePlayer.intArmour;
          ShowTransMessage('You remove the ' + thing[ThePlayer.intArmour].strName +
            ' and store it in your inventory.', False);
          Inc(inventory[s].longNumber);
          ThePlayer.intArmour := 0;
        end;
      end;

    // remove hat
    if ch = 'h' then
      if ThePlayer.intHat > 0 then
      begin
        s := ReturnSameItemInventorySlot(ThePlayer.intHat);
        if s = -1 then
          s := ReturnFreeInventorySlot;
        if s = -1 then
        begin
          BottomBar;
          GetKeyInput('You can''t remove the ' + thing[ThePlayer.intHat].strName +
            ' -- you have no space to store it.', True);
        end
        else
        begin
          inventory[s].intType := ThePlayer.intHat;
          ShowTransMessage('You remove the ' + thing[ThePlayer.intHat].strName +
            ' and store it in your inventory.', False);
          Inc(inventory[s].longNumber);
          ThePlayer.intHat := 0;
        end;
      end;

    // remove shoes
    if ch = 's' then
      if ThePlayer.intFeet > 0 then
      begin
        s := ReturnSameItemInventorySlot(ThePlayer.intFeet);
        if s = -1 then
          s := ReturnFreeInventorySlot;
        if s = -1 then
        begin
          BottomBar;
          GetKeyInput('You can''t remove the ' + thing[ThePlayer.intFeet].strName +
            ' -- you have no space to store it.', True);
        end
        else
        begin
          inventory[s].intType := ThePlayer.intFeet;
          ShowTransMessage('You remove the ' + thing[ThePlayer.intFeet].strName +
            ' and store it in your inventory.', False);
          Inc(inventory[s].longNumber);
          ThePlayer.intFeet := 0;
        end;
      end;

    // remove left ring
    if ch = 'l' then
      if ThePlayer.intRingLeft > 0 then
      begin
        s := ReturnSameItemInventorySlot(ThePlayer.intRingLeft);
        if s = -1 then
          s := ReturnFreeInventorySlot;
        if s = -1 then
        begin
          BottomBar;
          GetKeyInput('You can''t remove the ' + thing[ThePlayer.intRingLeft].strName +
            ' -- you have no space to store it.', True);
        end
        else
        begin
          inventory[s].intType := ThePlayer.intRingLeft;
          ShowTransMessage('You remove the ' + thing[ThePlayer.intRingLeft].strName +
            ' and store it in your inventory.', False);
          Inc(inventory[s].longNumber);
          ThePlayer.intRingLeft := 0;
        end;
      end;

    // remove right ring
    if ch = 'r' then
      if ThePlayer.intRingRight > 0 then
      begin
        s := ReturnSameItemInventorySlot(ThePlayer.intRingRight);
        if s = -1 then
          s := ReturnFreeInventorySlot;
        if s = -1 then
        begin
          BottomBar;
          GetKeyInput('You can''t remove the ' + thing[ThePlayer.intRingRight].strName +
            ' -- you have no space to store it.', True);
        end
        else
        begin
          inventory[s].intType := ThePlayer.intRingRight;
          ShowTransMessage('You remove the ' + thing[ThePlayer.intRingRight].strName +
            ' and store it in your inventory.', False);
          Inc(inventory[s].longNumber);
          ThePlayer.intRingRight := 0;
        end;
      end;

    // remove extras
    if ch = 'e' then
      if ThePlayer.intExtra > 0 then
      begin
        s := ReturnSameItemInventorySlot(ThePlayer.intExtra);
        if s = -1 then
          s := ReturnFreeInventorySlot;
        if s = -1 then
        begin
          BottomBar;
          GetKeyInput('You can''t remove the ' + thing[ThePlayer.intExtra].strName +
            ' -- you have no space to store it.', True);
        end
        else
        begin
          inventory[s].intType := ThePlayer.intExtra;
          ShowTransMessage('You remove the ' + thing[ThePlayer.intExtra].strName +
            ' and store it in your inventory.', False);
          Inc(inventory[s].longNumber);
          ThePlayer.intExtra := 0;
        end;

      end;

  end;
end;

// eat or drink an item
procedure ConsumeItem;
var
  n: integer;
begin
  n := -1;
  if (UseSDL = False) or (UseMouseToMove = False) then
    repeat
      Val(GetTextInput('Which item do you want to consume?', 2), n);
    until (n = 0) or ((n > 0) and (n < 17) and (Inventory[n].intType > 0));

  if n > 0 then
    if (thing[inventory[n].intType].blEat = True) or
      (thing[inventory[n].intType].blDrink = True) then
    begin
      if (ThePlayer.intWeapon = inventory[n].intType) or
        (ThePlayer.intArmour = inventory[n].intType) or
        (ThePlayer.intHat = inventory[n].intType) or
        (ThePlayer.intFeet = inventory[n].intType) or
        (ThePlayer.intExtra = inventory[n].intType) then
        GetKeyInput('You must remove the ' +
          thing[inventory[n].intType].strName + ' before eating it.', True)
      else
      begin
        // identify item
        Thing[inventory[n].intType].blIdentified := True;
        Thing[inventory[n].intType].strName      :=
          Thing[inventory[n].intType].strRealName;

        if thing[inventory[n].intType].blEat = True then
          ShowTransMessage('You eat the ' +
            thing[inventory[n].intType].strName + '.', False)
        else
          ShowTransMessage('You drink the ' +
            thing[inventory[n].intType].strName + '.', False);

        // set "Ido's Finest"
        if CheckForItemSet(8)=true then
          DoEffect(thing[inventory[n].intType].intEffect, thing[inventory[n].intType].intRange*2, thing[inventory[n].intType].strEfText)
        else
          DoEffect(thing[inventory[n].intType].intEffect, thing[inventory[n].intType].intRange, thing[inventory[n].intType].strEfText);


		// after eating a banana, keep the banana peel
		if thing[inventory[n].intType].strName = 'Banana' then
		  if DngLvl[ThePlayer.intX,ThePlayer.intY].intItem=0 then
		    DngLvl[ThePlayer.intX,ThePlayer.intY].intItem := ReturnItemByName('Banana Peel');


        Dec(inventory[n].longNumber);
        if inventory[n].longNumber = 0 then
          inventory[n].intType := 0;

      end;
    end
    else
      GetKeyInput('You cannot eat or drink this.', True);

end;


// sell item to trader
procedure SellItem;
var
  n: integer;
begin
  n := -1;

  if (UseSDL = False) or (UseMouseToMove = False) then
    repeat
      Val(GetTextInput('Enter the number of the item to sell [ENTER to cancel]:',
        2), n);
    until (n = 0) or ((n > 0) and (n < 17) and (Inventory[n].intType > 0));

  if n > 0 then
  begin

    if (DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding > 0) then
    begin
      if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding <> 8 then
      begin
        // sell

        Inc(ThePlayer.longGold, CollectSellPrice(Inventory[n].intType));
        Dec(inventory[n].longNumber, Thing[inventory[n].intType].intAmount);

        ShowTransMessage('You' + chr(39) + 've sold the ' +
          Thing[inventory[n].intType].strName + ' for ' + IntToStr(
          CollectSellPrice(Inventory[n].intType)) + ' Credits.', False);

        if inventory[n].longNumber < 1 then
        begin
          inventory[n].intType    := 0;
          inventory[n].longNumber := 0;
        end;
      end
      else
      begin
        // disassemble

        Dec(inventory[n].longNumber, Thing[inventory[n].intType].intAmount);

        DisassembleItem(inventory[n].intType);

        ShowTransMessage('You' + chr(39) + 've disassembled the ' +
          Thing[inventory[n].intType].strName + ' in the factory.', False);

        if inventory[n].longNumber < 1 then
        begin
          inventory[n].intType    := 0;
          inventory[n].longNumber := 0;
        end;
      end;
    end
    else
      GetKeyInput('You need to go to a trader if you want to sell items.',
        True);
  end;

end;


// detailed information on equip and bonuses
procedure EquipmentInfo;
var
  strName, strWP, strAP, strGP, strSP, dummy: string;
  intTotalWP, intTotalAP, intTotalGP, intTotalSP, i: integer;
  chLetter: char;
begin
  if UseSDL = False then
    ClearScreenSDL;

  repeat

    if UseSDL = True then
      LoadImage_Title('graphics/decobg.jpg');

    if UseSDL = True then
      BlitImage_Title
    else
      BottomBar;

    TransTextXY(1, 1, 'EQUIPMENT SUMMARY');


    for i := 4 to 18 do
    begin
      TransTextXY(14, i, '|');
      TransTextXY(48, i, '|');
      TransTextXY(53, i, '|');
      TransTextXY(58, i, '|');
      TransTextXY(63, i, '|');
    end;

    TransTextXY(1, 7, 'Weapon');
    TransTextXY(1, 10, 'Shield/Extra');

    TransTextXY(1, 11, 'Armour');
    TransTextXY(1, 12, 'Hat');
    TransTextXY(1, 13, 'Shoes');

    TransTextXY(1, 14, 'Ring (left)');
    TransTextXY(1, 15, 'Ring (right)');

    TransTextXY(1, 18, 'Total');

    TransTextXY(16, 4, 'Name');
    TransTextXY(50, 4, 'WP');
    TransTextXY(55, 4, 'AP');
    TransTextXY(60, 4, 'GP');
    TransTextXY(65, 4, 'SP');

    if UseSDL = False then
    begin
      TransTextXY(1, 5,
        '-------------+---------------------------------+----+----+----+-------------');
      TransTextXY(1, 17,
        '-------------+---------------------------------+----+----+----+-------------');
    end
    else
    begin
      TransTextXY(1, 5,
        '----------------------------------------------------------------------------');
      TransTextXY(1, 17,
        '----------------------------------------------------------------------------');
    end;


    intTotalWP := 0;
    intTotalAP := 0;
    intTotalGP := 0;
    intTotalSP := 0;

    // Weapon
    if ThePlayer.intWeapon > 0 then
    begin
      chLetter := Thing[ThePlayer.intWeapon].chLetter;
      strName := Thing[ThePlayer.intWeapon].strName;
      strWP   := IntToStr(Thing[ThePlayer.intWeapon].intWP);
      strAP   := IntToStr(Thing[ThePlayer.intWeapon].intAP);
      strGP   := IntToStr(Thing[ThePlayer.intWeapon].intGP);
      strSP   := IntToStr(Thing[ThePlayer.intWeapon].intSP);
      Inc(intTotalWP, Thing[ThePlayer.intWeapon].intWP);
      Inc(intTotalAP, Thing[ThePlayer.intWeapon].intAP);
      Inc(intTotalGP, Thing[ThePlayer.intWeapon].intGP);
      Inc(intTotalSP, Thing[ThePlayer.intWeapon].intSP);
      if ThePlayer.intWeaponMod>0 then
      begin
        if (ThePlayer.intWeaponMod=19) or (ThePlayer.intWeaponMod=38) or (ThePlayer.intWeaponMod=39) or (ThePlayer.intWeaponMod=40) or (ThePlayer.intWeaponMod=45) or (ThePlayer.intWeaponMod=56) then
          TransTextXY(18, 8, 'Greased; ' + GetEffectDescription(ThePlayer.intWeaponMod) + ': ' + IntToStr(ThePlayer.intWeaponModRange))
        else
          TransTextXY(18, 8, 'Greased, but without effect');
      end;
    end
    else
    begin
      chLetter := chr(32);
      strName := '-';
      strWP   := '-';
      strAP   := '-';
      strGP   := '-';
      strSP   := '-';
    end;
    if chLetter<>chr(32) then CharXY(17, 7, chLetter, 0, true);

    SetItemNameColor(strName);
    TransTextXY(18, 7, strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;

    TransTextXY(50, 7, strWP);
    TransTextXY(55, 7, strAP);
    TransTextXY(60, 7, strGP);
    TransTextXY(65, 7, strSP);


    // Shield/Extra
    if ThePlayer.intExtra > 0 then
    begin
      chLetter := Thing[ThePlayer.intExtra].chLetter;
      strName := Thing[ThePlayer.intExtra].strName;
      strWP   := IntToStr(Thing[ThePlayer.intExtra].intWP);
      strAP   := IntToStr(Thing[ThePlayer.intExtra].intAP);
      strGP   := IntToStr(Thing[ThePlayer.intExtra].intGP);
      strSP   := IntToStr(Thing[ThePlayer.intExtra].intSP);
      Inc(intTotalWP, Thing[ThePlayer.intExtra].intWP);
      Inc(intTotalAP, Thing[ThePlayer.intExtra].intAP);
      Inc(intTotalGP, Thing[ThePlayer.intExtra].intGP);
      Inc(intTotalSP, Thing[ThePlayer.intExtra].intSP);
    end
    else
    begin
      chLetter := chr(32);
      strName := '-';
      strWP   := '-';
      strAP   := '-';
      strGP   := '-';
      strSP   := '-';
    end;
    if chLetter<>chr(32) then CharXY(17, 10, chLetter, 0, true);

    SetItemNameColor(strName);
    TransTextXY(18, 10, strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;

    TransTextXY(50, 10, strWP);
    TransTextXY(55, 10, strAP);
    TransTextXY(60, 10, strGP);
    TransTextXY(65, 10, strSP);


    // Armour
    if ThePlayer.intArmour > 0 then
    begin
      chLetter := Thing[ThePlayer.intArmour].chLetter;
      strName := Thing[ThePlayer.intArmour].strName;
      strWP   := IntToStr(Thing[ThePlayer.intArmour].intWP);
      strAP   := IntToStr(Thing[ThePlayer.intArmour].intAP);
      strGP   := IntToStr(Thing[ThePlayer.intArmour].intGP);
      strSP   := IntToStr(Thing[ThePlayer.intArmour].intSP);
      Inc(intTotalWP, Thing[ThePlayer.intArmour].intWP);
      Inc(intTotalAP, Thing[ThePlayer.intArmour].intAP);
      Inc(intTotalGP, Thing[ThePlayer.intArmour].intGP);
      Inc(intTotalSP, Thing[ThePlayer.intArmour].intSP);
    end
    else
    begin
      chLetter := chr(32);
      strName := '-';
      strWP   := '-';
      strAP   := '-';
      strGP   := '-';
      strSP   := '-';
    end;
    if chLetter<>chr(32) then CharXY(17, 11, chLetter, 0, true);

    SetItemNameColor(strName);
    TransTextXY(18, 11, strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;

    TransTextXY(50, 11, strWP);
    TransTextXY(55, 11, strAP);
    TransTextXY(60, 11, strGP);
    TransTextXY(65, 11, strSP);


    // Hat
    if ThePlayer.intHat > 0 then
    begin
      chLetter := Thing[ThePlayer.intHat].chLetter;
      strName := Thing[ThePlayer.intHat].strName;
      strWP   := IntToStr(Thing[ThePlayer.intHat].intWP);
      strAP   := IntToStr(Thing[ThePlayer.intHat].intAP);
      strGP   := IntToStr(Thing[ThePlayer.intHat].intGP);
      strSP   := IntToStr(Thing[ThePlayer.intHat].intSP);
      Inc(intTotalWP, Thing[ThePlayer.intHat].intWP);
      Inc(intTotalAP, Thing[ThePlayer.intHat].intAP);
      Inc(intTotalGP, Thing[ThePlayer.intHat].intGP);
      Inc(intTotalSP, Thing[ThePlayer.intHat].intSP);
    end
    else
    begin
      chLetter := chr(32);
      strName := '-';
      strWP   := '-';
      strAP   := '-';
      strGP   := '-';
      strSP   := '-';
    end;
    if chLetter<>chr(32) then CharXY(17, 12, chLetter, 0, true);

    SetItemNameColor(strName);
    TransTextXY(18, 12, strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;

    TransTextXY(50, 12, strWP);
    TransTextXY(55, 12, strAP);
    TransTextXY(60, 12, strGP);
    TransTextXY(65, 12, strSP);


    // Shoes
    if ThePlayer.intFeet > 0 then
    begin
      chLetter := Thing[ThePlayer.intFeet].chLetter;
      strName := Thing[ThePlayer.intFeet].strName;
      strWP   := IntToStr(Thing[ThePlayer.intFeet].intWP);
      strAP   := IntToStr(Thing[ThePlayer.intFeet].intAP);
      strGP   := IntToStr(Thing[ThePlayer.intFeet].intGP);
      strSP   := IntToStr(Thing[ThePlayer.intFeet].intSP);
      Inc(intTotalWP, Thing[ThePlayer.intFeet].intWP);
      Inc(intTotalAP, Thing[ThePlayer.intFeet].intAP);
      Inc(intTotalGP, Thing[ThePlayer.intFeet].intGP);
      Inc(intTotalSP, Thing[ThePlayer.intFeet].intSP);
    end
    else
    begin
      chLetter := chr(32);
      strName := '-';
      strWP   := '-';
      strAP   := '-';
      strGP   := '-';
      strSP   := '-';
    end;
    if chLetter<>chr(32) then CharXY(17, 13, chLetter, 0, true);

    SetItemNameColor(strName);
    TransTextXY(18, 13, strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;

    TransTextXY(50, 13, strWP);
    TransTextXY(55, 13, strAP);
    TransTextXY(60, 13, strGP);
    TransTextXY(65, 13, strSP);


    // Ring (left)
    if ThePlayer.intRingLeft > 0 then
    begin
      chLetter := Thing[ThePlayer.intRingLeft].chLetter;
      strName := Thing[ThePlayer.intRingLeft].strName;
      strWP   := IntToStr(Thing[ThePlayer.intRingLeft].intWP);
      strAP   := IntToStr(Thing[ThePlayer.intRingLeft].intAP);
      strGP   := IntToStr(Thing[ThePlayer.intRingLeft].intGP);
      strSP   := IntToStr(Thing[ThePlayer.intRingLeft].intSP);
      Inc(intTotalWP, Thing[ThePlayer.intRingLeft].intWP);
      Inc(intTotalAP, Thing[ThePlayer.intRingLeft].intAP);
      Inc(intTotalGP, Thing[ThePlayer.intRingLeft].intGP);
      Inc(intTotalSP, Thing[ThePlayer.intRingLeft].intSP);
    end
    else
    begin
      chLetter := chr(32);
      strName := '-';
      strWP   := '-';
      strAP   := '-';
      strGP   := '-';
      strSP   := '-';
    end;
    if chLetter<>chr(32) then CharXY(17, 14, chLetter, 0, true);

    SetItemNameColor(strName);
    TransTextXY(18, 14, strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;

    TransTextXY(50, 14, strWP);
    TransTextXY(55, 14, strAP);
    TransTextXY(60, 14, strGP);
    TransTextXY(65, 14, strSP);


    // Ring (right)
    if ThePlayer.intRingRight > 0 then
    begin
      chLetter := Thing[ThePlayer.intRingRight].chLetter;
      strName := Thing[ThePlayer.intRingRight].strName;
      strWP   := IntToStr(Thing[ThePlayer.intRingRight].intWP);
      strAP   := IntToStr(Thing[ThePlayer.intRingRight].intAP);
      strGP   := IntToStr(Thing[ThePlayer.intRingRight].intGP);
      strSP   := IntToStr(Thing[ThePlayer.intRingRight].intSP);
      Inc(intTotalWP, Thing[ThePlayer.intRingRight].intWP);
      Inc(intTotalAP, Thing[ThePlayer.intRingRight].intAP);
      Inc(intTotalGP, Thing[ThePlayer.intRingRight].intGP);
      Inc(intTotalSP, Thing[ThePlayer.intRingRight].intSP);
    end
    else
    begin
      chLetter := chr(32);
      strName := '-';
      strWP   := '-';
      strAP   := '-';
      strGP   := '-';
      strSP   := '-';
    end;
    if chLetter<>chr(32) then CharXY(17, 15, chLetter, 0, true);

    SetItemNameColor(strName);
    TransTextXY(18, 15, strName);
    GlobalFontColor := FONTCOLOR_WHITE;
    GlobalConColor := -1;

    TransTextXY(50, 15, strWP);
    TransTextXY(55, 15, strAP);
    TransTextXY(60, 15, strGP);
    TransTextXY(65, 15, strSP);


    // totals
    TransTextXY(50, 18, IntToStr(intTotalWP));
    TransTextXY(55, 18, IntToStr(intTotalAP));
    TransTextXY(60, 18, IntToStr(intTotalGP));
    TransTextXY(65, 18, IntToStr(intTotalSP));

    dummy := GetKeyInput('[ESC] close', False);
  until (dummy = 'ESC');
end;


// examine an item
procedure ExamineItem;
var
  n: integer;
begin
  n := -1;
  if (UseSDL = False) or (UseMouseToMove = False) then
    repeat
      Val(GetTextInput('Which item do you want to examine?', 2), n);
    until (n = 0) or ((n > 0) and (n < 17) and (Inventory[n].intType > 0));

  if n > 0 then
  begin
    // check for identification
    if Thing[inventory[n].intType].blIdentified = False then
    begin
      GetKeyInput('You know nothing about this unidentified item.', True);
      n := 0;
    end
    else
      ItemInfo(inventory[n].intType);
  end;

end;


// grease item with fluid
procedure GreaseItem;
var
  n: integer;
begin

  if ThePlayer.intWeapon>0 then
  begin
    if ThePlayer.intWeaponMod=0 then
    begin
      n := -1;
      if (UseSDL = False) or (UseMouseToMove = False) then
        repeat
          Val(GetTextInput('With which potion do you want to grease your weapon?', 2), n);
        until (n = 0) or ((n > 0) and (n < 17) and (Inventory[n].intType > 0));

      if n > 0 then
      begin
        if Thing[inventory[n].intType].blDrink=true then
        begin
          ThePlayer.intWeaponMod := Thing[inventory[n].intType].intEffect;
          ThePlayer.intWeaponModRange := Thing[inventory[n].intType].intRange;
          ShowTransMessage('You grease your weapon with '+Thing[inventory[n].intType].strName+'.', false);

          if (ThePlayer.intWeaponMod=19) or (ThePlayer.intWeaponMod=38) or (ThePlayer.intWeaponMod=39) or (ThePlayer.intWeaponMod=40) or (ThePlayer.intWeaponMod=45) or (ThePlayer.intWeaponMod=56) then
            ShowTransMessage('The grease adds a temporary effect to your weapon: ' + GetEffectDescription(ThePlayer.intWeaponMod)+' ('+IntToStr(ThePlayer.intWeaponModRange)+').', false)
          else
            ShowTransMessage('The grease is useless.', false);


          // remove used item from inventory
          Dec(inventory[n].longNumber);
          if inventory[n].longNumber = 0 then
            inventory[n].intType := 0;
        end
        else
          GetKeyInput('You can only use potions to grease weapons.', true);
      end;
    end
    else
      GetKeyInput('Your weapon is already greased. Remove the weapon to clean it.', true);
  end
  else
    GetKeyInput('You don''t have equipped a weapon you could grease.', true);

end;

// study an item
procedure StudyItem;
var
  n, i: integer;
  blKnowsSpell: boolean;
begin
  n := -1;
  if (UseSDL = False) or (UseMouseToMove = False) then
    repeat
      Val(GetTextInput('Which item do you want to study?', 2), n);
      //             Writeln('Selection: '+IntToStr(n));
    until (n = 0) or ((n > 0) and (n < 17) and (Inventory[n].intType > 0));

  if n > 0 then
  begin

    // check for identification
    if Thing[inventory[n].intType].blIdentified = False then
    begin
      GetKeyInput('You can only study identified items.', True);
      n := 0;
    end
    else
    begin
      if inventory[n].longNumber = 0 then
      begin
        GetKeyInput('You did not select an item.', True);
      end
      else
      begin
        // not readable, not learnable
        if (Thing[inventory[n].intType].strTextfile = '-') and
          (Thing[inventory[n].intType].chLetter <> chr(193)) and
          (Thing[inventory[n].intType].chLetter <> chr(161)) then
          GetKeyInput('This item can' + chr(39) + 't be studied.', True);

        // paper / book
        if (Thing[inventory[n].intType].strTextfile <> '-') or
          (Thing[inventory[n].intType].chLetter = chr(193)) then
        begin
          PlaySFX('page-turn.mp3');
          ShowText(Thing[inventory[n].intType].strTextfile);
        end;

        // magic crystal
        if Thing[inventory[n].intType].chLetter = chr(161) then
        begin

          if (Thing[inventory[n].intType].intProf = 0) or (ThePlayer.intProf = Thing[inventory[n].intType].intProf) then
          begin
            if ThePlayer.intLvl > Thing[inventory[n].intType].intCharLvl - 1 then
            begin
              blKnowsSpell := False;

              // check if player already knows this spell
              for i := 1 to 12 do
                if spellbook[i].intType = Thing[inventory[n].intType].intSpellID then
                begin
                  blKnowsSpell := True;
                  Inc(spellbook[i].intKnown);
                  ShowTransMessage('You perform better in chanting "' + Thing[inventory[n].intType].strLearnChant + '".', False);

                  // remove used crystal from inventory
                  Dec(inventory[n].longNumber);
                  if inventory[n].longNumber = 0 then
                    inventory[n].intType := 0;
                    
                  break;
                end;

              // if spell not known, check if free space available
              if blKnowsSpell = False then
              begin
                if spellbook[12].intType = 0 then
                begin
				  for i := 1 to 12 do
					if spellbook[i].intType = 0 then
					begin
					  spellbook[i].intKnown   := 1;
					  spellbook[i].intType    := Thing[inventory[n].intType].intSpellID;
					  spellbook[i].intRefresh := Spell[spellbook[i].intType].intRefresh;
					  ShowTransMessage('You have learned the song "' + Thing[inventory[n].intType].strLearnChant + '".', False);					  
							  
            // remove used crystal from inventory
            Dec(inventory[n].longNumber);
              if inventory[n].longNumber = 0 then
                inventory[n].intType := 0;
						
					  // enchanter becomes mage when 7th spell is learned
					  if ThePlayer.intProf = 2 then // enchanter
						if ThePlayer.intDipl[6] = 0 then
						  // not mage yet
						  if i = 7 then
						  begin
							ThePlayer.intDipl[6] := 1;
							ShowTransMessage('You have been promoted to the rank "Mage".', True);
							StoreAchievement('Promoted to the rank "Mage".');
						  end;
	
					  break;
					end;                  
                 end
                 else
                   GetKeyInput('Your songbook is full; you can''t learn any new song.', True);
              end;
            end
            else
              GetKeyInput('You need at least level ' +
                IntToStr(thing[inventory[n].intType].intCharLvl) +
                ' to learn this song.', True);
          end
          else
            GetKeyInput(
              'This crystal cannot be studied by someone with your profession.',
              True);
        end;

      end;
    end;
  end;
end;

// This is the main inventory loop
procedure ShowInventory;
var
  n: longint;
  blCloseInventory: boolean;
  ch, dummy: string;
begin

  blCloseInventory := False;

  // main inventory loop
  repeat

    if UseSDL = True then
    begin
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      DarkenScreen;
      LoadImage_Title('graphics/equipbg.jpg');
    end;

    DecoIcon.x := 80;
    DecoIcon.y := 80;
    DecoIcon.w := 80;
    DecoIcon.h := 80;

    DecoIconS.x := 700 + HiResOffsetX;
    DecoIconS.y := 430 + HiResOffsetY;
    DecoIconS.w := 72;
    DecoIconS.h := 72;

    // inventory list and key selection loop
    repeat
      if UseSDL = True then
      begin
        BlitImage_Title;
        SDL_BLITSURFACE(extratiles, @DecoIcon, screen, @DecoIconS);
      end
      else
      begin
        ClearScreenSDL;
        StatusDeco;
        GlobalConColor := darkgray;
        TransTextXY(50, 3,  '     ___    ');
        TransTextXY(50, 4,  '    /   \   ');
        TransTextXY(50, 5,  '    |   |   ');
        TransTextXY(50, 6,  '    \___/   ');
        TransTextXY(50, 7,  '    __|__   ');
        TransTextXY(50, 8,  '   /     \  ');
        TransTextXY(50, 9,  '  //|   |\\ ');
        TransTextXY(50, 10, ' // |   | \\');
        TransTextXY(50, 11, ' || |   | ||');
        TransTextXY(50, 12, ' \\ |___| ||');
        TransTextXY(50, 13, '  \\|/ \| ||');
        TransTextXY(50, 14, '    || ||   ');
        TransTextXY(50, 15, '    || ||   ');
        TransTextXY(50, 16, '    || ||   ');
        TransTextXY(50, 17, '    || ||   ');
        TransTextXY(50, 18, '  _/ / \ \_ ');
        TransTextXY(50, 19, ' /__/   \__\');
        GlobalConColor := -1;
      end;

      TransTextXY(1, 1, 'INVENTORY OF ' + uppercase(ThePlayer.strName));
      TransTextXY(62, 1, 'Credits: ' + IntToStr(ThePlayer.longGold));

      // build and show the visible item list
      ListAllItems;

      // build and show equipment list
      ListEquipment;

      n := -1;

      dummy := GetKeyInput(
        '[i]nfo  [c]onsume  [s]tudy  [d]rop  |  [e]quip  [r]emove  [g]rease  [D]etails', False);

    until (dummy = 'c') or (dummy = 'r') or (dummy = 'd') or (dummy = 'D') or
      (dummy = 'e') or (dummy = 'i') or (dummy = 'ESC') or (dummy = 's') or
      (dummy = 'F1') or (dummy = 'F2') or (dummy = 'F3') or
      (dummy = 'F4') or (dummy = 'F5') or (dummy = 'F6') or
      (dummy = 'F7') or (dummy = 'F8') or (dummy = 'F9') or (dummy = 'F10') or
      (dummy = 'F11') or (dummy = 'F12') or (dummy = 'g');


    // evaluate key
    ch := dummy;

    // define quick keys
    if ch = 'F1' then
      BindQuickKey_Item(1);

    if ch = 'F2' then
      BindQuickKey_Item(2);

    if ch = 'F3' then
      BindQuickKey_Item(3);

    if ch = 'F4' then
      BindQuickKey_Item(4);

    if ch = 'F5' then
      BindQuickKey_Item(5);

    if ch = 'F6' then
      BindQuickKey_Item(6);

    if ch = 'F7' then
      BindQuickKey_Item(7);

    if ch = 'F8' then
      BindQuickKey_Item(8);

    if ch = 'F9' then
      BindQuickKey_Item(9);

    if ch = 'F10' then
      BindQuickKey_Item(10);

    if ch = 'F11' then
      BindQuickKey_Item(11);

    if ch = 'F12' then
      BindQuickKey_Item(12);

    // close inventory
    if ch = 'ESC' then
      blCloseInventory := True;

    // equip item
    if ch = 'e' then
      EquipItem;

    // grease weapon
    if ch = 'g' then
      GreaseItem;

    // remove equipped item
    if ch = 'r' then
    begin
      if ThePlayer.blCursed = False then
        RemoveItem
      else
        GetKeyInput('You can''t remove any equipment, because you are cursed.', True);
    end;

    // consume item
    if ch = 'c' then
      ConsumeItem;

    // simply drop item to ground, or combine it, or dip into well, or sacrifice at altar
    if (ch = 'd') and (DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding = 0) then
      DropItem;

    // drop item on trader --> sell it
    if (ch = 'd') and (DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding > 0) then
      SellItem;

    // look at item
    if ch = 'i' then
      ExamineItem;

    // equipment details
    if ch = 'D' then
      EquipmentInfo;

    // study item -> learn chant or read text
    if ch = 's' then
      StudyItem;

    if blWon = true then blCloseInventory:=true;

  until blCloseInventory = True;

  ClearScreenSDL;
  ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

end;


end.
