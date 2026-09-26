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

unit BaseOutput;

interface

uses
  WebBE, VidUtil, SysUtils, Constants, Math, RandomArea;

const
  FONTCOLOR_WHITE = 1;
  FONTCOLOR_GREEN = 2;
  FONTCOLOR_PURPLE = 3;
  FONTCOLOR_YELLOW = 4;

var
  GlobalFontColor, GlobalSmallOpac: integer;

procedure LoadImage_Tiles (intProfession, intSex: integer);
procedure LoadImage_Title(n: ansistring);
procedure LoadImage_Back(n: ansistring);

procedure BlitImage_Title;


procedure SmallCharXY(x: integer; y: integer; zeichen: char; transparent: boolean);

procedure AnyCharXY(x: integer; y: integer; zeichen: char; mode: integer);
procedure CharXY(x: integer; y: integer; zeichen: char; mode: integer; blTransformChar: boolean);
procedure TextXY(x: integer; y: integer; message: string);
procedure SmallTextXY(x: integer; y: integer; message: string;
  transparent: boolean; useoffset: boolean);
procedure TransTextXY(x: integer; y: integer; message: string);
procedure ClearScreenSDL;
procedure ShowMessage(message: string; pressanykey: boolean);

procedure InitGraphics(blNew: boolean);
procedure StopGraphics;

implementation

uses
  Player, CollectData;


// output BIG single character (SDL only; 20x40)
procedure BigCharXY(x: integer; y: integer; zeichen: char; mode: integer);
var
  CharRect: SDL_RECT;
  OrigRect: SDL_RECT;
  TransRect: SDL_RECT;
  HalfdarkRect: SDL_RECT;
  vv: integer;
  blDrawShade: boolean;
begin

  if UseSmallTiles = True then
  begin
    // position of char on screen
    CharRect.x := x * 20;           // 1.x: 20
    CharRect.y := y * 40;           // 1.x: 40
    CharRect.w := 20;               // 1.x: 20
    CharRect.h := 40;               // 1.x: 40

    // position of char in bitmap
    OrigRect.x := (Ord(zeichen) - 32) * 20;
    OrigRect.y := 0;
    OrigRect.w := 20;
    OrigRect.h := 40;

    // position of semi-transparent char in bitmap
    TransRect.x := 3440;
    TransRect.y := 0;
    TransRect.w := 20;
    TransRect.h := 40;

    // position of halfdark semi-transparent char in bitmap
    HalfdarkRect.x := 4320;
    HalfdarkRect.y := 0;
    HalfdarkRect.w := 20;
    HalfdarkRect.h := 40;
  end
  else
  begin
    // position of char on screen
    CharRect.x := x * 40;           // 1.x: 20
    CharRect.y := y * 80;           // 1.x: 40
    CharRect.w := 40;               // 1.x: 20
    CharRect.h := 80;               // 1.x: 40

    // position of char in bitmap
    OrigRect.x := (Ord(zeichen) - 32) * 40;
    OrigRect.y := 0;
    OrigRect.w := 40;
    OrigRect.h := 80;

    // position of semi-transparent char in bitmap
    TransRect.x := 6880;
    TransRect.y := 0;
    TransRect.w := 40;
    TransRect.h := 80;

    // position of halfdark semi-transparent char in bitmap
    HalfdarkRect.x := 8640;
    HalfdarkRect.y := 0;
    HalfdarkRect.w := 40;
    HalfdarkRect.h := 80;

  end;


  SDL_BLITSURFACE(TilesetASCII, @OrigRect, screen, @CharRect);

  // faded
  if mode = 1 then
    SDL_BLITSURFACE(TilesetASCII, @TransRect, screen, @CharRect)
  else
  begin

    // only dungeon tiles

    blDrawShade := False;

    case Ord(zeichen) of
      180, 214, 237, 244, 150, 138, 142, 236, 151, 152, 177, 178, 206,
      235, 153, 175, 176, 134, 135, 240, 136, 137, 154, 170, 173, 245,
      148, 149, 174, 183, 238, 181, 239, 182, 184, 185, 186, 199, 241,
      188, 190, 189, 196, 194, 203, 192, 198, 205, 209, 210, 211,
      212, 213, 225, 224, 223, 222, 226, 227, 228, 229,
      230, 231, 232, 233, 234, 242, 243, 249, 250, 251, 252, 253, 254: blDrawShade := True;
    end;

    if blDrawShade = True then
    begin
      vv := CollectLight(ThePlayer.intX, ThePlayer.intY) - 1;
      if (x < ThePlayer.intBX - vv) or (x > ThePlayer.intBX + vv) or
        (y < (ThePlayer.intBY + 1) - vv) or (y > (ThePlayer.intBY + 1) + vv) then  // halfdark
        SDL_BLITSURFACE(TilesetASCII, @HalfdarkRect, screen, @CharRect);

      vv := CollectLight(ThePlayer.intX, ThePlayer.intY) - 2;
      if (x < ThePlayer.intBX - vv) or (x > ThePlayer.intBX + vv) or
        (y < (ThePlayer.intBY + 1) - vv) or (y > (ThePlayer.intBY + 1) + vv) then  // halfdark
        SDL_BLITSURFACE(TilesetASCII, @HalfdarkRect, screen, @CharRect);
    end;

  end;
