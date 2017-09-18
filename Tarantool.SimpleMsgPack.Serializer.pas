unit Tarantool.SimpleMsgPack.Serializer;

interface

uses Tarantool.SimpleMsgPack, System.TypInfo;

function ObjectToMsgPack(AObject: TObject): TTNTMsgPack;
function MsgPackToObject(AMsgPack: TTNTMsgPack; AObjectClass: TClass): TObject; overload;
procedure MsgPackToObject(AInstance: TObject; AMsgPack: TTNTMsgPack); overload;

type
  TObjectHelper = class helper for TObject
  private
    function GetAsMsgPack: TTNTMsgPack;
    procedure SetAsMsgPack(const Value: TTNTMsgPack);
  public
    property AsMsgPack: TTNTMsgPack read GetAsMsgPack write SetAsMsgPack;
  end;

implementation
uses
  System.SysUtils,
  System.Classes,
  System.RTTI,
  System.Types,
  Soap.InvokeRegistry,
  Tarantool.Utils;


type
  TTestObject = class;
  TTestArray = array of TTestObject;
  TByteArray = array of Byte;
  TTestObject = class
  private
    FStr: string;
    FId: Integer;
    FObj: TTestObject;
    FArr: TTestArray;
    FArr2: TByteArray;
  public
    function Add(AObj: TObject): Integer;
    function Add2(AByte: Byte): Integer;
  published
    property Id: Integer index 1 read FId write FId;
    property Str: string index 2 read FStr write FStr;
    property Obj: TTestObject read FObj write FObj;
    property Arr: TTestArray read FArr write FArr;
    property Arr2: TByteArray read FArr2 write FArr2;
  end;


function SortProperties(Item1, Item2: Pointer): Integer;
begin
  if PPropInfo(Item1)^.Index > PPropInfo(Item2)^.Index then
   Result := 1
  else
  if PPropInfo(Item1)^.Index < PPropInfo(Item2)^.Index then
   Result := -1
  else
   Result := 0;
end;



procedure WriteRectDynArrayElem(Info: PTypeInfo; Size, Dim: Integer; P: Pointer; Arr: TTNTMsgPack);
var i: Integer;
    ElemSize: Integer;
    TypeData: PTypeData;
begin
  TypeData := GetTypeData(Info);
  if Dim > 1 then
   begin
     Dec(Dim);
     for i := 0 to Size - 1 do
       begin
         ElemSize := GetDynArrayLength(Pointer(P^));
         Arr.AddArrayChild.OO[I] := TTNTMsgPack.Create(mptArray);
         WriteRectDynArrayElem(Info, ElemSize, Dim, Pointer(P^), Arr.AddArrayChild.OO[I]);
         P := Pointer(NativeUInt(P) + sizeof(Pointer));
       end;
   end else
   begin
     for i := 0 to Size - 1 do
       begin
         if Info.Kind = tkClass then
         begin
           Arr.Add(ObjectToMsgPack(TObject(P^)));
           //AddArrayChild.OO[I] := ObjectToMsgPack(TObject(P^));
           P := Pointer( NativeUInt(P) + SizeOf(Pointer));
           Continue
         end
         else
         case info^.Kind of
          tkInteger: case TypeData.OrdType of
                      otSByte, otUByte: Arr.AddArrayChild.AsInteger := Byte(P^);
                      otSWord, otUWord: Arr.AddArrayChild.AsInteger := SmallInt(P^);
                      otSLong, otULong: Arr.AddArrayChild.AsInteger := Integer(P^);
                     end;
          tkFloat:   case TypeData.FloatType of
                      ftSingle: Arr.AddArrayChild.AsSingle := Single(P^);
                      ftDouble: Arr.AddArrayChild.AsFloat := Double(P^);
                     end;
          tkInt64: Arr.AddArrayChild.AsInteger :=Int64(P^);
          tkChar: Arr.AddArrayChild.AsString := Char(P^);
          tkWChar: Arr.AddArrayChild.AsString := WideChar(P^);
          tkWString: Arr.AddArrayChild.AsString := PWideString(P)^;
          tkString: Arr.AddArrayChild.AsString := PShortString(P)^;
          tkLString: Arr.AddArrayChild.AsString := PAnsiString(P)^;
          tkUString: Arr.AddArrayChild.AsString := PUnicodeString(P)^;
         end;

         P := Pointer( NativeUInt(P) + TypeData.elSize);
       end;
   end;

