{* UltraStar Deluxe - Karaoke Game
 *
 * UltraStar Deluxe is the legal property of its developers, whose names
 * are too numerous to list here. Please refer to the COPYRIGHT
 * file distributed with this source distribution.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING. If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * $URL: svn://basisbit@svn.code.sf.net/p/ultrastardx/svn/trunk/src/base/USingScores.pas $
 * $Id: USingScores.pas 2293 2010-04-23 22:39:26Z tobigun $
 *}

unit USingScores;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$I switches.inc}

uses
  dglOpenGL,
  UCommon,
  UThemes,
  UTexture;

//////////////////////////////////////////////////////////////
//                        ATTENTION:                        //
// Enabled flag does not work atm. This should cause popups //
// not to move and scores to stay until re-enabling.        //
// To use e.g. in pause mode                                //
// also invisible flag causes attributes not to change.     //
// This should be fixed after next draw when visible = true,//
// but not tested yet                                       //
//////////////////////////////////////////////////////////////

// some constants containing options that could change by time
const
  MaxPlayers = 6;   // maximum of players that could be added
  MaxPositions = 6; // maximum of score positions that could be added

type
  //-----------
  // TScorePlayer - record containing information about a players score
  //-----------
  TScorePlayer = record
    Position:       byte;     // index of the position where the player should be drawn
    Enabled:        boolean;  // is the score display enabled
    Visible:        boolean;  // is the score display visible
    Score:          word;     // current score of the player
    ScoreDisplayed: word;     // score cur. displayed (for counting up)
    ScoreBG:        TTexture; // texture of the players scores bg
    Color:          TRGB;     // the players color
    RBPos:          real;     // cur. percentille of the rating bar
    RBTarget:       real;     // target position of rating bar
    RBVisible:      boolean;  // is rating bar drawn
  end;
  aScorePlayer = array [0..MaxPlayers-1] of TScorePlayer;

  //-----------
  // TScorePosition - record containing information about a score position, that can be used
  //-----------
  PScorePosition = ^TScorePosition;
  TScorePosition = record
    // the position is used for which playercount
    PlayerCount: byte;
    // 1 - 1 player per screen
    // 2 - 2 players per screen
    // 4 - 3 players per screen
    // 8 - 4 players per screen
    // 16 - 6 players per screen
    // 6 would be 2 and 3 players per screen

    BGX: real;     // x position of the score bg
    BGY: real;     // y position of the score bg
    BGW: real;     // width of the score bg
    BGH: real;     // height of the score bg

    RBX: real;     // x position of the rating bar
    RBY: real;     // y position of the rating bar
    RBW: real;     // width of the rating bar
    RBH: real;     // height of the rating bar

    TextX:     real; // x position of the score text
    TextY:     real; // y position of the score text
    TextFont:  byte; // font family of the score text
    TextStyle: byte; // font style of the score text
    TextSize:  integer;    // size of the score text

    PUW:       real;     // width of the line bonus popup
    PUH:       real;     // height of the line bonus popup
    PUFont:    byte;     // font for the popups
    PUStyle:   byte;     // font style for the popups
    PUSize:    integer;  // font size for the popups
    PUStartX:  real;     // x start position of the line bonus popup
    PUStartY:  real;     // y start position of the line bonus popup
    PUTargetX: real;     // x target position of the line bonus popup
    PUTargetY: real;     // y target position of the line bonus popup
  end;
  aScorePosition = array [0..MaxPositions-1] of TScorePosition;

  //-----------
  // TScorePopUp - record containing information about a line bonus popup
  // list, next item is saved in next attribute
  //-----------
  PScorePopUp = ^TScorePopUp;
  TScorePopUp = record
    Player:     byte;        // index of the popups player
    TimeStamp:  cardinal;    // timestamp of popups spawn
    Rating:     integer;     // 0 to 8, type of rating (cool, bad, etc.)
    ScoreGiven: integer;     // score that has already been given to the player
    ScoreDiff:  integer;     // difference between cur score at spawn and old score
    Next:       PScorePopUp; // next item in list
  end;
  aScorePopUp = array of TScorePopUp;

  //-----------
  // TSingScores - class containing scores positions and drawing scores, rating bar + popups
  //-----------
  TSingScores = class
    private
      aPositions: aScorePosition;
      aPlayers:  aScorePlayer;
      oPositionCount: byte;
      oPlayerCount:   byte;

      // saves the first and last popup of the list
      FirstPopUp: PScorePopUp;
      LastPopUp:  PScorePopUp;

      // only defined during draw, time passed between
      // current and previous call of draw
      TimePassed: Cardinal;

      // draws a popup by pointer
      procedure DrawPopUp(const PopUp: PScorePopUp);

      // raises players score if RaiseScore was called
      // has to be called after DrawPopUp and before
      // DrawScore
      procedure DoRaiseScore(const Index: integer);

      // draws a score by playerindex
      procedure DrawScore(const Index: integer);

      // draws the rating bar by playerindex
      procedure DrawRatingBar(const Index: integer);

      // removes a popup w/o destroying the list
      procedure KillPopUp(const last, cur: PScorePopUp);

      // calculate the amount of points for a player that is
      // still in popups and therfore not displayed
      function GetPopUpPoints(const Index: integer): integer;
    public
      Settings: record // Record containing some Displaying Options
        Phase1Time: real;     // time for phase 1 to complete (in msecs)
                              // the plop up of the popup
        Phase2Time: real;     // time for phase 2 to complete (in msecs)
                              // the moving (mainly upwards) of the popup
        Phase3Time: real;     // time for phase 3 to complete (in msecs)
                              // the fade out and score adding

        PopUpTex:   array [0..8] of TTexture; // textures for every popup rating

        RatingBar_BG_Tex:  TTexture; // rating bar texs
        RatingBar_FG_Tex:  TTexture;
        RatingBar_Bar_Tex: TTexture;

      end;

      Visible:   boolean;  // visibility of all scores
      Enabled:   boolean;  // scores are changed, popups are moved etc.
      RBVisible: boolean;  // visibility of all rating bars

      // properties for reading position and playercount
      property PositionCount: byte         read oPositionCount;
      property PlayerCount:   byte         read oPlayerCount;
      property Players:       aScorePlayer read aPlayers;
      property Positions: aScorePosition read aPositions;

      // constructor just sets some standard settings
      constructor Create;

      // adds a position to array and increases position count
      procedure AddPosition(const pPosition: PScorePosition);

      // adds a player to array and increases player count
      procedure AddPlayer(const ScoreBG: TTexture; const Color: TRGB; const Score: word = 0; const Enabled: boolean = true; const Visible: boolean = true);

      // change a players visibility, enable
      procedure ChangePlayerVisibility(const Index: byte; const pVisible: boolean);
      procedure ChangePlayerEnabled(const Index: byte; const pEnabled: boolean);

      // deletes all player information
      procedure ClearPlayers;

      // deletes positions and playerinformation
      procedure Clear;

      // loads some settings and the positions from theme
      procedure LoadfromTheme;

      // has to be called after positions and players have been added, before first call of draw
      // it gives every player a score position
      procedure Init;

      // raises the score of a specified player to the specified score
      procedure RaiseScore(Player: byte; Score: integer);

      // sets the score of a specified player to the specified score
      procedure SetScore(Player: byte; Score: integer);

      // spawns a new line bonus popup for the player
      procedure SpawnPopUp(const PlayerIndex: byte; const Rating: integer; const Score: integer);

      // removes all popups from mem
      procedure KillAllPopUps;

      // draws scores and line bonus popups
      procedure Draw;
  end;

implementation

uses
  SysUtils,
  Math,
  sdl2,
  TextGL,
  ULog,
  UNote,
  UGraphic;

{**
 * sets some standard settings
 *}