end;

// chooses between BIG char and normal Char depending on SDL or console mode
procedure AnyCharXY(x: integer; y: integer; zeichen: char; mode: integer);
begin
  if UseSDL = True then
    BigCharXY(x, y, zeichen, mode)
  else
    CharXY(x, y, zeichen, mode, true);
end;

// Load image into "ASCII" (tiles) surface
procedure LoadImage_Tiles (intProfession, intSex: integer);
var
  prof, sex, tilefile: ansistring;
begin

  case intProfession of
    1: prof := 'unused';
    2: prof := 'enchanter';
    3: prof := 'thief';
    4: prof := 'archer';
    5: prof := 'soldier';
  end;

  case intSex of
    1: sex := 'm';
    2: sex := 'f';
  end;

  if UseSmallTiles = True then
  begin
    if UseOldSmallTiles = True then
      tilefile := CONST_DATADIR + 'graphics/tiles/tileset-2-small-old.png'
    else
      tilefile := CONST_DATADIR + 'graphics/tiles/tileset-2-small-' + sex + '-' + prof + '.png';
  end
  else
    tilefile := CONST_DATADIR + 'graphics/tiles/tileset-2-big-' + sex + '-' + prof + '.png';

  SDL_FREESURFACE(tilesetASCII);

  if fileexists(tilefile) = True then
    tilesetASCII := IMG_LOAD(PChar(tilefile))
  else
  begin
    Writeln('ERROR: File ' + tilefile + ' not found.');
    Halt;
  end;
end;

// Load image into "title" surface
procedure LoadImage_Title(n: ansistring);
var
  DebugFile: Textfile;

begin
  SDL_FREESURFACE(title);

  n := CONST_DATADIR + n;

(*  
Assign(DebugFile, 'debug.txt');
Append(DebugFile);
writeln (DebugFile, 'Loading Image: ' + n);
Close(DebugFile);  
*)  
  
  //writeln ('Loading graphics file '+n);

  if fileexists(n) = True then
    title := IMG_LOAD(PChar(n))
  else
  begin
    Writeln('ERROR: File ' + n + ' not found.');
    Halt;
  end;
  
  //writeln('Loading successful.');

(*
Assign(DebugFile, 'debug.txt');
Append(DebugFile);
writeln (DebugFile, 'Loading ok');
Close(DebugFile);    
*)

end;


// Load image into "background" surface
procedure LoadImage_Back(n: ansistring);
var
DebugFile: textfile;
begin
  SDL_FREESURFACE(backgroundGraph);
  
  n := CONST_DATADIR + n;

(*  
Assign(DebugFile, 'debug.txt');
Append(DebugFile);
writeln (DebugFile, 'Loading Image: ' + n);
Close(DebugFile);  
*)
  
  //writeln ('Loading graphics file '+n);

  if fileexists(n) = True then
  begin
    backgroundGraph := IMG_LOAD(PChar(n))
  end
  else
  begin
    Writeln('ERROR: File ' + n + ' not found.');
    Halt;
  end;
  
  //writeln ('Loading successful.');

