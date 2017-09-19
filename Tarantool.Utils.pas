unit Tarantool.Utils;

{$IFDEF FPC}
        {$MODESWITCH ADVANCEDRECORDS}
        {$MODESWITCH TYPEHELPERS}
{$ENDIF}


interface

uses
  {$IfDef FPC}
   typinfo
  {$Else}
   System.TypInfo
  {$EndIf}
   , Sysutils
  ;


type
  TNativeIntDynArray = array of NativeInt;

procedure GetDynArrayElementTypeInfo(TypeInfo: PTypeInfo; var ElementInfo: PTypeInfo; var Dims: Integer);
function GetDynArrayLength(P: Pointer): Integer;
function ReadByte(var P: Pointer): Byte;
function ReadWord(var P: Pointer): Word;
function ReadLong(var P: Pointer): Integer;
function ReadPointer(var P: Pointer): Pointer;
function ReadString(var P: Pointer): String;
function IsArrayRect(P: Pointer; Dims: Integer): Boolean;
procedure GetDims(ArrP: Pointer; DimAr: TNativeIntDynArray; Dims: Integer);

function GetDynArrayNextInfo2(typeInfo: PTypeInfo; var Name: string): PTypeInfo;
function GetDynArrayNextInfo(typeInfo: PTypeInfo): PTypeInfo;

{$IfDef FPC}
type

    { TGUIDHelperSub }

    TGUIDHelperSub = record helper(TGuidHelper) for TGuid
      class function Empty: TGUID; static;
    end;
{$EndIf}

implementation
uses
{$IfDef FPC}
  Classes,
  Types
{$Else}
  System.Classes,
  System.Types
{$EndIf}
;



procedure GetDynArrayElementTypeInfo(TypeInfo: PTypeInfo; var ElementInfo: PTypeInfo; var Dims: Integer);
var
  P: Pointer;
  S: String;
  ppInfo: PPTypeInfo;
  Info: PTypeInfo;
  CleanupInfo: Boolean;
begin
 CleanupInfo := False;
 Dims := 0;
 P := Pointer(TypeInfo);
 ReadByte(P);
 S := ReadString(P);
 ReadLong(P);
 ppInfo := ReadPointer(P);

  if (ppInfo <> nil) then
  begin
    CleanupInfo := True;
    Info := ppInfo^;
    if Info^.Kind = tkDynArray then
    begin
      GetDynArrayElementTypeInfo(Info, ElementInfo, Dims);
    end;
  end;

  ReadLong(P);
  ppInfo := ReadPointer(P);
  if ppInfo <> nil then
  begin
    ElementInfo := ppInfo^;
    if not CleanupInfo then
    begin
      Info := ElementInfo;
      if Info^.Kind = tkDynArray then
        GetDynArrayElementTypeInfo(Info, ElementInfo, Dims);
    end;
  end;
  Inc(Dims);
end;

function GetDynArrayLength(P: Pointer): Integer;
begin
  Result := Length(TByteDynArray(P));
end;

function ReadByte(var P: Pointer): Byte;
begin
  Result := Byte(P^);
  P := Pointer(NativeInt(P) + 1);
end;

function ReadWord(var P: Pointer): Word;
begin
  Result := Word(P^);
  P := Pointer( NativeInt(P) + 2);
end;

function ReadLong(var P: Pointer): Integer;
begin
  Result := Integer(P^);
  P := Pointer( NativeInt(P) + 4);
end;

function ReadPointer(var P: Pointer): Pointer;
begin
  Result := Pointer(P^);
  P := Pointer( NativeInt(P) + SizeOf(Pointer));
end;


function ReadString(var P: Pointer): String;
var
  B: Byte;
{$IFDEF UNICODE}
{$IFDEF NEXTGEN}
  AStr: TBytes;
{$ELSE !NEXTGEN}
  AStr: AnsiString;
{$ENDIF NEXTGEN}
{$ENDIF}
begin
  B := Byte(P^);
{$IFDEF UNICODE}
  SetLength(AStr, B);
  P := Pointer(NativeInt(P)+1);
{$IFDEF NEXTGEN}
  Move(P^, AStr[0], Integer(B));
  Result := Tencoding.UTF8.GetString(AStr);
{$ELSE !NEXTGEN}
  Move(P^, AStr[1], Integer(B));
  Result := UTF8ToString(AStr);
{$ENDIF NEXTGEN}
{$ELSE}
  SetLength(Result, B);
  P := Pointer( NativeInt(P) + 1);
  Move(P^, Result[1], Integer(B));
{$ENDIF}
  P := Pointer( NativeInt(P) + B );
end;




function RecurseArray(P: Pointer; var Dims: Integer): Boolean;
var
  I, Len, Size: Integer;
  ElemDataP: Pointer;
  Size2: Integer;
begin
  Result := True;
  if Dims > 1 then
  begin
    if not Assigned(P) then
      Exit;
    Len := GetDynArrayLength(P);
    ElemDataP := Pointer(P^);
    Size := GetDynArrayLength(ElemDataP);
    for I := 0 to Len - 1 do
    begin
      Size2 :=  GetDynArrayLength(ElemDataP);
      if Size <> Size2 { GetDynArrayLength(ElemDataP) } then
      begin
        Result := False;
        Exit;
      end;
      if Dims > 1 then
      begin
        Dec(Dims);
        Result := RecurseArray(ElemDataP, Dims);
        if not Result then
          Exit;
      end;
      ElemDataP := PPointer(NativeUInt(P) + SizeOf(Pointer))^;
    end;
  end;
end;

function IsArrayRect(P: Pointer; Dims: Integer): Boolean;
var
  D: Integer;
begin
  D := Dims;
  Result := RecurseArray(P, D);
end;

procedure GetDims(ArrP: Pointer; DimAr: TNativeIntDynArray; Dims: Integer);
var
  I: Integer;
begin
  for I := 0 to Dims - 1 do
  begin
    DimAr[I] := GetDynArrayLength(ArrP);
    if I < Dims - 1 then
    begin
      if Assigned(ArrP) then
        ArrP := Pointer(ArrP^);
    end;
  end;
end;

function GetDynArrayNextInfo(typeInfo: PTypeInfo): PTypeInfo;
var
  S: string;
begin
  Result := GetDynArrayNextInfo2(typeInfo, S);
end;

function GetDynArrayNextInfo2(typeInfo: PTypeInfo; var Name: string): PTypeInfo;
var
  P: Pointer;
  ppInfo: PPTypeInfo;
begin
  Result := nil;
  P := Pointer(typeInfo);
  ReadByte(P);            { kind }
  Name := ReadString(P);  { synmame }
  ReadLong(P);            { elsize }
  ppInfo := ReadPointer(P);
  if ppInfo <> nil then
    Result := ppInfo^   { eltype or 0 if not destructable }
  else
  begin
    ReadLong(P);      { vartype }
    ppInfo := ReadPointer(P); { elttype, even if not destructable, 0 if type has no RTTI }
    if ppInfo <> nil then
      Result := ppInfo^;
  end;
end;


{$IfDef FPC}
{ TGUIDHelperSub }

class function TGUIDHelperSub.Empty: TGUID;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{$EndIf}

end.
