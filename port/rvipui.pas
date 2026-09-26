{ RVIP pop-ups for LambdaRogue (web build): a floating menu drawn by the
  game itself (10x20 font of tileset-1.png on a filled box, sized to its
  content) and the inventory cursor with item action menus (RVIP.md 3b/3c).

  Keys in a menu: arrows / keypad 8 2 move, Enter / Space / 5 choose,
  Escape / 0 close, 4 / Left back, 6 / Right open, the entry's own key runs
  it directly; mouse: hover moves, click chooses. }
unit RvipUI;

{$mode objfpc}

interface

type
  TMenuEntry = record
    key: string;     { shown in the key column and accepted as hot key }
    text: string;
  end;

const
  MENU_CLOSE = -1;
  MENU_BACK = -2;

{ returns the chosen index (0-based), MENU_CLOSE or MENU_BACK }
function UIMenu(const title: string; const e: array of TMenuEntry; var cur: longint): longint;
function MonstersInView: longint;

{ inventory (InventoryScreen.ShowInventory, web build) }
function RvipInventoryKey: string;
procedure RvipInventoryPreselect(const ch: string);
function RvipInventoryClose: boolean;

implementation

uses WebBE, SysUtils, Constants, RandomArea, BaseOutput, Player, Items;

const
  COLS = 80; ROWS = 30;
  C_BOX = $101018; C_EDGE = $8a7a50; C_BAR = $4a4a80;

function Inside(x, y: integer): boolean;
begin
  Inside := (x >= 1) and (y >= 1) and (x <= DngMaxWidth) and (y <= DngMaxHeight);
end;

function MonstersInView: longint;
var m, n: longint;
begin
  n := 0;
  for m := 1 to 550 do
    with Monster[m] do
      if (intHP > 0) and Inside(intX, intY) and (intInvis = 0) and
        DngLvl[intX, intY].blLOS and DngLvl[intX, intY].blKnown then
        inc(n);
  MonstersInView := n;
end;

procedure CellFill(x, y, w, h: longint; rgb: longword; alpha: longint);
begin
  web_fill(x * 10 + HiResOffsetX, y * 20 + HiResOffsetY, w * 10, h * 20, rgb, alpha);
end;

procedure Box(x, y, w, h: longint);
var px, py: longint;
begin
  px := x * 10 + HiResOffsetX; py := y * 20 + HiResOffsetY;
  web_fill(px - 2, py - 2, w * 10 + 4, h * 20 + 4, C_EDGE, 255);
  web_fill(px, py, w * 10, h * 20, C_BOX, 245);
end;

{ one event: key (sym, uni) or mouse (kind 2 = click, 4 = move, at cell mx/my) }
procedure ReadEvent(var kind, sym, uni, mx, my: longint);
var ev: TSDL_Event;
begin
  kind := 0;
  repeat
    if SDL_PollEvent(@ev) > 0 then
      case ev.type_ of
        SDL_KEYDOWN:
        begin
          kind := 1; sym := ev.key.keysym.sym; uni := ev.key.keysym.unicode;
        end;
        SDL_MOUSEBUTTONDOWN, SDL_MOUSEMOTION:
        begin
          if ev.type_ = SDL_MOUSEMOTION then kind := 4 else kind := 2;
          mx := (ev.motion.x - HiResOffsetX) div 10;
          my := (ev.motion.y - HiResOffsetY) div 20;
          if ev.type_ = SDL_MOUSEBUTTONDOWN then
          begin
            mx := (ev.button.x - HiResOffsetX) div 10;
            my := (ev.button.y - HiResOffsetY) div 20;
            if ev.button.button <> SDL_BUTTON_LEFT then kind := 3;
          end;
        end;
      end;
  until kind <> 0;
end;

function UIMenu(const title: string; const e: array of TMenuEntry; var cur: longint): longint;
var
  i, w, h, x, y, kw, kind, sym, uni, mx, my, n: longint;
  line: string;
