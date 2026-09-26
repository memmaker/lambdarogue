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

unit Quests;


interface

uses
  Constants, SysUtils;

type
  NonPlayer = record
    intX: integer;
    intY: integer;
  end;


type
  Mission = record
    strName:     string;
    strDescri, strIntroPlot, strIntroBook, strExtroPlot, strExtroBook: string;
    strText1, strText2, strText3, strText4, strText5, strTextProgress,
    strTextSolved, strTextFinalVisit: string;
    strTargetText1, strTargetText2: string;
    strNPCname:  string;
    intType:     integer;
    intRewardType: integer;
    strRewardItem, strRewardMonster: string;
    longRewardAmount: longint;
    strTargetName: string;
    intTargetID: integer;
    intTargetHive: integer;
    strGetItem:  string;
    strGetResources: string;
    intGetGold:  integer;
    intHuntAmount: integer;
    strFileName: string;
    intClass:    integer;
    intCharLvl:  integer;
    intNeedQuest, intNeedPlot, intNeedProf, intNeedDipl: integer;
  end;


var
  NPC:   array[1..9] of NonPlayer;        // NPCs
  Quest: array[1..27, 1..9] of Mission;    // 27 level with 9 quests per level
  Statement: array[1..200] of string;     // random statements for NPCs without quest
  MaxStatements: integer;            // total number of available random statements


procedure QuestInit;

implementation



procedure QuestInit;
var
  QuestFile:     textfile;
  i, j, lvl, id: integer;
  strKey, strValue: string;
