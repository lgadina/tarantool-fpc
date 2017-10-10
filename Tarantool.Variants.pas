unit Tarantool.Variants;

{$I Tarantool.Options.inc}

interface

uses
  SysUtils,
  Classes,
  Variants,
  TypInfo,
  Tarantool.SimpleMsgPack,
  Tarantool.Interfaces;

type
  TTNTStringDynArray = array of string;
  TTNTVariantDynArray = array of variant;
  TTNTIntegerDynArray = array of integer;

  TTNTByteDynArray = array of byte;
  PTNTByteDynArray = ^TTNTByteDynArray;

  {$ifndef UNICODE}
  {$ifdef FPC}
  NativeInt = PtrInt;
  NativeUInt = PtrUInt;
  {$else}
  NativeInt = integer;
  NativeUInt = cardinal;
  {$endif}
  RawByteString = AnsiString;
  {$endif}

  {$ifdef NEXTGEN}
  TUTF8Buffer = TBytes;
  TObjectList = TObjectList<TObject>;
  {$else}
  TUTF8Buffer = UTF8String;
  {$endif}

  ETNTVariantException = class(Exception);

  TTNTVariantKind = (tvkUndefined, tvkObject, tvkArray);

  PTNTVariantData = ^TTNTVariantData;

  {$A-}
  {$ifdef USEOBJECTINSTEADOFRECORD}
  TTNTVariantData = object
  protected
  {$else}
  TTNTVariantData = record
  private
  {$endif}
    VType: TVarType;
    _Align: byte;
    VKind: TTNTVariantKind;
    VCount: integer;
    function GetKind: TTNTVariantKind;
    function GetCount: integer;
    function GetVarData(const aName: string; var Dest: TVarData): boolean;
    function GetValue(const aName: string): variant;
    function GetValueCopy(const aName: string): variant;
    procedure SetValue(const aName: string; const aValue: variant);
    function GetItem(aIndex: integer): variant;
    procedure SetItem(aIndex: integer; const aItem: variant);

  public
    Names: TTNTStringDynArray;
    Values: TTNTVariantDynArray;
    procedure Init; overload;
    procedure InitFrom(const AMsgPack: TTNTMsgPack); overload;
    procedure InitFrom(const APacker: ITNTPackerArray); overload;
    procedure InitFrom(const APacker: ITNTPackerMap); overload;
    function ToMsgPack: TTNTMsgPack;
    procedure PackToMessage(const APacker: ITNTPackerArray);
    procedure InitFrom(const aValues: TTNTVariantDynArray); overload;
    procedure Clear;
    function Data(const aName: string): PTNTVariantData;
      {$ifdef HASINLINE}inline;{$endif}
    function EnsureData(const aPath: string): PTNTVariantData;
    function AddItem: PTNTVariantData;
    procedure AddValue(const aValue: variant);
    procedure SetIndexedValue(const AIndex: Integer; const AValue: Variant);
    function AddTNTVariant: Variant;
    function AddNamedTNTValue(const aName: String; const aValue: Variant): variant;
    procedure AddNameValue(const aName: string; const aValue: variant);
    function NameIndex(const aName: string): integer;
    procedure SetPath(const aPath: string; const aValue: variant);
    property Kind: TTNTVariantKind read GetKind;
    property Count: integer read GetCount;
    property Value[const aName: string]: variant read GetValue write SetValue; default;
    property ValueCopy[const aName: string]: variant read GetValueCopy;
    property Item[aIndex: integer]: variant read GetItem write SetItem;
    function ToObject(Instance: TObject): boolean;
  end;
  {$A+}

  TTNTVariant = class(TInvokeableVariantType)
  protected
    {$ifndef FPC}
    {$ifndef ISDELPHI6}
    function FixupIdent(const AText: string): string; override;
    {$endif}
    {$endif}
  public
    procedure Copy(var Dest: TVarData; const Source: TVarData;
      const Indirect: Boolean); override;
    procedure Clear(var V: TVarData); override;
    function GetProperty(var Dest: TVarData; const V: TVarData;
      const Name: string): Boolean; override;
    {$ifdef FPC_VARIANTSETVAR} // see http://mantis.freepascal.org/view.php?id=26773
    function SetProperty(var V: TVarData; const Name: string;
      const Value: TVarData): Boolean; override;
    {$else}
    function SetProperty(const V: TVarData; const Name: string;
      const Value: TVarData): Boolean; override;
    {$endif}
    procedure Cast(var Dest: TVarData; const Source: TVarData); override;
    procedure CastTo(var Dest: TVarData; const Source: TVarData;
      const AVarType: TVarType); override;
  end;

var
  TNTVariantType: TInvokeableVariantType;