(* 
 Assign(DebugFile, 'debug.txt');
Append(DebugFile);
writeln (DebugFile, 'Loading ok');
Close(DebugFile);  
*)
  
end;


procedure BlitImage_Title;
var
  BlitRect: SDL_RECT;
begin
  BlitRect.w := 800;
  BlitRect.h := 0;
  BlitRect.x := 0 + HiResOffsetX;
  BlitRect.y := 0 + HiResOffsetY;
  SDL_BLITSURFACE(title, nil, screen, @BlitRect);
end;


// output small characters (7x12?) only for SDL mode
procedure SmallCharXY(x: integer; y: integer; zeichen: char; transparent: boolean);
var
  CharRect: SDL_RECT;
  OrigRect: SDL_RECT;
begin
  if UseSDL = True then
  begin
    // position of char on screen
    CharRect.x := (x * 7);

    if (UseHiRes = True) and (Netbook = False) then
      CharRect.y := (y * 12) - 4
    else if (UseHiRes = True) and (Netbook = True) then
      CharRect.y := (y * 12) - 2
    else
      CharRect.y := (y * 12);

    CharRect.w := 7;
    CharRect.h := 12;

    OrigRect.x := 760 + ((Ord(zeichen) - 32) * 7);
    OrigRect.w := 7;
    OrigRect.h := 12;

    // position of char in bitmap
    if transparent = False then
      OrigRect.y := 40
    else
      OrigRect.y := 80;

    // alternate way of selecting char
    case GlobalSmallOpac of
      3: OrigRect.y := 359;
      4: OrigRect.y := 375;
      5: OrigRect.y := 392;
    end;


    SDL_BLITSURFACE(extratiles, @OrigRect, screen, @CharRect);
  end;
end;




// make screen black
procedure ClearScreenSDL;
var
  i, j: integer;
begin

  if UseSDL = True then
    SDL_BLITSURFACE(backgroundGraph, nil, screen, nil)
  else
    for i := 0 to 80 do
      for j := 0 to 25 do
        TextXY(i, j, ' ');
end;


// output single character (10x20)
procedure CharXY(x: integer; y: integer; zeichen: char; mode: integer; blTransformChar: boolean);
var
  CharRect:  SDL_RECT;
  OrigRect:  SDL_RECT;
  TransRect: SDL_RECT;
  Color:     integer;
