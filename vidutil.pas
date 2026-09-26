unit vidutil;

Interface

uses
  video;

Procedure TextOut(X,Y : Word;Const S : String; Color: Integer);

Implementation


Procedure TextOut(X,Y : Word;Const S : String; Color: Integer);
//{$ifdef Darwin}
//begin
  // no code for MacOS
//end;
//{$else}
Var
  P,I,M : Word;
begin
  P:=((X-1)+(Y-1)*ScreenWidth);
  M:=Length(S);
  If P+M>ScreenWidth*ScreenHeight then
    M:=ScreenWidth*ScreenHeight-P;
  For I:=1 to M do
    VideoBuf^[P+I-1]:=Ord(S[i])+(Color shl 8);
end;
//{$endif}

end.