function TNTVariant: Variant; overload;
function TNTVariant(const MsgPack: TTNTMsgPack): Variant; overload;
function TNTVariant(const AObject: TObject): Variant; overload;
function TNTVariant(const AArray: ITNTPackerArray): Variant; overload;
function TNTVariant(const AMap: ITNTPackerMap): Variant; overload;
function TNTVariantData(const TNTVariant: Variant): PTNTVariantData;
function TNTObject(const TNTVariant: Variant; AClass: TClass): TObject;
function TNTVariantDataSafe(const TNTVariant: variant;
  ExpectedKind: TTNTVariantKind=tvkUndefined): PTNTVariantData;

procedure SetInstanceProp(Instance: TObject; PropInfo: PPropInfo;
  const Value: variant);

implementation

uses Tarantool.UserKeys
, Tarantool.Utils
{$IfNDef FPC}
, Soap.InvokeRegistry
, System.StrUtils
{$EndIf}
;


type
  TTNTParserKind = (
    kNone, kNull, kFalse, kTrue, kString, kInteger, kFloat, kObject, kArray);


procedure TTNTVariantData.Init;
begin
  VType := TNTVariantType.VarType;
  {$ifdef UNICODE}
  _Align := 0;
  {$endif}
  VKind := tvkUndefined;
  VCount := 0;
  pointer(Names) := nil;
  pointer(Values) := nil;
end;



function ParseArray(AMsgPack: TTNTMsgPack): TTNTVariantData; forward;

 function ParseMap(AMsgPack: TTNTMsgPack): TTNTVariantData;
 var i: Integer;
     val: variant;
     key: string;
 begin
   Result.Init;
    for i := 0 to AMsgPack.Count - 1 do
     begin
       key := AMsgPack[i].Name;
       case AMsgPack[i].DataType of
        mptArray: Val := variant(ParseArray(AMsgPack[i]));
        mptMap: Val := Variant(ParseMap(AMsgPack[i]));
       else
        Val := AMsgPack[I].AsVariant;
       end;
       Result.AddNameValue(key, val);
     end;
    Result.VKind := tvkObject;
 end;

 function ParseArray(AMsgPack: TTNTMsgPack): TTNTVariantData;
 var i: Integer;
     val: Variant;
 begin
   Result.Init;
   for I := 0 to AMsgPack.Count - 1 do
     begin
       case AMsgPack[I].DataType of
        mptArray: val := variant(ParseArray(AMsgPack[i]));
        mptMap: Val := Variant(ParseMap(AMsgPack[i]));
       else
         val := AMsgPack[I].AsVariant;
       end;
      Result.AddValue(val);
     end;
  Result.VKind := tvkArray;
 end;




procedure TTNTVariantData.InitFrom(const AMsgPack: TTNTMsgPack);
var V: Variant;
begin
 Init;
 case AMsgPack.DataType of
   mptUnknown: AddNameValue(AMsgPack.Name, Unassigned);
   mptNull: AddNameValue(AMsgPack.Name, Null);
   mptMap: Self := ParseMap(AMsgPack);
   mptArray: Self := ParseArray(AMsgPack);
   mptString: AddNameValue(AMsgPack.Name, AMsgPack.AsString);
   mptInteger: AddNameValue(AMsgPack.Name, AMsgPack.AsInteger);
   mptBoolean: AddNameValue(AMsgPack.Name, AMsgPack.AsBoolean);
   mptFloat: AddNameValue(AMsgPack.Name, AMsgPack.AsFloat);
   mptSingle: AddNameValue(AMsgPack.Name, AMsgPack.AsSingle);
   mptDateTime: AddNameValue(AMsgPack.Name, AMsgPack.AsDateTime);
   mptBinary: AddNameValue(AMsgPack.Name, AMsgPack.AsBytes);
 end;
end;

procedure TTNTVariantData.InitFrom(const aValues: TTNTVariantDynArray);
begin
  Init;
  VKind := tvkArray;
  Values := aValues;
  VCount := Length(aValues);
end;


function ParseIMap(APackerMap: ITNTPackerMap): TTNTVariantData; forward;

function ParseIArray(APackerArray: ITNTPackerArray): TTNTVariantData;
var i: Integer;
    val: Variant;
begin
  Result.Init;
  for I := 0 to APackerArray.Count - 1 do
    begin
     case APackerArray.DataType(I) of
      mptMap: Val := Variant(ParseIMap(APackerArray.UnpackMap(I)));
      mptArray: Val := Variant(ParseIArray(APackerArray.UnpackArray(I)));
      else
       val := APackerArray.UnpackVariant(i);
     end;
      Result.AddValue(Val);
    end;
