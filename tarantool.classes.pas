unit tarantool.classes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SimpleMsgPack, tarantool.constant, contnrs, IdTCPClient;

const
  MaxLimit = 4294967295;


type

  { ETarantoolException }

  ETarantoolConnectException = class(Exception);
  ETarantoolIndexNotFound = class(Exception);
  ETarantoolProtocolException = class(Exception);
  ETarantoolException = class(Exception)
  private
    FErrorCode: Integer;
  public
    constructor Create(AErrorCode: Integer; AMessage: String);
    property ErrorCode: Integer read FErrorCode;
  end;

  TTarantoolDataType = (tdtUnknown, tdtNumber, tdtString, tdtArray, tdtMap);
  TTarantoolIndexData = record
    &Type: TTarantoolDataType;
    Idx: Integer;
  end;

type
  TTarantoolRawResponce = array of TSimpleMsgPack;

  { TTarantoolIndexDef }

  TTarantoolIndexDef = class
  private
    FId: Cardinal;
    FIId: Cardinal;
    FName: String;
    FType: String;
    FUnique: Boolean;
    FParts: array of TTarantoolIndexData;
    function GetParts(index: integer): TTarantoolIndexData;
    function GetPartsCount: integer;
  protected

  public
    constructor Create(AMsgPack: TSimpleMsgPack);
    property Id: Cardinal read FId;
    property IId: Cardinal read FIId;
    property Name: String read FName;
    property &Type: String read FType;
    property Unique: Boolean read FUnique;
    property parts[index: integer]: TTarantoolIndexData read GetParts;
    property partsCount: integer read GetPartsCount;
  end;

  { TTarantoolFieldDef }

  TTarantoolFieldDef = class
  private
    FName: String;
    FType: TTarantoolDataType;
    function GetName: String;
    function GetType: TTarantoolDataType;
    procedure SetName(AValue: String);
    procedure SetType(AValue: TTarantoolDataType);
  public
    property Name: String read GetName write SetName;
    property &Type: TTarantoolDataType read GetType write SetType;
  end;

  TTarantoolFieldDefList = class;

  { TTarantoolFieldDefEnumerator }

  TTarantoolFieldDefEnumerator = class
  private
    FList: TTarantoolFieldDefList;
    FPosition: Integer;
  public
    constructor Create(AList: TTarantoolFieldDefList);
    function GetCurrent: TTarantoolFieldDef;
    function MoveNext: Boolean;
    property Current: TTarantoolFieldDef read GetCurrent;
  end;


  { TTarantoolFieldDefList }

  TTarantoolFieldDefList = class(TObjectList)
  private
    function GetItems(Index: Integer): TTarantoolFieldDef;
    function GetKeyByName(AKeyName: String): TTarantoolFieldDef;
  public
    function AddFieldDef(AName: String; AType: TTarantoolDataType): TTarantoolFieldDef;
    function IndexOfName(AKeyName: String): Integer;
    property Items[Index: Integer]: TTarantoolFieldDef read GetItems; default;
    property KeyByName[AKeyName: String]: TTarantoolFieldDef read GetKeyByName;
    function GetEnumerator: TTarantoolFieldDefEnumerator;
    function Add: TTarantoolFieldDef;
  end;

  TTarantoolIndexDefList = class;

  { TTarantoolIndexDefEnumerator }

  TTarantoolIndexDefEnumerator = class
  private
    FList: TTarantoolIndexDefList;
    FPosition: Integer;
  public
    constructor Create(AList: TTarantoolIndexDefList);
    function GetCurrent: TTarantoolIndexDef;
    function MoveNext: Boolean;
    property Current: TTarantoolIndexDef read GetCurrent;
  end;


  { TTarantoolIndexDefList }

  TTarantoolIndexDefList = class(TObjectList)
  private
    function GetItems(Index: Integer): TTarantoolIndexDef;
  public
    property Items[Index: Integer]: TTarantoolIndexDef read GetItems;
    function Add(AMsg: TSimpleMsgPack): TTarantoolIndexDef;
    function GetEnumerator: TTarantoolIndexDefEnumerator;
  end;

  { TTarantoolConnection }

  TTarantoolConnection = class(TIdTCPClient)
  private
    FSync: Int64;
    function AddArray(ASource, ADest: TBytes): TBytes;
    function GetTarantoolPacketLength(ABuf: TBytes): Integer;
    function MakeCommand(Body: TBytes): TBytes;
    function MakePing(Sync: Int64): TBytes;
    function MakeSelect(SpaceId, IndexId, Limit, Offset,
      Iterator: Int64; Key: array of const): TBytes;
    function MakeTarantoolHeader(Code, Sync, SchemaId: Integer): TBytes;
  protected
    procedure InitComponent; override;
    function BytesToRawResponce(ABytes: TBytes): TTarantoolRawResponce;
    procedure FreeRawResponce(ARawResponce: TTarantoolRawResponce);
    function RequestResponceRaw(ACmd: TBytes): TTarantoolRawResponce;
    function RequestResponce(ACmd: TBytes): TSimpleMsgPack;
  public

  end;

  { TTarantoolSpace }

  TTarantoolSpace = class
  private
    FConnection: TTarantoolConnection;
    FKeyList: TTarantoolFieldDefList;
    FIndexList: TTarantoolIndexDefList;
    FSpaceId: Cardinal;
    FOwner: Cardinal;
    FFieldCount: Cardinal;
    FName: String;
    FEngine: String;
    function GetEngine: String;
    function GetFieldCount: Cardinal;
    function GetName: String;
    function GetOwner: Cardinal;
    function GetSpaceId: Cardinal;
    procedure SetEngine(AValue: String);
    procedure SetName(AValue: String);
    procedure SetOwner(AValue: Cardinal);
    procedure SetSpaceId(AValue: Cardinal);
  protected
    procedure AddFormat(AName, AType: String);
    procedure LoadTarantoolSpace(AMsg: TSimpleMsgPack);
    procedure LoadTarantoolIndex(AMsg: TSimpleMsgPack);
  public
    constructor Create(AConnection: TTarantoolConnection); overload;
    constructor Create(ASpaceId: Integer; AConnection: TTarantoolConnection); overload;
    constructor Create(ASpaceName: String; AConnection: TTarantoolConnection); overload;
    destructor Destroy; override;
    procedure Refresh;
    property SpaceId: Cardinal read GetSpaceId write SetSpaceId;
    property Owner: Cardinal read GetOwner write SetOwner;
    property Name: String Read GetName write SetName;
    property Engine: String read GetEngine write SetEngine;
    property FieldCount: Cardinal read GetFieldCount;
    function Select(AKeys: array of const; AIndexId: Int64; ALimit: Int64 = MaxLimit; AOffset: Int64 = 0; AIterator: Byte = IterEq): TSimpleMsgPack; overload;
    function Select(AKeys: Array of const; AIndex: String = 'primary'; ALimit: Int64 = MaxLimit; AOffset: Int64 = 0; AIterator: Byte = IterEq): TSimpleMsgPack; overload;
  end;

