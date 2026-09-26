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

unit Effects;


interface

uses
  Constants, ExternMusic, ExternSFX, GFX, Crt, Keyboard, Video, Input,
  Dungeon, Plot, LineOfSight,
  SysUtils, SDL, RandomArea, Player, Items,
  BaseOutput, MessageLog, DrawDungeon, UserInterface;

var
  DecoIcon, DecoIconS: SDL_RECT;

procedure AreaDamage(n: integer);
procedure DoEffect(intEffectType: integer; intEffectRange: integer; strEffectText: string);
procedure HiveDestroyed;
procedure CylinderDestroyed(x, y: integer);
procedure BarrelDestroyed(x, y: integer);
function DoEffectOnMonster(intEffectRange: integer; intSpellType: integer): integer;

implementation

uses
  InventoryScreen;

procedure AreaDamage(n: integer);
var
  i: integer;
begin
  for i:=1 to 510 do
  begin
    if (Monster[i].intX=ThePlayer.intX-1) and (Monster[i].intY = ThePlayer.intY) then
    begin
      PlaySFX('hit-arrow.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

    if (Monster[i].intX=ThePlayer.intX-1) and (Monster[i].intY = ThePlayer.intY-1) then
    begin
      PlaySFX('hit-arrow-2.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

    if (Monster[i].intX=ThePlayer.intX) and (Monster[i].intY = ThePlayer.intY-1) then
    begin
      PlaySFX('hit-arrow.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

    if (Monster[i].intX=ThePlayer.intX+1) and (Monster[i].intY = ThePlayer.intY-1) then
    begin
      PlaySFX('hit-arrow-2.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

    if (Monster[i].intX=ThePlayer.intX+1) and (Monster[i].intY = ThePlayer.intY) then
    begin
      PlaySFX('hit-arrow.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

    if (Monster[i].intX=ThePlayer.intX+1) and (Monster[i].intY = ThePlayer.intY+1) then
    begin
      PlaySFX('hit-arrow-2.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

    if (Monster[i].intX=ThePlayer.intX) and (Monster[i].intY = ThePlayer.intY+1) then
    begin
      PlaySFX('hit-arrow.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

    if (Monster[i].intX=ThePlayer.intX-1) and (Monster[i].intY = ThePlayer.intY+1) then
    begin
      PlaySFX('hit-arrow-2.ogg');
      Monster[i].blHuman:=false;
      Monster[i].blAttacked:=true;
      ShowTransMessage('You hit the '+Monster[i].strName+'.', false);
      dec(Monster[i].intHP, n);
      if Monster[i].intHP < 1 then
        IsMonsterDead(i);
    end;

  end;
end;

// hive destroyed message
procedure HiveDestroyed;
var
  n: integer;
begin
  DngLvl[HiveX, HiveY].intIntegrity := 0;
  ShowTransMessage('You destroy the monster' + chr(39) + 's hive.', False);

  Inc(ThePlayer.longEXP, DungeonLevel * 100);
  Inc(ThePlayer.longThisLevelEXP, DungeonLevel * 100);
  LevelUp;

  Inc(ThePlayer.longScore, DungeonLevel * 10);

  // drop items around the destroyed hive
  // - hive itself drops a setitem

  if random(1000)>500 then
    n:=ReturnSetItem
  else
    n:=ReturnRareItem;

  DngLvl[HiveX, HiveY].intItem := n;

  // - area around hive drops standard item
  n:=ReturnRandomItem;
  if (DngLvl[HiveX-1,HiveY-1].intIntegrity=0) and (DngLvl[HiveX-1,HiveY-1].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX-1,HiveY-1].intItem:=n;

  n:=ReturnRandomItem;
  if (DngLvl[HiveX,HiveY-1].intIntegrity=0) and (DngLvl[HiveX,HiveY-1].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX,HiveY-1].intItem:=n;

  n:=ReturnRandomItem;
  if (DngLvl[HiveX+1,HiveY-1].intIntegrity=0) and (DngLvl[HiveX+1,HiveY-1].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX+1,HiveY-1].intItem:=n;

  n:=ReturnRandomItem;
  if (DngLvl[HiveX+1,HiveY].intIntegrity=0) and (DngLvl[HiveX+1,HiveY].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX+1,HiveY].intItem:=n;

  n:=ReturnRandomItem;
  if (DngLvl[HiveX+1,HiveY+1].intIntegrity=0) and (DngLvl[HiveX+1,HiveY+1].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX+1,HiveY+1].intItem:=n;

  n:=ReturnRandomItem;
  if (DngLvl[HiveX,HiveY+1].intIntegrity=0) and (DngLvl[HiveX,HiveY+1].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX,HiveY+1].intItem:=n;

  n:=ReturnRandomItem;
  if (DngLvl[HiveX-1,HiveY+1].intIntegrity=0) and (DngLvl[HiveX-1,HiveY+1].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX-1,HiveY+1].intItem:=n;

  n:=ReturnRandomItem;
  if (DngLvl[HiveX-1,HiveY].intIntegrity=0) and (DngLvl[HiveX-1,HiveY].intItem=0) and (random(1000)>500) then
    DngLvl[HiveX-1,HiveY].intItem:=n;


  // remove hive
  HiveX := -1;
  HiveY := -1;

  // check if player has "DestroyHive" Quest and this is the correct level
  // then set intNoHivesAnymore[level] to 1
  if IsTargetHive(DungeonLevel) = True then
  begin
    intNoHivesAnymore[DungeonLevel] := 1;
    ShowTransMessage('You have destroyed this hive forever. Return to your client.',
      False);
  end;
end;

// gas cylinder destroyed
procedure CylinderDestroyed(x, y: integer);
begin
  PlaySFX('explosion.ogg');

  ShowTransMessage('You destroy a gas cylinder; it explodes.', False);

  DngLvl[x, y].intIntegrity := 0;
  DngLvl[x, y].intFloorType := 31;
  DngLvl[x, y].intLight     := 2;
  DngLvl[x, y].intAirType   := 1;
  DngLvl[x, y].intAirRange  := 8 + trunc(random(10));

  DngLvl[x + 1, y].intIntegrity := 0;
  DngLvl[x + 1, y].intFloorType := 31;
  DngLvl[x + 1, y].intLight     := 2;
  DngLvl[x + 1, y].intAirType   := 1;
  DngLvl[x + 1, y].intAirRange  := 8 + trunc(random(10));
  if DngLvl[x + 1, y].intFloorType = 56 then
    CylinderDestroyed(x + 1, y);

  DngLvl[x + 1, y + 1].intIntegrity := 0;
  DngLvl[x + 1, y + 1].intFloorType := 31;
  DngLvl[x + 1, y + 1].intLight     := 2;
  DngLvl[x + 1, y + 1].intAirType   := 1;
  DngLvl[x + 1, y + 1].intAirRange  := 8 + trunc(random(10));
  if DngLvl[x + 1, y + 1].intFloorType = 56 then
    CylinderDestroyed(x + 1, y + 1);

  DngLvl[x, y + 1].intIntegrity := 0;
  DngLvl[x, y + 1].intFloorType := 31;
  DngLvl[x, y + 1].intLight     := 2;
  DngLvl[x, y + 1].intAirType   := 1;
  DngLvl[x, y + 1].intAirRange  := 8 + trunc(random(10));
  if DngLvl[x, y + 1].intFloorType = 56 then
    CylinderDestroyed(x, y + 1);

  DngLvl[x - 1, y + 1].intIntegrity := 0;
  DngLvl[x - 1, y + 1].intFloorType := 31;
  DngLvl[x - 1, y + 1].intLight     := 2;
  DngLvl[x - 1, y + 1].intAirType   := 1;
  DngLvl[x - 1, y + 1].intAirRange  := 8 + trunc(random(10));
  if DngLvl[x - 1, y + 1].intFloorType = 56 then
    CylinderDestroyed(x - 1, y + 1);

  DngLvl[x - 1, y].intIntegrity := 0;
  DngLvl[x - 1, y].intFloorType := 31;
  DngLvl[x - 1, y].intLight     := 2;
  DngLvl[x - 1, y].intAirType   := 1;
  DngLvl[x - 1, y].intAirRange  := 8 + trunc(random(10));
  if DngLvl[x - 1, y].intFloorType = 56 then
    CylinderDestroyed(x - 1, y);

  DngLvl[x - 1, y - 1].intIntegrity := 0;
  DngLvl[x - 1, y - 1].intFloorType := 31;
  DngLvl[x - 1, y - 1].intLight     := 2;
  DngLvl[x - 1, y - 1].intAirType   := 1;
  DngLvl[x - 1, y - 1].intAirRange  := 8 + trunc(random(10));
  if DngLvl[x - 1, y - 1].intFloorType = 56 then
    CylinderDestroyed(x - 1, y - 1);

  DngLvl[x, y - 1].intIntegrity := 0;
  DngLvl[x, y - 1].intFloorType := 31;
  DngLvl[x, y - 1].intLight     := 2;
  DngLvl[x, y - 1].intAirType   := 1;
  DngLvl[x, y - 1].intAirRange  := 8 + trunc(random(10));
  if DngLvl[x, y - 1].intFloorType = 56 then
    CylinderDestroyed(x, y - 1);

end;

// barrel destroyed
procedure BarrelDestroyed(x, y: integer);
var
  i, j, n: integer;
  blFindSomething: boolean;
begin
  PlaySFX('destroy-barrel.ogg');
  DngLvl[x, y].intIntegrity := 0;
  ShowTransMessage('You destroy the barrel.', False);

  n := 240;
  blFindSomething := False;

  if DngLvl[x, y].intItem = 0 then
  begin
    if random(CONST_CHESTISEMPTY) > n then
    begin
      i := 0;
      repeat
        Inc(i);
        j := trunc(1 + random(ItemCount));
        if (Thing[j].blUnique = False) and (Thing[j].blRare = False) and
          (Thing[j].blShopOnly = False) and (DungeonLevel >= Thing[j].intMinLvl) then
        begin
          DngLvl[x, y].intItem := j;
          blFindSomething      := True;
        end;
      until (i = 2000) or (blFindSomething = True);
    end;
  end;

end;

// show and calculate effects monsters suffer from player spells
function DoEffectOnMonster(intEffectRange: integer; intSpellType: integer): integer;
var
  ch1, chDir:   char;
  GunX, GunY, GunBY, GunBX, GunBYborder, vx, vy, i: integer;
  blMonsterHit: boolean;
begin

  // choose visual representation of spell
  case intSpellType of
    1:
      ch1 := chr(145);        // fire
    2:
      ch1 := chr(132);        // ice
    3:
      ch1 := chr(195);        // water
    19:
      ch1 := chr(207);        // force
    45:
      ch1 := chr(129);        // poison
    56:
      ch1 := chr(36);         // electricity
  end;

  // if an item with effect MaxMagic is worn, double the effect of the spell
  if CheckEffect(37) = True then
    intEffectRange := intEffectRange * 2;

  // direction
  chDir := '-';

  chDir := GetDirection(0);
  ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);

  if chDir = KeyNorth then
  begin
    vx := 0;
    vy := -1;
  end;

  if chDir = KeySouth then
  begin
    vx := 0;
    vy := 1;
  end;

  if chDir = KeyNorthEast then
  begin
    vx := 1;
    vy := -1;
  end;

  if chDir = KeySouthEast then
  begin
    vx := 1;
    vy := 1;
  end;

  if chDir = KeyNorthWest then
  begin
    vx := -1;
    vy := -1;
  end;

  if chDir = KeySouthWest then
  begin
    vx := -1;
    vy := 1;
  end;

  if chDir = KeyWest then
  begin
    vx := -1;
    vy := 0;
  end;

  if chDir = KeyEast then
  begin
    vx := 1;
    vy := 0;
  end;

  GunX  := ThePlayer.intX;
  GunY  := ThePlayer.intY;
  GunBX := ThePlayer.intBX;

  if UseSDL = True then
    GunBY := ThePlayer.intBY + 1
  else
    GunBY := ThePlayer.intBY;

  PlaySFX('magic-combat.ogg');

  // as long as there is no wall etc. let the bullet fly. At least for ThePlayer.intView+2 tiles
  blMonsterHit := False;
  while (DngLvl[GunX, GunY].intIntegrity = 0) and
    (abs(ThePlayer.intX - GunX) < ThePlayer.intView + 2) and
    (abs(ThePlayer.intY - GunY) < ThePlayer.intView + 2) and (blMonsterHit = False) do
  begin
    Inc(GunX, vx);
    Inc(GunY, vy);

    Inc(GunBX, vx);
    Inc(GunBY, vy);

    if (UseSmallTiles = True) or (UseSDL = False) then
      GunBYborder := 1
    else
      GunBYborder := 0;

    // show bullet
    if (GunBX > 1) and (GunBX < ThePlayer.intBX * 2) and
      (GunBY > GunBYborder) and (GunBY < ThePlayer.intBY * 2) then
    begin
      AnyCharXY(GunBX, GunBY, ch1, 0);
      //             TextXY(GunBX-1, GunBY, ch1);

      if UseSDL = True then
        SDL_UPDATERECT(screen, 0, 0, 0, 0)
      else
        UpdateScreen(True);
      delay(50);
      if UseSDL = True then
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // special effects of fire spells
    if intSpellType = 1 then
    begin
      // was a monster's hive hit?
      if (HiveX > -1) and (HiveY > -1) then
        if (HiveX = GunX) and (HiveY = GunY) then
        begin
          if DngLvl[HiveX, HiveY].intIntegrity > 0 then
          begin
            Dec(DngLvl[HiveX, HiveY].intIntegrity, 10 * intEffectRange);
            ShowTransMessage('You damage a monster' + chr(39) +
              's hive.', False);
            if DngLvl[HiveX, HiveY].intIntegrity < 1 then
            begin
              DngLvl[HiveX, HiveY].intFloorType := 2;
              HiveDestroyed;
            end;
          end;
        end;

      // was a paper item hit?
      if DngLvl[GunX, GunY].intItem > 0 then
        if Thing[DngLvl[GunX, GunY].intItem].chLetter= chr(193) then
        begin
          ShowTransMessage('Your fire chant destroys the '+Thing[DngLvl[GunX, GunY].intItem].strName+'.', false);
          DngLvl[GunX, GunY].intItem:=0;
        end;

      // was a corpse hit?
      if DngLvl[GunX, GunY].intItem > 0 then
        if Thing[DngLvl[GunX, GunY].intItem].chLetter = chr(37) then
        begin
          ShowTransMessage('The ' + Thing[DngLvl[GunX, GunY].intItem].strName +' is roasted.', false);
          DngLvl[GunX, GunY].intItem:=ReturnItemByName('Meat');
        end;

      // was an antbee web hit?
      if DngLvl[GunX, GunY].intAirType = 6 then
      begin
        DngLvl[GunX, GunY].intAirType  := 0;
        DngLvl[GunX, GunY].intAirRange := 0;
        ShowTransMessage('You destroy an antbee web.', False);
      end;

      // was a gas cylinder hit?
      if DngLvl[GunX, GunY].intFloorType = 56 then
        CylinderDestroyed(GunX, GunY);

      // was machine oil hit?
      if (DngLvl[GunX, GunY].intFloorType = 57) or ((DngLvl[GunX, GunY].blBlood=true) and ((DungeonLevel=26) or (DungeonLevel=27))) then
      begin

        if DngLvl[GunX, GunY].intFloorType = 57 then
          DngLvl[GunX, GunY].intFloorType := 2;

        DngLvl[GunX, GunY].intAirType   := 1;
        Inc(DngLvl[GunX, GunY].intAirRange, 7 + trunc(random(10)));
        ShowTransMessage('You emblaze the oil on the ground.', False);
      end;

      // was ice hit?
      if DngLvl[GunX, GunY].intFloorType = 61 then
      begin
        DngLvl[GunX, GunY].intFloorType := 5;
        ShowTransMessage('Ice is melting ...', False);
      end;
    end;

    // was a monster hit?
    for i := 1 to 510 do
    begin
      if (Monster[i].intX = GunX) and (Monster[i].intY = GunY) then
      begin

        Monster[i].blHuman    := False;
        // even men and peaceful monsters will now be angry
        Monster[i].blAttacked := True;  // set attacked flag

        blMonsterHit := True;

        // if the monster is immune against spell, show message
        // - water immunity?
        if (intSpellType = 3) and ((Monster[i].blWater = True) or
          (Monster[i].blWaterC = True)) then
        begin
          intEffectRange := 0;
          ShowTransMessage('The ' + Monster[i].strName +
            ' is immune to water magic.', False);
        end;

        // - fire immunity?
        if (intSpellType = 1) and (Monster[i].blFire = True) then
        begin
          intEffectRange := 0;
          ShowTransMessage('The ' + Monster[i].strName +
            ' is immune to fire magic.', False);
        end;

        // - ice immunity?
        if (intSpellType = 2) and (Monster[i].blIce = True) then
        begin
          intEffectRange := 0;
          ShowTransMessage('The ' + Monster[i].strName +
            ' is immune to ice magic.', False);
        end;

        // - electricity immunity?
        if (intSpellType = 4) then
        begin
          if (Monster[i].blElect = True) then
          begin
            intEffectRange := 0;
            ShowTransMessage('The ' + Monster[i].strName +  ' is immune to electricity.', False);
          end
          else
          begin
            inc(Monster[i].intPara, 2+(intEffectRange div 4));
            ShowTransMessage('The ' + Monster[i].strName + ' is stunned.', false);
          end
        end;


        // if the monster vulnearable against spell, double effect
        // - water vulnerability? (fire)
        if (intSpellType = 3) and (Monster[i].blFire = True) and (Monster[i].blWater = False) and
          (Monster[i].blWaterC = False) then
        begin
          intEffectRange := intEffectRange * 2;
          ShowTransMessage('The ' + Monster[i].strName +
            ' suffers critical water damage.', False);
        end;

        // - fire vulnerability? (ice)
        if (intSpellType = 1) and (Monster[i].blIce = True) and
          (Monster[i].blFire = False) then
        begin
          intEffectRange := intEffectRange * 2;
          ShowTransMessage('The ' + Monster[i].strName +
            ' suffers critical fire damage.', False);
        end;

        // - ice vulnerability? (water)
        if (intSpellType = 2) and ((Monster[i].blWater = True) or
          (Monster[i].blWaterC = True)) and (Monster[i].blIce = False) then
        begin
          intEffectRange := intEffectRange * 2;
          ShowTransMessage('The ' + Monster[i].strName +
            ' suffers critical ice damage.', False);
        end;

        // - electricity vulnerability? (water)
        if (intSpellType = 4) and ((Monster[i].blWater = True) or
          (Monster[i].blWaterC = True)) and (Monster[i].blElect = False) then
        begin
          intEffectRange := intEffectRange * 2;
          ShowTransMessage('The ' + Monster[i].strName +
            ' suffers critical electrical damage.', False);
        end;

        // poison attack
        if (intSpellType = 45) then
        begin
          if Monster[i].blPoison=false then
          begin
            inc(Monster[i].intPoison, intEffectRange);
            ShowTransMessage('You poison the ' + Monster[i].strName + '.', false);
          end
          else
            ShowTransMessage('The ' + Monster[i].strName + ' is immune to poison.', false);
        end;

        // decrease monster's HP by intEffectRange
        if (intSpellType <> 19) then
          Dec(Monster[i].intHP, intEffectRange)
        else
        begin
          if ThePlayer.intStrength >= intEffectRange then
          begin
            Dec(ThePlayer.intStrength, intEffectRange);
            Dec(Monster[i].intHP, intEffectRange);
          end
          else
            GetKeyInput(
              'You feel too weak; the force attack has no effect.', True);
        end;

        if Monster[i].intHP < 1 then
          Monster[i].intHP := 0;

        // check if monster's dead
        IsMonsterDead(i);

      end;
    end;
  end;

  DoEffectOnMonster := 1;
  if blMonsterHit = False then
    DoEffectOnMonster := 0;

end;


// show aura spells (these are spells which affect the air around the player)
procedure AuraSpell(n, range: integer);
var
  i, j: integer;
begin
  case n of
    1:
      BlendMagic(1);        // fire
    2:
      BlendMagic(2);        // ice
    3:
      BlendMagic(3);        // water
    4:
      BlendMagic(14);       // purify
    5:
      BlendMagic(19);      // lichtbringer
    6:
      BlendMagic(20);      // antbee web
  end;

  SetVisible;
  for i := 1 to DngMaxWidth do
    for j := 1 to DngMaxHeight do
      if (DngLvl[i, j].blLOS = True) and (DngLvl[i, j].intIntegrity = 0) then
      begin
        // create "normal" aura
        if n <> 5 then
        begin
          // only on non-dark tiles
          if DngLvl[i, j].intAirType <> 5 then
          begin
            DngLvl[i, j].intAirType  := n;
            DngLvl[i, j].intAirRange := range;

            // special effects of fire aura
            if n=1 then
            begin
              // tile transformations
              case DngLvl[i, j].intFloorType of
                17: DngLvl[i, j].intFloorType := 23; // grass -> dry grass
                10: DngLvl[i, j].intFloorType := 21; // small tree -> small dry tree
                13: DngLvl[i, j].intFloorType := 22; // big tree -> big dry tree
                61: DngLvl[i, j].intFloorType := 5;  // ice -> water
              end;
            end;

            // special effects of ice aura
            if n=1 then
            begin
            end;

            // special effects of water aura
            if n=2 then
            begin
            end;

          end;
        end
        else
        begin   // create "Lichtbringer" aura
          // but ONLY dark tiles
          if DngLvl[i, j].intAirType = 5 then
          begin
            DngLvl[i, j].intAirType  := 0;
            DngLvl[i, j].intAirRange := range;
          end;
        end;
      end;
end;


// effects of items and chants selected in inventory or in spellbook
procedure DoEffect(intEffectType: integer; intEffectRange: integer;
  strEffectText: string);
var
  rx, ry, n: integer;
begin

  // random effect?
  if intEffectType = -1 then
  begin
    n := trunc(random(47));
    case n of
      0:
        intEffectType := 2;
      1:
        intEffectType := 3;
      2:
        intEffectType := 4;
      3:
        intEffectType := 5;
      4:
        intEffectType := 8;
      5:
        intEffectType := 9;
      6:
        intEffectType := 12;
      7:
        intEffectType := 15;
      8:
        intEffectType := 16;
      9:
        intEffectType := 18;
      10:
        intEffectType := 21;
      11:
        intEffectType := 22;
      12:
        intEffectType := 23;
      13:
        intEffectType := 24;
      14:
        intEffectType := 27;
      15:
        intEffectType := 29;
      16:
        intEffectType := 30;
      17:
        intEffectType := 32;
      18:
        intEffectType := 33;
      19:
        intEffectType := 34;
      20:
        intEffectType := 38;
      21:
        intEffectType := 39;
      22:
        intEffectType := 40;
      23:
        intEffectType := 10;
      24:
        intEffectType := 13;
      25:
        intEffectType := 14;
      26:
        intEffectType := 17;
      27:
        intEffectType := 35;
      28:
        intEffectType := 31;
      29:
        intEffectType := 49;
      30:
        intEffectType := 28;
      31:
        intEffectType := 37;
      32:
        intEffectType := 26;
      33:
        intEffectType := 50;
      34:
        intEffectType := 51;
      35:
        intEffectType := 52;
      36:
        intEffectType := 53;
      37:
        intEffectType := 54;
      38:
        intEffectType := 55;
      39:
        intEffectType := 56;
      40:
        intEffectType := 58;
      41:
        intEffectType := 45;
      42:
        intEffectType := 62;
      43:
        intEffectType := 64;
      44:
        intEffectType := 65;
      45:
        intEffectType := 66;
      46:
        intEffectType := 57;
    end;

  end;


  // MaxMagic item equipped?
  if CheckEffect(37) = True then
    intEffectRange := intEffectRange * 2;

  strEffectText:='-';

  case intEffectType of

    // regain food
    1:
    begin
      PlaySFX('magic-holy.ogg');
      Inc(ThePlayer.longFood, intEffectRange);
      if ThePlayer.intReli = 4 then
        Inc(ThePlayer.longFood, intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'Your stomach is filled with food';
      ShowStatus;
    end;

    // reduce poison
    2:
    begin
      PlaySFX('magic-heal.ogg');
      Dec(ThePlayer.intPoison, intEffectRange);
      if ThePlayer.intPoison < 0 then
      begin
        ThePlayer.intPoison := 0;
        if strEffectText = '-' then
          strEffectText := 'You are cured from poison';
      end;
    end;

    // regain PP
    3:
    begin
      PlaySFX('magic-heal.ogg');
      BlendMagic(7);
      Inc(ThePlayer.intPP, intEffectRange);
      if ThePlayer.intPP > ThePlayer.intMaxPP then
        ThePlayer.intPP := ThePlayer.intMaxPP;
      if strEffectText = '-' then
        strEffectText := 'Your psychic power regenerates';
    end;

    // regain HP
    4:
    begin
      PlaySFX('magic-heal.ogg');
      BlendMagic(6);
      Inc(ThePlayer.intHP, intEffectRange);
      if ThePlayer.intHP > ThePlayer.intMaxHP then
        ThePlayer.intHP := ThePlayer.intMaxHP;
      if strEffectText = '-' then
        strEffectText := 'Your health regenerates';
    end;

    // become invisible
    5:
    begin
      PlaySFX('magic-time.ogg');
      inc(ThePlayer.intInvis, intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'Suddenly, you became invisible';
    end;

    // ExtraEXP
    6:
    begin
      PlaySFX('resistance.ogg');
      inc(ThePlayer.intTempResist[6], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel wiser';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // ExtraGold
    7:
    begin
      PlaySFX('coins.ogg');
      Inc(ThePlayer.intTempResist[7], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel that you will be a little richer soon';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;


    // fire aura
    8:
    begin
      PlaySFX('magic-fireaura.ogg');
      if strEffectText = '-' then
        strEffectText := 'You create an Fire Aura';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      AuraSpell(1, intEffectRange);
    end;

    // ice aura
    9:
    begin
      PlaySFX('magic-combat.ogg');
      if strEffectText = '-' then
        strEffectText := 'You create an Ice Aura';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      AuraSpell(2, intEffectRange);
    end;


    // poison resistance
    10:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[10], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against poison';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;


    // heal confusion
    12:
    begin
      PlaySFX('magic-holy.ogg');
      if ThePlayer.intConfusion > 0 then
      begin
        Dec(ThePlayer.intConfusion, intEffectRange);
        if ThePlayer.intConfusion < 0 then
          ThePlayer.intConfusion := 0;
        if strEffectText = '-' then
          strEffectText := 'You feel less confused';
      end;
    end;

    // fire resistance
    13:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[13], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against fire';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // ice resistance
    14:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[14], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against ice';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // magic wall
    15:
    begin
      PlaySFX('magic-time.ogg');
      BlendMagic(9);
      ThePlayer.intWall := intEffectRange;
      if strEffectText = '-' then
        strEffectText := 'A magic barrier has been created around you';
    end;

    // strength drug
    16:
    begin
      if ThePlayer.intTotalVitari < 2 then
        Inc(ThePlayer.intStrength, intEffectRange);
      if ThePlayer.intTotalVitari >= 2 then
        Inc(ThePlayer.intStrength, intEffectRange div 2);
      if ThePlayer.intTotalVitari >= 4 then
        Inc(ThePlayer.intStrength, intEffectRange div 4);
      if ThePlayer.intTotalVitari >= 6 then
        Inc(ThePlayer.intStrength, intEffectRange div 6);
      if ThePlayer.intTotalVitari >= 8 then
        Inc(ThePlayer.intStrength, intEffectRange div 8);
      if ThePlayer.intTotalVitari >= 10 then
        Inc(ThePlayer.intStrength, intEffectRange div 10);

      Inc(ThePlayer.intTotalVitari);
      if ThePlayer.intTotalVitari > 200 then
        ThePlayer.intTotalVitari := 200;

      if strEffectText = '-' then
        strEffectText := 'You feel very strong';

      case ThePlayer.intTotalVitari of
        1:
          ThePlayer.intNextVitari := 500;
        2:
          ThePlayer.intNextVitari := 400;
        3:
          ThePlayer.intNextVitari := 350;
        4:
          ThePlayer.intNextVitari := 200;
        5:
          ThePlayer.intNextVitari := 80;
        6:
          ThePlayer.intNextVitari := 50;
        7:
          ThePlayer.intNextVitari := 20;
      end;
      if ThePlayer.intTotalVitari > 7 then
        ThePlayer.intNextVitari := 10;
      ThePlayer.intNeedVitari   := 0;
    end;

    // blindness resistance
    17:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[17], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against blindness';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // heal blindness
    18:
    begin
      PlaySFX('magic-holy.ogg');
      if ThePlayer.intBlind > 0 then
      begin
        Dec(ThePlayer.intBlind, intEffectRange);
        if ThePlayer.intBlind < 0 then
          ThePlayer.intBlind := 0;
        if strEffectText = '-' then
          strEffectText := 'Your blindness is cured';
      end;
    end;

    // force
    19:
    begin
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      if DoEffectOnMonster(intEffectRange, 19) = 0 then
        strEffectText := 'The force attack missed; no enemy was hurt';
      BlendMagic(13);
      if strEffectText = '-' then
        strEffectText := 'You throw concentrated psychic power at the enemy';
    end;

    // heal aura
    20:
    begin
      PlaySFX('magic-holy.ogg');
      if strEffectText = '-' then
        strEffectText := 'You create a healing Aura';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      AuraSpell(4, intEffectRange);
    end;


    // teleport
    21:
    begin
      PlaySFX('magic-time.ogg');
      if strEffectText = '-' then
        strEffectText := 'You have been teleported to another region';
      repeat
        rx := trunc(random(DngMaxWidth - 12)) + 1;
        ry := trunc(random(DngMaxHeight - 12)) + 1;
      until DngLvl[rx, ry].intIntegrity = 0;
      ThePlayer.intX := rx;
      ThePlayer.intY := ry;
    end;


    // water aura
    22:
    begin
      PlaySFX('magic-water.ogg');
      if strEffectText = '-' then
        strEffectText := 'You create a Water Aura';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      AuraSpell(3, intEffectRange);
    end;


    // lose HP
    23:
    begin
      PlaySFX('magic-bad.ogg');
      if strEffectText = '-' then
        strEffectText := 'You feel unhealthy';
      Dec(ThePlayer.intHP, intEffectRange);
      if IsPlayerDead = True then
        GameOver('Poisoned to death.');
    end;


    // lose PP
    24:
    begin
      PlaySFX('magic-bad.ogg');
      if strEffectText = '-' then
        strEffectText := 'Your psychic power was drained';
      Dec(ThePlayer.intPP, intEffectRange);
      if ThePlayer.intPP < 0 then
        ThePlayer.intPP := 0;
    end;

    // resist paralye
    26:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[26], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against paralization';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // heal paralyze
    27:
    begin
      PlaySFX('magic-holy.ogg');
      if ThePlayer.intPara > 0 then
      begin
        Dec(ThePlayer.intPara, intEffectRange);
        if ThePlayer.intPara < 0 then
          ThePlayer.intPara := 0;
        if strEffectText = '-' then
          strEffectText := 'You can move again';
      end;
    end;

    // calm resistance
    28:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[28], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against calm';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;


    // heal calm
    29:
    begin
      PlaySFX('magic-holy.ogg');
      if ThePlayer.intCalm > 0 then
      begin
        Dec(ThePlayer.intCalm, intEffectRange);
        if ThePlayer.intCalm < 0 then
          ThePlayer.intCalm := 0;
        if strEffectText = '-' then
          strEffectText := 'You can chant again';
      end;
    end;


    // freeze time
    30:
    begin
      PlaySFX('magic-time.ogg');
      ThePlayer.intFreeze := intEffectRange;
      if strEffectText = '-' then
        strEffectText := 'Suddenly, time seems to be frozen';
    end;

    // curse resistance
    31:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[31], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against curses';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;


    // uncurse
    32:
    begin
      PlaySFX('magic-holy.ogg');
      if ThePlayer.blCursed = True then
      begin
        ThePlayer.blCursed := False;
        if strEffectText = '-' then
          strEffectText := 'You are not cursed anymore';
      end;
    end;


    // bless
    33:
    begin
      PlaySFX('magic-holy.ogg');
      if ThePlayer.blEvil = False then
      begin
        BlendMagic(5);
        ThePlayer.blBlessed := True;
        ThePlayer.blCursed  := False;
        if ThePlayer.intTotalVitari > 0 then
        begin
          ThePlayer.intTotalVitari := 0;
          ThePlayer.intNextVitari := 0;
          ThePlayer.intNeedVitari := 0;
          strEffectText :=
            ThePlayer.strReli +
            ' blessed you and healed your from your drug addiction';
        end
        else
        if strEffectText = '-' then
          strEffectText := 'You feel blessed by ' + ThePlayer.strReli;
      end;
    end;


    // curse
    34:
    begin
      PlaySFX('magic-bad.ogg');
      if ThePlayer.blEvil = False then
      begin
        if (CheckEffect(31) = False) and (ThePlayer.intHumility < 10) then
        begin
          BlendMagic(8);
          ThePlayer.blBlessed := False;
          ThePlayer.blCursed  := True;
          if strEffectText = '-' then
            strEffectText := 'A dark shadow threatens your mind';
        end
        else
          strEffectText := 'Due to your high humility, you resist a dark shadow';
      end;
    end;

    // water resistance
    35:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[35], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against water';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // MaxMagic
    37:
    begin
      PlaySFX('magic-time.ogg');
      Inc(ThePlayer.intTempResist[37], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'Your magic is stronger';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;


    // fire
    38:
    begin
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      if DoEffectOnMonster(intEffectRange, 1) = 0 then
        strEffectText := 'Your fire attack missed; no enemy was hurt';
      BlendMagic(1);
      if strEffectText = '-' then
        strEffectText := 'You throw fire out of your arms';
    end;


    // ice
    39:
    begin
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      if DoEffectOnMonster(intEffectRange, 2) = 0 then
        strEffectText := 'Your ice attack missed; no enemy was hurt';
      BlendMagic(2);
      if strEffectText = '-' then
        strEffectText := 'You throw ice out of your arms';
    end;


    // water
    40:
    begin
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      if DoEffectOnMonster(intEffectRange, 3) = 0 then
        strEffectText := 'Your water attack missed; no enemy was hurt';
      BlendMagic(3);
      if strEffectText = '-' then
        strEffectText := 'Water flows out of your arms';
    end;

    // clone item
    42:
    begin
      strEffectText := CloneItem;
      PlaySFX('magic-holy.ogg');
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // confusion
    44:
    begin
      PlaySFX('magic-bad.ogg');
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      BlendMagic(10);
      Inc(ThePlayer.intConfusion, intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel confused';
    end;

    // poison
    45:
    begin
      PlaySFX('magic-bad.ogg');
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      BlendMagic(4);
      Inc(ThePlayer.intPoison, intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel very sick';
    end;

    // meteor -- don't drink!
    46:
    begin
      if thePlayer.blEvil=false then
      begin
        PlaySFX('magic-bad.ogg');
        ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
        BlendMagic(4);
        Inc(ThePlayer.intPoison, intEffectRange);
        if strEffectText = '-' then
          strEffectText := 'You feel very sick';
        DngLvl[ThePlayer.intX,ThePlayer.intY].intItem := ReturnItemByName('Meteor');
      end
      else
      begin
        if DungeonLevel=1 then  // evil players can win by drinking Meteor
        begin
          PlaySFX('magic-fireaura.ogg');
          ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
          BlendMagic(18);
          DarkenScreen;
          WinGame;
          blWon:=true;
        end;
      end;
    end;

    // identify item
    47:
    begin
      strEffectText := IdentifyItem;
      PlaySFX('magic-holy.ogg');
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // lichtbringer
    48:
    begin
      PlaySFX('magic-time.ogg');
      if strEffectText = '-' then
        strEffectText := 'You enlighten the darkness';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      AuraSpell(5, intEffectRange);
    end;

    // divine rage bonus
    49:
    begin
      PlaySFX('magic-time.ogg');
      Inc(ThePlayer.intTempResist[49], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel your god watch over you';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // wipe
    50:
    begin
      PlaySFX('magic-time.ogg');
      KillAllMonsters;
      ThePlayer.intHP := ThePlayer.intHP div 2;
      if strEffectText = '-' then
        strEffectText := 'You feel pain and suddenly you are all alone';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // drainpp resistance
    51:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[51], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel very focused';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // drainstr resistance
    52:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[52], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You are confident in your strength';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // heal PP and HP
    53:
    begin
      PlaySFX('magic-holy.ogg');
      BlendMagic(21);
      Inc(ThePlayer.intHP, intEffectRange);
      if ThePlayer.intHP > ThePlayer.intMaxHP then
        ThePlayer.intHP := ThePlayer.intMaxHP;

      Inc(ThePlayer.intPP, intEffectRange);
      if ThePlayer.intPP > ThePlayer.intMaxPP then
        ThePlayer.intPP := ThePlayer.intMaxPP;

      if strEffectText = '-' then
        strEffectText := 'You are healed, and your psychic powers are restored';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // familiar terrain
    54:
    begin
      PlaySFX('magic-holy.ogg');
      Inc(ThePlayer.intTempResist[54], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel familiar with this area';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // electricity resistance
    55:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[55], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You feel resistant against electricity';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // electricity
    56:
    begin
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
      if DoEffectOnMonster(intEffectRange, 4) = 0 then
        strEffectText := 'Your electricity attack missed; no enemy was hurt';
      BlendMagic(22);
      if strEffectText = '-' then
        strEffectText := 'You attack with electricity';
    end;

    // red. PP costs
    57:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[57], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You need less psychic power for your songs';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // area damage
    58:
    begin
      AreaDamage(intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'You attack the surrounding area';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // inc hit
    62:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[62], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'Your hitting precision increases';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // inc fight
    64:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[64], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'Your fighting skill increases';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // inc talent
    66:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[66], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'The strength of your talent increases';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

    // inc humility
    65:
    begin
      PlaySFX('resistance.ogg');
      Inc(ThePlayer.intTempResist[65], intEffectRange);
      if strEffectText = '-' then
        strEffectText := 'The relation to your god increases';
      ShowDungeon(ThePlayer.intX, ThePlayer.intY, 80, 25, 0);
    end;

  end;

  if strEffectText = '-' then
    strEffectText := 'Nothing seems to happen';
  ShowTransMessage(strEffectText + '.', False);
end;

end.