end;

type
  TArrayElemDesc = record
    MultiDim: Boolean;
    Dims: TNativeIntDynArray;
  end;
  TArrayDesc = array of TArrayElemDesc;


procedure ParseDims(DimString: InvString; var Dims: TArrayDesc);
var
  I, J: Integer;
  CurDim, NumDims, SubDims, SubDim: Integer;
  StrLen: Integer;
  DimSize: InvString;
begin
  CurDim := 0;
  NumDims := 0;
  StrLen := High(DimString);
  for I := Low(string) to StrLen do
    if DimString[I] = '[' then      { do not localize }
      Inc(NumDims);
  SetLength(Dims, NumDims);
  I := Low(string);
  while I < StrLen do
  begin
    if DimString[I] = '[' then       { do not localize }
    begin
      DimSize := '';
      Inc(I);
      SubDims := 1;
      SubDim := 0;
      if DimString[I] = ']' then               { do not localize }
        SetLength(Dims[CurDim].Dims, 1);
      while (DimString[I] <> ']') and (I < StrLen) do     { do not localize }
      begin
        J := I;
        while (DimString[J] <> ']') and (J < StrLen) do       { do not localize }
        begin
          if DimString[J] = ',' then
            Inc(SubDims);
          Inc(J);
        end;
        SetLength(Dims[CurDim].Dims, SubDims);
        if SubDims > 1 then
        begin
          Dims[CurDim].MultiDim := True;
          while (DimString[I] <> ']') and (I < StrLen) do     { do not localize }
          begin
            DimSize := '';
            while (DimString[I] <> ',') and (DimString[I] <> ']') and (I < StrLen) do   { do not localize }
            begin
              DimSize := DimSize + DimString[I];
              Inc(I);
            end;
            if DimString[I] = ',' then
              Inc(I);
            if Trim(DimSize) <> '' then
              Dims[CurDim].Dims[SubDim] := StrToInt(trim(DimSize))
            else
              Dims[CurDim].Dims[SubDim] := 0;
            Inc(SubDim);
          end
        end else
        begin
          while (DimString[I] <> ']') and (I < StrLen) do      { do not localize }
          begin
            DimSize := DimSize + DimString[I];
            Inc(I);
          end;
          if Trim(DimSize) <> '' then
            Dims[CurDim].Dims[SubDim] := StrToInt(trim(DimSize))
          else
            Dims[CurDim].Dims[SubDim] := 0;
        end;
      end;
      Inc(I);
      Inc(CurDim);
    end else
      Inc(I);
  end;
end;

procedure WriteNonRectDynArray(Info: PTypeInfo; P: Pointer; Dim: Integer; Arr: TTNTMsgPack); forward;

procedure WriteNonRectDynArrayElem(Info: PTypeInfo; P: Pointer; Dim: Integer; Arr: TTNTMsgPack);
begin
 if (Dim > 0)  or (Info.Kind = tkDynArray) then
   WriteNonRectDynArray(Info, P, Dim, Arr)
 else
   WriteRectDynArrayElem(Info, 1, 1, P, Arr);

end;


procedure WriteNonRectDynArray(Info: PTypeInfo; P: Pointer; Dim: Integer; Arr: TTNTMsgPack);
var ElemInfo: PTypeInfo;
    Len: Integer;
    i: Integer;
    PData: Pointer;
    vArr: TTNTMsgPack;
begin
  ElemInfo := GetDynArrayNextInfo(Info);
  //if ArrayIsNull(P) then
  //   CreateEmptyArray
  Len := GetDynArrayLength(P);
  for i := 0 to Len - 1 do
  begin
    if ElemInfo.Kind = tkDynArray then
    begin
      PData := Pointer(P^);
      vArr := TTNTMsgPack.Create(mptArray);
      Arr.Add(vArr);
    end
     else
    begin
      PData := P;
      vArr := Arr;
    end;

     WriteNonRectDynArrayElem(ElemInfo, PData, Dim - 1, vArr);
    if ElemInfo.Kind = tkClass then
      P := Pointer(NativeUInt(P) + SizeOf(Pointer))
    else
      P := Pointer(NativeUInt(P) +  GetTypeData(ElemInfo).elSize);
  end;

