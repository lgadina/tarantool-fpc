unit Tarantool.Core;
{$I Tarantool.Options.inc}
interface
uses
   Tarantool.Interfaces;

function NewConnection(AHost: String; APort: Word;  AUseSSL: Boolean = False;
    AUsername: String = ''; APassword : String = ''; AConnectTimeout: Integer = 5000;
    AReadTimeout: Integer = 5000): ITNTConnection; overload;

function NewConnection(AUrl: String): ITNTConnection; overload;

function NewConnectionFromPool(APool: ITNTConnectionPool): ITNTConnection;

implementation
uses
{$IfDef FPC}
    fptimer,
{$Else}
    Vcl.ExtCtrls,
{$EndIf}
    SysUtils
  , syncobjs
  , classes
{$IfDef SYNAPSE}
  , blcksock
{$Else}
  , IdTCPClient
  , IdIOHandlerSocket
  , IdContext
  , IdTCPConnection
{$EndIf}
{$IfDef SYNAPSE}
  , ssl_openssl
{$Else}
  , IdSSLOpenSSL
{$EndIf}
  , IdGlobal
  , IdComponent
  , IdHashSHA
  , IdCoderMIME
  , Tarantool.InsertRequest
  , Tarantool.Tuple
  , Tarantool.AuthenticationRequest
  , Tarantool.ServerResponse
  , Tarantool.Packer
  , Tarantool.UserKeys
  , Tarantool.CommanCode
  , Tarantool.ErrorResponse
  , Tarantool.SelectRequest
  , Tarantool.Space
  , Tarantool.EvalRequest
  , Tarantool.CallRequest
  , Tarantool.SimpleMsgPack
  , Tarantool.Pool
  , Tarantool.Utils
  , Tarantool.Exceptions
  , Tarantool.Variants
  , Tarantool.Ping
  , Generics.Collections
  , URIParser
;


type
  TTNTSpaceList = class(TDictionary<String,ITNTSpace>);

  { TTNTConnection }

  TTNTConnection = class(TInterfacedObject, ITNTConnection)
  private
  private
    FConnectTimeout: integer;
    FRequestId: Int64;
    FTCPClient: {$IfDef SYNAPSE}TTCPBlockSocket{$Else}TIdTCPClient{$EndIf};
    FAlive: {$IfDef FPC}TFPTimer{$Else}TTimer{$EndIf};
    FAliveLock: TCriticalSection;
    {$IfDef SYNAPSE}
    {$Else}
    FSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
    {$EndIf}
    FSpaceList: TTNTSpaceList;
    FPool: ITNTConnectionPool;
    FPort: integer;
    FUseSSL: Boolean;
    FHostName: string;
    FPassword: string;
    FUserName: string;
    FIsReady: boolean;
    FVersion: String;
    FReadTimeOut: Integer;
    function GetConnectTimeout: integer;
    function GetConnectUrl: String;
    function GetUserName: string;
    function GetHostName: string;
    function GetIsReady: boolean;
    function GetPassword: string;
    function GetPort: integer;
    function GetUseSSL: Boolean;
    function GetVersion: String;
    procedure SetConnectTimeout(AValue: integer);
    procedure SetConnectUrl(AValue: String);
    procedure SetHostName(const Value: string);
    procedure SetPassword(const Value: string);
    procedure SetPort(const Value: integer);
    procedure SetUserName(const Value: string);
    procedure SetUseSSL(const Value: Boolean);
    function GetTarantoolPacketLength(ABuf: TBytes): Integer;
    function GetPool: ITNTConnectionPool;
    procedure SetPool(const Value: ITNTConnectionPool);
    function GetReadTimeout: integer;
    procedure SetReadTimeout(const Value: integer);
  protected
    function IdBytes2Bytes(ABytes: TIdBytes): TBytes;
    function Bytes2IdBytes(ABytes: TBytes): TIdBytes;
    procedure DoAlive(Sender: TObject);
   {$IfDef SYNAPSE}
    procedure SocketOnStatus(Sender: TObject; Reason: THookSocketReason; const Value: String);
   {$Else}
    procedure SocketOnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
    procedure ConnectionOnSocketAllocated(Sender: TObject);
   {$EndIf}

    procedure HandleConnectionClosed;
    procedure HandleConnectionOpened;

    function CreateScramble(ASalt: TIdBytes): TIdBytes; overload;
    function CreateScramble(ASalt: RawByteString): TIdBytes; overload;
    function ReadFromTarantool(AResponceGuid: TGUID; ASpace: ITNTSpace): ITNTResponce;
    procedure WriteToTarantool(ACommand: ITNTCommand);
    function DoTarantool(ACommand: ITNTCommand; AResponceGuid: TGUID; ASpace: ITNTSpace): ITNTResponce;
  public
    constructor Create(APool: ITNTConnectionPool = nil); virtual;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    function FindSpaceByName(ASpaceName: string): ITNTSpace;
    property ConnectURL: String read GetConnectUrl write SetConnectUrl;
    property HostName: string read GetHostName write SetHostName;
    property UserName: string read GetUserName write SetUserName;
    property Password: string read GetPassword write SetPassword;
    property Port: integer read GetPort write SetPort;
    property ConnectTimeout: integer read GetConnectTimeout write SetConnectTimeout;
    property UseSSL: Boolean read GetUseSSL write SetUseSSL;
    property IsReady: boolean read GetIsReady;
    property Version: String read GetVersion;
    property Pool: ITNTConnectionPool read GetPool Write SetPool;
    property ReadTimeout: integer read GetReadTimeout write SetReadTimeout;
    function Call(AFunctionName: string; AArguments: Variant; ANeedAnswer: Boolean = true): ITNTTuple; overload;
    function Call(AFunctionName: string; AArguments: array of const; ANeedAnswer: Boolean = true): ITNTTuple; overload;

    function Eval(AExpression: string; AArguments: Variant): ITNTTuple; overload;
    function Eval(AExpression: string; AArguments: array of const): ITNTTuple; overload;

    function Insert(ASpaceId: Integer; AValues: array of const; ANeedAnswer: Boolean = true): ITNTTuple; overload;
    function Insert(ASpaceId: Integer; AValues: Variant; ANeedAnswer: Boolean = true): ITNTTuple; overload;

    function Ping: boolean;

  public

  end;

