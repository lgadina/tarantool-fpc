unit Tarantool.InsertRequest;

interface
uses SysUtils, Classes, Tarantool.Interfaces;

  function NewInsert(ASpaceId: Int64; AValues: TTNTInsertValues; ATuple: TBytes): ITNTInsert; overload;
  function NewInsert(ASpaceId: Int64; AValues: TTNTInsertValues): ITNTInsert; overload;
  function NewInsert(ASpaceId: Int64; AValues: Variant): ITNTInsert; overload;

  function NewReplace(ASpaceId: Int64; AValues: TTNTInsertValues; ATuple: TBytes): ITNTReplace; overload;
  function NewReplace(ASpaceId: Int64; AValues: TTNTInsertValues): ITNTReplace; overload;
  function NewReplace(ASpaceId: Int64; AValues: Variant): ITNTReplace; overload;


implementation
uses Tarantool.ClientMessage, Tarantool.UserKeys, Tarantool.CommanCode, Tarantool.Variants, Variants;

type
  TTNTInsert = class(TTNTClientMessage, ITNTInsert, ITNTReplace)
  private
    FTuple: TBytes;
    FValues: Variant;
    function GetTuple: TBytes;
    procedure SetTuple(const Value: TBytes);
    function GetValues: Variant;
    procedure SetValues(const Value: Variant);
  protected
    procedure PackToMessage(APacker: ITNTPacker); override;
  public
    constructor Create(ACommand: Integer); override;
    destructor Destroy; override;
    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
    property Values: Variant read GetValues write SetValues;
    property Tuple: TBytes read GetTuple write SetTuple;
  end;

{ TTNTInsert }

constructor TTNTInsert.Create(ACommand: Integer);
begin
  inherited;
  FValues := Unassigned;
end;

destructor TTNTInsert.Destroy;
begin
  FValues := Unassigned;
  inherited;
end;


function TTNTInsert.GetTuple: TBytes;
begin
 Result := FTuple;
end;

function TTNTInsert.GetValues: Variant;
begin
 Result := FValues;
end;

procedure TTNTInsert.PackToMessage(APacker: ITNTPacker);
var v: Variant;
    i: Integer;
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
   end;
end;



procedure TTNTInsert.SetTuple(const Value: TBytes);
begin
 FTuple := Value;
end;

procedure TTNTInsert.SetValues(const Value: Variant);
begin
 FValues := Value;
end;

function NewInsert(ASpaceId: Int64; AValues: TTNTInsertValues; ATuple: TBytes): ITNTInsert;
begin
  Result := TTNTInsert.Create(tncInsert);
  Result.SpaceId := ASpaceId;
  Result.Values := AValues;
  Result.Tuple := ATuple;
end;

function NewInsert(ASpaceId: Int64; AValues: TTNTInsertValues): ITNTInsert; overload;
begin
  Result := TTNTInsert.Create(tncInsert);
  Result.SpaceId := ASpaceId;
  Result.Values := AValues;
end;

function NewInsert(ASpaceId: Int64; AValues: Variant): ITNTInsert; overload;
begin
  Result := TTNTInsert.Create(tncInsert);
  Result.SpaceId := ASpaceId;
  Result.Values := AValues;
end;

function NewReplace(ASpaceId: Int64; AValues: TTNTInsertValues; ATuple: TBytes): ITNTReplace; overload;
begin
  Result := TTNTInsert.Create(tncReplace);
  Result.SpaceId := ASpaceId;
  Result.Values := AValues;
  Result.Tuple := ATuple;
end;

function NewReplace(ASpaceId: Int64; AValues: TTNTInsertValues): ITNTReplace; overload;
begin
  Result := TTNTInsert.Create(tncReplace);
  Result.SpaceId := ASpaceId;
  Result.Values := AValues;
end;

function NewReplace(ASpaceId: Int64; AValues: Variant): ITNTReplace; overload;
begin
  Result := TTNTInsert.Create(tncReplace);
  Result.SpaceId := ASpaceId;
  Result.Values := AValues;
end;


end.