end;


function DynArrayToMsgPack(Info: PTypeInfo; P: Pointer): TTNTMsgPack;
var
  ElemInfo: PTypeInfo;
  Dims: Integer;
  UseNonRect: Boolean;
  DimArr: TNativeIntDynArray;
begin
  Result := TTNTMsgPack.Create(mptArray);
  GetDynArrayElementTypeInfo(Info, ElemInfo, Dims);
  UseNonRect := Assigned(P) and ((IsArrayRect(P, Dims)=False) or (Dims > 1));
  if UseNonRect then
   begin
     WriteNonRectDynArray(Info, P, Dims, Result);
   end
  else
   begin
     SetLength(DimArr, Dims);
     if Assigned(P) then
      GetDims(P, DimArr, Dims);
     WriteRectDynArrayElem(ElemInfo, GetDynArrayLength(P), Dims, P, Result);
   end;
end;

function ObjectToMsgPack(AObject: TObject): TTNTMsgPack;
var
  C, I: Integer;
  PI: PPropInfo;
  PL: PPropList;
  Obj: TObject;
  P: Pointer;
  D: Integer;
begin
 Result := TTNTMsgPack.Create(mptMap);
 if Assigned(AObject) then
 begin
   Pl := nil;
   C := GetPropList(PTypeInfo(AObject.ClassInfo), PL);
   if Assigned(PL) and (C > 0) then
   begin
     try
       for I := 0 to Pred(C) do
        begin
          PI := PL^[I];
            case PI^.PropType^.Kind of
              tkInteger: Result.O[pi^.Name] := MPO(GetOrdProp(AObject, PI));
              tkInt64: Result.O[PI^.Name] := MPO(GetInt64Prop(AObject, PI));
              tkString, tkUString: Result.O[PI^.Name] := MPO(GetStrProp(AObject, PI));
              tkEnumeration: begin
                if PI^.PropType^.Name = 'Boolean' then
                  Result.O[PI^.Name] := MPO(GetOrdProp(AObject, PI) = 1)
                else
                  Result.O[PI^.Name] := MPO(GetEnumProp(AObject, PI));

              end;
              tkClass: Begin
                         Obj := GetObjectProp(AObject, PI);
                         if Assigned(Obj) then
                          if Obj.InheritsFrom(TRemotableXS) then
                           Result.O[PI^.Name] := MPO(TRemotableXS(Obj).NativeToXS)
                          else
                           Result.O[PI^.Name] := ObjectToMsgPack(Obj);
                       End;
              tkDynArray: begin
                            P := Pointer(GetDynArrayProp(AObject, PI));
                            if Assigned(P) then
                              Result.O[PI^.Name] := DynArrayToMsgPack((PI^.PropType)^, P);
                          end;
            end;
          end;
     finally
      FreeMem(PL);
     end;
   end;
 end;
end;

procedure Test;
var
  TestObj: TTestObject;
  i: Byte;
begin
 Randomize;
 TestObj := TTestObject.Create;
 TestObj.Id := Random(1000);
 TestObj.Str := 'test string';
 TestObj.Obj := TTestObject.Create;
 TestObj.Obj.Id := Random(2010);
 TestObj.Obj.Str := 'test internal str';
 TestObj.Add(TTestObject.Create);
 TestObj.Obj.Add(TTestObject.Create);
 TestObj.Obj.Arr[0].Id := 1000;
 TestObj.Obj.Add(TTestObject.Create);
 TestObj.Obj.Arr[1].Id := 10001;
 for i := 0 to 100 do
    TestObj.Add2(i);


{$IFDEF  DUMP_MSG_PACK}
 DumpObjMsgPack(ObjectToMsgPack(TestObj), 0, '');
{$EndIf}

