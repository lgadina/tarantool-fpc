{$I Tarantool.Options.Inc}

unit Tarantool.Packer;

interface

uses Tarantool.Interfaces, IdGlobal, Tarantool.SimpleMsgPack, System.SysUtils;

type
  TTNTPacker = class(TInterfacedObject, IPacker)
  private
    FMsgPackObjects: array[0..2] of TSimpleMsgPack;
    function GetAsBytes: TIdBytes;
    function AddArray(ASource, ADest: TBytes): TBytes; inline;
    procedure SetAsBytes(const Value: TIdBytes);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Header: IPackerMap;
    function Body: IPackerMap;
    property AsBytes: TIdBytes read GetAsBytes write SetAsBytes;
  end;

  TTNTPackMap = class(TInterfacedObject, IPackerMap)
  private
    FObj: TSimpleMsgPack;
    function GetAsBytes: TBytes;
    procedure SetAsBytes(const Value: TBytes);
  public
    constructor Create(AMsgPackObject: TSimpleMsgPack);
    destructor Destroy; override;
    function Pack(const AKey: Integer; AValue: Integer): IPackerMap; overload;
    function Pack(const AKey: String; AValue: Integer): IPackerMap; overload;
    function Pack(const AKey: Integer; AValue: string): IPackerMap; overload;
    function Pack(const AKey: String; AValue: string): IPackerMap; overload;
    function Pack(const AKey: Integer; AValue: TBytes): IPackerMap; overload;
    function Pack(const AKey: String; AValue: TBytes): IPackerMap; overload;
    function Pack(const AKey: Integer; AValue: Boolean): IPackerMap; overload;
    function Pack(const AKey: String; AValue: Boolean): IPackerMap; overload;

    function PackMap(const AKey: Integer): IPackerMap; overload;
    function PackMap(const AKey: String): IPackerMap; overload;
    function PackArray(const AKey: string): IPackerArray; overload;
    function PackArray(const AKey: integer): IPackerArray; overload;
    function Count: Integer;
    function Name(const Index: Integer): String;
    function DataType(const Index: Integer): TMsgPackType;
    function UnpackArray(const AKey: Integer): IPackerArray; overload;
    function UnpackArray(const AKey: String): IPackerArray; overload;
    function UnpackMap(const AKey: Integer): IPackerMap; overload;
    function UnpackMap(const AKey: String): IPackerMap; overload;
    function UnpackInteger(const AKey: Integer): Integer; overload;
    function UnpackString(const AKey: Integer): String; overload;
    function UnpackInteger(const AKey: String): Integer; overload;
    function UnpackString(const AKey: String): String; overload;
    function UnpackBoolean(const AKey: Integer): Boolean; overload;
    function UnpackBoolean(const AKey: String): Boolean; overload;
    function UnpackBytes(const AKey: Integer): TBytes; overload;
    function UnpackBytes(const AKey: String): TBytes; overload;
    function UnpackVariant(const AKey: string): Variant; overload;
    function UnpackVariant(const AKey: Integer): Variant; overload;

    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
  end;

  TTNTPackArray = class(TInterfacedObject, IPackerArray)
  private
    FObj: TSimpleMsgPack;
    function GetAsBytes: TBytes;
    procedure SetAsBytes(const Value: TBytes);
  protected
    procedure InternalPack(const AValue: Integer); overload;
    procedure InternalPack(const AValue: string); overload;
    procedure InternalPack(const AValue: TBytes); overload;
  public
    constructor Create(AMsgPackObject: TSimpleMsgPack);
    destructor Destroy; override;
    function Count: Integer;
    function Pack(const AValue: Integer): IPackerArray; overload;
    function Pack(const AValue: String): IPackerArray; overload;
    function Pack(const AValue: TBytes): IPackerArray; overload;
    function Pack(const AValue: Boolean): IPackerArray; overload;
    function Pack(const AValue: Variant): IPackerArray; overload;
    function PackArray: IPackerArray;
    function PackMap: IPackerMap;
    function DataType(const Index: Integer): TMsgPackType;
    function UnpackArray(const Index: Integer): IPackerArray;
    function UnpackInteger(const Index: Integer): Integer;
    function UnpackString(const Index: Integer): String;
    function UnpackMap(const Index: Integer): IPackerMap;
    function UnpackBytes(const Index: Integer): TBytes;
    function UnpackBoolean(const Index: Integer): Boolean;
    function UnpackVariant(const Index: Integer): Variant;
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
  end;


implementation

uses System.Classes
  , Tarantool.UserKeys
  , Tarantool.Variants
  , Variants;




