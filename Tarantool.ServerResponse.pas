unit Tarantool.ServerResponse;
{$I Tarantool.Options.inc}
interface

uses
  Tarantool.Interfaces;

type
  TTNTResponce = class abstract(TInterfacedObject, ITNTResponce)
  private
    FCode: Integer;
    FRequestId: Int64;
    FConnection: ITNTConnection;
    FSpace: ITNTSpace;
    function GetConnection: ITNTConnection;
    function GetSpace: ITNTSpace;
  protected
    function GetCode: integer;
    function GetRequestId: Int64;
  public
    destructor Destroy; override;
    procedure Close; virtual;
    property Code: integer read GetCode;
    property RequestId: Int64 read GetRequestId;
    property Connection: ITNTConnection read GetConnection;
    property Space: ITNTSpace read GetSpace;
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace); virtual;

  end;

  TTNTResponseClass = class of TTNTResponce;

procedure RegisterResponseClass(AGuid: TGUID; AResponseClass: TTNTResponseClass);
function GetResponseClass(AGuid: TGUID): TTNTResponseClass;

implementation

uses
  Tarantool.UserKeys
  {$IfDef FPC}
  , generics.collections
  {$Else}
  , System.Generics.Collections
  {$EndIf}
  ;


type
  TResponseClassList = class(TDictionary<TGUID,TTNTResponseClass>);

var
  FResponseClassList : TResponseClassList = nil;

procedure RegisterResponseClass(AGuid: TGUID; AResponseClass: TTNTResponseClass);
begin
 if FResponseClassList = nil then
  FResponseClassList := TResponseClassList.Create();
 if not FResponseClassList.ContainsKey(AGuid) then
  FResponseClassList.Add(AGuid, AResponseClass);
end;

function GetResponseClass(AGuid: TGUID): TTNTResponseClass;
begin
  Result := nil;
  if assigned(FResponseClassList) and (FResponseClassList.ContainsKey(AGuid)) then
   Result := FResponseClassList[AGuid];
end;

{ TTNTResponse }

procedure TTNTResponce.Close;
begin

end;

constructor TTNTResponce.Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace);
begin
 if APacker <> nil then
 begin
  FCode := APacker.Header.UnpackInteger(tnCode);
  FRequestId := APacker.Header.UnpackInteger(tnSync);
 end;
  FConnection := AConnection;
  FSpace := ASpace;
end;

destructor TTNTResponce.Destroy;
begin
  FConnection := nil;
  FSpace := nil;
  inherited;
end;

function TTNTResponce.GetCode: integer;
begin
  Result := FCode;
end;

function TTNTResponce.GetConnection: ITNTConnection;
begin
 Result := FConnection;
end;

function TTNTResponce.GetRequestId: Int64;
begin
  Result := FRequestId;
end;

function TTNTResponce.GetSpace: ITNTSpace;
begin
  Result := FSpace;
end;

initialization

finalization

if FResponseClassList <> nil then
 FResponseClassList.Free;
 FResponseClassList := nil;

end.