constructor TSingScores.Create;
begin
  inherited;

  // clear popuplist pointers
  FirstPopUp := nil;
  LastPopUp  := nil;

  // clear variables
  Visible   := true;
  Enabled   := true;
  RBVisible := true;
  
  // clear position index
  oPositionCount := 0;
  oPlayerCount   := 0;

  Settings.Phase1Time := 350;  // plop it up     . -> [   ]
  Settings.Phase2Time := 550;  // shift it up        ^[   ]^
  Settings.Phase3Time := 200;  // increase score      [s++]

  Settings.PopUpTex[0].TexNum := 0;
  Settings.PopUpTex[1].TexNum := 0;
  Settings.PopUpTex[2].TexNum := 0;
  Settings.PopUpTex[3].TexNum := 0;
  Settings.PopUpTex[4].TexNum := 0;
  Settings.PopUpTex[5].TexNum := 0;
  Settings.PopUpTex[6].TexNum := 0;
  Settings.PopUpTex[7].TexNum := 0;
  Settings.PopUpTex[8].TexNum := 0;

  Settings.RatingBar_BG_Tex.TexNum   := 0;
  Settings.RatingBar_FG_Tex.TexNum   := 0;
  Settings.RatingBar_Bar_Tex.TexNum  := 0;
end;

{**
 * adds a position to array and increases position count
 *}
procedure TSingScores.AddPosition(const pPosition: PScorePosition);
begin
  if (PositionCount < MaxPositions) then
  begin
    aPositions[PositionCount] := pPosition^;
    Inc(oPositionCount);
  end;
end;

{**
 * adds a player to array and increases player count
 *}
procedure TSingScores.AddPlayer(const ScoreBG: TTexture; const Color: TRGB; const Score: word; const Enabled: boolean; const Visible: boolean);
begin
  if (PlayerCount < MaxPlayers) then
  begin
    aPlayers[PlayerCount].Position  := High(byte);
    aPlayers[PlayerCount].Enabled   := Enabled;
    aPlayers[PlayerCount].Visible   := Visible;
    aPlayers[PlayerCount].Score     := Score;
    aPlayers[PlayerCount].ScoreDisplayed := Score;
    aPlayers[PlayerCount].ScoreBG   := ScoreBG;
    aPlayers[PlayerCount].Color     := Color;
    aPlayers[PlayerCount].RBPos     := 0.5;
    aPlayers[PlayerCount].RBTarget  := 0.5;
    aPlayers[PlayerCount].RBVisible := true;

    Inc(oPlayerCount);
  end;
end;

{**
 * change a players visibility
 *}
procedure TSingScores.ChangePlayerVisibility(const Index: byte; const pVisible: boolean);
begin
  if (Index < MaxPlayers) then
    aPlayers[Index].Visible := pVisible;
end;
{**
 * change player enabled
 *}
procedure TSingScores.ChangePlayerEnabled(const Index: byte; const pEnabled: boolean);
begin
  if (Index < MaxPlayers) then
    aPlayers[Index].Enabled := pEnabled;
end;
{**
 * procedure deletes all player information
 *}
procedure TSingScores.ClearPlayers;
begin
  KillAllPopUps;
  oPlayerCount := 0;
  TimePassed := 0;
end;

{**
 * procedure deletes positions and playerinformation
 *}
procedure TSingScores.Clear;
begin
  KillAllPopUps;
  oPlayerCount    := 0;
  oPositionCount  := 0;
  TimePassed := 0;
end;

{**
 * procedure loads some settings and the positions from theme
 *}
procedure TSingScores.LoadfromTheme;
var
  I: integer;
  procedure AddbyStatics(const PC: byte; const ScoreStatic: TThemePosition; const SingBarStatic: TThemePosition; ScoreText: TThemeText);
  var
    nPosition: TScorePosition;
  begin
    nPosition.PlayerCount := PC; // only for one player playing

    nPosition.BGX := ScoreStatic.X;
    nPosition.BGY := ScoreStatic.Y;
    nPosition.BGW := ScoreStatic.W;
    nPosition.BGH := ScoreStatic.H;

    nPosition.TextX      := ScoreText.X;
    nPosition.TextY      := ScoreText.Y;
    nPosition.TextFont := ScoreText.Font;
    nPosition.TextStyle  := ScoreText.Style;
    nPosition.TextSize   := ScoreText.Size;

    nPosition.RBX := SingBarStatic.X;
    nPosition.RBY := SingBarStatic.Y;
    nPosition.RBW := SingBarStatic.W;
    nPosition.RBH := SingBarStatic.H;

    nPosition.PUW := nPosition.BGW;
    nPosition.PUH := nPosition.BGH;

    nPosition.PUFont := 0;
    nPosition.PUStyle  := ftOutline;
    nPosition.PUSize   := 18;

    nPosition.PUStartX := nPosition.BGX;
    nPosition.PUStartY := nPosition.TextY + 65;

    nPosition.PUTargetX := nPosition.BGX;
    nPosition.PUTargetY := nPosition.TextY;

    AddPosition(@nPosition);
  end;
begin
  Clear;

  // set textures
  // popup tex
  for I := 0 to 8 do
    Settings.PopUpTex[I] := Tex_SingLineBonusBack[I];

  // rating bar tex
  Settings.RatingBar_BG_Tex   :=  Tex_SingBar_Back;
  Settings.RatingBar_FG_Tex   :=  Tex_SingBar_Front;
  Settings.RatingBar_Bar_Tex  :=  Tex_SingBar_Bar;

  // load positions from theme

  // player 1:
  AddByStatics(1, Theme.Sing.Solo1PP1.ScoreBackground, Theme.Sing.Solo1PP1.SingBar, Theme.Sing.Solo1PP1.Score);
  AddByStatics(2, Theme.Sing.Solo2PP1.ScoreBackground, Theme.Sing.Solo2PP1.SingBar, Theme.Sing.Solo2PP1.Score);
  AddByStatics(4, Theme.Sing.Solo3PP1.ScoreBackground, Theme.Sing.Solo3PP1.SingBar, Theme.Sing.Solo3PP1.Score);

  // player 2:
  AddByStatics(2, Theme.Sing.Solo2PP2.ScoreBackground, Theme.Sing.Solo2PP2.SingBar, Theme.Sing.Solo2PP2.Score);
  AddByStatics(4, Theme.Sing.Solo3PP2.ScoreBackground, Theme.Sing.Solo3PP2.SingBar, Theme.Sing.Solo3PP2.Score);

  // player 3:
  AddByStatics(4, Theme.Sing.Solo3PP3.ScoreBackground, Theme.Sing.Solo3PP3.SingBar, Theme.Sing.Solo3PP3.Score);

end;

{**
 * raises the score of a specified player to the specified score
 *}
procedure TSingScores.RaiseScore(Player: byte; Score: integer);
begin
  if (Player <= PlayerCount - 1) then
    aPlayers[Player].Score := Score;
end;

{**
 * sets the score of a specified player to the specified score
 *}
procedure TSingScores.SetScore(Player: byte; Score: integer);
  var
    Diff: Integer;
begin
  if (Player <= PlayerCount - 1) then
  begin
    Diff := Score - Players[Player].Score;
    aPlayers[Player].Score := Score;
    Inc(aPlayers[Player].ScoreDisplayed, Diff);
  end;
end;

{**
 * spawns a new line bonus popup for the player
 *}
procedure TSingScores.SpawnPopUp(const PlayerIndex: byte; const Rating: integer; const Score: integer);
var
  Cur: PScorePopUp;
begin
  if (PlayerIndex < PlayerCount) then
  begin
    // get memory and add data
    GetMem(Cur, SizeOf(TScorePopUp));

    Cur.Player    := PlayerIndex;
    Cur.TimeStamp := SDL_GetTicks;

    // limit rating value to 0..8
    // a higher value would cause a crash when selecting the bg texture
    if (Rating > 8) then
      Cur.Rating := 8
    else if (Rating < 0) then
      Cur.Rating := 0
    else
      Cur.Rating := Rating;

    Cur.ScoreGiven:= 0;
    if (Players[PlayerIndex].Score < Score) then
    begin
      Cur.ScoreDiff := Score - Players[PlayerIndex].Score;
      aPlayers[PlayerIndex].Score := Score;
    end
    else
      Cur.ScoreDiff := 0;
    Cur.Next := nil;

    // Log.LogError('TSingScores.SpawnPopUp| Player: ' + InttoStr(PlayerIndex) + ', Score: ' + InttoStr(Score) + ', ScoreDiff: ' + InttoStr(Cur.ScoreDiff));

    // add it to the chain
    if (FirstPopUp = nil) then
      // the first popup in the list
      FirstPopUp := Cur
    else
    // second or earlier popup
      LastPopUp.Next := Cur;

    // set new popup to last popup in the list
    LastPopUp := Cur;
  end
  else
    Log.LogError('TSingScores: Try to add popup for non-existing player');
