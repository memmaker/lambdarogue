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

unit ExternSFX;


interface

uses
  Constants, ExternMusic, Process, crt, SDL, SDL_MIXER;

function SFXPlaying: boolean;
procedure PlaySFX(SoundFile: string);
procedure StopSFX;
procedure InitSFX;
procedure FreeSFX;


var
  sound_coins: pMIX_CHUNK=NIL;
  sound_destroy_barrel: pMIX_CHUNK=NIL;
  sound_door_close: pMIX_CHUNK=NIL;
  sound_door_open: pMIX_CHUNK=NIL;
  sound_door_unlock: pMIX_CHUNK=NIL;
  sound_explosion: pMIX_CHUNK=NIL;
  sound_gate_openclose: pMIX_CHUNK=NIL;
  sound_hit_arrow_2: pMIX_CHUNK=NIL;
  sound_hit_arrow: pMIX_CHUNK=NIL;
  sound_hit_stub: pMIX_CHUNK=NIL;
  sound_hit_sword_2: pMIX_CHUNK=NIL;
  sound_hit_sword: pMIX_CHUNK=NIL;
  sound_levelup: pMIX_CHUNK=NIL;
  sound_magic_bad: pMIX_CHUNK=NIL;
  sound_magic_combat: pMIX_CHUNK=NIL;
  sound_magic_fail: pMIX_CHUNK=NIL;
  sound_magic_fireaura: pMIX_CHUNK=NIL;
  sound_magic_heal: pMIX_CHUNK=NIL;
  sound_magic_holy: pMIX_CHUNK=NIL;
  sound_magic_time: pMIX_CHUNK=NIL;
  sound_magic_water: pMIX_CHUNK=NIL;
  sound_open_chest: pMIX_CHUNK=NIL;
  sound_page_turn: pMIX_CHUNK=NIL;
  sound_quake: pMIX_CHUNK=NIL;
  sound_resistance: pMIX_CHUNK=NIL;
  sound_steps: pMIX_CHUNK=NIL;
  sound_swoosh: pMIX_CHUNK=NIL;

  soundchannel:INTEGER;
  blUseExternPlayerTwo: boolean;

  intVolumeSFX: integer;

implementation


function SFXPlaying: boolean;
begin
  //if ExtProgramTwo <> nil then
    //SFXPlaying := ExtProgramTwo.Running;
  SFXPlaying:=false;
end;


procedure StopSFX;
begin
  // unused
end;


procedure PlaySFX(SoundFile: string);
begin
  if blUseExternPlayerTwo = true then
  begin
    if soundfile='coins.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_coins, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_coins,0);
    end;
    if soundfile='destroy-barrel.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_destroy_barrel, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_destroy_barrel,0);
    end;
    if soundfile='door-close.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_door_close, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_door_close,0);
    end;
    if soundfile='door-open.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_door_open, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_door_open,0);
    end;
    if soundfile='door-unlock.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_door_unlock, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_door_unlock,0);
    end;
    if soundfile='explosion.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_explosion, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_explosion,0);
    end;
    if soundfile='gate-openclose.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_gate_openclose, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_gate_openclose,0);
    end;
    if soundfile='hit-arrow-2.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_hit_arrow_2, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_hit_arrow_2,0);
    end;
    if soundfile='hit-arrow.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_hit_arrow, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_hit_arrow,0);
    end;
    if soundfile='hit-stub.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_hit_stub, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_hit_stub,0);
    end;
    if soundfile='hit-sword-2.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_hit_sword_2, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_hit_sword_2,0);
    end;
    if soundfile='hit-sword.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_hit_sword, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_hit_sword,0);
    end;
    if soundfile='levelup.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_levelup, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_levelup,0);
    end;
    if soundfile='magic-bad.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_bad, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_bad,0);
    end;
    if soundfile='magic-combat.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_combat, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_combat,0);
    end;
    if soundfile='magic-fail.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_fail, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_fail,0);
    end;
    if soundfile='magic-fireaura.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_fireaura, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_fireaura,0);
    end;
    if soundfile='magic-heal.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_heal, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_heal,0);
    end;
    if soundfile='magic-holy.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_holy, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_holy,0);
    end;
    if soundfile='magic-time.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_time, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_time,0);
    end;
    if soundfile='magic_water.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_magic_water, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_magic_water,0);
    end;
    if soundfile='open-chest.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_open_chest, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_open_chest,0);
    end;
    if soundfile='page-turn.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_page_turn, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_page_turn,0);
    end;
    if soundfile='quake.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_quake, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_quake,0);
    end;
    if soundfile='resistance.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_resistance, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_resistance,0);
    end;
    if soundfile='steps.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_steps, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_steps,0);
    end;
    if soundfile='swoosh.ogg' then
    begin
      MIX_VOLUMECHUNK(sound_swoosh, intVolumeSFX);
      soundchannel:=MIX_PLAYCHANNEL(-1,sound_swoosh,0);
    end;
  end;