begin
  n := length(e);
  kw := 1;
  for i := 0 to n - 1 do
    if length(e[i].key) > kw then kw := length(e[i].key);
  w := length(title);
  for i := 0 to n - 1 do
    if kw + 2 + length(e[i].text) > w then w := kw + 2 + length(e[i].text);
  w := w + 2; h := n + 1;
  if h > ROWS - 2 then h := ROWS - 2;
  x := (COLS - w) div 2; y := (ROWS - h) div 2;
  if cur < 0 then cur := 0;
  if cur >= n then cur := n - 1;
  repeat
    Box(x, y, w, h);
    GlobalFontColor := FONTCOLOR_YELLOW;
    TransTextXY(x, y, title);
    GlobalFontColor := FONTCOLOR_WHITE;
    for i := 0 to n - 1 do
    begin
      if i = cur then CellFill(x, y + 1 + i, w, 1, C_BAR, 255);
      line := e[i].key;
      while length(line) < kw + 2 do line := line + ' ';
      if i = cur then GlobalFontColor := FONTCOLOR_YELLOW
      else GlobalFontColor := FONTCOLOR_GREEN;
      TransTextXY(x, y + 1 + i, line);
      GlobalFontColor := FONTCOLOR_WHITE;
      TransTextXY(x + kw + 2, y + 1 + i, e[i].text);
    end;
    SDL_UpdateRect(screen, 0, 0, 0, 0);
    ReadEvent(kind, sym, uni, mx, my);
    if kind in [2, 4] then
    begin
      if (mx >= x) and (mx < x + w) and (my >= y + 1) and (my < y + 1 + n) then
      begin
        cur := my - y - 1;
        if kind = 2 then exit(cur);
      end
      else if kind = 2 then exit(MENU_CLOSE);
      continue;
    end;
    if kind = 3 then exit(MENU_CLOSE);
    if (sym = SDLK_UP) or (uni = ord('8')) then
      cur := (cur + n - 1) mod n
    else if (sym = SDLK_DOWN) or (uni = ord('2')) then
      cur := (cur + 1) mod n
    else if (sym = 13) or (sym = SDLK_KP_ENTER) or (uni = 32) or (uni = ord('5')) or
      (sym = SDLK_RIGHT) or (uni = ord('6')) then
      exit(cur)
    else if (sym = SDLK_ESCAPE) or (uni = ord('0')) then
      exit(MENU_CLOSE)
    else if (sym = SDLK_LEFT) or (uni = ord('4')) then
      exit(MENU_BACK)
    else if uni > 32 then
      for i := 0 to n - 1 do
        if ((length(e[i].key) = 1) and (ord(e[i].key[1]) = uni)) or
          ((length(e[i].key) = 3) and (e[i].key[1] = '[') and (ord(e[i].key[2]) = uni)) then
        begin
          cur := i;
          exit(i);
        end;
  until false;
end;

{ ---- inventory cursor: list 0 = inventory slots 1..16, list 1 = equipment }
const
  EQ_LET: array [1..7] of char = ('w', 'a', 'h', 's', 'l', 'r', 'e');
  EQ_X: array [1..7] of integer = (51, 57, 57, 57, 51, 51, 58);
  EQ_Y: array [1..7] of integer = (12, 10, 5, 20, 16, 17, 14);
var
  invlist: longint = 0;
  invcur: longint = 1;
  eqcur: longint = 1;
  acted: boolean = false;

function EqItem(i: longint): longint;
begin
  case i of
    1: EqItem := ThePlayer.intWeapon;
    2: EqItem := ThePlayer.intArmour;
    3: EqItem := ThePlayer.intHat;
    4: EqItem := ThePlayer.intFeet;
    5: EqItem := ThePlayer.intRingLeft;
    6: EqItem := ThePlayer.intRingRight;
  else EqItem := ThePlayer.intExtra;
  end;
end;

function Entry(const k, t: string): TMenuEntry;
begin
  Entry.key := k; Entry.text := t;
end;