begin

  // prevent landscape from drawing if would be hidden behind status panels
  if UseSDL = False then
    if (Ord(zeichen) > 128) and ((y < 3) or (y > 25)) then
      if (Ord(zeichen) < 205) or (Ord(zeichen) > 212) then
        if (Ord(zeichen) <> 156) and (Ord(zeichen) <> 157) and
          (Ord(zeichen) <> 162) and (Ord(zeichen) <> 159) and
          (Ord(zeichen) <> 164) and (Ord(zeichen) <> 163) and
          (Ord(zeichen) <> 158) and (Ord(zeichen) <> 172) and (Ord(zeichen) <> 166) and
          (Ord(zeichen) <> 165) then
          exit;

  // SDL output
  if UseSDL = True then
  begin

    // position of char on screen
    CharRect.x := (x * 10) + HiResOffsetX;
    CharRect.y := (y * 20) + HiResOffsetY;

    CharRect.w := 10;
    CharRect.h := 20;

    // position of char in bitmap
    OrigRect.x := (Ord(zeichen) - 32) * 10;

    case GlobalFontColor of
      FONTCOLOR_WHITE : OrigRect.y:=0;
      FONTCOLOR_GREEN : OrigRect.y:=21;
      FONTCOLOR_PURPLE : OrigRect.y:=41;
      FONTCOLOR_YELLOW : OrigRect.y:=61;
    end;

    OrigRect.w := 10;
    OrigRect.h := 20;

    // position of semi-transparent char in bitmap
    TransRect.x := 1720;
    TransRect.y := 0;
    TransRect.w := 10;
    TransRect.h := 20;

    // if char is space, then only display it, if mode is not 2
    if ((Ord(zeichen) = 32) and (mode <> 2)) or (Ord(zeichen) > 32) then
      SDL_BLITSURFACE(TilesetGraph, @OrigRect, screen, @CharRect);

    // faded
    if mode = 1 then
      SDL_BLITSURFACE(TilesetGraph, @TransRect, screen, @CharRect);
  end
  else
  begin

    if x < 0 then
      Inc(x, HiResTextOffsetX);
    if y > 29 then
      Dec(y, HiResTextOffsetY);

    // console output: SDL has 29 or 33 lines, console only 25, so adjust y-values
    if (y = 29) then
      y := 25;
    if (y = 28) then
      y := 24;
    if (y = 27) then
      y := 23;
    if (y = 26) then
      y := 22;
    if y = 0 then
      y := 1;

    // basic color
    Color := white;

    // retransform SDL specific chars to normal ASCII chars
    if (blTransformChar=true) and (y < 22) then
    begin
      case Ord(zeichen) of

        36:
        begin
          zeichen := '=';  // electricity
          Color := cyan;
        end;

        187, 146, 179:
          zeichen := '@';        // player char

        128:
        begin
          zeichen := '.';                // blood
          Color   := red;
        end;

        129:
        begin
          zeichen := '*';                // spitting
          Color   := brown;
        end;

        130:
        begin
          zeichen := '*';                // fire 1
          Color   := yellow;
        end;

        131:
        begin
          zeichen := '*';                // fire 2
          Color   := red;
        end;


        132:
        begin
          zeichen := '*';                // ice 1
          Color   := cyan;
        end;

        133:
        begin
          zeichen := '*';                // ice 2
          Color   := lightcyan;
        end;

        134:
        begin
          zeichen := '+';                // small tree
          Color   := green;
        end;

        135:
        begin
          zeichen := '=';                // caveworm excrements
          Color   := darkgray;
        end;

        136:
        begin
          zeichen := '.';                // sand, mud
          Color   := brown;
        end;


        137:
        begin
          zeichen := 'T';                // big tree
          Color   := green;
        end;

        139:
        begin
          zeichen := '2';
          Color   := brown;
        end;

        140:
        begin
          zeichen := '3';
          Color   := lightmagenta;
        end;

        141:
        begin
          zeichen := '4';
          Color   := magenta;
        end;

        143:
        begin
          zeichen := '@';
          Color   := lightgray;
        end;

        144:
        begin
          zeichen := '1';
          color   := green;
        end;
        145:
        begin
          zeichen := '*';
          color   := yellow;
        end;
        147:
        begin
          zeichen := '*';
          color   := lightcyan;
        end;

        148:
        begin
          zeichen := ',';                // grass
          color   := lightgreen;
        end;

        149:
        begin
          zeichen := '^';                // hill
          color   := green;
        end;

        150:
        begin
          zeichen := '.';                // floor
          color   := lightgray;
        end;
        151:
        begin
          zeichen := '+';                // door
          color   := brown;
        end;
        152:
        begin
          zeichen := '\';                // open door
          color   := brown;
        end;

        153:
        begin
          zeichen := ',';                // closed chest
          color   := yellow;
        end;

        154:
        begin
          zeichen := ';';                // open chest
          color   := yellow;
        end;

        155:
        begin
          zeichen := '!';                // potion
          color   := lightblue;
        end;

        156:
          zeichen := '/';                // weapon
        157:
          zeichen := '(';
        158:
          zeichen := '{';
        159:
          zeichen := '\';
        160:
          zeichen := '"';                // ammu
        161:
        begin
          zeichen := '?';                // scroll
          color   := lightred;
        end;
        162:
          zeichen := '/';
        163:
          zeichen := ')';
        164:
          zeichen := '~';                // lance
        165:
          zeichen := '[';
        166:
        begin
          zeichen := '=';                // ring
          color   := yellow;
        end;

        167:
        begin
          zeichen := '$';                // money
          color   := yellow;
        end;

        168:
        begin
          zeichen := '%';                // food
          color   := brown;
        end;

        169:
        begin
          zeichen := '*';                // rune
          color   := green;
        end;

        170:
          zeichen := '|';                // altar
        171:
          zeichen := ':';                // rock
        172:
        begin
          zeichen := '}';
          color   := yellow;
        end;
        173:
        begin
          zeichen := '.';
          color   := lightblue;
        end;
        174:
        begin
          zeichen := chr(39);
          color   := darkgray;
        end;

        175:
        begin
          zeichen := '<';                // staircase up
          color   := lightblue;

        end;
        176:
        begin
          zeichen := '>';                // staircase down
          color   := lightblue;
        end;

        177:
        begin
          zeichen := '=';                // water
          color   := blue;
        end;

        178:
        begin
          zeichen := '^';                // mountain
          color   := lightgray;
        end;

        180:
        begin
          zeichen := '#';                // wall
          color   := white;
        end;

        181:
        begin
          zeichen := '+';                // small tree brown
          color   := brown;
        end;

        182:
        begin
          zeichen := 'T';                // big tree brown
          color   := brown;
        end;

        183:
        begin
          zeichen := '=';                // lava
          color   := red;
        end;

        184:
        begin
          zeichen := ',';                // grass dark
          color   := green;
        end;

        185:
        begin
          zeichen := '+';                // sec. door
          color   := cyan;
        end;

        186:
        begin
          zeichen := '#';                // sec. wall
          color   := lightcyan;
        end;

        188:
        begin
          zeichen := 'U';                // crypt
          color   := lightgray;
        end;

        189:
        begin
          zeichen := 'U';                // well
          color   := lightblue;
        end;

        190:
        begin
          zeichen := '#';                // alternate std. wall
          color   := cyan;
        end;

        191:
          zeichen := 'o';                // dungeon key

        192:
        begin
          zeichen := '#';                // alternate std. wall
          color   := green;
        end;

        193:
        begin
          zeichen := '?';             // page
          color   := brown;
        end;

        194:
        begin
          zeichen := '*';                // blue star floor
          color   := blue;
        end;

        195:
        begin
          zeichen := '*';
          color   := blue;
        end;
        196:
        begin
          zeichen := 'U';        // empty well
          color   := darkgray;
        end;
        197:
        begin
          zeichen := '0';
          color   := red;
        end;
        198:
        begin
          zeichen := '|';
          color   := red;
        end;
        199:
        begin
          zeichen := '#';
          color   := lightblue;
        end;
        200:
        begin
          zeichen := '5';
          color   := yellow;
        end;
        201:
        begin
          zeichen := '6';
          color   := lightgreen;
        end;
        202:
        begin
          zeichen := '7';
          color   := darkgray;
        end;
        203:
        begin
          zeichen := chr(39);
          color   := lightred;
        end;
        205:
        begin
          zeichen := '_';
          color   := lightred;
        end;
        206:
        begin
          zeichen := '^';
          color   := brown;
        end;
        207:
        begin
          zeichen := '*';
          color   := red;
        end;
        208:
        begin
          zeichen := '*';
          color   := white;
        end;
        209:
        begin
          zeichen := chr(39);                // grass border
          color   := brown;
        end;
        210:
        begin
          zeichen := chr(39);                // grass border
          color   := brown;
        end;
        211:
        begin
          zeichen := '=';                // water
          color   := lightblue;
        end;
        212:
        begin
          zeichen := '=';                // water
          color   := lightblue;
        end;
        213:
        begin
          zeichen := '=';                // water
          color   := lightblue;
        end;
        214:
        begin
          zeichen := '+';
          color   := lightgreen;
        end;
        215:
        begin
          zeichen := '-';
          color   := lightred;
        end;
        216:
        begin
          zeichen := '=';
          color   := lightgray;
        end;
        217:
        begin
          zeichen := '?';
          color   := cyan;
        end;
        218:
        begin
          zeichen := 'L';
          color   := lightgray;
        end;
        220:
        begin                       // player in water
          zeichen := '@';
          color   := blue;
        end;
        221:
        begin                       // antbee web
          zeichen := '%';
          color   := white;
        end;
        222:
        begin
          zeichen := '0';           // barrel
          color   := brown;
        end;
        223:
        begin
          zeichen := '-';           // table
          color   := brown;
        end;
        224:
        begin
          zeichen := ',';           // stool
          color   := brown;
        end;
        225:
        begin
          zeichen := '#';           // bookshelf
          color   := brown;
        end;
        226:
        begin
          zeichen := ':';           // big mushroom
          color   := cyan;
        end;
        227:
        begin
          zeichen := '.';           // small mushroom
          color   := cyan;
        end;
        228:
        begin
          zeichen := '-';           // wood
          color   := brown;
        end;
        229:
        begin
          zeichen := '0';           // gas cylinder
          color   := lightgray;
        end;
        230:
        begin
          zeichen := '.';           // machine oil
          color   := yellow;
        end;
        231:
        begin
          zeichen := '/';           // old machine parts
          color   := yellow;
        end;
        232:
        begin
          zeichen := '>';           // portal through time
          color   := lightgreen;
        end;
        233:
        begin
          zeichen := ',';           // snow
          color   := white;
        end;
        234:
        begin
          zeichen := chr(39);           // ice
          color   := cyan;
        end;
        235:
        begin
          zeichen := '^';           // Noldalur mountain
          color   := white;
        end;
        236:
        begin
          zeichen := '.';           // Noldalur floor
          color   := white;
        end;
        237:
        begin
          zeichen := '#';           // Noldalur wall
          color   := darkgray;
        end;
        238:
        begin
          zeichen := '+';                // small tree white
          color   := white;
        end;
        239:
        begin
          zeichen := 'T';                // big tree white
          color   := white;
        end;
        240:
        begin
          zeichen := ',';                // big tree white
          color   := white;
        end;
        241:
        begin
          zeichen := 'U';                // ice crypt
          color   := white;
        end;
        242:
        begin
          zeichen := '<';                // old stairs up
          color   := brown;
        end;
        243:
        begin
          zeichen := '>';                // old stairs down
          color   := brown;
        end;
        244:
        begin
          zeichen := '#';                // red wall
          color   := red;
        end;
        245:
        begin
          zeichen := '.';                // red floor
          color   := red;
        end;
        246:
        begin
          zeichen := 'O';                // shield
          color   := cyan;
        end;
        247:
        begin
          zeichen := '=';                // shoes
          color   := brown;
        end;
        249:
        begin
          zeichen := '+';                // close iron gate
          color   := darkgray;
        end;
        250:
        begin
          zeichen := '/';                // open iron gate
          color   := darkgray;
        end;
        251:
        begin
          zeichen := '<';                // ladder up
          color   := red;
        end;
        252:
        begin
          zeichen := '>';                // ladder down
          color   := red;
        end;
        253:
        begin
          zeichen := '#';                // wall spaceship
          color   := lightblue;
        end;
        254:
        begin
          zeichen := '.';                // floor spaceship
          color   := darkgray;
        end;
      end;
    end;

    // faded
    if mode = 1 then
      color := darkgray;

    // if a global color is defined, use it instead the color defined above
    if GlobalConColor > -1 then
      color := GlobalConColor;

    // print character (special chars only in dungeon area)
    if ((Ord(zeichen) > 127) and (y < 22)) or (Ord(zeichen) < 128) then
      TextOut(x, y, zeichen, color);
  end;