end;


procedure InitSFX;
begin
  //Writeln('Loading SFX ...');
  sound_coins:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/coins.ogg'));
  sound_destroy_barrel:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/destroy-barrel.ogg'));
  sound_door_close:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/door-close.ogg'));
  sound_door_open:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/door-open.ogg'));
  sound_door_unlock:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/door-unlock.ogg'));
  sound_explosion:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/explosion.ogg'));
  sound_gate_openclose:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/gate-openclose.ogg'));
  sound_hit_arrow_2:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/hit-arrow-2.ogg'));
  sound_hit_arrow:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/hit-arrow.ogg'));
  sound_hit_stub:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/hit-stub.ogg'));
  sound_hit_sword_2:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/hit-sword-2.ogg'));
  sound_hit_sword:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/hit-sword.ogg'));
  sound_levelup:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/levelup.ogg'));
  sound_magic_bad:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-bad.ogg'));
  sound_magic_combat:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-combat.ogg'));
  sound_magic_fail:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-fail.ogg'));
  sound_magic_fireaura:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-fireaura.ogg'));
  sound_magic_heal:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-heal.ogg'));
  sound_magic_holy:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-holy.ogg'));
  sound_magic_time:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-time.ogg'));
  sound_magic_water:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/magic-water.ogg'));
  sound_open_chest:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/open-chest.ogg'));
  sound_page_turn:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/page-turn.ogg'));
  sound_quake:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/quake.ogg'));
  sound_resistance:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/resistance.ogg'));
  sound_steps:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/steps.ogg'));
  sound_swoosh:=MIX_LOADWAV(pchar(CONST_DATADIR + 'sound/swoosh.ogg'));
  //writeln('SFX loading done.');
end;


procedure FreeSFX;
begin
  //MIX_HALTCHANNEL(soundchannel);
  //Writeln('Unloading SFX...');
  MIX_FREECHUNK(sound_coins);
  MIX_FREECHUNK(sound_destroy_barrel);
  MIX_FREECHUNK(sound_door_close);
  MIX_FREECHUNK(sound_door_open);
  MIX_FREECHUNK(sound_door_unlock);
  MIX_FREECHUNK(sound_explosion);
  MIX_FREECHUNK(sound_gate_openclose);
  MIX_FREECHUNK(sound_hit_arrow_2);
  MIX_FREECHUNK(sound_hit_arrow);
  MIX_FREECHUNK(sound_hit_stub);
  MIX_FREECHUNK(sound_hit_sword_2);
  MIX_FREECHUNK(sound_hit_sword);
  MIX_FREECHUNK(sound_levelup);
  MIX_FREECHUNK(sound_magic_bad);
  MIX_FREECHUNK(sound_magic_combat);
  MIX_FREECHUNK(sound_magic_fail);
  MIX_FREECHUNK(sound_magic_fireaura);
  MIX_FREECHUNK(sound_magic_heal);
  MIX_FREECHUNK(sound_magic_holy);
  MIX_FREECHUNK(sound_magic_time);
  MIX_FREECHUNK(sound_magic_water);
  MIX_FREECHUNK(sound_open_chest);
  MIX_FREECHUNK(sound_page_turn);
  MIX_FREECHUNK(sound_quake);
  MIX_FREECHUNK(sound_resistance);
  MIX_FREECHUNK(sound_steps);
  MIX_FREECHUNK(sound_swoosh);
  //Writeln('SFX unloaded.');
end;

end.