{ the item's main action: consume, study, equip, else examine }
function MainAction(t: longint): string;
begin
  with Thing[t] do
    if blEat or blDrink then MainAction := 'c'
    else if blIdentified and ((strTextfile <> '-') or (chLetter = chr(193)) or (chLetter = chr(161))) then MainAction := 's'
    else if blWield or blWear or blHat or blShoes or blExtra or blRing then MainAction := 'e'
    else MainAction := 'i';
end;

function ItemMenu: string;
var
  e: array [0..7] of TMenuEntry;
  act: array [0..7] of string;
  n, c, r, t: longint;
  procedure Add(const a, text: string);
  begin
    e[n] := Entry('[' + a + ']', text); act[n] := a; inc(n);
  end;
begin
  ItemMenu := '';
  n := 0;
  if invlist = 0 then
  begin
    t := Inventory[invcur].intType;
    if t <= 0 then exit;
    with Thing[t] do
    begin
      if blEat then Add('c', 'eat')
      else if blDrink then Add('c', 'drink');
      if blIdentified and ((strTextfile <> '-') or (chLetter = chr(193)) or (chLetter = chr(161))) then
        Add('s', 'study / read');
      if blWield or blWear or blHat or blShoes or blExtra or blRing then Add('e', 'equip');
      if blDrink and (ThePlayer.intWeapon > 0) then Add('g', 'grease weapon with it');
      if DngLvl[ThePlayer.intX, ThePlayer.intY].intBuilding > 0 then Add('d', 'sell to the trader')
      else Add('d', 'drop');
      Add('i', 'examine');
    end;
    c := 0;
    r := UIMenu(Thing[t].strName, slice(e, n), c);
  end
  else
  begin
    t := EqItem(eqcur);
    if t <= 0 then exit;
    Add('r', 'remove');
    Add('D', 'equipment details');
    c := 0;
    r := UIMenu(Thing[t].strName, slice(e, n), c);
  end;
  if r >= 0 then ItemMenu := act[r];
end;

procedure DrawCursor;
begin
  if invlist = 0 then
    CellFill(1, 4 + invcur, 44, 1, C_BAR, 110)
  else
    CellFill(EQ_X[eqcur] - 1, EQ_Y[eqcur], 80 - EQ_X[eqcur], 1, C_BAR, 110);
end;

procedure MoveEq(d: longint);
var i: longint;
begin
  for i := 1 to 7 do
  begin
    eqcur := (eqcur - 1 + d + 7) mod 7 + 1;
    if EqItem(eqcur) > 0 then exit;
  end;
end;

procedure MoveInv(d: longint);
var i: longint;
begin
  for i := 1 to 16 do
  begin
    invcur := (invcur - 1 + d + 16) mod 16 + 1;
    if Inventory[invcur].intType > 0 then exit;
  end;
end;

{ replaces the inventory's GetKeyInput: '' = redraw (cursor moved), else
  the action key as GetKeyInput would return it }
function RvipInventoryKey: string;
var kind, sym, uni, mx, my: longint;
begin
  RvipInventoryKey := '';
  if (Inventory[invcur].intType <= 0) then
    for mx := 1 to 16 do
      if Inventory[mx].intType > 0 then begin invcur := mx; break; end;
  if (invlist = 1) and (EqItem(eqcur) <= 0) then MoveEq(1);
  if (invlist = 1) and (EqItem(eqcur) <= 0) then invlist := 0;
  DrawCursor;
  TransTextXY(1, 27, 'Enter: item menu  +: main action  -: drop  *: examine  Tab: equipment');
  TransTextXY(1, 28, '[i]nfo [c]onsume [s]tudy [d]rop [e]quip [r]emove [g]rease [D]etails [ESC]');
  SDL_UpdateRect(screen, 0, 0, 0, 0);
  ReadEvent(kind, sym, uni, mx, my);
  if kind = 4 then
  begin
    if (mx >= 1) and (mx <= 44) and (my >= 5) and (my <= 20) and (Inventory[my - 4].intType > 0) then
    begin
      invlist := 0; invcur := my - 4;
    end;
    exit;
  end;
  if kind = 2 then
  begin
    if (mx >= 1) and (mx <= 44) and (my >= 5) and (my <= 20) and (Inventory[my - 4].intType > 0) then
    begin
      invlist := 0; invcur := my - 4;
      RvipInventoryKey := ItemMenu;
    end;
    exit;
  end;
  if kind = 3 then exit('ESC');
  if (sym = SDLK_UP) or (uni = ord('8')) then
  begin
    if invlist = 0 then MoveInv(-1) else MoveEq(-1);
  end
  else if (sym = SDLK_DOWN) or (uni = ord('2')) then
  begin
    if invlist = 0 then MoveInv(1) else MoveEq(1);
  end
  else if (sym = SDLK_LEFT) or (sym = SDLK_RIGHT) or (sym = 9) or (uni = ord('4')) or (uni = ord('6')) then
  begin
    invlist := 1 - invlist;
    if invlist = 1 then
    begin
      if EqItem(eqcur) <= 0 then MoveEq(1);
      if EqItem(eqcur) <= 0 then invlist := 0;
    end;
  end
  else if (sym = 13) or (sym = SDLK_KP_ENTER) or (uni = 32) or (uni = ord('5')) then
    RvipInventoryKey := ItemMenu
  else if uni = ord('+') then
  begin
    if invlist = 0 then RvipInventoryKey := MainAction(Inventory[invcur].intType)
    else RvipInventoryKey := 'r';
  end
  else if uni = ord('-') then RvipInventoryKey := 'd'
  else if uni = ord('*') then RvipInventoryKey := 'i'
  else if (sym = SDLK_ESCAPE) or (uni = ord('0')) or (uni = ord('.')) then RvipInventoryKey := 'ESC'
  else if (sym >= SDLK_F1) and (sym <= SDLK_F12) then RvipInventoryKey := 'F' + IntToStr(sym - SDLK_F1 + 1)
  else if (uni > 32) and (uni < 127) and (pos(chr(uni), 'icsdergD') > 0) then
    RvipInventoryKey := chr(uni);
end;

{ answer the action's own item prompt with the cursor item (key queue) }
procedure RvipInventoryPreselect(const ch: string);
begin
  web_untype;
  acted := (ch <> '') and (ch <> 'ESC');
  if (invlist = 0) and (Inventory[invcur].intType > 0) and
    ((ch = 'c') or (ch = 's') or (ch = 'd') or (ch = 'e') or (ch = 'i') or (ch = 'g') or
     ((length(ch) > 1) and (ch[1] = 'F'))) then
    web_type(IntToStr(invcur) + #13);
  if (invlist = 1) and (ch = 'r') and (EqItem(eqcur) > 0) then
    web_type(EQ_LET[eqcur]);
end;

{ after an action: close the list when a monster is in view (RVIP 3c) }
function RvipInventoryClose: boolean;
begin
  web_untype;
  RvipInventoryClose := acted and (MonstersInView > 0);
  acted := false;
end;

end.
