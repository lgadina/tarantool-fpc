unit Tarantool.Pool;

interface
uses Tarantool.Interfaces;


function TNTConnectionPool(AMaxPoolSize: Integer; AHost: string; APort: Word; AUserName, APassword: string): ITNTConnectionPool; overload;

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
   FUsername, FPassword: String;
   FHost: String;
   FPort: Word;
   FConnList: TTarantoolConnectionList;
   FLockPooled, FLockTaked: TCriticalSection;
   FBusy: TEvent;
  protected
    function CreateNewConnection: ITNTConnection;
    procedure ReserveConnection;
  public
    constructor Create(AMaxPoolSize: Integer; AHost: String; APort: Word; AUsername, APassword: String);
    destructor Destroy; override;
    function Get: ITNTConnection;
    procedure Put(AConnection: ITNTConnection);
  end;

{ TTarantoolPool }

constructor TTarantoolPool.Create(AMaxPoolSize: Integer; AHost: String;
 APort: Word; AUsername, APassword: String);
begin
 FMaxPoolSize := AMaxPoolSize;
 FUsername := AUsername;
 FHost := AHost;
 FPassword := APassword;
 FPort := APort;
 FAllocatedConnection := 0;
 FTakenConnection := 0;
 FConnList := TTarantoolConnectionList.Create(AMaxPoolSize, INFINITE, 10);
 FLockTaked := TCriticalSection.Create;
 FLockPooled := TCriticalSection.Create;
 FBusy :=TEvent.Create(nil, True, True, '');
end;

function TTarantoolPool.CreateNewConnection: ITNTConnection;
begin
 Result := NewConnection(FHost, FPort);
 Result.UserName := FUserName;
 Result.Password := FPassword;
 Result.FromPool := True;
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
   if AConnection.FromPool then
   begin
     FConnList.PushItem(AConnection);
     FLockTaked.Enter;
     try
      Dec(FTakenConnection);
      FBusy.SetEvent;
     finally
       FLockTaked.Leave;
     end;
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


function TNTConnectionPool(AMaxPoolSize: Integer; AHost: string; APort: Word; AUserName, APassword: string): ITNTConnectionPool; overload;
begin
 Result := TTarantoolPool.Create(AMaxPoolSize, AHost, APort, AUserName, APassword);
end;

initialization

finalization

end.