{ TTNTPacker }

function TTNTPacker.Body: IPackerMap;
begin
 if FMsgPackObjects[2] = nil then
  FMsgPackObjects[2] := TSimpleMsgPack.Create(mptMap);
 Result := TTNTPackMap.Create(FMsgPackObjects[2]);
end;

procedure TTNTPacker.Clear;
var Obj: TSimpleMsgPack;
begin
 for Obj in FMsgPackObjects do
  if Assigned(Obj) then
    Obj.Free;
 FillChar(FMsgPackObjects, Length(FMsgPackObjects), 0);
end;

constructor TTNTPacker.Create;
begin
  FillChar(FMsgPackObjects[0], Length(FMsgPackObjects), 0);
end;


destructor TTNTPacker.Destroy;
begin
  Clear;
  inherited;
end;

function TTNTPacker.GetAsBytes: TIdBytes;
var Hdr, Bdy: TBytes;
    len: Int64;
    l: TBytes;
    outBuf: TBytes;
begin
 if (FMsgPackObjects[1] <> nil) and (FMsgPackObjects[2] <> nil) then
 begin
  Hdr := FMsgPackObjects[1].EncodeToBytes;
  {$IFDEF  DUMP_MSG_PACK}
   DumpObjMsgPack(FMsgPackObjects[1], 0, '');
  {$ENDIF}

  Bdy := FMsgPackObjects[2].EncodeToBytes;
  {$IFDEF  DUMP_MSG_PACK}
  DumpObjMsgPack(FMsgPackObjects[2], 0, '');
  {$ENDIF}

  len := Length(Hdr)+Length(Bdy);
  SetLength(l, 5);
  l[0] := $ce;
  l[1] := (len shr 24) and $FF;
  l[2] := (len shr 16) and $FF;
  l[3] := (len shr 8) and $FF;
  l[4] := len and $FF;

  outBuf := AddArray(Hdr, l);
  outBuf := AddArray(Bdy, OutBuf);
  SetLength(Result, length(outBuf));
  Move(outBuf[0], Result[0], Length(outBuf));
 end else
  SetLength(Result, 0);
end;

function TTNTPacker.Header: IPackerMap;
begin
 if FMsgPackObjects[1] = nil then
  FMsgPackObjects[1] := TSimpleMsgPack.Create(mptMap);
 Result := TTNTPackMap.Create(FMsgPackObjects[1]);
end;

procedure TTNTPacker.SetAsBytes(const Value: TIdBytes);
var Stream: TMemoryStream;
    Pos: Integer;
begin
 Clear;
 Pos := 1;
 FMsgPackObjects[1] := TSimpleMsgPack.Create;
 FMsgPackObjects[2] := TSimpleMsgPack.Create;
 Stream := TMemoryStream.Create;
 try
   Stream.Write(value[0], Length(Value));
   Stream.Position := 0;
   while Stream.Position < Stream.Size do
    begin
      FMsgPackObjects[Pos].DecodeFromStream(Stream);
     {$IFDEF  DUMP_MSG_PACK}
      DumpObjMsgPack(FMsgPackObjects[Pos], 0, '');
     {$EndIf}
      Inc(pos);
      if Pos >= Length(FMsgPackObjects) then
       Break
    end;
 finally
   Stream.Free;
 end;
end;

function TTNTPacker.AddArray(ASource, ADest: TBytes): TBytes;
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




{ TTNTPackMap }

function TTNTPackMap.Count: Integer;
begin
 Result :=FObj.Count;
end;

constructor TTNTPackMap.Create(AMsgPackObject: TSimpleMsgPack);
begin
 FObj := AMsgPackObject;
end;

function TTNTPackMap.DataType(const Index: Integer): TMsgPackType;
begin
 Result := FObj.Items[Index].DataType;
end;

destructor TTNTPackMap.Destroy;
begin
  FObj := nil;
  inherited;
end;

function TTNTPackMap.GetAsBytes: TBytes;
begin
 Result := FObj.EncodeToBytes;
end;

function TTNTPackMap.Name(const Index: Integer): String;
begin
 Result := FObj.Items[Index].Name;
end;

function TTNTPackMap.Pack(const AKey: Integer; AValue: TBytes): IPackerMap;
begin
 FObj.OO[AKey] := TSimpleMsgPack.Create(mptBinary);
 FObj.OO[AKey].AsBytes := AValue;
 Result := Self;
end;

