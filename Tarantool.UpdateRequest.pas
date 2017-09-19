unit Tarantool.UpdateRequest;
{$I Tarantool.Options.inc}

interface
uses Tarantool.Interfaces;

function UpdateDefinition: ITNTUpdateDefinition;
function NewUpdate(ASpaceId, AIndexId: Int64; AKeys: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTUpdate;

implementation

uses
  Contnrs,
  Tarantool.Variants,
  Tarantool.Exceptions,
  Tarantool.ClientMessage,
  Tarantool.UserKeys,
  Tarantool.CommanCode,
  Variants;


const
  StrOperationCode: array[TTNTUpdateOperationCode] of AnsiChar = ('+', '-', '&', '^', '|', '#', '!', '=', ':');

type
  TTNTUpdateOperationCodeHelper = record helper for TTNTUpdateOperationCode
  private
  public
    function ToChar: AnsiChar;
    procedure Parse(AOperationChar: AnsiChar);
  end;

{ TTNTUpdateOperationCodeHelper }

procedure TTNTUpdateOperationCodeHelper.Parse(AOperationChar: AnsiChar);
var c: TTNTUpdateOperationCode;
begin
 for c := Low(Self) to High(Self) do
  if StrOperationCode[c] = AOperationChar then
   begin
     Self := c;
     Break;
   end;
end;

function TTNTUpdateOperationCodeHelper.ToChar: AnsiChar;
begin
  Result := StrOperationCode[Self];
end;

type
  TTNTUpdateDefintion = class(TInterfacedObject, ITNTUpdateDefinition)
  private
  type
      TTNTUpdateOperationClass = class(TObject)
      private
        FFieldNo: Integer;
        FOp: TTNTUpdateOperationCode;
        FValue: Variant;
      public
        property FieldNo: Integer read FFieldNo write FFieldNo;
        property Operation: TTNTUpdateOperationCode read FOp write Fop;
        property Value: Variant read FValue write FValue;
      end;
  private
    FOperList: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PackToMessage(APacker: ITNTPackerArray);
    function AddOperation(AFieldNo: Integer; AOperation: TTNTUpdateOperationCode; AValue: Variant): ITNTUpdateDefinition;
  end;

type
  TTNTCustomUpdateOperation = class(TTNTClientMessageKeys, ITNTUpdate)
  private
    FUpdateDef: ITNTUpdateDefinition;
    function GetUpdateDefinition: ITNTUpdateDefinition;
    procedure SetUpdateDefinition(const Value: ITNTUpdateDefinition);
  protected
    procedure PackToMessage(APacker: ITNTPacker); override;
  public
    constructor Create(ACommand: Integer); override;
    property UpdateDefinition: ITNTUpdateDefinition read GetUpdateDefinition Write SetUpdateDefinition;
  end;

  TTntUpdate = class(TTNTCustomUpdateOperation)

  end;

{ TTNTUpdateDefintion }

function TTNTUpdateDefintion.AddOperation(AFieldNo: Integer;
  AOperation: TTNTUpdateOperationCode; AValue: Variant): ITNTUpdateDefinition;
var Obj: TTNTUpdateOperationClass;
begin
  if (AOperation in [TTNTUpdateOperationCode.Addition, TTNTUpdateOperationCode.Subtraction,
      TTNTUpdateOperationCode.BitwiseAnd, TTNTUpdateOperationCode.BitwiseXor,
      TTNTUpdateOperationCode.BitwiseOr]) and not VarIsOrdinal(AValue) then
       ETarantoolInvalidUpdateOperation.CreateFmt('Invalid operation "%s" for value', [AOperation.ToChar]);

  Obj := TTNTUpdateOperationClass.Create;
  Obj.FieldNo := AFieldNo;
  Obj.Operation := AOperation;
  Obj.Value := AValue;
  FOperList.Add(Obj);
  Result := Self;
end;

constructor TTNTUpdateDefintion.Create;
begin
 FOperList := TObjectList.Create;
end;

destructor TTNTUpdateDefintion.Destroy;
begin
  FOperList.Free;
  inherited;
end;

procedure TTNTUpdateDefintion.PackToMessage(APacker: ITNTPackerArray);
var Obj: TTNTUpdateOperationClass;
    i: Integer;
    L: ITNTPackerArray;
begin
  for i := 0 to FOperList.Count - 1 do
   begin
     Obj := TTNTUpdateOperationClass(FOperList[I]);
     L := APacker.PackArray;
     L.Pack(Obj.Operation.ToChar).pack(Obj.FieldNo);
     if VarType(Obj.Value) = TNTVariantType.VarType then
       TTNTVariantData(Obj.Value).PackToMessage(L.PackArray)
     else
       L.Pack(Obj.Value);
   end;
end;

{ TTNTCustomUpdateOperation }

constructor TTNTCustomUpdateOperation.Create(ACommand: Integer);
begin
  inherited;

end;

function TTNTCustomUpdateOperation.GetUpdateDefinition: ITNTUpdateDefinition;
begin
 Result := FUpdateDef;
end;

procedure TTNTCustomUpdateOperation.PackToMessage(APacker: ITNTPacker);
var i: Integer;
begin
  if FUpdateDef <> nil then
  begin
    inherited;
    UpdateDefinition.PackToMessage(APacker.Body.PackArray(tnTuple));
  end else
   raise ETarantoolException.Create('Update defintion is empty!');
end;


procedure TTNTCustomUpdateOperation.SetUpdateDefinition(
  const Value: ITNTUpdateDefinition);
begin
 FUpdateDef := Value;
end;

function UpdateDefinition: ITNTUpdateDefinition;
begin
  Result := TTNTUpdateDefintion.Create;
end;

function NewUpdate(ASpaceId, AIndexId: Int64; AKeys: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTUpdate;
begin
  Result := TTNTUpdate.Create(tncUpdate);
  Result.SpaceId := ASpaceId;
  Result.IndexId := AIndexId;
  Result.Keys := AKeys;
  Result.UpdateDefinition := AUpdateDef;
end;

end.
