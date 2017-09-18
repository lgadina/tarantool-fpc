unit Tarantool.Pool;

interface
uses Tarantool.Interfaces;


function TNTConnectionPool(AMaxPoolSize: Integer = 10; AMainConnection: ITNTConnection = nil): ITNTConnectionPool;
function IsPoolExist: Boolean;

implementation

uses System.SysUtils
  , System.Generics.Collections
  , System.SyncObjs
  , Tarantool.Core
  , Tarantool.Exceptions
  ;

type
  TTarantoolConnectionList = TThreadedQueue<ITNTConnection>;

  TTarantoolPool = class(TInterfacedObject, ITNTConnectionPool)
  private
   FMaxPoolSize: Integer;
   FAllocatedConnection, FTakenConnection: Integer;
   FMainConnection: ITNTConnection;
   FConnList: TTarantoolConnectionList;
   FLockPooled, FLockTaked: TCriticalSection;
   FBusy: TEvent;
  protected
    function CreateNewConnection: ITNTConnection;
    procedure ReserveConnection;
  public
    constructor Create(AMaxPoolSize: Integer; AMainConnection: ITNTConnection);
    destructor Destroy; override;
    function Get: ITNTConnection;
    procedure Put(AConnection: ITNTConnection);
  end;

{ TTarantoolPool }

constructor TTarantoolPool.Create(AMaxPoolSize: Integer;
  AMainConnection: ITNTConnection);
begin
 FMaxPoolSize := AMaxPoolSize;
 FMainConnection := AMainConnection;
 FAllocatedConnection := 0;
 FTakenConnection := 0;
 FConnList := TTarantoolConnectionList.Create(AMaxPoolSize, INFINITE, 10);
 FLockTaked := TCriticalSection.Create;
 FLockPooled := TCriticalSection.Create;
 FBusy :=TEvent.Create(nil, True, True, '');
end;

function TTarantoolPool.CreateNewConnection: ITNTConnection;
begin
 Result := NewConnection(FMainConnection.HostName, FMainConnection.Port, False);
 Result.UserName := FMainConnection.UserName;
 Result.Password := FMainConnection.Password;
 Result.Open;
 Inc(FAllocatedConnection);
end;

destructor TTarantoolPool.Destroy;
begin
  FreeAndNil(FLockPooled);
  FreeAndNil(FLockTaked);
  FreeAndNil(FBusy);
  while FConnList.PopItem <> nil do ;
  FreeAndNil(FConnList);
  inherited;
end;

function TTarantoolPool.Get: ITNTConnection;
const
{$IFDEF UNIX}
  Timeout: Cardinal = $FFFFFFFF;
{$ELSE}
  Timeout: Cardinal = 30000;
{$ENDIF}
begin
 if FBusy.WaitFor(Timeout) = wrTimeout then
  raise Exception.Create('Превышно количство соединений');
 Result := nil;

 FLockTaked.Enter;
 try
   if FTakenConnection < FMaxPoolSize then
     ReserveConnection
   else
    raise Exception.Create('Превышно количство соединений');
 finally
   FLockTaked.Leave;
 end;

 FLockPooled.Enter;
 try
  if FConnList.PopItem(Result) = wrTimeout then
   if FAllocatedConnection < FMaxPoolSize then
    Result := CreateNewConnection;
 finally
   FLockPooled.Leave;
 end;
end;

procedure TTarantoolPool.Put(AConnection: ITNTConnection);
begin
 FLockPooled.Enter;
 try
   FConnList.PushItem(AConnection);
   FLockTaked.Enter;
   try
    Dec(FTakenConnection);
    FBusy.SetEvent;
   finally
     FLockTaked.Leave;
   end;
 finally
   FLockPooled.Leave;
 end;
end;

procedure TTarantoolPool.ReserveConnection;
begin
 Inc(FTakenConnection);
 if FTakenConnection >= FMaxPoolSize then
  FBusy.ResetEvent;
end;

var
  FTNTConnectionPool : ITNTConnectionPool = nil;

function TNTConnectionPool(AMaxPoolSize: Integer = 10; AMainConnection: ITNTConnection = nil): ITNTConnectionPool;
begin
 Result := nil;
 if FTNTConnectionPool = nil then
  begin
    if AMainConnection = nil then
     raise ETarantoolException.Create('Невозможно создать пул соединений без указания основного соединения');
    FTNTConnectionPool := TTarantoolPool.Create(AMaxPoolSize, AMainConnection);
  end;
  Result := FTNTConnectionPool;
end;

function IsPoolExist: Boolean;
begin
  Result := FTNTConnectionPool <> nil;
end;

initialization
 FTNTConnectionPool := nil;

finalization
 FTNTConnectionPool := nil;

end.