function TTNTPackMap.Pack(const AKey: String; AValue: TBytes): IPackerMap;
begin
 FObj.O[AKey] := TSimpleMsgPack.Create(mptBinary);
 FObj.O[AKey].AsBytes := AValue;
 Result := Self;
end;

function TTNTPackMap.PackArray(const AKey: string): IPackerArray;
var Obj: TSimpleMsgPack;
begin
 Obj := TSimpleMsgPack.Create(mptArray);
 FObj.O[AKey] := Obj;
 Result := TTNTPackArray.Create(Obj);
end;

function TTNTPackMap.PackArray(const AKey: integer): IPackerArray;
var Obj: TSimpleMsgPack;
begin
 Obj := TSimpleMsgPack.Create(mptArray);
 FObj.OO[AKey] := Obj;
 Result := TTNTPackArray.Create(Obj);
end;

function TTNTPackMap.PackMap(const AKey: Integer): IPackerMap;
var Obj: TSimpleMsgPack;
begin
 Obj := TSimpleMsgPack.Create(mptMap);
 FObj.OO[AKey] := Obj;
 Result := TTNTPackMap.Create(Obj);
end;

function TTNTPackMap.PackMap(const AKey: String): IPackerMap;
var Obj: TSimpleMsgPack;
begin
 Obj := TSimpleMsgPack.Create(mptMap);
 FObj.O[AKey] := Obj;
 Result := TTNTPackMap.Create(Obj);
end;

procedure TTNTPackMap.SetAsBytes(const Value: TBytes);
begin
 FObj.DecodeFromBytes(Value);
end;

function TTNTPackMap.UnpackArray(const AKey: Integer): IPackerArray;
var O: TSimpleMsgPack;
begin
 Result := nil;
 O := FObj.OO[AKey];
 if (O <> nil) and (O.DataType = mptArray) then
   Result := TTNTPackArray.Create(O);
end;

function TTNTPackMap.UnpackArray(const AKey: String): IPackerArray;
var O: TSimpleMsgPack;
begin
 Result := nil;
 O := FObj.O[AKey];
 if (O <> nil) and (O.DataType = mptArray) then
   Result := TTNTPackArray.Create(O);
end;

function TTNTPackMap.UnpackBoolean(const AKey: Integer): Boolean;
begin
 Result := FObj.BB[AKey];
end;

function TTNTPackMap.UnpackBoolean(const AKey: String): Boolean;
begin
 Result := FObj.B[AKey];
end;

function TTNTPackMap.UnpackBytes(const AKey: Integer): TBytes;
begin
 Result := FObj.OO[AKey].AsBytes
end;

function TTNTPackMap.UnpackBytes(const AKey: String): TBytes;
begin
 Result := FObj.O[AKey].AsBytes
end;

function TTNTPackMap.UnpackInteger(const AKey: String): Integer;
begin
 Result :=  FObj.I[AKey];
end;

function TTNTPackMap.UnpackMap(const AKey: Integer): IPackerMap;
var O: TSimpleMsgPack;
begin
 Result := nil;
 O := FObj.OO[AKey];
 if (O <> nil) and (O.DataType = mptMap) then
   Result := TTNTPackMap.Create(O);
end;

function TTNTPackMap.UnpackMap(const AKey: String): IPackerMap;
var O: TSimpleMsgPack;
begin
 Result := nil;
 O := FObj.O[AKey];
 if (O <> nil) and (O.DataType = mptMap) then
   Result := TTNTPackMap.Create(O);
end;

function TTNTPackMap.UnpackInteger(const AKey: Integer): Integer;
begin
 Result := FObj.II[AKey];
end;

function TTNTPackMap.UnpackString(const AKey: Integer): String;
begin
 Result := FObj.SS[AKey];
end;

function TTNTPackMap.Pack(const AKey: Integer; AValue: string): IPackerMap;
begin
 FObj.SS[AKey] := AValue;
 Result := Self;
end;

function TTNTPackMap.Pack(const AKey: String; AValue: string): IPackerMap;
begin
 FObj.S[AKey] := AValue;
 Result := Self;
end;

function TTNTPackMap.Pack(const AKey: Integer; AValue: Integer): IPackerMap;
begin
 FObj.II[AKey] := AValue;
 Result := Self;
end;

function TTNTPackMap.Pack(const AKey: String; AValue: Integer): IPackerMap;
begin
 FObj.I[AKey] := AValue;
 Result := Self;
end;

function TTNTPackMap.UnpackString(const AKey: String): String;
begin
 Result := FObj.S[AKey];
end;

