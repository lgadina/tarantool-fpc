unit Tarantool.SimpleMsgPack.Serializer;

interface

uses Tarantool.SimpleMsgPack, System.TypInfo;

function ObjectToMsgPack(AObject: TObject): TSimpleMsgPack;

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



function WriteRectDynArrayElem(Info: PTypeInfo; Size, Dim: Integer; P: Pointer): TSimpleMsgPack;
var i: Integer;
    ElemSize: Integer;
    TypeData: PTypeData;
begin
  Result := TSimpleMsgPack.Create(mptArray);
  TypeData := GetTypeData(Info);
  if Dim > 1 then
   begin
     Dec(Dim);
     for i := 0 to Size - 1 do
       begin
         ElemSize := GetDynArrayLength(Pointer(P^));
         Result.AddArrayChild.OO[I] := WriteRectDynArrayElem(Info, ElemSize, Dim, Pointer(P^));
         P := Pointer(NativeUInt(P) + sizeof(Pointer));
       end;
   end else
   begin
     for i := 0 to Size - 1 do
       begin
         if Info.Kind = tkClass then
         begin
           Result.Add(ObjectToMsgPack(TObject(P^)));
           //AddArrayChild.OO[I] := ObjectToMsgPack(TObject(P^));
           P := Pointer( NativeUInt(P) + SizeOf(Pointer));
           Continue
         end
         else
         case info^.Kind of
          tkInteger: case TypeData.OrdType of
                      otSByte, otUByte: Result.AddArrayChild.AsInteger := Byte(P^);
                      otSWord, otUWord: Result.AddArrayChild.AsInteger := SmallInt(P^);
                      otSLong, otULong: Result.AddArrayChild.AsInteger := Integer(P^);
                     end;
          tkFloat:   case TypeData.FloatType of
                      ftSingle: Result.AddArrayChild.AsSingle := Single(P^);
                      ftDouble: Result.AddArrayChild.AsFloat := Double(P^);
                     end;
          tkInt64: Result.AddArrayChild.AsInteger :=Int64(P^);
          tkChar: Result.AddArrayChild.AsString := Char(P^);
          tkWChar: Result.AddArrayChild.AsString := WideChar(P^);
          tkWString: Result.AddArrayChild.AsString := PWideString(P)^;
          tkString: Result.AddArrayChild.AsString := PShortString(P)^;
          tkLString: Result.AddArrayChild.AsString := PAnsiString(P)^;
          tkUString: Result.AddArrayChild.AsString := PUnicodeString(P)^;
         end;

         P := Pointer( NativeUInt(P) + TypeData.elSize);
       end;
   end;

end;


function DynArrayToMsgPack(Info: PTypeInfo; P: Pointer): TSimpleMsgPack;
var
  ElemInfo: PTypeInfo;
  Dims: Integer;
  UseNonRect: Boolean;
  DimArr: TNativeIntDynArray;
begin
  Result := nil;
  GetDynArrayElementTypeInfo(Info, ElemInfo, Dims);
  UseNonRect := Assigned(P) and ((IsArrayRect(P, Dims)=False) or (Dims > 1));
  if UseNonRect then
   begin

   end
  else
   begin
     SetLength(DimArr, Dims);
     if Assigned(P) then
      GetDims(P, DimArr, Dims);
     Result := WriteRectDynArrayElem(ElemInfo, GetDynArrayLength(P), Dims, P);
   end;
end;

function ObjectToMsgPack(AObject: TObject): TSimpleMsgPack;
var
  C, I: Integer;
  PI: PPropInfo;
  PL: PPropList;
  Obj: TObject;
  P: Pointer;
  D: Integer;
begin
 Result := TSimpleMsgPack.Create(mptMap);
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

initialization
//   Test;
//   Halt;


end.