{ TTNTConnection }

function TTNTConnection.Bytes2IdBytes(ABytes: TBytes): TIdBytes;
begin
 SetLength(Result, length(ABytes));
 Move(ABytes[0], Result[0], Length(ABytes));
end;

procedure TTNTConnection.DoAlive(Sender: TObject);
begin
  Ping
end;

function TTNTConnection.Call(AFunctionName: string;
  AArguments: array of const; ANeedAnswer: Boolean = true): ITNTTuple;
begin
  Result := Call(AFunctionName, TNTVariant(AArguments), ANeedAnswer);
end;

function TTNTConnection.Call(AFunctionName: string;
  AArguments: Variant; ANeedAnswer: Boolean = true): ITNTTuple;
var CallCmd: ITNTCall;
begin
  CallCmd := NewCall(AFunctionName, AArguments);
  if ANeedAnswer then
  begin
   Result := DoTarantool(CallCmd, ITNTTuple, nil) as ITNTTuple;
   if Result.RowCount > 0 then
     Result := Result.Tuple[0];
  end else
     DoTarantool(CallCmd, TGuid.Empty, nil);
end;

procedure TTNTConnection.Close;
var Space: ITNTSpace;
begin
 for Space in FSpaceList.Values do
  Space.Close;
 FSpaceList.Clear;
 if FPool <> nil then
  FPool.Put(Self)
 else
 if Assigned(FAlive) then
 begin
  FAlive.Enabled := False;
  FreeAndNil(FAlive);
 end;
 FAliveLock.Enter;
 try
   if Assigned(FTCPClient) then
    begin
      FTCPClient.{$IfDef SYNAPSE}CloseSocket{$ELse}Disconnect{$EndIf};
      FVersion := '';
      FreeAndNil(FTCPClient);
     {$IfDef SYNAPSE}
     {$Else}
      if Assigned(FSSLIOHandler) then
       FreeAndNil(FSSLIOHandler);
     {$EndIf}
    end;
 finally
   FAliveLock.Leave;
 end;
end;