end;


function ParseIMap(APackerMap: ITNTPackerMap): TTNTVariantData;
var i: Integer;
    val: Variant;
begin
  Result.Init;
  for I := 0 to APackerMap.Count - 1 do
    begin
     case APackerMap.DataType(I) of
      mptMap: Val := Variant(ParseIMap(APackerMap.UnpackMap(APackerMap.Name(I))));
      mptArray: Val := Variant(ParseIArray(APackerMap.UnpackArray(APackerMap.Name(I))));
      else
       val := APackerMap.UnpackVariant(APackerMap.Name(I));
     end;
      Result.AddNameValue(APackerMap.Name(I), Val);
    end;
end;

procedure TTNTVariantData.InitFrom(const APacker: ITNTPackerArray);
var i: Integer;
begin
 Init;
 for I := 0 to APacker.Count - 1 do
   case APacker.DataType(I) of
     mptNull: AddValue(Null);
     mptUnknown: AddValue(Unassigned);
     mptMap: AddValue(Variant(ParseIMap(APacker.UnpackMap(i))));
     mptArray: AddValue(variant(ParseIArray(APacker.UnpackArray(i))));
     mptString: AddValue(APacker.UnpackString(i));
     mptInteger: AddValue(APacker.UnpackInteger(i));
     mptBoolean: AddValue(APacker.UnpackBoolean(i));
   end;
end;

procedure TTNTVariantData.InitFrom(const APacker: ITNTPackerMap);
begin
 Self := ParseIMap(APacker);
end;


procedure TTNTVariantData.Clear;
begin
  Names := nil;
  Values := nil;
  Init;
end;

function TTNTVariantData.AddNamedTNTValue(const aName: String;
  const aValue: Variant): variant;
begin
 TTNTVariantData(Result).Init;
 AddNameValue(aName, aValue);
end;

procedure TTNTVariantData.AddNameValue(const aName: string;
  const aValue: variant);
begin
  if VKind=tvkUndefined then
    VKind := tvkObject else
    if VKind<>tvkObject then
      raise ETNTVariantException.CreateFmt('AddNameValue(%s) over array',[aName]);
  if VCount<=length(Values) then begin
    SetLength(Values,VCount+VCount shr 3+32);
    SetLength(Names,VCount+VCount shr 3+32);
  end;
  Values[VCount] := aValue;
  Names[VCount] := aName;
  inc(VCount);
end;

function TTNTVariantData.AddTNTVariant: Variant;
begin
 TTNTVariantData(Result).Init;
 AddValue(Result);
end;

procedure TTNTVariantData.AddValue(const aValue: variant);
begin
  if VKind=tvkUndefined then
    VKind := tvkArray else
    if VKind<>tvkArray then
      raise ETNTVariantException.Create('AddValue() over object');
  if VCount<=length(Values) then
    SetLength(Values,VCount+VCount shr 3+32);
  Values[VCount] := aValue;
  inc(VCount);
end;


function TTNTVariantData.Data(const aName: string): PTNTVariantData;
var i: integer;
begin
  i := NameIndex(aName);
  if (i<0) or (TVarData(Values[i]).VType<>TNTVariantType.VarType) then
    result := nil else
    result := @Values[i];
end;

function TTNTVariantData.GetKind: TTNTVariantKind;
begin
  if (@self=nil) or (VType<>TNTVariantType.VarType) then
    result := tvkUndefined else
    result := VKind;
end;

function TTNTVariantData.GetCount: integer;
begin
  if (@self=nil) or (VType<>TNTVariantType.VarType) then
    result := 0 else
    result := VCount;
end;

function TTNTVariantData.GetValue(const aName: string): variant;
begin
  VarClear(result);
  if (@self<>nil) and (VType=TNTVariantType.VarType) and (VKind=tvkObject) then
    GetVarData(aName,TVarData(result));
end;

function TTNTVariantData.GetValueCopy(const aName: string): variant;
var i: cardinal;
begin
  VarClear(result);
  if (@self<>nil) and (VType=TNTVariantType.VarType) and (VKind=tvkObject) then begin
    i := cardinal(NameIndex(aName));
    if i<cardinal(length(Values)) then
      result := Values[i];
  end;
end;

function TTNTVariantData.GetItem(aIndex: integer): variant;
begin
  VarClear(result);
  if (@self<>nil) and (VType=TNTVariantType.VarType) and (VKind=tvkArray) then
    if cardinal(aIndex)<cardinal(VCount) then
      result := Values[aIndex];
end;

procedure TTNTVariantData.SetIndexedValue(const AIndex: Integer;
  const AValue: Variant);
