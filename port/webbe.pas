{ LambdaRogue web backend (RVIP): the one unit that replaces JEDI-SDL (SDL,
  SDL_image, SDL_mixer) and FPC's Crt/Video/Keyboard/Process for the game.

  The game draws only by blitting rectangles out of its own PNG/JPG sheets
  onto the 800x600 screen (fonts are sheets too). Here every SDL_BlitSurface
  becomes one entry of a blit list; SDL_UpdateRect / SDL_PollEvent / delay
  hand the list to the page (be_frame), which only copies rectangles.
  Keys and mouse come back through be_poll (asyncified by wasm-opt, so a
  poll can wait for the page). Sound: be_sfx / be_music with the file name.

  Native build (no CPUWASM32): a headless backend for the range/overflow
  checked run (web/check.sh) that feeds random keys and draws nothing. }
unit WebBE;

{$mode objfpc}

interface

uses SysUtils;

{ ---------------------------------------------------------------- SDL video }
type
  UInt8 = byte;
  UInt16 = word;
  SInt16 = smallint;
  UInt32 = longword;
  SInt32 = longint;

  PSDL_Rect = ^TSDL_Rect;
  TSDL_Rect = record
    x, y: SInt16;
    w, h: UInt16;
  end;
  SDL_Rect = TSDL_Rect;

  PSDL_Surface = ^TSDL_Surface;
  TSDL_Surface = record
    flags: UInt32;
    w, h: longint;
    id: longint;        { page-side surface number: 1 = screen }
    alpha: longint;     { SDL_SetAlpha: 0..255, 255 = opaque }
  end;

  TSDLKey = longword;
  TSDLMod = longword;
  TSDL_KeySym = record
    scancode: UInt8;
    sym: TSDLKey;
    modifier: TSDLMod;
    unicode: UInt16;
  end;
  TSDL_KeyboardEvent = record
    type_: UInt8;
    which: UInt8;
    state: UInt8;
    keysym: TSDL_KeySym;
  end;
  TSDL_MouseMotionEvent = record
    type_: UInt8;
    which: UInt8;
    state: UInt8;
    x, y: UInt16;
    xrel: SInt16;
    yrel: SInt16;
  end;
  TSDL_MouseButtonEvent = record
    type_: UInt8;
    which: UInt8;
    button: UInt8;
    state: UInt8;
    x: UInt16;
    y: UInt16;
  end;
  PSDL_Event = ^TSDL_Event;
  TSDL_Event = record
    case UInt8 of
      0: (type_: byte);
      2, 3: (key: TSDL_KeyboardEvent);
      4: (motion: TSDL_MouseMotionEvent);
      5, 6: (button: TSDL_MouseButtonEvent);
      7: (pad: array [0..23] of byte);
  end;