{$IfDef SYNAPSE}
{$Else}
procedure TTNTConnection.ConnectionOnSocketAllocated(Sender: TObject);
begin
  FTcpClient.Socket.ReadTimeout := FReadTimeOut; // TODO: get from config
  FTcpClient.Socket.OnStatus := SocketOnStatus;
end;
{$EndIf}

constructor TTNTConnection.Create(APool: ITNTConnectionPool = nil);
begin
  FTCPClient := nil;
 {$IfDef SYNAPSE}
 {$Else}
  FSSLIOHandler := nil;
 {$EndIf}
  FIsReady := False;
  FVersion := '';
  FRequestId := 1;
  FPool :=  APool;
  FAliveLock := TCriticalSection.Create;
  FSpaceList := TTNTSpaceList.Create;
end;

function TTNTConnection.CreateScramble(ASalt: RawByteString): TIdBytes;
var Salt: TIdBytes;
begin
  Salt := TIdDecoderMIME.DecodeBytes(ASalt);
  Result := CreateScramble(Salt);
end;

function TTNTConnection.CreateScramble(ASalt: TIdBytes): TIdBytes;
var
    Step1, Step2, Step3, Step3Input: TIdBytes;
    i: Integer;

begin
  SetLength(Step1, 0);
  SetLength(Step2, 0);
  SetLength(Step3, 0);
  SetLength(Step3Input, 0);
  SetLength(Result, 0);
   with TIdHashSHA1.Create do
    begin
      Step1 := HashBytes(IndyTextEncoding_UTF8.GetBytes(Password));
      Step2 := HashBytes(Step1);
      SetLength(Step3Input, 20 + Length(Step2));
      Move(ASalt[0], Step3Input[0], 20);
      Move(Step2[0], Step3Input[20], Length(Step2));
      Step3 := HashBytes(Step3Input);
      for i := 0 to Length(Step3) - 1 do
         Step3[i] := Step3[i] xor Step1[i];
      Free;
    end;
   Exit(Step3);
end;

destructor TTNTConnection.Destroy;
begin
  Close;
  FreeAndNil(FSpaceList);
  if Assigned(FAlive) then
    FreeAndNil(FAlive);
  if Assigned(FTCPClient) then
   FreeAndNil(FTCPClient);
 {$IfDef SYNAPSE}
 {$Else}
  if Assigned(FSSLIOHandler) then
   FreeAndNil(FSSLIOHandler);
 {$EndIf}
  FPool := nil;
  FreeAndNil(FAliveLock);
  inherited;
end;

function TTNTConnection.Eval(AExpression: string;
  AArguments: Variant): ITNTTuple;
var EvalCmd : ITNTEval;
begin
  EvalCmd := NewEval(AExpression, AArguments);
  Result := DoTarantool(EvalCmd, ITNTTuple, nil) as ITNTTuple;
end;

function TTNTConnection.Eval(AExpression: string; AArguments: array of const): ITNTTuple;
begin
 Result := Eval(AExpression, TNTVariant(AArguments));
end;

function TTNTConnection.FindSpaceByName(ASpaceName: string): ITNTSpace;
var Select: ITNTSelect;
begin
 if not FSpaceList.ContainsKey(ASpaceName) then
 begin
  Select := SelectRequest(VSpaceSpaceId, VSpaceNameIndexId, ASpaceName);
  Result := DoTarantool(Select, ITNTSpace, nil) as ITNTSpace;
  FSpaceList.Add(ASpaceName, Result);
 end else
  Result := FSpaceList[ASpaceName];
 if Result.SpaceId = 0 then // space is closed
  begin
    FSpaceList.Remove(ASpaceName);
    Result := FindSpaceByName(ASpaceName);
  end;
end;

function TTNTConnection.GetUserName: string;
begin
 Result := FUserName;
end;

function TTNTConnection.GetConnectTimeout: integer;
begin
  Result := FConnectTimeout;
end;

function TTNTConnection.GetConnectUrl: String;
begin
 if UseSSL then
  Result := Format('tnts://%s:%s@%s:%d?ct=%d&rt=%d', [FUserName, FPassword, FHostName, FPort, FConnectTimeout, FReadTimeOut])
 else
  Result := Format('tnt://%s:%s@%s:%d?ct=%d&rt=%d', [FUserName, FPassword, FHostName, FPort, FConnectTimeout, FReadTimeOut]);
end;

