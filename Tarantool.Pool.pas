﻿unit Tarantool.Pool;
{$I Tarantool.Options.inc}
interface
uses Tarantool.Interfaces;


function TNTConnectionPool(AMaxPoolSize: Integer; AHost: string; APort: Word; AUserName, APassword: string): ITNTConnectionPool; overload;

implementation

uses SysUtils
{$IfNDef FPC}
  , System.Generics.Collections
{$Else}
  , Generics.Collections
{$EndIf}
  , SyncObjs
  , Tarantool.Core
  , Tarantool.Exceptions
  ;

type
{$IfDef FPC}
  TTarantoolConnectionList = TQueue<ITNTConnection>;
{$Else}
  TTarantoolConnectionList = TThreadedQueue<ITNTConnection>;
{$EndIf}

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
 FConnList := TTarantoolConnectionList.Create{$IfNDef FPC}(AMaxPoolSize, INFINITE, 10){$EndIf};
 FLockTaked := TCriticalSection.Create;
 FLockPooled := TCriticalSection.Create;
 FBusy :=TEvent.Create(nil, True, True, '');
end;

function TTarantoolPool.CreateNewConnection: ITNTConnection;
begin
 Result := NewConnectionFromPool(Self);
 Result.HostName := FHost;
 Result.Port := FPort;
 Result.UserName := FUserName;
 Result.Password := FPassword;
 Result.Open;
 Inc(FAllocatedConnection);
end;

destructor TTarantoolPool.Destroy;
begin
  FreeAndNil(FLockPooled);
  FreeAndNil(FLockTaked);
  FreeAndNil(FBusy);
{$IfDef FPC}
  while FConnList.Count > 0 do
   FConnList.Dequeue;
{$Else}
  while FConnList.PopItem <> nil do ;
{$EndIf}
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
  raise Exception.Create('Превышно количество соединений');
 Result := nil;

 FLockTaked.Enter;
 try
   if FTakenConnection < FMaxPoolSize then
     ReserveConnection
   else
    raise Exception.Create('Превышно количество соединений');
 finally
   FLockTaked.Leave;
 end;

 FLockPooled.Enter;
 try
  {$IfDef FPC}
  if FConnList.Count > 0 then
   Result := FConnList.Dequeue
  else
   Result := nil;
  if Result = nil then
  {$Else}
  if FConnList.PopItem(Result) = wrTimeout then
  {$EndIf}
   if FAllocatedConnection < FMaxPoolSize then
    Result := CreateNewConnection;
   if (Result <> nil) and (Result.Pool = nil) then
    Result.Pool := Self;
 finally
   FLockPooled.Leave;
 end;
end;

procedure TTarantoolPool.Put(AConnection: ITNTConnection);
begin
 FLockPooled.Enter;
 try
   if AConnection.Pool <> nil then
   begin
     {$IfDef FPC}
     FConnList.Enqueue(AConnection);
     {$Else}
     FConnList.PushItem(AConnection);
     {$EndIf}
     AConnection.Pool := nil;
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
