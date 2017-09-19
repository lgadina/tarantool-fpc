unit Tarantool.SelectRequest;

interface

uses Classes
  , Tarantool.Interfaces
  , Tarantool.Iterator;


  function SelectRequest(ASpaceId, AIndexId: Int64; AKeys: Variant; AOffset: Int64 = 0;
     ALimit: Int64 = 0; AIterator : TTarantoolIterator = TTarantoolIterator.Eq): ITNTSelect;
implementation

uses SysUtils, Tarantool.ClientMessage, Tarantool.UserKeys, Tarantool.CommanCode, Variants, Tarantool.Variants;

type
  TTNTSelect = class(TTNTClientMessageBase, ITNTSelect)
  private
    FIndexId: Int64;
    FSpaceId: Int64;
    FIterator: TTarantoolIterator;
    FLimit: Int64;
    FKeys: Variant;
    FOffset: Int64;
    procedure SetIndexId(const Value: Int64);
    procedure SetIterator(const Value: TTarantoolIterator);
    procedure SetKeys(const Value: Variant);
    procedure SetLimit(const Value: Int64);
    procedure SetOffset(const Value: Int64);
    procedure SetSpaceId(const Value: Int64);
    function GetIndexId: Int64;
    function GetIterator: TTarantoolIterator;
    function GetKeys: Variant;
    function GetLimit: Int64;
    function GetOffset: Int64;
    function GetSpaceId: Int64;
  protected
    procedure PackToMessage(APacker: ITNTPacker); override;
  public
    constructor Create(ACommand: Integer); override;
    destructor Destroy; override;

    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
    property IndexId: Int64 read GetIndexId write SetIndexId;
    property Limit: Int64 read GetLimit write SetLimit;
    property Offset: Int64 read GetOffset write SetOffset;
    property Iterator: TTarantoolIterator read GetIterator write SetIterator;
    property Keys: Variant read GetKeys write SetKeys;
  end;

{ TTNTSelect }

constructor TTNTSelect.Create(ACommand: Integer);
begin
  inherited;
  FIterator := TTarantoolIterator.Eq;
  FLimit := Integer.MaxValue;
  FKeys := Unassigned;
end;

destructor TTNTSelect.Destroy;
begin
  FKeys := Unassigned;
  inherited;
end;

function TTNTSelect.GetIndexId: Int64;
begin
 Result := FIndexId;
end;

function TTNTSelect.GetIterator: TTarantoolIterator;
begin
 Result := FIterator;
end;

function TTNTSelect.GetKeys: Variant;
begin
 Result := FKeys;
end;

function TTNTSelect.GetLimit: Int64;
begin
 Result := FLimit;
end;

function TTNTSelect.GetOffset: Int64;
begin
 Result := FOffset;
end;

function TTNTSelect.GetSpaceId: Int64;
begin
 Result := FSpaceId;
end;

procedure TTNTSelect.PackToMessage(APacker: ITNTPacker);
var s: Variant;
    i: Integer;
    Arr: ITNTPackerArray;
begin
  inherited;
  with APacker.Body do
   begin
     Pack(tnSpaceId, FSpaceId);
     if FIndexId > -1 then
       Pack(tnIndexId, FIndexId);
     Pack(tnLimit, FLimit);
     Pack(tnOffset, FOffset);
     Pack(tnIterator, Ord(FIterator));
     Arr := PackArray(tnKey);
     if not VarIsNull(FKeys) then
     begin
      if (VarType(FKeys) and varArray) <> 0 then
       begin
         for i := VarArrayLowBound(FKeys, 1) to VarArrayHighBound(FKeys, 1) do
          begin
            s := FKeys[i];
            if VarType(s) = TNTVariantType.VarType then
             TNTVariantData(s)^.PackToMessage(Arr.PackArray)
            else
            Arr.Pack(s);
          end;
       end else
       if (VarType(FKeys) = TNTVariantType.VarType) then
         TNTVariantData(FKeys)^.PackToMessage(Arr.PackArray)
       else
         Arr.Pack(FKeys)
     end;
   end;
end;

procedure TTNTSelect.SetIndexId(const Value: Int64);
begin
  FIndexId := Value;
end;

procedure TTNTSelect.SetIterator(const Value: TTarantoolIterator);
begin
  FIterator := Value;
end;

procedure TTNTSelect.SetKeys(const Value: Variant);
begin
  FKeys := Value;
end;

procedure TTNTSelect.SetLimit(const Value: Int64);
begin
  FLimit := Value;
end;

procedure TTNTSelect.SetOffset(const Value: Int64);
begin
  FOffset := Value;
end;

procedure TTNTSelect.SetSpaceId(const Value: Int64);
begin
  FSpaceId := Value;
end;

function SelectRequest(ASpaceId, AIndexId: Int64; AKeys: Variant; AOffset: Int64 = 0;
   ALimit: Int64 = 0; AIterator : TTarantoolIterator = TTarantoolIterator.Eq): ITNTSelect;
var
    s: Variant;
begin
  Result := TTntSelect.Create(tncSelect);
  Result.SpaceId := ASpaceId;
  Result.IndexId := AIndexId;
  Result.Iterator := AIterator;
  Result.Offset := AOffset;
  if ALimit > 0 then
   Result.Limit := ALimit;
  Result.Keys := AKeys;
end;


end.