end;


{ TTestObject }

function TTestObject.Add(AObj: TObject): Integer;
begin
 SetLength(FArr, Length(FArr) + 1);
 FArr[Length(FArr)-1] := TTestObject(AObj);
 Result := Length(FArr) - 1;
end;

function TTestObject.Add2(AByte: Byte): Integer;
begin
 SetLength(FArr2, Length(FArr2) + 1);
 FArr2[Length(FArr2)-1] := AByte;
 Result := Length(FArr2) - 1;
end;


type
  PTObject = ^TObject;

procedure ReadRow(AInfo: PTypeInfo; var CurElement: Integer; ASize: Integer; AData: Pointer; AValue: TTNTMsgPack);
var i: Integer;
    TypeData: PTypeData;
    v: TTNTMsgPack;
begin
  if AInfo^.Kind = tkClass then
   begin
    for i := 0 to ASize - 1 do
    begin
     PTObject(AData)^ := MsgPackToObject(AValue[I], GetTypeData(AInfo).ClassType);
     AData := Pointer(NativeUInt(AData) + SizeOf(Pointer));
     Inc(CurElement);
    end;
   end else
  if AInfo.Kind = tkVariant then
  begin
   for i := 0 to ASize - 1 do
   begin
    Variant(PVarData(AData)^) := AValue[I].AsVariant;
    AData := Pointer(NativeUInt(AData) + TypeData^.elSize);
   end;
  end else
  begin
    TypeData := GetTypeData(AInfo);
    for i := 0 to ASize - 1 do
      begin
        v := AValue[I];
        case AInfo.Kind of
          tkInteger: case TypeData^.OrdType of
                      otSByte, otUByte:  PByte(AData)^ := v.AsInteger;
                      otSWord, otUWord: PSmallInt(AData)^ := v.AsInteger;
                      otSLong, otULong: PInteger(AData)^ := v.AsInteger;
                     end;
          tkFloat: case TypeData^.FloatType of
                     ftSingle: PSingle(AData)^ := v.AsFloat;
                     ftDouble: PDouble(AData)^ := V.AsFloat;
                     ftComp: PComp(AData)^ := v.AsFloat;
                     ftCurr: PCurrency(AData)^ := v.AsFloat;
                     ftExtended: PExtended(AData)^ := v.AsFloat;
                   end;
          tkWString: PWideString(AData)^ := v.AsString;
          tkString: PShortString(AData)^ := v.AsString;
          tkLString: PAnsiString(AData)^ := v.AsString;
          tkUString: PUnicodeString(AData)^ := v.AsString;
//          tkChar: PChar(AData)^ := Char(v);
//          tkWChar: PWideChar(AData)^ := v;
          tkInt64: PInt64(AData)^ := v.AsInteger;
          tkEnumeration: PByte(AData)^ := GetEnumValue(AInfo, v.AsString);
        end;
        AData := Pointer(NativeUInt(AData) + TypeData^.elSize);
      end;
  end;
end;


function  ConvertMsgPackToNativeArrayElem(ArrayInfo, ElemInfo: PTypeInfo; Dims, CurDim: Integer; AData: Pointer; AValue: TTNTMsgPack): Pointer;
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
    Len := AValue.Count;
    DynArraySetLength(LDyn, ArrayInfo, 1, @Len);
    Result := LDyn;
    PElem := LDyn;
    Dec(Dims);
    CurElement := 0;
    for i := 0 to Len -1 do
      begin
       PChild := ConvertMsgPackToNativeArrayElem(GetDynArrayNextInfo(ArrayInfo), ElemInfo, Dims, CurDim, PElem, AValue[I]);
       Pointer(PElem^) := PChild;
       PElem := Pointer(NativeUInt(PElem) + SizeOf(pointer));
      end;
  end else if Dims = 1 then
  begin
    LDyn := Pointer(AData^);

    Len := AValue.Count;
    DynArraySetLength(LDyn, ArrayInfo, 1, @Len);
    Result := LDyn;
    PElem := LDyn;
    CurElement := 0;
    if Len > 0 then
     ReadRow(ElemInfo, CurElement, Len, PElem, AValue);
  end;
 end;