const
  SDL_INIT_VIDEO = $00000020;
  SDL_INIT_AUDIO = $00000010;
  SDL_HWSURFACE = $00000001;
  SDL_FULLSCREEN = $80000000;
  SDL_SRCALPHA = $00010000;
  SDL_DEFAULT_REPEAT_DELAY = 500;
  SDL_DEFAULT_REPEAT_INTERVAL = 30;

  SDL_NOEVENT = 0;
  SDL_KEYDOWN = 2;
  SDL_KEYUP = 3;
  SDL_MOUSEMOTION = 4;
  SDL_MOUSEBUTTONDOWN = 5;
  SDL_MOUSEBUTTONUP = 6;
  SDL_BUTTON_LEFT = 1;
  SDL_BUTTON_MIDDLE = 2;
  SDL_BUTTON_RIGHT = 3;

  SDLK_BACKSPACE = 8;
  SDLK_TAB = 9;
  SDLK_RETURN = 13;
  SDLK_ESCAPE = 27;
  SDLK_SPACE = 32;
  SDLK_DELETE = 127;
  SDLK_KP0 = 256;
  SDLK_KP1 = 257;
  SDLK_KP2 = 258;
  SDLK_KP3 = 259;
  SDLK_KP4 = 260;
  SDLK_KP5 = 261;
  SDLK_KP6 = 262;
  SDLK_KP7 = 263;
  SDLK_KP8 = 264;
  SDLK_KP9 = 265;
  SDLK_KP_PERIOD = 266;
  SDLK_KP_ENTER = 271;
  SDLK_UP = 273;
  SDLK_DOWN = 274;
  SDLK_RIGHT = 275;
  SDLK_LEFT = 276;
  SDLK_INSERT = 277;
  SDLK_HOME = 278;
  SDLK_END = 279;
  SDLK_PAGEUP = 280;
  SDLK_PAGEDOWN = 281;
  SDLK_F1 = 282;
  SDLK_F2 = 283;
  SDLK_F3 = 284;
  SDLK_F4 = 285;
  SDLK_F5 = 286;
  SDLK_F6 = 287;
  SDLK_F7 = 288;
  SDLK_F8 = 289;
  SDLK_F9 = 290;
  SDLK_F10 = 291;
  SDLK_F11 = 292;
  SDLK_F12 = 293;

function SDL_Init(flags: UInt32): longint;
procedure SDL_Quit;
function SDL_EnableUNICODE(enable: longint): longint;
function SDL_EnableKeyRepeat(delay, interval: longint): longint;
procedure SDL_WM_SetCaption(title, icon: pchar);
function SDL_SetVideoMode(w, h, bpp: longint; flags: UInt32): PSDL_Surface;
function SDL_BlitSurface(src: PSDL_Surface; srcrect: PSDL_Rect; dst: PSDL_Surface; dstrect: PSDL_Rect): longint;
procedure SDL_UpdateRect(screen: PSDL_Surface; x, y: SInt32; w, h: UInt32);
procedure SDL_FreeSurface(surface: PSDL_Surface);
function SDL_SetAlpha(surface: PSDL_Surface; flag: UInt32; alpha: UInt8): longint;
function SDL_PollEvent(event: PSDL_Event): longint;
function SDL_GetMouseState(var x: longint; var y: longint): UInt8;
function SDL_BUTTON(b: longint): longint;
function IMG_Load(const path: pchar): PSDL_Surface;

{ ------------------------------------------------------------- SDL_mixer }
type
  PMix_Chunk = ^TMix_Chunk;
  TMix_Chunk = record name: ansistring; end;
  PMix_Music = ^TMix_Music;
  TMix_Music = record name: ansistring; end;
const
  MIX_DEFAULT_FORMAT = $8010;

function Mix_OpenAudio(frequency: longint; format: UInt16; channels, chunksize: longint): longint;
procedure Mix_CloseAudio;
function Mix_LoadWAV(path: pchar): PMix_Chunk;
function Mix_LoadMUS(path: pchar): PMix_Music;
procedure Mix_FreeChunk(c: PMix_Chunk);
procedure Mix_FreeMusic(m: PMix_Music);
function Mix_PlayChannel(channel: longint; c: PMix_Chunk; loops: longint): longint;
function Mix_HaltChannel(channel: longint): longint;
function Mix_VolumeChunk(c: PMix_Chunk; volume: longint): longint;
function Mix_PlayMusic(m: PMix_Music; loops: longint): longint;
function Mix_HaltMusic: longint;
function Mix_PlayingMusic: longint;
function Mix_VolumeMusic(volume: longint): longint;

{ --------------------------------------------- Crt / Video / Keyboard (text mode) }
{ The game's console mode is never used on the web (lambdarogue.cfg says
  UseSDL = True); these keep its code compiling. }
const
  Black = 0; Blue = 1; Green = 2; Cyan = 3; Red = 4; Magenta = 5; Brown = 6;
  LightGray = 7; DarkGray = 8; LightBlue = 9; LightGreen = 10; LightCyan = 11;
  LightRed = 12; LightMagenta = 13; Yellow = 14; White = 15; Blink = 128;
  crHidden = 0; crUnderline = 1; crBlock = 2; crHalfBlock = 3;