function TTNTConnection.GetHostName: string;
begin
 Result := FHostName
end;

function TTNTConnection.GetIsReady: boolean;
begin
 Result := FIsReady;
end;

function TTNTConnection.GetPassword: string;
begin
 Result := FPassword;
end;

function TTNTConnection.GetPool: ITNTConnectionPool;
begin
 Result := FPool;
end;

function TTNTConnection.GetPort: integer;
begin
 Result := FPort;
end;

function TTNTConnection.GetReadTimeout: integer;
begin
 Result := FReadTimeOut;
end;

function TTNTConnection.GetUseSSL: Boolean;
begin
 Result := FUseSSL;
end;

function TTNTConnection.GetVersion: String;
begin
 Result := FVersion;
end;

procedure TTNTConnection.SetConnectTimeout(AValue: integer);
begin
  FConnectTimeout:=AValue;
  if Assigned(FAlive) then
  begin
   if FAlive.Enabled and (FConnectTimeout = 0) then
    FAlive.Enabled:= False;
   FAlive.Interval:= FConnectTimeout;
  end;
end;

procedure TTNTConnection.SetConnectUrl(AValue: String);
var Uri: TURI;
    Params: TStringList;
begin
 Uri := ParseURI(AValue, 'tnt', 3301);
 UseSSL := Uri.Protocol = 'tnts';
 FHostName:=Uri.Host;
 FPort:= Uri.Port;
 FUserName:= Uri.Username;
 FPassword:=Uri.Password;
 Params := TStringList.Create;
 try
   Params.Delimiter:='&';
   Params.DelimitedText:=Uri.Params;
   FConnectTimeout := StrToIntDef(Params.Values['ct'], 5000);
   FReadTimeOut := StrToIntDef(Params.Values['rt'], 5000);
 finally
   Params.Free;
 end;
end;

procedure TTNTConnection.HandleConnectionClosed;
begin
 FIsReady := False;
end;

procedure TTNTConnection.HandleConnectionOpened;
begin
  FIsReady := True;
end;

function TTNTConnection.IdBytes2Bytes(ABytes: TIdBytes): TBytes;
begin
 SetLength(Result, length(ABytes));
 Move(ABytes[0], Result[0], Length(ABytes));
end;

function TTNTConnection.Insert(ASpaceId: Integer; AValues: Variant;
  ANeedAnswer: Boolean): ITNTTuple;
var
    insertCmd: ITNTInsert;
begin
 Result := nil;
 InsertCmd := NewInsert(ASpaceId, AValues);
 if ANeedAnswer then
   Result :=DoTarantool(insertCmd, ITNTTuple, nil) as ITNTTuple
 else
  DoTarantool(insertCmd, TGuid.Empty, nil);
end;

function TTNTConnection.Insert(ASpaceId: Integer; AValues: array of const;
  ANeedAnswer: Boolean): ITNTTuple;
begin
 Result := Insert(ASpaceId, TNTVariant(AValues), ANeedAnswer);
end;

procedure TTNTConnection.Open;
var Auth: string;
    Scramble: TIdBytes;
    Buf: TBytes;
    AuthRequest: ITNTAuthenticationRequest;