end;

{**
 * removes a popup w/o destroying the list
 *}
procedure TSingScores.KillPopUp(const last, cur: PScorePopUp);
begin
  // give player the last points that missing till now
  aPlayers[Cur.Player].ScoreDisplayed := aPlayers[Cur.Player].ScoreDisplayed + Cur.ScoreDiff - Cur.ScoreGiven;

  // change bars position
  if (Cur.ScoreDiff > 0) THEN
  begin // popup w/ scorechange -> give missing percentille
    aPlayers[Cur.Player].RBTarget := aPlayers[Cur.Player].RBTarget +
                                     (Cur.ScoreDiff - Cur.ScoreGiven) / Cur.ScoreDiff
                                     * (Cur.Rating / 20 - 0.26);
  end
  else
  begin // popup w/o scorechange -> give complete percentille
    aPlayers[Cur.Player].RBTarget := aPlayers[Cur.Player].RBTarget +
                                     (Cur.Rating / 20 - 0.26);
  end;

  if (aPlayers[Cur.Player].RBTarget > 1) then
    aPlayers[Cur.Player].RBTarget := 1
  else
  if (aPlayers[Cur.Player].RBTarget < 0) then
    aPlayers[Cur.Player].RBTarget := 0;

  // if this is the first popup => make next popup the first
  if (Cur = FirstPopUp) then
    FirstPopUp := Cur.Next
  // else => remove curent popup from chain
  else
    Last.Next := Cur.Next;

  // if this is the last popup, make popup before the last
  if (Cur = LastPopUp) then
    LastPopUp := Last;

  // free the memory
  FreeMem(Cur, SizeOf(TScorePopUp));
end;

{**
 * removes all popups from mem
 *}
procedure TSingScores.KillAllPopUps;
var
  Cur:  PScorePopUp;
  Last: PScorePopUp;
begin
  Cur := FirstPopUp;

  // remove all popups:
  while (Cur <> nil) do
  begin
    Last := Cur;
    Cur  := Cur.Next;
    FreeMem(Last, SizeOf(TScorePopUp));
  end;

  FirstPopUp := nil;
  LastPopUp := nil;
end;

{**
 * calculate the amount of points for a player that is
 * still in popups and therfore not displayed
 *}
function TSingScores.GetPopUpPoints(const Index: integer): integer;
  var
    CurPopUp: PScorePopUp;
begin
  Result := 0;
  
  CurPopUp := FirstPopUp;
  while (CurPopUp <> nil) do
  begin
    if (CurPopUp.Player = Index) then
    begin // add points left "in" popup to result
      Inc(Result, CurPopUp.ScoreDiff - CurPopUp.ScoreGiven);
    end;
    CurPopUp := CurPopUp.Next;
  end;
end;

{**
 * has to be called after positions and players have been added, before first call of draw
 * it gives each player a score position
 *}
procedure TSingScores.Init;
var
  PlC:                 array [0..1] of byte; // playercount first screen and second screen
  I, J:    integer;
  MaxPlayersperScreen: byte;
  CurPlayer:           byte;

  function GetPositionCountbyPlayerCount(bPlayerCount: byte): byte;
  var
    I: integer;
  begin
    Result := 0;
    bPlayerCount := 1 shl (bPlayerCount - 1);

    for I := 0 to PositionCount - 1 do
    begin
      if ((aPositions[I].PlayerCount and bPlayerCount) <> 0) then
        Inc(Result);
    end;
  end;

  function GetPositionbyPlayernum(bPlayerCount, bPlayer: byte): byte;
  var
    I: integer;
  begin
    bPlayerCount := 1 shl (bPlayerCount - 1);
    Result := High(byte);

    for I := 0 to PositionCount - 1 do
    begin
      if ((aPositions[I].PlayerCount and bPlayerCount) <> 0) then
      begin
        if (bPlayer = 0) then
        begin
          Result := I;
          Break;
        end
        else
          Dec(bPlayer);
      end;
    end;
  end;

begin
  MaxPlayersPerScreen := 0;

  for I := 1 to 6 do
  begin
    // if there are enough positions -> write to maxplayers
    if (Screens = 2) or (PlayersPlay <= 3) then
    begin
      if (GetPositionCountbyPlayerCount(I) = I) then
        MaxPlayersPerScreen := I
      else
        Break;
    end
    else
    begin
      // DIRTY HACK for 4/6 players one screen
      MaxPlayersPerScreen := PlayersPlay;
      //oPlayerCount := PlayersPlay;
    end;
  end;

  // split players to both screens or display on one screen
  if (Screens = 2) and (MaxPlayersPerScreen < PlayerCount) then
  begin
    PlC[0] := PlayerCount div 2 + PlayerCount mod 2;
    PlC[1] := PlayerCount div 2;
  end
  else
  begin
    PlC[0] := PlayerCount;
    PlC[1] := 0;
  end;

  // check if there are enough positions for all players
  for I := 0 to Screens - 1 do
  begin
    if (PlC[I] > MaxPlayersperScreen) then
    begin
      PlC[I] := MaxPlayersperScreen;
      Log.LogError('More Players than available Positions, TSingScores');
    end;
  end;

  CurPlayer := 0;
  // give every player a position
  for I := 0 to Screens - 1 do
    for J := 0 to PlC[I]-1 do
    begin
      // DIRTY HACK for 4/6 players one screen
      if (Screens = 2) or (PlayersPlay <= 3) then
        aPlayers[CurPlayer].Position := GetPositionbyPlayernum(PlC[I], J) or (I shl 7)
      else
        aPlayers[CurPlayer].Position := J;

      //Log.LogError('Player ' + InttoStr(CurPlayer) + ' gets Position: ' + InttoStr(aPlayers[CurPlayer].Position));
      Inc(CurPlayer);
    end;
end;

{**
 * draws scores and linebonus popups
 *}
procedure TSingScores.Draw;
var
  I: integer;
  CurTime: cardinal;
  CurPopUp, LastPopUp: PScorePopUp;
begin
  CurTime := SDL_GetTicks;
  if (TimePassed <> 0) then
    TimePassed := CurTime - TimePassed;

  if Visible then
  begin
    // draw popups
    LastPopUp := nil;
    CurPopUp  := FirstPopUp;

    while (CurPopUp <> nil) do
    begin
      if (CurTime - CurPopUp.TimeStamp > Settings.Phase1Time + Settings.Phase2Time + Settings.Phase3Time) then
      begin
        KillPopUp(LastPopUp, CurPopUp);
        if (LastPopUp = nil) then
          CurPopUp := FirstPopUp
        else
          CurPopUp  := LastPopUp.Next;
      end
      else
      begin
        DrawPopUp(CurPopUp);
        LastPopUp := CurPopUp;
        CurPopUp  := LastPopUp.Next;
      end;
    end;


    if (RBVisible) then
      // draw players w/ rating bar
      for I := 0 to PlayerCount-1 do
      begin
        DoRaiseScore(I);
        DrawScore(I);
        DrawRatingBar(I);
      end
    else
      // draw players w/o rating bar
      for I := 0 to PlayerCount-1 do
      begin
        DoRaiseScore(I);
        DrawScore(I);
      end;

  end; // eo visible

  TimePassed := CurTime;
end;

{**
 * raises players score if RaiseScore was called
 * has to be called after DrawPopUp and before
 * DrawScore
 *}
procedure TSingScores.DoRaiseScore(const Index: integer);
  var
    S: integer;
    Diff: integer;
  const
    RaisePerSecond = 500;
begin
  S := (Players[Index].Score - (Players[Index].ScoreDisplayed + GetPopUpPoints(Index)));

  if (S <> 0) then
  begin
    Diff := Round(RoundTo((RaisePerSecond * TimePassed) / 1000, 1));

    { minimal raise per frame = 1 }
    if Abs(Diff) < 1 then
      Diff := Sign(S);

    if (Abs(Diff) < Abs(S)) then
      Inc(aPlayers[Index].ScoreDisplayed, Diff)
    else
      Inc(aPlayers[Index].ScoreDisplayed, S);
  end;