end;


function ConvertMsgPackToNativeArray(AData: Pointer; ATypeInfo: PTypeInfo; AValue: TTNTMsgPack): Pointer;
var
   ElemInfo: PTypeInfo;
   Dims: Integer;
begin
  GetDynArrayElementTypeInfo(ATypeInfo, ElemInfo, Dims);
  Result := ConvertMsgPackToNativeArrayElem(ATypeInfo, ElemInfo, Dims, 0, AData, AValue);
end;


procedure SetInstanceProp(AInstance: TObject; APropInfo: PPropInfo; AMsgPack: TTNTMsgPack);
var
    obj: TObject;
    ArrayPtr: Pointer;
begin
  if (APropInfo<>nil) and (AInstance<>nil) then
  case APropInfo^.PropType^.Kind of
  tkInt64{$ifdef FPC}, tkQWord{$endif}:
      SetInt64Prop(AInstance,APropInfo,AMsgPack.AsInteger);
  tkEnumeration: if APropInfo^.PropType^.Name = 'Boolean' then
                    SetOrdProp(AInstance, APropInfo, Ord(AMsgPack.AsBoolean))
                  else
                    SetEnumProp(AInstance, APropInfo, AMsgPack.AsString);
  tkInteger, tkSet:
    SetOrdProp(AInstance,APropInfo,AMsgPack.AsInteger);
  {$ifdef NEXTGEN}
  tkUString: SetStrProp(AInstance,APropInfo,AMsgPack.AsString);
  {$else}
  {$ifdef FPC}tkAString,{$endif} tkLString: SetStrProp(AInstance,APropInfo,AMsgPack.AsString);
  tkWString:
      SetWideStrProp(AInstance,APropInfo,AMsgPack.AsString);
  {$ifdef UNICODE}
  tkUString:
      SetUnicodeStrProp(AInstance,APropInfo,AMsgPack.AsString);
  {$endif UNICODE}
  {$endif NEXTGEN}
  tkFloat:
      SetFloatProp(AInstance,APropInfo,AMsgPack.AsFloat);
  tkVariant:
    SetVariantProp(AInstance,APropInfo,AMsgPack.AsVariant);
  tkDynArray: begin
                ArrayPtr := nil;
                ArrayPtr := ConvertMsgPackToNativeArray(@ArrayPtr, APropInfo^.PropType^, AMsgPack);
                SetDynArrayProp(AInstance, APropInfo, ArrayPtr);
              end;
  tkClass: begin
            obj := GetObjectProp(AInstance, APropInfo);
             if obj<>nil then
              FreeAndNil(obj);
            obj := MsgPackToObject(AMsgPack, GetTypeData(APropInfo^.PropType^).ClassType);
             if obj<>nil then
              SetOrdProp(AInstance,APropInfo,NativeInt(obj));
           end;
  end;
end;

function MsgPackToObject(AMsgPack: TTNTMsgPack; AObjectClass: TClass): TObject;
var i: Integer;
begin

 if AMsgPack.DataType = mptMap then
  begin
    Result := AObjectClass.Create;
    for I := 0 to AMsgPack.Count - 1 do
      begin
        SetInstanceProp(Result, GetPropInfo(Result, AMsgPack[i].Name), AMsgPack[i]);
      end;
  end;
end;

procedure MsgPackToObject(AInstance: TObject; AMsgPack: TTNTMsgPack);
var i: Integer;
begin
 if AMsgPack.DataType = mptMap then
  begin
    for I := 0 to AMsgPack.Count - 1 do
      begin
        SetInstanceProp(AInstance, GetPropInfo(AInstance, AMsgPack[i].Name), AMsgPack[i]);
      end;
  end;
end;

{ TObjectHelper }

function TObjectHelper.GetAsMsgPack: TTNTMsgPack;
begin
 Result := ObjectToMsgPack(Self);
end;

procedure TObjectHelper.SetAsMsgPack(const Value: TTNTMsgPack);
begin
 MsgPackToObject(Self, Value);
end;

initialization
//   Test;
//   Halt;


end.