begin
  if not FIsReady then
  begin
    try
      if not Assigned(FTCPClient) then
       begin
         FTCPClient := {$IfDef SYNAPSE}TTCPBlockSocket.Create{$Else}TIdTCPClient.Create(nil){$EndIf};
         {$IfDef Synapse}
         {$Else}
         if UseSSL then
          begin
            FSSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create();
            FTCPClient.IOHandler := FSSLIOHandler;
          end;
         {$EndIf}
         {$IfDef SYNAPSE}
          FTCPClient.OnStatus:= SocketOnStatus;
         {$Else}
          FTCPClient.OnSocketAllocated := ConnectionOnSocketAllocated;
          FTCPClient.OnStatus := SocketOnStatus;
         {$EndIf}
       end;
     {$IfDef SYNAPSE}
       FTCPClient.RaiseExcept:=True;
       FTCPClient.ConnectionTimeout:= FReadTimeOut;
       FTCPClient.Connect(FHostName, FPort.ToString);

       FTCPClient.ExceptCheck;

       if FUseSSL then
        begin
         FTCPClient.SSLDoConnect;
         FTCPClient.ExceptCheck;
        end;

       FVersion := FTCPClient.RecvTerminated(FReadTimeOut, #10);
       Auth:= Trim(FTCPClient.RecvTerminated(FReadTimeOut, #10));
     {$Else}
       FTCPClient.Port := FPort;
       FTCPClient.Host := FHostName;
       FTCPClient.ConnectTimeout := FConnectTimeout;
       FTCPClient.UseNagle := False;
       FTCPClient.Connect;
       FTCPClient.IOHandler.RecvBufferSize := 1024*1024;
       FVersion := FTCPClient.IOHandler.ReadLn();
       Auth := Trim(FTCPClient.IOHandler.ReadLn());
     {$EndIf}
       if FUserName = '' then
        FUserName := 'guest';
       if FUserName <> 'guest' then
       begin
         Scramble := CreateScramble(Auth);
         AuthRequest := NewTNTAuthenticationRequest;
         AuthRequest.Username := UserName;
         SetLength(Buf, Length(Scramble));
         Move(Scramble[0], Buf[0], Length(Scramble));
         AuthRequest.Scramble := Buf;
         AuthRequest.RequestId := 1;
         WriteToTarantool(AuthRequest);
         ReadFromTarantool(TGUID.Empty, nil);
       end;
       if not Assigned(FAlive) then
       begin
        FAlive := {$IfDef FPC}TFPTimer{$Else}TTimer{$EndIf}.Create(nil);
        FAlive.Interval := FConnectTimeout;
        {$IfDef FPC}
        FAlive.UseTimerThread:=True;
        {$EndIf}
        FAlive.OnTimer:= DoAlive;
       end;
       FAlive.Enabled:= FConnectTimeout > 0;
    except
      on E: Exception do
       begin
         FreeAndNil(FTCPClient);
         raise;
       end;
    end;
  end;
end;

function TTNTConnection.Ping: boolean;
var Cmd: ITNTPing;
begin
 if Assigned(FTCPClient) then
 begin
  Cmd := NewPing;
  try
    DoTarantool(Cmd, ITNTPingResponce, nil);
    Result := True;
  except
     Result := False;
  end;
 end else
  Result := False;
end;

function TTNTConnection.ReadFromTarantool(AResponceGuid: TGUID; ASpace: ITNTSpace): ITNTResponce;
var InBuf: TIdBytes;
    BufLen: Integer;
    Packer: ITNTPacker;
    FClass: TTNTResponseClass;
begin
  if Assigned(FTCPClient) then
  begin
   Result := nil;
   SetLength(InBuf, 5);
   {$IfDef SYNAPSE}
   FTCPClient.RecvBufferEx(@InBuf[0], 5, FReadTimeOut);
   {$Else}
   FTCPClient.IOHandler.ReadBytes(InBuf, 5, False);
   {$EndIf}
   BufLen := GetTarantoolPacketLength(IdBytes2Bytes(InBuf));
   SetLength(InBuf, BufLen);
   {$Ifdef SYNAPSE}
   FTCPClient.RecvBufferEx(@InBuf[0], BufLen, FReadTimeOut);
   {$Else}
   FTCPClient.IOHandler.ReadBytes(InBuf, BufLen, False);
   {$EndIf}
   Packer := TTNTPacker.Create;
   Packer.AsBytes := InBuf;
   SetLength(InBuf, 0);
   if Packer.Header.UnpackInteger(tnCode) >= tncERROR then
    begin
     Result := ErrorResponse(Packer, Self);
     raise ETarantoolException.Create((Result as ITNTError).ErrorCode, (Result as ITNTError).ErrorMessage);
    end;
  if GUIDToString(AResponceGuid) <> GUIDToString(TGUID.Empty) then
   FClass := GetResponseClass(AResponceGuid)
  else
   FClass:= nil;
  if FClass <> nil then
   Result := FClass.Create(Packer, Self, ASpace);
  end else
    raise ETarantoolException.Create(0, 'Connection failed');
end;

procedure TTNTConnection.SetHostName(const Value: string);
begin
 FHostName := Value;
end;

procedure TTNTConnection.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

procedure TTNTConnection.SetPool(const Value: ITNTConnectionPool);
begin
 FPool := Value;
end;

procedure TTNTConnection.SetPort(const Value: integer);
begin
  FPort := Value;
end;

procedure TTNTConnection.SetReadTimeout(const Value: integer);
begin
 if Value <> FReadTimeOut then
  begin
    FReadTimeOut := Value;
    {$IfDef SYNAPSE}

    {$Else}
    if assigned(FTCPClient) and Assigned(FTCPClient.Socket) then
     FTCPClient.Socket.ReadTimeout := FReadTimeOut;
    {$EndIf}
  end;
end;

procedure TTNTConnection.SetUserName(const Value: string);
begin
  FUserName := Value;
end;

procedure TTNTConnection.SetUseSSL(const Value: Boolean);
begin
 FUseSSL := Value;
end;

{$IfDef SYNAPSE}
procedure TTNTConnection.SocketOnStatus(Sender: TObject; Reason: THookSocketReason; const Value: String);
begin
  case Reason of
    HR_Error: Begin
                FTCPClient.CloseSocket;
                HandleConnectionClosed;
              end;
    HR_Connect: begin
                  FIsReady:= True;
                  HandleConnectionOpened;
                end;
    HR_SocketClose: Begin
                      FIsReady:= False;
                      HandleConnectionClosed;
                    end;
  end;
end;

{$Else}
procedure TTNTConnection.SocketOnStatus(ASender: TObject;
  const AStatus: TIdStatus; const AStatusText: string);
begin
 case AStatus of
   hsResolving: ;
   hsConnecting: ;
   hsConnected: begin
                  FIsReady := True;
                  HandleConnectionOpened;
                end;
   hsDisconnecting: ;
   hsDisconnected: begin
                    FIsReady := False;
                    HandleConnectionClosed;
                  end;
   hsStatusText: ;
   ftpTransfer: ;
   ftpReady: ;
   ftpAborted: ;
 end;
end;
{$EndIf}

procedure TTNTConnection.WriteToTarantool(ACommand: ITNTCommand);
var
  Packer: ITNTPacker;
  Buffer: TIdBytes;
begin
  Packer := TTNTPacker.Create;
  ACommand.RequestId := FRequestId;
  ACommand.PackToMessage(Packer);
{$IfDef SYNAPSE}
  Buffer := Packer.AsBytes;
  if Assigned(FTCPClient) then
  begin
    FTCPClient.SendBuffer(@Buffer[0], Length(Buffer));
{$Else}
    FTCPClient.IOHandler.Write(Packer.AsBytes);
{$EndIf}
    Inc(FRequestId);
  end else
    raise ETarantoolException.Create(0, 'Connection failed');
end;

function TTNTConnection.DoTarantool(ACommand: ITNTCommand;
  AResponceGuid: TGUID; ASpace: ITNTSpace): ITNTResponce;
begin
 FAliveLock.Enter;
 try
  WriteToTarantool(ACommand);
  Result := ReadFromTarantool(AResponceGuid, ASpace);
 finally
   FAliveLock.Leave;
 end;
end;

function TTNTConnection.GetTarantoolPacketLength(ABuf: TBytes): Integer;
begin
 Result := -1;
  if (Length(ABuf) >= 5) and (ABuf[0] = $ce) then
    with TTNTMsgPack.Create do
    begin
      try
         DecodeFromBytes(ABuf);
         Result := AsInteger;
      finally
        Free;
      end;
    end;
end;



function NewConnection(AHost: String; APort: Word; AUseSSL: Boolean = False;
   AUsername: String = ''; APassword : String = '';
   AConnectTimeout: Integer = 5000; AReadTimeout: Integer = 5000): ITNTConnection;
begin
 Result := TTNTConnection.Create;
 Result.HostName := AHost;
 Result.Port := APort;
 Result.UserName := AUsername;
 Result.UseSSL := AUseSSL;
 Result.Password := APassword;
 Result.ReadTimeout:=AReadTimeout;
 Result.ConnectTimeout:=AConnectTimeout;
end;

function NewConnectionFromPool(APool: ITNTConnectionPool): ITNTConnection;
begin
  Result := TTNTConnection.Create(APool);
end;

function NewConnection(AUrl: String): ITNTConnection;
begin
 Result := TTNTConnection.Create(nil);
 Result.ConnectUrl := AUrl;;
end;

end.