begin
  if VKind=tvkUndefined then
    VKind := tvkArray else
    if VKind<>tvkArray then
      raise ETNTVariantException.Create('SetIndexedValue() over object');
  if AIndex >= VCount then
   if (VCount+AIndex) >=length(Values) then
     SetLength(Values,(VCount+AIndex)+VCount shr 3+32);
  Values[AIndex] := aValue;
  if AIndex >= VCount then
    VCount := AIndex+1;
end;

procedure TTNTVariantData.SetItem(aIndex: integer; const aItem: variant);
begin
  if (@self<>nil) and (VType=TNTVariantType.VarType) and (VKind=tvkArray) then
    if cardinal(aIndex)<cardinal(VCount) then
      Values[aIndex] := aItem;
end;

function TTNTVariantData.GetVarData(const aName: string;
  var Dest: TVarData): boolean;
var i: cardinal;
begin
  i := cardinal(NameIndex(aName));
  if i<cardinal(length(Values)) then begin
    Dest.VType := varVariant or varByRef;
    Dest.VPointer := @Values[i];
    result := true;
  end else
    result := false;
end;

function TTNTVariantData.NameIndex(const aName: string): integer;
begin
  if (@self<>nil) and (VType=TNTVariantType.VarType) and (Names<>nil) then
    for result := 0 to VCount-1 do
      if Names[result]=aName then
        exit;
  result := -1;
end;

procedure TTNTVariantData.PackToMessage(const APacker: ITNTPackerArray);
begin
 APacker.AsBytes := ToMsgPack.EncodeToBytes;
end;

procedure TTNTVariantData.SetPath(const aPath: string; const aValue: variant);
var i: integer;
begin
  for i := length(aPath) downto 1 do 
    if aPath[i]='.' then begin
      EnsureData(copy(aPath,1,i-1))^.SetValue(copy(aPath,i+1,maxInt),aValue);
      exit;
    end;
  SetValue(aPath,aValue);
end;


function TTNTVariantData.EnsureData(const aPath: string): PTNTVariantData;
var i: integer;
    new: TTNTVariantData;
begin
  i := Pos('.',aPath);
  if i=0 then begin
    i := NameIndex(aPath);
    if i<0 then begin
      new.Init;
      AddNameValue(aPath,variant(new));
      result := @Values[VCount-1];
    end else begin
      if TVarData(Values[i]).VType<>TNTVariantType.VarType then begin
        VarClear(Values[i]);
        TTNTVariantData(Values[i]).Init;
      end;
      result := @Values[i];
    end;
  end else
    result := EnsureData(copy(aPath,1,i-1))^.EnsureData(copy(aPath,i+1,maxInt));
end;

function TTNTVariantData.AddItem: PTNTVariantData;
var new: TTNTVariantData;
begin
  new.Init;
  AddValue(variant(new));
  result := @Values[VCount-1];
end;

procedure TTNTVariantData.SetValue(const aName: string;
  const aValue: variant);