end;

{**
 * draws a popup by pointer
 *}
procedure TSingScores.DrawPopUp(const PopUp: PScorePopUp);
var
  Progress:          real;
  CurTime:           cardinal;
  X, Y, W, H, Alpha: real;
  FontSize:          integer;
  FontOffset:        real;
  TimeDiff:          cardinal;
  PIndex:            byte;
  TextLen:           real;
  ScoretoAdd:        word;
  PosDiff:           real;
  procedure aPositionsInternal(index: integer; themeElements: TThemeSingPlayer);
  var
    yOffset: integer;
    puSize: integer;
  begin
    if (CurrentSong.isDuet) then begin
      yOffset := 40;
      puSize := 14;
    end else begin
      yOffset := 65;
      puSize := 18;
    end;
    aPositions[PIndex].PUSize := puSize;

    aPositions[PIndex].PUW := themeElements.ScoreBackground.W;
    aPositions[PIndex].PUH := themeElements.ScoreBackground.H;

    aPositions[PIndex].PUStartX := themeElements.ScoreBackground.X;
    aPositions[PIndex].PUStartY := themeElements.Score.Y + yOffset;

    aPositions[PIndex].PUTargetX := themeElements.ScoreBackground.X;
    aPositions[PIndex].PUTargetY := themeElements.Score.Y;

  end;
begin
{ if screens = 2 and playerplay <= 3 the 2nd screen shows the
   textures of screen 1 }
  if (Screens = 2) and (PlayersPlay <= 3) then
    ScreenAct := 1;

  if (PopUp <> nil) then
  begin
    // only draw if player has a position
    PIndex := Players[PopUp.Player].Position;
    if PIndex <> High(byte) then
    begin
      // only draw if player is on cur screen
      if ((Players[PopUp.Player].Position and 128) = 0) = (ScreenAct = 1) then
      begin
        CurTime := SDL_GetTicks;
        if not (Enabled and Players[PopUp.Player].Enabled) then
        // increase timestamp with tiem where there is no movement ...
        begin
          // Inc(PopUp.TimeStamp, LastRender);
        end;
        TimeDiff := CurTime - PopUp.TimeStamp;

        // get position of popup
        PIndex := PIndex and 127;

        // DIRTY HACK
        // correct position for duet with 3/6 players and 4/6 players in one screen
        if (Screens = 1) and ((PlayersPlay = 4) or (PlayersPlay = 6)) then
        begin
          if (PlayersPlay = 4) then
          begin
            if (CurrentSong.isDuet) then
            begin
              case (PopUp.Player) of
                  0: aPositionsInternal(PIndex, Theme.Sing.Duet4PP1);
                  1: aPositionsInternal(PIndex, Theme.Sing.Duet4PP2);
                  2: aPositionsInternal(PIndex, Theme.Sing.Duet4PP3);
                  3: aPositionsInternal(PIndex, Theme.Sing.Duet4PP4);
                end;
            end
            else
            begin
              case (PopUp.Player) of
                  0: aPositionsInternal(PIndex, Theme.Sing.Solo4PP1);
                  1: aPositionsInternal(PIndex, Theme.Sing.Solo4PP2);
                  2: aPositionsInternal(PIndex, Theme.Sing.Solo4PP3);
                  3: aPositionsInternal(PIndex, Theme.Sing.Solo4PP4);
                end;
            end;
          end;

          if (PlayersPlay = 6) then
          begin
            if (CurrentSong.isDuet) then
            begin
              case (PopUp.Player) of
                  0: aPositionsInternal(PIndex, Theme.Sing.Duet6PP1);
                  1: aPositionsInternal(PIndex, Theme.Sing.Duet6PP2);
                  2: aPositionsInternal(PIndex, Theme.Sing.Duet6PP3);
                  3: aPositionsInternal(PIndex, Theme.Sing.Duet6PP4);
                  4: aPositionsInternal(PIndex, Theme.Sing.Duet6PP5);
                  5: aPositionsInternal(PIndex, Theme.Sing.Duet6PP6);
                end;
            end
            else
            begin
              case (PopUp.Player) of
                  0: aPositionsInternal(0, Theme.Sing.Solo6PP1);
                  1: aPositionsInternal(1, Theme.Sing.Solo6PP2);
                  2: aPositionsInternal(2, Theme.Sing.Solo6PP3);
                  3: aPositionsInternal(3, Theme.Sing.Solo6PP4);
                  4: aPositionsInternal(4, Theme.Sing.Solo6PP5);
                  5: aPositionsInternal(5, Theme.Sing.Solo6PP6);
                end;
            end;
          end;
        end
        else
        begin

          if (CurrentSong.isDuet) then
          begin
            if ((PlayersPlay = 3) or (PlayersPlay = 6)) then
            begin
              case (PopUp.Player) of
                0, 3, 6: aPositionsInternal(PIndex, Theme.Sing.Duet3PP1);
                1, 4, 7: aPositionsInternal(PIndex, Theme.Sing.Duet3PP2);
                2, 5, 8: aPositionsInternal(PIndex, Theme.Sing.Duet3PP3);
              end;
            end;
          end
          else
          begin
          if ((PlayersPlay = 3) or (PlayersPlay = 6)) then
            begin
              case (PopUp.Player) of
                0, 3, 6: aPositionsInternal(PIndex, Theme.Sing.Solo3PP1);
                1, 4, 7: aPositionsInternal(PIndex, Theme.Sing.Solo3PP2);
                2, 5, 8: aPositionsInternal(PIndex, Theme.Sing.Solo3PP3);
              end;
            end;
          end;
        end;

        // check for phase ...
        if (TimeDiff <= Settings.Phase1Time) then
        begin
          // phase 1 - the ploping up
          Progress := TimeDiff / Settings.Phase1Time;


          W := aPositions[PIndex].PUW * Sin(Progress/2*Pi);
          H := aPositions[PIndex].PUH * Sin(Progress/2*Pi);

          X := aPositions[PIndex].PUStartX + (aPositions[PIndex].PUW - W)/2;
          Y := aPositions[PIndex].PUStartY + (aPositions[PIndex].PUH - H)/2;

          FontSize   := Round(Progress * aPositions[PIndex].PUSize);
          FontOffset := (H - FontSize) / 2;
          Alpha := 1;
        end

        else if (TimeDiff <= Settings.Phase2Time + Settings.Phase1Time) then
        begin
          // phase 2 - the moving
          Progress := (TimeDiff - Settings.Phase1Time) / Settings.Phase2Time;

          W := aPositions[PIndex].PUW;
          H := aPositions[PIndex].PUH;

          PosDiff := aPositions[PIndex].PUTargetX - aPositions[PIndex].PUStartX;
          if PosDiff > 0 then
            PosDiff := PosDiff + W;
          X := aPositions[PIndex].PUStartX + PosDiff * sqr(Progress);

          PosDiff := aPositions[PIndex].PUTargetY - aPositions[PIndex].PUStartY;
          if PosDiff < 0 then
            PosDiff := PosDiff + aPositions[PIndex].BGH;
          Y := aPositions[PIndex].PUStartY + PosDiff * sqr(Progress);

          FontSize   := aPositions[PIndex].PUSize;
          FontOffset := (H - FontSize) / 2;
          Alpha := 1 - 0.3 * Progress;
        end

        else
        begin
          // phase 3 - the fading out + score adding
          Progress := (TimeDiff - Settings.Phase1Time - Settings.Phase2Time) / Settings.Phase3Time;

          if (PopUp.Rating > 0) then
          begin
            // add scores if player enabled
            if (Enabled and Players[PopUp.Player].Enabled) then
            begin
              ScoreToAdd := Round(PopUp.ScoreDiff * Progress) - PopUp.ScoreGiven;
              Inc(PopUp.ScoreGiven, ScoreToAdd);
              aPlayers[PopUp.Player].ScoreDisplayed := Players[PopUp.Player].ScoreDisplayed + ScoreToAdd;

              // change bar positions
	      if PopUp.ScoreDiff = 0 then
		Log.LogError('TSingScores.DrawPopUp', 'PopUp.ScoreDiff is 0 and we want to divide by it. No idea how this happens.')
	      else
                aPlayers[PopUp.Player].RBTarget := aPlayers[PopUp.Player].RBTarget + ScoreToAdd/PopUp.ScoreDiff * (PopUp.Rating / 20 - 0.26);
              if (aPlayers[PopUp.Player].RBTarget > 1) then
                aPlayers[PopUp.Player].RBTarget := 1
              else if (aPlayers[PopUp.Player].RBTarget < 0) then
                aPlayers[PopUp.Player].RBTarget := 0;
            end;

            // set positions etc.
            Alpha := 0.7 - 0.7 * Progress;

            W := aPositions[PIndex].PUW;
            H := aPositions[PIndex].PUH;

            PosDiff := aPositions[PIndex].PUTargetX - aPositions[PIndex].PUStartX;
            if (PosDiff > 0) then
              PosDiff := W
            else
              PosDiff := 0;
            X := aPositions[PIndex].PUTargetX + PosDiff * Progress;

            PosDiff := aPositions[PIndex].PUTargetY - aPositions[PIndex].PUStartY;
            if (PosDiff < 0) then
              PosDiff := -aPositions[PIndex].BGH
            else
              PosDiff := 0;
            Y := aPositions[PIndex].PUTargetY - PosDiff * (1 - Progress);

            FontSize   := aPositions[PIndex].PUSize;
            FontOffset := (H - FontSize) / 2;
          end
          else
          begin
            // here the effect that should be shown if a popup without score is drawn
            // and or spawn with the graphicobjects etc.
            // some work for blindy to do :p

            // atm: just let it slide in the scores just like the normal popup
            Alpha := 0;
          end;
        end;

        // draw popup

        if (Alpha > 0) and (Players[PopUp.Player].Visible) then
        begin
          // draw bg:
          glEnable(GL_TEXTURE_2D);
          glEnable(GL_BLEND);
          glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

          glColor4f(1,1,1, Alpha);
          glBindTexture(GL_TEXTURE_2D, Settings.PopUpTex[PopUp.Rating].TexNum);

          glBegin(GL_QUADS);
            glTexCoord2f(0, 0); glVertex2f(X, Y);
            glTexCoord2f(0, Settings.PopUpTex[PopUp.Rating].TexH); glVertex2f(X, Y + H);
            glTexCoord2f(Settings.PopUpTex[PopUp.Rating].TexW, Settings.PopUpTex[PopUp.Rating].TexH); glVertex2f(X + W, Y + H);
            glTexCoord2f(Settings.PopUpTex[PopUp.Rating].TexW, 0); glVertex2f(X + W, Y);
          glEnd;

          glDisable(GL_TEXTURE_2D);
          glDisable(GL_BLEND);

          // set font style and size
          SetFontFamily(aPositions[PIndex].PUFont);
          SetFontStyle(aPositions[PIndex].PUStyle);
          SetFontItalic(false);
          SetFontSize(FontSize);
          SetFontReflection(false, 0);

          // draw text
          TextLen := glTextWidth(Theme.Sing.LineBonusText[PopUp.Rating]);

          // color and pos
          SetFontPos (X + (W - TextLen) / 2, Y + FontOffset);
          glColor4f(1, 1, 1, Alpha);

          // draw
          glPrint(Theme.Sing.LineBonusText[PopUp.Rating]);
        end; // eo alpha check
      end; // eo right screen
    end; // eo player has position
  end
  else
    Log.LogError('TSingScores: Try to draw a non-existing popup');
