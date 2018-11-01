unit Tarantool.CallRequest;
{$I Tarantool.Options.inc}
interface
uses Tarantool.Interfaces;

function NewCall(AFunctionName: String; AArguments: Variant): ITNTCall;

implementation

uses Tarantool.ClientMessage
 , Tarantool.UserKeys
 , Tarantool.Variants
 , Tarantool.CommanCode
 , Variants;

type
  TTNTCall = class(TTNTClientMessageBase, ITNTCall)
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

function TTNTCall.GetArguments: Variant;
begin
 Result := FArguments;
end;

function TTNTCall.GetFunctionName: String;
begin
 Result := FFunctionName;
end;

procedure TTNTCall.PackToMessage(APacker: ITNTPacker);
var i: Integer;
begin
  inherited;
  APacker.Body.Pack(tnFunctionName, FFunctionName);
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

procedure TTNTCall.SetArguments(const Value: Variant);
begin
  FArguments := Value;
end;

procedure TTNTCall.SetFunctionName(const Value: String);
begin
  FFunctionName := Value;
end;


function NewCall(AFunctionName: String; AArguments: Variant): ITNTCall;
begin
  Result := TTNTCall.Create(tncCall);
  Result.FunctionName := AFunctionName;
  Result.Arguments := AArguments;
end;

end.
