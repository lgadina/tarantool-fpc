unit Tarantool.Tuple;

interface

uses
      Tarantool.Interfaces;

  function NewTuple(AConnection: ITNTConnection; ASpace: ITNTSpace): ITNTTuple;

implementation

uses
      Tarantool.ServerResponse
    , Tarantool.Variants
    , Tarantool.UserKeys
    , Variants
    , SysUtils;


type

  { TTNTTuple }

  TTNTTuple = class(TTNTResponce, ITNTTuple)
  private
    FValues: Variant;
    FFields: Array of String;
    function GetValues: Variant;
    function GetRowCount: Integer;
    function GetRow(Index: Integer): Variant;
    function GetItemCount(ARowIndex: Integer): Integer;
  protected
    function NewRow: Variant;
    procedure LoadFields;
    function GetFieldIndex(AFieldName: String): Integer;
  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace); override;
    constructor NewTuple(AConnection: ITNTConnection; ASpace: ITNTSpace); virtual;
    destructor Destroy; override;
    property Values: Variant read GetValues;
    property RowCount: Integer read GetRowCount;
    property Row[Index: Integer]: Variant read GetRow;

    function FieldByName(ARow: Integer; AFieldName: String): Variant;

    function AddRow: Integer;
    procedure SetFieldValue(ARow: Integer; AFieldName: String; AValue: Variant);
    property ItemCount[ARowIndex: Integer]: Integer read GetItemCount;
  end;

function NewTuple(AConnection: ITNTConnection; ASpace: ITNTSpace): ITNTTuple;
begin
  Result := TTNTTuple.NewTuple(AConnection, ASpace);
end;

{ TTNTTuple }

constructor TTNTTuple.Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace);
var Arr: ITNTPackerArray;
begin
  inherited;
  Arr := APacker.Body.UnpackArray(tnData);
  FValues:= TNTVariant(Arr);
  LoadFields;
end;

constructor TTNTTuple.NewTuple(AConnection: ITNTConnection; ASpace: ITNTSpace);
begin
  inherited Create(nil, AConnection, ASpace);
  LoadFields;
  FValues := TNTVariant;
end;

function TTNTTuple.AddRow: Integer;
begin
  NewRow;
  Result := GetRowCount - 1;
end;

destructor TTNTTuple.Destroy;
begin
  FValues := Unassigned;
  SetLength(FFields, 0);
  inherited Destroy;
end;

function TTNTTuple.FieldByName(ARow: Integer; AFieldName: String): Variant;
var i: Integer;
begin
 Result := null;
 if ARow < RowCount then
  begin
   i := GetFieldIndex(AFieldName);
   if i > -1 then
     Exit(TNTVariantDataSafe(Row[ARow])^.Item[i]);
  end;
end;

function TTNTTuple.GetFieldIndex(AFieldName: String): Integer;
var i: Integer;
begin
 i := -1;
 for i := 0 to Length(FFields) - 1 do
  if CompareStr(AFieldName, FFields[i]) = 0 then
    exit(i);
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

procedure TTNTTuple.LoadFields;
var
    Fld: ITNTField;
    i: Integer;
begin
 if Space <> nil then
  begin
   i := 0;
   Fld := Space.Field[i];
   while Fld <> nil do
    begin
      SetLength(FFields, i+1);
      FFields[i] := Fld.Name;
      Inc(i);
      Fld := Space.Field[i];
    end;
  end;
end;

function TTNTTuple.NewRow: Variant;
var i: integer;
begin
  Result := TTNTVariantData(FValues).AddTNTVariant;
  for i := 0 to Length(FFields) - 1 do
    TNTVariantDataSafe(Result)^.AddItem;
end;

procedure TTNTTuple.SetFieldValue(ARow: Integer; AFieldName: String;
  AValue: Variant);
var
    i: Integer;
begin
 if ARow < RowCount then
  begin
   i := GetFieldIndex(AFieldName);
   if i > -1 then
     TNTVariantDataSafe(Row[ARow])^.Item[i] := AValue;
  end;
end;

initialization
  RegisterResponseClass(ITNTTuple, TTNTTuple);

end.