end;

{**
 * draws a score by playerindex
 *}
procedure TSingScores.DrawScore(const Index: integer);
var
  Position: TScorePosition;
  ScoreStr: String;
  Drawing: boolean;
begin
  Drawing := false;

  { if screens = 2 and playerplay <= 3 the 2nd screen shows the
   textures of screen 1 }
  if (Screens = 2) and (PlayersPlay <= 3) then
    ScreenAct := 1;

  // DIRTY HACK
  // correct position for duet with 3/6 players and 4/6 players one screen
  if (Screens = 1) and ((PlayersPlay = 4) or (PlayersPlay = 6)) then
  begin

    Position := aPositions[Players[Index].Position and 127];
    Drawing := true;

    if (PlayersPlay = 4) then
    begin
      if (CurrentSong.isDuet) then
      begin
        case Index of
          0: begin
               Position.BGX := Theme.Sing.Duet4PP1.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet4PP1.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet4PP1.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet4PP1.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet4PP1.Score.X;
               Position.TextY     := Theme.Sing.Duet4PP1.Score.Y;
               Position.TextFont  := Theme.Sing.Duet4PP1.Score.Font;
               Position.TextStyle := Theme.Sing.Duet4PP1.Score.Style;
               Position.TextSize  := Theme.Sing.Duet4PP1.Score.Size;
             end;
          1: begin
               Position.BGX := Theme.Sing.Duet4PP2.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet4PP2.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet4PP2.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet4PP2.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet4PP2.Score.X;
               Position.TextY     := Theme.Sing.Duet4PP2.Score.Y;
               Position.TextFont  := Theme.Sing.Duet4PP2.Score.Font;
               Position.TextStyle := Theme.Sing.Duet4PP2.Score.Style;
               Position.TextSize  := Theme.Sing.Duet4PP2.Score.Size;
             end;
          2: begin
               Position.BGX := Theme.Sing.Duet4PP3.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet4PP3.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet4PP3.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet4PP3.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet4PP3.Score.X;
               Position.TextY     := Theme.Sing.Duet4PP3.Score.Y;
               Position.TextFont  := Theme.Sing.Duet4PP3.Score.Font;
               Position.TextStyle := Theme.Sing.Duet4PP3.Score.Style;
               Position.TextSize  := Theme.Sing.Duet4PP3.Score.Size;
             end;
          3: begin
               Position.BGX := Theme.Sing.Duet4PP4.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet4PP4.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet4PP4.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet4PP4.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet4PP4.Score.X;
               Position.TextY     := Theme.Sing.Duet4PP4.Score.Y;
               Position.TextFont  := Theme.Sing.Duet4PP4.Score.Font;
               Position.TextStyle := Theme.Sing.Duet4PP4.Score.Style;
               Position.TextSize  := Theme.Sing.Duet4PP4.Score.Size;
             end;
        end;
      end
      else
      begin
        case Index of
          0: begin
               Position.BGX := Theme.Sing.Solo4PP1.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo4PP1.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo4PP1.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo4PP1.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo4PP1.Score.X;
               Position.TextY     := Theme.Sing.Solo4PP1.Score.Y;
               Position.TextFont  := Theme.Sing.Solo4PP1.Score.Font;
               Position.TextStyle := Theme.Sing.Solo4PP1.Score.Style;
               Position.TextSize  := Theme.Sing.Solo4PP1.Score.Size;
             end;
          1: begin
               Position.BGX := Theme.Sing.Solo4PP2.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo4PP2.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo4PP2.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo4PP2.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo4PP2.Score.X;
               Position.TextY     := Theme.Sing.Solo4PP2.Score.Y;
               Position.TextFont  := Theme.Sing.Solo4PP2.Score.Font;
               Position.TextStyle := Theme.Sing.Solo4PP2.Score.Style;
               Position.TextSize  := Theme.Sing.Solo4PP2.Score.Size;
             end;
          2: begin
               Position.BGX := Theme.Sing.Solo4PP3.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo4PP3.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo4PP3.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo4PP3.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo4PP3.Score.X;
               Position.TextY     := Theme.Sing.Solo4PP3.Score.Y;
               Position.TextFont  := Theme.Sing.Solo4PP3.Score.Font;
               Position.TextStyle := Theme.Sing.Solo4PP3.Score.Style;
               Position.TextSize  := Theme.Sing.Solo4PP3.Score.Size;
             end;
          3: begin
               Position.BGX := Theme.Sing.Solo4PP4.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo4PP4.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo4PP4.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo4PP4.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo4PP4.Score.X;
               Position.TextY     := Theme.Sing.Solo4PP4.Score.Y;
               Position.TextFont  := Theme.Sing.Solo4PP4.Score.Font;
               Position.TextStyle := Theme.Sing.Solo4PP4.Score.Style;
               Position.TextSize  := Theme.Sing.Solo4PP4.Score.Size;
             end;
        end;
      end;
    end
    else
    begin
      // 6 players
      if (CurrentSong.isDuet) then
      begin
        case Index of
          0: begin
               Position.BGX := Theme.Sing.Duet6PP1.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet6PP1.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet6PP1.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet6PP1.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet6PP1.Score.X;
               Position.TextY     := Theme.Sing.Duet6PP1.Score.Y;
               Position.TextFont  := Theme.Sing.Duet6PP1.Score.Font;
               Position.TextStyle := Theme.Sing.Duet6PP1.Score.Style;
               Position.TextSize  := Theme.Sing.Duet6PP1.Score.Size;
             end;
          1: begin
               Position.BGX := Theme.Sing.Duet6PP2.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet6PP2.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet6PP2.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet6PP2.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet6PP2.Score.X;
               Position.TextY     := Theme.Sing.Duet6PP2.Score.Y;
               Position.TextFont  := Theme.Sing.Duet6PP2.Score.Font;
               Position.TextStyle := Theme.Sing.Duet6PP2.Score.Style;
               Position.TextSize  := Theme.Sing.Duet6PP2.Score.Size;
             end;
          2: begin
               Position.BGX := Theme.Sing.Duet6PP3.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet6PP3.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet6PP3.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet6PP3.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet6PP3.Score.X;
               Position.TextY     := Theme.Sing.Duet6PP3.Score.Y;
               Position.TextFont  := Theme.Sing.Duet6PP3.Score.Font;
               Position.TextStyle := Theme.Sing.Duet6PP3.Score.Style;
               Position.TextSize  := Theme.Sing.Duet6PP3.Score.Size;
             end;
          3: begin
               Position.BGX := Theme.Sing.Duet6PP4.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet6PP4.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet6PP4.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet6PP4.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet6PP4.Score.X;
               Position.TextY     := Theme.Sing.Duet6PP4.Score.Y;
               Position.TextFont  := Theme.Sing.Duet6PP4.Score.Font;
               Position.TextStyle := Theme.Sing.Duet6PP4.Score.Style;
               Position.TextSize  := Theme.Sing.Duet6PP4.Score.Size;
             end;
          4: begin
               Position.BGX := Theme.Sing.Duet6PP5.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet6PP5.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet6PP5.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet6PP5.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet6PP5.Score.X;
               Position.TextY     := Theme.Sing.Duet6PP5.Score.Y;
               Position.TextFont  := Theme.Sing.Duet6PP5.Score.Font;
               Position.TextStyle := Theme.Sing.Duet6PP5.Score.Style;
               Position.TextSize  := Theme.Sing.Duet6PP5.Score.Size;
             end;
          5: begin
               Position.BGX := Theme.Sing.Duet6PP6.ScoreBackground.X;
               Position.BGY := Theme.Sing.Duet6PP6.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Duet6PP6.ScoreBackground.W;
               Position.BGH := Theme.Sing.Duet6PP6.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Duet6PP6.Score.X;
               Position.TextY     := Theme.Sing.Duet6PP6.Score.Y;
               Position.TextFont  := Theme.Sing.Duet6PP6.Score.Font;
               Position.TextStyle := Theme.Sing.Duet6PP6.Score.Style;
               Position.TextSize  := Theme.Sing.Duet6PP6.Score.Size;
             end;
        end;
      end
      else
      begin
        case Index of
          0: begin
               Position.BGX := Theme.Sing.Solo6PP1.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo6PP1.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo6PP1.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo6PP1.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo6PP1.Score.X;
               Position.TextY     := Theme.Sing.Solo6PP1.Score.Y;
               Position.TextFont  := Theme.Sing.Solo6PP1.Score.Font;
               Position.TextStyle := Theme.Sing.Solo6PP1.Score.Style;
               Position.TextSize  := Theme.Sing.Solo6PP1.Score.Size;
             end;
          1: begin
               Position.BGX := Theme.Sing.Solo6PP2.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo6PP2.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo6PP2.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo6PP2.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo6PP2.Score.X;
               Position.TextY     := Theme.Sing.Solo6PP2.Score.Y;
               Position.TextFont  := Theme.Sing.Solo6PP2.Score.Font;
               Position.TextStyle  := Theme.Sing.Solo6PP2.Score.Style;
               Position.TextSize  := Theme.Sing.Solo6PP2.Score.Size;
             end;
          2: begin
               Position.BGX := Theme.Sing.Solo6PP3.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo6PP3.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo6PP3.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo6PP3.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo6PP3.Score.X;
               Position.TextY     := Theme.Sing.Solo6PP3.Score.Y;
               Position.TextFont  := Theme.Sing.Solo6PP3.Score.Font;
               Position.TextStyle := Theme.Sing.Solo6PP3.Score.Style;
               Position.TextSize  := Theme.Sing.Solo6PP3.Score.Size;
             end;
          3: begin
               Position.BGX := Theme.Sing.Solo6PP4.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo6PP4.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo6PP4.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo6PP4.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo6PP4.Score.X;
               Position.TextY     := Theme.Sing.Solo6PP4.Score.Y;
               Position.TextFont  := Theme.Sing.Solo6PP4.Score.Font;
               Position.TextStyle := Theme.Sing.Solo6PP4.Score.Style;
               Position.TextSize  := Theme.Sing.Solo6PP4.Score.Size;
             end;
          4: begin
               Position.BGX := Theme.Sing.Solo6PP5.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo6PP5.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo6PP5.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo6PP5.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo6PP5.Score.X;
               Position.TextY     := Theme.Sing.Solo6PP5.Score.Y;
               Position.TextFont  := Theme.Sing.Solo6PP5.Score.Font;
               Position.TextStyle := Theme.Sing.Solo6PP5.Score.Style;
               Position.TextSize  := Theme.Sing.Solo6PP5.Score.Size;
             end;
          5: begin
               Position.BGX := Theme.Sing.Solo6PP6.ScoreBackground.X;
               Position.BGY := Theme.Sing.Solo6PP6.ScoreBackground.Y;
               Position.BGW := Theme.Sing.Solo6PP6.ScoreBackground.W;
               Position.BGH := Theme.Sing.Solo6PP6.ScoreBackground.H;

               Position.TextX     := Theme.Sing.Solo6PP6.Score.X;
               Position.TextY     := Theme.Sing.Solo6PP6.Score.Y;
               Position.TextFont  := Theme.Sing.Solo6PP6.Score.Font;
               Position.TextStyle := Theme.Sing.Solo6PP6.Score.Style;
               Position.TextSize  := Theme.Sing.Solo6PP6.Score.Size;
             end;
        end;
      end;
    end;
  end
  else
  begin

    // only draw if player has a position
    if Players[Index].Position <> High(byte) then
    begin
      // only draw if player is on cur screen
      if (((Players[Index].Position and 128) = 0) = (ScreenAct = 1)) and Players[Index].Visible then
      begin
        Position := aPositions[Players[Index].Position and 127];

        Drawing := true;

        if (CurrentSong.isDuet) and ((PlayersPlay = 3) or (PlayersPlay = 6)) then
        begin
          case Index of
            0, 3, 6: begin
                 Position.BGX := Theme.Sing.Duet3PP1.ScoreBackground.X;
                 Position.BGY := Theme.Sing.Duet3PP1.ScoreBackground.Y;
                 Position.BGW := Theme.Sing.Duet3PP1.ScoreBackground.W;
                 Position.BGH := Theme.Sing.Duet3PP1.ScoreBackground.H;

                 Position.TextX := Theme.Sing.Duet3PP1.Score.X;
                 Position.TextY := Theme.Sing.Duet3PP1.Score.Y;
                 Position.TextFont := Theme.Sing.Duet3PP1.Score.Font;
                 Position.TextSize := Theme.Sing.Duet3PP1.Score.Size;
               end;
            1, 4, 7: begin
                 Position.BGX := Theme.Sing.Duet3PP2.ScoreBackground.X;
                 Position.BGY := Theme.Sing.Duet3PP2.ScoreBackground.Y;
                 Position.BGW := Theme.Sing.Duet3PP2.ScoreBackground.W;
                 Position.BGH := Theme.Sing.Duet3PP2.ScoreBackground.H;

                 Position.TextX := Theme.Sing.Duet3PP2.Score.X;
                 Position.TextY := Theme.Sing.Duet3PP2.Score.Y;
                 Position.TextFont := Theme.Sing.Duet3PP2.Score.Font;
                 Position.TextSize := Theme.Sing.Duet3PP2.Score.Size;
               end;
            2, 5, 8: begin
                 Position.BGX := Theme.Sing.Duet3PP3.ScoreBackground.X;
                 Position.BGY := Theme.Sing.Duet3PP3.ScoreBackground.Y;
                 Position.BGW := Theme.Sing.Duet3PP3.ScoreBackground.W;
                 Position.BGH := Theme.Sing.Duet3PP3.ScoreBackground.H;

                 Position.TextX := Theme.Sing.Duet3PP3.Score.X;
                 Position.TextY := Theme.Sing.Duet3PP3.Score.Y;
                 Position.TextFont := Theme.Sing.Duet3PP3.Score.Font;
                 Position.TextSize := Theme.Sing.Duet3PP3.Score.Size;
               end;
          end;
      end;
  end;
  end;
  end;

  if (Drawing) then
  begin
    // draw scorebg
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glColor4f(1,1,1, 1);
    glBindTexture(GL_TEXTURE_2D, Players[Index].ScoreBG.TexNum);

    glBegin(GL_QUADS);
      glTexCoord2f(0, 0); glVertex2f(Position.BGX, Position.BGY);
      glTexCoord2f(0, Players[Index].ScoreBG.TexH); glVertex2f(Position.BGX, Position.BGY + Position.BGH);
      glTexCoord2f(Players[Index].ScoreBG.TexW, Players[Index].ScoreBG.TexH); glVertex2f(Position.BGX + Position.BGW, Position.BGY + Position.BGH);
      glTexCoord2f(Players[Index].ScoreBG.TexW, 0); glVertex2f(Position.BGX + Position.BGW, Position.BGY);
    glEnd;

    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);

    // draw score text
    SetFontFamily(Position.TextFont);
    SetFontStyle(Position.TextStyle);
    SetFontItalic(false);
    SetFontSize(Position.TextSize);
    SetFontPos(Position.TextX, Position.TextY);
    SetFontReflection(false, 0);

    ScoreStr := InttoStr(Players[Index].ScoreDisplayed div 10) + '0';
    while (Length(ScoreStr) < 5) do
      ScoreStr := '0' + ScoreStr;

    glPrint(ScoreStr);
  end; // eo player has position