function TTNTPackMap.UnpackVariant(const AKey: string): Variant;
begin
 Result := FObj.O[AKey].AsVariant
end;

function TTNTPackMap.UnpackVariant(const AKey: Integer): Variant;
begin
 Result := FObj.OO[AKey].AsVariant
end;

function TTNTPackMap.Pack(const AKey: Integer; AValue: Boolean): IPackerMap;
begin
 FObj.OO[AKey] := TSimpleMsgPack.Create(mptBoolean);
 FObj.OO[AKey].AsBoolean := AValue;
 Result := Self;
end;

function TTNTPackMap.Pack(const AKey: String; AValue: Boolean): IPackerMap;
begin
 FObj.O[AKey] := TSimpleMsgPack.Create(mptBoolean);
 FObj.O[AKey].AsBoolean := AValue;
 Result := Self;
end;

{ TTNTPackArray }

function TTNTPackArray.Count: Integer;
begin
 Result := FObj.Count;
end;

constructor TTNTPackArray.Create(AMsgPackObject: TSimpleMsgPack);
begin
 FObj := AMsgPackObject;
end;

function TTNTPackArray.DataType(const Index: Integer): TMsgPackType;
begin
 Result := FObj.Items[Index].DataType;
end;

destructor TTNTPackArray.Destroy;
begin
  FObj := nil;
  inherited;
end;

function TTNTPackArray.GetAsBytes: TBytes;
begin
 Result := FObj.EncodeToBytes;
end;

procedure TTNTPackArray.InternalPack(const AValue: string);
begin
 FObj.AddArrayChild.AsString := AValue;
end;

procedure TTNTPackArray.InternalPack(const AValue: TBytes);
begin
 FObj.AddArrayChild.AsBytes := AValue;
end;

function TTNTPackArray.Pack(const AValue: String): IPackerArray;
begin
 InternalPack(AValue);
 Result := Self;
end;

function TTNTPackArray.Pack(const AValue: TBytes): IPackerArray;
begin
 InternalPack(AValue);
 Result := Self;
end;

function TTNTPackArray.PackArray: IPackerArray;
begin
 Result := TTNTPackArray.Create(FObj.Add(mptArray));
end;

function TTNTPackArray.PackMap: IPackerMap;
begin
 Result := TTNTPackMap.Create(FObj.Add(mptMap));
end;

procedure TTNTPackArray.SetAsBytes(const Value: TBytes);
begin
 FObj.DecodeFromBytes(Value);
end;

function TTNTPackArray.UnpackArray(const Index: Integer): IPackerArray;
Var O: TSimpleMsgPack;
begin
  O := FObj.Items[Index];
  Result := nil;
  if (O <> nil) and (O.DataType = mptArray) then
   Result := TTNTPackArray.Create(O);
end;

function TTNTPackArray.UnpackBoolean(const Index: Integer): Boolean;
begin
 Result := FObj.Items[Index].AsBoolean;
end;

function TTNTPackArray.UnpackBytes(const Index: Integer): TBytes;
begin
 Result := FObj.Items[Index].AsBytes;
end;

function TTNTPackArray.UnpackInteger(const Index: Integer): Integer;
begin
 Result := FObj.Items[Index].AsInteger;
end;

function TTNTPackArray.UnpackMap(const Index: Integer): IPackerMap;
Var O: TSimpleMsgPack;
begin
  O := FObj.Items[Index];
  Result := nil;
  if (O <> nil) and (O.DataType = mptMap) then
   Result := TTNTPackMap.Create(O);
end;

function TTNTPackArray.UnpackString(const Index: Integer): String;
begin
 Result := FObj.Items[Index].AsString;
end;

function TTNTPackArray.UnpackVariant(const Index: Integer): Variant;
begin
 Result := FObj.Items[Index].AsVariant;
end;

procedure TTNTPackArray.InternalPack(const AValue: Integer);
begin
  FObj.AddArrayChild.AsInteger := AValue;
end;

function TTNTPackArray.Pack(const AValue: Integer): IPackerArray;
begin
  InternalPack(AValue);
  Result := Self;
end;

function TTNTPackArray.Pack(const AValue: Boolean): IPackerArray;
begin
 FObj.AddArrayChild.AsBoolean := AValue;
 Result := Self;
end;

function TTNTPackArray.Pack(const AValue: Variant): IPackerArray;
begin
  if VarType(AValue) = TNTVariantType.VarType then
   begin
     TNTVariantData(AValue).PackToMessage(PackArray);
   end else
    FObj.AddArrayChild.AsVariant := AValue;
  Result := Self;
end;

end.
