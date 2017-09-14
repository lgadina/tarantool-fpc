{$I SynCrossPlatform.Inc}
unit Tarantool.ServerResponse;

interface

uses
  Tarantool.Interfaces;

type
  TTNTResponce = class abstract(TInterfacedObject, ITNTResponce)
  private
    FCode: Integer;
    FRequestId: Int64;
    FConnection: ITNTConnection;
    function GetConnection: ITNTConnection;
  protected
    function GetCode: integer;
    function GetRequestId: Int64;
  public
    destructor Destroy; override;
    property Code: integer read GetCode;
    property RequestId: Int64 read GetRequestId;
    property Connection: ITNTConnection read GetConnection;
    constructor Create(APacker: IPacker; AConnection: ITNTConnection); virtual;

  end;

  TTNTResponseClass = class of TTNTResponce;

procedure RegisterResponseClass(AGuid: TGUID; AResponseClass: TTNTResponseClass);
function GetResponseClass(AGuid: TGUID): TTNTResponseClass;

implementation

uses
  Tarantool.UserKeys, System.Generics.Collections;


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

constructor TTNTResponce.Create(APacker: IPacker; AConnection: ITNTConnection);
begin
 if APacker <> nil then
 begin
  FCode := APacker.Header.UnpackInteger(tnCode);
  FRequestId := APacker.Header.UnpackInteger(tnSync);
 end;
  FConnection := AConnection;
end;

destructor TTNTResponce.Destroy;
begin
  FConnection := nil;
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

initialization

finalization

if FResponseClassList <> nil then
 FResponseClassList.Free;
 FResponseClassList := nil;

end.