var i: integer;
begin
  if @self=nil then
    raise ETNTVariantException.Create('Unexpected Value[] access');
  if aName='' then
    raise ETNTVariantException.Create('Unexpected Value['''']');
  i := NameIndex(aName);
  if i<0 then
    AddNameValue(aName,aValue) else
    Values[i] := aValue;
end;





function TTNTVariantData.ToMsgPack: TTNTMsgPack;
var i: Integer;
    vt: Word;
begin
 Result := nil;
 if VKind = tvkObject then
 begin
  Result := TTNTMsgPack.Create(mptMap);
  for I := 0 to VCount - 1 do
    begin
      vt := VarType(Values[I]);
      if vt = TNTVariantType.VarType then
       begin
         Result.O[Names[I]] := TTNTVariantData(Values[I]).ToMsgPack;
       end else
        Result.O[Names[I]] := MPO(Values[i]);
    end;
 end
 else
 if VKind = tvkArray then
 begin
  Result := TTNTMsgPack.Create(mptArray);
  for I := 0 to VCount - 1 do
    begin
      vt := VarType(Values[I]);
      if vt = TNTVariantType.VarType then
       begin
         Result.Add(TTNTVariantData(Values[I]).ToMsgPack);
       end else
        Result.AddArrayChild.AsVariant := Values[i];
    end;
 end else
  Result := TTNTMsgPack.Create(mptArray);
end;

type
  PTObject = ^TObject;

procedure ReadRow(AInfo: PTypeInfo; var CurElement: Integer; ASize: Integer; AData: Pointer; AValue: Variant);
var i: Integer;
    TypeData: PTypeData;
    v: Variant;
begin
  if AInfo^.Kind = tkClass then
   begin
    for i := 0 to ASize - 1 do
    begin
     PTObject(AData)^ := TNTObject(TTNTVariantData(AValue).Item[i], GetTypeData(AInfo)^.ClassType);
     AData := Pointer(NativeUInt(AData) + SizeOf(Pointer));
     Inc(CurElement);
    end;
   end else
  if AInfo^.Kind = tkVariant then
  begin
   for i := 0 to ASize - 1 do
   begin
    Variant(PVarData(AData)^) := TTNTVariantData(AValue).Item[i];
    AData := Pointer(NativeUInt(AData) + TypeData^.elSize);
   end;
  end else
  begin
    TypeData := GetTypeData(AInfo);
    for i := 0 to ASize - 1 do
      begin
        v := TTNTVariantData(AValue).Item[i];
        case AInfo^.Kind of
          tkInteger: case TypeData^.OrdType of
                      otSByte, otUByte:  PByte(AData)^ := v;
                      otSWord, otUWord: PSmallInt(AData)^ := v;
                      otSLong, otULong: PInteger(AData)^ := v;
                     end;
          tkFloat: case TypeData^.FloatType of
                     ftSingle: PSingle(AData)^ := v;
                     ftDouble: PDouble(AData)^ := V;
                     ftComp: PComp(AData)^ := v;
                     ftCurr: PCurrency(AData)^ := v;
                     ftExtended: PExtended(AData)^ := v;
                   end;
          tkWString: PWideString(AData)^ := v;
          tkString: PShortString(AData)^ := v;
          tkLString: PAnsiString(AData)^ := v;
          tkUString: PUnicodeString(AData)^ := v;
          tkInt64: PInt64(AData)^ := v;
          tkEnumeration: PByte(AData)^ := GetEnumValue(AInfo, v);
        end;
        AData := Pointer(NativeUInt(AData) + TypeData^.elSize);
      end;
  end;
end;

function  ConvertVariantToNativeArrayElem(ArrayInfo, ElemInfo: PTypeInfo; Dims, CurDim: Integer; AData: Pointer; AValue: Variant): Pointer;
var
  LDyn: Pointer;
  PElem: Pointer;
  PChild: Pointer;
  CurElement: Integer;
  Len, I: Integer;
begin
 if AData <> nil then
 begin
  if Dims > 1 then
  begin
    LDyn := Pointer(AData^);
    Len := TTNTVariantData(AValue).Count;
    DynArraySetLength(LDyn, ArrayInfo, 1, @Len);
    Result := LDyn;
    PElem := LDyn;
    Dec(Dims);
    CurElement := 0;
    for i := 0 to Len -1 do
      begin
       PChild := ConvertVariantToNativeArrayElem(GetDynArrayNextInfo(ArrayInfo), ElemInfo, Dims, CurDim, PElem, TTNTVariantData(AValue).Values[I]);
       Pointer(PElem^) := PChild;
       PElem := Pointer(NativeUInt(PElem) + SizeOf(pointer));
      end;
  end else if Dims = 1 then
  begin
    LDyn := Pointer(AData^);

    Len := TTNTVariantData(AValue).Count;
    DynArraySetLength(LDyn, ArrayInfo, 1, @Len);
    Result := LDyn;
    PElem := LDyn;
    CurElement := 0;
    if Len > 0 then
     ReadRow(ElemInfo, CurElement, Len, PElem, AValue);
  end;
 end;
end;


function ConvertVariantToNativeArray(AData: Pointer; ATypeInfo: PTypeInfo; AValue: Variant): Pointer;
var
   ElemInfo: PTypeInfo;
   Dims: Integer;
begin
  GetDynArrayElementTypeInfo(ATypeInfo, ElemInfo, Dims);
  Result := ConvertVariantToNativeArrayElem(ATypeInfo, ElemInfo, Dims, 0, AData, AValue);
end;

procedure SetInstanceProp(Instance: TObject; PropInfo: PPropInfo;
  const Value: variant);
var
    obj: TObject;
    ArrayPtr: Pointer;
    PropType: PTypeInfo;
begin
  if (PropInfo<>nil) and (Instance<>nil) then
  begin
    PropType := {$IfDef FPC}PropInfo^.PropType{$Else}PropInfo^.PropType^{$EndIf};

      case PropInfo^.PropType^.Kind of
      tkInt64{$ifdef FPC}, tkQWord{$endif}:
        if TVarData(Value).VType=varInt64 then
          SetInt64Prop(Instance,PropInfo,TVarData(Value).VInt64) else
          SetOrdProp(Instance,PropInfo,Value);
      tkEnumeration: if PropInfo^.PropType^.Name = 'Boolean' then
                        SetOrdProp(Instance, PropInfo, Ord(StrToBoolDef(VarToStr(Value), false)))
                      else
                        SetEnumProp(Instance, PropInfo, Value);
      tkInteger, tkSet:
        SetOrdProp(Instance,PropInfo,Value);
      {$ifdef NEXTGEN}
      tkUString:
        if TVarData(Value).VType<=varNull then
          SetStrProp(Instance,PropInfo,'') else
          SetStrProp(Instance,PropInfo,Value);
      {$else}
      {$ifdef FPC}tkAString,{$endif} tkLString:
        if TVarData(Value).VType<=varNull then
          SetStrProp(Instance,PropInfo,'') else
          SetStrProp(Instance,PropInfo,Value);
      tkWString:
        if TVarData(Value).VType<=varNull then
          SetWideStrProp(Instance,PropInfo,'') else
          SetWideStrProp(Instance,PropInfo,Value);
      {$ifdef UNICODE}
      tkUString:
        if TVarData(Value).VType<=varNull then
          SetUnicodeStrProp(Instance,PropInfo,'') else
          SetUnicodeStrProp(Instance,PropInfo,Value);
      {$endif UNICODE}
      {$endif NEXTGEN}
      tkFloat:
          SetFloatProp(Instance,PropInfo,Value);
      tkVariant:
        SetVariantProp(Instance,PropInfo,Value);
      tkDynArray: begin
                    ArrayPtr := nil;
                    ArrayPtr := ConvertVariantToNativeArray(@ArrayPtr, PropType, Value);
                    SetDynArrayProp(Instance, PropInfo, ArrayPtr);
                  end;
      tkClass: begin
        obj := GetObjectProp(Instance, PropInfo);
        if TVarData(Value).VType>varNull then
          if obj=nil then begin
            obj := TNTObject(Value, GetTypeData(PropType)^.ClassType);
            if obj<>nil then
              SetOrdProp(Instance,PropInfo,NativeInt(obj));
          end else
            TNTVariantData(Value)^.ToObject(obj);
      end;

      end;

  end;
end;


function TTNTVariantData.ToObject(Instance: TObject): boolean;
var i: Integer;
begin
 Result := false;
 if Instance = nil then
  Exit;
 case VKind of
   tvkUndefined: ;
   tvkObject: for i := 0 to Count - 1 do
                SetInstanceProp(Instance, GetPropInfo(Instance, Names[i]), Values[I]);
   tvkArray: ;
 end;

end;

{ TJSONVariant }

procedure TTNTVariant.Cast(var Dest: TVarData; const Source: TVarData);
begin
  CastTo(Dest,Source,VarType);
end;

procedure TTNTVariant.CastTo(var Dest: TVarData; const Source: TVarData;
  const AVarType: TVarType);
begin
  if Source.VType<>VarType then
    RaiseCastError;
end;

procedure TTNTVariant.Clear(var V: TVarData);
begin
  V.VType := varEmpty;
  Finalize(TTNTVariantData(V).Names);
  Finalize(TTNTVariantData(V).Values);
end;

procedure TTNTVariant.Copy(var Dest: TVarData; const Source: TVarData;
  const Indirect: Boolean);
begin
  if Indirect then
    SimplisticCopy(Dest,Source,true) else begin
    VarClear(variant(Dest));
    TTNTVariantData(Dest).Init;
    TTNTVariantData(Dest) := TTNTVariantData(Source);
  end;
end;

{$ifndef FPC}
{$ifndef ISDELPHI6}
function TTNTVariant.FixupIdent(const AText: string): string;
begin // we expect the names to be case-sensitive
  result := AText;
end;
{$endif}
{$endif}

function TTNTVariant.GetProperty(var Dest: TVarData; const V: TVarData;
  const Name: string): Boolean;
begin
  if not TTNTVariantData(V).GetVarData(Name,Dest) then
    Dest.VType := varNull;
  result := true;
end;

{$ifdef FPC_VARIANTSETVAR}
function TTNTVariant.SetProperty(var V: TVarData; const Name: string;
  const Value: TVarData): Boolean;
{$else}
function TTNTVariant.SetProperty(const V: TVarData; const Name: string;
  const Value: TVarData): Boolean;
{$endif}
begin
  {$ifdef FPC}
  {$ifndef FPC_VARIANTSETVAR} 
  raise ETNTVariantExceptionException.Create('Not worked in FPC!');
  {$endif}
  {$endif}
  TTNTVariantData(V).SetValue(Name,variant(Value));
  result := true;
end;


function TNTVariant: Variant;
begin
  TTNTVariantData(Result).Init;
end;


function TNTVariant(const MsgPack: TTNTMsgPack): Variant; overload;
begin
  TTNTVariantData(Result).InitFrom(MsgPack);
end;

function TNTVariant(const AArray: ITNTPackerArray): Variant; overload;
begin
  TTNTVariantData(Result).InitFrom(AArray);
end;

function TNTVariant(const AMap: ITNTPackerMap): Variant; overload;
begin
  TTNTVariantData(Result).InitFrom(AMap);
end;


function TNTVariantData(const TNTVariant: Variant): PTNTVariantData;
begin
  with TVarData(TNTVariant) do
    if VType=TNTVariantType.VarType then
      result := @TNTVariant else
    if VType=varByRef or varVariant then
      result := TNTVariantData(PVariant(VPointer)^) else
    raise ETNTVariantException.CreateFmt('TNTVariantData.Data(%d<>TNTVariant)',[VType]);
end;

const // will be in code section of the exe, so will be read-only by design
  TNTVariantDataFake: TTNTVariantData = ();

function TNTVariantDataSafe(const TNTVariant: variant;
  ExpectedKind: TTNTVariantKind=tvkUndefined): PTNTVariantData;
begin
  with TVarData(TNTVariant) do
    if VType=TNTVariantType.VarType then
      if (ExpectedKind=tvkUndefined) or
         (TTNTVariantData(TNTVariant).VKind=ExpectedKind) then
        result := @TNTVariant else
        result := @TNTVariantDataFake else
    if VType=varByRef or varVariant then
      result := TNTVariantDataSafe(PVariant(VPointer)^) else
      result := @TNTVariantDataFake;
end;

procedure WriteRectDynArrayElem(Info: PTypeInfo; Size, Dim: Integer; P: Pointer; Arr: PTNTVariantData);
var i: Integer;
    ElemSize: Integer;
    TypeData: PTypeData;
    L: Variant;
    V: PTNTVariantData;
begin
  TypeData := GetTypeData(Info);
  if Dim > 1 then
   begin
     Dec(Dim);
     for i := 0 to Size - 1 do
       begin
         ElemSize := GetDynArrayLength(Pointer(P^));
         TTNTVariantData(L).Init;
         V := TNTVariantDataSafe(L);
         WriteRectDynArrayElem(Info, ElemSize, Dim, Pointer(P^), V);
         Arr^.AddNameValue(I.ToString, L);
         P := Pointer(NativeUInt(P) + sizeof(Pointer));
       end;
   end else
   begin
     for i := 0 to Size - 1 do
       begin
         if Info^.Kind = tkClass then
         begin
           Arr^.AddValue(TNTVariant(TObject(P^)));
           P := Pointer( NativeUInt(P) + SizeOf(Pointer));
           Continue
         end
         else
         case info^.Kind of
          tkInteger: case TypeData^.OrdType of
                      otSByte, otUByte: Arr^.AddValue(Byte(P^));
                      otSWord, otUWord: Arr^.AddValue(SmallInt(P^));
                      otSLong, otULong: Arr^.AddValue(Integer(P^));
                     end;
          tkFloat:   case TypeData^.FloatType of
                      ftSingle: Arr^.AddValue(Single(P^));
                      ftDouble: Arr^.AddValue(Double(P^));
                     end;
          tkInt64: Arr^.AddValue(Int64(P^));
          tkChar: Arr^.AddValue(Char(P^));
          tkWChar: Arr^.AddValue(WideChar(P^));
          tkWString: Arr^.AddValue(PWideString(P)^);
          tkString: Arr^.AddValue(PShortString(P)^);
          tkLString: Arr^.AddValue(PAnsiString(P)^);
          tkUString: Arr^.AddValue(PUnicodeString(P)^);
         end;

         P := Pointer( NativeUInt(P) + TypeData^.elSize);
       end;
   end;

end;


procedure WriteNonRectDynArray(Info: PTypeInfo; P: Pointer; Dim: Integer; Arr: PTNTVariantData); forward;

procedure WriteNonRectDynArrayElem(Info: PTypeInfo; P: Pointer; Dim: Integer; Arr: PTNTVariantData);
begin
 if (Dim > 0)  or (Info^.Kind = tkDynArray) then
   WriteNonRectDynArray(Info, P, Dim, Arr)
 else
   WriteRectDynArrayElem(Info, 1, 1, P, Arr);

end;


procedure WriteNonRectDynArray(Info: PTypeInfo; P: Pointer; Dim: Integer; Arr: PTNTVariantData);
var ElemInfo: PTypeInfo;
    Len: Integer;
    i: Integer;
    PData: Pointer;
    L: Variant;
    V: PTNTVariantData;
begin
  ElemInfo := GetDynArrayNextInfo(Info);
  //if ArrayIsNull(P) then
  //   CreateEmptyArray
  Len := GetDynArrayLength(P);

  for i := 0 to Len - 1 do
  begin
    if ElemInfo^.Kind = tkDynArray then
    begin
      PData := Pointer(P^);
      TTNTVariantData(L).Init;
      V := TNTVariantDataSafe(L, tvkUndefined);
      WriteNonRectDynArrayElem(ElemInfo, PData, Dim - 1, V);
      Arr^.AddValue(L);
    end
     else
    begin
      PData := P;
      WriteNonRectDynArrayElem(ElemInfo, PData, Dim - 1, Arr);
    end;


    if ElemInfo^.Kind = tkClass then
      P := Pointer(NativeUInt(P) + SizeOf(Pointer))
    else
      P := Pointer(NativeUInt(P) +  GetTypeData(ElemInfo)^.elSize);
  end;

end;


function DynArrayToTNTVariant(Info: PTypeInfo; P: Pointer): Variant;
var
  ElemInfo: PTypeInfo;
  Dims: Integer;
  UseNonRect: Boolean;
  DimArr: TNativeIntDynArray;
begin
  TTNTVariantData(Result).Init;
  GetDynArrayElementTypeInfo(Info, ElemInfo, Dims);
  UseNonRect := Assigned(P) and ((IsArrayRect(P, Dims)=False) or (Dims > 1));
  if UseNonRect then
   begin
     WriteNonRectDynArray(Info, P, Dims, TNTVariantDataSafe(Result));
   end
  else
   begin
     SetLength(DimArr, Dims);
     if Assigned(P) then
      GetDims(P, DimArr, Dims);
     WriteRectDynArrayElem(ElemInfo, GetDynArrayLength(P), Dims, P, TNTVariantDataSafe(Result));
   end;
end;

function TNTVariant(const AObject: TObject): Variant; overload;
var
  C, I: Integer;
  PI: PPropInfo;
  PL: PPropList;
  Obj: TObject;
  P: Pointer;
  D: Integer;
begin
 Result:= Unassigned;
 if Assigned(AObject) then
 begin
   TTNTVariantData(Result).Init;
   Pl := nil;
   C := GetPropList(PTypeInfo(AObject.ClassInfo), PL);
   if Assigned(PL) and (C > 0) then
   begin
     try
       for I := 0 to Pred(C) do
        begin
          PI := PL^[I];
            case PI^.PropType^.Kind of
              tkInteger: TTNTVariantData(Result).AddNameValue(pi^.Name, GetOrdProp(AObject, PI));
              tkInt64: TTNTVariantData(Result).AddNameValue(pi^.Name, GetInt64Prop(AObject, PI));
              tkString, tkUString: TTNTVariantData(Result).AddNameValue(pi^.Name, GetStrProp(AObject, PI));
              tkEnumeration: begin
                if PI^.PropType^.Name = 'Boolean' then
                  TTNTVariantData(Result).AddNameValue(pi^.Name, GetOrdProp(AObject, PI) = 1)
                else
                  TTNTVariantData(Result).AddNameValue(pi^.Name, GetEnumProp(AObject, PI));

              end;
              tkClass: Begin
                         Obj := GetObjectProp(AObject, PI);
                         if Assigned(Obj) then
                         {$IfNDef FPC}
                          if Obj.InheritsFrom(TRemotableXS) then
                           TTNTVariantData(Result).AddNameValue(pi^.Name, TRemotableXS(Obj).NativeToXS)
                          else
                         {$EndIf}
                           TTNTVariantData(Result).AddNameValue(pi^.Name, TNTVariant(Obj));
                       End;
              tkDynArray: begin
                            P := Pointer(GetDynArrayProp(AObject, PI));
                            if Assigned(P) then
                              TTNTVariantData(Result).AddNameValue(pi^.Name, DynArrayToTNTVariant(PI^.PropType{$IfNDef FPC}^{$EndIf}, P));
                          end;
            end;
          end;
     finally
      FreeMem(PL);
     end;
   end;
 end;
end;

function TNTObject(const TNTVariant: Variant; AClass: TClass): TObject;
begin
  Result := nil;
{$IfNDef FPC}
  if AClass.InheritsFrom(TRemotableXS) then
   begin
     Result := AClass.Create;
     TRemotableXS(Result).XSToNative(TNTVariant);
   end else
{$EndIf}
  if VarType(TNTVariant) = TNTVariantType.VarType then
   begin
     Result := AClass.Create;
     TTNTVariantData(TNTVariant).ToObject(Result);
   end;
end;

initialization
  TNTVariantType := TTNTVariant.Create;
end.