end;


procedure TSingScores.DrawRatingBar(const Index: integer);
var
  Position:   TScorePosition;
  R, G, B:    real;
  Size, Diff: real;
  Drawing: boolean;
begin
  { if screens = 2 and playerplay <= 3 the 2nd screen shows the
   textures of screen 1 }
  if (Screens = 2) and (PlayersPlay <= 3) then
    ScreenAct := 1;

  Drawing := false;

  // DIRTY HACK
  // correct position for duet with 3/6 players and 4/6 players in one screen
  if (Screens = 1) and ((PlayersPlay = 4) or (PlayersPlay = 6)) then
  begin
    Drawing := true;

    if (PlayersPlay = 4) then
    begin

      if (CurrentSong.isDuet) then
      begin
        case Index of
          0:
             begin
               Position.RBX := Theme.Sing.Duet4PP1.SingBar.X;
               Position.RBY := Theme.Sing.Duet4PP1.SingBar.Y;
               Position.RBW := Theme.Sing.Duet4PP1.SingBar.W;
               Position.RBH := Theme.Sing.Duet4PP1.SingBar.H;
             end;
          1: begin
               Position.RBX := Theme.Sing.Duet4PP2.SingBar.X;
               Position.RBY := Theme.Sing.Duet4PP2.SingBar.Y;
               Position.RBW := Theme.Sing.Duet4PP2.SingBar.W;
               Position.RBH := Theme.Sing.Duet4PP2.SingBar.H;
             end;
          2: begin
               Position.RBX := Theme.Sing.Duet4PP3.SingBar.X;
               Position.RBY := Theme.Sing.Duet4PP3.SingBar.Y;
               Position.RBW := Theme.Sing.Duet4PP3.SingBar.W;
               Position.RBH := Theme.Sing.Duet4PP3.SingBar.H;
             end;
          3: begin
               Position.RBX := Theme.Sing.Duet4PP4.SingBar.X;
               Position.RBY := Theme.Sing.Duet4PP4.SingBar.Y;
               Position.RBW := Theme.Sing.Duet4PP4.SingBar.W;
               Position.RBH := Theme.Sing.Duet4PP4.SingBar.H;
             end;
        end;
      end
      else
      begin
        case Index of
          0:
             begin
               Position.RBX := Theme.Sing.Solo4PP1.SingBar.X;
               Position.RBY := Theme.Sing.Solo4PP1.SingBar.Y;
               Position.RBW := Theme.Sing.Solo4PP1.SingBar.W;
               Position.RBH := Theme.Sing.Solo4PP1.SingBar.H;
             end;
          1: begin
               Position.RBX := Theme.Sing.Solo4PP2.SingBar.X;
               Position.RBY := Theme.Sing.Solo4PP2.SingBar.Y;
               Position.RBW := Theme.Sing.Solo4PP2.SingBar.W;
               Position.RBH := Theme.Sing.Solo4PP2.SingBar.H;
             end;
          2: begin
               Position.RBX := Theme.Sing.Solo4PP3.SingBar.X;
               Position.RBY := Theme.Sing.Solo4PP3.SingBar.Y;
               Position.RBW := Theme.Sing.Solo4PP3.SingBar.W;
               Position.RBH := Theme.Sing.Solo4PP3.SingBar.H;
             end;
          3: begin
               Position.RBX := Theme.Sing.Solo4PP4.SingBar.X;
               Position.RBY := Theme.Sing.Solo4PP4.SingBar.Y;
               Position.RBW := Theme.Sing.Solo4PP4.SingBar.W;
               Position.RBH := Theme.Sing.Solo4PP4.SingBar.H;
             end;
        end;
      end;
    end
    else
    begin
      // 6 players
      if (CurrentSong.isDuet) then
      begin
        case Index of
          0:
             begin
               Position.RBX := Theme.Sing.Duet6PP1.SingBar.X;
               Position.RBY := Theme.Sing.Duet6PP1.SingBar.Y;
               Position.RBW := Theme.Sing.Duet6PP1.SingBar.W;
               Position.RBH := Theme.Sing.Duet6PP1.SingBar.H;
             end;
          1: begin
               Position.RBX := Theme.Sing.Duet6PP2.SingBar.X;
               Position.RBY := Theme.Sing.Duet6PP2.SingBar.Y;
               Position.RBW := Theme.Sing.Duet6PP2.SingBar.W;
               Position.RBH := Theme.Sing.Duet6PP2.SingBar.H;
             end;
          2: begin
               Position.RBX := Theme.Sing.Duet6PP3.SingBar.X;
               Position.RBY := Theme.Sing.Duet6PP3.SingBar.Y;
               Position.RBW := Theme.Sing.Duet6PP3.SingBar.W;
               Position.RBH := Theme.Sing.Duet6PP3.SingBar.H;
             end;
          3: begin
               Position.RBX := Theme.Sing.Duet6PP4.SingBar.X;
               Position.RBY := Theme.Sing.Duet6PP4.SingBar.Y;
               Position.RBW := Theme.Sing.Duet6PP4.SingBar.W;
               Position.RBH := Theme.Sing.Duet6PP4.SingBar.H;
             end;
          4: begin
               Position.RBX := Theme.Sing.Duet6PP5.SingBar.X;
               Position.RBY := Theme.Sing.Duet6PP5.SingBar.Y;
               Position.RBW := Theme.Sing.Duet6PP5.SingBar.W;
               Position.RBH := Theme.Sing.Duet6PP5.SingBar.H;
             end;
          5: begin
               Position.RBX := Theme.Sing.Duet6PP6.SingBar.X;
               Position.RBY := Theme.Sing.Duet6PP6.SingBar.Y;
               Position.RBW := Theme.Sing.Duet6PP6.SingBar.W;
               Position.RBH := Theme.Sing.Duet6PP6.SingBar.H;
             end;
        end;
      end
      else
      begin
        case Index of
          0:
             begin
               Position.RBX := Theme.Sing.Solo6PP1.SingBar.X;
               Position.RBY := Theme.Sing.Solo6PP1.SingBar.Y;
               Position.RBW := Theme.Sing.Solo6PP1.SingBar.W;
               Position.RBH := Theme.Sing.Solo6PP1.SingBar.H;
             end;
          1: begin
               Position.RBX := Theme.Sing.Solo6PP2.SingBar.X;
               Position.RBY := Theme.Sing.Solo6PP2.SingBar.Y;
               Position.RBW := Theme.Sing.Solo6PP2.SingBar.W;
               Position.RBH := Theme.Sing.Solo6PP2.SingBar.H;
             end;
          2: begin
               Position.RBX := Theme.Sing.Solo6PP3.SingBar.X;
               Position.RBY := Theme.Sing.Solo6PP3.SingBar.Y;
               Position.RBW := Theme.Sing.Solo6PP3.SingBar.W;
               Position.RBH := Theme.Sing.Solo6PP3.SingBar.H;
             end;
          3: begin
               Position.RBX := Theme.Sing.Solo6PP4.SingBar.X;
               Position.RBY := Theme.Sing.Solo6PP4.SingBar.Y;
               Position.RBW := Theme.Sing.Solo6PP4.SingBar.W;
               Position.RBH := Theme.Sing.Solo6PP4.SingBar.H;
             end;
          4: begin
               Position.RBX := Theme.Sing.Solo6PP5.SingBar.X;
               Position.RBY := Theme.Sing.Solo6PP5.SingBar.Y;
               Position.RBW := Theme.Sing.Solo6PP5.SingBar.W;
               Position.RBH := Theme.Sing.Solo6PP5.SingBar.H;
             end;
          5: begin
               Position.RBX := Theme.Sing.Solo6PP6.SingBar.X;
               Position.RBY := Theme.Sing.Solo6PP6.SingBar.Y;
               Position.RBW := Theme.Sing.Solo6PP6.SingBar.W;
               Position.RBH := Theme.Sing.Solo6PP6.SingBar.H;
             end;
        end;
      end;
    end;
  end
  else
  begin
    // only draw if player has a position
    if Players[Index].Position <> High(byte) then
    begin
      // only draw if player is on cur screen
      if (((Players[Index].Position and 128) = 0) = (ScreenAct = 1) and
          Players[index].RBVisible and
          Players[index].Visible) then
      begin
        Drawing := true;

        Position := aPositions[Players[Index].Position and 127];

        // DIRTY HACK
        // correct position for duet with 3/6 players
        if (CurrentSong.isDuet) and ((PlayersPlay = 3) or (PlayersPlay = 6)) then
        begin
          case Index of
            0, 3, 6:
               begin
                 Position.RBX := Theme.Sing.Duet3PP1.SingBar.X;
                 Position.RBY := Theme.Sing.Duet3PP1.SingBar.Y;
                 Position.RBW := Theme.Sing.Duet3PP1.SingBar.W;
                 Position.RBH := Theme.Sing.Duet3PP1.SingBar.H;
               end;
            1, 4, 7: begin
                 Position.RBX := Theme.Sing.Duet3PP2.SingBar.X;
                 Position.RBY := Theme.Sing.Duet3PP2.SingBar.Y;
                 Position.RBW := Theme.Sing.Duet3PP2.SingBar.W;
                 Position.RBH := Theme.Sing.Duet3PP2.SingBar.H;
               end;
            2, 5, 8: begin
                 Position.RBX := Theme.Sing.Duet3PP3.SingBar.X;
                 Position.RBY := Theme.Sing.Duet3PP3.SingBar.Y;
                 Position.RBW := Theme.Sing.Duet3PP3.SingBar.W;
                 Position.RBH := Theme.Sing.Duet3PP3.SingBar.H;
               end;
          end;
        end;
      end;
    end;
  end;

  if (Drawing) then
  begin
    if (Enabled and Players[Index].Enabled) then
    begin
      // move position if enabled
      Diff := Players[Index].RBTarget - Players[Index].RBPos;
      if (Abs(Diff) < 0.02) then
        aPlayers[Index].RBPos := aPlayers[Index].RBTarget
      else
        aPlayers[Index].RBPos := aPlayers[Index].RBPos + Diff*0.1;
    end;

    // get colors for rating bar
    if (Players[index].RBPos <= 0.22) then
    begin
      R := 1;
      G := 0;
      B := 0;
    end
    else if (Players[index].RBPos <= 0.42) then
    begin
      R := 1;
      G := Players[index].RBPos * 5;
      B := 0;
    end
    else if (Players[index].RBPos <= 0.57) then
    begin
      R := 1;
      G := 1;
      B := 0;
    end
    else if (Players[index].RBPos <= 0.77) then
    begin
      R := 1 - (Players[index].RBPos - 0.57) * 5;
      G := 1;
      B := 0;
    end
    else
    begin
      R := 0;
      G := 1;
      B := 0;
    end;

    // enable all glfuncs needed
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    // draw rating bar bg
    glColor4f(1, 1, 1, 0.8);
    glBindTexture(GL_TEXTURE_2D, Settings.RatingBar_BG_Tex.TexNum);

    glBegin(GL_QUADS);
      glTexCoord2f(0, 0);
      glVertex2f(Position.RBX, Position.RBY);

      glTexCoord2f(0, Settings.RatingBar_BG_Tex.TexH);
      glVertex2f(Position.RBX, Position.RBY+Position.RBH);

      glTexCoord2f(Settings.RatingBar_BG_Tex.TexW, Settings.RatingBar_BG_Tex.TexH);
      glVertex2f(Position.RBX+Position.RBW, Position.RBY+Position.RBH);

      glTexCoord2f(Settings.RatingBar_BG_Tex.TexW, 0);
      glVertex2f(Position.RBX+Position.RBW, Position.RBY);
    glEnd;

    // draw rating bar itself
    Size := Position.RBX + Position.RBW * Players[Index].RBPos;
    glColor4f(R, G, B, 1);
    glBindTexture(GL_TEXTURE_2D, Settings.RatingBar_Bar_Tex.TexNum);
    glBegin(GL_QUADS);
      glTexCoord2f(0, 0);
      glVertex2f(Position.RBX, Position.RBY);

      glTexCoord2f(0, Settings.RatingBar_Bar_Tex.TexH);
      glVertex2f(Position.RBX, Position.RBY + Position.RBH);

      glTexCoord2f(Settings.RatingBar_Bar_Tex.TexW, Settings.RatingBar_Bar_Tex.TexH);
      glVertex2f(Size, Position.RBY + Position.RBH);

      glTexCoord2f(Settings.RatingBar_Bar_Tex.TexW, 0);
      glVertex2f(Size, Position.RBY);
    glEnd;

    // draw rating bar fg (the thing with the 3 lines to get better readability)
    glColor4f(1, 1, 1, 0.6);
    glBindTexture(GL_TEXTURE_2D, Settings.RatingBar_FG_Tex.TexNum);
    glBegin(GL_QUADS);
      glTexCoord2f(0, 0);
      glVertex2f(Position.RBX, Position.RBY);

      glTexCoord2f(0, Settings.RatingBar_FG_Tex.TexH);
      glVertex2f(Position.RBX, Position.RBY + Position.RBH);

      glTexCoord2f(Settings.RatingBar_FG_Tex.TexW, Settings.RatingBar_FG_Tex.TexH);
      glVertex2f(Position.RBX + Position.RBW, Position.RBY + Position.RBH);

      glTexCoord2f(Settings.RatingBar_FG_Tex.TexW, 0);
      glVertex2f(Position.RBX + Position.RBW, Position.RBY);
    glEnd;

    // disable all enabled glfuncs
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
  end; // eo Player has Position
end;

end.