type
  TVideoMode = record col, row: word; color: boolean; end;
  TVideoCell = word;
  TVideoBuf = array [0..32759] of TVideoCell;
  PVideoBuf = ^TVideoBuf;
  TKeyEvent = longword;
var
  VideoBuf: PVideoBuf;
  ScreenWidth: word = 80;
  ScreenHeight: word = 25;
  TextAttr: byte = 7;

procedure delay(ms: word);
function KeyPressed: boolean;
function ReadKey: char;
procedure TextColor(c: byte);
procedure TextBackground(c: byte);
procedure ClrScr;
procedure GotoXY(x, y: longint);
procedure InitVideo;
procedure DoneVideo;
procedure UpdateScreen(force: boolean);
procedure ClearScreen;
procedure SetCursorType(t: word);
procedure GetVideoMode(var m: TVideoMode);
procedure LockScreenUpdate;
procedure UnLockScreenUpdate;
procedure InitKeyboard;
procedure DoneKeyboard;
function GetKeyEvent: TKeyEvent;
function PollKeyEvent: TKeyEvent;
function TranslateKeyEvent(k: TKeyEvent): TKeyEvent;
function IsFunctionKey(k: TKeyEvent): boolean;
function KeyEventToString(k: TKeyEvent): string;
function GetKeyEventCode(k: TKeyEvent): word;
function GetKeyEventChar(k: TKeyEvent): char;

{ ---------------------------------------------------------------- Process }
type
  TProcess = class
    CommandLine: string;
    procedure Execute;
    procedure Terminate(code: longint);
  end;

{ ------------------------------------------------------------ RVIP hooks }
var
  web_at_cmd: boolean = false;   { game waits for a command (web prompt line) }
  web_msgs: longint = 0;         { messages so far (RVIP explore stops on a new one) }
