unit Tarantool.UpsertRequest;

interface
uses Tarantool.Interfaces;


function NewUpsert(ASpaceId: Integer; AValues: Variant; AUpdateDefinition: ITNTUpdateDefinition): ITNTUpsert;

implementation

uses SysUtils
 , Tarantool.UserKeys
 , Tarantool.ClientMessage
 , Tarantool.Variants
 , Tarantool.Exceptions
 , Tarantool.CommanCode
 , Variants;

type
  TTNTUpsert = class(TTNTClientMessage, ITNTUpsert)
  private
    FValues: Variant;
    FTuple: TBytes;
    FUpdateDef: ITNTUpdateDefinition;
    function GetValues: Variant;
    procedure SetValues(const Value: Variant);
    function GetUpdateDef: ITNTUpdateDefinition;
    procedure SetUpdateDef(const Value: ITNTUpdateDefinition);
    function GetTuple: TBytes;
    procedure SetTuple(const Value: TBytes);
  protected
    procedure PackToMessage(APacker: ITNTPacker); override;
  public

    property Values: Variant read GetValues write SetValues;
    property Tuple: TBytes read GetTuple write SetTuple;
    property UpdateDefinition: ITNTUpdateDefinition read GetUpdateDef write SetUpdateDef;
  end;

{ TTNTUpsert }

function TTNTUpsert.GetTuple: TBytes;
begin
 Result := FTuple;
end;

function TTNTUpsert.GetUpdateDef: ITNTUpdateDefinition;
begin
 Result := FUpdateDef;
end;

function TTNTUpsert.GetValues: Variant;
begin
 Result := FValues;
end;

procedure TTNTUpsert.PackToMessage(APacker: ITNTPacker);
var i: Integer;
begin
 if FUpdateDef <> nil then
 begin
  inherited;
  if (VarType(FValues) and varArray) <> 0 then
   with APacker.Body.PackArray(tnTuple) do
   begin
    for i := VarArrayLowBound(FValues, 1) to VarArrayHighBound(FValues, 1) do
     Pack(FValues[i]);
    if Length(FTuple) > 0 then
      PackArray.AsBytes := FTuple;
   end
  else
  if VarType(FValues) = TNTVariantType.VarType then
   begin
     TTNTVariantData(FValues).PackToMessage(APacker.Body.PackArray(tnTuple));
   end else
    APacker.Body.PackArray(tnTuple).Pack(FValues);
  FUpdateDef.PackToMessage(APacker.Body.PackArray(tnOps));
 end else
  raise ETarantoolInvalidUpdateOperation.Create(4, 'Update operation not defined');
end;

procedure TTNTUpsert.SetTuple(const Value: TBytes);
begin
 FTuple := Value;
end;

procedure TTNTUpsert.SetUpdateDef(const Value: ITNTUpdateDefinition);
begin
 FUpdateDef := Value;
end;

procedure TTNTUpsert.SetValues(const Value: Variant);
begin
 FValues := Value;
end;

function NewUpsert(ASpaceId: Integer; AValues: Variant; AUpdateDefinition: ITNTUpdateDefinition): ITNTUpsert;
begin
  Result := TTNTUpsert.Create(tncUpsert);
  Result.SpaceId := ASpaceId;
  Result.Values := AValues;
  Result.UpdateDefinition := AUpdateDefinition;
end;

end.