begin

  strKey   := '';
  strValue := '';

  Assign(QuestFile, CONST_DATADIR + 'data/quests.txt');
  Reset(QuestFile);

  for i := 1 to 27 do
    for j := 1 to 9 do
    begin
      with Quest[i, j] do
      begin
        strName      := '-';
        strDescri    := '-';
        strIntroPlot := '-';
        strExtroPlot := '-';
        strIntroBook := '-';
        strExtroBook := '-';
        strText1     := '';
        strText2     := '';
        strText3     := '';
        strText4     := '';
        strText5     := '';
        strTargetText1 := '';
        strTargetText2 := '';
        strTextProgress := '';
        strTextSolved := '';
        strTextFinalVisit := 'I am glad to know you, friend :)';
        strNPCname   := '-';
        intType      := 1;
        intRewardType := -1;
        strRewardItem := '';
        longRewardAmount := 0;
        strRewardMonster := '';
        strTargetName := '';
        intTargetID  := 0;
        intTargetHive := 0;
        intHuntAmount := 0;
        strGetItem   := '';
        strGetResources := '';
        intGetGold   := 0;
        strFileName  := '';
        intClass     := 0;
        intCharLvl   := 1;
        intNeedQuest := 0;
        intNeedPlot  := 0;
        intNeedProf  := 0;
        intNeedDipl  := 0;
      end;
    end;

  i := 0;

  id  := 1;
  lvl := 1;

  while EOF(QuestFile) = False do
  begin
    repeat
      ReadLn(QuestFile, strKey);
    until ((strKey <> '') and (strKey[1] <> ' ') and (strKey <> '#')) or (EOF(QuestFile));

    ReadLn(QuestFile, strValue);

    if strKey = 'NewQuest:' then
      id := StrToInt(strValue);
    if strKey = 'DungeonLvl:' then
      lvl := StrToInt(strValue);

    if strKey = 'Description:' then
      Quest[lvl, id].strDescri := strValue;
    if strKey = 'IntroPlot:' then
      Quest[lvl, id].strIntroPlot := strValue;
    if strKey = 'ExtroPlot:' then
      Quest[lvl, id].strExtroPlot := strValue;
    if strKey = 'IntroBook:' then
      Quest[lvl, id].strIntroBook := strValue;
    if strKey = 'ExtroBook:' then
      Quest[lvl, id].strExtroBook := strValue;
    if strKey = 'Text1:' then
      Quest[lvl, id].strText1 := strValue;
    if strKey = 'Text2:' then
      Quest[lvl, id].strText2 := strValue;
    if strKey = 'Text3:' then
      Quest[lvl, id].strText3 := strValue;
    if strKey = 'Text4:' then
      Quest[lvl, id].strText4 := strValue;
    if strKey = 'Text5:' then
      Quest[lvl, id].strText5 := strValue;
    if strKey = 'TargetText1:' then
      Quest[lvl, id].strTargetText1 := strValue;
    if strKey = 'TargetText2:' then
      Quest[lvl, id].strTargetText2 := strValue;
    if strKey = 'TextProgress:' then
      Quest[lvl, id].strTextProgress := strValue;
    if strKey = 'TextSolved:' then
      Quest[lvl, id].strTextSolved := strValue;
    if strKey = 'TextFinalVisit:' then
      Quest[lvl, id].strTextFinalVisit := strValue;

    if strKey = 'QuestType' then
    begin
      if strValue = '= GetItem' then
        Quest[lvl, id].intType := 1;
      if strValue = '= Transport' then
        Quest[lvl, id].intType := 2;
      if strValue = '= Hunt' then
        Quest[lvl, id].intType := 4;
      if strValue = '= GetItemset' then
        Quest[lvl, id].intType := 5;
      if strValue = '= Info' then
        Quest[lvl, id].intType := 6;
      if strValue = '= GetGold' then
        Quest[lvl, id].intType := 7;
      if strValue = '= Answer' then
        Quest[lvl, id].intType := 8;
      if strValue = '= GetResources' then
        Quest[lvl, id].intType := 9;
      if strValue = '= DestroyHive' then
        Quest[lvl, id].intType := 10;
    end;

    if strKey = 'TargetID:' then
      Quest[lvl, id].intTargetID := StrToInt(strValue);

    if strKey = 'TargetName:' then
      Quest[lvl, id].strTargetName := strValue;

    if strKey = 'TargetHive:' then
      Quest[lvl, id].intTargetHive := StrToInt(strValue);


    if strKey = 'Answer:' then
      Quest[lvl, id].strTargetName := strValue;
    if strKey = 'NPC-Name:' then
      Quest[lvl, id].strNPCName := strValue;

    if strKey = 'Reward' then
    begin
      if strValue = '= Gold' then
        Quest[lvl, id].intRewardType := 1;
      if strValue = '= EXP' then
        Quest[lvl, id].intRewardType := 2;
      if strValue = '= Item' then
        Quest[lvl, id].intRewardType := 3;
      if strValue = '= Plot' then
        Quest[lvl, id].intRewardType := 4;
      if strValue = '= Bless' then
        Quest[lvl, id].intRewardType := 5;
      if strValue = '= WinGame' then
        Quest[lvl, id].intRewardType := 6;
      if strValue = '= Train' then
        Quest[lvl, id].intRewardType := 7;
      if strValue = '= LevelUp' then
        Quest[lvl, id].intRewardType := 8;
      if strValue = '= Heal' then
        Quest[lvl, id].intRewardType := 9;
      if strValue = '= Nothing' then
        Quest[lvl, id].intRewardType := 10;
      if strValue = '= CreatePortal' then
        Quest[lvl, id].intRewardType := 11;
      if strValue = '= Diploma' then
        Quest[lvl, id].intRewardType := 12;
      if strValue = '= SummonMonster' then
        Quest[lvl, id].intRewardType := 13;
    end;

    if strKey = 'RewardNumber:' then  // for reward types Gold, EXP, Diploma, Train
      Quest[lvl, id].longRewardAmount := StrToInt(strValue);
    if strKey = 'RewardItem:' then
      Quest[lvl, id].strRewardItem := strValue;
    if strKey = 'RewardMonster:' then
      Quest[lvl, id].strRewardMonster := strValue;


    //        if strKey='RewardPlot:' then
    //            Quest[lvl,id].strRewardItem := strValue;
    if strKey = 'GetItem:' then
      Quest[lvl, id].strGetItem := strValue;
    if strKey = 'GetResources:' then
      Quest[lvl, id].strGetResources := strValue;
    if strKey = 'GetGold:' then
      Quest[lvl, id].intGetGold := StrToInt(strValue);

    if strKey = 'HuntAmount:' then
      Quest[lvl, id].intHuntAmount := StrToInt(strValue);
    if strKey = 'FileName:' then
      Quest[lvl, id].strFileName := strValue;

    if strKey = 'Class:' then
      Quest[lvl, id].intClass := StrToInt(strValue);
    if strKey = 'CharLvl:' then
      Quest[lvl, id].intCharLvl := StrToInt(strValue);
    if strKey = 'NeedQuest:' then
      Quest[lvl, id].intNeedQuest := StrToInt(strValue);
    if strKey = 'NeedPlot:' then
      Quest[lvl, id].intNeedPlot := StrToInt(strValue);
    if strKey = 'NeedProfession:' then
      Quest[lvl, id].intNeedProf := StrToInt(strValue);
    if strKey = 'NeedDiploma:' then
      Quest[lvl, id].intNeedDipl := StrToInt(strValue);

  end;

  Close(QuestFile);
end;

end.
