unit Tarantool.EvalRequest;

interface
uses Tarantool.Interfaces;

function NewEval(AExpression: String; AArguments: Variant): ITNTEval;

implementation

uses Tarantool.ClientMessage
 , Tarantool.UserKeys
 , Tarantool.Variants
 , Tarantool.CommanCode
 , Variants;

type
  TTNTEval = class(TTNTClientMessageBase, ITNTEval)
  private
    FArguments: Variant;
    FFunctionName: String;
    procedure SetArguments(const Value: Variant);
    procedure SetFunctionName(const Value: String);
    function GetArguments: Variant;
    function GetFunctionName: String;
  protected
    procedure PackToMessage(APacker: ITNTPacker); override;
  public
    property FunctionName: String read GetFunctionName write SetFunctionName;
    property Arguments: Variant read GetArguments write SetArguments;
  end;

{ TTNTCall }

function TTNTEval.GetArguments: Variant;
begin
 Result := FArguments;
end;

function TTNTEval.GetFunctionName: String;
begin
 Result := FFunctionName;
end;

procedure TTNTEval.PackToMessage(APacker: ITNTPacker);
var i: Integer;
begin
  inherited;
  APacker.Body.Pack(tnExpression, FFunctionName);
  if not VarIsClear(FArguments) then
  begin
    if (VarType(FArguments) and varArray) <> 0 then
    begin
      with APacker.Body.PackArray(tnTuple) do
       for i := VarArrayLowBound(FArguments, 1) to VarArrayHighBound(FArguments, 1) do
        Pack(FArguments[I])
    end else
    begin
      APacker.Body.PackArray(tnTuple).Pack(FArguments);
    end;
  end;
end;

procedure TTNTEval.SetArguments(const Value: Variant);
begin
  FArguments := Value;
end;

procedure TTNTEval.SetFunctionName(const Value: String);
begin
  FFunctionName := Value;
end;


function NewEval(AExpression: String; AArguments: Variant): ITNTEval;
begin
  Result := TTNTEval.Create(tncEval);
  Result.FunctionName := AExpression;
  Result.Arguments := AArguments;
end;

initialization


end.
