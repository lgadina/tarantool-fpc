unit Tarantool.Core;

interface
uses
   Tarantool.Interfaces;


function NewConnection(AHost: String; APort: Word; AUseSSL: Boolean = False;
   AUsername: String = ''; APassword : String = ''): ITNTConnection;

implementation
uses System.SysUtils
  , IdTCPClient
  , IdIOHandlerSocket
  , IdSSLOpenSSL
  , IdGlobal
  , IdContext
  , IdTCPConnection
  , IdComponent
  , IdHashSHA
  , IdCoderMime
  , Tarantool.AuthenticationRequest
  , Tarantool.ServerResponse
  , Tarantool.Packer
  , Tarantool.UserKeys
  , Tarantool.CommanCode
  , Tarantool.ErrorResponse
  , Tarantool.SelectRequest
  , Tarantool.Space
  , Tarantool.CallRequest
  , Tarantool.SimpleMsgPack;


type
  TTNTConnection = class(TInterfacedObject, ITNTConnection)
  private
  private
    FRequestId: Int64;
    FTCPClient: TIdTCPClient;
    FSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
    FPort: integer;
    FUseSSL: Boolean;
    FHostName: string;
    FPassword: string;
    FUserName: string;
    FIsReady: boolean;
    FVersion: String;
    function GetUserName: string;
    function GetHostName: string;
    function GetIsReady: boolean;
    function GetPassword: string;
    function GetPort: integer;
    function GetUseSSL: Boolean;
    function GetVersion: String;
    procedure SetHostName(const Value: string);
    procedure SetPassword(const Value: string);
    procedure SetPort(const Value: integer);
    procedure SetUserName(const Value: string);
    procedure SetUseSSL(const Value: Boolean);
    function GetTarantoolPacketLength(ABuf: TBytes): Integer;

  protected
    function IdBytes2Bytes(ABytes: TIdBytes): TBytes;
    function Bytes2IdBytes(ABytes: TBytes): TIdBytes;
    procedure SocketOnStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
    procedure ConnectionOnSocketAllocated(Sender: TObject);
    procedure HandleConnectionClosed;
    procedure HandleConnectionOpened;

    function CreateScramble(ASalt: TIdBytes): TIdBytes; overload;
    function CreateScramble(ASalt: RawByteString): TIdBytes; overload;
    function ReadFromTarantool(AResponceGuid: TGUID): ITNTResponce;
    procedure WriteToTarantool(ACommand: ITNTCommand);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    function FindSpaceByName(ASpaceName: string): IUnknown;
    property HostName: string read GetHostName write SetHostName;
    property UserName: string read GetUserName write SetUserName;
    property Password: string read GetPassword write SetPassword;
    property Port: integer read GetPort write SetPort;
    property UseSSL: Boolean read GetUseSSL write SetUseSSL;
    property IsReady: boolean read GetIsReady;
    property Version: String read GetVersion;
    function Call(AFunctionName: string; AArguments: Variant): ITNTTuple;
  public

  end;

{ TTNTConnection }

function TTNTConnection.Bytes2IdBytes(ABytes: TBytes): TIdBytes;
begin
 SetLength(Result, length(ABytes));
 Move(ABytes[0], Result[0], Length(ABytes));
end;

function TTNTConnection.Call(AFunctionName: string;
  AArguments: Variant): ITNTTuple;
var CallCmd: ITNTCall;
begin
  CallCmd := NewCall(AFunctionName, AArguments);
  WriteToTarantool(CallCmd);
  Result := ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

procedure TTNTConnection.Close;
begin
 if Assigned(FTCPClient) then
  begin
    FTCPClient.Disconnect;
    FVersion := '';
    FreeAndNil(FTCPClient);
    if Assigned(FSSLIOHandler) then
     FreeAndNil(FSSLIOHandler);
  end;
end;

procedure TTNTConnection.ConnectionOnSocketAllocated(Sender: TObject);
begin
  FTcpClient.Socket.ReadTimeout := 2000; // TODO: get from config
  FTcpClient.Socket.OnStatus := SocketOnStatus;
end;

constructor TTNTConnection.Create;
begin
  FTCPClient := nil;
  FSSLIOHandler := nil;
  FIsReady := False;
  FVersion := '';
  FRequestId := 1;
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
  if Assigned(FTCPClient) then
   FreeAndNil(FTCPClient);
  if Assigned(FSSLIOHandler) then
   FreeAndNil(FSSLIOHandler);
  inherited;