procedure DumpTarantoolPacketFile(AFileName: String);


implementation
uses variants;

{ TTarantoolIndexDefEnumerator }

constructor TTarantoolIndexDefEnumerator.Create(AList: TTarantoolIndexDefList);
begin
  FList := AList;
  FPosition := -1;
end;

function TTarantoolIndexDefEnumerator.GetCurrent: TTarantoolIndexDef;
begin
 Result := FList.Items[FPosition];
end;

function TTarantoolIndexDefEnumerator.MoveNext: Boolean;
begin
 inc(FPosition);
 Result := FPosition < FList.Count;
end;


{ ETarantoolException }

constructor ETarantoolException.Create(AErrorCode: Integer; AMessage: String);
begin
  FErrorCode := AErrorCode;
  inherited CreateFmt(AMessage+' (0x%s)', [IntToHex(AErrorCode, 4)]);
end;

function TTarantoolConnection.BytesToRawResponce(ABytes: TBytes): TTarantoolRawResponce;
var Stream: TMemoryStream;
    Msg: TSimpleMsgPack;
begin
  SetLength(Result, 0);
  if Length(ABytes) > 0 then
  begin
    Stream := TMemoryStream.Create;
    try
     Stream.Write(ABytes[0], Length(ABytes));
     Stream.Position := 0;
     while Stream.Position < Stream.Size do
      begin
        Msg := TSimpleMsgPack.Create;
        try
         msg.DecodeFromStream(Stream);
         SetLength(Result, Length(Result) + 1);
         Result[Length(Result)-1] := Msg;
        finally
        end;
      end;
    finally
      Stream.Free;
    end;
  end;
end;

