unit Tarantool.Tuple;

interface

implementation

uses Tarantool.Interfaces
    , Tarantool.ServerResponse
    , Tarantool.Variants
    , Tarantool.UserKeys
    , Variants;


type
  TTNTTuple = class(TTNTResponce, ITNTTuple)
  private
    FValues: Variant;
    FFields: Array of String;
    function GetValues: Variant;
    function GetRowCount: Integer;
    function GetRow(Index: Integer): Variant;
    function GetItemCount(ARowIndex: Integer): Integer;
  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace); override;
    property Values: Variant read GetValues;
    property RowCount: Integer read GetRowCount;
    property Row[Index: Integer]: Variant read GetRow;
    function FieldByName(ARow: Integer; AFieldName: String): Variant;
    property ItemCount[ARowIndex: Integer]: Integer read GetItemCount;
  end;

{ TTNTTuple }

constructor TTNTTuple.Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace);
var Arr: ITNTPackerArray;
    Fld: ITNTField;
    i: Integer;
begin
  inherited;
  Arr := APacker.Body.UnpackArray(tnData);
  TTNTVariantData(FValues).InitFrom(Arr);
  if ASpace <> nil then
   begin
    i := 0;
    Fld := ASpace.Field[i];
    while Fld <> nil do
     begin
       SetLength(FFields, i+1);
       FFields[i] := Fld.Name;
       Inc(i);
       Fld := ASpace.Field[i];
     end;
   end;
end;

function TTNTTuple.FieldByName(ARow: Integer; AFieldName: String): Variant;
var i: Integer;
begin
 Result := null;
 if ARow < RowCount then
  for i := 0 to Length(FFields) - 1 do
   if AFieldName = FFields[i] then
      Exit(TNTVariantDataSafe(Row[ARow])^.Item[i]);
end;

function TTNTTuple.GetItemCount(ARowIndex: Integer): Integer;
begin
 Result := TTNTVariantData(Row[ARowIndex]).Count;
end;

function TTNTTuple.GetRow(Index: Integer): Variant;
begin
 result := TTNTVariantData(FValues).Values[Index];
end;

function TTNTTuple.GetRowCount: Integer;
begin
 Result := TTNTVariantData(FValues).Count;
end;

function TTNTTuple.GetValues: Variant;
begin
 Result := FValues;
end;

initialization
  RegisterResponseClass(ITNTTuple, TTNTTuple);

end.