procedure web_flush;
procedure web_message(const s: string);   { MessageLog.ShowTransMessage: history line }
function web_pending: boolean;             { a key/mouse event is waiting }
procedure web_type(const s: string);       { queue keys the game reads before the player's (RVIP item preselect) }
procedure web_untype;                      { drop what web_type queued and nobody read }
procedure web_fill(x, y, w, h: longint; rgb: longword; alpha: longint);  { filled rectangle on the screen }
procedure web_lists(const inv, vis: ansistring);  { Inventory / Visible windows (lines "colour<TAB>text") }
procedure web_prompt(const s: string);     { the live message row: prompt line over the map }
function web_want_save: boolean;           { the page asks for an autosave }
procedure web_sync;                        { files changed: the page mirrors them to IndexedDB }
procedure web_hero(x, y: longint);         { player's screen pixel: the map camera centres on it }

implementation

{$IFDEF CPUWASM32}
procedure be_frame(list: pointer; n: longint); external 'lr' name 'be_frame';
procedure be_image(id: longint; path: pchar); external 'lr' name 'be_image';
procedure be_free(id: longint); external 'lr' name 'be_free';
function be_poll(atcmd: longint): longint; external 'lr' name 'be_poll';
function be_evarg(i: longint): longint; external 'lr' name 'be_evarg';
procedure be_sleep(ms: longint); external 'lr' name 'be_sleep';
procedure be_sfx(path: pchar; vol: longint); external 'lr' name 'be_sfx';
procedure be_music(path: pchar; loops, vol: longint); external 'lr' name 'be_music';
function be_music_playing: longint; external 'lr' name 'be_music_playing';
procedure be_title(s: pchar); external 'lr' name 'be_title';
procedure be_screen(w, h: longint); external 'lr' name 'be_screen';
procedure be_msg(s: pchar; fold: longint); external 'lr' name 'be_msg';
procedure be_lists(inv, vis: pchar); external 'lr' name 'be_lists';
procedure be_prompt(s: pchar); external 'lr' name 'be_prompt';
function be_want_save: longint; external 'lr' name 'be_want_save';
procedure be_sync; external 'lr' name 'be_sync';
procedure be_hero(x, y: longint); external 'lr' name 'be_hero';
procedure be_music_vol(v: longint); external 'lr' name 'be_music_vol';
function be_pending: longint; external 'lr' name 'be_pending';
{$ELSE}
{ headless native backend (web/check.sh): random keys, nothing drawn }
var
  nkeys: longint = 0;
  maxkeys: longint = 20000;
  evargs: array [0..3] of longint;
  blits: int64 = 0;
const
  KEYS: string = 'hjklyubn12346789.<>zzioegdtwqaszxcvfr,;:?' + #13#13#13#27#32#32;
procedure be_frame(list: pointer; n: longint); begin inc(blits, n) end;
procedure be_image(id: longint; path: pchar); begin end;
procedure be_free(id: longint); begin end;
{ LR_KEYS: keys typed first (a game start), then LR_MAX random keys }
var
  prefix: ansistring;
  prefixread: boolean = false;
function be_poll(atcmd: longint): longint;
var r: longint;
begin
  if not prefixread then
  begin
    prefixread := true;
    prefix := GetEnvironmentVariable('LR_KEYS');
    if GetEnvironmentVariable('LR_MAX') <> '' then maxkeys := StrToInt(GetEnvironmentVariable('LR_MAX'));
    if GetEnvironmentVariable('LR_SEED') <> '' then RandSeed := StrToInt(GetEnvironmentVariable('LR_SEED'));
  end;
  be_poll := 1;
  if prefix <> '' then
  begin
    evargs[1] := ord(prefix[1]); evargs[0] := evargs[1];
    delete(prefix, 1, 1);
    exit;
  end;
  inc(nkeys);
  if nkeys > maxkeys then
  begin
    writeln(stderr, 'check: ', maxkeys, ' random keys done, ', blits, ' blits, no range/overflow error');
    halt(0);
  end;
  r := random(40);
  if r = 0 then
  begin
    evargs[0] := SDLK_UP + random(4); evargs[1] := 0;
  end
  else
  begin
    evargs[1] := ord(KEYS[1 + random(length(KEYS))]);
    evargs[0] := evargs[1];
  end;
end;
function be_evarg(i: longint): longint; begin be_evarg := evargs[i] end;
procedure be_sleep(ms: longint); begin end;
procedure be_sfx(path: pchar; vol: longint); begin end;
procedure be_music(path: pchar; loops, vol: longint); begin end;
function be_music_playing: longint; begin be_music_playing := 0 end;
procedure be_title(s: pchar); begin end;
procedure be_screen(w, h: longint); begin end;
procedure be_msg(s: pchar; fold: longint); begin end;
procedure be_lists(inv, vis: pchar); begin end;
procedure be_prompt(s: pchar); begin end;
function be_want_save: longint; begin be_want_save := ord(random(500) = 0) end;
procedure be_sync; begin end;
procedure be_hero(x, y: longint); begin end;
procedure be_music_vol(v: longint); begin end;
function be_pending: longint; begin be_pending := 0 end;
{$ENDIF}

{ one blit: surface ids, source rect (w/h -1 = whole surface), target point, alpha }
type
  TBlit = record src, sx, sy, sw, sh, dst, dx, dy, alpha: longint; end;
const
  MAXBLITS = 16384;
var
  list: array [0..MAXBLITS - 1] of TBlit;
  nlist: longint = 0;
  nextid: longint = 2;
  screensurf: TSDL_Surface;
  mousex, mousey, mousebtn: longint;

procedure web_flush;
begin
  if nlist > 0 then be_frame(@list[0], nlist);
  nlist := 0;
end;

{ a repeat of the last message becomes "message (xN)" replacing the page's
  last line (fold = 1), as BOSS's crt_msg }
var
  prev_msg: ansistring = '';
  reps: longint = 1;
procedure web_message(const s: string);
var z: ansistring;
begin
  inc(web_msgs);
  if (prev_msg <> '') and (s = prev_msg) then
  begin
    inc(reps);
    z := s + ' (x' + IntToStr(reps) + ')';
    be_msg(pchar(z), 1);
  end
  else
  begin
    prev_msg := s; reps := 1;
    z := s;
    be_msg(pchar(z), 0);
  end;
  web_prompt(z);
end;

var lastinv, lastvis: ansistring;
procedure web_lists(const inv, vis: ansistring);
begin
  if (inv = lastinv) and (vis = lastvis) then exit;
  lastinv := inv; lastvis := vis;
  be_lists(pchar(inv), pchar(vis));
end;

var lastprompt: ansistring = '';
procedure web_prompt(const s: string);
var z: ansistring;
begin
  z := s;
  if z = lastprompt then exit;
  lastprompt := z;
  be_prompt(pchar(z));
end;

function web_want_save: boolean;
begin
  web_want_save := be_want_save <> 0;
end;

procedure web_sync;
begin
  be_sync;
end;

var herox: longint = -1; heroy: longint = -1;
procedure web_hero(x, y: longint);
begin
  if (x = herox) and (y = heroy) then exit;
  herox := x; heroy := y;
  be_hero(x, y);
end;

function web_pending: boolean;
begin
  web_pending := be_pending > 0;
end;

function SDL_Init(flags: UInt32): longint; begin SDL_Init := 0 end;
procedure SDL_Quit; begin web_flush end;
function SDL_EnableUNICODE(enable: longint): longint; begin SDL_EnableUNICODE := 1 end;
function SDL_EnableKeyRepeat(delay, interval: longint): longint; begin SDL_EnableKeyRepeat := 0 end;
procedure SDL_WM_SetCaption(title, icon: pchar); begin be_title(title) end;

function SDL_SetVideoMode(w, h, bpp: longint; flags: UInt32): PSDL_Surface;
begin
  screensurf.w := w; screensurf.h := h; screensurf.id := 1;
  screensurf.alpha := 255; screensurf.flags := flags;
  web_flush;
  be_screen(w, h);
  SDL_SetVideoMode := @screensurf;
end;

function SDL_BlitSurface(src: PSDL_Surface; srcrect: PSDL_Rect; dst: PSDL_Surface; dstrect: PSDL_Rect): longint;
var b: ^TBlit;
begin
  SDL_BlitSurface := -1;
  if (src = nil) or (dst = nil) then exit;
  if nlist >= MAXBLITS then web_flush;
  b := @list[nlist];
  b^.src := src^.id;
  b^.dst := dst^.id;
  b^.alpha := src^.alpha;
  if srcrect <> nil then
  begin
    b^.sx := srcrect^.x; b^.sy := srcrect^.y; b^.sw := srcrect^.w; b^.sh := srcrect^.h;
  end
  else
  begin
    b^.sx := 0; b^.sy := 0; b^.sw := -1; b^.sh := -1;
  end;
  if dstrect <> nil then
  begin
    b^.dx := dstrect^.x; b^.dy := dstrect^.y;
  end
  else
  begin
    b^.dx := 0; b^.dy := 0;
  end;
  inc(nlist);
  SDL_BlitSurface := 0;
end;

procedure SDL_UpdateRect(screen: PSDL_Surface; x, y: SInt32; w, h: UInt32);
begin
  web_flush;
end;

procedure SDL_FreeSurface(surface: PSDL_Surface);
begin
  if (surface = nil) or (surface = @screensurf) then exit;
  web_flush;
  be_free(surface^.id);
  dispose(surface);
end;

function SDL_SetAlpha(surface: PSDL_Surface; flag: UInt32; alpha: UInt8): longint;
begin
  SDL_SetAlpha := 0;
  if surface = nil then exit;
  if flag and SDL_SRCALPHA <> 0 then surface^.alpha := alpha
  else surface^.alpha := 255;
end;

var
  typed: ansistring = '';

procedure web_type(const s: string);
begin
  typed := typed + s;
end;

procedure web_untype;
begin
  typed := '';
end;

procedure web_fill(x, y, w, h: longint; rgb: longword; alpha: longint);
var b: ^TBlit;
begin
  if nlist >= MAXBLITS then web_flush;
  b := @list[nlist];
  b^.src := -1; b^.sx := rgb; b^.sy := 0; b^.sw := w; b^.sh := h;
  b^.dst := 1; b^.dx := x; b^.dy := y; b^.alpha := alpha;
  inc(nlist);
end;

{ be_poll: 0 = nothing, 1 = key (args: sym, unicode), 2 = mouse down,
  3 = mouse up, 4 = motion (args: x, y, button). Keys queued by web_type
  come first. }
function SDL_PollEvent(event: PSDL_Event): longint;
var t: longint;
begin
  web_flush;
  if typed <> '' then
  begin
    fillchar(event^, sizeof(TSDL_Event), 0);
    event^.key.type_ := SDL_KEYDOWN;
    event^.key.state := 1;
    event^.key.keysym.sym := ord(typed[1]);
    event^.key.keysym.unicode := ord(typed[1]);
    delete(typed, 1, 1);
    exit(1);
  end;
  t := be_poll(ord(web_at_cmd));
  SDL_PollEvent := 0;
  if t = 0 then exit;
  fillchar(event^, sizeof(TSDL_Event), 0);
  case t of
    1:
    begin
      event^.key.type_ := SDL_KEYDOWN;
      event^.key.state := 1;
      event^.key.keysym.sym := be_evarg(0);
      event^.key.keysym.unicode := be_evarg(1);
    end;
    2, 3, 4:
    begin
      mousex := be_evarg(0); mousey := be_evarg(1);
      if t = 4 then
      begin
        event^.motion.type_ := SDL_MOUSEMOTION;
        event^.motion.x := mousex; event^.motion.y := mousey;
      end
      else
      begin
        if t = 2 then
        begin
          event^.button.type_ := SDL_MOUSEBUTTONDOWN;
          mousebtn := mousebtn or SDL_BUTTON(be_evarg(2));
        end
        else
        begin
          event^.button.type_ := SDL_MOUSEBUTTONUP;
          mousebtn := mousebtn and not SDL_BUTTON(be_evarg(2));
        end;
        event^.button.button := be_evarg(2);
        event^.button.x := mousex; event^.button.y := mousey;
      end;
    end;
  end;
  SDL_PollEvent := 1;
end;

function SDL_GetMouseState(var x: longint; var y: longint): UInt8;
begin
  x := mousex; y := mousey;
  SDL_GetMouseState := mousebtn;
end;

function SDL_BUTTON(b: longint): longint;
begin
  SDL_BUTTON := 1 shl (b - 1);
end;

function IMG_Load(const path: pchar): PSDL_Surface;
var s: PSDL_Surface;
begin
  new(s);
  s^.flags := 0; s^.w := 0; s^.h := 0; s^.alpha := 255;
  s^.id := nextid; inc(nextid);
  be_image(s^.id, path);
  IMG_Load := s;
end;

{ ---- mixer: the page plays the files (rvip-sound.js), off by default }
var
  musicvol: longint = 128;

function Mix_OpenAudio(frequency: longint; format: UInt16; channels, chunksize: longint): longint;
begin Mix_OpenAudio := 0 end;
procedure Mix_CloseAudio; begin end;
function Mix_LoadWAV(path: pchar): PMix_Chunk;
var c: PMix_Chunk;
begin new(c); c^.name := path; Mix_LoadWAV := c end;
function Mix_LoadMUS(path: pchar): PMix_Music;
var m: PMix_Music;
begin new(m); m^.name := path; Mix_LoadMUS := m end;
procedure Mix_FreeChunk(c: PMix_Chunk); begin if c <> nil then dispose(c) end;
procedure Mix_FreeMusic(m: PMix_Music); begin if m <> nil then dispose(m) end;
var chunkvol: longint = 128;
function Mix_PlayChannel(channel: longint; c: PMix_Chunk; loops: longint): longint;
begin
  Mix_PlayChannel := -1;
  if c = nil then exit;
  be_sfx(pchar(c^.name), chunkvol);
  Mix_PlayChannel := 0;
end;
function Mix_HaltChannel(channel: longint): longint; begin Mix_HaltChannel := 0 end;
function Mix_VolumeChunk(c: PMix_Chunk; volume: longint): longint;
begin
  if volume >= 0 then chunkvol := volume;
  Mix_VolumeChunk := chunkvol;
end;
function Mix_PlayMusic(m: PMix_Music; loops: longint): longint;
begin
  Mix_PlayMusic := -1;
  if m = nil then exit;
  be_music(pchar(m^.name), loops, musicvol);
  Mix_PlayMusic := 0;
end;
function Mix_HaltMusic: longint; begin be_music(nil, 0, 0); Mix_HaltMusic := 0 end;
function Mix_PlayingMusic: longint; begin Mix_PlayingMusic := be_music_playing end;
function Mix_VolumeMusic(volume: longint): longint;
begin
  if volume >= 0 then
  begin
    musicvol := volume;
    be_music_vol(volume);
  end;
  Mix_VolumeMusic := musicvol;
end;

{ ---- Crt / Video / Keyboard }
var
  vbuf: TVideoBuf;

procedure delay(ms: word);
begin
  web_flush;
  be_sleep(ms);
end;

function next_key_char: longint;
var ev: TSDL_Event;
begin
  repeat
  until (SDL_PollEvent(@ev) > 0) and (ev.type_ = SDL_KEYDOWN);
  if ev.key.keysym.unicode <> 0 then next_key_char := ev.key.keysym.unicode
  else next_key_char := ev.key.keysym.sym;
end;

function KeyPressed: boolean; begin KeyPressed := false end;
function ReadKey: char; begin ReadKey := chr(next_key_char and 255) end;
procedure TextColor(c: byte); begin end;
procedure TextBackground(c: byte); begin end;
procedure ClrScr; begin end;
procedure GotoXY(x, y: longint); begin end;
procedure InitVideo; begin VideoBuf := @vbuf end;
procedure DoneVideo; begin end;
procedure UpdateScreen(force: boolean); begin end;
procedure ClearScreen; begin end;
procedure SetCursorType(t: word); begin end;
procedure GetVideoMode(var m: TVideoMode); begin m.col := 80; m.row := 25; m.color := true end;
procedure LockScreenUpdate; begin end;
procedure UnLockScreenUpdate; begin end;
procedure InitKeyboard; begin end;
procedure DoneKeyboard; begin end;
function GetKeyEvent: TKeyEvent; begin GetKeyEvent := next_key_char end;
function PollKeyEvent: TKeyEvent; begin PollKeyEvent := 0 end;
function TranslateKeyEvent(k: TKeyEvent): TKeyEvent; begin TranslateKeyEvent := k end;
function IsFunctionKey(k: TKeyEvent): boolean; begin IsFunctionKey := k > 255 end;
function KeyEventToString(k: TKeyEvent): string; begin KeyEventToString := '' end;
function GetKeyEventCode(k: TKeyEvent): word; begin GetKeyEventCode := k end;
function GetKeyEventChar(k: TKeyEvent): char; begin GetKeyEventChar := chr(k and 255) end;

procedure TProcess.Execute; begin end;
procedure TProcess.Terminate(code: longint); begin end;

initialization
  VideoBuf := @vbuf;
end.
