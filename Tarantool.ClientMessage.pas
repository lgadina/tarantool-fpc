unit Tarantool.ClientMessage;

interface

uses Tarantool.Interfaces;

type
  TTNTClientMessageBase = class abstract (TInterfacedObject, ITNTCommand)
  private
    FCommand: Integer;
    FRequestId: Int64;
    function GetCommand: Integer;
    procedure SetRequestId(const Value: Int64);
    function GetRequestId: Int64;
  protected
    procedure MakeHeader(APacker: ITNTPacker);
    procedure PackToMessage(APacker: ITNTPacker); virtual;
  public
    constructor Create(ACommand: Integer); virtual;
    property Command: Integer read GetCommand;
    property RequestId: Int64 read GetRequestId write SetRequestId;
  end;

  TTNTClientMessage = class(TTNTClientMessageBase, ITNTClientMessage)
  private
    FSpaceId: Int64;
  protected
    function GetSpaceId: Int64;
    procedure SetSpaceId(const Value: Int64);
    procedure PackToMessage(APacker: ITNTPacker);override;
  public
    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
  end;

  TTNTClientMessageIndex = class(TTNTClientMessage, ITNTClientMessageIndex)
  private
    FIndexId: Int64;
  protected
    function GetIndexId: Int64;
    procedure SetIndexId(const Value: Int64);
    procedure PackToMessage(APacker: ITNTPacker); override;
  public
    property IndexId: Int64 read GetIndexId write SetIndexId;
  end;

  TTNTClientMessageKeys = class(TTNTClientMessageIndex, ITNTClientMessageKeys)
  private
    FKeys: Variant;
  protected
    procedure PackToMessage(APacker: ITNTPacker); override;
    function GetKeys: Variant;
    procedure SetKeys(const Value: Variant);
  public
    property Keys: Variant read GetKeys write SetKeys;
  end;

implementation

uses Tarantool.UserKeys, Variants;


{ TTNTClientMessageBase }

constructor TTNTClientMessageBase.Create(ACommand: Integer);
begin
 FCommand := ACommand;
end;


function TTNTClientMessageBase.GetCommand: Integer;
begin
 Result := FCommand;
end;

function TTNTClientMessageBase.GetRequestId: Int64;
begin
 Result := FRequestId;
end;

procedure TTNTClientMessageBase.MakeHeader(APacker: ITNTPacker);
begin
 APacker.Header.Pack(tnCode, FCommand);
 APacker.Header.Pack(tnSync, FRequestId);
end;

procedure TTNTClientMessageBase.PackToMessage(APacker: ITNTPacker);
begin
 MakeHeader(APacker);
end;

procedure TTNTClientMessageBase.SetRequestId(const Value: Int64);
begin
  FRequestId := Value;
end;

{ TTNTClientMessage }

function TTNTClientMessage.GetSpaceId: Int64;
begin
 Result := FSpaceId;
end;

procedure TTNTClientMessage.PackToMessage(APacker: ITNTPacker);
begin
 inherited;
 APacker.Body.Pack(tnSpaceId, FSpaceId);
end;

procedure TTNTClientMessage.SetSpaceId(const Value: Int64);
begin
 FSpaceId := Value;
end;

{ TTNTClientMessageIndex }

function TTNTClientMessageIndex.GetIndexId: Int64;
begin
 Result := FIndexId;
end;

procedure TTNTClientMessageIndex.PackToMessage(APacker: ITNTPacker);
begin
  inherited;
  APacker.Body.Pack(tnIndexId, FIndexId);
end;

procedure TTNTClientMessageIndex.SetIndexId(const Value: Int64);
begin
 FIndexId := Value;
end;

{ TTNTClientMessageKeys }

function TTNTClientMessageKeys.GetKeys: Variant;
begin
 Result := FKeys;
end;

procedure TTNTClientMessageKeys.PackToMessage(APacker: ITNTPacker);
var i: Integer;
begin
  inherited;
   with APacker.Body.PackArray(tnKey) do
   begin
    if (VarType(FKeys) and varArray) <> 0 then
      for i := VarArrayLowBound(FKeys, 1) to VarArrayHighBound(FKeys, 1) do
       Pack(FKeys[i])
    else
     Pack(FKeys);
   end;
end;

procedure TTNTClientMessageKeys.SetKeys(const Value: Variant);
begin
 FKeys := Value;
end;

end.
