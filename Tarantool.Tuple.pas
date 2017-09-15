unit Tarantool.Tuple;

interface

implementation

uses Tarantool.Interfaces
    , Tarantool.ServerResponse
    , Tarantool.Variants
    , Tarantool.UserKeys;


type
  TTNTTuple = class(TTNTResponce, ITNTTuple)
  private
    FValues: Variant;
    function GetValues: Variant;
    function GetRowCount: Integer;
    function GetRow(Index: Integer): Variant;
    function GetItemCount(ARowIndex: Integer): Integer;
  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection); override;
    property Values: Variant read GetValues;
    property RowCount: Integer read GetRowCount;
    property Row[Index: Integer]: Variant read GetRow;
    property ItemCount[ARowIndex: Integer]: Integer read GetItemCount;
  end;

{ TTNTTuple }

constructor TTNTTuple.Create(APacker: ITNTPacker; AConnection: ITNTConnection);
var Arr: ITNTPackerArray;
begin
  inherited;
  Arr := APacker.Body.UnpackArray(tnData);
  TTNTVariantData(FValues).InitFrom(Arr);
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