procedure TTarantoolConnection.FreeRawResponce(ARawResponce: TTarantoolRawResponce);
var i: Integer;
begin
 for i := 0 to Length(ARawResponce) - 1 do
  begin
    if ARawResponce[i] <> nil then
     ARawResponce[i].Free;
   ARawResponce[i] := nil;
  end;
end;

procedure DumpObjMsgPack(AObj: TSimpleMsgPack; Ident: Word; ParentName: String);
var i: Integer;
begin
  if AObj.Name <> '' then
   Write(' ':Ident*2, 'Object=', AObj.DataType, ' Name=', AObj.Name)
 else
   Write(' ':Ident*2, 'Object=', AObj.DataType);
  if AObj.DataType in [mptArray, mptMap] then
  begin
    if AObj.Count = 0 then
     Write(' <empty>', #13#10)
    else
     Write(' Count:', AObj.Count, #13#10);
   for I := 0 to AObj.Count - 1 do
    DumpObjMsgPack(AObj.Items[i], Ident + 1, AObj.Name);
  end else
   Write(' Value=',AObj.AsString, #13#10);
end;

procedure DumpObjArray(ABody: TBytes; AOnlyDecode: Boolean = false);
var Stream: TMemoryStream;
    Msg: TSimpleMsgPack;
    i: Integer;
begin
  if Length(ABody) > 0 then
  begin
    Stream := TMemoryStream.Create;
    try
     Stream.Write(ABody[0], Length(ABody));
     Stream.Position := 0;
     i := 0;
     while Stream.Position < Stream.Size do
      begin
        Inc(i);
        Write('Responce #', i, ' at ', Stream.Position, #13#10);
        Msg := TSimpleMsgPack.Create;
        try
         msg.DecodeFromStream(Stream);
         if not AOnlyDecode then
          DumpObjMsgPack(Msg, 1, '');
        finally
          Msg.Free;
        end;
      end;
    finally
      Stream.Free;
    end;
  end;
end;

procedure DumpTarantoolPacketFile(AFileName: String);
var fl: TFileStream;
  TrMsg: TSimpleMsgPack;
begin
 writeln();
 writeln(AFileName);
 fl := TFileStream.Create(AFileName, fmOpenRead);
 TrMsg := TSimpleMsgPack.Create;
 TrMsg.DecodeFromStream(Fl);
 DumpObjMsgPack(TrMsg, 0, '');
 TrMsg.Free;

 TrMsg := TSimpleMsgPack.Create;
 TrMsg.DecodeFromStream(Fl);
 DumpObjMsgPack(TrMsg, 0, '');
 TrMsg.Free;
 TrMsg := TSimpleMsgPack.Create;
 TrMsg.DecodeFromStream(Fl);
 DumpObjMsgPack(TrMsg, 0, '');
 TrMsg.Free;
 fl.Free;

end;


function TTarantoolConnection.MakeTarantoolHeader(Code, Sync, SchemaId: Integer): TBytes;
var Msg: TSimpleMsgPack;
begin
 SetLength(Result, 0);
 try
  Msg := TSimpleMsgPack.Create;
  Msg.II[IPROTO_REQUEST_TYPE] := Code;
  Msg.II[IPROTO_SYNC] := Sync;
  if SchemaId > 0 then
   Msg.II[IPROTO_SCHEMA_ID] := SchemaId;
  Result := Msg.EncodeToBytes;
 finally
   Msg.Free;
 end;
end;

procedure TTarantoolConnection.InitComponent;
begin
  FSync := 0;
  inherited InitComponent;
end;

function TTarantoolConnection.AddArray(ASource, ADest: TBytes): TBytes; inline;
var i: Integer;
begin
 Result := ADest;
 if Length(ASource) > 0 then
  begin
   i := Length(ADest);
   SetLength(Result, Length(ASource)+i);
   Move(ASource[0], Result[i], Length(ASource));
  end;
end;

function TTarantoolConnection.MakeCommand(Body: TBytes): TBytes;
//var Msg: TSimpleMsgPack;
var
  i: Int64;
begin
 try
  i := Length(Body);
  SetLength(Result, 5);
  Result[0] := $ce;
  Result[1] := (i shl 24) and $FF;
  Result[2] := (i shl 16) and $FF;
  Result[3] := (i shl 8) and $FF;
  Result[4] := i and $FF;
  Result := AddArray(Body, Result);
 finally
 end;
end;

function TTarantoolConnection.GetTarantoolPacketLength(ABuf: TBytes): Integer;
begin
 Result := -1;
  if (Length(ABuf) >= 5) and (ABuf[0] = $ce) then
    with TSimpleMsgPack.Create do
    begin
      try
         DecodeFromBytes(ABuf);
         Result := AsInteger;
      finally
        Free;
      end;
    end;
end;

function TTarantoolConnection.MakeSelect(SpaceId, IndexId, Limit, Offset, Iterator: Int64; Key: array of const): TBytes;
var Msg: TSimpleMsgPack;
    Buf: TBytes;
    i: Integer;
    k: Integer;
begin
 Inc(FSync);
 SetLength(Result, 0);
 Result := MakeTarantoolHeader(IPROTO_SELECT, FSync, 0);
 try
  Msg := TSimpleMsgPack.Create;
  Msg.II[IPROTO_SPACE_ID] := SpaceId;
  Msg.II[IPROTO_INDEX_ID] :=  IndexId;
  Msg.II[IPROTO_LIMIT] := Limit;
  Msg.II[IPROTO_OFFSET] := Offset;
  Msg.II[IPROTO_ITERATOR] := Iterator;
  Msg.O[IPROTO_KEY.ToString] := TSimpleMsgPack.Create(mptArray);

  for i := 0 to Length(Key) - 1 do
    case Key[i].VType of
     vtChar: Msg.O[IPROTO_KEY.ToString].AddArrayChild.AsString := Key[i].VChar;
     vtString: Msg.O[IPROTO_KEY.ToString].AddArrayChild.AsString := Key[i].VString^;
     vtAnsiString: Msg.O[IPROTO_KEY.ToString].AddArrayChild.AsString := String(Key[i].VAnsiString);
     vtInt64: Msg.O[IPROTO_KEY.ToString].AddArrayChild.AsInteger := Key[i].VInt64^;
     vtInteger:Msg.O[IPROTO_KEY.ToString].AddArrayChild.AsInteger := Key[i].VInteger;
    end;
  Buf := Msg.EncodeToBytes;
 Result := MakeCommand(AddArray(Buf, Result));
 finally
   Msg.Free;
 end;
end;

function TTarantoolConnection.MakePing(Sync: Int64): TBytes;
begin
 Result := MakeTarantoolHeader(IPROTO_PING, Sync, 0);
 Result := MakeCommand(Result);
end;



procedure Test;
var Tcp: TTarantoolConnection;
    Tmp: TSimpleMsgPack;
    Version: String;
    Auth: String;
    Space: TTarantoolSpace;
begin
 tcp := TTarantoolConnection.Create;
 try
   tcp.Connect('172.17.0.103', 3301);
   tcp.IOHandler.RecvBufferSize := 100 * 1024 * 1024;
   Version := tcp.IOHandler.ReadLn();
   Auth := tcp.IOHandler.ReadLn();

{
   Space := TTarantoolSpace.Create(514, Tcp);

   Space.Free;}

   Space := TTarantoolSpace.Create('distro', Tcp);
    tmp := Space.Select(['2'], 'codename');
    if Tmp <> nil then
     begin
      DumpObjMsgPack(Tmp, 1, '');
      FreeAndNil(Tmp);
     end;
   Space.Free;

   Space := TTarantoolSpace.Create('space55', Tcp);
   tmp := Space.Select([5000000], 0, 4, 20, IterGe);
    if Tmp <> nil then
     begin
      DumpObjMsgPack(Tmp, 1, '');
      FreeAndNil(Tmp);
     end;
   Space.Free;


{
   Space := TTarantoolSpace.Create(281, Tcp);

   Space.Free;

   Space := TTarantoolSpace.Create(289, Tcp);

   Space.Free;}

 finally
   Tcp.Free;
 end;
end;

{ TTarantoolConnection }

function TTarantoolConnection.RequestResponceRaw(
  ACmd: TBytes): TTarantoolRawResponce;
var Buf: TBytes;
    Len: Integer;
    ErrCode: Integer;
    ErrMsg: String;
begin
  SetLength(Result, 0);
  if Connected then
   begin
    IOHandler.Write(ACmd);
    IOHandler.ReadBytes(Buf, 5, False);
    Len := GetTarantoolPacketLength(Buf);
    if Len > -1 then
     begin
      SetLength(buf, 0);
      IOHandler.ReadBytes(Buf, Len, False);
      Result := BytesToRawResponce(Buf);
     end;
    if Length(Result) > 0 then
     begin
       ErrCode := Result[0].II[IPROTO_REQUEST_TYPE];

      if ErrCode >= IPROTO_TYPE_ERR then
       begin
         ErrMsg := 'Unknown error.';
         if Length(Result) > 1 then
           ErrMsg := Result[1].SS[IPROTO_ERROR];
         raise ETarantoolException.Create(ErrCode, ErrMsg);
       end;
     end;
   end;
end;

function TTarantoolConnection.RequestResponce(ACmd: TBytes): TSimpleMsgPack;
var rw: TTarantoolRawResponce;
    tmp: TSimpleMsgPack;
begin
  Tmp := nil;
  Result := nil;
  rw := RequestResponceRaw(ACmd);
  if Length(rw) > 1 then
    Tmp := rw[1];
  if Length(rw) > 0 then
    rw[0].Free;
  SetLength(rw, 0);
  if Tmp = nil then
    raise ETarantoolProtocolException.Create('Empty responce');
  if Tmp.O[IPROTO_DATA.ToString] = nil then
    raise ETarantoolProtocolException.Create('IPROTO_DATA expected');
  if Tmp.O[IPROTO_DATA.ToString].DataType <> mptArray then
    raise ETarantoolProtocolException.Create('No tuple array');
  try
   Result := TSimpleMsgPack.Create;
   Result.DecodeFromBytes(Tmp.O[IPROTO_DATA.ToString].EncodeToBytes);
  finally
    Tmp.Free;
  end;
end;

{ TTarantoolIndexDefList }

function TTarantoolIndexDefList.GetItems(Index: Integer): TTarantoolIndexDef;
begin
  Result := TTarantoolIndexDef(inherited Items[Index]);
end;

function TTarantoolIndexDefList.Add(AMsg: TSimpleMsgPack): TTarantoolIndexDef;
begin
  Result := TTarantoolIndexDef.Create(AMsg);
  inherited Add(Result);
end;

function TTarantoolIndexDefList.GetEnumerator: TTarantoolIndexDefEnumerator;
begin
  Result := TTarantoolIndexDefEnumerator.Create(Self);
end;

{ TTarantoolIndexDef }

function TTarantoolIndexDef.GetParts(index: integer): TTarantoolIndexData;
begin
  Result := FParts[index];
end;

function TTarantoolIndexDef.GetPartsCount: integer;
begin
 Result := Length(FParts);
end;

constructor TTarantoolIndexDef.Create(AMsgPack: TSimpleMsgPack);
var tmp, tmp2: TSimpleMsgPack;
    i: Integer;
begin
 if AMsgPack.DataType = mptArray then
  begin
    FId := AMsgPack.Items[0].AsInteger;
    FIId := AMsgPack.Items[1].AsInteger;
    FName := AMsgPack.Items[2].AsString;
    FType := AMsgPack.Items[3].AsString;
    tmp := AMsgPack.Items[4];
    if tmp.DataType = mptMap then
     begin
      FUnique := tmp.B['unique'];
     end;
    tmp := AMsgPack.Items[5];
   {$IfDef TNT_DEBUG}
    write('   Id:', FId, ', IId:', FIId, ', Name:', FName, ', Type:', FType, ', Unique:', FUnique, #13#10);
    write('    ');
   {$EndIf}
    if tmp.DataType = mptArray then
     begin
      SetLength(FParts, tmp.Count);
      for i := 0 to tmp.Count - 1 do
       begin
        tmp2 := tmp.Items[i];
        if tmp2.DataType = mptArray then
         begin
          case LowerCase(tmp2.Items[1].AsString)  of
           'str': FParts[i].&Type := tdtString;
           'num': FParts[i].&Type := tdtNumber;
          end;
          FParts[i].Idx := tmp2.Items[0].AsInteger;
          {$IfDef TNT_DEBUG}
          Write(FParts[i].Idx,':',FParts[i].&Type);
          if i < tmp.Count - 1 then
            Write(',');
          {$EndIf}
         end;
       end;
     {$IfDef TNT_DEBUG}
      write(#13#10);
     {$EndIf}
     end;
  end;
end;


{ TTarantoolFieldDefEnumerator }

constructor TTarantoolFieldDefEnumerator.Create(AList: TTarantoolFieldDefList);
begin
  FList := AList;
  FPosition := -1;
end;

function TTarantoolFieldDefEnumerator.GetCurrent: TTarantoolFieldDef;
begin
 Result := FList[FPosition];
end;

function TTarantoolFieldDefEnumerator.MoveNext: Boolean;
begin
 Inc(FPosition);
 Result := FPosition < FList.Count;
end;

{ TTarantoolFieldDefList }

function TTarantoolFieldDefList.GetItems(Index: Integer): TTarantoolFieldDef;
begin
  Result := TTarantoolFieldDef(inherited Items[Index]);
end;

function TTarantoolFieldDefList.GetKeyByName(AKeyName: String): TTarantoolFieldDef;
var i: Integer;
begin
 Result := nil;
 i := IndexOfName(AKeyName);
 if i > -1 then
   Result := Items[i];
end;

function TTarantoolFieldDefList.AddFieldDef(AName: String;
  AType: TTarantoolDataType): TTarantoolFieldDef;
begin
  Result := Add;
  Result.Name := AName;
  Result.&Type := AType;
end;

function TTarantoolFieldDefList.IndexOfName(AKeyName: String): Integer;
var i: Integer;
begin
 Result := -1;
 for i := 0 to Count - 1 do
  begin
    if CompareStr(AKeyName, Items[i].Name) = 0 then
      begin
        Result := i;
        Break;
      end;
  end;
end;

function TTarantoolFieldDefList.GetEnumerator: TTarantoolFieldDefEnumerator;
begin
  Result := TTarantoolFieldDefEnumerator.Create(Self);
end;

function TTarantoolFieldDefList.Add: TTarantoolFieldDef;
begin
 Result := TTarantoolFieldDef.Create;
 inherited Add(Result);
end;

{ TTarantoolFieldDef }

function TTarantoolFieldDef.GetName: String;
begin
  Result := FName;
end;

function TTarantoolFieldDef.GetType: TTarantoolDataType;
begin
 Result := FType;
end;

procedure TTarantoolFieldDef.SetName(AValue: String);
begin
 FName := AValue;
end;

procedure TTarantoolFieldDef.SetType(AValue: TTarantoolDataType);
begin
 FType := AValue;
end;

{ TTarantoolSpace }

function TTarantoolSpace.GetSpaceId: Cardinal;
begin
  Result := FSpaceId;
end;

procedure TTarantoolSpace.SetEngine(AValue: String);
begin
 FEngine := AValue;
end;

function TTarantoolSpace.GetName: String;
begin
  Result := FName;
end;

function TTarantoolSpace.GetOwner: Cardinal;
begin
  Result := FOwner;
end;

function TTarantoolSpace.GetEngine: String;
begin
  Result := FEngine;
end;

function TTarantoolSpace.GetFieldCount: Cardinal;
begin
  Result := FFieldCount;
end;

procedure TTarantoolSpace.SetName(AValue: String);
begin
 FName := AValue;
end;

procedure TTarantoolSpace.SetOwner(AValue: Cardinal);
begin
 FOwner:= AValue;
end;

procedure TTarantoolSpace.SetSpaceId(AValue: Cardinal);
begin
 FSpaceId := AValue;
end;

procedure TTarantoolSpace.AddFormat(AName, AType: String);
var Key: TTarantoolFieldDef;
begin
  if FKeyList.IndexOfName(AName) = -1 then
    begin
     Key := FKeyList.Add;
     Key.FName := AName;
     case AType of
      'str': Key.FType := tdtString;
      'num': Key.FType := tdtNumber;
      '*': Key.FType := tdtMap;
      'array': Key.FType := tdtArray;

     end;
    {$IfDef TNT_DEBUG}
     Write(' ', AName, '(', AType, ')');
    {$EndIf}
    end;
end;

procedure TTarantoolSpace.LoadTarantoolSpace(
  AMsg: TSimpleMsgPack);
var
    i: integer;
    MsgKeyList: TSimpleMsgPack;
begin
  FKeyList.Clear;
  if AMsg.DataType = mptArray then
    begin
     FSpaceId := AMsg.Items[0].AsInteger;         {0 Id Integer}
     FOwner := AMsg.Items[1].AsInteger;           {1 Owner Integer}
     FName := AMsg.Items[2].AsString;             {2 Name String}
     FEngine := AMsg.Items[3].AsString;           {3 Engine String}
     FFieldCount := AMsg.Items[4].AsInteger;      {4 field_count Integer}
     //                                           {5 flags Map}
     MsgKeyList := AMsg.Items[6];                        {6 format Array}
    {$IfDef TNT_DEBUG}
     Write('Space: ', FSpaceId, ', Owner:', FOwner, ', Name:', FName, ', Engine:', FEngine, ', FieldCount:', FFieldCount, #13#10);
    {$EndIf}
     if MsgKeyList.DataType = mptArray then
       begin
    {$IfDef TNT_DEBUG}
        Write(' Format:');
    {$EndIf}
         for i := 0 to MsgKeyList.Count - 1 do
         begin
            AddFormat(MsgKeyList.Items[i].S['name'], MsgKeyList.Items[i].S['type']);
           {$IfDef TNT_DEBUG}
            if i < MsgKeyList.Count-1 then
              Write(',');
           {$EndIf}
         end;
       end;
    {$IfDef TNT_DEBUG}
      Write(#13#10);
    {$EndIf}
    end;
end;

procedure TTarantoolSpace.LoadTarantoolIndex(AMsg: TSimpleMsgPack);
begin
  FIndexList.Add(AMsg);
end;

constructor TTarantoolSpace.Create(AConnection: TTarantoolConnection);
begin
  FConnection := AConnection;
  FKeyList := TTarantoolFieldDefList.Create;
  FIndexList := TTarantoolIndexDefList.Create;
end;

constructor TTarantoolSpace.Create(ASpaceId: Integer;
  AConnection: TTarantoolConnection);
begin
  Create(AConnection);
  FSpaceId := ASpaceId;
  Refresh;
end;

constructor TTarantoolSpace.Create(ASpaceName: String;
  AConnection: TTarantoolConnection);
begin
  Create(AConnection);
  FName := ASpaceName;
  Refresh;
end;

destructor TTarantoolSpace.Destroy;
begin
 FKeyList.Free;
 FIndexList.Free;
 inherited Destroy;
end;

procedure TTarantoolSpace.Refresh;
var cmd: TBytes;
    tmp: TSimpleMsgPack;
    i: Integer;
begin
  if FConnection.Connected then
   begin
     if (FSpaceId = 0) and (FName <> '') then
       cmd := FConnection.MakeSelect(281, 2, MaxLimit, 0, IterEq, [FName])
     else
     if (FSpaceId > 0) then
      cmd := FConnection.MakeSelect(281, 0, MaxLimit, 0, IterEq, [FSpaceId])
     else
      raise Exception.Create('Space id is not defined');

     Tmp := FConnection.RequestResponce(cmd);
     if tmp <> nil then
      try
       for i := 0 to tmp.Count -1 do
         LoadTarantoolSpace(tmp.Items[i]);
      finally
        FreeAndNil(tmp);
      end;

     cmd := FConnection.MakeSelect(289, 0, MaxLimit, 0, IterEq, [FSpaceId]);
     Tmp := FConnection.RequestResponce(cmd);
     if tmp <> nil then
      try
       for i := 0 to tmp.Count -1 do
         LoadTarantoolIndex(tmp.Items[i]);
      finally
        FreeAndNil(tmp);
      end;
   end;
end;

function TTarantoolSpace.Select(AKeys: array of const; AIndexId: Int64;
  ALimit: Int64; AOffset: Int64; AIterator: Byte): TSimpleMsgPack;
var cmd: TBytes;
begin
  if FConnection.Connected then
   begin
     cmd := FConnection.MakeSelect(FSpaceId, AIndexId, ALimit, AOffset, AIterator, AKeys);
     Result := FConnection.RequestResponce(cmd);
   end
  else
   raise ETarantoolConnectException.Create('Not connected');
end;

function TTarantoolSpace.Select(AKeys: array of const; AIndex: String;
  ALimit: Int64; AOffset: Int64; AIterator: Byte): TSimpleMsgPack;
var idx: TTarantoolIndexDef;
    IdxId: Integer;
begin
  idxId := -1;
  for idx in FIndexList do
   if CompareStr(idx.Name, AIndex) = 0 then
    begin
      IdxId := idx.IId;
      Break;
    end;
  if IdxId = -1 then
   raise ETarantoolIndexNotFound.CreateFmt('Index "%s" in space "%s/%d" not found', [AIndex, FName, FSpaceId]);
  Result := Select(AKeys, IdxId, ALimit, AOffset, AIterator);
end;

initialization
   Test;
   Halt(0);
end.