end;


// output a string (calls CharXY several times, until string is shown)
procedure TextXY(x: integer; y: integer; message: string);
var
  i:    integer;
  cstr: char;
begin
  for i := 1 to length(message) do
  begin
    cstr := message[i];
    CharXY(x + i, y, cstr, 0, false);
  end;
end;


// like TextXY, but with transparent space
procedure TransTextXY(x: integer; y: integer; message: string);
var
  i:    integer;
  cstr: char;
begin
  for i := 1 to length(message) do
  begin
    cstr := message[i];
    CharXY(x + i, y, cstr, 2, false);
  end;
end;


// like TextXY, but uses the smaller 7x12 chars and is always transparent
procedure SmallTextXY(x: integer; y: integer; message: string; transparent: boolean; useoffset: boolean);
var
  i:    integer;
  cstr: char;
  xoffset, yoffset: integer;
begin

  if (UseHiRes = True) and (Netbook = False) then
  begin
    xoffset := 17;
    yoffset := 7;
  end;

  if (UseHiRes = True) and (Netbook = True) then
  begin
    xoffset := 17;
    yoffset := 0;
  end;

  if (UseHiRes = False) or (UseOffset = False) then
  begin
    xoffset := 0;
    yoffset := 0;
  end;


  for i := 1 to length(message) do
  begin
    cstr := message[i];
    SmallCharXY(x + i + xoffset, y + yoffset, cstr, transparent);
  end;
