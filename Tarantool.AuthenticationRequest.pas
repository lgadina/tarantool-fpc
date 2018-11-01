unit Tarantool.AuthenticationRequest;
{$I Tarantool.Options.inc}
interface

uses
{$IfDef FPC}
   sysutils
{$Else}
   System.SysUtils
{$EndIf}
  , Tarantool.ClientMessage
  , Tarantool.Interfaces
  , IdGlobal;

type
  ITNTAuthenticationRequest = interface(ITNTCommand)
    procedure SetUsername(const Value: string);
    function GetUsername: string;
    procedure SetScramble(const Value: TBytes);
    function GetScramble: TBytes;

    property Username: string read GetUsername write SetUsername;
    property Scramble: TBytes read GetScramble write SetScramble;
  end;

  function NewTNTAuthenticationRequest: ITNTAuthenticationRequest;

implementation

uses Tarantool.UserKeys, Tarantool.CommanCode;

type
  TTNTAuthenticationRequest = class(TTNTClientMessageBase, ITNTAuthenticationRequest)
  private
    FUsername: string;
    FScramble: TBytes;
    procedure SetUsername(const Value: string);
    function GetUsername: string;
    procedure SetScramble(const Value: TBytes);
    function GetScramble: TBytes;
  protected
    procedure PackToMessage(APacker: ITNTPacker); override;
  public
    property Username: string read GetUsername write SetUsername;
    property Scramble: TBytes read GetScramble write SetScramble;
  end;


{ TTNTAuthenticationRequest }


function TTNTAuthenticationRequest.GetScramble: TBytes;
begin
 Result := FScramble;
end;

function TTNTAuthenticationRequest.GetUsername: string;
begin
 Result := FUsername;
end;

procedure TTNTAuthenticationRequest.PackToMessage(APacker: ITNTPacker);
begin
  inherited;
  APacker.Body.Pack(tnUsername, FUsername);
  with APacker.Body.PackArray(tnTuple) do
   begin
     Pack('chap-sha1');
     Pack(FScramble);
   end;
end;

procedure TTNTAuthenticationRequest.SetScramble(const Value: TBytes);
begin
  FScramble := Value;
end;

procedure TTNTAuthenticationRequest.SetUsername(const Value: string);
begin
  FUsername := Value;
end;


function NewTNTAuthenticationRequest: ITNTAuthenticationRequest;
begin
  Result := TTNTAuthenticationRequest.Create(tncAuth);
end;

end.
