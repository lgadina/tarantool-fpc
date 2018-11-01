unit Tarantool.ErrorResponse;
{$I Tarantool.Options.inc}
interface
uses
   Tarantool.Interfaces;

type
   ITNTError = interface(ITNTResponce)
     ['{DBB04E28-13A5-4E89-B227-A3B570158443}']
     function GetErrorCode: Integer;
     function GetErrorMessage: String;

     property ErrorCode: Integer read GetErrorCode;
     property ErrorMessage: String read GetErrorMessage;
   end;

   function ErrorResponse(APacker: ITNTPacker; AConnection: ITNTConnection): ITNTError;

implementation

uses Tarantool.ServerResponse, Tarantool.UserKeys;

type
  TTNTError = class(TTNTResponce, ITNTError)
  private
    FMessage: String;
    function GetErrorCode: Integer;
    function GetErrorMessage: String;
  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace); override;

    property ErrorCode: Integer read GetErrorCode;
    property ErrorMessage: String read GetErrorMessage;
  end;

{ TTNTError }

constructor TTNTError.Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace);
begin
  inherited;
  FMessage := APacker.Body.UnpackString(tnError);
end;

function TTNTError.GetErrorCode: Integer;
begin
 Result := inherited GetCode;
end;

function TTNTError.GetErrorMessage: String;
begin
 Result := FMessage;
end;

function ErrorResponse(APacker: ITNTPacker; AConnection: ITNTConnection): ITNTError;
begin
  Result := TTNTError.Create(APacker, AConnection, nil);
end;

end.