end;


// show a message (calls TextXY)
procedure ShowMessage(message: string; pressanykey: boolean);
var
  intMY: integer;
begin
  if UseHiRes = False then
    intMY := 27
  else
    intMY := 27;


  TextXY(1, intMY,
    '                                                                            ');

  TextXY(1, intMY, message);
  if pressanykey = True then
  begin
    TextXY(1, intMY + 1,
      '                                                                            ');
    if (UseSDL = True) and (UseMouseToMove = True) then
      TextXY(34, intMY + 1, ' [Right-click, SPACE or ENTER to continue]')
    else
      TextXY(48, intMY + 1, ' [SPACE or ENTER to continue]');
  end;
  LastMessage := message;

  if UseSDL = True then
    SDL_UPDATERECT(screen, 0, 0, 0, 0)
  else
    UpdateScreen(True);
end;


  procedure InitGraphics(blNew: boolean);
  var
    VideoInitResult: integer;
    FullscreenFlag:  longword;
    debugfile: textfile;
    mm: TVideoMode;
  begin

    if UseFullScreen=true then
      FullscreenFlag := SDL_FULLSCREEN
    else
      FullscreenFlag := 0;   // SDL_FULLSCREEN

    GlobalConColor := -1;    // console text color
    GlobalFontColor := FONTCOLOR_WHITE;  // SDL text color

    GlobalSmallOpac := 1;


    if UseSDL = True then
    begin

      {$ifdef Darwin}
      SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,exOverflow, exUnderflow, exPrecision]);
      FullScreenFlag := 0;
      {$endif}

      if blNew = True then
      begin
        VideoInitResult := SDL_INIT(SDL_INIT_VIDEO);
        if VideoInitResult < 0 then
        begin
          Writeln('Error: Could not initialize SDL video. However, you can play this game');
          Writeln('in console mode by setting the option UseSDL to "= False" (without the');
          Writeln('quotation marks). To do so, edit lambdarogue.cfg in a text editor.');
          halt;
        end;

        SDL_ENABLEUNICODE(1);
        SDL_ENABLEKEYREPEAT(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);

        SDL_WM_SETCAPTION('LambdaRogue ' + strVersion, 'LambdaRogue ' + strVersion);
        //SDL_WM_SETICON(SDL_LOADBMP('graphics/icon.png'), 0);
      end;

      if UseHiRes = False then
      begin
        screen    := SDL_SETVIDEOMODE(800, 600, 24, SDL_HWSURFACE + FullscreenFlag);
        HiResOffsetX := 0;
        HiResOffsetY := 0;
        HiResTextOffsetX := 0;
        HiResTextOffsetY := 0;
        ChantBarX := 254;
        ChantBarY := 540;
        LoadImage_Back('graphics/bg-800.png');
      end
      else
      begin
        screen := SDL_SETVIDEOMODE(1024, 768, 24, SDL_HWSURFACE + FullscreenFlag);

        HiResOffsetX := 110;
        HiResTextOffsetX := -12;
        ChantBarX := 239;
        ChantBarY := 708;
        
        LoadImage_Back('graphics/bg-1024.png');

        //if Netbook = True then
        //begin
        //  HiResOffsetY     := 0;
        //  HiResTextOffsetY := 0;
        //end
        //else
        //begin
          HiResOffsetY     := 80;
          HiResTextOffsetY := 3;
        //end;
      end;

      if screen = nil then
        halt;

      if backgroundGraph = nil then
        halt;

      if blNew = True then
      begin
      
        //writeln('Lade Tile-Grafiken');
        if UseSmallTiles = True then
          tilesetASCII := IMG_LOAD(PChar(CONST_DATADIR + 'graphics/tiles/tileset-2-small-m-soldier.png'))
        else
          tilesetASCII := IMG_LOAD(PChar(CONST_DATADIR + 'graphics/tiles/tileset-2-big-m-soldier.png'));

        if tilesetASCII = nil then
          halt;

        //writeln('Lade Schrift-Grafiken');
        tilesetGraph := IMG_LOAD(PChar(CONST_DATADIR + 'graphics/tiles/tileset-1.png'));
        if tilesetGraph = nil then
          halt;

        //writeln('Lade Titelbild');
        if UseHiRes=true then
          LoadImage_Title('graphics/title-1024.jpg')
        else
          LoadImage_Title('graphics/title-800.jpg');

        if title = nil then
          halt;

        //writeln('Lade Interface-Grafiken');
        extratiles := IMG_LOAD(PChar(CONST_DATADIR + 'graphics/extra.png'));
        if extratiles = nil then
          halt;

        //writeln('Erzeuge Pixel');

        // initiate "pixels" to draw with
        PixelWhiteRect.x := 300;
        PixelWhiteRect.y := 230;
        PixelWhiteRect.w := 1;
        PixelWhiteRect.h := 1;

        PixelGreyRect.x := 301;
        PixelGreyRect.y := 230;
        PixelGreyRect.w := 1;
        PixelGreyRect.h := 1;

        PixelRedRect.x := 302;
        PixelRedRect.y := 230;
        PixelRedRect.w := 1;
        PixelRedRect.h := 1;

        PixelBlueRect.x := 303;
        PixelBlueRect.y := 230;
        PixelBlueRect.w := 1;
        PixelBlueRect.h := 1;

        PixelGreenRect.x := 304;
        PixelGreenRect.y := 230;
        PixelGreenRect.w := 1;
        PixelGreenRect.h := 1;

        PixelBrownRect.x := 305;
        PixelBrownRect.y := 230;
        PixelBrownRect.w := 1;
        PixelBrownRect.h := 1;

        PixelOrangeRect.x := 306;
        PixelOrangeRect.y := 230;
        PixelOrangeRect.w := 1;
        PixelOrangeRect.h := 1;
      end;
    end
    else
    begin
      HiResOffsetX     := 0;
      HiResOffsetY     := 0;
      HiResTextOffsetX := 0;
      HiResTextOffsetY := 0;
      InitVideo;
      SetCursorType(crHidden);
      InitKeyboard;

      GetVideoMode(mm);
      if (mm.row<>25) or (mm.col<>80) then
      begin
        TextOut (1, 1, 'The text mode of LambdaRogue requires a terminal size of 80x25.', lightblue);
        TextOut (1, 2, 'Your current terminal has a size of ' + IntToStr(mm.col) + 'x' + IntToStr(mm.row)+'.', lightblue);
        TextOut (1, 3, 'Please configure your terminal accordingly and try again.', lightblue);

        TextOut (1, 5, 'Press Enter to exit.', lightblue);


        UpdateScreen(true);

        GetKeyEvent;

        DoneKeyboard;
        DoneVideo;
        Halt;
      end;
    end;
  
  (*  
  Assign(DebugFile, 'debug.txt');
  Append(DebugFile);
  writeln (DebugFile, 'Grafik ini ok');
  Close(DebugFile);   
  *)
  
  end;

  procedure StopGraphics;
  begin
    if UseSDL = True then
    begin
      SDL_FREESURFACE(tilesetASCII);
      SDL_FREESURFACE(tilesetGraph);
      SDL_FREESURFACE(title);
      SDL_FREESURFACE(backgroundGraph);
      SDL_FREESURFACE(screen);
      SDL_FREESURFACE(extratiles);
      SDL_QUIT;
    end
    else
    begin
      DoneKeyboard;
      SetCursorType(crUnderline);
      DoneVideo;
    end;
  end;



end.
