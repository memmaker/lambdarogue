unit sdlbitmapfont;
{******************************************************************}
{                                                                  }
{ The initial developer of the Pascal code is :                    }
{ Dominique Louis <Dominique@SavageSoftware.com.au>                }
{                                                                  }
{                                                                  }
{ Portions created by Dominique Louis are                          }
{ Copyright (C) 2001 Dominique Louis.                              }
{                                                                  }
{                                                                  }
{ Contributor(s)                                                   }
{ --------------                                                   }
{                                                                  }
{                                                                  }
{ Obtained through:                                                }
{ Joint Endeavour of Delphi Innovators ( Project JEDI )            }
{                                                                  }
{ You may retrieve the latest version of this file at the Project  }
{ JEDI home page, located at http://delphi-jedi.org                }
{                                                                  }
{ The contents of this file are used with permission, subject to   }
{ the Mozilla Public License Version 1.1 (the "License"); you may  }
{ not use this file except in compliance with the License. You may }
{ obtain a copy of the License at                                  }
{ http://www.mozilla.org/NPL/NPL-1_1Final.html                     }
{                                                                  }
{ Software distributed under the License is distributed on an      }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   }
{ implied. See the License for the specific language governing     }
{ rights and limitations under the License.                        }
{                                                                  }
{ Description                                                      }
{ -----------                                                      }
{  A Class to Draw Bitmapped Text via either SDL or OpenGL within  }
{  an SDL application. Render as normal SDL by default. To render  }
{  using OpenGL, make sure you conditionally define OPENGL.        }
{                                                                  }
{                                                                  }
{ Example                                                          }
{ -------
var
  bitmapfont : TSDLBitmapFont;
  TransColor : TSDL_Color;
begin
  TransColor.r := 0;
  TransColor.g := 0;
  TransColor.b := 0;
  bitmapfont := TSDLBitmapFont.Create( ScreenSurface, TransColor, 'images/font.bmp' );
  try
    bitmapfont.DrawText( 50, 50, 'Hello World', 0 );
  finally
    bitmapfont.Free;
  end;
end;
{                                                                  }
{                                                                  }
{ Requires                                                         }
{ --------                                                         }
{   SDL runtime libary somewhere in your path                      }
{   The Latest SDL runtime can be found on http://www.libsdl.org   }
{                                                                  }
{                                                                  }
{ Programming Notes                                                }
{ -----------------                                                }
{   Make sure that your texture is 256x256 ( power of 2 ) as we    }
{   are using GL_TEXTURE_2D. If you plan to use a rectangualr      }
{   bitmap font or a size other than 256x256, then you will need   }
{   to change this code to handle your special scenario.           }
{                                                                  }
{                                                                  }
{ Revision History                                                 }
{ ----------------                                                 }
{ September 11 2008 - DL : Initial v1.0 version                    }
{                                                                  }
{                                                                  }
{******************************************************************}

interface

uses
  Classes,
{$IFDEF OPENGL}
  gl,
  glu,
  glext,
{$ENDIF}
  sdl;

type
  TSDLBitmapFont = class( TObject )
  private
    {$IFDEF OPENGL}
    FBase : GLuint; // Base Display List For The Font
    FBitmapID : GLuint;
    {$ELSE}
    FBitmapClipRect : array[ 0..255 ] of TSDL_Rect;
    {$ENDIF}
    FBitmapSurface : PSDL_Surface;

    FFileName : string;
    FScreenSurface : PSDL_Surface;
    FTransparentColour: TSDL_Color;
    FTextSpacing : integer;

    procedure BuildFont;
    procedure SetFileName( const Value : string );
  public
    constructor Create( aScreenSurface : PSDL_Surface; aTransparentColour : TSDL_Color; aFileName : string = '' );
    destructor Destroy; override;
    procedure DrawText( aX, aY : integer; aText : string; aFontSet : Byte );
    procedure LoadFromFile( aFileName : string );
    procedure LoadFromStream( aStream : TStream );
    function TextHeight( aSomeText : string ) : integer;
    function TextWidth( aSomeText : string ) : integer;

{$IFDEF OPENGL}
    property BitmapID : GLuint read FBitmapID write FBitmapID;
{$ENDIF}
    property BitmapSurface : PSDL_Surface read FBitmapSurface write FBitmapSurface;
    property FileName : string read FFileName write SetFileName;
    property ScreenSurface : PSDL_Surface read FScreenSurface write FScreenSurface;
    property TextSpacing : integer read FTextSpacing write FTextSpacing;
    property TransparentColour : TSDL_Color read FTransparentColour write FTransparentColour;
  end;


implementation

uses
  sdlutils,
  logger;

{ TSDLBitmapFont }

procedure TSDLBitmapFont.BuildFont;
var
  loop                   : integer; // Loop variable
  cx                     : {$IFDEF OPENGL}single{$ELSE}integer{$ENDIF}; // Holds Our X Character Coord
  cy                     : {$IFDEF OPENGL}single{$ELSE}integer{$ENDIF}; // Holds Our Y Character Coord
begin
{$IFDEF OPENGL}
  // Creating 256 Display List
  FBase := glGenLists( 256 );

  // Select Our Font Texture
  glBindTexture( GL_TEXTURE_2D, FBitmapID );

  // Loop Through All 256 Lists
  for loop := 0 to 255 do
  begin
    {* NOTE:
     *  BMPs are stored with the top-leftmost pixel being the
     * last byte and the bottom-rightmost pixel being the first
     * byte. So an image that is displayed as
     *    1 0
     *    0 0
     * is represented data-wise like
     *    0 0
     *    0 1
     * And because SDL_LoadBMP loads the raw data without
     * translating to how it is thought of when viewed we need
     * to start at the bottom-right corner of the data and work
     * backwards to get everything properly. So the below code has
     * been modified to reflect this. Examine how this is done and
     * how the original tutorial is done to grasp the differences.
     *
     * As a side note BMPs are also stored as BGR instead of RGB
     * and that is why we load the texture using GL_BGR. It's
     * bass-ackwards I know but whattaya gonna do?
     *}

    // X Position Of Current Character
    cx := 1 - ( loop mod 16 ) / 16.0;
    // Y Position Of Current Character
    cy := 1 - ( loop div 16 ) / 16.0;

    // Start Building A List
    glNewList( FBase + ( 255 - loop ), GL_COMPILE );
    // Use A Quad For Each Character
    glBegin( GL_QUADS );
    // Texture Coord (Bottom Left)
    glTexCoord2f( cx - 0.0625, cy );
    // Vertex Coord (Bottom Left)
    glVertex2i( 0, 0 );

    // Texture Coord (Bottom Right)
    glTexCoord2f( cx, cy );
    // Vertex Coord (Bottom Right)
    glVertex2i( 16, 0 );

    // Texture Coord (Top Right)
    glTexCoord2f( cx, cy - 0.0625 );
    // Vertex Coord (Top Right)
    glVertex2i( 16, 16 );

    // Texture Coord (Top Left)
    glTexCoord2f( cx - 0.0625, cy - 0.0625 );
    // Vertex Coord (Top Left)
    glVertex2i( 0, 16 );
    glEnd;

    // Move To The Left Of The Character
    glTranslated( 10, 0, 0 );
    glEndList;
  end;
{$ELSE}
  // Loop Through All 256 letters
  for loop := 0 to 255 do
  begin
    // X Position Of Current Character
    cx := ( loop mod 16 ) * 16;
    // Y Position Of Current Character
    cy := ( loop div 16 ) * 16;
    FBitmapClipRect[ loop ] := SDLRect( cx, cy, 16, 16 );
  end;
{$ENDIF}
end;

constructor TSDLBitmapFont.Create( aScreenSurface : PSDL_Surface; aTransparentColour : TSDL_Color; aFileName : string );
begin
  FScreenSurface := aScreenSurface;
  FFileName := aFileName;
  FTransparentColour := aTransparentColour;

  //defaults
  FTextSpacing := 16;

  LoadFromFile( FFileName );
end;

destructor TSDLBitmapFont.Destroy;
begin
  {$IFDEF OPENGL}
  // Clean up our font list
  glDeleteLists( FBase, 256 ); // Delete All 256 Display Lists

  // Clean up our textures
  glDeleteTextures( 1, @FBitmapID );
  {$ELSE}
  {$ENDIF}
  SDL_FreeSurface( FBitmapSurface );
  inherited;
end;

procedure TSDLBitmapFont.DrawText( aX, aY : integer; aText : string; aFontSet : Byte );
var
{$IFNDEF OPENGL}
  loop                   : integer;
  letterindex            : integer;
  DrawRect               : TSDL_Rect;
{$ENDIF}
  stringarray            : array of string;
  iPos                   : integer;
  iLineLoop              : integer;
begin
  if ( aFontSet > 1 ) then
    aFontSet := 1;

  // Ok Let check for Carriage returns so we can draw multiple lines.
  iPos := Pos( #13, aText );
  while iPos > 0 do
  begin
    SetLength( stringarray, Length( stringarray ) + 1 );
    stringarray[ Length( stringarray ) - 1 ] := Copy( aText, 0, iPos );
    aText := Copy( aText, iPos + 1, Length ( aText ) - iPos );
    iPos := Pos( #13, aText );
  end;

  SetLength( stringarray, Length( stringarray ) + 1 );
  stringarray[ Length( stringarray ) - 1 ] := Copy( aText, 0, Length ( aText ) );

  for iLineLoop := Low( stringarray ) to High( stringarray ) do
  begin
{$IFDEF OPENGL}
  // Enable Texture Mapping
  glEnable( GL_TEXTURE_2D );

  // Select and bind our texture
  glBindTexture( GL_TEXTURE_2D, FBitmapID );

  // Disable depth testing
  glDisable( GL_DEPTH_TEST );

  // Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );

  // Store The Projection Matrix
  glPushMatrix;

  // Reset The Projection Matrix
  glLoadIdentity;

  // Set Up An Ortho Screen
  glOrtho( 0.0, FScreenSurface.w, FScreenSurface.h, 0, -1.0, 1.0 );

  // Select The Modelview Matrix
  glMatrixMode( GL_MODELVIEW );

  // Store the Modelview Matrix
  glPushMatrix;

  // Reset The Modelview Matrix
  glLoadIdentity;

  // Position The Text (0,0 - Bottom Left)
  glTranslated( aX, aY, 0 );

  // Choose The Font Set (0 or 1)
  glListBase( FBase - 32 + ( 128 * aFontSet ) );

  // Write The Text To The Screen
  glCallLists( Length( stringarray[iLineLoop] ), GL_BYTE, PChar( stringarray[iLineLoop] ) );

  // Select the Modelview Matrix
  glMatrixMode( GL_MODELVIEW );

  // Restore the Old Projection Matrix
  glPopMatrix;

  // Select The Projection Matrix
  glMatrixMode( GL_PROJECTION );

  // Restore The Old Projection Matrix
  glPopMatrix;

  // Re-enable Depth Testing
  glEnable( GL_DEPTH_TEST );

  // Disable Texture Mapping
  glDisable( GL_TEXTURE_2D );
{$ELSE}
  letterindex := -32 + ( 128 * aFontSet );
  DrawRect :=  SDLRect( aX, aY, 16, 16 );
  for loop := 1 to Length( stringarray[iLineLoop] ) do
  begin
    SDL_BlitSurface( FBitmapSurface, @FBitmapClipRect[ letterindex + Ord( stringarray[iLineLoop][ loop ] ) ], FScreenSurface, @DrawRect );
    DrawRect.x :=  DrawRect.x + FTextSpacing;
  end;
{$ENDIF}
    aY := aY + 18;
  end;
end;

procedure TSDLBitmapFont.LoadFromFile( aFileName : string );
var
  e: integer;
  tmpsrf : PSDL_Surface;
begin
  tmpsrf := SDL_LoadBMP( PChar( aFileName ) );
  {$IFDEF ENDIAN_BIG}
  FBitmapSurface := SDL_CreateRGBSurface( SDL_SWSURFACE, tmpsrf.w, tmpsrf.h, 32, $000000FF, $0000FF00, $00FF0000, $FF000000 );
  {$ELSE}
  FBitmapSurface := SDL_CreateRGBSurface( SDL_SWSURFACE, tmpsrf.w, tmpsrf.h, 32, $FF000000, $00FF0000, $0000FF00, $000000FF );
  {$ENDIF}
  SDL_BlitSurface( tmpsrf, nil, FBitmapSurface, nil );

  SDL_FreeSurface( tmpsrf );

  SDL_SetAlpha( FBitmapSurface, SDL_SRCALPHA, SDL_ALPHA_TRANSPARENT );

  {$IFDEF OPENGL}
  // Create Texture
  glGenTextures( 1, @FBitmapID );
  e := glGetError;
  if (e <> 0) then
  begin
    Log.LogWarning( 'Error Calling glGenTextures : ' + gluErrorString(e),'TSDLBitmapFont.LoadFromFile');
  end;

  // Load in texture
  // Typical Texture Generation Using Data From The Bitmap
  glBindTexture( GL_TEXTURE_2D, FBitmapID );
  e := glGetError;
  if (e <> 0) then
  begin
    Log.LogWarning( 'Error Calling glBindTexture : ' + gluErrorString(e)  ,'TSDLBitmapFont.LoadFromFile');
  end;

  if ( FBitmapSurface.format.BitsPerPixel = 32 ) then
  begin
    // Generate The Texture
    glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, FBitmapSurface.w, FBitmapSurface.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, FBitmapSurface.pixels );
  end
  else
  begin
    // Generate The Texture
    glTexImage2D( GL_TEXTURE_2D, 0, 3, FBitmapSurface.w, FBitmapSurface.h, 0, GL_BGR, GL_UNSIGNED_BYTE, FBitmapSurface.pixels );
  end;
  e := glGetError;
  if (e <> 0) then
  begin
    Log.LogWarning( 'Error Calling glTexImage2D : ' + gluErrorString(e)  ,'TSDLBitmapFont.LoadFromFile');
  end;

  // scale linearly when image bigger than texture
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );

  // scale linearly when image smaller than texture
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );

  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
  glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
  {$ELSE}
  // Now Make is transparent so we can blit it properly
  SDL_SetColorKey( FBitmapSurface, SDL_SRCCOLORKEY or SDL_RLEACCEL,  SDL_MapRGB( FBitmapSurface.format, FTransparentColour.r, FTransparentColour.g, FTransparentColour.b ) );
  {$ENDIF}

  BuildFont;
end;

procedure TSDLBitmapFont.LoadFromStream( aStream : TStream );
begin

end;

procedure TSDLBitmapFont.SetFileName( const Value : string );
begin
  if ( FFileName <> Value ) then
  begin
    FFileName := Value;
    LoadFromFile( FFileName );
  end;
end;

function TSDLBitmapFont.TextHeight( aSomeText : string ) : integer;
begin
  result := 16;
end;

function TSDLBitmapFont.TextWidth( aSomeText : string ) : integer;
begin
  result := Length( aSomeText ) * 16;
end;

end.

 