end;

function TTNTConnection.FindSpaceByName(ASpaceName: string): IUnknown;
var Select: ITNTSelect;
begin
  Select := SelectRequest(VSpaceSpaceId, VSpaceNameIndexId, ASpaceName);
  WriteToTarantool(Select);
  Result := ReadFromTarantool(ITNTSpace) as ITNTSpace;
end;

function TTNTConnection.GetUserName: string;
begin
 Result := FUserName;
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

function TTNTConnection.GetPort: integer;
begin
 Result := FPort;
end;

function TTNTConnection.GetUseSSL: Boolean;
begin
 Result := FUseSSL;
end;

function TTNTConnection.GetVersion: String;
begin
 Result := FVersion;
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

procedure TTNTConnection.Open;
var Auth: string;
    Scramble: TIdBytes;
    Buf: TBytes;
    InBuf: TIdBytes;
    BufLen: Integer;
    AuthRequest: ITNTAuthenticationRequest;
    Packer: IPacker;
begin
  if not FIsReady then
  begin
    try
      if not Assigned(FTCPClient) then
       begin
         FTCPClient := TIdTCPClient.Create(nil);
         if UseSSL then
          begin
            FSSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create();
            FTCPClient.IOHandler := FSSLIOHandler;
          end;
          FTCPClient.OnSocketAllocated := ConnectionOnSocketAllocated;
          FTCPClient.OnStatus := SocketOnStatus;
       end;
       FTCPClient.Port := FPort;
       FTCPClient.Host := FHostName;
       FTCPClient.ConnectTimeout := 5000;
       FTCPClient.Connect;
       FTCPClient.IOHandler.RecvBufferSize := 100*1024*1024;
       FVersion := FTCPClient.IOHandler.ReadLn();
       Auth := Trim(FTCPClient.IOHandler.ReadLn());
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
         ReadFromTarantool(TGUID.Empty);

       end;
    except
      on E: Exception do
       begin
         FreeAndNil(FTCPClient);
         raise;
       end;
    end;
  end;
end;

function TTNTConnection.ReadFromTarantool(AResponceGuid: TGUID): ITNTResponce;
var InBuf: TIdBytes;
    BufLen: Integer;
    Packer: IPacker;
    FClass: TTNTResponseClass;
begin
   Result := nil;
   SetLength(InBuf, 5);
   FTCPClient.IOHandler.ReadBytes(InBuf, 5, False);
   BufLen := GetTarantoolPacketLength(IdBytes2Bytes(InBuf));
   SetLength(InBuf, BufLen);
   FTCPClient.IOHandler.ReadBytes(InBuf, BufLen, False);
   Packer := TTNTPacker.Create;
   Packer.AsBytes := InBuf;
   if Packer.Header.UnpackInteger(tnCode) >= tncERROR then
    begin
     Result := ErrorResponse(Packer, Self);
     raise Exception.Create((Result as ITNTError).ErrorMessage);
    end;
  FClass := GetResponseClass(AResponceGuid);
  if FClass <> nil then
   Result := FClass.Create(Packer, Self);
end;

procedure TTNTConnection.SetHostName(const Value: string);
begin
 FHostName := Value;
end;

procedure TTNTConnection.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

procedure TTNTConnection.SetPort(const Value: integer);
begin
  FPort := Value;
end;

procedure TTNTConnection.SetUserName(const Value: string);
begin
  FUserName := Value;
end;

procedure TTNTConnection.SetUseSSL(const Value: Boolean);
begin
 FUseSSL := Value;
end;

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

procedure TTNTConnection.WriteToTarantool(ACommand: ITNTCommand);
var
  Packer: IPacker;
begin
  Packer := TTNTPacker.Create;
  ACommand.RequestId := FRequestId;
  ACommand.PackToMessage(Packer);
  FTCPClient.IOHandler.Write(Packer.AsBytes);
  Inc(FRequestId);
end;

function TTNTConnection.GetTarantoolPacketLength(ABuf: TBytes): Integer;
begin
 Result := -1;
  if (Length(ABuf) >= 5) and (ABuf[0] = $ce) then
    with TSimpleMsgPack.Create do
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
   AUsername: String = ''; APassword : String = ''): ITNTConnection;
begin
  Result := TTNTConnection.Create;
  Result.HostName := AHost;
  Result.Port := APort;
  Result.UserName := AUsername;
  Result.UseSSL := AUseSSL;
  Result.Password := APassword;
end;

end.
