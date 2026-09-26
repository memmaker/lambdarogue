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

unit ExternMusic;


interface

uses
  Constants, WebBE;

function MusicPlaying: boolean;
procedure PlayMusic(SoundFile: string);
procedure StopMusic;
procedure InitMusic;
procedure FreeMusic;


var
  ExtProgram:      TProcess;
  blUseExternPlayer: boolean;
  strExternPlayer: string;

  intVolumeMusic: integer;

CONST
AUDIO_FREQUENCY:INTEGER=44100;
AUDIO_FORMAT:WORD=MIX_DEFAULT_FORMAT;
AUDIO_CHANNELS:INTEGER=2;
AUDIO_CHUNKSIZE:INTEGER=4096;

VAR
music:pMIX_MUSIC=NIL;

implementation


function MusicPlaying: boolean;
begin
 if Mix_PlayingMusic=0 then
   MusicPlaying := false
 else
   MusicPlaying := true;
end;


procedure StopMusic;
begin
  MIX_HALTMUSIC;
end;


procedure PlayMusic(SoundFile: string);
begin

  //writeln('Trying to play '+CONST_DATADIR + 'music/' + Soundfile);

  if blUseExternPlayer=true then
  begin
    music:=MIX_LOADMUS(pchar(CONST_DATADIR + 'music/' + Soundfile));
    if music=nil then
    begin
      Writeln ('Warning: music file ' + CONST_DATADIR + 'music/' + Soundfile +' could not be opened.');
    end
    else
    begin
      MIX_PLAYMUSIC(music,0);
      MIX_VOLUMEMUSIC(intVolumeMusic);
    end;
  end;
end;


procedure InitMusic;
begin
  //Writeln ('Initializing SDL audio ...');
  SDL_INIT(SDL_INIT_AUDIO);
  IF MIX_OPENAUDIO(AUDIO_FREQUENCY, AUDIO_FORMAT, AUDIO_CHANNELS, AUDIO_CHUNKSIZE)<>0 THEN
  begin
    writeln ('Error: SDL Mixer could not be initialized.');
    HALT;
  end;
  //Writeln ('SDL audio initialized.');
end;


procedure FreeMusic;
begin
  //Writeln ('Stopping music.');
  MIX_HALTMUSIC;
  //Writeln ('Unloading music.');
  MIX_FREEMUSIC(music);

  //Writeln ('Stopping SDL audio.');
  MIX_CLOSEAUDIO;
end;

end.
